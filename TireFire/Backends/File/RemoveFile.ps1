<#
    .SYNOPSIS
        Remove notes from the File backend
    .DESCRIPTION
        Remove notes from the File backend

        BackEndConfig Parameters:
            RootPath.  Path to notes.  All notes get a filename pstf-$id

    .PARAMETER ID
        Remove note with this ID

    .PARAMETER RootPath
        BackEndConfig parameter specifiying a path to notes

        All notes get a filename pstf-$id
#>
[cmdletbinding()]
param(
    [Parameter(Mandatory = $True)]
    [string]$ID,
    [string]$RootPath
)
if(-not $RootPath){
    throw "RootPath required for now"
}
if(-not (Test-Path $RootPath)){
    throw "RootPath [$RootPath] does not exist.  Create it first"
}

Function Get-NoteData {
    [cmdletbinding()]
    param(
        [string]$Path
    )
    Write-Verbose "Getting notes from [$Path]"
    foreach($NoteFile in (Get-ChildItem $Path -File)){
        if($NoteFile.Name -notmatch '^pstf-'){
            Write-Verbose "Skipping $($NoteFile.Fullname), doesn't start pstf-"
            continue
        }
        try {
            Write-Verbose "Importing $($NoteFile.Fullname)"
            Import-Clixml -Path $NoteFile.Fullname
        }
        catch {
            Write-Error $_
            Write-Error "Failed to import $($NoteFile.Fullname)"
        }
    }
}
$FileName = '{0}-{1}' -f 'pstf', ($ID -replace "^pstf-")
$NotePath = Join-Path $RootPath $FileName
if(Test-Path $NotePath -ErrorAction SilentlyContinue){
    Write-Verbose "Removing [$NotePath]"
    Remove-Item $NotePath -Force
}
else {
    Write-Warning "No file found at [$NotePath]"
}
