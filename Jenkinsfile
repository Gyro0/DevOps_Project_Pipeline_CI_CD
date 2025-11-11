pipeline {
    agent any
    
    tools {
        maven 'Maven-3.9.11'
        jdk 'JDK-17'
    }
    
    environment {
        MAVEN_OPTS = '-Xmx1024m'
        SCANNER_HOME = tool 'SonarScanner'
    }
    
    stages {
        stage('1. Cloner le repo') {
            steps {
                script{
                    if (isUnix()){
                        sh 'git config --global core.autocrlf input'
                    } 
                }

                echo 'Clonage du repository depuis GitHub...'
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
    }
    
    post {
        success {
            echo '==============Le Pipeline est execute avec succes!=============='
        }
        failure {
            echo '==============Le pipeline a echoue.=============='
        }
        always {
            echo "workspace: ${WORKSPACE}"
            //echo 'Cleaning workspace...'
            //cleanWs()
        }
    }
}
