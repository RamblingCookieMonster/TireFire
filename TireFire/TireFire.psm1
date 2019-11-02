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

$TireFireConfig = @{
    Backend = 'File'
    BackendConfig = @{ }
    BackendScriptPath = [string[]]'Default'
}
# Append default to end if specified
if($TireFireConfig.BackendScriptPath -notcontains 'Default'){
    $TireFireConfig.BackendScriptPath += 'Default'
}
[array]::reverse($TireFireConfig.BackendScriptPath)
$BackendHash = @{}
$Backends = foreach($Path in $TireFireConfig.BackendScriptPath){
    if($Path -eq 'Default'){
        $Path = Join-Path $PSScriptRoot Backends/*.ps1
    }
    Write-Verbose "Checking $Path for Backend scripts"
    $Scripts = @(Get-ChildItem -Path $Path -File -Filter *.ps1)
    foreach($Script in $Scripts){
        if(-not $BackendHash.ContainsKey($Script.BaseName)){
            Write-Verbose "Importing [$($Script.Fullname)] from path [$SPath]"
            $BackendHash.add($Script.BaseName, $Script.FullName)
            $Script
        }
        else {
            Write-Verbose "Skipping [$($Script.Fullname)].  Change BackendScriptPath precedence if needed"
        }
    }
}

Export-ModuleMember -Function $public.Basename
