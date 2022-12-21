def label = "build"
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
  - name: build
    image: dpthub/eos-jen-node-build-agent
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
          git credentialsId: 'git', url: 'https://dptrealtime@bitbucket.org/dptrealtime/eos-micro-services-admin.git', branch: 'master'
          container('build') {
                stage('Build a Maven project') {
                    sh './mvnw clean package'             
                }
            }
        }

        stage ('Artifactory configuration'){
          container('build') {
                stage('Artifactory configuration') {
                    rtServer (
                    id: "jfrog",
                    url: "https://edproject.jfrog.io/artifactory",
                    credentialsId: "jfrog"
                )

                rtMavenDeployer (
                    id: "MAVEN_DEPLOYER",
                    serverId: "jfrog",
                    releaseRepo: "eos-admin-libs-release-local",
                    snapshotRepo: "eos-admin-libs-snapshot-local"
                )

                rtMavenResolver (
                    id: "MAVEN_RESOLVER",
                    serverId: "jfrog",
                    releaseRepo: "default-maven-virtual",
                    snapshotRepo: "default-maven-virtual"
                )            
                }
            }
        }
        stage ('Deploy Artifacts'){
          container('build') {
                stage('Deploy Artifacts') {
                    rtMavenRun (
                    tool: "maven", // Tool name from Jenkins configuration
                    pom: 'app/pom.xml',
                    goals: 'clean install',
                    deployerId: "MAVEN_DEPLOYER",
                    resolverId: "MAVEN_RESOLVER"
                  )
                }
            }
        }
        stage ('Publish build info') {
            container('build') {
                stage('Publish build info') {
                rtPublishBuildInfo (
                    serverId: "jfrog"
                  )
               }
           }
       }
       stage ('Docker Build'){
          container('build') {
                stage('Build Image') {
                    docker.withRegistry( 'https://registry.hub.docker.com', 'docker' ) {
                    def customImage = docker.build("dpthub/eos-micro-services-admin:latest")
                    customImage.push()             
                    }
                }
            }
        }

        stage ('Helm Chart') {
          container('build') {
            dir('charts') {
              withCredentials([usernamePassword(credentialsId: 'jfrog', usernameVariable: 'username', passwordVariable: 'password')]) {
              sh '/usr/local/bin/helm package microservices-admin'
              sh '/usr/local/bin/helm push-artifactory microservices-admin-1.0.tgz https://edproject.jfrog.io/artifactory/dpt7-helm-local --username $username --password $password'
              }
            }
        }
        }
    }
}
