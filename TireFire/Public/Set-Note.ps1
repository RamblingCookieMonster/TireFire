Function Set-Note {
    <#
    .SYNOPSIS
        Update a note

    .DESCRIPTION
        Update a note

    .EXAMPLE
        Set-Note -TargetID 1 -Data 'new data'
        Change data on note with ID 1

    .EXAMPLE
        Get-Note -Tags tag2 | Set-Note -RemoveTag tag2 -AddTag tagtwo
        Replace all existing tag2 tags with tagtwo tags

    .PARAMETER TargetID
        ID of the note to change

    .PARAMETER NewID
        Change the target note's ID to this

    .PARAMETER Data
        Change the target note's Data to this

    .PARAMETER Tags
        Change the target note's tags to this

        Removes all existing tags.  Use RemoveTag or AddTag for iterative changes

    .PARAMETER UpdatedBy
        Change the target note's UpdatedBy to this.  Defaults to $ENV:USERNAME

    .PARAMETER AddTag
        Add this to existing tags of the target note

    .PARAMETER RemoveTag
        Remove this to existing tags of the target note

    .PARAMETER RelatedIDs
        Change the target note's tags to this.  Removes all existing RelatedIDs.  Use RemoveRelatedID or AddRelatedID for iterative changes

    .PARAMETER AddRelatedID
        Add this to existing RelatedIDs of the target note

    .PARAMETER RemoveRelatedID
        Remove this from existing RelatedIDs of the target note

    .PARAMETER Source
        Change the target note's Source to this

    .PARAMETER Passthru
        Return newly created note
    .PARAMETER Backend
        Backend to use.  Defaults to value from Set-TireFireConfig
    .PARAMETER BackendConfig
        Configurations specific to the selected backend.  Defaults to value from Set-TireFireConfig

        See Get-BackendHelp for valid BackendConfig parameters
    #>
    [cmdletbinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [alias('ID')]
        [string]$TargetID,
        [string]$NewID,
        [string[]]$Tags,
        [string[]]$AddTag,
        [string[]]$RemoveTag,
        [string[]]$AddRelatedID,
        [string[]]$RemoveRelatedID,
        [object]$Data,
        [string[]]$RelatedIDs,
        [string]$Source,
        [string]$UpdatedBy,
        [switch]$Passthru,
        [string]$Backend = $Script:TireFireConfig.Backend,
        [hashtable]$BackendConfig = $Script:TireFireConfig.BackendConfig
    )
    process {
        $Params = @{}
        Write-Output TargetID, NewID, Tags, AddTag, RemoveTag, Data, Source, UpdatedBy, RelatedIDs, AddRelatedID, RemoveRelatedID, Passthru | ForEach-Object {
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
            $BackendScript = $Script:BackendHash[$Backend].set
        }
        if ($PSCmdlet.ShouldProcess($TargetID, "Change Note with ID [$TargetID] on backend [$Backend]")) {
            . $BackendScript @Params
        }
    }
}
