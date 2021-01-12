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
        if($LastExitCode -eq 1) {
            # simply continue with next item in pipeline
            Write-Error "Could not start container on image $ENV:IMAGETAGCKMS"
            return
        }

        $exeFile = $InstallItem.Name
        try {
            $fileName = ".\$exeFile.txt"
            $hostFile = $InstallItem.FullName
            $exeFilePath = "C:\$exeFile"
            $containerFile = $containerId+":$exeFilePath"
            
            docker stop $containerId > $null
            docker cp $hostFile $containerFile
            docker start $containerId > $null

            docker exec $containerId $exeFilePath /q APPDIR="C:\Installation"

            # TODO: Fix this
            # $installationJob = Start-Job -ScriptBlock {
            #     Invoke-Command -ComputerName $env:COMPUTERNAME -ScriptBlock {
            #         docker exec $containerId $exeFilePath /q APPDIR="C:\Installation"
            #     } 
            # }
            # $installationJob | Wait-Job -Timeout 180
            # if ($installationJob.state -eq 'Running') {
            #     # simply continue with next item in pipeline
            #     Write-Error "Installation of $exeFile timed out after 180 seconds"
            #     return
            # }

            $res = docker exec -e SIGNERTHUMBPRINT=$Thumbprint $containerId "powershell" -File "c:\report.ps1"
            if([string]::IsNullOrEmpty($res)) {
                # simply continue with next item in pipeline
                Write-Error "Could not inspect installed files"
                return
            }
            $res | Format-List | Out-File $fileName
            
            #docker exec -e SIGNERTHUMBPRINT=$Thumbprint $containerId "powershell" -File "c:\report.ps1" | Format-List | Out-File $fileName
        } catch {
            # simply continue with next item in pipeline
            Write-Error "Could not inspect installed files for $exeFile"
        } finally {
            docker kill $containerId > $null
        }
    }
    
    end {
    }
}

$args[0] | Get-CryptomathicMsi | ForEach-Object { Get-CryptomathicReport -InstallItem $_ -Thumbprint "bbc51542eba868c49c5458e9eef556d0d54c2463" }
