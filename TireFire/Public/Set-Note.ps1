Function Set-Note {
    <#
    .SYNOPSIS
        Create or update a note
    .DESCRIPTION
        Create or update a note
    .EXAMPLE
        Set-Note -id 1 -data 'new data'
    #>
    [cmdletbinding(DefaultParameterSetName = 'Update')]
    param(
        [Parameter(ParameterSetName = 'Update',
                   Mandatory = $True)]
        [string]$TargetID,
        [string]$ID,
        [string[]]$Tags,
        [string[]]$AddTag,
        [string[]]$RemoveTag,
        [object]$Data,
        [string]$Source,
        [string]$UpdatedBy,
        [string]$Backend = $Script:TireFireConfig.Backend,
        [hashtable]$BackendConfig = $Script:TireFireConfig.BackendConfig
    )
    process {
        $Params = @{
            Action = 'Set'
        }
        echo TargetID, ID, Tags, AddTags, RemoveTags, Data, Source, UpdatedBy | ForEach-Object {
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
