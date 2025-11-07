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
                echo 'Clonage du repository depuis GitHub...'
                checkout scm
            }
        }
        
        stage('2. Compiler le projet') {
            steps {
                echo 'Compilation du projet Maven...'
                bat 'mvn clean compile'
            }
        }
        
        stage('3. Lancer les tests unitaires') {
            steps {
                echo 'Exécution des tests unitaires...'
                bat 'mvn test'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('4. Générer le package WAR/JAR') {
            steps {
                echo 'Création du package WAR...'
                bat 'mvn package -DskipTests'
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
                    bat 'mvn sonar:sonar'
                }
            }
        }
        
        stage('6. Quality Gate') {
            steps {
                echo 'Vérification du Quality Gate...'
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }
    
    post {
        success {
            echo '✓ Pipeline exécuté avec succès!'
        }
        failure {
            echo '✗ Le pipeline a échoué.'
        }
        always {
            echo 'Nettoyage de l\'espace de travail...'
            cleanWs()
        }
    }
}
