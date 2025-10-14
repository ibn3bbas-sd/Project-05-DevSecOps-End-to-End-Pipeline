pipeline {
    agent any
    tools {
        jdk 'jdk'
        maven 'maven'
    }
    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }
    stages {
        stage("Git Checkout") {
            steps {
                git branch: 'main', changelog: false, poll: false, url: 'https://github.com/ersinsari13/devsecops.git'
            }
        }

        stage("Compile") {
            steps {
                sh "mvn clean compile"
            }
        }

        stage("Test Cases") {
            steps {
                sh "mvn test"
            }
        }

        stage("Sonarqube Analysis") {
            steps {
                script {
                    withSonarQubeEnv('SonarQubeDefault') {
                        sh '''
                            mvn clean verify sonar:sonar \
                            -Dsonar.projectKey=Petclinic
                        '''
                    }
                }
            }
        }

        stage("Quality Gate") {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    script {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }

        stage("Build") {
            steps {
                sh "mvn clean install"
            }
        }

        stage("OWASP-Dependency-Check") {
            steps {
                withCredentials([string(credentialsId: 'NVD_API_KEY', variable: 'NVD_API_KEY')]) {
                    sh '''
                        mvn org.owasp:dependency-check-maven:12.1.0:check \
                        -Dnvd.api.key=$NVD_API_KEY \
                        -Dossindex.api.key=$OSS_API_KEY \
                        -DsuppressionFile=/opt/devsecops/config/dependency-check-suppress.xml \
                        -Danalyzer.nvd.cachevalidforhours=720 || true
                    '''
                }
            }
            post {
                always {
                    dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
                }
            }
        }

        stage("Scan Dockerfile with Conftest") {
            steps {
                echo 'Scanning Dockerfile'
                sh "docker run --rm -v \$(pwd):/project openpolicyagent/conftest:v0.45.0 test --policy dockerfile-conftest.rego Dockerfile"
            }
        }

        stage("Prepare Tags for Docker Images") {
            steps {
                echo 'Preparing Tags for Docker Images'
                script {
                    // Extract Maven version from pom.xml reliably
                    MVN_VERSION = sh(script: "mvn help:evaluate -Dexpression=project.version -q -DforceStdout", returnStdout: true).trim()
                    env.IMAGE_TAG_DEVSECOPS = "ersinsari/devsecops:${MVN_VERSION}-b${BUILD_NUMBER}"
                }
            }
        }

        stage("Build App Docker Images") {
            steps {
                echo 'Building App Docker Image'
                sh "docker build --force-rm -t ${IMAGE_TAG_DEVSECOPS} ."
                sh 'docker image ls'
            }
        }

        stage("Scan Image with Trivy") {
            steps {
                script {
                    // Scan image and fail pipeline if critical vulnerabilities found
                    def scanResult = sh(script: "trivy image --severity CRITICAL --exit-code 1 ${IMAGE_TAG_DEVSECOPS}", returnStatus: true)
                    if (scanResult != 0) {
                        error "Critical vulnerabilities found in Docker image. Failing the pipeline."
                    }
                    // Optional: save Trivy report
                    sh "trivy image --format json -o trivy-report.json ${IMAGE_TAG_DEVSECOPS} || true"
                    archiveArtifacts artifacts: 'trivy-report.json', fingerprint: true
                }
            }
        }
    }
}
