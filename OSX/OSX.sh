#!/bin/bash
######################################################################################################################
# This is for macs only - needs to be ported to windows. || it can be run in the ubuntu shell in windows 10.. 
# if you put your machine into developer mode
######################################################################################################################

export PLATFORM_DOMAIN=!!!!SETME!!!!!
export MINIO_ACCESS_KEY=!!!!SETME!!!!!
export MINIO_ACCESS_SECRET=!!!!SETME!!!!!

# handy logging and error handling functions
log() { tput sgr0 ; tput setaf 4; tput setab 7; tput bold tput bold ; printf '%s\n' "$*"; }
info() { log "INFO: $*" >&2; }
warn() { log "WARNING: $*" >&2; }
error() { log "ERROR: $*" >&2; }
fatal() { error "$*"; exit 1; }
usage_fatal() { error "$*"; usage >&2; exit 1; }

# Text animatin for intro
function animate_text() {
  str=$1
  x=0; while [[ "$x" -lt ${#str} ]]; do ((x++)); echo -ne "\t${str:0:$x}\r"; sleep .05; done; echo
}

# Function to wait for a pod to be ready
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

INFO6=$(cat << EOF
please make a decision which hypervisor you would like to use. for ease of use virtualbox, for better performance hyperkit, but it chews cpu
please select a hypervisor
### Please note there are several things that dont work with xhyve.. so virtual box is the recommended hypervisor to use if you want everything working. 
EOF
)


# Intro Routine
tput blink ; tput setaf 4; tput setab 7; tput bold
printf '\n%s\n'  "$BANNER"
tput sgr0 ; tput setaf 4; tput setab 7; tput bold tput bold
printf '\n%s\n' "$INFO1"
printf '\n%s\n' "$SEPARATOR"
printf '\n%s\n' "$INFO2"
printf '\n%s\n' "$SEPARATOR"
printf '\n%s\n' "$INFO3"
printf '\n%s\n' "$SEPARATOR"
printf '\n%s\n' "$INFO4"
printf '\n%s\n' "$SEPARATOR"

# Install brew package manager if it is not installed
command -v brew >/dev/null 2>&1 || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install the various dependencies i.e go, git, hg, virtualbox
brew update

# Set the versions
COREDNS_VERSION=0.9.10

# Install all our utils. 
tput sgr0 ; tput setaf 5; tput setab 0; tput bold tput bold
command -v gcloud >/dev/null 2>&1 || curl https://sdk.cloud.google.com | bash
command -v kubectl  >/dev/null 2>&1 || gcloud components install kubectl
echo Y | gcloud components update
brew upgrade git || brew install git
brew upgrade mercurial || brew install mercurial

curl -LO https://storage.googleapis.com/minikube/releases/latest/docker-machine-driver-hyperkit \
&& chmod +x docker-machine-driver-hyperkit \
&& sudo mv docker-machine-driver-hyperkit /usr/local/bin/ \
&& sudo chown root:wheel /usr/local/bin/docker-machine-driver-hyperkit \
&& sudo chmod u+s /usr/local/bin/docker-machine-driver-hyperkit


brew upgrade docker || brew install docker
brew cask upgrade minikube || brew cask install minikube
curl -S -L https://github.com/coredns/coredns/releases/download/v${COREDNS_VERSION}/coredns_${COREDNS_VERSION}_darwin_amd64.tgz -o /tmp/coredns.tgz && tar -xzf /tmp/coredns.tgz -C /usr/local/bin || echo "codedns already installed"
brew upgrade direnv || brew install direnv

brew upgrade minio/stable/mc || brew install minio/stable/mc
brew upgrade kubernetes-helm  || brew install kubernetes-helm
brew upgrade Caskroom/cask/virtualbox Caskroom/cask/virtualbox-extension-pack || brew install Caskroom/cask/virtualbox Caskroom/cask/virtualbox-extension-pack
brew tap azure/draft
brew upgrade draft || brew install draft
brew upgrade azure-cli || brew install azure-cli


tput sgr0 ; tput setaf 4; tput setab 7; tput bold tput bold

test -d $HOME/dns-zones && echo "Directory exists" || mkdir $HOME/dns-zones
log "Adding local $PLATFORM_DOMAIN zone"
cat << EOF > $HOME/dns-zones/db.$PLATFORM_DOMAIN
; $PLATFORM_DOMAIN test file
$PLATFORM_DOMAIN.          IN      SOA     sns.dns.icann.org. noc.dns.icann.org. 2015082541 7200 3600 1209600 3600
$PLATFORM_DOMAIN.          IN      NS      b.iana-servers.net.
$PLATFORM_DOMAIN.          IN      NS      a.iana-servers.net.
$PLATFORM_DOMAIN.          IN      A       192.168.99.100
service.$PLATFORM_DOMAIN.  IN      SRV     8080 10 10 $PLATFORM_DOMAIN.
registry          IN      A       10.96.0.222
storage           IN      A       192.168.99.100
EOF

log "Adding the Coredns config file"
# Create the coredns config file 
cat << EOF > $HOME/.Corefile
.:53 {
  log stdout
  hosts {
    127.0.0.1 minikube
    fallthrough
  }
  proxy . 8.8.8.8:53 {
    except cluster.local $PLATFORM_DOMAIN
  }
  
}
cluster.local { 
  proxy . 192.168.99.100:30500
}
$PLATFORM_DOMAIN {
  file $HOME/dns-zones/db.$PLATFORM_DOMAIN $PLATFORM_DOMAIN {
    transfer to *
  }
}
10.96.0.0/12 {
  whoami
}
10.0.0.0/24 {
  whoami
}
192.168.1.0/16 {
  whoami
}
172.16.0.0/16 {
  whoami
}
EOF

log "creating service watcher for coredns"
# Create a service description for coredns
cat << EOF > /tmp/org.golang.coredns.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>org.golang.coredns</string>
    <key>UserName</key>
    <string>root</string>
    <key>Program</key>
    <string>/usr/local/bin/coredns</string>
    <key>ProgramArguments</key>
    <array>
	  <string>/usr/local/bin/coredns</string>
      <string>-conf</string>
      <string>$HOME/.Corefile</string>
    </array>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
  </dict>
</plist>
EOF

log "creating plist for coredns"

cat << EOF > /tmp/dnsconf.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>dnsconf</string>
    <key>UserName</key>
    <string>root</string>
    <key>ProgramArguments</key>
    <array>
        <string>launchctl</string>
        <string>stop</string>
        <string>org.golang.coredns</string>
        <string>;</string>
        <string>launchctl</string>
        <string>start</string>
        <string>org.golang.coredns</string>
    </array>
    <key>WatchPaths</key>
    <array>
        <string>/Users/$HOME/.Corefile</string>
    </array>
</dict>
</plist>
EOF

log "Moving the plists into place, I will need your password for this"
# Move the plist into place and set it up
sudo mv /tmp/org.golang.coredns.plist /Library/LaunchDaemons/org.golang.coredns.plist
sudo mv /tmp/dnsconf.plist /Library/LaunchDaemons/dnsconf.plist
sudo chown root:wheel /Library/LaunchDaemons/org.golang.coredns.plist
sudo chown root:wheel /Library/LaunchDaemons/dnsconf.plist
sudo launchctl load /Library/LaunchDaemons/org.golang.coredns.plist || :
sudo launchctl load /Library/LaunchDaemons/dnsconf.plist || :
sudo launchctl start /Library/LaunchDaemons/org.golang.coredns.plist || :
sudo launchctl start /Library/LaunchDaemons/dnsconf.plist || :

log "Pointing your dns servers to the newly created coredns server"
# Setup the networking correctly so that localhost is the dnsserver
wired=$(networksetup -listnetworkserviceorder | grep en1 | awk -F : '{print $2}' | awk -F , '{print $1}' | sed -e 's/ //1')
networksetup -setdnsservers "${wired}" 127.0.0.1
wireless=$(networksetup -listnetworkserviceorder | grep en0 | awk -F : '{print $2}' | awk -F , '{print $1}' | sed -e 's/ //1')
networksetup -setdnsservers "${wireless}" 127.0.0.1

printf '\n%s\n' "$INFO6"

PS3='Please Select a hypervisor: '
options=("hyperkit" "xhyve" "virtualbox" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "hyperkit")
            echo "Good Choice"
            echo "Good Choice"
            PS3='Please select the size of the virtual disk you would like created: '
            options=("optimum" "smallest" "Quit")
            select opt in "${options[@]}"
            do
                case $opt in
                    "optimum")
                      export DISK_SIZE=60g
                      log "setting disk size to 60GB"
                      break
                      ;;
                    "smallest")
                      export DISK_SIZE=30g
                      log "setting disk size to 30GB"
                      break
                      ;; 
                    "Quit")
                      log "OK see you soon"
                      break
                      ;;
                    *) 
                      log "invalid option" 
                      ;;
                esac
            done
            minikube start \
              --vm-driver=hyperkit \
              --v=10 \
              --alsologtostderr \
              --cpus=4 \
              --memory=7096 \
              --disk-size=$DISK_SIZE \
              --insecure-registry "10.0.0.0/8" \
              --insecure-registry "172.0.0.0/8" \
              --insecure-registry "192.0.0.0/8" \
              --insecure-registry "10.96.0.0/12" \
              --insecure-registry "docker-registry-local-reg:30400" \
              --insecure-registry "cluster.local:30400" \
              --insecure-registry "kube-registry.kube-system.svc.cluster.local:5000" \
              --insecure-registry "kube-registry.kube-system.svc.cluster.local" \
              --insecure-registry "kube-registry:5000" \
              --insecure-registry "kube-registry:5000" \
              --insecure-registry "registry.kube-system.svc.cluster.local" \
              --insecure-registry "registry.kube-system.svc.cluster.local:5000" \
              --insecure-registry "minikube.cluster.local" \
              --insecure-registry "registry.$PLATFORM_DOMAIN" \
              --insecure-registry "registry.$PLATFORM_DOMAIN:5000"

