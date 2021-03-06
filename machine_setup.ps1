Checkpoint-Computer -Description "Running machine setup"

Update-Help

if (!(Test-Path $PROFILE)) {
    New-Item -Path $PROFILE -Value "#Powershell Profile" -ItemType File -Force
}

Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
. $PROFILE

$registryUpdates = @{
    "HKCU\Control Panel\Accessibility\StickyKeys\Flags" = "506"
    "HKCU\Control Panel\Accessibility\Keyboard Response\Flags" = "122"
    "HKCU\Control Panel\Accessibility\ToggleKeys\Flags" = "58"
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\EnableAutoTray" = 0
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\HideFileExt" = 0
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Search\SearchboxTaskbarMode" = 1

    "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem\LongPathsEnabled" = 1
    "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\fDenyTSConnections" = 0
    "HKLM\SYSTEM\ControlSet001\Control\FileSystem\LongPathsEnabled" = 1
}

$registryUpdates.GetEnumerator() | ForEach-Object {
    $type = "REG_DWORD"
    if ($_.Value -is [string]) {
        $type = "REG_SZ"
    }

    & reg add (Split-Path -Parent $_.Key) /v (Split-Path -Leaf $_.Key) /t $type /d $_.Value /f | Out-Null
}

Get-NetFirewallRule -DisplayName "Remote Desktop*" | Set-NetFirewallRule -Enabled True

# apply above registry settings
Stop-Process -ProcessName explorer

# should look into chocolatey provider for oneget
$chocoPrograms = @(
    "7zip"
    "AutoHotkey"
    "AutoIt"
    "Brave"
    "ChocolateyGUI"
    "Cmder"
    ,@("Everything", "/client-service /folder-context-menu /run-on-system-startup /start-menu-shortcuts")
    #"GoogleChrome"
    "firacode"
    "Firefox"
    "Microsoft-Teams"
    "nodejs"
    #"nteract"
    #"Nuget.CommandLine"
    #"Nuget-CredentialProvider-VSS"
    "PowerBI"
    "RapidEE"
    #"RegexTester"
    "RegScanner.Install"
    #"SQL-Server-Management-Studio"
    "SysInternals"
    #"WinDirStat"
    "WizTree"
    "Vivaldi"

    # Editors
    #"Notepad2"
    #"SublimeText3"

    # Git
    ,@("Git", "/GitAndUnixToolsOnPath /WindowsTerminal")
    "SourceTree"
    #"TortoiseGit"

    # Network Tools
    "Fiddler"
    #"Fiddler4"
    #"PostMan"

    # Diff Tools
    "BeyondCompare"
    "BeyondCompare-Integration" # needs to be after git, BeyondCompare, and TortoiseGit
    "WinMerge"

    # VSCode
    ,@("VSCode", "/NoDesktopIcon")

    # VS2017
    #,@("VisualStudio2017Enterprise", "--add Microsoft.VisualStudio.Workload.DataScience --includeRecommended --includeOptional") # there's no datascience package for some reason
    #"VisualStudio2017-Workload-Azure"
    #"VisualStudio2017-Workload-Data"
    #"VisualStudio2017-Workload-ManagedDesktop"
    #"VisualStudio2017-Workload-NativeDesktop"
    #"VisualStudio2017-Workload-NetCoreTools"
    #"VisualStudio2017-Workload-NetWeb"
    #"VisualStudio2017-Workload-Node"
    #"VisualStudio2017-Workload-Universal"
    #"VisualStudio2017-Workload-VisualStudioExtension"
    #"ncrunch-vs2017"
    
    # VS2019 https://www.1eswiki.com/wiki/Visual_Studio
    
    "Resharper-Ultimate-All"
    #"resharper"
    #"resharpercpp"
    #"dotcover"
    #"dotmemory"
    #"dotpeek"
    #"dottrace"

    #"R.Studio" # install after VS to use MS R
)

$chocoPrograms | ForEach-Object {
    if ($_ -is [System.String]) {
        & choco upgrade $_ -y --timeout 0
    } else {
        & choco upgrade $_[0] --params $_[1] -y --timeout 0
    }
}

#Stop-Process -Name sublime_text

# package is not updated to latest chocolatey api, can be used with a random echo
#Write-Output 'st3' | & choco upgrade SublimeText3.PackageControl -y

Install-PackageProvider Nuget -Force
(new-object Net.WebClient).DownloadString("http://bit.ly/GetPsGet") | iex

$powershellPackages = @(
    "Carbon"
    "GitHubProvider"
    "Posh-Git"
    "PoShAncestry"
    "PSColor"
    "Pscx"
)

$powershellPackages | ForEach-Object {
    if (!($_ -in (Get-InstalledModule).Name)) {
        #Install-Module $_ -Force -AllowClobber
        Install-Module $_ -Force 
        Add-Content -Path $PROFILE -Value "Import-Module $_"
    }
}

#$powershellGitHubPackages = @(
#    ,@("DuFace", "PoShAncestry")
#)

# probably a smarter way to do this
#$powershellGitHubPackages | ForEach-Object {
#    $user = $_[0]
#    $repo = $_[1]

#    if (!($_[1] -in (Get-Module).Name)) {
#        Install-Package -ProviderName Github -Source $user -Name $repo -Force
#        Add-Content -Path $PROFILE -Value "Import-Module '$env:LOCALAPPDATA\OneGet\GitHub\$repo-master\$repo.psm1'"
#    }
#}

& refreshenv

