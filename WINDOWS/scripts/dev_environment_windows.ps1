Param($arg)

if ($arg){ if ($arg -eq 'force'){$force='--force'} else {"Argument ${arg} is invalid, valid arguments: force"}}

if ((whoami /all | select-string S-1-16-12288) -eq $null){
$wshell = New-Object -ComObject Wscript.Shell 
$a=$wshell.Popup("Not running elevated, aborting",0,"Error",0x10)
  if($a -eq 1) {Exit}
}

function Out-Unix
{
    param ([string] $Path)

    begin 
    {
        $streamWriter = New-Object System.IO.StreamWriter("$Path", $false)
    }
    
    process
    {
        $streamWriter.Write(($_ | Out-String).Replace("`r`n","`n"))
    }
    end
    {

        $streamWriter.Flush()
        $streamWriter.Close()
    }
}

function Wait-For-Pods 
{
  param ([string] $Pod)
  param ([string] $Pod)
}



try {if(Get-Command choco -ErrorAction Stop){"chocolatey is installed"}} catch {iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex}

$SYSTEMDRIVE = $env:SystemDrive
$GOROOT = "c:\tools\go"
$GOPATH =  "${GOROOT}\gopath"
$COREDNSROOT = "c:\tools\windows-amd64"
$OLDPATH = [Environment]::GetEnvironmentVariable("PATH","Machine")
$PATH = "${OLDPATH};${GOPATH}\bin;${GOROOT}\bin"


$InstalledB4 = Read-Host -Prompt 'Have You run the older version of this script? If so we need to cleanup some shit from a previous run, this will restart your machine and probably kill your dns'
if ($InstalledB4 -eq "yes")  {
  minikube stop
  minikube delete 
  nssm remove  CoreDNS_proxy confirm
  $netinterface2 = (Get-NetAdapter -physical | where status -eq 'up' | Select-Object -ExpandProperty Name)
  netsh interface ip set dns "${netinterface2}" static 8.8.8.8
  Restart-Computer
}


# Persist environment variables

[Environment]::SetEnvironmentVariable("GOROOT",$GOROOT,"Machine")
[Environment]::SetEnvironmentVariable("GOPATH",$GOPATH,"Machine")
[Environment]::SetEnvironmentVariable("PATH",$PATH,"Machine")

$command="gcloudsdk"; try {if(Get-Command gcloud -ErrorAction Stop){"$command is installed"}} catch {choco install -y openvpn $command $force}
$command="git"; try {if(Get-Command $command -ErrorAction Stop){"$command is installed"}} catch {choco install -y $command $force}
$command="docker-toolbox"; try {if(Get-Command docker -ErrorAction Stop){"$command is installed"}} catch {choco install -y $command $force}
$command="minikube"; try {if(Get-Command $command -ErrorAction Stop){"$command is installed"}} catch {choco install -y $command $force}
$command="virtualbox"; try {if(Get-Command $command -ErrorAction Stop){"$command is installed"}} catch {choco install -y $command $force}
$command="hg"; try {if(Get-Command $command -ErrorAction Stop){"$command is installed"}} catch {choco install -y $command $force}
$command="virtualbox"; try {if(Get-Command $command -ErrorAction Stop){"$command is installed"}} catch {choco install -y $command $force}
$command="7z"; try {if(Get-Command $command -ErrorAction Stop){"$command is installed"}} catch {choco install -y 7zip.install 7z.portable 7zip.commandline $force}

# Declare our software versions
$HELM_VERSION = "2.7.0"
$CORE_DNS_VERSION = "1.0.1"
$DIR_ENV_VERSION = "2.13.1"

if ($Upgrade -eq "yes")  {
  choco upgrade -y minikube $force
}

try {if(Get-Command helm -ErrorAction Stop){"helm is installed"}} catch {
  iwr https://storage.googleapis.com/kubernetes-helm/helm-v$HELM_VERSION-windows-amd64.tar.gz -OutFile $env:SystemDrive\tools\helm.tar.gz
  7z x $env:SystemDrive\tools\helm.tar.gz -aoa -o"$env:SystemDrive\tools\"
  7z x $env:SystemDrive\tools\helm.tar -aoa -o"$env:SystemDrive\tools\"
  $OLDPATH = [Environment]::GetEnvironmentVariable("PATH","Machine")
  $PATH = "${OLDPATH};$env:SystemDrive\tools\windows-amd64"
  [Environment]::SetEnvironmentVariable("PATH",$PATH,"Machine")
}


try {if(Get-Command coredns -ErrorAction Stop){"coredns is installed"}} catch {
  mkdir c:\temp -ErrorAction SilentlyContinue
  iwr https://github.com/coredns/coredns/releases/download/v$CORE_DNS_VERSION/coredns_$CORE_DNS_VERSION_windows_amd64.tgz -OutFile c:\temp\coredns.tgz
  7z x c:\temp\coredns.tgz -aoa -o"c:\temp\tools\"
  7z x c:\temp\tools\coredns.tar -aoa -o"c:\temp\tools\"
  mv c:\temp\tools\coredns  $env:SystemDrive\tools\windows-amd64\coredns.exe
}


