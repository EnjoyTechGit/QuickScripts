# SelectScript.ps1
$githubUser = "EnjoyTechGit"
$repoName   = "QuickScripts"
$branch     = "main"

# GitHub REST API Endpoint
$apiUrl = "https://api.github.com/repos/$githubUser/$repoName/git/trees/$branch?recursive=1"

# Headers are required so GitHub API doesn't throw a 403 Forbidden / User-Agent error
$headers = @{
    "User-Agent" = "PowerShell-Script-Runner"
}

# Add your GitHub PAT here IF the repository is PRIVATE:
# $headers.Add("Authorization", "token ghp_YourPersonalAccessTokenHere")

try {
    Write-Host "Connecting to repository ($repoName)..." -ForegroundColor Cyan
    $repoContent = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop
    
    # Filter for .ps1 files, excluding the selection menu itself
    $scripts = $repoContent.tree | Where-Object { 
        $_.path -like "*.ps1" -and $_.path -notlike "*SelectScript.ps1*" -and $_.path -notlike "*Menu.ps1*" 
    }
} catch {
    Write-Host "Failed to fetch repository scripts." -ForegroundColor Red
    Write-Host "Details: $_" -ForegroundColor DarkGray
    return
}

if (-not $scripts -or $scripts.Count -eq 0) {
    Write-Host "No runnable .ps1 scripts found in repository." -ForegroundColor Yellow
    return
}

# Interactive Loop
do {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "         QuickScripts Menu              " -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan

    for ($i = 0; $i -lt $scripts.Count; $i++) {
        Write-Host (" [{0}] {1}" -f ($i + 1), $scripts[$i].path) -ForegroundColor Yellow
    }
    Write-Host "`n [Q] Quit`n" -ForegroundColor Gray

    $selection = Read-Host "Select a script number to execute"

    if ($selection -eq 'Q' -or $selection -eq 'q') {
        break
    }

    if ($selection -match '^\d+$' -and [int]$selection -le $scripts.Count -and [int]$selection -gt 0) {
        $selectedScript = $scripts[[int]$selection - 1]
        $rawUrl = "https://raw.githubusercontent.com/$githubUser/$repoName/$branch/$($selectedScript.path)"
        
        Write-Host "`nFetching and running: $($selectedScript.path)..." -ForegroundColor Cyan
        
        try {
            # Running via scriptblock prevents child scripts from terminating the main menu execution context
            $code = Invoke-RestMethod -Uri $rawUrl -Headers $headers -ErrorAction Stop
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
