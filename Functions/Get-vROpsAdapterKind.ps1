Function Get-vROpsAdapterKind{
	<#
		.Synopsis
			Collects AdapterKinds from vROps via REST API.

		.DESCRIPTION
			Collects AdapterKinds from vROps Operations Manager server via REST API.

		.PARAMETER OMServer
			FQDN or IP address of Operations Manager server to connect to.

		.PARAMETER AuthToken
			Authorisation Token that has been generated previously, either via Connect-vROpsRASession or another method.

		.PARAMETER AuthResource
			Authorisation Resource object that has been generated previously, either via Connect-vROpsRASession or another method.

		.EXAMPLE
			$AuthToken = (Connect-vROpsRASession -OMServer vROpsOMServer.CentralIndustrial.eu -Credentials $OMCreds).Token
			Get-vROpsAdapterKind -OMServer vROpsOMServer.CentralIndustrial.eu -AuthToken $AuthToken

		.EXAMPLE
			$AuthResource = Connect-vROpsRASession -OMServer 10.11.12.13 -Credentials $OMCreds -UseUntrustedSSLCertificates
			Get-vROpsAdapterKind -OMServer 10.11.12.13 -AuthResource $AuthToken

		.EXAMPLE
			$OMserver = '10.11.12.13'
			$AuthToken = Connect-vROpsRASession -OMServer $OMserver -Credentials $OMCreds -AuthSource "CentralIndustrial"
			Get-vROpsAdapterKind -OMServer $OMserver -AuthToken $AuthToken.Token

		.OUTPUTS
			This will output a list of AdapterKindKeys available to the environment.

		.Notes
			.NOTES
			Author:				Lars Panzerbjørn
			Creation Date:		2019.11.25
			Purpose/Change:		Initial script development

	#>
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory,ParameterSetName="Token")]
		[Parameter(Mandatory,ParameterSetName="Object")]
		[ValidateNotNullOrEmpty()]
		[string]$OMServer,

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

	Begin{
		IF ($PSCmdlet.ParameterSetName -eq "Object") {$AuthToken = $AuthResource.Token}
		$Authorization = "vRealizeOpsToken $AuthToken"
		IF ($Type -eq "JSON") {$RestType = 'application/json'}
		IF ($Type -eq "XML") {$RestType = "application/xml"}
		$Headers = @{Authorization=$Authorization}
		$Headers.Accept += $RestType
		$InvokeRestMethodSplat = @{
			Headers = $Headers
			Method = "GET"
			ContentType = $RestType
		}

		$BaseURL = "https://" + $OMserver + "/suite-api/api/"
		$PageSize = "5000" #Maximum is 10000
		$Page = 0
		$Adapterlist = @()
	}
	Process{
		Try{
			DO{
				Write-Verbose "Page $($Page)"
				$ResourcesURL = $BaseURL + "resources/?page=$page&pageSize=$PageSize" #A stylistic choice was made here to highlight the BaseURL. Page and PageSize weren't so important to highlight.
				$Adapters = Invoke-RestMethod @InvokeRestMethodSplat -Uri $ResourcesURL
				IF ($Type -eq "XML") {$Adapterlist += $Adapters.resources.resource.Resourcekey.adapterkindkey}
				IF ($Type -eq "JSON") {$Adapterlist += $Adapters.resourceList.resourcekey.adapterkindkey}
				$Page++
			}
			UNTIL ((($Adapters.resources.links.link.href | Select -first 1) -eq ($Adapters.resources.links.link.href | Select -last 1)) -AND (($Adapters.links.href | Select -first 1) -eq ($Adapters.links.href | Select -last 1)))
			$Adapterlist = $Adapterlist | Sort-Object | Get-Unique
		}
		Catch [System.Net.WebException]{
			IF (($PSItem | Get-ErrorInfo).Exception -eq 'The remote server returned an error: (401) Unauthorized.'){
				Write-Warning "Failed to login. The remote server returned an error: (401) Unauthorized."
			}
		}
		Catch{
			Write-Warning "Failed to get resources.
				Exception:	$(($PSItem | Get-ErrorInfo).Exception)
				Reason: 	$(($PSItem | Get-ErrorInfo).Reason)
				Fullname:	$(($PSItem | Get-ErrorInfo).Fullname)
			"
		}
	}
	End{
		Return $Adapterlist
	}
}