# Configuration
$githubUser  = "EnjoyTechGit"
$repoName    = "QuickScripts"
$branch      = "main"
$folderPath  = "Win/ITSM" # Target folder within the repo

# Paths
$rawBaseUrl  = "https://github.com/$githubUser/$repoName/raw/refs/heads/$branch/$folderPath"
$localDir    = $PSScriptRoot
$outputFile  = Join-Path $localDir "README.md"

# Generate Markdown Content
$md = @"
# Command List: $folderPath

Copy and paste any of the commands below directly into an elevated PowerShell prompt to execute the script in-memory.

| Script Name | Description | Execution Command (IEX) |
| :--- | :--- | :--- |
"@

Get-ChildItem -Path $localDir -Filter "*.ps1" |
    Where-Object { $_.FullName -ne $PSCommandPath } |
    ForEach-Object {
        $fileName = $_.Name
        $rawUrl   = "$rawBaseUrl/$fileName"
        $commandText = "iex (irm `"$rawUrl`")"
        $jsCommand = $commandText.Replace("'", "&apos;").Replace('"', '&quot;')

        # Extract the first meaningful comment line starting with '#' as the description.
        # Skip internal stage markers like "Check In" and other section labels.
        $firstComment = (Get-Content $_.FullName | Where-Object {
                $_ -match '^\s*#\s*(?!Check In\b|Boarding\b|InFlight\b|Service refreshments\b|Landing\b|End Of The Line\b).+'
            } | Select-Object -First 1)
        $description = if ($firstComment) { ($firstComment -replace '^\s*#\s*', '').Trim() } else { "PowerShell script $fileName" }

        # Format the table row with a copy button
        $md += "`n| **$fileName** | $description | <code>$commandText</code> | <button type=`"button`" onclick=`"navigator.clipboard.writeText('$jsCommand');`">Copy</button> |"
    }

# Output README.md
$md | Out-File -FilePath $outputFile -Encoding utf8 -Force
Write-Host "README.md successfully updated at: $outputFile" -ForegroundColor Green