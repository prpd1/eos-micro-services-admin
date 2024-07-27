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
                - name: build
                  image: qwerty703/eos-jenkins-agent-base:latest
                  command:
                  - cat
                  tty: true
                - name: kaniko
                  image: gcr.io/kaniko-project/executor:debug
                  command:
                  - sleep
                  args:
                  - 9999999
                  volumeMounts:
                  - name: kaniko-secret
                    mountPath: /kaniko/.docker
                restartPolicy: Never
                volumes:
                - name: kaniko-secret
                  secret:
                    secretName: dockercred
                    items:
                    - key: .dockerconfigjson
                      path: config.json
"""
) {
    node (label) {
        stage ('Checkout SCM'){
          git credentialsId: 'git', url: 'https://github.com/prpd1/eos-micro-services-admin.git', branch: 'main'
          container('build') {
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
          container('build') {
                stage('Sonar Scan') {
                  withSonarQubeEnv('sonar') {
                  sh './mvnw verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar -Dsonar.projectKey=eos-sonar_eos'
                }
                }
            }
        }


        stage ('Artifactory configuration'){
          container('build') {
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
          container('build') {
                stage('Deploy Artifacts') {
                    rtMavenRun (
                    tool: "java2", // Tool name from Jenkins configuration
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
            container('build') {
                stage('Publish build info') {
                rtPublishBuildInfo (
                    serverId: "jfrog"
                  )
               }
           }
       }
       stage ('Docker Build'){
          container('kaniko') {
                stage('Build Image') {
                    sh '''
                      /kaniko/executor --context `pwd` --destination qwerty703/eos-micro-services-admin:latest
                    '''
                }
            }
        }

        stage ('Helm Chart') {
          container('build') {
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
