# --- Stage 1: Build Phase ---
FROM maven:3.9-eclipse-temurin-21-alpine AS builder
WORKDIR /build

COPY pom.xml ./
RUN mvn install -N -DskipTests -Dcheckstyle.skip=true

COPY . .
ARG SERVICE_NAME
RUN mvn clean package -pl ${SERVICE_NAME} -am -DskipTests -Dcheckstyle.skip=true -Dmaven.wagon.http.retryHandler.count=5

# Extract Spring Boot layers
RUN java -Djarmode=layertools -jar ${SERVICE_NAME}/target/*.jar extract --destination extracted

# --- Stage 2: Runtime Phase ---
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

ARG SERVICE_NAME

# Copy strictly the 4 lightweight Spring Boot directories (NOT the whole target folder)
COPY --from=builder /build/extracted/dependencies/ ./
COPY --from=builder /build/extracted/spring-boot-loader/ ./
COPY --from=builder /build/extracted/snapshot-dependencies/ ./
COPY --from=builder /build/extracted/application/ ./

ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