cat << EOF > $HOME/dns-zones/db.$PLATFORM_DOMAIN
; $PLATFORM_DOMAIN test file
$PLATFORM_DOMAIN.          IN      SOA     sns.dns.icann.org. noc.dns.icann.org. 2015082541 7200 3600 1209600 3600
$PLATFORM_DOMAIN.          IN      NS      b.iana-servers.net.
$PLATFORM_DOMAIN.          IN      NS      a.iana-servers.net.
$PLATFORM_DOMAIN.          IN      A       192.168.99.100
service.$PLATFORM_DOMAIN.  IN      SRV     8080 10 10 $PLATFORM_DOMAIN.
registry          IN      A       10.96.0.222
storage           IN      A       $(minikube ip)
*                 IN      A       $(minikube ip)
EOF
              sudo route -n add 10.96.0.0/12 $(minikube ip) || log "route exists"
              # restart dns with our new dns zone file
              sudo launchctl unload /Library/LaunchDaemons/org.golang.coredns.plist
              sudo launchctl load /Library/LaunchDaemons/org.golang.coredns.plist
              minikube addons enable ingress
              break
            ;;
        "xhyve")
            echo "Good Choice"
            echo "Good Choice"
            PS3='Please select the size of the virtual disk you would like created: '
            options=("optimum" "smallest" "Quit")
            select opt in "${options[@]}"
            do
                case $opt in
                    "optimum")
                      export DISK_SIZE=60g
                      log "setting disk size to 60GB"
                      break
                      ;;
                    "smallest")
                      export DISK_SIZE=30g
                      log "setting disk size to 30GB"
                      break
                      ;; 
                    "Quit")
                      log "OK see you soon"
                      break
                      ;;
                    *) 
                      log "invalid option" 
                      ;;
                esac
            done
            minikube start \
              --vm-driver=xhyve \
              --v=10 \
              --alsologtostderr \
              --cpus=2 \
              --memory=4096 \
              --disk-size=$DISK_SIZE \
              #--docker-opt=dns=10.0.2.3 \
              --insecure-registry "10.0.0.0/8" \
              --insecure-registry "10.96.0.0/12" \
              --insecure-registry "172.0.0.0/8" \
              --insecure-registry "192.0.0.0/8" \
              --insecure-registry "docker-registry-local-reg:30400" \
              --insecure-registry "cluster.local:30400" \
              --insecure-registry "kube-registry.kube-system.svc.cluster.local:5000" \
              --insecure-registry "kube-registry.kube-system.svc.cluster.local" \
              --insecure-registry "kube-registry:5000" \
              --insecure-registry "kube-registry:5000" \
              --insecure-registry "registry.kube-system.svc.cluster.local" \
              --insecure-registry "registry.kube-system.svc.cluster.local:5000" \
              --insecure-registry "minikube.cluster.local" \
              --insecure-registry "registry.$PLATFORM_DOMAIN" \
              --insecure-registry "registry.$PLATFORM_DOMAIN:5000" 
            break
            ;;
        "virtualbox")
            echo "Good Choice"
            PS3='Please select the size of the virtual disk you would like created: '
            options=("optimum" "smallest" "Quit")
            select opt in "${options[@]}"
            do
                case $opt in
                    "optimum")
                      export DISK_SIZE=60g
                      log "setting disk size to 60GB"
                      break
                      ;;
                    "smallest")
                      export DISK_SIZE=30g
                      log "setting disk size to 30GB"
                      break
                      ;; 
                    "Quit")
                      log "OK see you soon"
                      break
                      ;;
                    *) 
                      log "invalid option" 
                      ;;
                esac
            done
            minikube start \
              --vm-driver=virtualbox \
              --cpus=2 \
              --memory=4096 \
              --disk-size=$DISK_SIZE \
              --docker-opt=dns=10.0.2.3 \
              --insecure-registry "10.0.0.0/8" \
              --insecure-registry "172.0.0.0/8" \
              --insecure-registry "192.0.0.0/8" \
              --insecure-registry "10.96.0.0/12" \
              --insecure-registry "docker-registry-local-reg:30400" \
              --insecure-registry "cluster.local:30400" \
              --insecure-registry "kube-registry.kube-system.svc.cluster.local:5000" \
              --insecure-registry "kube-registry.kube-system.svc.cluster.local" \
              --insecure-registry "kube-registry:5000" \
              --insecure-registry "kube-registry:5000" \
              --insecure-registry "registry.kube-system.svc.cluster.local" \
              --insecure-registry "registry.kube-system.svc.cluster.local:5000" \
              --insecure-registry "minikube.cluster.local" \
              --insecure-registry "registry.$PLATFORM_DOMAIN" \
              --insecure-registry "registry.$PLATFORM_DOMAIN:5000"
            log "Adding the static routes I will require your password"
            sudo route -n add 10.96.0.0/12 192.168.99.100 || log "route exists"
            minikube stop
            VBoxManage modifyvm "minikube" --natdnshostresolver1 on
            minikube start
            minikube addons enable ingress
            break
            ;; 
        "Quit")
            break
            ;;
        *) 
            echo invalid option
            ;;
    esac
