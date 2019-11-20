function Get-TireFireConfig {
    <#
    .SYNOPSIS
       Get TireFire configuration values
    .DESCRIPTION
       Get TireFire configuration values
    .EXAMPLE
        Get-TireFireConfig
        Get current TireFire config
    .FUNCTIONALITY
        TireFire
    #>
    [cmdletbinding()]
    param()
    $Script:TireFireConfig
}
