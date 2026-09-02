function Show-QuickScriptsMenu {
    Clear-Host
    $githubUser = "TavisHawkes"
    $repoName   = "QuickScripts"
    $branch     = "main"

    # 1. Fetch available .ps1 files via GitHub API
    $apiUrl = "https://api.github.com/repos/$githubUser/$repoName/git/trees/$branch?recursive=1"
    
    try {
        $repoContent = Invoke-RestMethod -Uri $apiUrl -UserAgent "PowerShell"
        $scripts = $repoContent.tree | Where-Object { $_.path -like "*.ps1" -and $_.path -notlike "*menu*" }
    } catch {
        Write-Host "Failed to fetch repository scripts. Check internet connection or repository privacy." -ForegroundColor Red
        return
    }

    if ($scripts.Count -eq 0) {
        Write-Host "No .ps1 scripts found in repository." -ForegroundColor Yellow
        return
    }

    # 2. Display Selection Menu
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "         QuickScripts Menu              " -ForegroundColor Header
    Write-Host "========================================`n" -ForegroundColor Cyan

    for ($i = 0; $i -lt $scripts.Count; $i++) {
        Write-Host ("[{0}] {1}" -f ($i + 1), $scripts[$i].path) -ForegroundColor Yellow
    }
    Write-Host "[Q] Quit`n" -ForegroundColor Gray

    # 3. Handle User Input
    $selection = Read-Host "Select a script number to execute"

    if ($selection -eq 'Q' -or $selection -eq 'q') {
        return
    }

    if ($selection -match '^\d+$' -and [int]$selection -le $scripts.Count -and [int]$selection -gt 0) {
        $selectedScript = $scripts[[int]$selection - 1]
        $rawUrl = "https://github.com/$githubUser/$repoName/raw/refs/heads/$branch/$($selectedScript.path)"
        
        Write-Host "`nDownloading and executing: $($selectedScript.path)..." -ForegroundColor Cyan
        
        try {
            $code = Invoke-RestMethod -Uri $rawUrl -UserAgent "Mozilla/5.0"
            $sb = [scriptblock]::Create($code)
            & $sb
        } catch {
            Write-Host "Error executing script: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Invalid selection." -ForegroundColor Red
    }
}

# Run the menu
Show-QuickScriptsMenu
