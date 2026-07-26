# Stage 1: Build the application using official Maven + JDK 21
FROM maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /app

# Copy Maven dependency descriptor & source code
COPY pom.xml .
COPY src ./src

# Build production JAR skipping tests
RUN mvn clean package -DskipTests

# Stage 2: Minimal Java Runtime environment for production
FROM eclipse-temurin:21-jre
WORKDIR /app

# Copy built JAR from build stage
COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
