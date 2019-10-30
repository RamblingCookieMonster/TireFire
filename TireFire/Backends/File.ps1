<#
    .SYNOPSIS
        Get, Set, Create, or Remove notes from the File backend
    .DESCRIPTION
        Get, Set, Create, or Remove notes from the File backend

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
            Optional: ID, Data, Tags, UpdatedBy, AddTag, RemoveTag, Source
            For your convenience, you can use Set just like New - specify an ID rather than TargetID
        Remove
            Required: RootPath, ID
#>
[cmdletbinding()]
param(
    [string]$ID,
    [string]$TargetID,
    [validateset('Get','Set','New','Remove')]
    [string]$Action,
    [object]$Data,
    [string[]]$Tags,
    [string]$UpdatedBy,
    [string[]]$AddTag,
    [string[]]$RemoveTag,
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
    param($Path)
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
        if(-not $WorkingID){
                @(Get-NoteData -Path $RootPath).foreach({
                    $Note = $_
                    if($PSBoundParameters.ContainsKey('Tags')){
                        foreach($Tag in $Tags){
                            if(@($Note.Tags) -contains $Tag){
                                $Note
                                continue
                            }
                        }
                    }
                    else {
                        $Note
                    }
                })
        }
        else {
            $NotePath = Join-Path $RootPath $ID
            if(-not (Test-Path $NotePath)){
                Write-Error "Could not find note with ID [$ID] at path [$Path]"
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
            $Note = Import-Clixml $NotePath
            switch ($PSBoundParameters.Keys){
                'ID' {
                    $NewFileName = '{0}-{1}' -f 'pstf', $ID.TrimStart('pstf-')
                    $ExportPath = Join-Path $RootPath $NewFileName
                    Move-Item -Path $NotePath -Destination $ExportPath -Force
                    if(-not $PSBoundParameters.ContainsKey('Source') -and $NotePath -eq $Note.Source){
                        $Note.Source = $ExportPath
                    }
                    $Note.ID = $ID
                }
                'Tags' {
                    $Note.Tags = $Tags
                }
                'RemoveTag' {
                    $Note.Tags = @($Note.Tags).where({$RemoveTag -notcontains $_})
                }
                'AddTag' {
                    $Note.Tags = @($Note.Tags) + @($AddTag) | Select-Object -Unique
                }
                'Data' {
                    $Note.Data = $Data
                }
                'Source' {
                    $Note.Source = $Source
                }
                'UpdatedBy' {
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
            $ID = [guid]::NewGuid()
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
            Tags = $Tags
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
