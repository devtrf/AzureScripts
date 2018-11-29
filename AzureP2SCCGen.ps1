<#
    .SYNOPSIS
    Grabs an existing Root Certificate from the Certificate Store and generates Self-Signed Certificates to be used for Azure Point-to-Site VPN configuration.
       
    .DESCRIPTION
    Full description:      Some of the code has been re-used from Oliver Hurn's Azure P2S Script that generates a new Root Certificate alongside the X amount of Client Certificates.
                           This script was created to address the re-issuing of new Client Certificates with an existing Root Certificate.
    Supported: Yes
    Prerequisites: Yes - Windows 10 or Windows Server 2016
    Makes changes: Yes
    
    .EXAMPLE
    Full command: AzureP2SCCertGen.ps1
           
    .OUTPUTS
    Example:
   
    ---------------------------------
     Azure P2S Client Certificate Generator 
    ---------------------------------

    OS Verification complete: Windows Server 2016 or higher.

    Retrieving the list of installed certificates.
    Fetching the thumbprint...

    How many Client Point-to-Site certificates would you want to create?: 3
    Generating 3 Client Certificates from Root Certificate [CN=HCWDRRootCert]....

    Client Certificate(s) have been succcessfully generated into the 'Cert:\CurrentUser\My' Store.

    Exporting certificates to .pfx format...


    Client SSL Certificate Export Report:

    Common Name  : [Subject]
    CN=MainRootCert

    [Issuer]
    CN=RootCert

    [Serial Number]
    624C5666A281B198400F4C793C23FF2B

    [Not Before]
    9/17/2018 3:09:55 PM

    [Not After]
    9/17/2019 3:29:55 PM

    [Thumbprint]
    0ECE8A3675C642A1EFEA93E357FCDD837760D104

    Certificates : 3
    Directory    : C:\rs-pkgs\
    Password     : s0m3p4ssw0rd

    Subject                 Thumbprint
    -------                 ----------
    CN=ClientCert1 B2F7F52C925493B089AEF03985499E167DBD9307
    CN=ClientCert2 D07C7720E82540329FFC83AD567E86D98ECDD0D8
    CN=ClientCert3 4021DB4143BB2755AB2AE9B3C09F5D08FED6N72B

        
    .NOTES
    Minimum OS: 2016 
    Minimum PoSh: 5.0

    Version Table:
    Version :: Author             :: Live Date      :: JIRA     :: QC                :: Description
    -----------------------------------------------------------------------------------------------------------
    1.0     :: Tiago Ferreira     :: 29-Nov-2018    :: 000-00      :: J.T. Shoupe       :: Release
#>

try
{
    $osVersion = ([environment]::OSVersion.Version).Major

    if ($osVersion -gt '6')
    {
    #Script title
    Write-Host "---------------------------------" -ForegroundColor Yellow
    Write-Host "  Azure P2S Client Certificate Generator " -ForegroundColor Yellow
    Write-Host "---------------------------------`n" -ForegroundColor Yellow

    Write-host "OS Verification complete: Windows Server 2016 or higher.`n" -ForegroundColor Gray
    #Collect user input for which CN they want to use for the Root certificate
    Write-Host "Retrieving the list of installed certificates." -ForegroundColor Cyan
    $certificate = Get-ChildItem -Path Cert:\CurrentUser\My\ | Out-GridView -PassThru
    Write-Host "Fetching the thumbprint..."
    $cert = $certificate

    #Collect number of client certificates to create
    $uinput = Read-Host "`nHow many Client Point-to-Site certificates would you want to create?"

    #Confirm what what we are creating	
    Write-host "Generating $($uinput) Client Certificates from Root Certificate [$($certificate.Subject)]...." -ForegroundColor Cyan

    #Create number array for client certificate loop
    $array = (1..$uinput)

    #Client certificate loop
    $clientCerts = foreach ($a in $array)
    {
        New-SelfSignedCertificate -Type Custom -DnsName P2SChildCert -KeySpec Signature `
        -Subject "$($certificate.Subject)Client$($a)" -KeyExportPolicy Exportable `
        -HashAlgorithm sha256 -KeyLength 2048 `
        -CertStoreLocation "CERT:\CurrentUser\My" `
        -Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")

    }

    #Confirmation
    Write-Host "`nClient Certificate(s) have been succcessfully generated into the 'Cert:\CurrentUser\My' Store." -ForegroundColor Green
    }
    else
    {
    Write-Host "Operating System must be Windows 10/Windows Server 2016 or higher to include the New-SelfSignedCertificate cmdlet." -ForegroundColor Red
    }

    #password for certiticate export
    $pwd = ConvertTo-SecureString -String "s0m3p4ssw0rd" -Force -AsPlainText

    #directory for certificate export
    $dir = 'C:\rs-pkgs'

    $clientcerts | Select Subject, Thumbprint

    $Num = 1
    $clientcertsList = @()
        foreach ($c in $clientcerts) 

                {
                
                    $item = New-Object PSObject 
                    $item | Add-Member -MemberType NoteProperty -Name "Number" -Value $Num
                    $item | Add-Member -MemberType NoteProperty -Name "Name" -Value $c.Subject.TrimStart("CN=")
                    $item | Add-Member -MemberType NoteProperty -Name "Thumbprint" -Value $c.Thumbprint
                    $clientcertsList +=$item
                    $Num += 1

                }

    Write-Host "Exporting certificates to .pfx format...`n" -ForegroundColor Gray

    foreach ($i in $clientcertsList)

    {
        $CertPath = "Cert:\Currentuser\My\"+($i.Thumbprint)
        $PfXPath = "C:\rs-pkgs\"+$i.Name+".pfx"
        Get-ChildItem -Path $CertPath  | Export-PfxCertificate -FilePath $PfXPath -Password $pwd
    }
 
    Write-Host "`nClient SSL Certificate Export Report:" -ForegroundColor Yellow
    Write-Host "`nCommon Name  : $($certificate)"
    Write-Host "Certificates : $($clientcertsList.Count)"
    Write-Host "Directory    : C:\rs-pkgs\"
    Write-Host "Password     : s0m3p4ssw0rd`n"

}
catch
{
    $ErrMsg = "Powershell exception :: Line# $($_.InvocationInfo.ScriptLineNumber) :: $($_.Exception.Message)"
    Write-Output "Script failed to run`n"
    Write-Output $ErrMsg
}
