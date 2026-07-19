FROM eclipse-temurin:21-jdk
WORKDIR /app
COPY . .
RUN ./mvnw -q -DskipTests package
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "target/skillforge-backend-0.0.1-SNAPSHOT.jar"]
