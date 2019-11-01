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

    #>
    [cmdletbinding()]
    param(
        [string]$ID,
        [string[]]$Tags,
        [string[]]$AddTag,
        [string[]]$RemoveTag,
        [string[]]$RelatedIDs,
        [object]$Data,
        [string]$Source,
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
