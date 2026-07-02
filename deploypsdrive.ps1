#############################################################
# SMB-NewGen Deployment Script
# Author  : Deepak Kushwaha
# Purpose : Copy SMB-NewGen Folder to Multiple Windows Servers
#############################################################

#=============================
# Configuration
#=============================

$SourceFolder = "C:\Users\Administrator\Downloads\SMB-NewGen"

$DestinationFolder = "Users\Administrator\Downloads"

$CsvFile = "C:\scripts\servers.csv"

$LogFile = "C:\scripts\deployment.log"

#=============================
# Validate Source
#=============================

if (!(Test-Path $SourceFolder))
{
    Write-Host ""
    Write-Host "ERROR: Source folder not found." -ForegroundColor Red
    Write-Host $SourceFolder
    exit 1
}

if (!(Test-Path $CsvFile))
{
    Write-Host ""
    Write-Host "ERROR: servers.csv not found." -ForegroundColor Red
    exit 1
}

# Create log file if it doesn't exist
if (!(Test-Path $LogFile))
{
    New-Item -ItemType File -Path $LogFile -Force | Out-Null
}

$Servers = Import-Csv $CsvFile

#=============================
# Start Deployment
#=============================

foreach($Server in $Servers)
{
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "Server : $($Server.Name)"
    Write-Host "IP     : $($Server.IP)"
    Write-Host "==========================================" -ForegroundColor Cyan

    # Remove existing PSDrive if present
    if(Get-PSDrive Z -ErrorAction SilentlyContinue)
    {
        Remove-PSDrive Z -Force
    }

    # Test SMB Port
    $Result = Test-NetConnection $Server.IP -Port 445 -WarningAction SilentlyContinue

    if(!$Result.TcpTestSucceeded)
    {
        Write-Host "Port 445 is NOT reachable." -ForegroundColor Red

        Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$($Server.Name),FAILED,Port 445 Closed"

        continue
    }

    Write-Host "Port 445 Reachable." -ForegroundColor Green

    try
    {
        # Create Credential
        $SecurePassword = ConvertTo-SecureString $Server.Password -AsPlainText -Force

        $Credential = New-Object System.Management.Automation.PSCredential(
            $Server.Username,
            $SecurePassword
        )

        # Map Remote C$
        New-PSDrive `
            -Name Z `
            -PSProvider FileSystem `
            -Root "\\$($Server.IP)\C$" `
            -Credential $Credential `
            -ErrorAction Stop | Out-Null

        # Create Downloads folder if missing
        if (!(Test-Path "Z:\$DestinationFolder"))
        {
            Write-Host "Creating destination folder..."

            New-Item `
                -ItemType Directory `
                -Path "Z:\$DestinationFolder" `
                -Force | Out-Null
        }

        # Remove previous deployment (optional)
        if (Test-Path "Z:\$DestinationFolder\SMB-NewGen")
        {
            Write-Host "Removing old SMB-NewGen folder..."

            Remove-Item `
                "Z:\$DestinationFolder\SMB-NewGen" `
                -Recurse `
                -Force
        }

        # Copy Folder
        Write-Host "Copying SMB-NewGen folder..."

        Copy-Item `
            $SourceFolder `
            "Z:\$DestinationFolder\" `
            -Recurse `
            -Force

        Write-Host ""
        Write-Host "Deployment Successful." -ForegroundColor Green

        Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$($Server.Name),SUCCESS"

        Remove-PSDrive Z -Force
    }
    catch
    {
        Write-Host ""
        Write-Host $_.Exception.Message -ForegroundColor Red

        Add-Content $LogFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$($Server.Name),FAILED,$($_.Exception.Message)"

        if(Get-PSDrive Z -ErrorAction SilentlyContinue)
        {
            Remove-PSDrive Z -Force
        }
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host " Deployment Completed"
Write-Host "==========================================" -ForegroundColor Green
