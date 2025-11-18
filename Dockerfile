# ==========================================
# Étape 1 : Build stage (compilation Maven)
# ==========================================
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /build

COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src
RUN mvn clean package -DskipTests -B

# ==========================================
# Étape 2 : Runtime stage (Tomcat)
# ==========================================
FROM tomcat:9-jdk17

LABEL maintainer="gyro@example.com"
LABEL description="YourWayToItaly - Application JEE"
LABEL version="1.0"

ENV CATALINA_HOME=/usr/local/tomcat
ENV POSTGRES_HOST=postgres
ENV POSTGRES_PORT=5433
ENV POSTGRES_DB=yourwaytoitaly
ENV POSTGRES_USER=ywti
ENV POSTGRES_PASSWORD=ywti_password

RUN apt-get update && \
    apt-get install -y unzip curl && \
    rm -rf /var/lib/apt/lists/*

RUN rm -rf ${CATALINA_HOME}/webapps/*

COPY --from=builder /build/target/ywti-wa2021-1.0-SNAPSHOT.war /tmp/ROOT.war

# Décompresser le WAR dans le dossier ROOT
RUN mkdir -p ${CATALINA_HOME}/webapps/ROOT && \
    cd ${CATALINA_HOME}/webapps/ROOT && \
    unzip -q /tmp/ROOT.war && \
    rm /tmp/ROOT.war

# Créer un script de démarrage pour remplacer les variables d'environnement
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Remplacer les variables d'\''environnement dans context.xml\n\
sed -i "s|\${POSTGRES_HOST}|${POSTGRES_HOST}|g" ${CATALINA_HOME}/webapps/ROOT/META-INF/context.xml\n\
sed -i "s|\${POSTGRES_PORT}|${POSTGRES_PORT}|g" ${CATALINA_HOME}/webapps/ROOT/META-INF/context.xml\n\
sed -i "s|\${POSTGRES_DB}|${POSTGRES_DB}|g" ${CATALINA_HOME}/webapps/ROOT/META-INF/context.xml\n\
sed -i "s|\${POSTGRES_USER}|${POSTGRES_USER}|g" ${CATALINA_HOME}/webapps/ROOT/META-INF/context.xml\n\
sed -i "s|\${POSTGRES_PASSWORD}|${POSTGRES_PASSWORD}|g" ${CATALINA_HOME}/webapps/ROOT/META-INF/context.xml\n\
\n\
echo "Environment variables replaced in context.xml"\n\
cat ${CATALINA_HOME}/webapps/ROOT/META-INF/context.xml\n\
\n\
# Démarrer Tomcat\n\
exec catalina.sh run\n\
' > /startup.sh && chmod +x /startup.sh

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/html/index.html || exit 1

CMD ["/startup.sh"]