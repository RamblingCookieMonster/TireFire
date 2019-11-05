<#
    .SYNOPSIS
        Get, Set, Create, or Remove notes from the File backend
    .DESCRIPTION
        Get, Set, Create, or Remove notes from the File backend

        BackEndConfig Parameters:
            RootPath.  Path to notes.  All notes get a filename pstf-$id

        Sorry, no time for parametersets at this scale:
        Valid parameters per -Action:

        Get
            Required: RootPath
            Optional: ID, Tags
        New
            Required: RootPath, ID|
            Optional: Data, Tags, UpdatedBy, AddTag, RemoveTag, Source, Force
        Set
            Required: RootPath, TargetID
            Optional: NewID, Data, Tags, UpdatedBy, AddTag, RemoveTag, Source
            For your convenience, you can use Set just like New - specify an ID rather than TargetID
        Remove
            Required: RootPath, ID

    .PARAMETER ID
        New:    ID for a new note.  Defaults to randomly generated GUID
        Get:    Get a note with this specific ID
        Remove: Remove a specific ID

    .PARAMETER NewID
        Set:    Change ID to this

        Why NewID rather than ID?  Pipeline input for Set-Note should be the ID of a note to change... but that's ID.
        So TargetID is aliased to ID, allowing pipelineinput, but precluding us from using ID rather than a new parameter
    .PARAMETER TargetID
        Set:    ID of the note to set

    .PARAMETER Action
        Action to take for a note
            New:    Create
            Set:    Update
            Get:    Read
            Remove: Delete

    .PARAMETER Data
        The actual data for the note.  We serialize with Export-Clixml, so objects are supported
        New:    Data for a new note
        Set:    Change Data to this

    .PARAMETER Tags
        Tags are a way to tag or classify a note for searching or organizational purposes
        New:    Tags for a new note
        Set:    Change tags to this.  Removes all existing tags.  Use RemoveTag or AddTag for iterative changes
        Get:    Get a note with at least one of the specified tags

    .PARAMETER UpdatedBy
        New:    UpdatedBy for a new note.  Defaults to $ENV:USERNAME
        Set:    Change UpdatedBy to this.  Defaults to $ENV:USERNAME

    .PARAMETER AddTag
        Set:    Add this to existing tags of a note

    .PARAMETER RemoveTag
        Set:    Remove this to existing tags of a note

    .PARAMETER RelatedIDs
        These are a set of IDs a note is related to.  We do no validation, so you could repurpose this
        New:    RelatedIDs for a new note
        Set:    Change tags to this.  Removes all existing RelatedIDs.  Use RemoveRelatedID or AddRelatedID for iterative changes

    .PARAMETER AddRelatedID
        Set:    Add this to existing RelatedIDs of a note

    .PARAMETER RemoveRelatedID
        Set:    Remove this from existing RelatedIDs of a note

    .PARAMETER Query
        Get:    Search using regex (-Match).  We search a note's ID, Tags, RelatedIDs, Data, and jsonified Data

    .PARAMETER IncludeRelated
        Get:    For any note that we would output, output RelatedIDs as well

    .PARAMETER Force
        New:    If a note with the same ID exists, overwrite it

    .PARAMETER Source
        Where did this note come from?  Defaults to full path to note
        New:    Source for a new note
        Set:    Change Source to this

    .PARAMETER RootPath
        BackEndConfig parameter specifiying a path to notes

        All notes get a filename pstf-$id
#>
[cmdletbinding()]
param(
    [string]$ID,
    [string]$TargetID,
    [string]$NewID,
    [validateset('Get','Set','New','Remove')]
    [string]$Action,
    [object]$Data,
    [string[]]$Tags,
    [string]$UpdatedBy,
    [string[]]$AddTag,
    [string[]]$RemoveTag,
    [string[]]$RelatedIDs,
    [string[]]$AddRelatedID,
    [string[]]$RemoveRelatedID,
    [string]$Query,
    [switch]$IncludeRelated,
    [switch]$Force,
    [string]$RootPath,
    [string]$Source
)
if(-not $RootPath){
    throw "RootPath required for now"
}
if(-not (Test-Path $RootPath)){
    throw "RootPath [$RootPath] does not exist.  Create it first"
}
if($Action -eq 'Set' -and -not $PSBoundParameters.ContainsKey('TargetID')){
    $Action = 'New'
    Write-Verbose "Specified action [Set] without parameter [TargetID].  Switching to action [New]"
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
    (Get-ChildItem $Path -File).foreach({
        if($_.Name -notmatch '^pstf-'){
            continue
        }
        try {
            Import-Clixml -Path $_.Fullname -ErrorAction stop
        }
        catch {
            Write-Error $_
            Write-Error "Failed to import $($_.Fullname)"
        }
    })
}

switch($Action){
    'get' {
        if(-not $ID){
                $splat = @{
                    InputObject = Get-NoteData -Path $RootPath
                }
                if($PSBoundParameters.ContainsKey('Query')){
                    $splat.Add('Query', $Query)
                }
                if($PSBoundParameters.ContainsKey('IncludeRelated')){
                    $splat.Add('IncludeRelated', $IncludeRelated)
                }
                if($PSBoundParameters.ContainsKey('Tags')){
                    $splat.Add('Tags', $Tags)
                }
                Select-Note @splat
        }
        else {
            $FileName = '{0}-{1}' -f 'pstf', $ID.TrimStart('pstf-')
            $NotePath = Join-Path $RootPath $FileName
            if(-not (Test-Path $NotePath)){
                Write-Error "Could not find note with ID [$ID] at path [$NotePath]"
            }
            else {
                Get-NoteData -Path $NotePath
            }
        }
    }
    'set' {
        if($PSBoundParameters.ContainsKey('TargetID')){
            $FileName = '{0}-{1}' -f 'pstf', $TargetID.TrimStart('pstf-')
            $NotePath = Join-Path $RootPath $FileName
            $ExportPath = Join-Path $RootPath $FileName
            $Note = Get-NoteData -Path $NotePath
            switch ($PSBoundParameters.Keys){
                'NewID' {
                    # Changing the ID changes data outside of the note itself.  filename in this case
                    $NewFileName = '{0}-{1}' -f 'pstf', $NewID.TrimStart('pstf-')
                    $ExportPath = Join-Path $RootPath $NewFileName
                    Move-Item -Path $NotePath -Destination $ExportPath -Force
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
        }
    }
    'new' {
        if(-not $PSBoundParameters.ContainsKey('ID')){
            $ID = [guid]::NewGuid().Guid
        }
        $FileName = '{0}-{1}' -f 'pstf', $ID.TrimStart('pstf-')
        $NotePath = Join-Path $RootPath $FileName
        if(-not $PSBoundParameters.ContainsKey('Source')){
            $Source = $NotePath
        }
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
        [pscustomobject]@{
            ID = $ID
            Data = $Data
            Tags = $Tags | Select-Object -Unique
            RelatedIDs = $RelatedIDs | Select-Object -Unique
            UpdatedBy = $UpdatedBy
            UpdateDate = Get-Date
            Source = $Source
        } | Export-Clixml -Path $NotePath -Force
    }
    'remove' {
        if(-not $ID){
            Write-Error "Must specify -ID to delete a note"
            return
        }
        $FileName = '{0}-{1}' -f 'pstf', $ID.TrimStart('pstf-')
        $NotePath = Join-Path $RootPath $FileName
        if(Test-Path $NotePath -ErrorAction SilentlyContinue){
            Write-Verbose "Removing [$NotePath]"
            Remove-Item $NotePath -Force
        }
    }
}