try {if(Get-Command direnv -ErrorAction Stop){"direnv is installed"}} catch {
  mkdir c:\temp -ErrorAction SilentlyContinue
  iwr https://github.com/direnv/direnv/releases/download/v$DIR_ENV_VERSION/direnv.windows-amd64.exe -OutFile $env:SystemDrive\tools\windows-amd64\direnv.exe
}


$command="nssm"; try {if(Get-Command $command -ErrorAction Stop){"$command is installed"}} catch {choco install -y $command $force}

New-Item -ItemType Directory -Path $COREDNSROOT -Force | Out-Null
New-Item -ItemType Directory -Path $COREDNSROOT/dns-zones -Force | Out-Null

$PLATFORM_DOMAIN = !!!!SET-ME!!!!

$coreconfig = @"
.:53 {
  log stdout
  hosts {
    127.0.0.1 minikube
    fallthrough
  }
  proxy . 8.8.8.8:53 {
    except cluster.local dev.int $PLATFORM_DOMAIN
  }
  
}

cluster.local { 
  proxy . 192.168.99.100:30500
}

dev.int {
  file ${COREDNSROOT}/dns-zones/$PLATFORM_DOMAIN $PLATFORM_DOMAIN {
    transfer to *
  }
}

10.0.0.0/24 {
  whoami
}

10.96.0.0/12 {
  whoami
}

192.168.1.0/16 {
  whoami
}

172.16.0.0/16 {
  whoami
}
"@


$dnsdb = @"
; dev.int test file
$PLATFORM_DOMAIN.          IN      SOA     sns.dns.icann.org. noc.dns.icann.org. 2015082541 7200 3600 1209600 3600
$PLATFORM_DOMAIN.          IN      NS      b.iana-servers.net.
$PLATFORM_DOMAIN.          IN      NS      a.iana-servers.net.
$PLATFORM_DOMAIN.          IN      A       192.168.99.100
service.$PLATFORM_DOMAIN.  IN      SRV     8080 10 10 dev.int.
registry          IN      A       192.168.99.100
storage           IN      A       192.168.99.100
"@


$coreconfig | Out-Unix "${COREDNSROOT}\.Corefile"
$dnsdb | Out-Unix "${COREDNSROOT}/dns-zones/db.dev.int"

nssm install CoreDNS_proxy "${COREDNSROOT}\coredns.exe" "-conf ${COREDNSROOT}\.Corefile"


$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
RefreshEnv
nssm start CoreDNS_proxy

# We have to set the dns address to your localhost for this to work
$netinterface2 = (Get-NetAdapter -physical | where status -eq 'up' | Select-Object -ExpandProperty Name)
netsh interface ip set dns "${netinterface2}" static 127.0.0.1
netsh interface ipv6 set dns "${netinterface2}" static ::1

$minikubestatus = minikube status
if($minikubestatus -contains "minikube: Running"){"minikube is running"} else {
    minikube start `
      --vm-driver=virtualbox `
      --cpus=2 `
      --memory=4096 `
      --disk-size=60g `
      --insecure-registry "10.0.0.0/8" `
      --insecure-registry "172.0.0.0/8" `
      --insecure-registry "192.0.0.0/8" `
      --insecure-registry "docker-registry-local-reg:30400" `
      --insecure-registry "cluster.local:30400" `
      --insecure-registry "kube-registry.kube-system.svc.cluster.local:5000" `
      --insecure-registry "kube-registry.kube-system.svc.cluster.local" `
      --insecure-registry "kube-registry:5000" `
      --insecure-registry "kube-registry:5000" `
      --insecure-registry "registry.kube-system.svc.cluster.local" `
      --insecure-registry "registry.kube-system.svc.cluster.local:5000" `
      --insecure-registry "minikube.cluster.local" `
      --insecure-registry "registry.dev.int" `
      --insecure-registry "registry.dev.int:5000"
}

& minikube docker-env | Invoke-Expression
Start-Sleep -s 60
#persist minkube/docker variables

[Environment]::SetEnvironmentVariable("DOCKER_TLS_VERIFY",$env:DOCKER_TLS_VERIFY,"Machine")
[Environment]::SetEnvironmentVariable("DOCKER_HOST",$env:DOCKER_HOST,"Machine")
[Environment]::SetEnvironmentVariable("DOCKER_CERT_PATH",$env:DOCKER_CERT_PATH,"Machine")
[Environment]::SetEnvironmentVariable("DOCKER_API_VERSION",$env:DOCKER_API_VERSION,"Machine")

Start-Sleep -s 180

# add our static routes
ROUTE -P ADD 10.96.0.0/12 192.168.99.100
minikube stop
VBoxManage.exe modifyvm "minikube" --natdnshostresolver1 on
minikube start
minikube addons enable ingress
