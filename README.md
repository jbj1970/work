# Work
This project is for automatic inspection of installed files on a Windows system (file product names, file product versions, file copyrights, validation of file signatures etc.). 

The goal is to be able to run a PowerShell script or command calling one or more PowerShell functions like:
```
<file path> | <PS function> | <PS function>
```
which will traverse and look for all installer files in `<file path>` and for each one install it in a docker image. Then to generate a report with all relevant information about the relevant files installed.

## Prerequisites
The prerequisites are:
- Windows OS version compatible with docker image mcr.microsoft.com/windows/servercore:1909 (e.g. Windows OS Build 18363.1256)
- Windows Powershell 7.1 (5.1 might work as well)

## Development perspective
- Assemble a docker image with a PowerShell inspection script running inside the docker container. The script will be invoked by the host
- Traverse the specified `file path` on the host looking for installer files
- Convenient functions (mostly related to docker) are put into a Powershell profile
