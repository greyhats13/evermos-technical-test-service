def unit                = "evm"
def code                = "core"
def feature             = "api"
def repo_name           = "${unit}-${code}-${feature}"
def repo_url            = "https://github.com/greyhats13/${repo_name}.git"
def docker_username     = "greyhats13"
def docker_creds        = "docker_creds"
def github_creds        = "github_creds"
def build_number        = "${env.BUILD_NUMBER}"
def fullname            = "${repo_name}-${build_number}"
def service_name        = "${unit}-${code}-${feature}"
def environment, namespace, version, runBranch, helm_values

podTemplate(
    label: fullname , 
    serviceAccount: "${unit}-toolchain-jenkins",
    containers: [
        //container template to perform docker build and docker push operation
        containerTemplate(name: 'docker', image: 'docker.io/docker', command: 'cat', ttyEnabled: true, alwaysPullImage: true),
        containerTemplate(name: 'helm', image: 'alpine/helm:3.3.4', command: 'cat', ttyEnabled: true)
    ],
    volumes: [
        //the mounting for container
        hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock')
    ]) 
{
    node(fullname) {
        stage("Source") {
            echo "env: ${env.GET_ENV}"
            echo "Entering Source stage"
            if (env.BRANCH_NAME == 'dev') {
                echo "Version: Alpha"
                environment  = 'dev'
                namespace    = 'dev'
                version      = 'alpha'
                runBranch    = "*/dev"
                helm_values  = "values-${environment}.yaml"
            } else if (env.BRANCH_NAME == 'main') {
                echo "Version: Beta"
                environment  = 'stg'
                namespace    = 'stg'
                version      = 'beta'
                runBranch    = "*/main"
                helm_values  = "values-${environment}.yaml"
            } else {
                echo "Version: Debug"
                version      = 'debug'
                runBranch    = "*/${env.BRANCH_NAME}"
                helm_values  = "values-${environment}.yaml"
            }
            echo "Perform checkout"
            def scm = checkout([$class: 'GitSCM', branches: [[name: runBranch]], userRemoteConfigs: [[credentialsId: github_creds, url: repo_url]]])
        }

        //use container slave for docker to perform docker build and push
        stage('Build Container') {
            echo "Perform Docker Build..."
            container('docker') {
                dockerBuild(docker_username: docker_username, service_name: service_name, build_number: build_number)
            }
        }

        stage('Push Container') {
            echo "Perform Docker Push and Tagging..."
            container('docker') {
                docker.withRegistry("", docker_creds) {
                    dockerPush(docker_username: docker_username, service_name: service_name, build_number: build_number)
                    dockerPushTag(docker_username: docker_username, service_name: service_name, build_number: build_number, version: version)
                }
            }
        }

        stage('Deploy') {
            echo "Perform Helm Deploy..."
            container('helm') {
               sh "helm lint -f ${helm_values}"
               sh "helm -n ${namespace} install ${service_name} -f ${helm_values} . --dry-run --debug"
               sh "helm -n ${namespace} upgrade --install ${service_name} -f ${helm_values} . --recreate-pods"
            }
        }
    }
}

//function to perform docker build that is defined in dockerfile
def dockerBuild(Map args) {
    sh "docker build -t ${args.docker_username}/${args.service_name}:${args.build_number} ."
}

def dockerPush(Map args) {
    sh "docker push ${args.docker_username}/${args.service_name}:${args.build_number}"
}

def dockerPushTag(Map args) {
    sh "docker tag ${args.docker_username}/${args.service_name}:${args.build_number} ${args.docker_username}/${args.service_name}:${args.version}"
    sh "docker push ${args.docker_username}/${args.service_name}:${args.version}"
}
