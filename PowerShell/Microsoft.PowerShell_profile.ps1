<# -------------------------------------------------------------------------------------------------
  _ __                                     _            _  _  _ __                 __  _  _
  | '_ \   ___  __      __  ___  _ __  ___ | |__    ___ | || || '_ \  _ __   ___   / _|(_)| |  ___
  | |_) | / _ \ \ \ /\ / / / _ \| '__|/ __|| '_ \  / _ \| || || |_) || '__| / _ \ | |_ | || | / _ \
  | .__/ | (_) | \ V  V / |  __/| |   \__ \| | | ||  __/| || || .__/ | |   | (_) ||  _|| || ||  __/
  |_|     \___/   \_/\_/   \___||_|   |___/|_| |_| \___||_||_||_|    |_|    \___/ |_|  |_||_| \___|
  ------------------------------------------------------------------------------------------------- #>
# Coding by Sidney Zhang <zly@lyzhang.com>
# Update 2020-08-27

<#
  ===================================================================================================
  REQUIRED MODULES
  ===================================================================================================
#>

Import-Module posh-git
Import-Module oh-my-posh
Import-Module Get-ChildItemColor

<#
  ===================================================================================================
  STATIC VARIABLES
  ===================================================================================================
#>

New-Variable -Name Download -Value ($HOME + "\Downloads") -Option Constant -Description "This is download folder."
New-Variable -Name APPDATA -Value ($HOME + "\AppData") -Option Constant -Description "This is appdata folder."
New-Variable -Name CODE -Value "C:\WorkPlace\CodingOnline\" -Option Constant -Description "This is my coding work folder."
New-Variable -Name GETSECRETS -Value "C:\Users\alfch\Documents\WindowsPowerShell\Modules\Get-Secret\getSecret.py" -Option Constant -Description "Script of get-Secrets."

<#
  ===================================================================================================
  FUNCTIONS
  ===================================================================================================
#>
<# --------------------------------------------General--------------------------------------------- #>

function Read-UTF8 {
  [CmdletBinding()]
  param(
    [Parameter(
      ValueFromPipeline = $True,
      Mandatory = $True)]
    [String]
    $File,
    [Alias('h')]
    $Head = -1,
    [Alias('t')]
    $Tail = -1,
    [Alias('l')]
    $Line = -1
  )
  if ($Line -gt 0) {
    if (($Head -gt 0) -or ($Tail -gt 0)){
      Write-Host "按行展示不可使用Head与Tail参数。`n"
    }
    (Get-Content -Encoding "UTF8" -TotalCount $Line $File)[-1]
  }
  else {
    if (($Head -le 0) -and ($Tail -le 0)) {
      Get-Content -Encoding "UTF8" $File
    }
    elseif (($Head -gt 0) -and ($Tail -le 0)) {
      Get-Content -Encoding "UTF8" $File -TotalCount $Head
    }
    elseif (($Head -le 0) -and ($Tail -gt 0)) {
      Get-Content -Encoding "UTF8" $File -Tail $Tail
    }
    else {
      Get-Content -Encoding "UTF8" $File -TotalCount $Head
      Write-Host "... ..."
      Get-Content -Encoding "UTF8" $File -Tail $Tail
    }
  }
}

function Get-Nowtime { Get-Date -Format "HH:mm" }

function Get-ArchFile {
  Param (
    [ValidateSet("win","comp","cloud")]
    [Alias("f")]
    $fromserver = "win",
    [ValidateSet("win","comp","cloud")]
    [Alias("t")]
    $toserver = "comp",
    [Alias("b")]
    $fromfolder,
    [Alias("e")]
    $tofolder
  )
  Begin{
    switch ($fromserver) {
      "win" {
        $here = "C:\Users\alfch\Downloads\"
        break
      }
      "comp" {
        $here = "sidneyzhang@192.168.20.59:"
        break
      }
      "cloud" {
        $here = "root@47.99.100.104:"
        break
      }
    }
    switch ($toserver) {
      "win" {
        $there = "C:\Users\alfch\Downloads\"
        break
      }
      "comp" {
        $there = "sidneyzhang@192.168.20.59:"
        break
      }
      "cloud" {
        $there = "root@47.99.100.104:"
        break
      }
    }
  }
  Process{
    scp -r ($here+$fromfolder) ($there+$tofolder)
  }
}

function Get-Downloads { aria2c -s16 -x16 -k1M $args }

<# -------------------------------------------Location--------------------------------------------- #>

function Set-coding { Set-Location $CODE }
function Set-download { Set-Location $Download }
function Set-AppData { Set-Location $APPDATA }

<# ----------------------------------------------Git----------------------------------------------- #>

function Get-gitadd
{
    git add .
    git commit -S -m $args
}

function Get-gitpush { git push -u origin master }

<#
  ===================================================================================================
  ALIASES
  ===================================================================================================
#>

Set-Alias -Name cat8 -Value Read-UTF8
Set-Alias -Name now -Value Get-Nowtime
Set-Alias -Name arch -Value Get-ArchFile
set-Alias -Name load -Value Get-Downloads

If (-Not (Test-Path Variable:PSise)) {
  function l { Get-ChildItemColor | Format-Wide }
  Set-Alias la Get-ChildItem -option AllScope
  Set-Alias ls Get-ChildItemColorFormatWide -option AllScope
}

<#
  ===================================================================================================
  SETTING CONSOLE
  ===================================================================================================
#>

Set-Theme Agnoster
posh-winfetch