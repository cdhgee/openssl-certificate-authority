[CmdletBinding()]
Param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$Subject,
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$CAPath,
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [ValidateSet("ECDSA", "RSA")]
  [string]$PrivateKeyType,
  [Parameter(Mandatory = $false, ParameterSetName = "RootCA")]
  [switch]$CreateRootCA,
  [Parameter(Mandatory = $false, ParameterSetName = "IntermediateCA")]
  [switch]$CreateIntermediateCA,
  [Parameter(Mandatory = $true, ParameterSetName = "IntermediateCA")]
  [ValidateNotNullOrEmpty()]
  [string]$SigningCAPath
)

Switch ($PSCmdlet.ParameterSetName) {

  "RootCA" {
    $years = 25
  }
  "IntermediateCA" {
    $years = 10
  }
}

$start = [datetime]::Now
$end = $start.AddYears($years)
$duration = ($end - $start).TotalDays


If (-not (Test-Path $CAPath -PathType Container)) {
  New-Item -Path $CAPath -ItemType Directory
}

# Create private key

Switch ($PrivateKeyType) {

  "ECDSA" {
    openssl ecparam -out $CAPath/ecparams.pem -name prime256v1
    openssl genpkey -paramfile $CAPath/ecparams.pem -out $CAPath/private-key.pem
  }
  "RSA" {
    openssl genrsa -out $CAPath/private-key.pem 4096
  }

}

# Create certificate signing request

openssl req -new -sha256 -key $CAPath/private-key.pem -out $CAPath/request.pem -subj $Subject

# Sign certificate; self sign if root CA, use provided cert and key otherwise

Switch ($PSCmdlet.ParameterSetName) {

  "RootCA" {
    openssl x509 -req -sha256 -days $duration -in $CAPath/request.pem -signkey $CAPath/private-key.pem -out $CAPath/certificate.pem -extfile $PSScriptRoot/root-ca-extensions.ext
  }

  "IntermediateCA" {
    openssl x509 -req -days $duration -in $CAPath/request.pem -CA $SigningCAPath/certificate.pem -CAkey $SigningCAPath/private-key.pem -CAcreateserial -out $CAPath/certificate.pem -extfile $PSScriptRoot/intermediate-ca-extensions.ext
  }
}

# Concatenate certificates together into chain file

Get-Content -Path $CAPath/certificate.pem | Out-File -FilePath $CAPath/chain.pem -Encoding utf8

If ($PSCmdlet.ParameterSetName -eq "IntermediateCA") {

  Get-Content -Path $SigningCAPath/chain.pem | Out-File -FilePath $CAPath/chain.pem -Encoding utf8 -Append

}

Pop-Location

