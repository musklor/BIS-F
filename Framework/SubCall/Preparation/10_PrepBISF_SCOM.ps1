<#
    .SYNOPSIS
        Prepare SCOM Client for Image Managemement
	.Description
      	delete Computer specified entries
    .EXAMPLE
    .Inputs
    .Outputs
    .NOTES
		Author: Matthias Schlimm
      	Company: Login Consultants Germany GmbH
		
		History
      	Last Change: 17.11.2014 MS: Script created for OpsMagr2k7
		Last Change: 19.02.2015 MS: change line 65 to IF ($svc -And (Test-Path $OpsStateDirOrigin))
		Last Change: 04.05.2015 MS: add SCOM 2012 detection, checks 2007 path only 
		Last Change: 30.07.2015 MS: Fix line 39: rename $returnCheckPVSSoftware to $returnTestPVSSoftware
		Last Change: 01.10.2015 MS: rewritten script with standard .SYNOPSIS, use central BISF function to configure service
		Last Change: 03.10.2017 MS: Bugfix 214: Test path if $OpsStateDirOrigin before delete, instead of complete C: content if if $OpsStateDirOrigin is not available
	.Link
#>

Begin {
	$OpsStateDir = "$PVSDiskDrive\OpsStateDir"
	$OpsStateDirOrigin2012 = "$env:ProgramFiles\Microsoft Monitoring Agent\Agent\Health Service State"
	$OpsStateDirOrigin2007 = "$ProgramFilesx86\System Center Operations Manager 2007\Health Service State"
	$servicename = "HealthService"
	$Product = "Microsoft SCOM Agent"
	$script_path = $MyInvocation.MyCommand.Path
	$script_dir = Split-Path -Parent $script_path
	$script_name = [System.IO.Path]::GetFileName($script_path)
}
####################################################################
####### functions #####
####################################################################

Process {

    function ReconfigureAgent
    {
		Write-BISFLog -Msg "remove existing certificates for $product"
        & Invoke-Expression "certutil -delstore ""Operations Manager"" $env:Computername.$env:userdnsdomain"
        
		IF ($returnTestPVSSoftware -eq "true")
        {
			Write-BISFLog -Msg "Citrix PVS Target Device detected, Set StateDirectory to Path $OpsStateDir" 
			Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\services\$servicename\Parameters" -Name "State Directory" -Value "$OpsStateDir"
        } ELSE {
			Write-BISFLog -Msg "Citrix PVS Target Device NOT detected, StateDirectory leave on original path $OpsStateDirOrigin"	
		}
		
		if (Test-Path $OpsStateDirOrigin)
		{
			Write-BISFLog -Msg "Delete Path $OpsStateDirOrigin"
			remove-item -Path "$OpsStateDirOrigin\*" -recurse
   		}
	}


    
####################################################################
####### end functions #####
####################################################################

#### Main Program

	$svc = Test-BISFService -ServiceName "$servicename" -ProductName "$product"
	IF ($svc -eq $true)
	{
		$OpsStateDirOrigin=@()   # set empty variable to check later if Ops/SCOM installed 
		IF (Test-Path $OpsStateDirOrigin2012) {$OpsStateDirOrigin = $OpsStateDirOrigin2012}
		IF (Test-Path $OpsStateDirOrigin2007) {$OpsStateDirOrigin = $OpsStateDirOrigin2007}
		
	    IF ($OpsStateDirOrigin -ne $null)
	    {
		    Write-BISFLog -Msg "Path $OpsStateDirOrigin detected"
		    Invoke-BISFService -ServiceName "$servicename" -Action Stop -StartType manual
		    ReconfigureAgent
	    } ELSE {
		    Write-BISFLog -Msg "$Service $ServiceName detected, but path $OpsStateDirOrigin2012 or $OpsStateDirOrigin2007 not found. $product will not be optimized for Imaging" -Type E -SubMsg
	    }
    }
}

End {
	Add-BISFFinishLine
}
