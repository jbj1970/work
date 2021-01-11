function Get-CryptomathicMsi {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $RootPath
    )
    
    begin {
    }
    
    process {
        Get-ChildItem -Path "$Input" -Include *.exe -Recurse | ForEach-Object {
            $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_.FullName)
            $auth = Get-AuthenticodeSignature -FilePath $_.FullName
            if(($null -ne $auth -and $auth.Status.ToString().ToUpper() -eq "VALID" -and $null -ne $auth.SignerCertificate -and $auth.SignerCertificate.Thumbprint.toLower() -eq "bbc51542eba868c49c5458e9eef556d0d54c2463") -and
               ($null -ne $versionInfo.FileDescription -and $versionInfo.FileDescription.ToUpper().Contains("INSTALLER"))) {
                $item = [PSCustomObject]@{
                    Name = $_.Name
                    FullName = $_.FullName
                }
                Write-Output $item
            }
        }
    }
    
    end {
    }
}

function Get-CryptomathicReport {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $InstallItem,
        [Parameter(ValueFromPipeline = $true)]
        $Thumbprint
    )
    
    begin {
    }
    
    process {
        Write-Host $InstallItem.Name
        $containerId = docker run -it -d $ENV:IMAGETAGCKMS

        $exeFile = $InstallItem.Name
        $fileName = ".\$exeFile.txt"
        $hostFile = $InstallItem.FullName
        $exeFilePath = "C:\$exeFile"
        $containerFile = $containerId+":$exeFilePath"

        docker stop $containerId
        docker cp $hostFile $containerFile
        
        docker start $containerId
        docker exec $containerId $exeFilePath /q APPDIR="C:\Installation"
        $res = docker exec -e SIGNERTHUMBPRINT=$Thumbprint $containerId "powershell" -File "c:\report.ps1"
        docker kill $containerId
        
        $res | Format-List | Out-File $fileName
    }
    
    end {
    }
}

#$args[0] | Get-CryptomathicMsi | ForEach-Object { Get-CryptomathicReport -InstallItem $_ -Thumbprint "bbc51542eba868c49c5458e9eef556d0d54c2463" }
"C:\docker\ckms\1.20.0 RC1\Addons\Listeners" | Get-CryptomathicMsi | ForEach-Object { Get-CryptomathicReport -InstallItem $_ -Thumbprint "bbc51542eba868c49c5458e9eef556d0d54c2463" }
