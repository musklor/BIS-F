<#
    .SYNOPSIS
        Prepare SCCM Client for Image Managemement
	.Description
      	delete Computer specified entries
    .EXAMPLE
    .Inputs
    .Outputs
    .NOTES
		Author: Matthias Schlimm
      	Company: Login Consultants Germany GmbH
		
		History
      	Last Change: 26.03.2014 MS: Script created for SCCM 2012 R2
		Last Change: 01.04.2014 MS: change Console message 
		Last Change: 02.05.2014 MS: BUG code-error certstore SMS not deleted > & Invoke-Expression 'certutil -delstore SMS "SMS"'
		Last Change: 11.08.2014 MS: remove Write-Host change to Write-BISFLog
		Last Change: 13.08.2014 MS: remove $logfile = Set-logFile, it would be used in the 10_XX_LIB_Config.ps1 Script only
		Last Change: 19.02.2015 MS: syntax error and errorhandling
		Last Change: 06.03.2015 MS: delete CCM Package Cache
		Last Change: 05.05.2015 MS: #temp. deactivate DeleteCCMCache, some errors more testing
		Last Change: 01.09.2015 MS: bugfix 42 - fixing deleteCCMCahce, this must be running before service stops
		Last Change: 30.09.2015 MS: rewritten script with standard .SYNOPSIS, use central BISF function to configure service
		Last Change:
	.Link
#>


Begin {
	$ccm_path = "C:\Windows\CCM"
	$PSScriptFullName = $MyInvocation.MyCommand.Path
	$PSScriptRoot = Split-Path -Parent $PSScriptFullName
	$PSScriptName = [System.IO.Path]::GetFileName($PSScriptFullName)
	$Product = "Microsoft SCCM Agent"
	$servicename = "CcmExec"
}


Process {
    function deleteCCMData
    {
		Write-BISFLog -Msg "remove existing certificates from SMS store"
        & Invoke-Expression 'certutil -delstore SMS "SMS"'
		
		Write-BISFLog -Msg "reset site key information"
		& Invoke-Expression "WMIC /NAMESPACE:\\root\ccm\locationservices Path TrustedRootKey DELETE"
		
		Write-BISFLog -Msg "Delete Smscfg.ini"
		Remove-Item -Path ${env:WinDir}'\SMSCFG.ini' -Force -ErrorAction SilentlyContinue
	}

    function DeleteCCMCache
    {
        # original source http://www.david-obrien.net/2013/02/how-to-configure-the-configmgr-client/
        [CmdletBinding()]
        $UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr
        $Cache=$UIResourceMgr.GetCacheInfo()
        $CacheElements=$Cache.GetCacheElements()
        foreach ($Element in $CacheElements)
        {
            Write-BISFLog -Msg "Deleting CacheElement with PackageID $($Element.ContentID)"
            Write-BISFLog -Msg "in folder location $($Element.Location)"
            $Cache.DeleteCacheElement($Element.CacheElementID)
         }
    }

 
	$svc = Test-BISFService -ServiceName "$servicename" -ProductName "$product"
	IF ($svc -eq $true)
	{
		DeleteCCMCache  #01.09.2015 MS: DeleteCCMCache must be running before StopService
		Invoke-BISFService -ServiceName "$servicename" -Action Stop -StartType manual
		deleteCCMdata
	}
}

End {
	Add-BISFFinishLine
}
