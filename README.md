
---

# DevOps Project – Deployment of a JEE Web Application

## Original Project

Source code used as the base of the work:
🔗 [https://github.com/vittorioexp/ywti-j2ee-webapp-project](https://github.com/vittorioexp/ywti-j2ee-webapp-project)

## Technologies Used

Docker · Kubernetes · Jenkins · SonarQube · Prometheus · Grafana

## Table of Contents

* Introduction and Prerequisites
* Step 1: GitHub – Source Code Management
* Step 2: Jenkins – Continuous Integration
* Step 3: SonarQube – Code Quality
* Step 4: Docker – Containerization
* Step 5: Kubernetes – Deployment
* Step 6: Prometheus & Grafana – Monitoring
* Conclusion and Best Practices

---

# Introduction and Prerequisites

This project aims to design and implement a complete CI/CD pipeline for deploying a JEE web application on Kubernetes. The pipeline automates the entire lifecycle:

* Developers push code to GitHub.
* Jenkins pulls the updates, builds the project, and runs tests.
* SonarQube performs automated static analysis and enforces code-quality gates.
* Docker packages the JEE application into container images.
* Kubernetes deploys and manages these images.
* Prometheus and Grafana provide real-time monitoring and visualization of application metrics.

This setup ensures reliability, repeatability, and full automation of the deployment process.

---

## Required Software / Tools

| Tool           | Installation Link                                                                                        |
| -------------- | -------------------------------------------------------------------------------------------------------- |
| Git            | [https://git-scm.com](https://git-scm.com)                                                               |
| Java JDK       | [https://www.oracle.com/java/technologies/downloads](https://www.oracle.com/java/technologies/downloads) |
| Maven          | [https://maven.apache.org](https://maven.apache.org)                                                     |
| Docker Desktop | [https://www.docker.com](https://www.docker.com)                                                         |
| Jenkins        | [https://www.jenkins.io](https://www.jenkins.io)                                                         |
| SonarQube      | [https://www.sonarqube.org](https://www.sonarqube.org)                                                   |
| kubectl        | [https://kubernetes.io](https://kubernetes.io)                                                           |

## Required Skills

* Basics of Java & Maven
* Understanding Git commands (commit, branch, merge)
* Docker concepts (images, containers, Dockerfile)
* Basic command-line usage

---

# Step 1: GitHub – Source Code Management

## Create a GitHub Repository

1. Sign in to GitHub
2. Click the **+** icon (top-right) → **New Repository**
3. Enter repository name, optional description
4. Set the visibility to **Public**
5. Create the repository

---

## Create a `.gitignore` File

A `.gitignore` file tells Git which files should **not** be committed (build artifacts, IDE configs, secrets, etc.).

Place this file in your project root:

```gitignore
# Maven
target/
pom.xml.tag
pom.xml.releaseBackup
pom.xml.versionsBackup
pom.xml.next
release.properties

# IDE
.idea/
*.iml
.vscode/
.settings/
.project
.classpath

# Logs
*.log

# Docker
.dockerignore

# Kubernetes secrets
k8s/*-secret.yaml

# Environment variables
.env
.env.local

# OS
.DS_Store
Thumbs.db
```

---

## Push Your Project to GitHub

```bash
# Navigate to your project
cd C:\Path\To\YourProject\

# Initialize Git
git init

# Add all project files
git add .

# First commit
git commit -m "Initial commit"

# Link GitHub repository
git remote add origin https://github.com/UserName/repositoryName.git

# Push to main branch
git branch -M main
git push -u origin main
```

---

## Branching Strategy

### Main Branch (default)

Check that you're on main:

```bash
git branch
# * main
```

### Create a Develop Branch

```bash
git pull origin main
git checkout -b develop
git push -u origin develop
```

### Create a Feature Branch

```bash
git pull origin develop
git checkout -b feature/example
git push -u origin feature/example
```

### Verify Branch Structure

```bash
git branch -a
```

---

# Step 2: Jenkins – Continuous Integration

## Jenkins Installation

Download `jenkins.war` from:
🔗 [https://www.jenkins.io/download/](https://www.jenkins.io/download/)

Run Jenkins locally:

```bash
cd C://Path/To/Jenkins/
java -jar jenkins.war --httpPort=8080
```

Access Jenkins at:
 [http://localhost:8080](http://localhost:8080)

The initial admin password is located at:

```
C://Users/<your-user>/.jenkins/secrets/initialAdminPassword
```

---

## Jenkins Configuration

Go to: **Manage Jenkins → Tools**

### Configure Maven

* Add Maven
* Name: `Maven-3.9.11`
* Install automatically: **Yes**
* Version: **3.9.11**

### Configure JDK

* Add JDK
* Name: `JDK-17`
* Install automatically: **Yes**

### Configure Git

* Name: `git.exe`
* Path: `C:\Program Files\Git\bin\git.exe`

---

## Connect Jenkins with GitHub (Webhook)

Because Jenkins is running locally, we use **ngrok** to expose port 8080.

```bash
ngrok http 8080
```

Use the generated HTTPS URL for GitHub Webhooks.

### Configure GitHub Webhook

GitHub → Repository → **Settings → Webhooks → Add Webhook**

| Field        | Value                                 |
| ------------ | ------------------------------------- |
| Payload URL  | `https://<ngrok-url>/github-webhook/` |
| Content type | `application/json`                    |
| Secret       | *Leave empty*                         |
| Events       | **Just the push event**               |

---

## Create a Jenkins Pipeline Job

**New Item → Pipeline**

### Triggers

* **GitHub hook trigger for GITScm polling**
* **Poll SCM**: `H/5 * * * *` (checks every 5 minutes)

### Pipeline Definition

* Definition: **Pipeline script from SCM**
* SCM: **Git**
* Repository URL
* Credentials
* Branch: `*/develop` or any branch you want to build
* Script Path: `Jenkinsfile`

---

## Jenkinsfile

Here is the pipeline script :

```groovy
pipeline {
    agent any

    tools {
        maven 'Maven-3.9.11'
        jdk 'JDK-17'
    }

    environment {
        MAVEN_OPTS = '-Xmx1024m'
        SCANNER_HOME = tool 'SonarScanner'
        DOCKER_IMAGE = '${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}'
        DOCKER_TAG = "${env.BUILD_NUMBER ?: 1.0}"
        GIT_BRANCH = "develop"
    }

    stages {
        stage('1. Clone Repository') {
            when {
                branch 'develop'
            }
            steps {
                echo "Cloning repository (branch: ${GIT_BRANCH})..."
                checkout scm
            }
        }

        stage('2. Compile Project') {
            steps {
                echo 'Compiling Maven project...'
                bat 'mvn clean compile'
            }
        }

        stage('3. Run Unit Tests') {
            steps {
                echo 'Running unit tests...'
                bat 'mvn test'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('4. Package WAR/JAR') {
            steps {
                echo 'Packaging application...'
                bat 'mvn package -DskipTests'
            }
            post {
                success {
                    archiveArtifacts artifacts: '**/target/*.war', allowEmptyArchive: true, fingerprint: true
                }
            }
        }

        stage('5. SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    bat 'mvn sonar:sonar'
                }
            }
        }

        stage('6. Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('7. Build Docker Image') {
            steps {
                bat "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                bat "docker rmi ${DOCKER_IMAGE}:latest || exit 0"
                bat "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
            }
        }

        stage('8. Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    bat 'echo %PASS% | docker login -u %USER% --password-stdin'
                    bat "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    bat "docker push ${DOCKER_IMAGE}:latest"
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline executed successfully."
        }
        failure {
            echo "Pipeline failed."
        }
        always {
            cleanWs()
        }
    }
}
```

---

## Pipeline Stage Summary

| Stage | Description              | Command             |
| ----- | ------------------------ | ------------------- |
| 1     | Clone repository         | `checkout scm`      |
| 2     | Compile project          | `mvn clean compile` |
| 3     | Run tests                | `mvn test`          |
| 4     | Package JAR/WAR          | `mvn package`       |
| 5     | SonarQube analysis       | `mvn sonar:sonar`   |
| 6     | Quality Gate             | Sonar API           |
| 7     | Build Docker image       | `docker build`      |
| 8     | Push image to Docker Hub | `docker push`       |

---

>Note: "when {
                branch 'develop'
            } " here we specified the branch that we should be building from when the pipeline is triggered
# Step 3: SonarQube – Code Quality

SonarQube automatically analyzes source code to detect bugs, vulnerabilities, code smells, duplications, and test coverage using JaCoCo.

---

## Install SonarQube

Download:
🔗 [https://www.sonarsource.com/products/sonarqube/downloads/](https://www.sonarsource.com/products/sonarqube/downloads/)

Run SonarQube :

```
sonarqube/bin/windows-x86-64/StartSonar.bat
```

Access SonarQube:
 [http://localhost:9000/](http://localhost:9000/)

---

## Generate an Authentication Token

1. SonarQube → **My Account → Security**
2. Create token:

   * Name: `Jenkins`
   * Type: *User Token*
   * Expiration: 90 days
3. Copy the token (starts with `squ_`)

---

## Integrate Jenkins with SonarQube

### Install SonarQube Scanner

Jenkins → Manage Jenkins → Plugins → Install **SonarQube Scanner**

### Configure SonarQube Server

Jenkins → Manage Jenkins → System → SonarQube Servers

| Field       | Value                   |
| ----------- | ----------------------- |
| Name        | `SonarQube`             |
| URL         | `http://localhost:9000` |
| Credentials | Token created earlier   |

### Configure SonarScanner Tool

Jenkins → Manage Jenkins → Tools → SonarQube Scanner

* Install automatically: **Yes**

---

## Add JaCoCo and Sonar Properties in `pom.xml`

```xml
<properties>
    <maven.compiler.source>17</maven.compiler.source>
    <maven.compiler.target>17</maven.compiler.target>

    <!-- SonarQube -->
    <sonar.projectKey>yourwaytoitaly</sonar.projectKey>
    <sonar.projectName>YourWayToItaly</sonar.projectName>
    <sonar.host.url>http://localhost:9000</sonar.host.url>
    <sonar.java.binaries>target/classes</sonar.java.binaries>
    <sonar.coverage.jacoco.xmlReportPaths>target/site/jacoco/jacoco.xml</sonar.coverage.jacoco.xmlReportPaths>
</properties>

<build>
    <plugins>
        <!-- JaCoCo Coverage -->
        <plugin>
            <groupId>org.jacoco</groupId>
            <artifactId>jacoco-maven-plugin</artifactId>
            <version>0.8.10</version>
            <executions>
                <execution>
                    <id>prepare-agent</id>
                    <goals>
                        <goal>prepare-agent</goal>
                    </goals>
                </execution>
                <execution>
                    <id>report</id>
                    <phase>test</phase>
                    <goals>
                        <goal>report</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

---

# Step 4: Docker – Containerization

Docker is a platform that allows us to package an application and all its dependencies into a **portable container image**.  
To do this, we use a **Dockerfile**, which is a text file containing the instructions needed to build the image (like a recipe for creating the container).

## Create a Dockerfile

Create a file named `Dockerfile` in the root directory of your project:

```dockerfile
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
RUN apt-get update && apt-get install -y unzip && \
    rm -rf /var/lib/apt/lists/* && \
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
````

---

## Line-by-Line Explanation

### 1. Build Stage (Builder Image)

```dockerfile
FROM maven:3.9-eclipse-temurin-17 AS builder
```

* Uses an official image containing **Maven** and **Java 17**.
* `AS builder` gives a name to this build stage (used later to copy artifacts).

```dockerfile
WORKDIR /build
```

* Sets `/build` as the working directory inside the image.
* All subsequent commands run from this directory.

```dockerfile
COPY pom.xml .
RUN mvn dependency:go-offline -B
```

* Copies only the `pom.xml` file first.
* Downloads all Maven dependencies in advance (`go-offline`), speeding up subsequent builds.

```dockerfile
COPY src ./src
RUN mvn clean package -DskipTests -B
```

* Copies the source code into `/build/src`.
* Compiles and packages the project, generating the `.war` file while **skipping tests**.

This **build stage** is only used to compile the application and produce the deployable artifact.

---

### 2. Runtime Stage (Tomcat Container)

```dockerfile
FROM tomcat:9-jdk17
```

* Uses a lightweight image containing **Tomcat 9** and **Java 17**.
* This is the runtime environment where the application will actually run.

```dockerfile
ENV CATALINA_HOME=/usr/local/tomcat \
    POSTGRES_HOST=postgres \
    POSTGRES_PORT=5433 \
    POSTGRES_DB=yourwaytoitaly \
    POSTGRES_USER=ywti \
    POSTGRES_PASSWORD=ywti_password
```

* Sets environment variables for:

  * `CATALINA_HOME`: Tomcat installation directory.
  * Database connection parameters: host, port, name, user, password.
* These will be injected later into the `context.xml` file.

```dockerfile
RUN apt-get update && apt-get install -y unzip && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf ${CATALINA_HOME}/webapps/*
```

* Installs `unzip` (needed to extract the WAR file).
* Cleans up APT cache to reduce image size.
* Removes default webapps (like `ROOT`, `docs`, etc.) from Tomcat.

```dockerfile
COPY --from=builder /build/target/ywti-wa2021-1.0-SNAPSHOT.war /tmp/ROOT.war
```

* Copies the `.war` file produced in the **builder** stage into `/tmp/ROOT.war` inside the runtime image.

```dockerfile
RUN mkdir -p ${CATALINA_HOME}/webapps/ROOT && \
    cd ${CATALINA_HOME}/webapps/ROOT && \
    unzip -q /tmp/ROOT.war && \
    rm /tmp/ROOT.war
```

* Creates the `ROOT` application directory.
* Unzips the WAR content into `webapps/ROOT`, so the application is accessible as the root context `/`.
* Removes the temporary WAR file.

```dockerfile
RUN echo '#!/bin/bash\nset -e\n\
for var in POSTGRES_HOST POSTGRES_PORT POSTGRES_DB POSTGRES_USER POSTGRES_PASSWORD; do\n\
  sed -i "s|\${${var}}|${!var}|g" ${CATALINA_HOME}/webapps/ROOT/META-INF/context.xml\n\
done\n\
exec catalina.sh run' > /startup.sh && chmod +x /startup.sh
```

* Creates a startup script `/startup.sh` that:

  * Replaces placeholders like `${POSTGRES_HOST}` in `META-INF/context.xml` with actual env values.
  * Starts Tomcat (`catalina.sh run`).
* Marks the script as executable.

```dockerfile
EXPOSE 8080
```

* Documents that the container listens on port **8080** (Tomcat default).

```dockerfile
CMD ["/startup.sh"]
```

* Defines the command executed when the container starts:

  * Runs the startup script, injects DB values, then launches Tomcat.

---

## Manually Build a Docker Image

From your project root (where the `Dockerfile` is located):

```bash
cd C:\Path\To\YourProject

# Build the Docker image
docker build -t YourUserName/YourProjectName:1.0 .
```

You can update the tag (`1.0`, `1.1`, etc.) for each new version:

```bash
docker build -t YourUserName/YourProjectName:1.1 .
```

---

## Push the Docker Image to Docker Hub

### 1. Create a Docker Hub Account

* Go to [https://hub.docker.com](https://hub.docker.com)
* Create an account and log in.

### 2. Push the Image

```bash
# Log in to Docker Hub
docker login

# Push a specific version
docker push YourUserName/YourProjectName:1.0

# Tag the image as "latest" (most stable version)
docker tag YourUserName/YourProjectName:1.0 YourUserName/YourProjectName:latest

# Push the "latest" tag
docker push YourUserName/YourProjectName:latest
```

---

## Test the Image Locally with Docker Compose

Create a `docker-compose.yml` file in your project root:

```yaml
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: yourwaytoitaly
      POSTGRES_USER: ywti
      POSTGRES_PASSWORD: ywti_password
      PGPORT: 5433
    ports:
      - "5433:5433"
    command: -p 5433
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./src/database/CreateTables.sql:/docker-entrypoint-initdb.d/01-schema.sql
      - ./src/database/INSERT.sql:/docker-entrypoint-initdb.d/02-data.sql
    restart: unless-stopped

  app:
    build: .
    image: gyro0/ywti:latest
    depends_on:
      postgres:
        condition: service_started
    environment:
      POSTGRES_HOST: postgres
      POSTGRES_PORT: 5433
      POSTGRES_DB: yourwaytoitaly
      POSTGRES_USER: ywti
      POSTGRES_PASSWORD: ywti_password
    ports:
      - "8081:8080"
    restart: unless-stopped

volumes:
  postgres_data:
```

* `postgres` service:

  * Runs PostgreSQL 15.
  * Exposes it on port **5433**.
  * Initializes DB schema and data from SQL files.
* `app` service:

  * Uses the image `gyro0/ywti:latest` (built previously or built from `build: .`).
  * Connects to the `postgres` service using the environment variables.
  * Maps container port `8080` (Tomcat) to host port `8081`, just because we are already running Jenkins on port `8080`.

---

## Run the Application with Docker Compose

From the folder containing `docker-compose.yml`:

```bash
# Start all services in detached mode
docker-compose up -d

# Follow logs of all services
docker-compose logs -f

# Check the status of services
docker-compose ps
```

Open the application in your browser:

```bash
start http://localhost:8081/html/index.html
```

> Note: We mapped `8081:8080`, so the app is available on port **8081** on the host.

To stop and clean up:

```bash
# Stop containers
docker-compose down

# Stop containers and remove volumes (wipe all data)
docker-compose down -v
```

