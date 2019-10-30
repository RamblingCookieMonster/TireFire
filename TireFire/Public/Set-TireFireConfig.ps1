function Set-TireFireConfig {
    <#
    .SYNOPSIS
       Set TireFire configuration values
    .DESCRIPTION
       Set TireFire configuration values
    .EXAMPLE
        Set-TireFireConfig -Token $Token
    .FUNCTIONALITY
        TireFire
    #>
    [cmdletbinding()]
    param(
        [ValidateNotNull()]
        [string]$Backend,

        [ValidateNotNull()]
        [hashtable]$BackendConfig
    )
    Switch ($PSBoundParameters.Keys)
    {
        'Backend' { $Script:TireFireConfig.Backend = $Backend }
        'BackendConfig' { $Script:TireFireConfig.BackendConfig = $BackendConfig }
    }
}
