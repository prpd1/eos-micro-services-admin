def label = "eosagent"
def mvn_version = 'M2'
podTemplate(label: label, yaml: """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: build
  annotations:
    sidecar.istio.io/inject: "false"
spec:
  containers:
  - name: jnlp
    image: qwerty703/eos-jenkins-agent-base:latest
    command:
    - cat
    tty: true
    volumeMounts:
    - name: dockersock
      mountPath: /var/run/docker.sock
  volumes:
  - name: dockersock
    hostPath:
      path: /var/run/docker.sock
"""
) {
    node (label) {
        stage ('Checkout SCM'){
          git credentialsId: 'git', url: 'https://github.com/prpd1/eos-micro-services-admin.git', branch: 'main'
          container('jnlp') {
                stage('Build a Maven project') {
                  //withEnv( ["PATH+MAVEN=${tool mvn_version}/bin"] ) {
                   //sh "mvn clean package"
                  //  }
                  sh './mvnw clean package' 
                   //sh 'mvn clean package'
                }
            }
        }
        stage ('Sonar Scan'){
          container('jnlp') {
                stage('Sonar Scan') {
                  withSonarQubeEnv('sonar') {
                  sh './mvnw verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar -Dsonar.projectKey=eos-sonar_eos'
                }
                }
            }
        }


        stage ('Artifactory configuration'){
          container('jnlp') {
                stage('Artifactory configuration') {
                    rtServer (
                    id: "jfrog",
                    url: "https://eosadmin.jfrog.io/artifactory",
                    credentialsId: "jfrog"
                )

                rtMavenDeployer (
                    id: "MAVEN_DEPLOYER",
                    serverId: "jfrog",
                    releaseRepo: "eos-maven-libs-release-local",
                    snapshotRepo: "eos-maven-libs-release-local"
                )

                rtMavenResolver (
                    id: "MAVEN_RESOLVER",
                    serverId: "jfrog",
                    releaseRepo: "eos-maven-libs-release",
                    snapshotRepo: "eos-maven-libs-release"
                )            
                }
            }
        }
        stage ('Deploy Artifacts'){
          container('jnlp') {
                stage('Deploy Artifacts') {
                    rtMavenRun (
                    tool: "java", // Tool name from Jenkins configuration
                    useWrapper: true,
                    pom: 'pom.xml',
                    goals: 'clean install',
                    deployerId: "MAVEN_DEPLOYER",
                    resolverId: "MAVEN_RESOLVER"
                  )
                }
            }
        }
        stage ('Publish build info') {
            container('jnlp') {
                stage('Publish build info') {
                rtPublishBuildInfo (
                    serverId: "jfrog"
                  )
               }
           }
       }
       stage ('Docker Build'){
          container('jnlp') {
                stage('Build Image') {
                    docker.withRegistry( 'https://registry.hub.docker.com', 'docker' ) {
                    def customImage = docker.build("qwerty703/eos-micro-services-admin:latest")
                    customImage.push()             
                    }
                }
            }
        }

        stage ('Helm Chart') {
          container('jnlp') {
            dir('charts') {
              withCredentials([usernamePassword(credentialsId: 'jfrog', usernameVariable: 'username', passwordVariable: 'password')]) {
              sh '/usr/local/bin/helm package micro-services-admin'
              sh '/usr/local/bin/helm push-artifactory micro-services-admin-1.0.tgz https://eosadmin.jfrog.io/artifactory/eos-helm-helm-local --username $username --password $password'
              }
            }
        }
        }
    }
}
