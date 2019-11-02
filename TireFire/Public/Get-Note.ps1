Function Get-Note {
    <#
    .SYNOPSIS
        Get a note

    .DESCRIPTION
        Get a note

    .EXAMPLE
        Get-Note

    .EXAMPLE
        Get-Note -ID some_id

    .EXAMPLE
        Get-Note -Tags some_tag

    .PARAMETER ID
        Get a note with this specific ID

    .PARAMETER Tags
        Get a note with at least one of these Tags

    .PARAMETER Query
        Search notes using regex (-Match)

        We search a note's ID, Tags, RelatedIDs, Data, and jsonified Data

    .PARAMETER IncludeRelated
        For any note identified by your query, include all notes from RelatedIDs
    #>
    [cmdletbinding()]
    param(
        [string]$Query,
        [string]$ID,
        [string[]]$Tags,
        [switch]$IncludeRelated,
        [string]$Backend = $Script:TireFireConfig.Backend,
        [hashtable]$BackendConfig = $Script:TireFireConfig.BackendConfig
    )
    $Params = @{
        Action = 'Get'
    }
    echo ID, Tags, IncludeRelated, Query | ForEach-Object {
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
