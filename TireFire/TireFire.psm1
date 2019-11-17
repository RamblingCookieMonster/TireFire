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
    BackendPath = [string[]]'Default'
}
# Append default to end if specified
if($TireFireConfig.BackendPath -notcontains 'Default'){
    $TireFireConfig.BackendPath += 'Default'
}
[array]::reverse($TireFireConfig.BackendPath)
$BackendHash = @{}
foreach($Path in $TireFireConfig.BackendPath){
    if($Path -eq 'Default'){
        $Path = Join-Path $PSScriptRoot Backends
    }
    Write-Verbose "Checking $Path for Backend scripts"
    $Directories = @(Get-ChildItem -Path $Path -Directory)
    foreach($Backend in $Directories){
        if(-not $BackendHash.ContainsKey($Backend.BaseName)){
            Write-Verbose "Adding [$($Backend.Fullname)] backend from path [$SPath]"
            $BackendScripts = @{}
            'New', 'Get', 'Set', 'Remove' | ForEach-Object {
                $ExpectedFileName = "{0}{1}.ps1" -f $_, $Backend.BaseName
                $ExpectedScript = Join-Path $Backend.FullName $ExpectedFileName
                if(-not (Test-Path $ExpectedScript -ErrorAction SilentlyContinue)){
                    Write-Warning "[$($Backend.BaseName)] backend does not contain expected [$_] script at [$($ExpectedScript.Fullname)]"
                }
                else {
                    $BackendScripts.add($_, $ExpectedScript)
                }
            }
            $BackendHash.add($Backend.BaseName, $BackendScripts)
        }
        else {
            Write-Verbose "Skipping [$($Backend.Fullname)].  Change BackendPath precedence if needed"
        }
    }
}

Export-ModuleMember -Function $public.Basename
