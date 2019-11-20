function Select-Note {
    [cmdletbinding()]
    param(
        [object[]]$InputObject,
        [string]$ID,
        [string]$Query,
        [string[]]$Tags,
        [string[]]$Data,
        [validateset('and','or')]
        [string]$ComparisonOperator = 'and',
        [switch]$IncludeRelated = $IncludeRelated
    )
    $Notes = @( foreach($Note in $InputObject){
        Write-verbose "Checking ID [$($Note.ID)] with query [$Query] Tags [$Tags] IncludeRelated [$IncludeRelated]"
        $Output = $False
        $AllOutput = [System.Collections.Generic.List[bool]]::new()
        if($PSBoundParameters.ContainsKey('Tags')) {
            foreach($Tag in $Tags){
                if(@($Note.Tags) -contains $Tag){
                    $Output = $true
                    continue
                }
            }
            if($Output){
                $AllOutput.add($true)
                if($ComparisonOperator -eq 'or') { $Note; continue }
            }
            else {
                $AllOutput.add($False)
            }
        }
        if($PSBoundParameters.ContainsKey('Data')){
            foreach($DataString in $Data) {
                if($Note.Data -match $DataString){
                    $AllOutput.add($true)
                    Write-Verbose "Data [$DataString] matched Description [$($Note.Data)]"
                    if($ComparisonOperator -eq 'or') { $Note; continue }
                }
                else{
                    # Okay, no matches, go to town and convert data to json...  not too deep...
                    try {
                        $StringData = $null
                        $StringData = ConvertTo-Json -InputObject $Note.Data -Depth 3 -Compress -ErrorAction Stop
                        if($StringData -match $DataString) {
                            $AllOutput.add($true)
                            Write-Verbose "Data [$DataString] matched jsonified Description [$StringData]"
                            if($ComparisonOperator -eq 'or') { $Note; continue }
                        }
                        else {
                            $AllOutput.add($false)
                        }
                    }
                    catch {
                        Write-Warning $_
                        Write-Verbose "Could not jsonify note ID $($Note.ID), skipping."
                        $AllOutput.add($false)
                        continue
                    }
                }
            }
        }
        if($PSBoundParameters.ContainsKey('Query')){
            if($Note.ID -match $Query){
                $Output = $true
                Write-Verbose "Query [$Query] matched ID [$($Note.ID)]"
                if($ComparisonOperator -eq 'or') { $Note; continue }
            }
            foreach($Tag in $Note.Tags){
                if($Tag -match $Query){
                    $Output = $true
                    Write-Verbose "Query [$Query] matched tag [$Tag]"
                    if($ComparisonOperator -eq 'or') { $Note; continue }
                }
            }
            foreach($RelatedID in $Note.RelatedIDs){
                if($RelatedID -match $Query){
                    $Output = $true
                    Write-Verbose "Query [$Query] matched RelatedID [$RelatedID]"
                    if($ComparisonOperator -eq 'or') { $Note; continue }
                }
            }
            if($Note.Data -match $Query){
                $Output = $true
                Write-Verbose "Query [$Query] matched Description [$($Note.Data)]"
                if($ComparisonOperator -eq 'or') { $Note; continue }
            }
            if(-not $Output){
                # Okay, no matches, go to town and convert data to json...  not too deep...
                try {
                    $StringData = $null
                    $StringData = ConvertTo-Json -InputObject $Note.Data -Depth 3 -Compress -ErrorAction Stop
                    if($StringData -match $Query) {
                        $Output = $true
                        Write-Verbose "Query [$Query] matched jsonified Description [$StringData]"
                        if($ComparisonOperator -eq 'or') { $Note; continue }
                    }
                }
                catch {
                    Write-Warning $_
                    Write-Verbose "Could not jsonify note ID $($Note.ID), skipping."
                }
            }
            if($Output){
                $AllOutput.add($true)
                if($ComparisonOperator -eq 'or') { $Note; continue }
            }
            else {
                $AllOutput.add($false)
            }
        }
        # No query, return all data
        if($AllOutput.count -eq 0) {
            $Note
            continue
        }
        # Query! if it was -or, we returned it already
        if($ComparisonOperator -eq 'and' -and $AllOutput -notcontains $false -and $AllOutput -contains $true){
            $Note
        }
    })
    if($IncludeRelated){
        $ExistingIDs = @($Notes.ID)
        $RelatedIDs = @($Notes.RelatedIDs | Sort-Object -Unique)
        foreach($Note in $InputObject){
            if($ExistingIDs -notcontains $Note.ID -and $RelatedIDs -Contains $Note.ID){
                $ExistingIDs += $Note.ID
                $Notes += $Note
            }
        }
        $Notes
    }
    else {
        $Notes
    }
}
