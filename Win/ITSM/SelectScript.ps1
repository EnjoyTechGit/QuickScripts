# Interactive script launcher for Win/ITSM
$repoOwner = "EnjoyTechGit"
$repoName = "QuickScripts"
$branch = "main"
$folderPath = "Win/ITSM"
$excludeFiles = @("SelectScript.ps1", "GenList.ps1")

$apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/contents/$folderPath?ref=$branch"
$rawBaseUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/$branch/$folderPath"

try {
    $items = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" } |
        Where-Object { $_.type -eq "file" -and $_.name -like "*.ps1" -and $_.name -notin $excludeFiles } |
        Sort-Object name
}
catch {
    Write-Error "Unable to load script list from GitHub: $($_.Exception.Message)"
    return
}

if (-not $items) {
    Write-Host "No scripts were found in $folderPath." -ForegroundColor Yellow
    return
}

Write-Host "`nAvailable scripts in $folderPath:`n" -ForegroundColor Cyan
for ($i = 0; $i -lt $items.Count; $i++) {
    $index = $i + 1
    Write-Host ("[{0}] {1}" -f $index, $items[$i].name)
}

while ($true) {
    $choice = Read-Host "Select a script number to run (or Q to quit)"

    if ($choice -match '^(q|quit|exit)$') {
        Write-Host "Script launcher cancelled." -ForegroundColor Yellow
        return
    }

    if ($choice -notmatch '^\d+$') {
        Write-Host "Please enter a valid number." -ForegroundColor Yellow
        continue
    }

    $selectedIndex = [int]$choice - 1
    if ($selectedIndex -lt 0 -or $selectedIndex -ge $items.Count) {
        Write-Host ("Please choose a number between 1 and {0}." -f $items.Count) -ForegroundColor Yellow
        continue
    }

    break
}

$selectedItem = $items[$selectedIndex]
$scriptUrl = "$rawBaseUrl/$($selectedItem.name)"
Write-Host "`nRunning $($selectedItem.name) ..." -ForegroundColor Green

try {
    $scriptContent = (Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing).Content
    Invoke-Expression $scriptContent
}
catch {
    Write-Error "Failed to run $($selectedItem.name): $($_.Exception.Message)"
}
