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
        DOCKER_TAG = "2.1"
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
                        bat "docker rmi ${DOCKER_IMAGE}:latest || exit 0"

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
