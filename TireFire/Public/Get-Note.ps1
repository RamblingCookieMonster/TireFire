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
    #>
    [cmdletbinding()]
    param(
        [string]$ID,
        [string[]]$Tags,
        [string]$Backend = $Script:TireFireConfig.Backend,
        [hashtable]$BackendConfig = $Script:TireFireConfig.BackendConfig
    )
    $Params = @{
        ID = $ID
        Action = 'Get'
    }
    if($PSBoundParameters.ContainsKey('Tags')){
        $Params.add('Tags', $Tags)
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
