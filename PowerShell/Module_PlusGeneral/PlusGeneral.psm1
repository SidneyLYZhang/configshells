<#  =========================================================================
     ____  _            ____                           _
    |  _ \| |_   _ ___ / ___| ___ _ __   ___ _ __ __ _| |
    | |_) | | | | / __| |  _ / _ \ '_ \ / _ \ '__/ _` | |
    |  __/| | |_| \__ \ |_| |  __/ | | |  __/ | | (_| | |
    |_|   |_|\__,_|___/\____|\___|_| |_|\___|_|  \__,_|_|

    =========================================================================  #>
#   Update 2019-11-09
#   Copyright (2019) by Sidney Zhang <zly@lyzhang.me>
<#  =========================================================================  #>

<#  ---------------------------------SIMPLE----------------------------------  #>
function Open-PowershellAdmin { Start-Process PowerShell -Verb RunAS }
function Open-PowershellCoreAdmin { Start-Process pwsh -Verb RunAS }

Export-ModuleMember -Function Open-PowershellAdmin,Open-PowershellCoreAdmin
function CloseComputer 
{
    param(
        [int]
        [Alias("t")]
        $Time = 60,
        [switch]
        [Alias("n")]
        $Now
    )
    if($Now){
        Stop-Computer
    } else {
        Write-Host "Computer will be shutdown after $Time seconds."
        shutdown -s -t $Time
    }
}
function StopShutdown { shutdown -a }

function RestartComputer 
{
    param(
        [int]
        [Alias("t")]
        $Time = 60,
        [switch]
        [Alias("n")]
        $Now
    )
    if(-not $Now){
        Write-Host "Computer will be restart after $Time seconds."
        Start-Sleep -Seconds $Time
    }
    Restart-Computer
}
function StopShutdown { shutdown -a }

Export-ModuleMember -Function CloseComputer, StopShutdown, RestartComputer 
function Get-CommandSource
{
    <#
    .NOTES
    This Function is copying from [Andot(小马哥)](https://github.com/andot/).
    Code from https://coolcode.org/2018/03/19/some-useful-scripts-of-powershell/ .
    #>
    $results = New-Object System.Collections.Generic.List[System.Object];
    foreach ($command in $args)
    {
        $path = (Get-Command $command).Source
        if ($path)
        {
            $results.Add($path);
        }
    }
    return $results;
}

Set-Alias which Get-CommandSource
Export-ModuleMember -Function Get-CommandSource -Alias which

<#  ---------------------------------ILIKEIT---------------------------------  #>

Add-Type -TypeDefinition @" 
using System; 
using System.Runtime.InteropServices;

public class ProcessTime 
{ 
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
    public static extern bool GetProcessTimes(IntPtr handle, 
                                              out IntPtr creation, 
                                              out IntPtr exit, 
                                              out IntPtr kernel,
                                              out IntPtr user);
}
"@

function Measure-Time
{
    [CmdletBinding()]
    param ([scriptblock] $Command,
    [switch] $Silent = $false
    )

    begin
    {
        $creation = 0
        $exit = 0
        $kernel = 0
        $user = 0
        $psi = new-object diagnostics.ProcessStartInfo
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-NoProfile -command $Command"
        $psi.UseShellExecute = $false
    }
    process
    {
        $proc = [diagnostics.process]::start($psi)
        $buffer = $proc.StandardOutput.ReadToEnd()    

        if (!$Silent)
        {
            Write-Output $buffer
        }
        $proc.WaitForExit()
    }

    end
    {
        $ret = [ProcessTime]::GetProcessTimes($proc.handle,
                                      [ref]$creation,
                                      [ref]$exit,
                                      [ref]$kernel,
                                      [ref]$user
                                      )
        $kernelTime = [long]$kernel/10000000.0
        $userTime = [long]$user/10000000.0
        $elapsed = [datetime]::FromFileTime($exit) - [datetime]::FromFileTime($creation)

        Write-Output "Kernel time : $kernelTime"
        Write-Output "User time   : $userTime"
        Write-Output "Elapsed     : $elapsed"
    }
}

Export-ModuleMember -Function Measure-Time

function Get-MyIPAddress
{
    <#
    .SYNOPSIS
    Usage: Get-MyIPAddress [OPTION]...
    .DESCRIPTION
    Through this function, You can gey your current Network IP and same information.
    For example, your Public network Adress or your LAN Adress.
    .LINK
    https://github.com/SidneyLYZhang/PowerShell_profile
    .EXAMPLE
    Get-MyIPAddress -Mode "inner"
    .EXAMPLE
    Get-MyIPAddress -All -Mode "outer"
    .PARAMETER Mode
    There are three supported modes : all, inner and outer. For :
        - all : LAN & Outer IP
        - inner : LAN Information
        - outer : Outer IP
    .PARAMETER All
    This is the switch parameter,when using this option, you can get all information about your network IP.
    #>
    param(
        [ValidateSet("inner","outer","all")]
        [Alias("m")]
        $Mode = "outer",
        [switch] $All
    )
    $data_o = Invoke-RestMethod "http://ip.taobao.com/service/getIpInfo.php?ip=myip";
    $data_i = Get-NetIPConfiguration -Detailed
    $out_data = [Ordered]@{
        IPAddress = $data_o.data.ip;
        ISP = $data_o.data.isp;
        Country = $data_o.data.country
    }
    $inn_data = [Ordered]@{
        IPAddress = $data_i.IPv4Address[0];
        Name = $data_i.NetProfile.Name;
        ComputerName = $data_i.ComputerName[0];
        InterfaceAlias = $data_i.InterfaceAlias[0];
        Gateway = $data_i.IPv4DefaultGateway[0];
        DNSServer = $data_i.DNSServer[0]
    }
    if ($All)
    {
        $result = switch ($Mode){
            "inner" {$data_i}
            "outer" {$data_o.data}
            "all" {@{inner = $data_i; outer = $data_o}}
        }
    } else {
        $result = switch ($Mode){
            "inner" {$inn_data}
            "outer" {$out_data}
            "all" {
                @{
                    Inner = @{
                        IP = $inn_data.IPAddress;
                        Type = $inn_data.Name;
                        From = $inn_data.ComputerName
                    };
                    Outer = @{
                        IP = $out_data.IPAddress;
                        Type = $out_data.ISP;
                        From = $out_data.Country
                    }
                }
            }
        }
    }
    return $result
}

Export-ModuleMember -Function Get-MyIPAddress

function Get-shortURL
{
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [Alias("u")]
        [String]
        $URL,
        [Alias("a")]
        [switch]
        $AllFields,
        [Alias("o")]
        [switch]
        $OutPrint
    )
    begin
    {
        if (-Not ($URL -match "^[hH][tT][tT][pP][sS]{0,}://[/a-zA-Z0-9\._-]{0,}$"))
        {
            $rURL = "http://" + $URL
        } else {
            $rURL = $URL
        }
        $Body = @{
            "url" = $rURL
        }
    }
    process
    {
        $PostBack = Invoke-WebRequest 'https://rel.ink/api/links/' -Body $Body -Method 'POST'
        $ContentBack = $PostBack.Content | ConvertFrom-Json
        $Result = @{
            "ShorterURL" = ("https://rel.ink/" + $ContentBack.hashid.ToString());
            "Information" = $ContentBack
        }
    }
    end
    {
        if ($OutPrint) {
            Write-Host "`nShort URL : " -NoNewline
            Write-Host $Result.ShorterURL -ForegroundColor Green
            if ($AllFields)
            {
                $Keys = ($Result.Information | Get-Member -MemberType "NoteProperty").Name
                Write-Host "`nAll Information : "
                foreach ($item in $Keys)
                {
                    switch ($item)
                    {
                        "url" { Write-Host ("`tOriginal URL`t: " + $Result.Information.url) -ForegroundColor Cyan }
                        "hashid" { Write-Host ("`tHashID`t`t: " + $Result.Information.hashid) -ForegroundColor Cyan }
                        "created_at" { Write-Host ("`tCreated at`t: " + $Result.Information.created_at) -ForegroundColor Cyan }
                    }
                }
            }
            Write-Host "`n"
        } else {
            if ($AllFields) {
                return $Result
            } else {
                return $Result.ShorterURL
            }
        }
    }
}

