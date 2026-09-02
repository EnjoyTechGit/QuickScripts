# SelectScript.ps1 - Strictly Typed Array Parser
$githubUser   = "EnjoyTechGit"
$repoName     = "QuickScripts"
$branch       = "main"
$targetFolder = "Win/ITSM"

$readmeUrl = "https://raw.githubusercontent.com/$githubUser/$repoName/$branch/$targetFolder/README.md"

try {
    Write-Host "Fetching script index from README.md..." -ForegroundColor Cyan
    $readmeText = Invoke-RestMethod -Uri $readmeUrl -Headers @{ "User-Agent" = "PowerShell" } -ErrorAction Stop

    # Regex targeting raw GitHub URLs ending in .ps1
    $urlPattern = 'https://raw\.githubusercontent\.com/[^\s"''<>]+\.ps1'
    $matches = [regex]::Matches($readmeText, $urlPattern)

    # Use a strongly-typed List to enforce string storage
    $scriptUrls = [System.Collections.Generic.List[string]]::new()

    foreach ($match in $matches) {
        $url = $match.Value
        if ($url -notlike "*SelectScript.ps1*" -and $url -notlike "*Menu.ps1*") {
            if (-not $scriptUrls.Contains($url)) {
                $scriptUrls.Add($url)
            }
        }
    }

} catch {
    Write-Host "Failed to read README.md: $_" -ForegroundColor Red
    return
}

if ($scriptUrls.Count -eq 0) {
    Write-Host "No runnable .ps1 scripts found listed in README.md." -ForegroundColor Yellow
    return
}

# Interactive Menu Loop
do {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "      QuickScripts Menu ($targetFolder)  " -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan

    for ($i = 0; $i -lt $scriptUrls.Count; $i++) {
        $fileName = Split-Path -Path $scriptUrls[$i] -Leaf
        Write-Host (" [{0}] {1}" -f ($i + 1), $fileName) -ForegroundColor Yellow
    }
    Write-Host "`n [Q] Quit`n" -ForegroundColor Gray

    $selection = Read-Host "Select a script number to execute"

    if ($selection -eq 'Q' -or $selection -eq 'q') { break }

    if ($selection -match '^\d+$' -and [int]$selection -le $scriptUrls.Count -and [int]$selection -gt 0) {
        $selectedIndex = [int]$selection - 1
        $selectedUrl   = $scriptUrls[$selectedIndex]
        $selectedName  = Split-Path -Path $selectedUrl -Leaf
        
        Write-Host "`nFetching and running: $selectedName..." -ForegroundColor Cyan
        
        try {
            $code = Invoke-RestMethod -Uri $selectedUrl -Headers @{ "User-Agent" = "PowerShell" } -ErrorAction Stop
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
