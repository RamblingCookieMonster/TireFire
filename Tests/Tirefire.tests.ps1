Set-StrictMode -Version latest

# Make sure MetaFixers.psm1 is loaded - it contains Get-TextFilesList
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'MetaFixers.psm1') -Verbose:$false -Force

$projectRoot = $ENV:BHProjectPath
if(-not $projectRoot) {
    $projectRoot = $PSScriptRoot
}
