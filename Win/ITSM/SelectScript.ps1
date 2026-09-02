# SelectScript.ps1 - Deep Crawl (No API, Searches All Subfolders)
$githubUser = "EnjoyTechGit"
$repoName   = "QuickScripts"
$branch     = "main"

# GitHub's directory tree payload (recursively lists ALL files in ALL folders)
$treePayloadUrl = "https://github.com/$githubUser/$repoName/tree-list/$branch"

try {
    Write-Host "Scanning repository and all subfolders for scripts..." -ForegroundColor Cyan
    
    # Request JSON payload directly from GitHub web server
    $response = Invoke-RestMethod -Uri $treePayloadUrl -Headers @{ 
        "User-Agent" = "Mozilla/5.0"
        "Accept"     = "application/json"
    } -ErrorAction Stop

    # Extract all .ps1 paths, excluding menu scripts
    $scriptPaths = $response.paths | Where-Object { 
        $_ -like "*.ps1" -and 
        $_ -notlike "*SelectScript.ps1*" -and 
        $_ -notlike "*Menu.ps1*" 
    }
} catch {
    Write-Host "Failed to scan repository: $_" -ForegroundColor Red
    return
}

if (-not $scriptPaths -or $scriptPaths.Count -eq 0) {
    Write-Host "No runnable .ps1 scripts found in any subfolders." -ForegroundColor Yellow
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
