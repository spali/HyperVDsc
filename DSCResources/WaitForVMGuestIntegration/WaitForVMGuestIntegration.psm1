#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename WaitForVMGuestIntegration.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename WaitForVMGuestIntegration.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER Id
Parameter description

.PARAMETER VMName
Parameter description

.PARAMETER RetryIntervalSec
Parameter description

.PARAMETER RetryCount
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory)]
        [String] $Id,

        [Parameter(Mandatory)]
        [String] $VMName,
        
        [Parameter()]
        [UInt64] $RetryIntervalSec = 10,
        
        [Parameter()]
        [UInt32] $RetryCount = 5
    )

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.NoHyperVModule
    }
    
    Write-Verbose -Message ($localizedData.CheckGIS -f $VMName)
    $returnValue = @{
        Id = $Id
        VMName = $VMName
        RetryIntervalSec = $RetryIntervalSec
        RetryCount = $RetryCount
    }
    $returnValue
}

<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER Id
Parameter description

.PARAMETER VMName
Parameter description

.PARAMETER RetryIntervalSec
Parameter description

.PARAMETER RetryCount
Parameter description

.PARAMETER Force
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [String] $Id,
        
        [Parameter(Mandatory)]
        [String] $VMName,

        [Parameter()]
        [UInt64] $RetryIntervalSec = 10,

        [Parameter()]
        [UInt32] $RetryCount = 5,

        [Parameter()]
        [bool] $Force
    )

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.NoHyperVModule
    }

    $vmIntegrationServicesRunning = $false
    Write-Verbose -Message ($localizedData.CheckGIS -f $VMName)

    $vm = Get-VM -Name $VMName

    if ($vm)
    {
        if ($vm.State -eq 'Off' -and $Force)
        {
            Write-Verbose -Message $localizedData.ForcePowerOn
            Start-VM -VM $vm
        }

        for ($count = 0; $count -lt $RetryCount; $count++)
        {
            $gis = Get-VMIntegrationService -VMName $VMName -Name 'Guest Service Interface'
            if ($gis.PrimaryStatusDescription -eq 'OK') {
                Write-Verbose -Message ($localizedData.GISRunning -f $VMName)
                $vmIntegrationServicesRunning = $true
                break
            }
            else
            {
                Write-Verbose -Message ($localizedData.GISNotRunning -f $VMName)
                Write-Verbose -Message ($localizedData.Retry -f $RetryIntervalSec)
                Start-Sleep -Seconds $RetryIntervalSec
            }
        }

        if (!$vmIntegrationServicesRunning)
        {
            throw ($localizedData.CheckError -f $VMName, $RetryIntervalSec)
        }
    }
}

<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER Id
Parameter description

.PARAMETER VMName
Parameter description

.PARAMETER RetryIntervalSec
Parameter description

.PARAMETER RetryCount
Parameter description

.PARAMETER Force
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [String] $Id,

        [Parameter(Mandatory)]
        [String] $VMName,

        [Parameter()]        
        [UInt64] $RetryIntervalSec = 10,
        
        [Parameter()]        
        [UInt32] $RetryCount = 5,

        [Parameter()]
        [bool] $Force
    )

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.NoHyperVModule
    }
    
    $vm = Get-VM -Name $VMName

    if ($vm)
    {
        if ($vm.State -eq 'Off' -and $Force)
        {
            Write-Verbose -Message $localizedData.ForcePowerOn
            Start-VM -VM $vm
        }    
        
        Write-Verbose -Message ($localizedData.CheckGIS -f $VMName)
        $gis = Get-VMIntegrationService -VMName $VMName -Name 'Guest Service Interface'
        if ($gis.PrimaryStatusDescription -eq 'OK') {
            Write-Verbose -Message ($localizedData.GISRunning -f $VMName)
            return $true
        }
        else
        {
            Write-Verbose -Message ($localizedData.GISNotRunning -f $VMName)
            return $false
        }
    }        
}

Export-ModuleMember -Function *-TargetResource