Export-ModuleMember -Function Get-shortURL

<#
https://newsapi.org/docs/get-started
https://www.potterapi.com/
https://bhagavadgita.io/api/
https://hitokoto.cn/api
#>

<#  ---------------------------------INSTALL---------------------------------  #>
function Start-pip
{
    param(
        [ValidateSet("Aliyun","Tuna","USTC","Netease","Offical")]
        [Alias("s")]
        $Source = "Aliyun",
        [switch]
        [Alias("r")]
        $Renew,
        [string]
        [Alias("p")]
        $Package = "requirements",
        [string]
        [Alias("v")]
        $PyVersion = "3.6"
    )
    $pipserver = switch ($Source){
        "Aliyun" {"https://mirrors.aliyun.com/pypi/simple/"}
        "Tuna" {"https://pypi.tuna.tsinghua.edu.cn/simple"}
        "USTC" {"https://mirrors.ustc.edu.cn/pypi/web/simple"}
        "Netease" {"https://mirrors.163.com/pypi/simple/"}
        "Offical" {""}
    }
    $repfile = "C:\Users\alfch\AppData\StaticData\requirements_" + $PyVersion + ".txt"
    $dopython = "-NoProfile write-host `"`n`";py -" + $PyVersion + " -m pip"
    $pluspy = "write-host `"`n`";py -" + $PyVersion + " -m pip"
    if (-Not $(Test-Path $repfile)) {
        start-process -FilePath "powershell" -ArgumentList ($dopython + " freeze | Out-File " + $repfile + ";exit") -WindowStyle hidden
    }
    if( $Renew )
    {
        if( $pipserver -eq "" ){
            start-process -FilePath "powershell" -ArgumentList ($dopython + " install --upgrade pip" + ";exit") -NoNewWindow
        } else {
            start-process -FilePath "powershell" -ArgumentList ($dopython + " install -i " + $pipserver + " --upgrade pip;exit") -NoNewWindow
        }
    }
    if ( $Package -eq "pip" ) {
        if ( $Renew ) {
            Write-Host "pip has upgraded successfully."
        } else {
            if( $pipserver -eq "" ){
                start-process -FilePath "powershell" -ArgumentList ($dopython + " install --upgrade pip" + ";exit") -NoNewWindow
            } else {
                start-process -FilePath "powershell" -ArgumentList ($dopython + " install -i " + $pipserver + " --upgrade pip;exit") -NoNewWindow
            }
        }
    } else {
        if( $pipserver -eq "" ){
            if ( $Package -eq "requirements" ) {
                $packages = Get-Content $repfile
                foreach ($theline in $packages) {
                    $pack = ($theline.split("=="))[0]
                    Write-Host "`n===============================================================================`n"
                    Write-Host ("#`t" + $pack + "`n")
                    start-process -FilePath "powershell" -ArgumentList ($dopython + " install --upgrade " + $pack + ";exit") -NoNewWindow
                }
            } else {
                $docommends = $dopython + " install --upgrade " + $Package + ";" + $pluspy + " freeze | Out-File " + $repfile + ";exit"
                start-process -FilePath "powershell" -ArgumentList $docommends -NoNewWindow
            }
        } else {
            if ( $Package -eq "requirements" ) {
                $packages = Get-Content $repfile
                foreach ($theline in $packages) {
                    $pack = ($theline.split("=="))[0]
                    Write-Host "`n===============================================================================`n"
                    Write-Host ("#`t" + $pack + "`n")
                    start-process -FilePath "powershell" -ArgumentList ($dopython + " install -i " + $pipserver + " --upgrade " + $pack) -NoNewWindow
                }
            } else {
                $docommends = $dopython + " install -i " + $pipserver + " --upgrade " + $Package + ";" + $pluspy + " freeze | Out-File " + $repfile + ";exit"
                start-process -FilePath "powershell" -ArgumentList ($docommends) -NoNewWindow
            }
        }
    }
}

