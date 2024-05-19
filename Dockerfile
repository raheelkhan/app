FROM maven:3.9.6-eclipse-temurin-21-alpine as build

WORKDIR /app

COPY pom.xml .
COPY src src

RUN mvn install -DskipTests
RUN mkdir -p target/dependency && (cd target/dependency; jar -xf ../*.jar)

FROM eclipse-temurin:21.0.3_9-jre-alpine

VOLUME /tmp

ARG DEPENDENCY=/app/target/dependency

ARG UID=10001

RUN addgroup -S appgroup && adduser --disabled-password --no-create-home --uid "${UID}" appuser
USER appuser

COPY --from=build ${DEPENDENCY}/BOOT-INF/lib /app/lib
COPY --from=build ${DEPENDENCY}/META-INF /app/META-INF
COPY --from=build ${DEPENDENCY}/BOOT-INF/classes /app

ENTRYPOINT ["java","-cp","app:app/lib/*","com.raheelkhan.app.AppApplication"]