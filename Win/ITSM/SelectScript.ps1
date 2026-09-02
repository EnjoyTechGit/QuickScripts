# SelectScript.ps1 - Scoped Folder Scanner (Win/ITSM Focus)
$githubUser   = "EnjoyTechGit"
$repoName     = "QuickScripts"
$branch       = "main"
$targetFolder = "Win/ITSM"

$treeUrl = "https://github.com/$githubUser/$repoName/tree-list/$branch"
$webUrl  = "https://github.com/$githubUser/$repoName/tree/$branch/$targetFolder"

try {
    Write-Host "Scanning $targetFolder for scripts..." -ForegroundColor Cyan
    
    # Attempt 1: Fetch via internal tree-list payload
    $response = Invoke-RestMethod -Uri $treeUrl -Headers @{ 
        "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
        "Accept"     = "application/json"
    } -ErrorAction SilentlyContinue

    if ($response.paths) {
        $allPaths = $response.paths
    } else {
        # Attempt 2: Direct web page scrape parsing embedded JSON state
        $html = Invoke-RestMethod -Uri $webUrl -Headers @{ "User-Agent" = "Mozilla/5.0" } -ErrorAction Stop
        $allPaths = [regex]::Matches($html, '"path":"([^"]+\.ps1)"') | ForEach-Object { $_.Groups[1].Value }
    }

    # Filter strictly for target folder and .ps1 extensions
    $scriptPaths = $allPaths | Where-Object { 
        $_ -like "$targetFolder/*.ps1" -and 
        $_ -notlike "*SelectScript.ps1*" -and 
        $_ -notlike "*Menu.ps1*" 
    } | Select-Object -Unique

} catch {
    Write-Host "Failed to scan directory: $_" -ForegroundColor Red
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
        $scriptName = Split-Path $scriptPaths[$i] -Leaf
        Write-Host (" [{0}] {1}" -f ($i + 1), $scriptName) -ForegroundColor Yellow
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