Export-ModuleMember -Function Start-pip

function RunAsAdmin
{
    start-process -FilePath "powershell" -ArgumentList "-NoProfile -NoLogo" -NoNewWindow
}

Export-ModuleMember -Function RunAsAdmin

<#  ---------------------------------WORKING---------------------------------  #>
function Test-CommandExist 
{
    param(
        [switch]
        [Alias("f")]
        $Full
    )
    begin {
        try{
            $tip = Get-Command -ErrorAction "Stop" $args
        }
        catch {
            $tip = ""
        }
    }
    process {
        if($tip -eq ""){
            $so = $False
        } else {
            $so = $True
        }
        $result = @{
            "Information" = $tip;
            "Result" = $so
        }
    }
    end {
        if ($Full){
            return $result
        } else {
            return $result.Result
        }
    }
}

Export-ModuleMember -Function Test-CommandExist

function Head($file, $lines){
    Get-Content $file -TotalCount $lines -encoding utf8
}

Export-ModuleMember -Function Head

function Tail($file, $lines){
    Get-Content $file -Tail $lines -encoding utf8
}

Export-ModuleMember -Function Tail
<#  ------------------------------WelcomeScreen------------------------------  #>
function GET-NowWeather
{
    <#
    .SYNOPSIS
    Usage: GET-NowWeather -userkey ...
    .DESCRIPTION
    获取当前天气状态...
    .LINK
    https://github.com/SidneyLYZhang/PowerShell_profile
    .EXAMPLE
    GET-NowWeather -userkey "-----------"
    .PARAMETER USERKEY
    userkey should be got from heweather.
    #>
    param(
        [String]
        [Alias("k")]
        $userkey,
        [switch]
        [Alias("s")]
        $OutString
    )
    $path = "https://free-api.heweather.net/s6/weather/now?location=auto_ip&lang=en&key=";
    $data = Invoke-RestMethod ($path+$userkey);
    $timenow = Get-Date;
    $results = [ordered]@{
        1 = ("Current Weather" , $data.HeWeather6.now.cond_txt);
        2 = ("Current Temperature" , ("{0:0.0} Celsius" -f $data.HeWeather6.now.tmp));
        3 = ("Somatosensory Temperature" , ("{0:0.0} Celsius" -f $data.HeWeather6.now.fl));
        4 = ("Humidity" , ($data.HeWeather6.now.hum + "%"));
        5 = ("Wind" , ($data.HeWeather6.now.wind_dir + $data.HeWeather6.now.wind_spd + " Level"));
        6 = ("Visibility" , ($data.HeWeather6.now.vis + " Kilometers"))
    }
    if ($OutString) {
        $rests = New-Object System.Collections.Generic.List[System.Object];
        $rests.Add($timenow.ToString("yyyy-MM-dd,HH:mm:ss"));
        foreach ($item in $results.Values) {
            $rests.Add(($item[0] + ":" +$item[1]))
        }
        return $rests
    } else {
        Write-Host ($timenow.ToString("D") + $timenow.ToString("dddd") + $timenow.ToString("T"))
        $results.Keys | foreach {
            $tx = "$($results[$_-1][0]) : $($results[$_-1][1])";
            Write-Host $tx
        }
        Write-Host "`n"
    }
}

Export-ModuleMember -Function GET-NowWeather

function Get-WelcomeScreen
{
    $timenow = Get-Date;
    $pointone = Get-Date ($timenow.ToString("D") + " 10:00:00")
    $pointtwo = Get-Date ($timenow.ToString("D") + " 14:00:00")
    $pointthree = Get-Date ($timenow.ToString("D") + " 18:00:00")
    if ($timenow -lt $pointone)
    {
        $message = "Morning, "
    } elseif ($timenow -lt $pointtwo)
    {
        $message = "Hello, "
    } elseif ($timenow -lt $pointthree)
    {
        $message = "Guten Tag, "
    } else {
        $message = "Hi, "
    }
    Write-Ascii ($message + $args + "!") -Fore ([enum]::GetValues([System.ConsoleColor]) | Get-Random)
}

Export-ModuleMember -Function Get-WelcomeScreen