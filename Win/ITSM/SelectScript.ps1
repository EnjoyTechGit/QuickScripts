# SelectScript.ps1 - Pure Web-Scraping Version (No API, No Hardcoding)
$githubUser = "EnjoyTechGit"
$repoName   = "QuickScripts"
$branch     = "main"

# 1. Fetch the main repo page HTML directly
$repoWebUrl = "https://github.com/$githubUser/$repoName/tree/$branch"

try {
    Write-Host "Scanning repository for scripts..." -ForegroundColor Cyan
    $webContent = Invoke-RestMethod -Uri $repoWebUrl -Headers @{ "User-Agent" = "Mozilla/5.0" } -ErrorAction Stop

    # 2. Extract relative .ps1 file paths using regex matching from the HTML
    $pattern = "($githubUser/$repoName/blob/$branch/.*?\.ps1)"
    $matches = [regex]::Matches($webContent, $pattern) | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique

    # 3. Clean up paths and filter out menu scripts
    $scriptPaths = $matches | ForEach-Object {
        $_ -replace "^$githubUser/$repoName/blob/$branch/", ""
    } | Where-Object { 
        $_ -notlike "*SelectScript.ps1*" -and $_ -notlike "*Menu.ps1*" 
    }
} catch {
    Write-Host "Failed to scrape repository content: $_" -ForegroundColor Red
    return
}

if (-not $scriptPaths -or $scriptPaths.Count -eq 0) {
    Write-Host "No runnable .ps1 scripts found in repository." -ForegroundColor Yellow
    return
}

# 4. Interactive Menu Loop
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
