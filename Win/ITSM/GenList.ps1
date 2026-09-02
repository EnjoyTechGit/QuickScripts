# Configuration
$githubUser  = "EnjoyTechGit"
$repoName    = "QuickScripts"
$branch      = "main"
$folderPath  = "Win/ITSM" # Target folder within the repo

# Paths
$rawBaseUrl  = "https://github.com/$githubUser/$repoName/raw/refs/heads/$branch/$folderPath"
$localDir    = Join-Path $PSScriptRoot $folderPath
$outputFile  = Join-Path $localDir "README.md"

# Generate Markdown Content
$md = @"r
# Command List: $folderPath

Copy and paste any of the commands below directly into an elevated PowerShell prompt to execute the script in-memory.

| Script Name | Description | Execution Command (IEX) |
| :--- | :--- | :--- |
"@

Get-ChildItem -Path $localDir -Filter "*.ps1" | ForEach-Object {
    $fileName = $_.Name
    $rawUrl   = "$rawBaseUrl/$fileName"
    
    # Extract the first comment line starting with '#' as the description (falls back to filename)
    $firstComment = (Get-Content $_.FullName | Where-Object { $_ -match '^\s*#' -and $_ -notmatch '^\s*#\s*Check In' } | Select-Object -First 1)
    $description  = if ($firstComment) { $firstComment -replace '^\s*#\s*', '' } else { "PowerShell script $fileName" }
    
    # Format the table row
    $md += "`n| **$fileName** | $description | ``iex (irm `"$rawUrl`")`` |"
}

# Output README.md
$md | Out-File -FilePath $outputFile -Encoding utf8 -Force
Write-Host "README.md successfully updated at: $outputFile" -ForegroundColor Green