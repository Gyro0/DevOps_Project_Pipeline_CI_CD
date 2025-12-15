
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

The pipeline consists of 10 automated stages:

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
        DOCKER_IMAGE = 'gyro0/ywti'
        DOCKER_TAG = "2.0"
        GIT_BRANCH = "develop"
    }
    
    stages {
        stage('1. Cloner le repo') {
            when {
                anyOf {
                    branch 'develop'
                }
            }
            steps {
                script{
                    if (isUnix()){
                        sh 'git config --global core.autocrlf input'
                    } 
                }

                echo "Clonage du repository depuis GitHub (branche: ${env.GIT_BRANCH})..."
                checkout scm
            }
        }
        
        stage('2. Compiler le projet') {
            steps {
                echo 'Compilation du projet Maven...'
                script{
                    if (isUnix()){
                        sh 'mvn clean compile'
                    } 
                    else{
                        bat 'mvn clean compile'
                    }
                }
            }
        }
        
        stage('3. Lancer les tests unitaires') {
            steps {
                echo 'Execution des tests unitaires...'
                script{
                    if (isUnix()){
                        sh 'mvn test'
                    } 
                    else{
                        bat 'mvn test'
                    }
                }
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('4. Generer le package WAR/JAR') {
            steps {
                echo 'Creation du package WAR...'
                script{
                    if (isUnix()){
                        sh 'mvn package -DskipTests'
                    }
                    else{
                        bat 'mvn package -DskipTests'
                    } 
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: '**/target/*.war', allowEmptyArchive: true, fingerprint: true
                }
            }
        }
        
        stage('5. Analyse SonarQube') {
            steps {
                echo 'Lancement de l\'analyse SonarQube...'
                withSonarQubeEnv('SonarQube') {
                    script{
                        if (isUnix()){
                            sh 'mvn sonar:sonar'
                        } 
                        else{
                            bat 'mvn sonar:sonar'
                        }
                    }
                }
            }
        }
        
        stage('6. Quality Gate') {
            steps {
                echo 'Verification du Quality Gate...'
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('7. Build Docker Image') {
            steps {
                echo 'Construction de l\'image Docker...'
                script {
                    if (isUnix()) {
                        sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                        sh "docker rmi ${DOCKER_IMAGE}:latest || exit 0"
                        sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                    } else {
                        bat "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                        bat "docker rmi ${DOCKER_IMAGE}:latest || exit 0"
                        bat "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                    }
                }
            }
        }
        
        stage('8. Push Docker Image') {
            steps {
                echo 'Push de l\'image vers Docker Hub...'
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        if (isUnix()) {
                            sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                            sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                            sh "docker push ${DOCKER_IMAGE}:latest"
                        } else {
                            bat 'echo %DOCKER_PASS% | docker login -u %DOCKER_USER% --password-stdin'
                            bat "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                            bat "docker push ${DOCKER_IMAGE}:latest"
                        }
                    }
                }
            }
        }
        
        stage('9. Deploy to Kubernetes') {
            steps {
                echo 'Deploiement de l\'application sur Kubernetes...'
                script {
                    if (isUnix()) {
                        sh 'cd k8s && ./deploy.sh'
                    } else {
                        bat 'cd k8s && powershell -ExecutionPolicy Bypass -File deploy.ps1'
                    }
                }
            }
        }
        
        stage('10. Deploy Monitoring Stack') {
            steps {
                echo 'Deploiement de Prometheus et Grafana...'
                script {
                    if (isUnix()) {
                        sh 'cd k8s/monitoring && ./deploy.sh'
                    } else {
                        bat 'cd k8s\\monitoring && powershell -ExecutionPolicy Bypass -File deploy.ps1'
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo '==============Le Pipeline est execute avec succes!=============='
            echo "Branche: ${GIT_BRANCH}"
            echo "Image Docker publiee: ${DOCKER_IMAGE}:${DOCKER_TAG}"
            echo "Application deployee sur: http://ywti.local/html/index.html"
            echo "Grafana: http://localhost:30300"
            echo "Prometheus: http://localhost:30090"
        }
        failure {
            echo '==============Le pipeline a echoue.=============='
        }
        always {
            echo "workspace: ${WORKSPACE}"
            echo 'Cleaning workspace...'
            cleanWs()
        }
    }
}
```

### 2.2 Pipeline Configuration Explained

#### Tools Section

```groovy
tools {
    maven 'Maven-3.9.11'
    jdk 'JDK-17'
}
```

**Purpose:** Specifies which Maven and JDK versions Jenkins should use. These must be pre-configured in Jenkins under **Manage Jenkins > Global Tool Configuration**.

#### Environment Variables

```groovy
environment {
    MAVEN_OPTS = '-Xmx1024m'           // Allocates 1GB RAM to Maven
    SCANNER_HOME = tool 'SonarScanner' // SonarQube scanner location
    DOCKER_IMAGE = 'gyro0/ywti'        // Docker Hub repository
    DOCKER_TAG = "2.0"                 // Image version tag
    GIT_BRANCH = "develop"             // Target branch for deployment
}
```

**Why these variables?**
- `MAVEN_OPTS`: Prevents OutOfMemoryError during large builds
- `SCANNER_HOME`: Required by SonarQube Maven plugin
- `DOCKER_IMAGE` & `DOCKER_TAG`: Avoid hardcoding values in multiple stages

### 2.3 Stage-by-Stage Breakdown

#### Stage 1: Clone Repository

```groovy
when {
    anyOf {
        branch 'develop'
    }
}
```

**Purpose:** Only runs the pipeline when code is pushed to the `develop` branch.

**Cross-platform handling:**
```groovy
if (isUnix()){
    sh 'git config --global core.autocrlf input'
}
```

This prevents Windows line-ending issues (`\r\n`) in Unix/Linux environments.

#### Stage 2: Compile Project

```groovy
script{
    if (isUnix()){
        sh 'mvn clean compile'
    } 
    else{
        bat 'mvn clean compile'
    }
}
```

**Purpose:** Compiles Java source code without running tests.

**Cross-platform:**
- `sh` for Linux/macOS
- `bat` for Windows

#### Stage 3: Run Unit Tests

```groovy
post {
    always {
        junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
    }
}
```

**Purpose:** Executes JUnit tests and publishes results to Jenkins dashboard.

**Benefits:**
- Test trend graphs
- Failure notifications
- Historical test data

#### Stage 4: Package WAR

```groovy
bat 'mvn package -DskipTests'
```

**Purpose:** Creates deployable WAR file (skips tests since they already ran in Stage 3).

```groovy
post {
    success {
        archiveArtifacts artifacts: '**/target/*.war', fingerprint: true
    }
}
```

**Artifact Archiving:** Stores the WAR file in Jenkins for download/deployment.

#### Stage 5: SonarQube Analysis

```groovy
withSonarQubeEnv('SonarQube') {
    bat 'mvn sonar:sonar'
}
```

**Purpose:** Sends code to SonarQube for quality analysis.

**What `withSonarQubeEnv` does:**
- Injects SonarQube server URL
- Adds authentication token automatically
- Configures Maven plugin parameters

#### Stage 6: Quality Gate

```groovy
timeout(time: 5, unit: 'MINUTES') {
    waitForQualityGate abortPipeline: true
}
```

**Purpose:** Waits for SonarQube to finish analysis and checks if code passes quality standards.

**Behavior:**
- If Quality Gate **PASSES**: Pipeline continues
- If Quality Gate **FAILS**: Pipeline aborts immediately
- If no response in 5 minutes: Pipeline times out

#### Stage 7: Build Docker Image

```groovy
bat "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
bat "docker rmi ${DOCKER_IMAGE}:latest || exit 0"
bat "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
```

**Steps:**
1. Builds image with version tag (e.g., `gyro0/ywti:2.0`)
2. Removes old `latest` tag (ignores error if doesn't exist)
3. Tags new image as `latest`

**Why two tags?**
- `2.0`: Specific version for rollback capability
- `latest`: Always points to newest version

#### Stage 8: Push Docker Image

```groovy
withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
    bat 'echo %DOCKER_PASS% | docker login -u %DOCKER_USER% --password-stdin'
    bat "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
    bat "docker push ${DOCKER_IMAGE}:latest"
}
```

**Security:** Credentials are stored securely in Jenkins and never exposed in logs.

**Pushes:**
- `gyro0/ywti:2.0`
- `gyro0/ywti:latest`

#### Stage 9: Deploy to Kubernetes

```groovy
bat 'cd k8s && powershell -ExecutionPolicy Bypass -File deploy.ps1'
```

**Purpose:** Runs the Kubernetes deployment script (covered in Step 5).

**What it deploys:**
- PostgreSQL database (1 pod)
- YWTI application (2 pods)
- Services and Ingress

#### Stage 10: Deploy Monitoring Stack

```groovy
bat 'cd k8s\\monitoring && powershell -ExecutionPolicy Bypass -File deploy.ps1'
```

**Purpose:** Deploys Prometheus and Grafana for monitoring (covered in Step 6).

### 2.4 Post-Pipeline Actions

```groovy
post {
    success {
        echo "Application deployee sur: http://ywti.local/html/index.html"
        echo "Grafana: http://localhost:30300"
        echo "Prometheus: http://localhost:30090"
    }
    failure {
        echo '==============Le pipeline a echoue.=============='
    }
    always {
        cleanWs()  // Deletes workspace to save disk space
    }
}
```

**Cleanup:** The `cleanWs()` command prevents disk space issues by removing build artifacts after each run.

### 2.5 Pipeline Stage Summary

| Stage | Description | Command | Duration |
|-------|-------------|---------|----------|
| 1 | Clone repository from GitHub | `checkout scm` | 10s |
| 2 | Compile Java source code | `mvn clean compile` | 30s |
| 3 | Run JUnit tests | `mvn test` | 45s |
| 4 | Package WAR file | `mvn package` | 20s |
| 5 | SonarQube code analysis | `mvn sonar:sonar` | 60s |
| 6 | Wait for Quality Gate result | Webhook callback | 30s |
| 7 | Build Docker image | `docker build` | 90s |
| 8 | Push image to Docker Hub | `docker push` | 120s |
| 9 | Deploy to Kubernetes cluster | PowerShell script | 60s |
| 10 | Deploy monitoring stack | PowerShell script | 45s |

---

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


# Step 5: Kubernetes – Deployment

Kubernetes is a container orchestration platform that automates the deployment, scaling, and management of containerized applications. In this step, we deploy our JEE application and PostgreSQL database on a local Kubernetes cluster provided by Docker Desktop.

---

## 5.1 What is Kubernetes?

Kubernetes manages containers at scale by:
- Automatically restarting failed containers
- Load balancing traffic across multiple instances
- Providing service discovery and DNS
- Managing configuration and secrets
- Enabling zero-downtime deployments

### Architecture Overview

```
┌──────────────────────── Kubernetes Cluster ────────────────────────┐
│                                                                     │
│  ┌─────────────────── Control Plane ──────────────────┐           │
│  │  - API Server (receives kubectl commands)          │           │
│  │  - Scheduler (assigns pods to nodes)               │           │
│  │  - Controller Manager (maintains desired state)    │           │
│  └─────────────────────────────────────────────────────┘           │
│                                                                     │
│  ┌─────────────────── Worker Node ────────────────────────────┐   │
│  │                                                             │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐                 │   │
│  │  │   Pod    │  │   Pod    │  │   Pod    │                 │   │
│  │  │ ywti-app │  │ ywti-app │  │ postgres │                 │   │
│  │  └──────────┘  └──────────┘  └──────────┘                 │   │
│  │                                                             │   │
│  │  kubelet (node agent)    kube-proxy (networking)           │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### Key Kubernetes Objects

| Object | Description | Our Usage |
|--------|-------------|-----------|
| **Pod** | Smallest deployable unit containing one or more containers | 1 postgres pod + 2 ywti-app pods |
| **Deployment** | Manages replicas of pods and rolling updates | One for database, one for application |
| **Service** | Stable network endpoint for accessing pods | ClusterIP for internal communication |
| **Ingress** | HTTP routing and load balancing | Routes `ywti.local` to our application |
| **Job** | One-time task that runs to completion | Database initialization |

---

## 5.2 Enable Kubernetes in Docker Desktop

Docker Desktop includes a built-in single-node Kubernetes cluster, perfect for local development.

### Steps:

1. Open **Docker Desktop**
2. Click the **Settings** icon (gear icon in top-right)
3. Navigate to **Kubernetes** in the left sidebar
4. Check **Enable Kubernetes**
5. Click **Apply & Restart**
6. Wait 2-5 minutes until status shows **Kubernetes is running**

### Verify Installation

```powershell
# Check current context
kubectl config current-context
# Expected output: docker-desktop

# Check cluster nodes
kubectl get nodes
# Expected output:
# NAME             STATUS   ROLES           AGE   VERSION
# docker-desktop   Ready    control-plane   5m    v1.29.1

# Verify cluster connectivity
kubectl cluster-info
# Expected: Kubernetes control plane is running at https://kubernetes.docker.internal:6443
```

---

## 5.3 Project Structure

All Kubernetes manifests are organized in the k8s directory:

```
project/
├── k8s/
│   ├── deployment.yaml       # Defines postgres + ywti-app pods
│   ├── service.yaml          # Network access to pods
│   ├── ingress.yaml          # HTTP routing rules
│   ├── init-db-job.yaml      # Database initialization
│   └── deploy.ps1            # Automation script
├── src/
├── Dockerfile
├── docker-compose.yml
└── pom.xml
```

Create the directory:

```powershell
cd C:\Users\Gyro\Desktop\project
mkdir k8s
cd k8s
```

---

## 5.4 Kubernetes Manifests

### 5.4.1 Deployments: `deployment.yaml`

This file defines two separate deployments: one for PostgreSQL (1 replica) and one for the YWTI application (2 replicas for high availability).

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15
        ports:
        - containerPort: 5433
        env:
        - name: POSTGRES_DB
          value: yourwaytoitaly
        - name: POSTGRES_USER
          value: ywti
        - name: POSTGRES_PASSWORD
          value: ywti_password
        - name: PGPORT
          value: "5433"
        command: ["docker-entrypoint.sh"]
        args: ["-p", "5433"]

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ywti-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ywti-app
  template:
    metadata:
      labels:
        app: ywti-app
    spec:
      containers:
      - name: ywti-app
        image: gyro0/ywti:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
        env:
        - name: POSTGRES_HOST
          value: postgres
        - name: POSTGRES_PORT
          value: "5433"
        - name: POSTGRES_DB
          value: yourwaytoitaly
        - name: POSTGRES_USER
          value: ywti
        - name: POSTGRES_PASSWORD
          value: ywti_password
```

**Explanation:**

**PostgreSQL Deployment:**
- `replicas: 1` - Single database instance (databases are stateful, we avoid multiple writers)
- `image: postgres:15` - Official PostgreSQL 15 Docker image
- `PGPORT: "5433"` - Runs on port 5433 instead of default 5432 to avoid conflicts
- `command` and `args` - Configures PostgreSQL to listen on port 5433

**YWTI Application Deployment:**
- `replicas: 2` - Two instances for high availability and load balancing
- `image: gyro0/ywti:latest` - Our Docker image from Docker Hub
- `imagePullPolicy: IfNotPresent` - Uses local image if available (faster deployment)
- Environment variables - Database connection parameters that connect to the `postgres` service

**Why 2 replicas for the app?**
- If one pod crashes, the other continues serving requests
- Kubernetes automatically load balances traffic between both pods
- Simulates a production environment with redundancy

---

### 5.4.2 Services: `service.yaml`

Services provide stable network addresses to access pods. Even if pods are recreated with new IP addresses, the service DNS name remains constant.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  selector:
    app: postgres
  ports:
  - port: 5433
    targetPort: 5433

---
apiVersion: v1
kind: Service
metadata:
  name: ywti-app
spec:
  type: ClusterIP
  selector:
    app: ywti-app
  ports:
  - port: 80
    targetPort: 8080
```

**Explanation:**

**Service Types:**

| Type | Accessibility | Use Case |
|------|---------------|----------|
| **ClusterIP** | Internal only (default) | Database, backend services |
| **NodePort** | External via fixed port | Development/testing |
| **LoadBalancer** | External via cloud provider | Production (AWS, GCP, Azure) |

**PostgreSQL Service:**
- No `type` specified, defaults to `ClusterIP`
- Only accessible inside the cluster
- Other pods reach it using DNS name `postgres:5433`
- This provides service discovery - applications don't need to know pod IPs

**YWTI Application Service:**
- `type: ClusterIP` - Internal only (external access via Ingress)
- `port: 80` - Service listens on port 80
- `targetPort: 8080` - Forwards to container port 8080 (Tomcat)
- The Ingress controller routes external traffic to this service

**Why use DNS names instead of IP addresses?**

Instead of hardcoding IP addresses like `10.96.157.174`, we use the service name `postgres`. Kubernetes provides automatic DNS resolution:

```
POSTGRES_HOST=postgres → Resolves to postgres service IP automatically
```

This way, even if pod IPs change, the service name remains constant.

---

### 5.4.3 Ingress: `ingress.yaml`

The Ingress acts as an HTTP router that directs traffic based on hostnames and paths.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ywti-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: ywti.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ywti-app
            port:
              number: 80
```

**Explanation:**

**What is an Ingress?**

An Ingress is like a reverse proxy (similar to NGINX or Apache) that routes HTTP requests to the correct service based on rules.

**Traffic Flow:**

```
Browser (http://ywti.local)
    ↓
Hosts file (ywti.local → 127.0.0.1)
    ↓
Ingress Controller (NGINX on port 80)
    ↓
Ingress rules (host=ywti.local → service ywti-app:80)
    ↓
Service ywti-app (load balances to 2 pods)
    ↓
One of the ywti-app pods
```

**Configuration Parameters:**
- `ingressClassName: nginx` - Uses NGINX Ingress Controller
- `host: ywti.local` - Only requests to this hostname are matched
- `path: /` - All URLs under `/` are routed to the backend
- `backend.service.name: ywti-app` - Traffic goes to the `ywti-app` service
- `backend.service.port.number: 80` - Service port to target

**Benefits of Ingress vs NodePort:**
- Clean URL (`http://ywti.local` instead of `http://localhost:30080`)
- Standard port 80 (no need to specify port in URL)
- Supports SSL/TLS certificates for HTTPS
- Can host multiple applications on different hostnames

---

### 5.4.4 Database Initialization: `init-db-job.yaml`

A Kubernetes Job is a one-time task that runs until completion. We use it to create database tables and insert sample data.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: init-db
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: init-db
        image: postgres:15
        command:
        - /bin/bash
        - -c
        - |
          cat <<'EOF' | psql -h postgres -p 5433 -U ywti -d yourwaytoitaly
          CREATE TABLE IF NOT EXISTS City (
           ID_city SERIAL PRIMARY KEY,
           name VARCHAR(100) NOT NULL
          );

          CREATE TABLE IF NOT EXISTS Type_advertisement (
           ID_type SERIAL PRIMARY KEY,
           type VARCHAR(100) NOT NULL
          );

          CREATE TABLE IF NOT EXISTS Company (
           email_c VARCHAR(100) PRIMARY KEY,
           name_c VARCHAR(100) NOT NULL,
           phone_number VARCHAR(100) NOT NULL,
           address VARCHAR(200) NOT NULL,
           password VARCHAR(100) NOT NULL,
           ID_city INT NOT NULL,
           FOREIGN KEY (ID_city) REFERENCES City (ID_city)
          );

          CREATE TABLE IF NOT EXISTS Tourist (
           email_t VARCHAR(100) PRIMARY KEY,
           surname VARCHAR(100) NOT NULL,
           name VARCHAR(100) NOT NULL,
           birth_date DATE NOT NULL,
           phone_number VARCHAR(100) NOT NULL,
           address VARCHAR(200) NOT NULL,
           password VARCHAR(100) NOT NULL,
           ID_city INT NOT NULL,
           FOREIGN KEY (ID_city) REFERENCES City (ID_city)
          );

          CREATE TABLE IF NOT EXISTS Advertisement (
           ID_advertisement SERIAL PRIMARY KEY,
           title VARCHAR(200) NOT NULL,
           description VARCHAR(10000) NOT NULL,
           score INT NOT NULL,
           price INT NOT NULL,
           num_tot_item INT NOT NULL,
           date_start DATE NOT NULL,
           date_end DATE NOT NULL,
           time_start TIME NOT NULL,
           time_end TIME NOT NULL,
           email_c VARCHAR(100) NOT NULL,
           ID_type INT NOT NULL,
           FOREIGN KEY (email_c) REFERENCES Company (email_c),
           FOREIGN KEY (ID_type) REFERENCES Type_advertisement (ID_type)
          );

          CREATE TABLE IF NOT EXISTS Tourist_Advertisement (
           email_t VARCHAR(100) NOT NULL,
           ID_advertisement INT NOT NULL,
           num_items INT NOT NULL,
           rating INT,
           PRIMARY KEY (email_t, ID_advertisement),
           FOREIGN KEY (email_t) REFERENCES Tourist (email_t),
           FOREIGN KEY (ID_advertisement) REFERENCES Advertisement (ID_advertisement)
          );

          CREATE TABLE IF NOT EXISTS Review (
           ID_review SERIAL PRIMARY KEY,
           title VARCHAR(100) NOT NULL,
           description VARCHAR(1000) NOT NULL,
           email_t VARCHAR(100) NOT NULL,
           ID_advertisement INT NOT NULL,
           FOREIGN KEY (email_t) REFERENCES Tourist (email_t),
           FOREIGN KEY (ID_advertisement) REFERENCES Advertisement (ID_advertisement)
          );

          CREATE TABLE IF NOT EXISTS Image (
           ID_image SERIAL PRIMARY KEY,
           image BYTEA NOT NULL,
           ID_advertisement INT NOT NULL,
           FOREIGN KEY (ID_advertisement) REFERENCES Advertisement (ID_advertisement)
          );
          EOF

          # Insert data only if tables are empty
          COUNT=$(psql -h postgres -p 5433 -U ywti -d yourwaytoitaly -t -c "SELECT COUNT(*) FROM City;")
          if [ "$COUNT" -eq 0 ]; then
            cat <<'EOF' | psql -h postgres -p 5433 -U ywti -d yourwaytoitaly
            INSERT INTO City (name) VALUES ('Abano Terme'), ('Affi'), ('Agugliaro'), ('Altavilla Vicentina'), ('Altissimo');
            INSERT INTO Type_advertisement (type) VALUES ('Museum'), ('Tour'), ('Restaurant'), ('Beach'), ('Park');
            INSERT INTO Company (email_c, name_c, phone_number, address, password, ID_city) VALUES ('company1@example.com', 'Tourism Venice', '+39 041 1234567', 'Via Roma 1, Venice', 'password123', 1);
            INSERT INTO Tourist (email_t, surname, name, birth_date, phone_number, address, password, ID_city) VALUES ('tourist1@example.com', 'Rossi', 'Mario', '1990-01-15', '+39 340 1234567', 'Via Dante 10, Padua', 'password123', 1);
          EOF
            echo "Database initialized successfully!"
          else
            echo "Database already initialized, skipping data insertion."
          fi
        env:
        - name: PGPASSWORD
          value: ywti_password
  backoffLimit: 3
```

**Explanation:**

**Why use a Job instead of manual SQL execution?**

- **Automatic** - Runs during deployment without manual intervention
- **Idempotent** - Can be re-run safely (thanks to `IF NOT EXISTS`)
- **Logged** - Kubernetes stores logs for debugging with `kubectl logs`
- **Repeatable** - Same initialization every time

**How it works:**

1. Creates a temporary pod using the `postgres:15` image
2. Connects to the `postgres` service using `-h postgres -p 5433`
3. Runs SQL commands to create tables (if they don't exist)
4. Checks if `City` table is empty
5. If empty, inserts sample data
6. Pod completes and stops

**Configuration Parameters:**
- `restartPolicy: Never` - Don't restart if the job fails
- `backoffLimit: 3` - Retry up to 3 times if it fails
- `PGPASSWORD` environment variable - Authenticates to PostgreSQL without password prompt
- `CREATE TABLE IF NOT EXISTS` - Prevents errors if tables already exist
- `COUNT` check - Only inserts data once to avoid duplicates

---

### 5.4.5 Deployment Script: `deploy.ps1`

To avoid typing multiple `kubectl` commands, we created a PowerShell script that automates the entire deployment process.

```powershell
#script de deploiement Kubernetes

Write-Host "=== Deploiement sur Kubernetes (Docker Desktop) ===" -ForegroundColor Cyan

# Verifier le contexte
$context = kubectl config current-context
if ($context -ne "docker-desktop") {
    Write-Host "Erreur: Veuillez basculer vers le contexte docker-desktop" -ForegroundColor Red
    kubectl config use-context docker-desktop
    exit 1
}

Write-Host "Contexte actuel: $context" -ForegroundColor Green

# Appliquer tous les fichiers YAML
Write-Host "1. Deploiement des applications" -ForegroundColor Yellow
kubectl apply -f deployment.yaml

Write-Host "2. Creation des services" -ForegroundColor Yellow
kubectl apply -f service.yaml

Write-Host "3. Configuration de l'Ingress" -ForegroundColor Yellow
kubectl apply -f ingress.yaml

Write-Host "4. Attente du demarrage des pods" -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "5. Initialisation de la base de donnees" -ForegroundColor Yellow
kubectl delete job init-db 2>$null
kubectl apply -f init-db-job.yaml
kubectl wait --for=condition=complete job/init-db --timeout=10s

Write-Host "6. etat du cluster:" -ForegroundColor Green
kubectl get all

Write-Host "7. Ingress:" -ForegroundColor Green
kubectl get ingress

Write-Host "=== Deploiement termine ===" -ForegroundColor Cyan
Write-Host "Lien vers l'application:" -ForegroundColor Green
Write-Host "   http://ywti.local/html/index.html" -ForegroundColor Cyan
```

**Explanation:**

**What the script does (step-by-step):**

1. **Checks Kubernetes context** - Ensures we're using `docker-desktop` cluster
2. **Deploys applications** - Creates postgres and ywti-app pods
3. **Creates services** - Makes pods accessible via stable network addresses
4. **Configures Ingress** - Sets up HTTP routing rules
5. **Waits for pods** - Gives containers time to start (10 seconds)
6. **Initializes database** - Runs the init-db Job
   - Deletes old job first (if exists) with `2>$null` to suppress error messages
   - Waits for job completion with a 10-second timeout
7. **Shows cluster status** - Displays all Kubernetes resources
8. **Shows Ingress configuration** - Displays HTTP routing rules
9. **Prints access URL** - Shows how to reach the application

**Before using the script**, allow PowerShell script execution:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

---

## 5.5 Install NGINX Ingress Controller

The Ingress object is just configuration. We need an Ingress Controller (actual software) to process those rules. We use NGINX.

**Installation:**

```powershell
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.1/deploy/static/provider/cloud/deploy.yaml

# Wait for it to be ready (1-2 minutes)
kubectl wait --namespace ingress-nginx `
  --for=condition=ready pod `
  --selector=app.kubernetes.io/component=controller `
  --timeout=120s
```

**Verify Installation:**

```powershell
kubectl get svc -n ingress-nginx

# Expected output:
# NAME                                 TYPE           EXTERNAL-IP   PORT(S)
# ingress-nginx-controller             LoadBalancer   localhost     80:xxxxx/TCP,443:xxxxx/TCP
```

The `EXTERNAL-IP: localhost` confirms the Ingress Controller is accessible on `localhost:80`.

---

## 5.6 Deploy the Application

### Option 1: Using the Automation Script (Recommended)

```powershell
cd C:\Users\Gyro\Desktop\project\k8s
.\deploy.ps1
```

**Expected Output:**

```
=== Deploiement sur Kubernetes (Docker Desktop) ===
Contexte actuel: docker-desktop
1. Deploiement des applications
deployment.apps/postgres created
deployment.apps/ywti-app created

2. Creation des services
service/postgres created
service/ywti-app created

3. Configuration de l'Ingress
ingress.networking.k8s.io/ywti-ingress created

4. Attente du demarrage des pods

5. Initialisation de la base de donnees
job.batch/init-db created
job.batch/init-db condition met

6. etat du cluster:
NAME                            READY   STATUS      RESTARTS   AGE
pod/init-db-xxxxx               0/1     Completed   0          15s
pod/postgres-xxxxx              1/1     Running     0          25s
pod/ywti-app-xxxxx              1/1     Running     0          25s
pod/ywti-app-yyyyy              1/1     Running     0          25s

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
service/kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP        10m
service/postgres     ClusterIP   10.105.157.174   <none>        5433/TCP       20s
service/ywti-app     ClusterIP   10.109.12.134    <none>        80/TCP         20s

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/postgres   1/1     1            1           25s
deployment.apps/ywti-app   2/2     2            2           25s

7. Ingress:
NAME           CLASS   HOSTS        ADDRESS     PORTS   AGE
ywti-ingress   nginx   ywti.local   localhost   80      15s

=== Deploiement termine ===
Lien vers l'application:
   http://ywti.local/html/index.html
```

### Option 2: Manual Deployment (Step-by-Step)

```powershell
cd C:\Users\Gyro\Desktop\project\k8s

# Deploy workloads
kubectl apply -f deployment.yaml

# Create services
kubectl apply -f service.yaml

# Configure Ingress
kubectl apply -f ingress.yaml

# Wait for pods to start
Start-Sleep -Seconds 10

# Initialize database
kubectl apply -f init-db-job.yaml
kubectl wait --for=condition=complete job/init-db --timeout=60s

# Check cluster state
kubectl get all
kubectl get ingress
```

---

## 5.7 Verify the Deployment

### Check Pods

```powershell
kubectl get pods

# Expected output:
# NAME                        READY   STATUS      RESTARTS   AGE
# init-db-xxxxx               0/1     Completed   0          2m
# postgres-xxxxx              1/1     Running     0          3m
# ywti-app-xxxxx              1/1     Running     0          3m
# ywti-app-yyyyy              1/1     Running     0          3m
```

**Pod Status Meanings:**

| Status | Meaning |
|--------|---------|
| `Running` | Pod is healthy and working |
| `Completed` | Job finished successfully |
| `Pending` | Waiting for resources |
| `CrashLoopBackOff` | Pod keeps crashing |
| `Error` | Pod failed |

### Check Services

```powershell
kubectl get services

# Expected output:
# NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)     AGE
# kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP     10m
# postgres     ClusterIP   10.105.157.174   <none>        5433/TCP    5m
# ywti-app     ClusterIP   10.109.12.134    <none>        80/TCP      5m
```

### Check Ingress

```powershell
kubectl get ingress

# Expected output:
# NAME           CLASS   HOSTS        ADDRESS     PORTS   AGE
# ywti-ingress   nginx   ywti.local   localhost   80      5m
```

### Verify Database Initialization

```powershell
# Connect to PostgreSQL
kubectl exec -it deployment/postgres -- psql -U ywti -d yourwaytoitaly

# Inside PostgreSQL shell:
\dt                                      # List tables (should see 8 tables)
SELECT COUNT(*) FROM City;               # Should return 5
SELECT COUNT(*) FROM Type_advertisement; # Should return 5
\q                                       # Exit
```

---

## 5.8 Access the Application

### Configure Hosts File

To access the application via the custom hostname `ywti.local`, we need to add an entry to the hosts file.

**Step 1: Open Notepad as Administrator**

```powershell
notepad C:\Windows\System32\drivers\etc\hosts
```

**Step 2: Add this line at the end:**

```
127.0.0.1    ywti.local
```

**Step 3: Save and close**

### Test DNS Resolution

```powershell
ping ywti.local

# Expected output:
# Pinging ywti.local [127.0.0.1] with 32 bytes of data:
# Reply from 127.0.0.1: bytes=32 time<1ms TTL=128
```

### Open the Application

```powershell
start http://ywti.local/html/index.html
```

**Traffic Flow:**

```
Browser (http://ywti.local)
    ↓
Hosts file (ywti.local → 127.0.0.1)
    ↓
Ingress Controller NGINX (port 80)
    ↓
Ingress rule (routes to ywti-app service)
    ↓
Service ywti-app (load balances between 2 pods)
    ↓
One of the ywti-app pods
```

**Benefits:**
- Clean URL without port number
- Standard HTTP port (80)
- Production-like setup
- Ready for HTTPS with SSL certificates

---

## 5.9 Useful kubectl Commands

**Viewing Resources:**

```powershell
kubectl get pods                    # List all pods
kubectl get services                # List all services
kubectl get deployments             # List all deployments
kubectl get ingress                 # List ingress rules
kubectl get all                     # Overview of all resources
```

**Inspecting Resources:**

```powershell
kubectl describe pod <pod-name>     # Detailed pod information and events
kubectl logs <pod-name>             # View container logs
kubectl logs -f deployment/ywti-app # Follow logs in real-time
kubectl exec -it <pod-name> -- bash # Open shell inside pod
```

**Managing Deployments:**

```powershell
kubectl scale deployment ywti-app --replicas=3    # Change to 3 instances
kubectl rollout restart deployment/ywti-app       # Restart all pods
kubectl rollout status deployment/ywti-app        # Check rollout progress
kubectl rollout undo deployment/ywti-app          # Rollback to previous version
```

**Cleanup:**

```powershell
kubectl delete -f deployment.yaml   # Delete deployments
kubectl delete -f service.yaml      # Delete services
kubectl delete -f ingress.yaml      # Delete ingress
kubectl delete job init-db          # Delete job
```

---

# Step 6: Prometheus & Grafana – Monitoring

Monitoring is essential for maintaining application health and performance. In this step, we deploy Prometheus for metrics collection and Grafana for visualization.

---

## 6.1 Monitoring Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                    │
│                                                           │
│  ┌──────────────┐      ┌──────────────┐                │
│  │  YWTI App    │      │  PostgreSQL  │                │
│  │  (Pods)      │      │  (Pod)       │                │
│  └──────┬───────┘      └──────┬───────┘                │
│         │                     │                          │
│         │   Metrics           │                          │
│         └─────────────┬───────┘                          │
│                       │                                   │
│                ┌──────▼──────────┐                       │
│                │   Prometheus    │ Scrapes Metrics       │
│                │   (NodePort)    │                       │
│                └──────┬──────────┘                       │
│                       │                                   │
│                       │ Queries                           │
│                ┌──────▼──────────┐                       │
│                │    Grafana      │ Visualizes            │
│                │   (NodePort)    │                       │
│                └─────────────────┘                       │
└─────────────────────────────────────────────────────────┘
         │                           │
         │ http://localhost:30090    │ http://localhost:30300
         └───────────────────────────┘
```

### What We Monitor

| Metric           | Description                                      | Source   |
| ---------------- | ------------------------------------------------ | -------- |
| **CPU Usage**    | CPU consumption per pod (ywti-app, postgres)     | cAdvisor |
| **Memory Usage** | RAM consumption per pod                          | cAdvisor |
| **Pod Status**   | Running, pending, failed pods                    | Kubelet  |
| **Node Health**  | Kubernetes node status                           | Kubelet  |

---

## 6.2 Configure Prometheus

Prometheus scrapes metrics from the Kubernetes cAdvisor endpoint, which provides container-level statistics.

### File: prometheus-config.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s

    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']

      - job_name: 'kubernetes-cadvisor'
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        kubernetes_sd_configs:
        - role: node
        relabel_configs:
        - action: labelmap
          regex: __meta_kubernetes_node_label_(.+)
        - target_label: __address__
          replacement: kubernetes.default.svc:443
        - source_labels: [__meta_kubernetes_node_name]
          regex: (.+)
          target_label: __metrics_path__
          replacement: /api/v1/nodes/${1}/proxy/metrics/cadvisor
```

**Explanation:**
- `scrape_interval: 15s` - Prometheus collects metrics every 15 seconds
- `job_name: 'kubernetes-cadvisor'` - Scrapes container metrics from Kubernetes nodes
- `bearer_token_file` - Authenticates with Kubernetes API using the service account token
- `/metrics/cadvisor` - Endpoint exposing CPU/memory data from containers

---

### File: prometheus-deployment.yaml

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
  - apiGroups: [""]
    resources: ["nodes", "nodes/proxy", "nodes/metrics", "services", "endpoints", "pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
  - kind: ServiceAccount
    name: prometheus
    namespace: default

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      serviceAccountName: prometheus
      containers:
        - name: prometheus
          image: prom/prometheus:latest
          args:
            - '--config.file=/etc/prometheus/prometheus.yml'
          ports:
            - containerPort: 9090
          volumeMounts:
            - name: config-volume
              mountPath: /etc/prometheus
      volumes:
        - name: config-volume
          configMap:
            name: prometheus-config

---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
spec:
  type: NodePort
  selector:
    app: prometheus
  ports:
    - port: 9090
      targetPort: 9090
      nodePort: 30090
```

**Explanation:**
- **ServiceAccount** - Allows Prometheus to access Kubernetes API
- **ClusterRole** - Grants permissions to read nodes, pods, and metrics
- **ClusterRoleBinding** - Binds the role to the service account
- **Deployment** - Runs Prometheus in a pod with the configuration mounted
- **NodePort Service** - Exposes Prometheus on `http://localhost:30090`

---

## 6.3 Configure Grafana

Grafana needs to know where to fetch data from (Prometheus) and which dashboards to display.

### File: grafana-provisioning.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
data:
  datasources.yaml: |
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      access: proxy
      url: http://prometheus:9090
      isDefault: true
      editable: false
      uid: prometheus
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards-provider
data:
  dashboards.yaml: |
    apiVersion: 1
    providers:
    - name: 'Default'
      orgId: 1
      folder: ''
      type: file
      disableDeletion: false
      updateIntervalSeconds: 10
      allowUiUpdates: true
      options:
        path: /var/lib/grafana/dashboards
```

**Explanation:**
- `url: http://prometheus:9090` - Grafana queries Prometheus using Kubernetes internal DNS
- `uid: prometheus` - Used in dashboard JSON to reference this data source
- `path: /var/lib/grafana/dashboards` - Where pre-configured dashboards are loaded from

---

### File: grafana-dashboard.yaml

This ConfigMap contains a complete dashboard JSON that automatically appears in Grafana.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboard
data:
  ywti-dashboard.json: |
    {
      "title": "YWTI Application Monitoring",
      "panels": [
        {
          "title": "CPU Usage by Pod",
          "targets": [
            {
              "expr": "sum(rate(container_cpu_usage_seconds_total{pod=~\"ywti-app.*|postgres.*\", container!=\"POD\"}[5m])) by (pod)",
              "legendFormat": "{{pod}}"
            }
          ],
          "type": "timeseries"
        },
        {
          "title": "Memory Usage by Pod",
          "targets": [
            {
              "expr": "sum(container_memory_usage_bytes{pod=~\"ywti-app.*|postgres.*\", container!=\"POD\"}) by (pod)",
              "legendFormat": "{{pod}}"
            }
          ],
          "type": "timeseries"
        }
      ]
    }
```

**Prometheus Queries Explained:**

| Query | Description |
|-------|-------------|
| `sum(rate(container_cpu_usage_seconds_total{pod=~"ywti-app.*\|postgres.*", container!="POD"}[5m])) by (pod)` | Calculates CPU usage rate over 5 minutes for ywti-app and postgres pods |
| `sum(container_memory_usage_bytes{pod=~"ywti-app.*\|postgres.*", container!="POD"}) by (pod)` | Shows current memory usage for those pods |

---

### File: grafana-deployment.yaml

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: grafana-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "admin"
        - name: GF_PATHS_PROVISIONING
          value: /etc/grafana/provisioning
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana
        - name: grafana-datasources
          mountPath: /etc/grafana/provisioning/datasources
        - name: grafana-dashboards-provider
          mountPath: /etc/grafana/provisioning/dashboards
        - name: grafana-dashboard
          mountPath: /var/lib/grafana/dashboards
      volumes:
      - name: grafana-storage
        persistentVolumeClaim:
          claimName: grafana-pvc
      - name: grafana-datasources
        configMap:
          name: grafana-datasources
      - name: grafana-dashboards-provider
        configMap:
          name: grafana-dashboards-provider
      - name: grafana-dashboard
        configMap:
          name: grafana-dashboard
---
apiVersion: v1
kind: Service
metadata:
  name: grafana
spec:
  type: NodePort
  ports:
  - port: 3000
    targetPort: 3000
    nodePort: 30300
  selector:
    app: grafana
```

**Explanation:**
- **PersistentVolumeClaim** - Stores Grafana data persistently (survives pod restarts)
- **Volume Mounts:**
  - `grafana-datasources` - Prometheus connection configuration
  - `grafana-dashboards-provider` - Dashboard auto-loading configuration
  - `grafana-dashboard` - Pre-built dashboard JSON
- **NodePort 30300** - Access Grafana at `http://localhost:30300`

---

## 6.4 Deployment Script

### File: deploy.ps1

```powershell
Write-Host "=== Deploiement Des Services De Monitoring ===" -ForegroundColor Cyan

$context = kubectl config current-context
if ($context -ne "docker-desktop") {
    Write-Host "ERREUR: Contexte incorrect. Basculement vers docker-desktop..." -ForegroundColor Red
    kubectl config use-context docker-desktop
}

Write-Host "Contexte actuel: $context" -ForegroundColor Green

# Deploy Prometheus
Write-Host "1. Deploiement de Prometheus" -ForegroundColor Yellow
kubectl apply -f prometheus-config.yaml
kubectl apply -f prometheus-deployment.yaml

# Deploy Grafana with provisioning
Write-Host "2. Deploiement de Grafana avec provisioning" -ForegroundColor Yellow
kubectl apply -f grafana-provisioning.yaml
kubectl apply -f grafana-dashboard.yaml
kubectl apply -f grafana-deployment.yaml

Write-Host "3. Attente du demarrage..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=prometheus --timeout=180s
kubectl wait --for=condition=ready pod -l app=grafana --timeout=180s

Write-Host "=== Deploiement termine ===" -ForegroundColor Green
Write-Host "Prometheus: http://localhost:30090" -ForegroundColor Cyan
Write-Host "Grafana: http://localhost:30300 (admin/admin)" -ForegroundColor Cyan
Write-Host "Dashboard 'YWTI Application Monitoring' disponible!" -ForegroundColor Green
```

**Explanation:**

1. Verifies Kubernetes context is `docker-desktop`
2. Deploys Prometheus configuration and pods
3. Deploys Grafana with auto-provisioned datasources and dashboards
4. Waits for pods to be ready (maximum 3 minutes)
5. Prints access URLs

---

## 6.5 Deploy Monitoring Stack

### Manual Deployment

```powershell
cd C:\Users\Gyro\Desktop\project\k8s\monitoring

# Deploy Prometheus
kubectl apply -f prometheus-config.yaml
kubectl apply -f prometheus-deployment.yaml

# Deploy Grafana
kubectl apply -f grafana-provisioning.yaml
kubectl apply -f grafana-dashboard.yaml
kubectl apply -f grafana-deployment.yaml

# Check status
kubectl get pods -l app=prometheus
kubectl get pods -l app=grafana
```

### Automated Deployment

```powershell
cd C:\Users\Gyro\Desktop\project\k8s\monitoring
powershell -ExecutionPolicy Bypass -File deploy.ps1
```

---

## 6.6 Access Monitoring Services

### Prometheus

**URL:** http://localhost:30090

**Verify Targets:**
1. Navigate to **Status → Targets**
2. You should see `kubernetes-cadvisor` with **UP** status

**Test a Query:**
1. Go to **Graph** tab
2. Enter: `container_cpu_usage_seconds_total`
3. Click **Execute**
4. You should see CPU metrics from all containers

### Grafana

**URL:** http://localhost:30300

**Login Credentials:**
- Username: `admin`
- Password: `admin` (change on first login)

**Pre-Loaded Dashboard:**
1. Navigate to **Dashboards** in the left sidebar
2. You should see **"YWTI Application Monitoring"**
3. Click it to view:
   - CPU Usage by Pod (line graph)
   - Memory Usage by Pod (line graph)

**Manual Query Verification:**
1. Click **Explore** (compass icon in left sidebar)
2. Select **Prometheus** as data source
3. Run query: `container_memory_usage_bytes{pod=~"ywti-app.*"}`
4. Click **Run Query** to see memory usage data

---

## 6.7 Monitoring Workflow

```
┌─────────────────────────────────────────────────────────┐
│  STEP 1: Application Generates Metrics                  │
│  ├─ CPU usage (from cAdvisor)                           │
│  ├─ Memory usage (from cAdvisor)                        │
│  └─ Pod status (from Kubelet)                           │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│  STEP 2: Prometheus Scrapes Metrics (every 15s)         │
│  ├─ Reads from /metrics/cadvisor                        │
│  ├─ Stores time-series data                             │
│  └─ Exposes query API (:9090/api/v1/query)              │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│  STEP 3: Grafana Queries Prometheus                     │
│  ├─ Sends PromQL queries                                │
│  ├─ Receives time-series data                           │
│  └─ Renders graphs/dashboards                           │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│  STEP 4: User Views Dashboard (http://localhost:30300)  │
│  ├─ Real-time CPU/Memory graphs                         │
│  ├─ Auto-refreshes every 5 seconds                      │
│  └─ Historical data for analysis                        │
└─────────────────────────────────────────────────────────┘
```

---

## 6.8 Summary

| Component   | Purpose                          | Access URL                    |
| ----------- | -------------------------------- | ----------------------------- |
| Prometheus  | Metrics collection and storage   | http://localhost:30090        |
| Grafana     | Visualization dashboards         | http://localhost:30300        |
| cAdvisor    | Container metrics (built-in K8s) | N/A (scraped by Prometheus)   |
| ConfigMaps  | Store configs and dashboards     | Applied via `kubectl apply`   |

**What We Achieved:**
- Automatic metrics collection from Kubernetes
- Pre-configured Grafana dashboard
- Real-time CPU/Memory monitoring
- Zero manual configuration (fully automated)
- Integrated with CI/CD pipeline (Jenkins deploys it)



---

# Conclusion and Best Practices

This project successfully implements a complete DevOps pipeline covering all aspects of modern software delivery:

- Automated CI/CD with Jenkins (10 stages)
- Code quality enforcement with SonarQube
- Container orchestration with Kubernetes
- Real-time monitoring with Prometheus and Grafana
- Cross-platform compatibility (Windows/Linux/macOS)


