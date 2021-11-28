FROM openjdk:11.0.13-jre-slim
COPY target/*.jar /usr/src/
WORKDIR /usr/src/
EXPOSE 8080
ENTRYPOINT ["/bin/bash", "-c", "java $JAVA_OPTS -jar ./app.jar"]
