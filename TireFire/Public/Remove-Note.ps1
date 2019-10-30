Function Remove-Note {
    <#
    .SYNOPSIS
        Remove a note
    .DESCRIPTION
        Remove a note
    .EXAMPLE
        Remove-Note -ID some_id
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$True,
                   ValueFromPipelineByPropertyName = $True)]
        [string]$ID,
        [string]$Backend = $Script:TireFireConfig.Backend,
        [hashtable]$BackendConfig = $Script:TireFireConfig.BackendConfig
    )
    process {
        $Params = @{
            ID = $ID
            Action = 'Remove'
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
