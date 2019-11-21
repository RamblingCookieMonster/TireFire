<#
    .SYNOPSIS
        Get notes from the File backend
    .DESCRIPTION
        Get notes from the File backend

        BackEndConfig Parameters:
            RootPath.  Path to notes.  All notes get a filename pstf-$id

    .PARAMETER ID
        Get a note with this specific ID

        Accepts wildcard, faster without wildcard

    .PARAMETER Tags
        Get a note with at least one of the specified tags

    .PARAMETER Query
        Search using regex (-Match).  We search a note's ID, Tags, RelatedIDs, Data, and jsonified Data

    .PARAMETER IncludeRelated
        For any note that we would output, output RelatedIDs as well

    .PARAMETER RootPath
        BackEndConfig parameter specifiying a path to notes

        All notes get a filename pstf-$id
#>
[cmdletbinding()]
param(
    [string[]]$ID,
    [string[]]$Data,
    [string[]]$Tags,
    [string[]]$Query,
    [validateset('and','or')]
    [string]$ComparisonOperator = 'and',
    [switch]$IncludeRelated,
    [string]$RootPath
)
if(-not $RootPath){
    throw "RootPath required for now"
}
if(-not (Test-Path $RootPath)){
    throw "RootPath [$RootPath] does not exist.  Create it first"
}

Function Get-NoteData {
    [cmdletbinding()]
    param(
        [string]$Path
    )
    Write-Verbose "Getting notes from [$Path]"
    foreach($NoteFile in (Get-ChildItem $Path -File)){
        if($NoteFile.Name -notmatch '^pstf-'){
            Write-Verbose "Skipping $($NoteFile.Fullname), doesn't start pstf-"
            continue
        }
        try {
            Write-Verbose "Importing $($NoteFile.Fullname)"
            Import-Clixml -Path $NoteFile.Fullname
        }
        catch {
            Write-Error $_
            Write-Error "Failed to import $($NoteFile.Fullname)"
        }
    }
}

$splat = @{
    InputObject = Get-NoteData -Path $RootPath
}
if($PSBoundParameters.ContainsKey('ID')){
    $Exact = $true
    foreach($IDString in $ID){
        if($IDString -match '\*'){
            $Exact = $false
        }
    }
    if($Exact){
        foreach($IDString in $ID){
            $FileName = '{0}-{1}' -f 'pstf', ($IDString -Replace "^pstf-")
            $NotePath = Join-Path $RootPath $FileName
            if(-not (Test-Path $NotePath)){
                Write-Error "Could not find note with ID [$IDString] at path [$NotePath]"
            }
            else {
                Get-NoteData -Path $NotePath
            }
        }
        return
    }
    else {
        $splat.add('Id', $ID)
    }
}
if($PSBoundParameters.ContainsKey('Query')){
    $splat.Add('Query', $Query)
}
if($PSBoundParameters.ContainsKey('IncludeRelated')){
    $splat.Add('IncludeRelated', $IncludeRelated)
}
if($PSBoundParameters.ContainsKey('Tags')){
    $splat.Add('Tags', $Tags)
}
if($PSBoundParameters.ContainsKey('Data')){
    $splat.Add('Data', $Data)
}
$splat.Add('ComparisonOperator', $ComparisonOperator)
Select-Note @splat
