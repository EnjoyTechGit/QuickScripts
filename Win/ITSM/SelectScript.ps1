# SelectScript.ps1 - Fixed README.md Parser
$githubUser   = "EnjoyTechGit"
$repoName     = "QuickScripts"
$branch       = "main"
$targetFolder = "Win/ITSM"

$readmeUrl = "https://github.com/$githubUser/$repoName/raw/refs/heads/$branch/$targetFolder/README.md"

try {
    Write-Host "Fetching script index from README.md..." -ForegroundColor Cyan
    $readmeText = Invoke-RestMethod -Uri $readmeUrl -Headers @{ "User-Agent" = "Mozilla/5.0" } -ErrorAction Stop

    # Matches valid .ps1 filenames (e.g. eParakst.ps1) ignoring partial matches
    $pattern = '(?i)\b([a-z0-9_\-]+\.ps1)\b'
    $matches = [regex]::Matches($readmeText, $pattern) | ForEach-Object { $_.Groups[1].Value }
    
    # Filter out menu scripts, self-references, and duplicates
    $scriptNames = $matches | Where-Object { 
        $_ -notlike "*SelectScript.ps1*" -and $_ -notlike "*Menu.ps1*" 
    } | Select-Object -Unique

} catch {
    Write-Host "Failed to read README.md: $_" -ForegroundColor Red
    return
}

if (-not $scriptNames -or $scriptNames.Count -eq 0) {
    Write-Host "No valid .ps1 scripts found listed in README.md." -ForegroundColor Yellow
    return
}

# Interactive Menu Loop
do {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "      QuickScripts Menu ($targetFolder)  " -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan

    for ($i = 0; $i -lt $scriptNames.Count; $i++) {
        Write-Host (" [{0}] {1}" -f ($i + 1), $scriptNames[$i]) -ForegroundColor Yellow
    }
    Write-Host "`n [Q] Quit`n" -ForegroundColor Gray

    $selection = Read-Host "Select a script number to execute"

    if ($selection -eq 'Q' -or $selection -eq 'q') { break }

    if ($selection -match '^\d+$' -and [int]$selection -le $scriptNames.Count -and [int]$selection -gt 0) {
        $selectedScript = $scriptNames[[int]$selection - 1]
        $rawScriptUrl = "https://github.com/$githubUser/$repoName/raw/refs/heads/$branch/$targetFolder/$selectedScript"
        
        Write-Host "`nFetching and running: $selectedScript..." -ForegroundColor Cyan
        
        try {
            # Execute in a discrete ScriptBlock so child scripts don't exit the menu session
            $code = Invoke-RestMethod -Uri $rawScriptUrl -Headers @{ "User-Agent" = "Mozilla/5.0" } -ErrorAction Stop
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
