Function Get-vROpsResources
{
	<#
		.Synopsis
			Collects resources from vROps via REST API.

		.DESCRIPTION
			Collects resources from a vROps Operations Manager server via REST API.

		.PARAMETER OMServer
			FQDN or IP address of Operations Manager server to connect to.

		.PARAMETER ResourceKind
			This is the Resource Kind to be looking for.

		.PARAMETER AuthToken
			Authorisation Token that has been generated previously, either via Connect-vROpsRASession or another method.

		.PARAMETER AuthResource
			Authorisation Resource object that has been generated previously, either via Connect-vROpsRASession or another method.

		.EXAMPLE
			$AuthToken = (Connect-vROpsRASession -OMServer vROpsOMServer.CentralIndustrial.eu -Credentials $OMCreds).Token
			Get-vROpsResources -OMServer vROpsOMServer.CentralIndustrial.eu -AuthToken $AuthToken -ResourceKind "HPE3PAR_ADAPTER"

		.EXAMPLE
			$AuthResource = Connect-vROpsRASession -OMServer 10.11.12.13 -Credentials $OMCreds -UseUntrustedSSLCertificates
			Get-vROpsResources -OMServer 10.11.12.13 -AuthResource $AuthResource -ResourceKind "VMWARE"

		.EXAMPLE
			$OMserver = '10.11.12.13'
			$AuthToken = Connect-vROpsRASession -OMServer $OMserver -Credentials $OMCreds -AuthSource "CentralIndustrial"
			Get-vROpsResources -OMServer $OMserver -AuthToken $AuthToken.Token -ResourceKind "VMWARE"

		.OUTPUTS
			This will output a list of resources of the kind specified.

		.Notes
			.NOTES
			Version:			1.0
			Author:				Lars Panzerbjørn
			Creation Date:		2019.11.22
			Purpose/Change:		Initial script development

	#>
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory,ParameterSetName="Token")]
		[Parameter(Mandatory,ParameterSetName="Object")]
		[ValidateNotNullOrEmpty()]
		[string]$OMServer,

		[Parameter(ParameterSetName="Token")]
		[Parameter(ParameterSetName="Object")]
		[string]$ResourceKind,

		[Parameter(Mandatory,ParameterSetName="Token")]
		[ValidateNotNullOrEmpty()]
		[PSObject]$AuthToken,

		[Parameter(Mandatory,ParameterSetName="Object")]
		[ValidateNotNullOrEmpty()]
		[PSObject]$AuthResource,

		[Parameter(ParameterSetName="Token")]
		[Parameter(ParameterSetName="Object")]
		[ValidateSet('JSON', 'XML')]
		[string]$Type="JSON"
	)

	Begin
	{
		Write-Verbose "Beginning"
		$BaseURL = "https://" + $OMserver + "/suite-api/api/"
		$PageSize = "5000" #Maximum is 10000
		$Page = 0
		$Resourcelist = @()
		IF ($PSCmdlet.ParameterSetName -eq "Object") {$AuthToken = $AuthResource.Token}
		$Authorization = "vRealizeOpsToken $AuthToken"
		$InvokeRestMethodSplat = @{}
		$InvokeRestMethodSplat.Method = "GET"
		IF ($Type -eq "JSON") {$RestType = 'application/json'}
		IF ($Type -eq "XML") {$RestType = "application/xml"}
		$Headers = @{Authorization=$Authorization}
		IF (!([string]::IsNullOrEmpty($RestType)))
		{
			$Headers.Accept = $RestType
			$InvokeRestMethodSplat.ContentType = $RestType
		}
		$InvokeRestMethodSplat.Headers = $Headers
	}
	Process
	{
		Write-Verbose "Processing"
		Try
		{
			DO
			{
				Write-Verbose "Page $($Page)"
				IF (!([string]::IsNullOrEmpty($ResourceKind))) {$ResourcesURL = $BaseURL + "adapterkinds/" + $ResourceKind + "/resources/?page=$page&pageSize=$PageSize"} #A stylistic choice was made here to highlight thee BaseURL and ResourceKind. Page and PageSize weren't so important to highlight.
				IF ([string]::IsNullOrEmpty($ResourceKind)) {$ResourcesURL = $BaseURL + "resources/?page=$page&pageSize=$PageSize"}
				$Resources = Invoke-RestMethod @InvokeRestMethodSplat -Uri $ResourcesURL -verbose
				$Resourcelist += $Resources.resources.Resource
				$Page++
			}
			UNTIL (($Resources.resources.links.link.href | Select -first 1) -eq ($Resources.resources.links.link.href | Select -last 1))
		}
		Catch [System.Net.WebException]
		{
			IF (($PSItem | Get-ErrorInfo).Exception -eq 'The remote server returned an error: (401) Unauthorized.')
			{
				Write-Warning "Failed to login. The remote server returned an error: (401) Unauthorized."
			}
		}
		Catch
		{
			Write-Warning "Failed to get resources.
				Exception:	$(($PSItem | Get-ErrorInfo).Exception)
				Reason: 	$(($PSItem | Get-ErrorInfo).Reason)
				Fullname:	$(($PSItem | Get-ErrorInfo).Fullname)
			"
		}
	}
	End
	{
		Write-Verbose "Ending"
		Return $Resourcelist
	}
}
