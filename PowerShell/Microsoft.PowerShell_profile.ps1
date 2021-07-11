<# -------------------------------------------------------------------------------------------------
  _ __                                     _            _  _  _ __                 __  _  _
  | '_ \   ___  __      __  ___  _ __  ___ | |__    ___ | || || '_ \  _ __   ___   / _|(_)| |  ___
  | |_) | / _ \ \ \ /\ / / / _ \| '__|/ __|| '_ \  / _ \| || || |_) || '__| / _ \ | |_ | || | / _ \
  | .__/ | (_) | \ V  V / |  __/| |   \__ \| | | ||  __/| || || .__/ | |   | (_) ||  _|| || ||  __/
  |_|     \___/   \_/\_/   \___||_|   |___/|_| |_| \___||_||_||_|    |_|    \___/ |_|  |_||_| \___|
  ------------------------------------------------------------------------------------------------- #>
# Coding by Sidney Zhang <zly@lyzhang.com>
# Update 2019-11-09

<#
  ===================================================================================================
  REQUIRED MODULES
  ===================================================================================================
#>

Import-Module posh-git
Import-Module oh-my-posh

<#
  ===================================================================================================
  STATIC VARIABLES
  ===================================================================================================
#>

New-Variable -Name Download -Value ("D:\Downloads") -Option Constant -Description "This is download folder."
New-Variable -Name APPDATA -Value ($HOME + "\AppData") -Option Constant -Description "This is appdata folder."
New-Variable -Name CODE -Value "D:\WorkPlace\0.Coding" -Option Constant -Description "This is my coding work folder."

<#
  ===================================================================================================
  FUNCTIONS
  ===================================================================================================
#>
<# --------------------------------------------General--------------------------------------------- #>

function x { exit }
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
        $here = ""
        break
      }
      "comp" {
        $here = "sidney@192.168.20.59:"
        break
      }
      "cloud" {
        $here = "root@47.99.100.104:"
        break
      }
    }
    switch ($toserver) {
      "win" {
        $there = "D:\archload"
        break
      }
      "comp" {
        $there = "sidney@192.168.20.59:"
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
function Get-ArchDLFiles { Get-ArchFile -f comp -t win -b ~\Downloads\ -e .\ }
function Get-ToArch ($ccc) { Get-ArchFile -b $ccc -e ~/Downloads }
function Get-Downloads { aria2c -s16 -x16 -k1M $args }
function Get-Softlink ($target, $path) {
  New-Item -Path (".\"+"$path") -ItemType SymbolicLink -Value $target
}
function Get-Hardlink ($target, $path) {
  New-Item -Path (".\"+"$path") -ItemType HardLink -Value $target
}

<# -------------------------------------------Location--------------------------------------------- #>

function Set-coding { Set-Location $CODE }
function Set-download { Set-Location $Download }
function Set-AppData { Set-Location $APPDATA }

<# -------------------------------------------QuickApp--------------------------------------------- #>

function py38 { py -3.8 }
function ju { jupyter notebook }

<#
  ===================================================================================================
  ALIASES
  ===================================================================================================
#>

Set-Alias -Name cdco -Value Set-coding
Set-Alias -Name cddo -Value Set-download
Set-Alias -Name cdad -Value Set-AppData
Set-Alias -Name mkslink -Value Get-Softlink
Set-Alias -Name mkhlink -Value Get-Hardlink
Set-Alias -Name cat8 -Value Read-UTF8
Set-Alias -Name now -Value Get-Nowtime
Set-Alias -Name load -Value Get-Downloads
Set-Alias -Name archdl -Value Get-ArchDLFiles
Set-Alias -Name toarch -Value Get-ToArch

<#
  ===================================================================================================
  SETTING CONSOLE
  ===================================================================================================
#>

Set-PoshPrompt -Theme agnoster
Set-PSReadLineOption -Colors @{
  Command            = 'Magenta'
  Number             = 'DarkGray'
  Member             = 'DarkGray'
  Operator           = 'DarkGray'
  Type               = 'DarkGray'
  Variable           = 'DarkGreen'
  Parameter          = 'DarkGreen'
  ContinuationPrompt = 'DarkGray'
  Default            = 'DarkGray'
}
If (-Not (Test-Path Variable:PSise)) {  # Only run this in the console and not in the ISE
    Import-Module Get-ChildItemColor
    
    Set-Alias l Get-ChildItem -option AllScope
    Set-Alias ls Get-ChildItemColorFormatWide -option AllScope
}