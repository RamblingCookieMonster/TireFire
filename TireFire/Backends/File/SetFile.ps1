<#
    .SYNOPSIS
        Update notes from the File backend

    .DESCRIPTION
        Update notes from the File backend

        BackEndConfig Parameters:
            RootPath.  Path to notes.  All notes get a filename pstf-$id

    .PARAMETER TargetID
        ID of the note to set

    .PARAMETER NewID
        Change ID to this

        Why NewID rather than ID?  Pipeline input for Set-Note should be the ID of a note to change... but that's ID.
        So TargetID is aliased to ID, allowing pipelineinput, but precluding us from using ID rather than a new parameter

    .PARAMETER Data
        The actual data for the note.  We serialize with Export-Clixml, so objects are supported

        This overwrites all of the note Data.  Want to update one property?  Get the existing note, and merge the change into that

    .PARAMETER Tags
        Change tags to this.  Removes all existing tags.  Use RemoveTag or AddTag for iterative changes

    .PARAMETER UpdatedBy
        Change UpdatedBy to this.  Defaults to $ENV:USERNAME

    .PARAMETER AddTag
        Add this to existing tags of a note

    .PARAMETER RemoveTag
        Remove this to existing tags of a note

    .PARAMETER RelatedIDs
        Change tags to this.  Removes all existing RelatedIDs.  Use RemoveRelatedID or AddRelatedID for iterative changes

    .PARAMETER AddRelatedID
        Add this to existing RelatedIDs of a note

    .PARAMETER RemoveRelatedID
        Remove this from existing RelatedIDs of a note

    .PARAMETER Source
        Where did this note come from?  Defaults to full path to note.  If you update the note ID, this changes accordingly

    .PARAMETER RootPath
        BackEndConfig parameter specifiying a path to notes

        All notes get a filename pstf-$id

    .PARAMETER Passthru
        Return the updated note
#>
[cmdletbinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetID,
    [string]$NewID,
    [object]$Data,
    [string[]]$Tags,
    [string]$UpdatedBy,
    [string[]]$AddTag,
    [string[]]$RemoveTag,
    [string[]]$RelatedIDs,
    [string[]]$AddRelatedID,
    [string[]]$RemoveRelatedID,
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
$FileName = '{0}-{1}' -f 'pstf', ($TargetID -replace "^pstf-")
$NotePath = Join-Path $RootPath $FileName
$ExportPath = Join-Path $RootPath $FileName
$Note = Get-NoteData -Path $NotePath
switch ($PSBoundParameters.Keys){
    'NewID' {
        # Changing the ID changes data outside of the note itself.  filename in this case
        $NewFileName = '{0}-{1}' -f 'pstf', ($NewID -replace "^pstf-")
        $ExportPath = Join-Path $RootPath $NewFileName
        Move-Item -Path $NotePath -Destination $ExportPath -Force
        # Only update the source if it explicitly pointed at file previously
        # Folks might override our use of 'Source'
        if(-not $PSBoundParameters.ContainsKey('Source') -and $NotePath -eq $Note.Source){
            $Note.Source = $ExportPath
        }
        Write-Verbose ("Changing ID from {0} to {1}" -f $Note.ID, $NewID)
        $Note.ID = $NewID
    }
    'Tags' {
        Write-Verbose ("Changing Tags from {0} to {1}" -f $Note.Tags, $Tags)
        $Note.Tags = $Tags
    }
    'RemoveTag' {
        Write-Verbose ("Removing Tag {0} from {1}" -f $RemoveTag, $Note.Tags)
        $Note.Tags = @($Note.Tags).where({$RemoveTag -notcontains $_})
    }
    'AddTag' {
        Write-Verbose ("Adding Tag {0} to {1}" -f $AddTag, $Note.Tags)
        $Note.Tags = @($Note.Tags) + @($AddTag) | Select-Object -Unique
    }
    'RelatedIDs' {
        Write-Verbose ("Changing RelatedIDs from {0} to {1}" -f $Note.RelatedIDs, $RelatedIDs)
        $Note.RelatedIDs = $RelatedIDs
    }
    'RemoveRelatedID' {
        Write-Verbose ("Removing RelatedIDs {0} from {1}" -f $RemoveRelatedID, $Note.RelatedIDs)
        $Note.RelatedIDs = @($Note.RelatedIDs).where({$RemoveRelatedID -notcontains $_})
    }
    'AddRelatedID' {
        Write-Verbose ("Adding RelatedIDs {0} from {1}" -f $AddRelatedID, $Note.RelatedIDs)
        $Note.RelatedIDs = @($Note.RelatedIDs) + @($AddRelatedID) | Select-Object -Unique
    }
    'Data' {
        Write-Verbose ("Changing Data from {0} to {1}" -f $Note.Data, $Data)
        $Note.Data = $Data
    }
    'Source' {
        Write-Verbose ("Changing Source from {0} to {1}" -f $Note.Source, $Source)
        $Note.Source = $Source
    }
    'UpdatedBy' {
        Write-Verbose ("Changing UpdatedBy from {0} to {1}" -f $Note.UpdatedBy, $UpdatedBy)
        $Note.UpdatedBy = $UpdatedBy
    }
}
$Note.UpdateDate = Get-Date
Write-Verbose "Updating [$ExportPath]"
$Note | Export-Clixml -Path $ExportPath
if($Passthru){
    $Note
}
