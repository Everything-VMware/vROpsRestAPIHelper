Function Get-vROpsRelationship{
	<#
		.Synopsis
			This funtion retreives the relationships for a vROps object.

		.DESCRIPTION
			This funtion retreives the relationships for a vROps object. A connection must already have been established.

		.PARAMETER OMServer
			FQDN or IP address of Operations Manager server to connect to.

		.PARAMETER ID
			This is the ID of the resource to be investigated.

		.PARAMETER AuthToken
			Authorisation Token that has been generated previously, either via Connect-vROpsRASession or another method.

		.PARAMETER AuthResource
			Authorisation Resource object that has been generated previously, either via Connect-vROpsRASession or another method.

		.EXAMPLE
			$AuthToken = (Connect-vROpsRASession -OMServer vROpsOMServer.CentralIndustrial.eu -Credentials $OMCreds).Token
			$Relationships = Get-vROpsRelationship -OMServer vROpsOMServer.CentralIndustrial.eu -ID $Volume.Id -AuthResource $AuthToken

		.EXAMPLE
			$AuthResource = Connect-vROpsRASession -OMServer 10.11.12.13 -Credentials $OMCreds -UseUntrustedSSLCertificates
			$Relationships = Get-vROpsRelationship -OMServer 10.11.12.13 -ID $Volume.Id -AuthResource $AuthResource

		.OUTPUTS
			This will output The relationship of a resource

		.Notes
			.NOTES
			Version:			1.1
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
		
		[Parameter(Mandatory,ParameterSetName="Token")]
		[Parameter(Mandatory,ParameterSetName="Object")]
		[ValidateNotNullOrEmpty()]
		[string]$ID,
		
		[Parameter(Mandatory,ParameterSetName="Token")]
		[ValidateNotNullOrEmpty()]
		[PSObject]$AuthToken,

		[Parameter(Mandatory,ParameterSetName="Object")]
		[ValidateNotNullOrEmpty()]
		[PSObject]$AuthResource
	)
	Begin{
		IF ($PSCmdlet.ParameterSetName -eq "Object") {$AuthToken = $AuthResource.Token}
		$Authorization = "vRealizeOpsToken $AuthToken"
		$JSONContentType = 'application/json'
		$Headers = @{accept=$JSONContentType; Authorization=$Authorization}
		$Uri = "https://$OMServer/suite-api/api/resources/$ID/relationships"
		#$PageSize = "5000" #Maximum is 10000
		#$Page = 0
		$RelationshipReport = @()
	}
	Process{
		$Relationships = Invoke-RestMethod -Uri $Uri -ContentType $JsonContentType -Headers $Headers
		#Parse the output to get the relationships and add it to a standard object
		ForEach ($Relationship in $Relationships.resourceList){
			$RelationshipReport += New-Object PSObject -Property @{
				ID = $ID
				ChildID = $Relationship.identIFier
				ResourceKind = $Relationship.resourceKey.resourceKindKey
				ResourceName = $Relationship.resourceKey.name
			}
		}
	}
	End{
		Return $RelationshipReport
	}
}