done


eval $(minikube docker-env)
tput sgr0 ; tput setaf 4; tput setab 7; tput bold tput bold
 

cat << EOF
having a snooze for a minute so the various k8s components are up please be patient
EOF

helm repo update
kubectl --namespace=kube-system create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default
helm init --service-account tiller --node-selectors "beta.kubernetes.io/os"="linux" --upgrade --wait
kubectl -n kube-system patch deployment tiller-deploy -p '{"spec": {"template": {"spec": {"automountServiceAccountToken": true}}}}'
sleep 30


MINIKUBE_IP=$(minikube ip)
# Install Minio as our local object storage
sleep 20

helm install --name=minio-dev --set accessKey=$MINIO_ACCESS_KEY,secretKey=$MINIO_ACCESS_SECRET,serviceType=NodePort stable/minio --namespace kube-system
helm install --name verdaccio-dev stable/verdaccio
helm install --namespace default --name gitlab -f ./value.yaml gitlab/gitlab

wait_for_pods kube-system minio-dev-minio

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
          serviceName: minio-dev
          servicePort: 9000
EOF

echo "Adding ingress for verdacio"

cat << EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: verdacio-ingress
  namespace: default
  annotations:
    kubernetes.io/ingress.class: "nginx"
    ingress.kubernetes.io/enable-cors: "true"
    ingress.kubernetes.io/proxy-body-size: "0"