$vsCodeExtensions = @(
    #"donjayamanne.githistory"
    #"eamodio.gitlens"
    #"felipecaputo.git-project-manager"
    #"ms-vscode.csharp"
    #"ms-vscode.powershell"
    #"Tyriar.sort-lines"
    #"waderyan.gitblame"
    "Shan.code-settings-sync"
)

$vsCodeExtensions | ForEach-Object {
    & code --install-extension $_
}

# customize cmder
$cmderDir = "C:\tools\cmder"
$cmderBinDir = "$cmderDir\bin"
$cmderConfigDir = "$cmderDir\config"
$cmderVendorDir = "$cmderDir\vendor"
$cmderCmdProfile = "$cmderConfigDir\user_profile.cmd"
$cmderPsProfile = "$cmderConfigDir\user_profile.ps1"

# enable aliases to run with clink/powershell
@"
& doskey /MACROS |
    ForEach-Object { ,(`$_ -split "=").Trim() } |
    ForEach-Object {
@"
@if "%_echo%"=="" echo off
`$(`$_[1] -replace "\$", "%")
`"@ | New-Item "`$env:CMDER_ROOT\bin\`$(`$_[0]).cmd" -ItemType File -Force | Out-Null
    }
"@ | New-Item $cmderBinDir\New-CommandsFromAliases.ps1 -ItemType File -Force

@"
if "%_echo%"=="" echo off
powershell %~dp0\New-CommandsFromAliases.ps1
"@ | New-Item $cmderBinDir\New-CommandsFromAliases.cmd -ItemType File -Force

# switch to c:
$location = Get-Location
Set-Location c:

if (!(Test-Path $cmderPsProfile)) {
    & $cmderVendorDir\profile.ps1
@"
. `$PROFILE
& doskey /MACROFILE="$env:CMDER_ROOT\config\user_aliases.cmd"
& New-CommandsFromAliases
"@ | Add-Content -Path $cmderPsProfile
}

if (!(Test-Path $cmderCmdProfile)) {
    & $cmderVendorDir\init.bat
    Add-Content -Path $cmderCmdProfile -Value "New-CommandsFromAliases"
}

Set-Location $location

& $cmderVendorDir\clink\clink_x64.exe --cfgdir $cmderConfigDir set history_io 1

# clean desktop
Remove-Item "$env:PUBLIC\Desktop\*.lnk"
Remove-Item "$env:USERPROFILE\Desktop\*.lnk"

# command correction
# check this one day http://nathan-smith.org/blog/using-thefuck-with-clink-cmder
if (!($env:Path -match "Anaconda")) {
    [Environment]::SetEnvironmentVariable(
        "Path",
        #"$($env:Path);C:\Program Files\Anaconda3\Scripts",
        "$($env:Path);C:\Tools\Anaconda3\Scripts",
        [System.EnvironmentVariableTarget]::Machine)
}

& refreshenv

pip install --upgrade thefuck
if (!((Get-Content $PROFILE) -match "fuck")) {
@"
`$env:PYTHIONIOENCODING="utf-8"
`$env:PYTHONLEGACYWINDOWSSTDIO="yes"
`$env:THEFUCK_NO_COLORS="true"
Invoke-Expression "`$(thefuck --alias)"
"@ | Add-Content -Path $PROFILE
}

@"
@if "%_echo%"=="" echo off
set PYTHONIOENCODING=utf-8
set PYTHONLEGACYWINDOWSSTDIO=yes
set THEFUCK_NO_COLORS=true
for /F "usebackq delims=" %%A in (``history ^| sed "x;$!d" ^| xargs -0 thefuck``) do %%A
"@ | New-Item $cmderBinDir\fuck.cmd -ItemType File -Force

# customize git
$gitConfig = @{
    "alias.root" = "rev-parse --show-toplevel"
    "alias.trim" = "!git branch -vv | sed '/\[[^]]*: gone\]/ !d' | awk '{print `$1}' | xargs git branch -D"
    "core.ignoreCase" = $false
    "core.longpaths" = $true
    "push.default" = "current"
    "remote.origin.prune" = $true
    "rerere.enabled" = $true
}

$gitConfig.GetEnumerator() | ForEach-Object {
    & git config --global $_.Key $_.Value
}

# install r jupyter
#if (!($env:Path -match "R_SERVER")) {
#    [Environment]::SetEnvironmentVariable(
#        "Path",
#        "$($env:Path);C:\Program Files\Microsoft\R Client\R_SERVER\bin\x64",
#        [System.EnvironmentVariableTarget]::Machine)
#}

& refreshenv

#$rPackages = @(
#    "crayon"
#    "data.table"
#    "devtools"
#    "digest"
#    "dplyr"
#    "evaluate"
#    "lubridate"
#    "IRdisplay"
#    "pbdZMQ"
#    "repr"
#    "uuid"
#)

#@"
#install.packages(c($(($rPackages | ForEach-Object { "'$_'" }) -join ", ")))
#devtools::install_github('IRkernel/IRkernel')
#IRkernel::installspec()
#"@ -split "\r?\n" | ForEach-Object { & Rscript.exe -e $_ } #carriage returns break rscript

# make r library writable
#Grant-Permission -Path "C:/Program Files/Microsoft/R Client/R_SERVER/library" -Identity (& whoami) -Permission Write

Enable-WindowsOptionalFeature -FeatureName IIS-ASPNET45,Microsoft-Hyper-V-All -Online -All

# npm 
# nvm
start https://github.com/coreybutler/nvm-windows/releases

$npmPackages = @(
    "@microsoft/rush"
    "eslint"
    "gulp"
    "jshint"
    "lerna"
    "vsts-npm-auth"
    "yarn"
)

$npmPackages | ForEach-Object { & npm install -g $_ }

. $PROFILE
