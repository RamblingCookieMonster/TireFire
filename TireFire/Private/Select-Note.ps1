function Select-Note {
    [cmdletbinding()]
    param(
        [object[]]$InputObject,
        [string]$ID,
        [string]$Query,
        [string[]]$Tags,
        [switch]$IncludeRelated = $IncludeRelated
    )
    $Data = @( foreach($Note in $InputObject){
        Write-verbose "Checking ID [$($Note.ID)] with query [$Query] Tags [$Tags] IncludeRelated [$IncludeRelated]"
        $Output = $False
        if($PSBoundParameters.ContainsKey('Query')){
            if($Note.ID -match $Query){
                $Output = $true
                Write-Verbose "Query [$Query] matched ID [$($Note.ID)]"
            }
            foreach($Tag in $Note.Tags){
                if($Tag -match $Query){
                    $Output = $true
                    Write-Verbose "Query [$Query] matched tag [$Tag]"
                }
            }
            foreach($RelatedID in $Note.RelatedIDs){
                if($RelatedID -match $Query){
                    $Output = $true
                    Write-Verbose "Query [$Query] matched RelatedID [$RelatedID]"
                }
            }
            if($Note.Data -match $Query){
                $Output = $true
                Write-Verbose "Query [$Query] matched Description [$($Note.Data)]"
            }
            if(-not $Output){
                # Okay, no matches, go to town and convert data to json...  not too deep...
                try {
                    $StringData = $null
                    $StringData = ConvertTo-Json -InputObject $Note.Data -Depth 3 -Compress -ErrorAction Stop
                    if($StringData -match $Query) {
                        $Output = $true
                        Write-Verbose "Query [$Query] matched jsonified Description [$StringData]"
                    }
                }
                catch {
                    Write-Warning $_
                    Write-Verbose "Could not jsonify note ID $($Note.ID), skipping."
                }
            }
        }
        elseif($PSBoundParameters.ContainsKey('Tags')) {
            foreach($Tag in $Tags){
                if(@($Note.Tags) -contains $Tag){
                    $Output = $true
                    continue
                }
            }
        }
        else {
            $Output = $True
        }
        if($Output){
            $Note
        }
    })
    if($IncludeRelated){
        $ExistingIDs = @($Data.ID)
        $RelatedIDs = @($Data.RelatedIDs | Sort-Object -Unique)
        foreach($Note in $InputObject){
            if($ExistingIDs -notcontains $Note.ID -and $RelatedIDs -Contains $Note.ID){
                $ExistingIDs += $Note.ID
                $Data += $Note
            }
        }
        $Data
    }
    else {
        $Data
    }
}
