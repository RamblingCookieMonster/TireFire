<#
    .SYNOPSIS
        Create notes from the File backend
    .DESCRIPTION
        Create notes from the File backend

        BackEndConfig Parameters:
            RootPath.  Path to notes.  All notes get a filename pstf-$id

    .PARAMETER ID
        New:    ID for a new note.  Defaults to randomly generated GUID

    .PARAMETER Data
        The  data for the note.  We serialize with Export-Clixml, so objects are supported

    .PARAMETER Tags
        Tags are a way to tag or classify a note for searching or organizational purposes

    .PARAMETER UpdatedBy
        UpdatedBy for a new note.  Defaults to $ENV:USERNAME

    .PARAMETER RelatedIDs
        These are a set of IDs a note is related to.  We do no validation, so you could repurpose this

    .PARAMETER Force
        If a note with the same ID exists, overwrite it

    .PARAMETER Source
        Where did this note come from?  Defaults to full path to note

    .PARAMETER RootPath
        BackEndConfig parameter specifiying a path to notes

        All notes get a filename pstf-$id

    .PARAMETER Passthru
        Return the new note
#>
[cmdletbinding()]
param(
    [string]$ID,
    [object]$Data,
    [string[]]$Tags,
    [string]$UpdatedBy,
    [string[]]$RelatedIDs,
    [switch]$Force,
    [string]$RootPath,
    [string]$Source,
    [switch]$Passthru
)
if(-not $RootPath){
    throw "RootPath required for now"
}
if(-not (Test-Path $RootPath)){
    throw "RootPath [$RootPath] does not exist.  Create it first"
}
if(-not $PSBoundParameters.ContainsKey('UpdatedBy')){
    $UpdatedBy = $env:USERNAME
}
if(-not $PSBoundParameters.ContainsKey('Source')){
    $Source = $NotePath
}

$FileName = '{0}-{1}' -f 'pstf', $ID.TrimStart('pstf-')
$NotePath = Join-Path $RootPath $FileName
if(Test-Path -Path $NotePath -ErrorAction SilentlyContinue){
    if($Force){
        Write-Verbose "Overwriting [$NotePath]"
    }
    else {
        Write-Warning "Skipping [$ID].  [$NotePath] exists.  Specify -Force to overwrite"
        return
    }
}
else {
    Write-Verbose "Creating [$NotePath]"
}
$Note = [pscustomobject]@{
    ID = $ID
    Data = $Data
    Tags = $Tags | Select-Object -Unique
    RelatedIDs = $RelatedIDs | Select-Object -Unique
    UpdatedBy = $UpdatedBy
    UpdateDate = Get-Date
    Source = $Source
}
$Note | Export-Clixml -Path $NotePath -Force
if($Passthru){
    $Note
}
