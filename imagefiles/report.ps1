
Get-ChildItem -Path "C:/Installation" -Include *.dll, *.exe -Recurse | ForEach-Object {
    $thumbprint = $env:SIGNERTHUMBPRINT
    $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_.FullName)
    $auth = Get-AuthenticodeSignature -FilePath $_.FullName
    if($null -ne $auth -and $auth.Status.ToString().ToUpper() -eq "VALID" -and $null -ne $auth.SignerCertificate -and $auth.SignerCertificate.Thumbprint.toUpper() -eq $thumbprint.ToUpper()) {
        
        $item = [PSCustomObject]@{
            FullName = $_.FullName
            ProductName = $versionInfo.ProductName
            ProductVersion = $versionInfo.ProductVersion
            FileVersion = $versionInfo.FileVersion
            CopyRight = $versionInfo.LegalCopyright
        }
        Write-Output $item
    }
}