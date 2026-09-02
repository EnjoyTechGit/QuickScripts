# SelectScript.ps1 - Commit Tree Engine (No API Limits, Full Subfolder Scan)
$githubUser = "EnjoyTechGit"
$repoName   = "QuickScripts"
$branch     = "main"

# GitHub's lightweight raw commit metadata endpoint
$commitUrl = "https://github.com/$githubUser/$repoName/file-list/$branch"

try {
    Write-Host "Scanning repository and subfolders for scripts..." -ForegroundColor Cyan
    
    # Request the full directory file manifest
    $manifest = Invoke-RestMethod -Uri $commitUrl -Headers @{ 
        "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
        "Accept"     = "application/json"
    } -ErrorAction Stop

    # Filter all nested .ps1 files, ignoring menu scripts
    $scriptPaths = $manifest | Where-Object { 
        $_ -like "*.ps1" -and 
        $_ -notlike "*SelectScript.ps1*" -and 
        $_ -notlike "*Menu.ps1*" 
    }
} catch {
    # Failover: Direct search against the HTML commit tree
    try {
        $html = Invoke-RestMethod -Uri "https://github.com/$githubUser/$repoName/find/$branch" -Headers @{ "User-Agent" = "Mozilla/5.0" }
        $pattern = '"path":"([^"]+\.ps1)"'
        $scriptPaths = [regex]::Matches($html, $pattern) | ForEach-Object { $_.Groups[1].Value } | Where-Object {
            $_ -notlike "*SelectScript.ps1*" -and $_ -notlike "*Menu.ps1*"
        } | Select-Object -Unique
    } catch {
        Write-Host "Failed to scan repository: $_" -ForegroundColor Red
        return
    }
}

if (-not $scriptPaths -or $scriptPaths.Count -eq 0) {
    Write-Host "No runnable .ps1 scripts found in any subfolder." -ForegroundColor Yellow
    return
}

# Interactive Menu Loop
do {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "         QuickScripts Menu              " -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan

    for ($i = 0; $i -lt $scriptPaths.Count; $i++) {
        Write-Host (" [{0}] {1}" -f ($i + 1), $scriptPaths[$i]) -ForegroundColor Yellow
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
