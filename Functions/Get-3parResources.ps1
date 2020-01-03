Function Get-3parResources # This funtion retreives the relationships for a vROPs object
{
	$OMserver = '10.44.236.35'

#Allow untrusted SSL Certs
add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
	public bool CheckValidationResult(
		ServicePoint srvPoint, X509Certificate certificate,
		WebRequest request, int certificateProblem) {
		return true;
	}
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

	$RelationReport = @()
 
	$Body = @{
	username = 's-dv-ct-data';
	authSource = 'infocorp';
	password = '7?6Wa(#T)Lem4@E'
	} | ConvertTo-Json

	#Call vRops API
	$Uri = "https://$OMserver/suite-api/api/auth/token/acquire"
	$JsonContentType = 'application/json'
	$AuthResponse = Invoke-RestMethod -Method Post -Uri $Uri -Body $Body -ContentType $JsonContentType -Headers @{accept=$JsonContentType} 
	$AuthToken = $AuthResponse.token
	$Authorization = "vRealizeOpsToken $AuthToken"
	$Headers = @{accept=$JsonContentType; Authorization=$Authorization}
	
	$BaseURL = "https://" + $OMserver + "/suite-api/api/"
	$PageSize = "5000" #Maximum is 5000
	$Page = 0
	$Type = "application/json"
	$Resourcelist = @()

	DO
	{
	Write-Verbose "Page $($Page)" -verbose
	$ResourcesURL = "https://$OMserver/suite-api/api/resources/?page=$page&pageSize=$PageSize"
	$ResourcesJSON = Invoke-RestMethod -Method GET -Uri $ResourcesURL -Headers $Headers -ContentType $Type
	$Resourcelist += $ResourcesJSON.resourceList
	$Page++

	}
	UNTIL (($ResourcesJSON.links.href | Select -first 1) -eq ($ResourcesJSON.links.href | Select -last 1))

	#$Resourcelist.Count #Here for testing
	Return $Resourcelist
}
