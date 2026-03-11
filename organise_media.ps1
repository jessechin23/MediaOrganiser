param(
    [string]$SourceFolder = "D:\TestMedia",
    [string]$DestinationFolder = "D:\SortedMedia",
    [bool]$DryRun = $true
)

$extensions = @(".mp4",".mov",".mkv",".avi",".wmv",".flv",".m4v")

$duplicateRoot = Join-Path $DestinationFolder "Duplicate"
$reportFile = Join-Path $DestinationFolder "duplicate_report.csv"

$globalHashes = @{}
$duplicateReport = @()

function Get-MediaDate($file) {

    $name = $file.Name

    # yyyyMMddHHmmss (20111016140440)
    if ($name -match '\b(20\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})\b') {
        return Get-Date "$($matches[1])-$($matches[2])-$($matches[3]) $($matches[4]):$($matches[5]):$($matches[6])"
    }

    # yyyyMMdd_HHmmss (20121227_211843)
    if ($name -match '\b(20\d{2})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})\b') {
        return Get-Date "$($matches[1])-$($matches[2])-$($matches[3])"
    }

    # yyyyMMdd
    if ($name -match '\b(20\d{2})(\d{2})(\d{2})\b') {
        return Get-Date "$($matches[1])-$($matches[2])-$($matches[3])"
    }

    # dd-MM-yyyy (16-10-2016)
    if ($name -match '\b(\d{2})-(\d{2})-(20\d{2})\b') {
        return Get-Date "$($matches[3])-$($matches[2])-$($matches[1])"
    }

    # yyyy-MM-dd
    if ($name -match '\b(20\d{2})-(\d{2})-(\d{2})\b') {
        return Get-Date "$($matches[1])-$($matches[2])-$($matches[3])"
    }

    # Metadata (Date Taken)
    try {
        $shell = New-Object -ComObject Shell.Application
        $folder = $shell.Namespace($file.DirectoryName)
        $item = $folder.ParseName($file.Name)

        $dateTaken = $folder.GetDetailsOf($item,12)

        if ($dateTaken) {
            return [datetime]$dateTaken
        }
    } catch {}

    # Fallback to filesystem timestamps
    if ($file.CreationTime -lt $file.LastWriteTime) {
        return $file.CreationTime
    }

    return $file.LastWriteTime
}

function SafeMove($src,$dest) {

    if ($DryRun) {
        Write-Host "[DRYRUN] Move $src -> $dest"
    }
    else {
        Move-Item $src -Destination $dest
    }
}

Get-ChildItem $SourceFolder -Recurse -File | Where-Object {
    $extensions -contains $_.Extension.ToLower()
} | ForEach-Object {

    $file = $_

    $date = Get-MediaDate $file
    $year = $date.ToString("yyyy")
    $month = $date.ToString("MM")

    $targetFolder = Join-Path $DestinationFolder "$year\$month"

    if (!(Test-Path $targetFolder) -and !$DryRun) {
        New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
    }

    $targetFile = Join-Path $targetFolder $file.Name

    $hash = (Get-FileHash $file.FullName -Algorithm SHA256).Hash

    if ($globalHashes.ContainsKey($hash)) {

        $duplicateFolder = Join-Path $duplicateRoot "$year\$month"

        if (!(Test-Path $duplicateFolder) -and !$DryRun) {
            New-Item -ItemType Directory -Path $duplicateFolder -Force | Out-Null
        }

        $dest = Join-Path $duplicateFolder $file.Name

        SafeMove $file.FullName $dest

        $duplicateReport += [PSCustomObject]@{
            FileName = $file.Name
            OriginalFile = $globalHashes[$hash]
            DuplicateFile = $file.FullName
            Hash = $hash
        }

        return
    }

    if (Test-Path $targetFile) {

        $base = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $ext = $file.Extension
        $counter = 1

        do {
            $newName = "$base`_$counter$ext"
            $newPath = Join-Path $targetFolder $newName
            $counter++
        } while (Test-Path $newPath)

        SafeMove $file.FullName $newPath

        $globalHashes[$hash] = $newPath
    }
    else {

        SafeMove $file.FullName $targetFile
        $globalHashes[$hash] = $targetFile
    }
}

if ($duplicateReport.Count -gt 0 -and !$DryRun) {
    $duplicateReport | Export-Csv $reportFile -NoTypeInformation
}