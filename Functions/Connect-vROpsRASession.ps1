Function Connect-vROpsRASession
{
	<#
		.Synopsis
			Connect to vROps Rest API Session.

		.DESCRIPTION
			Connect to vROps Operations Manager server Rest API Session.

		.PARAMETER OMServer
			FQDN or IP address of server to connect to.

		.PARAMETER Credentials
			Credentials of an account that has access.

		.PARAMETER AuthSource
			This is the authoritative source.

		.PARAMETER UseUntrustedSSLCertificates
			Use this if you have untrusted certificates in your environment.

		.EXAMPLE
			$AuthToken = Connect-vROpsRASession -OMServer vROpsOMServer.CentralIndustrial.eu -Credentials $OMCreds

		.EXAMPLE
			$AuthToken = Connect-vROpsRASession -OMServer 10.11.12.13 -Credentials $OMCreds -UseUntrustedSSLCertificates

		.EXAMPLE
			$AuthToken = Connect-vROpsRASession -OMServer 10.11.12.13 -Credentials $OMCreds -AuthSource "CentralIndustrial"

		.OUTPUTS
			Function will return an authentication token that will be used as an Auth token in other functions

		.Notes
			.NOTES
			Version:			0.1
			Author:				Lars Panzerbjørn
			Creation Date:		2019.11.21
			Purpose/Change:		Initial script development

	#>
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory,ParameterSetName="Credentials")]
		[Parameter(Mandatory,ParameterSetName="UsernamePwd")]
		[ValidateNotNullOrEmpty()]
		[string]$OMServer,

		[Parameter(Mandatory,ParameterSetName="UsernamePwd")]
		[ValidateNotNullOrEmpty()]
		[string]$UserName,

		[Parameter(Mandatory,ParameterSetName="UsernamePwd")]
		[ValidateNotNullOrEmpty()]
		[string]$Password,

		[Parameter(Mandatory,ParameterSetName="Credentials")]
		[ValidateNotNullOrEmpty()]
		[System.Management.Automation.PSCredential]$Credentials,
		
		[Parameter(ParameterSetName="Credentials")]
		[Parameter(ParameterSetName="UsernamePwd")]
		[switch]$UseUntrustedSSLCertificates,
		
		[Parameter(ParameterSetName="Credentials")]
		[Parameter(ParameterSetName="UsernamePwd")]
		[ValidateNotNullOrEmpty()]
		[string]$AuthSource
	)

	Begin
	{
		Try
		{
			IF ($UseUntrustedSSLCertificates)
			{
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
			}
		}
		Catch
		{
			$PSItem | Get-ErrorInfo
		}
		#Creating the body for the payload that will be used
		$JsonContentType = 'application/json'
		IF ($PSCmdlet.ParameterSetName -eq "UserNamePwd")
		{
			Write-Verbose "ParameterSetName UsernamePwd"
			$Body = @{
				username = $UserName
				password = $Password
			}
		}
		IF ($PSCmdlet.ParameterSetName -eq "Credentials")
		{
			Write-Verbose "ParameterSetName is Credentials"
			$Body = @{
				username = $Credentials.UserName;
				password = $Credentials.GetNetworkCredential().Password
			}
		}
		IF (!([string]::IsNullOrEmpty($Authsource)))
		{
			$Body.authSource = $Authsource
		}
		## Construct url
		$Uri = "https://$OMserver/suite-api/api/auth/token/acquire"
		Write-Verbose "Uri is $($Uri)"
		$Headers = @{accept=$JsonContentType}
		$Body = $Body | ConvertTo-Json
		$AuthResponseSplat = @{
			Method = "Post"
			Uri = $Uri
			Body = $Body
			ContentType = $JsonContentType
		}
	}
	Process
	{
		Try
		{
			$AuthResponse = Invoke-RestMethod @AuthResponseSplat -Headers $Headers -ErrorAction STOP
		}
		Catch [System.Net.WebException]
		{
			IF (($PSItem|Get-ErrorInfo).Exception -eq "Unable to connect to the remote server")
			{
				Write-Warning "You are unable to connect to the remote server."
				Write-warning "$(($PSItem|Get-ErrorInfo).Exception)"
				Write-warning "$(($PSItem|Get-ErrorInfo).Testing)"
				Return "$(($PSItem|Get-ErrorInfo).Exception)"
			}
			ELSEIF (($PSItem|Get-ErrorInfo).Exception -eq 'The remote server returned an error: (401) Unauthorized.')
			{
				Write-Warning "You are unauthorised to connect to the remote server."
				Write-warning "$(($PSItem|Get-ErrorInfo).Exception)"
				Write-warning "$(($PSItem|Get-ErrorInfo).Testing)"
				Return "$(($PSItem|Get-ErrorInfo).Exception)"
			}
			ELSE
			{
				Write-Warning "You are not allowing untrusted SSL certs. Good, you shouldn't. Please try again using the -UseUntrustedSSLCertificates switch.`n Or even better, fix your certs ;-`)"
				Write-warning "$(($PSItem|Get-ErrorInfo).Exception)"
				Write-warning "$(($PSItem|Get-ErrorInfo).Testing)"
				Return "$(($PSItem|Get-ErrorInfo).Exception)"
			}
		}
		Catch [System.NullReferenceException]
		{
			Write-Warning "Object reference not set to an instance of an object."
			Write-warning "$(($PSItem|Get-ErrorInfo).Exception)"
			Write-warning "$(($PSItem|Get-ErrorInfo).Testing)"
			Return "$(($PSItem|Get-ErrorInfo).Exception)"
		}
		Catch
		{
			Write-Warning "Something Happened"
			Write-warning "$(($PSItem|Get-ErrorInfo).Exception)"
			Write-warning "$(($PSItem|Get-ErrorInfo).Testing)"
			Return "$(($PSItem|Get-ErrorInfo).Exception)"
		}
	}
	End
	{
		Return $AuthResponse
	}
}