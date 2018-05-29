Param($arg)

if ($arg){ if ($arg -eq 'force'){$force='--force'} else {"Argument ${arg} is invalid, valid arguments: force"}}

if ((whoami /all | select-string S-1-16-12288) -eq $null){
$wshell = New-Object -ComObject Wscript.Shell 
$a=$wshell.Popup("Not running elevated, aborting",0,"Error",0x10)
  if($a -eq 1) {Exit}
}

try {if(Get-Command choco -ErrorAction Stop){"chocolatey is installed"}} catch {iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex}
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
choco install -y openvpn