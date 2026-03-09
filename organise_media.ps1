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

    try {

        $shell = New-Object -ComObject Shell.Application
        $folder = $shell.Namespace($file.DirectoryName)
        $item = $folder.ParseName($file.Name)

        $dateTaken = $folder.GetDetailsOf($item,12)

        if ($dateTaken) {
            return [datetime]$dateTaken
        }

    } catch {}

    return $file.CreationTime
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

    # Only calculate hash when needed
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