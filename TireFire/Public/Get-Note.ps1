Function Get-Note {
    <#
    .SYNOPSIS
        Get a note

    .DESCRIPTION
        Get a note

    .EXAMPLE
        # Get all notes
        Get-Note

    .EXAMPLE
        # Get note with ID some_id
        Get-Note -ID some_id

    .EXAMPLE
        # Get notes with tag some_tag
        Get-Note -Tags some_tag

    .EXAMPLE
        # Get notes with keyword somewhere in the ID, tags, relatedids, or data
        Get-Note -Query keyword

    .PARAMETER ID
        Get a note with this specific ID

    .PARAMETER Tags
        Get a note with at least one of these Tags

    .PARAMETER Data
        One or more strings to search for in the Data field

    .PARAMETER Query
        Search notes using regex (-Match)

        We search a note's ID, Tags, RelatedIDs, Data, and jsonified Data

    .PARAMETER ComparisonOperator
        If more than one filter is provided (Id, Query, Data, Tags), use this operator:

        Or:  Return the note if any of the conditions are met.  More performant, less selective
        And: Return the note only when all of the conditions are met.  More selective, less performant

        This applies across parameters, as well as for array input for Id, Query, Data, and Tags parameters

        Example:
           -ComparisonOperator And -Query Foo, Bar -Tags Buzz: Return only if _both_ foo and bar are found via Query, and Buzz is found in Tags
           -ComparisonOperator Or  -Query Foo, Bar -Tags Buzz: Return if either foo or bar are found via Query, or if Buzz is found in Tags

    .PARAMETER MergeData
        If specified, merge all properties fom the $Note.Data into $Note itself

        Existing $Note properties take precedence
    .PARAMETER IncludeRelated
        For any note identified by your query, include all notes from RelatedIDs
    .PARAMETER Backend
        Backend to use.  Defaults to value from Set-TireFireConfig
    .PARAMETER BackendConfig
        Configurations specific to the selected backend.  Defaults to value from Set-TireFireConfig

        See Get-BackendHelp for valid BackendConfig parameters
    #>
    [cmdletbinding()]
    param(
        [string[]]$Query,
        [string[]]$ID,
        [string[]]$Data,
        [string[]]$Tags,
        [switch]$IncludeRelated,
        [switch]$MergeData,
        [validateset('and', 'or')]
        [string]$ComparisonOperator = 'and',
        [string]$Backend = $Script:TireFireConfig.Backend,
        [hashtable]$BackendConfig = $Script:TireFireConfig.BackendConfig
    )
    $Params = @{ComparisonOperator = $ComparisonOperator}
    Write-Output ID, Tags, IncludeRelated, Query, Data | ForEach-Object {
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
        $BackendScript = $Script:BackendHash[$Backend].get
    }
    $Notes = . $BackendScript @Params
    if($MergeData){
        foreach($Note in $Notes){
            foreach($Prop in @($Note.Data.psobject.properties.name)){
                Add-Member -InputObject $Note -Type NoteProperty -Name $Prop -Value $Note.Data.$Prop -ErrorAction SilentlyContinue
            }
        }
    }
    $Notes
}
