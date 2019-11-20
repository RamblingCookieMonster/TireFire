Function Remove-Note {
    <#
    .SYNOPSIS
        Remove a note
    .DESCRIPTION
        Remove a note
    .EXAMPLE
        Remove-Note -ID some_id
        Remove a note with ID some_id
    .EXAMPLE
        Get-Note | Remove-Note
        Remove allll the notes
    .PARAMETER ID
        ID of note to remove
    .PARAMETER Backend
        Backend to use.  Defaults to value from Set-TireFireConfig
    .PARAMETER BackendConfig
        Configurations specific to the selected backend.  Defaults to value from Set-TireFireConfig

        See Get-BackendHelp for valid BackendConfig parameters
    #>
    [cmdletbinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
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
        }
        foreach($Param in $BackendConfig.Keys){
            $Params.Add($Param, $BackendConfig[$Param])
        }
        if(-not $Script:BackendHash.ContainsKey($Backend)){
            Throw "$Backend is not a valid backend.  Valid backends:`n$($Script:BackendHash.keys | Out-String)"
        }
        else {
            $BackendScript = $Script:BackendHash[$Backend].remove
        }
        if ($PSCmdlet.ShouldProcess($ID, "Remove Note with ID [$ID] from backend [$Backend]")) {
            . $BackendScript @Params
        }
    }
}
