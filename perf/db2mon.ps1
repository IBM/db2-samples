<#
.SYNOPSIS

Collects and reports performance metrics against a Db2 database. 

.DESCRIPTION

The db2mon.ps1 script executes a set of (CLP) db2 statements that uses the lightweight in-memory monitoring interfaces
to  collect monitoring data for a specific period of time, to generate a usefull set of performance metrics. 

.PARAMETER dbName
Specifies the target database name.

.PARAMETER monitorTime
Specifies monitor interval time in seconds, the script will capture the metrics.

.INPUTS

None. You cannot pipe objects to db2mon.ps1.

.OUTPUTS

None Powershell .Net objects. The script just writes regular text to the console. 
The output can be redirected to a file. 

.EXAMPLE

PS> .\db2mon.ps1 SAMPLE

.EXAMPLE

PS> .\db2mon.ps1 -dbName SAMPLE -monitorTime 60 

.LINK

https://www.ibm.com/support/knowledgecenter/SSEPGG_11.5.0/com.ibm.db2.luw.admin.perf.doc/doc/t0070377.html

#>



Param(
    #dbName
    [Parameter(Mandatory=$true, Position=1)]
    [string]$dbName,
    
    [Parameter(Mandatory=$false, Position = 2)]
    [int]$monitorTime 
)

$scriptRoot = (Split-Path $MyInvocation.MyCommand.Definition)

Set-Item -Path env:DB2CLP -value "**$$**"
# Remove any user settings
if ( Test-Path -Path env:DB2OPTIONS ) {
    Remove-Item -Path env:DB2OPTIONS 
}

if ([string]::IsNullOrEmpty($dbName) ) { 
    Write-Host "Specify a database to connect to!"
    Write-Host "Usage:"
    Write-Host "  db2mon.ps1 <DBNAME> [interval]"
    Write-Host ""
    Write-Host "If no interval is specified, script will wait for user input to break data collection!"
    exit 1
}

if ( $monitorTime -ne $null ) {

    if ( $monitorTime -gt 0  ) {
        Write-Host "Monitoring interval set to $monitorTime seconds"
    }
    if ($monitorTime -lt 0  ) {
        Write-Host "Error: Monitoring interval $monitorTime is negative - only positive intervals are supported"
        exit 2 
    }
}
    

Write-Host "Scripts should be found in $scriptRoot"

db2 -v connect to $dbName
db2 -v create bufferpool db2monbp
db2 -v create user temporary tablespace db2montmptbsp bufferpool db2monbp

db2 +c -tvf $scriptRoot/db2monBefore.sql

# Earlier versions did not offer a easily changable monitor time
if (  $monitorTime -eq $null ) {
    db2 +c -tvf $scriptRoot/db2monInterval.sql
} else {
    if ( $monitorTime -eq 0 ) {
        $void = Read-Host -Prompt "Hit enter to finish monitoring:"
        Remove-Variable -Name void
    } else {
        Start-Sleep -Seconds $monitorTime
    }
    
}


db2 +c -tvf $scriptRoot/db2monAfter.sql

db2 -v commit work
db2 -v connect reset
db2 -v connect to $dbName

db2 -v drop tablespace db2montmptbsp
db2 -v drop bufferpool db2monbp

db2 -v connect reset