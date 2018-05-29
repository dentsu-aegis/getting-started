#!/bin/bash
######################################################################################################################
# This is for macs only - needs to be ported to windows. || it can be run in the ubuntu shell in windows 10.. 
# if you put your machine into developer mode
######################################################################################################################

# handy logging and error handling functions
log() { tput sgr0 ; tput setaf 4; tput setab 7; tput bold tput bold ; printf '%s\n' "$*"; }
info() { log "INFO: $*" >&2; }
warn() { log "WARNING: $*" >&2; }
error() { log "ERROR: $*" >&2; }
fatal() { error "$*"; exit 1; }
usage_fatal() { error "$*"; usage >&2; exit 1; }

export WINDOWS_USERNAME=$1
export LINUX_USERNAME=$2
export PLATFORM_DOMAIN=!!!!SETME!!!!!
export MINIO_ACCESS_KEY=!!!!SETME!!!!!
export MINIO_ACCESS_SECRET=!!!!SETME!!!!!

# Text animatin for intro
function animate_text() {
  str=$1
  x=0; while [[ "$x" -lt ${#str} ]]; do ((x++)); echo -ne "\t${str:0:$x}\r"; sleep .05; done; echo
}

# Function to wait for a pod to be ready
function wait_for_pods() {
  echo -n "waiting for $1 pods to run"

  PODS=$(kubectl get pods -n $1 -lapp=$2 -o name | awk -F / '{print $2}')

  for POD in ${PODS}; do
    while [[ $(kubectl get pod ${POD} -n $1 -o go-template --template "{{.status.phase}}") != "Running" ]]; do
      sleep 1
      echo -n "."
    done
  done
  echo
}

# Define out lovely little banner.
BANNER=$(cat << EOF 

########################################################################################################################################################################################################
      ___           ___                                               ___           ___                    ___                       ___           ___                       ___          _____    
     /  /\         /  /\          ___         ___       ___          /__/\         /  /\                  /  /\          ___        /  /\         /  /\          ___        /  /\        /  /::\   
    /  /:/_       /  /:/_        /  /\       /  /\     /  /\         \  \:\       /  /:/_                /  /:/_        /  /\      /  /::\       /  /::\        /  /\      /  /:/_      /  /:/\:\  
   /  /:/ /\     /  /:/ /\      /  /:/      /  /:/    /  /:/          \  \:\     /  /:/ /\              /  /:/ /\      /  /:/     /  /:/\:\     /  /:/\:\      /  /:/     /  /:/ /\    /  /:/  \:\ 
  /  /:/_/::\   /  /:/ /:/_    /  /:/      /  /:/    /__/::\      _____\__\:\   /  /:/_/::\            /  /:/ /::\    /  /:/     /  /:/~/::\   /  /:/~/:/     /  /:/     /  /:/ /:/_  /__/:/ \__\:|
 /__/:/__\/\:\ /__/:/ /:/ /\  /  /::\     /  /::\    \__\/\:\__  /__/::::::::\ /__/:/__\/\:\          /__/:/ /:/\:\  /  /::\    /__/:/ /:/\:\ /__/:/ /:/___  /  /::\    /__/:/ /:/ /\ \  \:\ /  /:/
 \  \:\ /~~/:/ \  \:\/:/ /:/ /__/:/\:\   /__/:/\:\      \  \:\/\ \  \:\~~\~~\/ \  \:\ /~~/:/          \  \:\/:/~/:/ /__/:/\:\   \  \:\/:/__\/ \  \:\/:::::/ /__/:/\:\   \  \:\/:/ /:/  \  \:\  /:/ 
  \  \:\  /:/   \  \::/ /:/  \__\/  \:\  \__\/  \:\      \__\::/  \  \:\  ~~~   \  \:\  /:/            \  \::/ /:/  \__\/  \:\   \  \::/       \  \::/~~~~  \__\/  \:\   \  \::/ /:/    \  \:\/:/  
   \  \:\/:/     \  \:\/:/        \  \:\      \  \:\     /__/:/    \  \:\        \  \:\/:/              \__\/ /:/        \  \:\   \  \:\        \  \:\           \  \:\   \  \:\/:/      \  \::/   
    \  \::/       \  \::/          \__\/       \__\/     \__\/      \  \:\        \  \::/                 /__/:/          \__\/    \  \:\        \  \:\           \__\/    \  \::/        \__\/    
     \__\/         \__\/                                             \__\/         \__\/                  \__\/                     \__\/         \__\/                     \__\/                

########################################################################################################################################################################################################
#
#     PLEASE NOTE TO RUN THIS YOU NEED A MINIMUM OF 30GB ON YOUR MACHINE TO RUN, OPTIMAL IS 60GB
#
EOF
)

SEPARATOR="########################################################################################################################################################################################################"

INFO1=$(cat << EOF
This is a simple utility to install various developer friendly utilities on your machine.  This is what it does :
EOF
)

INFO2=$(cat << EOF
1. Installs the following utilities
  - brew
  - virtualbox
  - xhyve
  - golang
  - minikube
  - helm
  - coredns
  - direnv
  - minio

EOF
)

INFO3=$(cat << EOF
2. It then configures a dns proxy so that you forward traffic for internal services through that interface. (tun) 
   PLEASE NOTE: You will need your vpn configuration present for this to work correctly.  Please speak to someone in devops
   if you dont have this. This will be installed on your machine and will require sudo privileges, if you dont have it, well 
   sorry I cant help you. For more information please refer to the coredns website:
   https://coredns.io


3. Appends some environment variables into your bash_profile

4. Setups up a minio server in your local environment.  You can use this for any object storage requirements you may have as this is a fully
   functional S3 compatible object storage server.  For more details please refer to
   https://www.minio.io/

Please report any bugs to the devops team 
  #devops (teams) 
  devops@dentsuaegis.com (email)

EOF
)

INFO4=$(cat << EOF
We are going to install brew package manager...if you prefer something else, go write your own version of this script, and create a pull request. 
EOF
)

INFO5=$(cat << EOF
##################################################################
 Go Assumes you use github to push your code to
 if you do not require golang build capability
 Just add a dummy account as go requires this folder
 structure to be present. You only need this if you will be
 compiling go code
##################################################################
 Please enter your github username ex: someuser
##################################################################
EOF
)

INFO6=$(cat << 'EOF'
please make a decision which hypervisor you would like to use. for ease of use virtualbox, for better performance xhyve
please select a hypervisor
### Please note there are several things that dont work with xhyve.. so virtual box is the recommended hypervisor to use if you want everything working. 
EOF
)

sudo apt-get remove docker docker-engine docker.io -y 
sudo apt-get install python curl git mercurial direnv -y
curl -fsSL get.docker.com -o get-docker.sh && sudo sh get-docker.sh
curl https://sdk.cloud.google.com | bash

# Need to ensure our path is substitutes
export PATH=$HOME/google-cloud-sdk/bin:$PATH
echo Y | gcloud components install kubectl || echo "already installed"
echo Y | gcloud components upgrade
# Set the versions
COREDNS_VERSION=0.9.10
LOCAL_BUILDER=v1.0.0-no-net
HELM_VERSION=2.9.0

sudo curl -S -L https://github.com/ryanharper007/container-builder-local/releases/download/${LOCAL_BUILDER}/builder-linux --output /usr/local/bin/builder && sudo chmod 755 /usr/local/bin/builder
sudo curl -S -L https://dl.minio.io/client/mc/release/linux-amd64/mc --output /usr/local/bin/mc && sudo chmod 755 /usr/local/bin/mc
sudo curl -S -L https://kubernetes-helm.storage.googleapis.com/helm-v${HELM_VERSION}-linux-amd64.tar.gz --output /tmp/helm.tar.gz && tar xzf /tmp/helm.tar.gz && sudo mv linux-amd64/helm /usr/local/bin/ && sudo chmod 755 /usr/local/bin/helm && sudo rm -rfv linux-amd64/ /tmp/helm.tar.gz 
rm -rfv ~/.minikube && cp -PR "/mnt/c/Users/$WINDOWS_USERNAME/.minikube" ~/ 
rm -rfv ~/.kube && cp -PR "/mnt/c/Users/$WINDOWS_USERNAME/.kube" ~/
sed -i 's/C:\\Users\\'"$WINDOWS_USERNAME"'\\.minikube\\/\/mnt\/\/c\/\/Users\/'"$USER"'\/.minikube\//g' ~/.kube/config

tput sgr0 ; tput setaf 4; tput setab 7; tput bold tput bold

export PATH=$PATH:/usr/local/bin

log "Adding the static routes I will require your password"
log "Setting up your bash profile"


cat << EOF > ~/.sedex_profile
#!/bin/bash
# load our direnv files
export WINDOWS_USERNAME=$WINDOWS_USERNAME
EOF
echo "sticking in the rest of the profile"
cat << 'EOF' >> ~/.dan_profile

eval "$(direnv hook bash)"
export PATH=/usr/local/bin:$HOME/google-cloud-sdk/bin:$PATH
# load the docker environment into your shell
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://192.168.99.100:2376"
export DOCKER_CERT_PATH="/mnt/c/Users/$WINDOWS_USERNAME/.minikube/certs"
export DOCKER_API_VERSION="1.23"

function wait_for_pods() {
  echo "waiting for $1 pods to run"
  PODS=$(kubectl get pods -n $1 -lapp=$2 --no-headers=true -o=custom-columns=NAME:.metadata.name)
  for POD in ${PODS}; do
    while [[ $(kubectl get pod ${POD} -n $1 -o go-template --template "{{.status.phase}}") != "Running" ]]; do
      sleep 1
      echo -n "."
    done
  done
  echo
} 
 

# parse the git branch
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

function parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}
export PATH=$PATH:/usr/local/bin
EOF


grep -q 'source ~/.dan_profile' ~/.bash_profile ||  cat << 'EOF' >> ~/.bash_profile 
source ~/.dan_profile
EOF

export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://192.168.99.100:2376"
export DOCKER_CERT_PATH="/mnt/c/Users/$WINDOWS_USERNAME/.minikube/certs"
export DOCKER_API_VERSION="1.23"

tput sgr0 ; tput setaf 4; tput setab 7; tput bold tput bold
# Switch your context to minikube
kubectl config set-context minikube
kubectl config use-context minikube
kubectl create ns devint

# This will set the account up to pull images.  Note this is project specific
# TODO: Minukube will have to spawned to replicate project structure. WIP
helm init --service-account tiller --node-selectors "beta.kubernetes.io/os"="linux" --upgrade --wait
helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
helm repo update


cat << 'EOF'
having a snooze for a minute so the various k8s components are up please be patient
EOF
sleep 60

# Install Minio as our local object storage
helm install --name=minio-dev --set accessKey=$MINIO_ACCESS_KEY,secretKey=$MINIO_ACCESS_SECRET,serviceType=NodePort stable/minio --namespace kube-system
# we need minio to be up for everything else.
wait_for_pods minio-dev-minio
sleep 20

cat << EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: system-ingress
  namespace: kube-system
  annotations:
    kubernetes.io/ingress.class: "nginx"
    ingress.kubernetes.io/enable-cors: "true"
    ingress.kubernetes.io/proxy-body-size: "0"
spec:
  rules:
  - host: storage.$PLATFORM_DOMAIN
    http:
      paths:
      - path: /
        backend:
          serviceName: minio-dev-minio-svc
          servicePort: 9000
EOF

sleep 30
# add the minio host
mc config host add local http://storage.$PLATFORM_DOMAIN/ $MINIO_ACCESS_KEY $MINIO_ACCESS_SECRET
# make our buckets for local storage
mc mb local/caches
mc mb local/docker-registry

# Create our registry that is backed by minio
cat << EOF | kubectl create -f -
apiVersion: v1
kind: ReplicationController
metadata:
  name: kube-registry-v0
  namespace: kube-system
  labels:
    k8s-app: kube-registry
    version: v0
spec:
  replicas: 1
  selector:
    k8s-app: kube-registry
    version: v0
  template:
    metadata:
      labels:
        k8s-app: kube-registry
        version: v0
    spec:
      containers:
      - name: registry
        image: registry:2
        resources:
          limits:
            cpu: 100m
            memory: 100Mi
        env:
        - name: REGISTRY_HTTP_ADDR
          value: :5000
        volumeMounts:
        - name: image-store
          mountPath: /var/lib/registry
        - name: kube-registry-config
          mountPath: /etc/docker/registry/
        ports:
        - containerPort: 5000
          name: registry
          protocol: TCP
      volumes:
      - name: image-store
        emptyDir: {}
      - name: kube-registry-config
        configMap:
          name: kube-registry-config
---
apiVersion: v1
kind: Pod
metadata:
  name: kube-registry-proxy
  namespace: kube-system
spec:
  containers:
  - name: kube-registry-proxy
    image: gcr.io/google_containers/kube-registry-proxy:0.3
    resources:
      limits:
        cpu: 100m
        memory: 50Mi
    env:
    - name: REGISTRY_HOST
      value: kube-registry.kube-system.svc.cluster.local
    - name: REGISTRY_PORT
      value: "5000"
    - name: FORWARD_PORT
      value: "5000"
    ports:
    - name: registry
      containerPort: 5000
      hostPort: 5000
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-registry-config
  namespace: kube-system
data:
  config.yml: |-
    version: 0.1
    log:
      level: debug
      formatter: text
      fields:
        service: registry
        environment: staging
    loglevel: debug
    storage:
      s3:
        accesskey: $MINIO_ACCESS_KEY
        secretkey: $MINIO_ACCESS_SECRET
        region: us-east-1
        regionendpoint: http://minio-dev-minio-svc.kube-system.svc.cluster.local:9000
        bucket: docker-registry
        encrypt: false
        secure: false
        v4auth: true
        chunksize: 5242880
        rootdirectory: /i
      delete:
        enabled: true
      maintenance:
        uploadpurging:
          enabled: true
          age: 168h
          interval: 24h
          dryrun: false
        readonly:
          enabled: false
    http:
      addr: :5000
---   
apiVersion: v1
kind: Service
metadata:
  name: kube-registry
  namespace: kube-system
  labels:
    app: kube-registry
    kubernetes.io/name: "KubeRegistry"
spec:
  clusterIP: 10.96.0.222
  type: NodePort
  selector:
    k8s-app: kube-registry
  ports:
  - name: registry
    port: 5000
    protocol: TCP
EOF

log "In Order for us to get external resolution working within the cluster we need to convert the service to a nodeport"
# delete the existing dns service
kubectl delete svc kube-dns -n kube-system
# create the new dns service
cat << 'EOF' | kubectl create -f - 
apiVersion: v1
kind: Service
metadata:
  annotations:
  labels:
    addonmanager.kubernetes.io/mode: Reconcile
    k8s-app: kube-dns
    kubernetes.io/name: KubeDNS
  name: kube-dns
  namespace: kube-system
spec:
  clusterIP: 10.96.0.10
  externalTrafficPolicy: Cluster
  ports:
  - name: dns
    nodePort: 30500
    port: 53
    protocol: UDP
    targetPort: 53
  - name: dns-tcp
    nodePort: 30500
    port: 53
    protocol: TCP
    targetPort: 53
  selector:
    k8s-app: kube-dns
  sessionAffinity: None
  type: NodePort
status:
  loadBalancer: {}
EOF
