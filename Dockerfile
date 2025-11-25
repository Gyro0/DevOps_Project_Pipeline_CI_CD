# Build Stage
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /build
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package -DskipTests -B

# Runtime Stage
FROM tomcat:9-jdk17

ENV CATALINA_HOME=/usr/local/tomcat \
    POSTGRES_HOST=postgres \
    POSTGRES_PORT=5433 \
    POSTGRES_DB=yourwaytoitaly \
    POSTGRES_USER=ywti \
    POSTGRES_PASSWORD=ywti_password

# Install dependencies and clean up
RUN apt-get update && apt-get install -y unzip && rm -rf /var/lib/apt/lists/* && \
    rm -rf ${CATALINA_HOME}/webapps/*

# Setup Application
COPY --from=builder /build/target/ywti-wa2021-1.0-SNAPSHOT.war /tmp/ROOT.war
RUN mkdir -p ${CATALINA_HOME}/webapps/ROOT && \
    cd ${CATALINA_HOME}/webapps/ROOT && \
    unzip -q /tmp/ROOT.war && \
    rm /tmp/ROOT.war

# Startup script for env var substitution
RUN echo '#!/bin/bash\nset -e\n\
for var in POSTGRES_HOST POSTGRES_PORT POSTGRES_DB POSTGRES_USER POSTGRES_PASSWORD; do\n\
  sed -i "s|\${${var}}|${!var}|g" ${CATALINA_HOME}/webapps/ROOT/META-INF/context.xml\n\
done\n\
exec catalina.sh run' > /startup.sh && chmod +x /startup.sh

EXPOSE 8080

CMD ["/startup.sh"]