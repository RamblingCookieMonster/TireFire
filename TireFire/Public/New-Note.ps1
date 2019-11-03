Function New-Note {
    <#
    .SYNOPSIS
        Create or overwrite a note
    .DESCRIPTION
        Create or overwrite a note
    .EXAMPLE
        New-Note -Data 'A bunch of dataaaa' -Tags tag1, tag2
    .EXAMPLE
        New-Note -Data 'A bunch of dataaaa' -Tags tag1, tag2 -ID existing_id -Force

    .PARAMETER ID
        ID for the new note.  Defaults to randomly generated GUID

    .PARAMETER Data
        Data for the new note.  See backend specifications to determine supported data types and serialization

    .PARAMETER Tags
        Tags for the new note.

        Tags are a way to tag or classify a note for searching or organizational purposes

    .PARAMETER UpdatedBy
        UpdatedBy for the new note.  Defaults to $ENV:USERNAME

    .PARAMETER RelatedIDs
        RelatedIDs for the new note.  No validation is performed

        This is a way to tie your note to other notes

    .PARAMETER Source
        Source for a note.  For default values, See backend specifications

    .PARAMETER Force
        If a note with the specified ID exists, overwrite it
    #>
    [cmdletbinding()]
    param(
        [parameter(Position=1,
                   ValueFromPipelineByPropertyName = $True)]
        [object]$Data,
        [parameter(ValueFromPipelineByPropertyName = $True)]
        [string]$ID,
        [parameter(ValueFromPipelineByPropertyName = $True)]
        [string[]]$Tags,
        [parameter(ValueFromPipelineByPropertyName = $True)]
        [string[]]$RelatedIDs,
        [parameter(ValueFromPipelineByPropertyName = $True)]
        [string]$Source,
        [parameter(ValueFromPipelineByPropertyName = $True)]
        [string]$UpdatedBy,
        [switch]$Force,
        [string]$Backend = $Script:TireFireConfig.Backend,
        [hashtable]$BackendConfig = $Script:TireFireConfig.BackendConfig
    )
    process {
        $Params = @{
            Action = 'New'
        }
        echo ID, Tags, Data, Source, UpdatedBy, RelatedIDs | ForEach-Object {
            $Key = $_
            if($PSBoundParameters.ContainsKey($Key)){
                $Value = $PSBoundParameters[$Key]
                $Params.add($Key, $Value)
            }
        }
        foreach($Param in $BackendConfig.Keys){
            $Params.Add($Param, $BackendConfig[$Param])
        }
        if($Script:Backends.BaseName -notcontains $Backend){
            Throw "$Backend is not a valid backend.  Valid backends:`n$($Script:Backends.BaseName | Out-String)"
        }
        else {
            $BackendScript = $Backends.where({$_.BaseName -eq $Backend}).Fullname
        }
        . $BackendScript @Params
    }
}
