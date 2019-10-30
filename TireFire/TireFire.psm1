# Dot source public/private functions
$public  = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'public/*.ps1')  -Recurse -ErrorAction Stop)
$private = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'private/*.ps1') -Recurse -ErrorAction Stop)
foreach ($import in @($public + $private)) {
    try {
        . $import.FullName
    }
    catch {
        throw "Unable to dot source [$($import.FullName)]"
    }
}

$Backends = @( Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath Backends/*.ps1 -ErrorAction Stop) )
$TireFireConfig = @{
    Backend = 'File'
    BackendConfig = @{ }
}

Export-ModuleMember -Function $public.Basename
