$ENV:IMAGETAGCKMS = "ckms"

function New-ImageCkms {
    param (
        $ImageFolder
    )
    
    docker build -t $ENV:IMAGETAGCKMS $ImageFolder
}

function Remove-DanglingImagesCkms {
    
    docker rmi -f $(docker images -f "dangling=true" -q)
}