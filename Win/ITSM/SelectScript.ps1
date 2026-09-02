# SelectScript.ps1 - Scoped Folder Scanner (Win/ITSM Focus)
$githubUser  = "EnjoyTechGit"
$repoName    = "QuickScripts"
$branch      = "main"
$targetFolder = "Win/ITSM"  # Targeted directory path

$findUrl = "https://github.com/$githubUser/$repoName/find/$branch"

try {
    Write-Host "Scanning https://github.com/$githubUser/$repoName/tree/$branch/$targetFolder for scripts..." -ForegroundColor Cyan
    
    # Download GitHub's file finder index page
    $html = Invoke-RestMethod -Uri $findUrl -Headers @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" } -ErrorAction Stop
    
    # Extract paths strictly matching targetFolder AND ending in .ps1
    $pattern = '"path":"(' + [regex]::Escape($targetFolder) + '/[^"]+\.ps1)"'
    
    $scriptPaths = [regex]::Matches($html, $pattern) | ForEach-Object { 
        $_.Groups[1].Value 
    } | Where-Object { 
        $_ -notlike "*SelectScript.ps1*" -and $_ -notlike "*Menu.ps1*" 
    } | Select-Object -Unique

} catch {
    Write-Host "Failed to scan folder: $_" -ForegroundColor Red
    return
}

if (-not $scriptPaths -or $scriptPaths.Count -eq 0) {
    Write-Host "No runnable .ps1 scripts found in $targetFolder." -ForegroundColor Yellow
    return
}

# Interactive Menu Loop
do {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "      QuickScripts Menu ($targetFolder)  " -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan

    for ($i = 0; $i -lt $scriptPaths.Count; $i++) {
        # Display short script name alongside full path
        $scriptName = Split-Path $scriptPaths[$i] -Leaf
        Write-Host (" [{0}] {1}  ({2})" -f ($i + 1), $scriptName, $scriptPaths[$i]) -ForegroundColor Yellow
    }
    Write-Host "`n [Q] Quit`n" -ForegroundColor Gray

    $selection = Read-Host "Select a script number to execute"

    if ($selection -eq 'Q' -or $selection -eq 'q') { break }

    if ($selection -match '^\d+$' -and [int]$selection -le $scriptPaths.Count -and [int]$selection -gt 0) {
        $relativePath = $scriptPaths[[int]$selection - 1]
        $rawUrl = "https://raw.githubusercontent.com/$githubUser/$repoName/$branch/$relativePath"
        
        Write-Host "`nFetching and running: $relativePath..." -ForegroundColor Cyan
        
        try {
            $code = Invoke-RestMethod -Uri $rawUrl -Headers @{ "User-Agent" = "Mozilla/5.0" } -ErrorAction Stop
            $sb = [scriptblock]::Create($code)
            & $sb
        } catch {
            Write-Host "Error executing script: $_" -ForegroundColor Red
        }
        
        Write-Host "`nExecution finished. Press Enter to return to menu..." -ForegroundColor Gray
        Read-Host
    } else {
        Write-Host "Invalid selection. Press Enter to retry..." -ForegroundColor Red
        Read-Host
    }
} while ($true)