spec:
  rules:
  - host: npm.$PLATFORM_DOMAIN
    http:
      paths:
      - path: /
        backend:
          serviceName: verdaccio-dev-verdaccio
          servicePort: 4873
EOF

echo "adding ingress for gitlab"
cat << EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: gitlab-ingress
  namespace: default
  annotations:
    kubernetes.io/ingress.class: "nginx"
    ingress.kubernetes.io/enable-cors: "true"
    ingress.kubernetes.io/proxy-body-size: "0"
spec:
  rules:
  - host: gitlab.$PLATFORM_DOMAIN
    http:
      paths:
      - path: /
        backend:
          serviceName: gitlab-gitlab
          servicePort: 8080
EOF

sleep 20

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
cat << EOF | kubectl create -f - 
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


# Add static routes so we can resolve minikube resources without a vpn or port-forward. 
log "add service for static routes"
sudo mkdir /Library/StartupItems/AddRoute || echo "Directory exists"
cat << EOF > /tmp/StartupParameters.plist
{
        Description     = "Add static routing tables";
        Provides        = ("AddRoutes");
        Requires        = ("Network");
        OrderPreference = "None";
}
EOF

cat << EOF > /tmp/AddRoutes
#!/bin/sh

# Set up static routing tables 
# Roark Holz, Thursday, April 6, 2006

. /etc/rc.common

StartService ()
{
        ConsoleMessage "Adding Static Routing Tables"
sudo route -n add 10.96.0.0/12 192.168.99.100
}

StopService ()
{
        return 0
}

RestartService ()
{
        return 0
}

RunService "$1"
EOF


# Move the plist into place and set it up
log "Moving static routes plist into place so they are persistent"
tput sgr0 ; tput setaf 4; tput setab 7; tput bold tput bold
sudo mv /tmp/StartupParameters.plist /Library/StartupItems/AddRoute || :
sudo mv /tmp/AddRoutes /Library/StartupItems/AddRoute || :
sudo chown root:wheel /Library/StartupItems/AddRoute/* || :
sudo chmod 755 /Library/StartupItems/AddRoute/AddRoutes || :
