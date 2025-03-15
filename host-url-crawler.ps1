# Web Crawler PowerShell Script
# This script crawls all web pages within a specific domain and saves URLs to a text file

param(
    [Parameter(Mandatory=$true)]
    [string]$HostUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxPages = 100
)

# Process input URL to extract hostname and protocol
if ($HostUrl -notmatch '^https?://') {
    $HostUrl = "https://$HostUrl"
}

$uri = [System.Uri]$HostUrl
$protocol = $uri.Scheme
$hostName = $uri.Host

# Set default output file name if not specified
if ([string]::IsNullOrEmpty($OutputFile)) {
    $OutputFile = ".\$hostName-urls.txt"
}

# Initialize variables
$baseUrl = "$protocol`://$hostName"
$urlsToCrawl = New-Object System.Collections.Queue
$urlsCrawled = New-Object System.Collections.Generic.HashSet[string]
$foundUrls = New-Object System.Collections.Generic.HashSet[string]

# Add the starting URL to the queue
$urlsToCrawl.Enqueue($HostUrl) | Out-Null
$foundUrls.Add($HostUrl) | Out-Null

# Function to extract links from HTML content using regex instead of COM objects
function Extract-Links {
    param(
        [string]$html,
        [string]$baseUrl,
        [string]$hostName
    )
    
    $links = @()
    
    # Use regex to find href attributes in anchor tags - properly escaped for PowerShell
    $hrefPattern = '<a\s+(?:[^>]*?\s+)?href=([''"])(.*?)\1'
    $matches = [regex]::Matches($html, $hrefPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    
    foreach ($match in $matches) {
        if ($match.Groups.Count -ge 3) {
            $href = $match.Groups[2].Value.Trim()
            
            # Handle query parameters and fragments
            $href = $href -split '#', 2 | Select-Object -First 1
            
            # Skip empty links, javascript, mailto, tel links
            if ([string]::IsNullOrWhiteSpace($href) -or 
                $href.StartsWith("javascript:") -or 
                $href.StartsWith("mailto:") -or 
                $href.StartsWith("tel:")) {
                continue
            }
            
            # Convert relative URLs to absolute
            if ($href.StartsWith("/")) {
                $href = "$baseUrl$href"
            }
            elseif (-not $href.StartsWith("http")) {
                # Handle relative paths without leading slash
                $href = "$baseUrl/$href"
            }
            
            # Normalize the URL
            try {
                $normalizedUri = [System.Uri]$href
                $normalizedUrl = $normalizedUri.AbsoluteUri
                $links += $normalizedUrl
            }
            catch {
                Write-Verbose "Could not parse URL: $href"
            }
        }
    }
    
    return $links
}

Write-Host "Starting to crawl $HostUrl..."
Write-Host "URLs will be saved to $OutputFile"

# Create or clear the output file
"" | Out-File -FilePath $OutputFile

try {
    # Continue until queue is empty or maximum page count is reached
    while ($urlsToCrawl.Count -gt 0 -and $urlsCrawled.Count -lt $MaxPages) {
        $currentUrl = $urlsToCrawl.Dequeue()
        
        # Skip if already crawled
        if ($urlsCrawled.Contains($currentUrl)) {
            continue
        }
        
        Write-Host "Crawling ($($urlsCrawled.Count + 1)/$MaxPages): $currentUrl"
        
        try {
            # Fetch the page with increased timeout and handling large files
            $response = Invoke-WebRequest -Uri $currentUrl -UseBasicParsing -TimeoutSec 60 -MaximumRedirection 5
            $urlsCrawled.Add($currentUrl) | Out-Null
            
            # Save the URL to the output file
            $currentUrl | Out-File -FilePath $OutputFile -Append
            
            # Extract links from the page
            $links = Extract-Links -html $response.Content -baseUrl $baseUrl -hostName $hostName
            
            foreach ($link in $links) {
                try {
                    # Parse the link URL to get its host
                    $linkUri = [System.Uri]$link
                    $linkHost = $linkUri.Host
                    
                    # Only add URLs from the same host
                    if ($linkHost -eq $hostName -and -not $foundUrls.Contains($link)) {
                        $urlsToCrawl.Enqueue($link) | Out-Null
                        $foundUrls.Add($link) | Out-Null
                    }
                }
                catch {
                    Write-Verbose "Invalid URL format: $link"
                }
            }
            
            # Brief pause to avoid hammering the server
            Start-Sleep -Milliseconds 500
        }
        catch {
            Write-Warning "Failed to crawl $currentUrl`: $_"
        }
    }
    
    Write-Host "Crawling completed. Found $($urlsCrawled.Count) URLs."
    Write-Host "URLs saved to $OutputFile"
}
catch {
    Write-Error "Error occurred: $_"
}