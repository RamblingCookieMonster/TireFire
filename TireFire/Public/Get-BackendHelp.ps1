function Get-BackendHelp {
    <#
    .SYNOPSIS
        Get help for a specific backend

    .DESCRIPTION
        Get help for a specific backend

        What to look for:

        * The backend description, and individual parameter notes should
          indicate which parameters are used in the BackendConfig
        * Backend specific notes on parameters and their default values

        Backend help is only intended to give you an idea of how Get, Set,
        New, and Remove-Note will behave.  Do not use the Backend script
        outside of these abstractions
    #>
    [cmdletbinding()]
    param([validateset('File')]$Name)
    if(-not $PSBoundParameters.ContainsKey('Name')){
        Write-Warning "No name specified.  Valid names and associated paths:`n$()$($Script:Backends | Select-Object BaseName, Fullname | Out-String)"
        return
    }
    $Backend = $Script:Backends.where({$_.BaseName -eq $Name})
    Write-Verbose "Getting help for [$Name] with path [$($Backend.Fullname)]"
    Get-Help $Backend.Fullname
}
