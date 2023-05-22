ARG PORT=8080

FROM maven:3-eclipse-temurin-11-alpine as build
LABEL name="sonarqube-maven-docker-issue-1"
EXPOSE ${PORT}
WORKDIR /workspace/app
VOLUME [ "/root/.m2" ]

COPY pom.xml pom.xml
RUN mvn dependency:go-offline --batch-mode
COPY src src
# https://issues.apache.org/jira/browse/MDEP-82
# due to a bug in go-offline not all dependencies are downloaded, so can't use offline mode on build
RUN mvn clean package --batch-mode -D skipTests
RUN mkdir -p target/extracted && (java -Djarmode=layertools -jar target/*.jar extract --destination target/extracted)

FROM eclipse-temurin:11-alpine as run

VOLUME /tmp
ARG EXTRACTED=/workspace/app/target/extracted
COPY --from=build ${EXTRACTED}/dependencies/ ./
COPY --from=build ${EXTRACTED}/spring-boot-loader/ ./
COPY --from=build ${EXTRACTED}/snapshot-dependencies/ ./
COPY --from=build ${EXTRACTED}/application/ ./
ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]
