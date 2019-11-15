Function Set-Note {
    <#
    .SYNOPSIS
        Update a note

    .DESCRIPTION
        Update a note

    .EXAMPLE
        Set-Note -TargetID 1 -Data 'new data'
        # Change data on note with ID 1

    .EXAMPLE
        # Replace all existing tag2 tags with tagtwo tags
        Get-Note -Tags tag2 | Set-Note -RemoveTag tag2 -AddTag tagtwo

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
        $Params = @{
            Action = 'Set'
        }
        Write-Output TargetID, NewID, Tags, AddTag, RemoveTag, Data, Source, UpdatedBy, RelatedIDs, AddRelatedID, RemoveRelatedID | ForEach-Object {
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
        if ($PSCmdlet.ShouldProcess($TargetID, "Change Note with ID [$TargetID] on backend [$Backend]")) {
            . $BackendScript @Params
            if($Passthru){
                Get-Note -Backend $Backend -BackendConfig $BackendConfig -ID $TargetID
            }
        }
    }
}
