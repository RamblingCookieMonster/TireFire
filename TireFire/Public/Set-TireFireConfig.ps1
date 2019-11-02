function Set-TireFireConfig {
    <#
    .SYNOPSIS
       Set TireFire configuration values
    .DESCRIPTION
       Set TireFire configuration values
    .EXAMPLE
        Set-TireFireConfig -Token $Token
    .PARAMETER Backend
        Backend to use for all commands
    .PARAMETER BackendConfig
        Configurations specific to the selected backend.  See Get-BackendHelp for valid BackendConfig parameters
    .PARAMETER BackendScriptPath
        Path to look for backend scripts
    .FUNCTIONALITY
        TireFire
    #>
    [cmdletbinding()]
    param(
        [ValidateNotNull()]
        [string]$Backend,

        [ValidateNotNull()]
        [hashtable]$BackendConfig,

        [ValidateNotNull()]
        [string[]]$BackendScriptPath
    )
    Switch ($PSBoundParameters.Keys)
    {
        'Backend' { $Script:TireFireConfig.Backend = $Backend }
        'BackendConfig' { $Script:TireFireConfig.BackendConfig = $BackendConfig }
        'BackendScriptPath' { $Script:TireFireConfig.BackendScriptPath = $BackendScriptPath }
    }
}
