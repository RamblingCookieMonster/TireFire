Function Set-Note {
    <#
    .SYNOPSIS
        Update a note

    .DESCRIPTION
        Update a note

    .EXAMPLE
        Set-Note -id 1 -data 'new data'

    .PARAMETER TargetID
        ID of the note to set

    .PARAMETER ID
        Change  the target note's ID to this

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
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $True)]
        [string]$TargetID,
        [string]$ID,
        [string[]]$Tags,
        [string[]]$AddTag,
        [string[]]$RemoveTag,
        [string[]]$AddRelatedID,
        [string[]]$RemoveRelatedID,
        [object]$Data,
        [string[]]$RelatedIDs,
        [string]$Source,
        [string]$UpdatedBy,
        [string]$Backend = $Script:TireFireConfig.Backend,
        [hashtable]$BackendConfig = $Script:TireFireConfig.BackendConfig
    )
    process {
        $Params = @{
            Action = 'Set'
        }
        echo TargetID, ID, Tags, AddTags, RemoveTags, Data, Source, UpdatedBy, RelatedIDs, AddRelatedID, RemoveRelatedID | ForEach-Object {
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
