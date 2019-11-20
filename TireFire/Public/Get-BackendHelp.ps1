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
    .EXAMPLE
        Get-BackendHelp -Name File -Action New
        Get help for creating a new note with the File backend
    .EXAMPLE
        Get-BackendHelp -Name File
        Get help for Get, Set, New, and Remove actions for the File backend
    .PARAMETER Name
        Backend name.  e.g. File
    .PARAMETER Action
        Get help for this action for the specified backend name - Get, Set, New, or Remove
    .PARAMETER Full
        Get detailed help including examples and description
    #>
    [cmdletbinding()]
    param(
        [validateset('File')]$Name,
        [validateset('Get', 'Set', 'New', 'Remove', '*')]$Action = '*',
        [switch]$Full
    )
    if(-not $PSBoundParameters.ContainsKey('Name')){
        Write-Warning "No name specified.  Valid names:`n$()$($Script:BackendHash.Keys | Out-String)"
        return
    }
    $Backend = $Script:BackendHash.$Name
    foreach($Verb in 'Get', 'Set', 'New', 'Remove'){
        if($Verb -like  $Action){
            Write-Verbose "Getting help for [$Verb] [$Name] with path [$($Backend.$Verb)]"
            Get-Help $Backend.$Verb -Detailed
        }
    }
}
