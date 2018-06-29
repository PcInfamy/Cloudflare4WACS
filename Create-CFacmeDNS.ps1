﻿#requires -version 5
<#
.SYNOPSIS
Cloudflare DNS create script for WACS. 
 
.DESCRIPTION
Cloudflare DNS create script for WACS.
 
.PARAMETER Hostname
Hostname that's being validated.

.PARAMETER Name
Name of the TXT record to create.

.PARAMETER Content
Content of the TXT record to create.
 
.INPUTS
Credential file saved at $PSRoot\Cloudflare.xml. Create file with Create-CFXMLCredFile.ps1.
 
.OUTPUTS
Powershell transcript written to $env:TEMP
 
.NOTES
Author:         Andrew Zbikowski <andrew@itouthouse.com>
Revision History
2018-06-29: Initial script development
 
.EXAMPLE
<Example goes here. Repeat this attribute for more than one example>
#>
 
#-------------[Parameters]-----------------------------------------------------
# Enable -Debug, -Verbose Parameters. Write-Debug and Write-Verbose!
[CmdletBinding()]

# WACS will call the provided script with three parameters, but not specificy paramenters. 
# Order of incoming parameters is important.  
Param (
    [Parameter(Mandatory=$true,Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]$Hostname,
    [Parameter(Mandatory=$true,Position=1)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,
    [Parameter(Mandatory=$true,Position=2)]
    [ValidateNotNullOrEmpty()]
    [string]$Content
)

#-------------[Initializations]------------------------------------------------
 
#Set Error Action to Silently Continue
#$ErrorActionPreference = "SilentlyContinue"
Import-Module pscloudflare -ErrorAction Stop
 
#-------------[Declarations]---------------------------------------------------

# ISO 8601 Date Format. Accept no substitutes! 
$iso8601 = Get-Date -Format s
# Colon (:) isn't a valid character in file names.
$iso8601 = $iso8601.Replace(":","_")
# Transcript File
$TranscriptFile = $env:TEMP + '\' + $iso8601 + '_CFacmeCreateDNS.txt'
 
#-------------[Functions]------------------------------------------------------
. $PSRoot + '\Decrypt-CredXML.ps1' 
 
#-------------[Execution]------------------------------------------------------
 
Start-Transcript -Path $TranscriptFile

<# Pseudocode
 
Logic, flow, etc.

Connect-CFClientAPI [-APIToken] <String> [-EmailAddress] <String>
Get-CFZoneID -Zone 'contoso.com'
Add-CFDNSRecord [[-ZoneID] <String>] [-RecordType] <CFDNSRecordType> [-Name] <String> [-Content] <String> [[-TTL] <Int32>] [[-Proxied] <CFDNSOrangeCloudMode>]
Get-CFDNSRecord [[-ZoneID] <String>] [[-ID] <String>] [[-RecordType] <CFDNSRecordType>] [[-Name] <String>] [[-PerPage] <Int32>] [[-Order] <String>] [[-Direction] <String>] [[-MatchScope] <String>]
End Pseudocode #>

# Get the ZoneID from the domain and TLD. 
$pattern = '^.*\.(.*\..*)$'
$DNSZone = $Hostname -split $pattern
$DNSZoneID = Get-CFZoneID -Zone $DNSZone

# Add the DNS Record
Add-CFDNSRecord -ZoneID $DNSZoneID -RecordType TXT -Name $Name -Content $Content

# Verify the DNS Record
$result = Get-CFDNSRecord -ZoneID $DNSZoneID -RecordType TXT -Name $Name
# Not 100% sure what this returns. 
if ($result -eq $Content) {
    Write-Host "All good"
} else {
    Write-Host "Error: result does not match."
    Write-Host $result
}
Stop-Transcript
