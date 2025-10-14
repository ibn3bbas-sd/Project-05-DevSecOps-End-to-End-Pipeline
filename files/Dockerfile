FROM openjdk:17

WORKDIR /app
COPY . /app

# Install Maven
RUN microdnf install -y maven

# Build the app
RUN mvn clean package -DskipTests

# Create and use non-root user
RUN useradd -m spring
USER spring

EXPOSE 8080
CMD ["java", "-jar", "target/*.jar"]