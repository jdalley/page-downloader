# Webpage Downloader Script
# Takes a list of URLs and downloads each using headless Chrome and monolith
# Organizes downloads by hostname

# Input file containing URLs (one per line)
param (
    [Parameter(Mandatory=$true)]
    [string]$UrlListFile,
    
    [Parameter(Mandatory=$false)]
    [string]$BaseOutputDir = ".\downloads"  # Default output directory
)

# Check if the input file exists
if (-not (Test-Path $UrlListFile)) {
    Write-Error "Input file not found: $UrlListFile"
    exit 1
}

# Create the base output directory if it doesn't exist
if (-not (Test-Path $BaseOutputDir)) {
    New-Item -ItemType Directory -Path $BaseOutputDir | Out-Null
    Write-Host "Created base output directory: $BaseOutputDir" -ForegroundColor Cyan
}

# Read URLs from the input file
$urls = Get-Content $UrlListFile

# Process each URL
foreach ($url in $urls) {
    # Skip empty lines
    if ([string]::IsNullOrWhiteSpace($url)) {
        continue
    }

    try {
        # Parse the URL
        $uri = [System.Uri]$url
        
        # Get the hostname for the folder name
        $hostname = $uri.Host
        
        # Create hostname directory if it doesn't exist
        $hostnameDir = Join-Path -Path $BaseOutputDir -ChildPath $hostname
        if (-not (Test-Path $hostnameDir)) {
            New-Item -ItemType Directory -Path $hostnameDir | Out-Null
            Write-Host "Created directory: $hostnameDir" -ForegroundColor Cyan
        }
        
        # Extract the final part of the path to use as the output filename
        $path = $uri.AbsolutePath.TrimEnd('/')
        $filename = if ($path -eq "/" -or [string]::IsNullOrEmpty($path)) {
            "index"  # Use "index" for the root path
        } else {
            $path.Substring($path.LastIndexOf('/') + 1)
        }
        
        # Ensure filename is valid
        $filename = $filename -replace '[^\w\-.]', '_'
        
        # Add .html extension if not present
        if (-not $filename.EndsWith(".html")) {
            $filename = "$filename.html"
        }
        
        # Full path for the output file
        $outputPath = Join-Path -Path $hostnameDir -ChildPath $filename

        Write-Host "Processing: $url -> $outputPath"

        # Run the download command
        $command = "chrome --headless --window-size=1920,1080 --run-all-compositor-stages-before-draw --virtual-time-budget=9000 --incognito --dump-dom $url | monolith - -I -b $url -o `"$outputPath`""
        
        # Execute the command
        Invoke-Expression $command

        Write-Host "Successfully downloaded: $outputPath" -ForegroundColor Green
    }
    catch {
        Write-Host "Error processing URL: $url" -ForegroundColor Red
        Write-Host $_ -ForegroundColor Red
    }
}

Write-Host "All downloads completed!" -ForegroundColor Cyan