# MediaOrganiser
A smart file organisation script that scans a selected folder and automatically sorts video files into a structured media library based on their recording date.  It safely handles duplicates, renames conflicting files, and generates report so you can review what was detected.

	•	🚀 fast scanning with cached file hash
	•	🧠 Global duplicate detection
	•	📷 EXIF / media date first
	•	🛡 Dry-run mode for testing
	•	📊 Duplicate CSV report

## To test
### Dry run

```powershell
.\organize_media.ps1 -SourceFolder "D:\TestFolder" -DestinationFolder "D:\SortedMedia" -DryRun $true
```

#### Expected output

```
.[DRYRUN] Move D:\TestFolder\video.mp4 -> D:\SortedMedia\2024\02\video.mp4
```

This gives you an overview of what will be moved.

### Real run

```powershell
.\organize_media.ps1 -SourceFolder "D:\TestFolder" -DestinationFolder "D:\SortedMedia" -DryRun $false
```

#### Example final structure

```
SortedMedia
 ├── 2022
 │   └── 11
 │       holiday.mp4
 ├── 2024
 │   └── 03
 │       concert.mp4
 │       concert_1.mp4
 ├── Duplicate
 │   └── 2024
 │       └── 03
 │           concert.mp4
 └── duplicate_report.csv
```


## Future Improvements
- automatic self-organizing digital archive with daily scheduling so it automatically organise files as you download.
- improve to also organise:
Videos
Photos
Music
Documents

Into something like:

```
Media
 ├── Photos
 │   └── 2024\03
 ├── Videos
 │   └── 2024\03
 ├── Music
 └── Documents
```