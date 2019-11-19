Function New-Note {
    <#
    .SYNOPSIS
        Create or overwrite a note

    .DESCRIPTION
        Create or overwrite a note

        See Get-BackendHelp for details on whether a note supports serialization for its Data
    .EXAMPLE
        New-Note -Data 'A bunch of dataaaa' -Tags tag1, tag2

    .EXAMPLE
        # Create a new note with a specific ID and overwrite any note with the same ID
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
    .PARAMETER Passthru
        Return newly created note
    #>
    [cmdletbinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
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
        [switch]$Passthru,
        [string]$Backend = $Script:TireFireConfig.Backend,
        [hashtable]$BackendConfig = $Script:TireFireConfig.BackendConfig
    )
    process {
        if(-not $PSBoundParameters.ContainsKey('ID')){
            $ID = [guid]::NewGuid().Guid
        }
        $Params = @{
            ID = $ID
        }
        Write-Output Tags, Data, Source, UpdatedBy, RelatedIDs, Passthru, Force | ForEach-Object {
            $Key = $_
            if($PSBoundParameters.ContainsKey($Key)){
                $Value = $PSBoundParameters[$Key]
                $Params.add($Key, $Value)
            }
        }
        foreach($Param in $BackendConfig.Keys){
            $Params.Add($Param, $BackendConfig[$Param])
        }
        if(-not $Script:BackendHash.ContainsKey($Backend)){
            Throw "$Backend is not a valid backend.  Valid backends:`n$($Script:BackendHash.keys | Out-String)"
        }
        else {
            $BackendScript = $Script:BackendHash[$Backend].new
        }
        if ($Force -or $PSCmdlet.ShouldProcess($ID, "Create Note with ID [$ID] on backend [$Backend]")) {
            . $BackendScript @Params
        }
    }
}
