function Select-Note {
    [cmdletbinding()]
    param(
        [object[]]$InputObject,
        [string[]]$ID,
        [string[]]$Query,
        [string[]]$Tags,
        [string[]]$Data,
        [validateset('and','or')]
        [string]$ComparisonOperator = 'and',
        [switch]$IncludeRelated = $IncludeRelated
    )
    $Notes = @( :note foreach($Note in $InputObject){
        Write-verbose "Checking ID [$($Note.ID)] with query [$Query] Tags [$Tags] IncludeRelated [$IncludeRelated]"
        $NoteAnd = [System.Collections.Generic.List[bool]]::new()
        if($PSBoundParameters.ContainsKey('ID')) {
            $And = [System.Collections.Generic.List[bool]]::new()
            foreach($IDstring in $ID){
                if($Note.ID -like $IDstring){
                    Write-Verbose "ID [$IDString] matched [$($Note.ID)]"
                    if($ComparisonOperator -eq 'And'){
                        $And.add($true)
                    }
                    else {
                        $Note
                        continue note
                    }
                }
                else {
                    $And.add($false)
                }
            }
            if($ComparisonOperator -eq 'and') {
                if($And -contains $false){
                    continue note
                }
                elseif($And -contains $true) {
                    $NoteAnd.add($True)
                }
            }
        }
        if($PSBoundParameters.ContainsKey('Tags')) {
            $And = [System.Collections.Generic.List[bool]]::new()
            foreach($Tag in $Tags){
                if(@($Note.Tags) -contains $Tag){
                    Write-Verbose "Tag [$Tag] found in [$($Note.Tags)]"
                    if($ComparisonOperator -eq 'And'){
                        $And.add($true)
                    }
                    else {
                        $Note
                        continue note
                    }
                }
                else {
                    $And.add($false)
                }
            }
            if($ComparisonOperator -eq 'and') {
                if($And -contains $false){
                    continue note
                }
                elseif($And -contains $true) {
                    $NoteAnd.add($True)
                }
            }
        }
        if($PSBoundParameters.ContainsKey('Data')){
            $And = [System.Collections.Generic.List[bool]]::new()
            foreach($DataString in $Data) {
                if($Note.Data -match $DataString){
                    $And.add($True)
                    Write-Verbose "Data [$DataString] matched Data [$($Note.Data)]"
                    if($ComparisonOperator -eq 'or') { $Note; continue note}
                }
                else{
                    # Okay, no matches, go to town and convert data to json...  not too deep...
                    try {
                        $StringData = $null
                        $StringData = ConvertTo-Json -InputObject $Note.Data -Depth 3 -Compress -ErrorAction Stop
                        if($StringData -match $DataString) {
                            Write-Verbose "Data [$DataString] matched jsonified Data [$StringData]"
                            if($ComparisonOperator -eq 'and') {
                                $And.add($True)
                            } else {
                                $Note
                                continue note
                            }
                        }
                        else {
                            $NoteAnd.add($false)
                            $And.add($false)
                        }
                    }
                    catch {
                        Write-Warning $_
                        Write-Verbose "Could not jsonify note ID $($Note.ID), skipping."
                        $NoteAnd.add($false)
                        $And.add($false)
                        continue
                    }
                }
            }
            if($ComparisonOperator -eq 'and') {
                if($And -contains $false){
                    continue note
                }
                elseif($And -contains $true) {
                    $NoteAnd.add($True)
                }
            }
        }
        if($PSBoundParameters.ContainsKey('Query')){
            $And = [System.Collections.Generic.List[bool]]::new()
            foreach($QueryString in $Query){
                $ThisMatched = $False
                if($Note.ID -match $QueryString){
                    $And.add($true)
                    $ThisMatched = $true
                    Write-Verbose "Query [$QueryString] matched ID [$($Note.ID)]"
                    if($ComparisonOperator -eq 'or') { $Note; continue note}
                    continue
                }
                foreach($Tag in $Note.Tags){
                    if($Tag -match $QueryString){
                        $ThisMatched = $true
                        $And.add($true)
                        Write-Verbose "Query [$QueryString] matched tag [$Tag]"
                        if($ComparisonOperator -eq 'or') { $Note; continue note}
                        break
                    }
                }
                foreach($RelatedID in $Note.RelatedIDs){
                    if($RelatedID -match $QueryString){
                        $ThisMatched = $true
                        $And.add($true)
                        Write-Verbose "Query [$QueryString] matched RelatedID [$RelatedID]"
                        if($ComparisonOperator -eq 'or') { $Note; continue note}
                        break
                    }
                }
                if($Note.Data -match $QueryString){
                    $ThisMatched = $true
                    $And.add($true)
                    Write-Verbose "Query [$QueryString] matched Data [$($Note.Data)]"
                    if($ComparisonOperator -eq 'or') { $Note; continue note}
                    continue
                }
                if(-not $ThisMatched){
                    # Okay, no matches, go to town and convert data to json...  not too deep...
                    try {
                        $StringData = $null
                        $StringData = ConvertTo-Json -InputObject $Note.Data -Depth 3 -Compress -ErrorAction Stop
                        if($StringData -match $QueryString) {
                            $And.add($True)
                            $ThisMatched = $true
                            Write-Verbose "Query [$QueryString] matched jsonified Data [$StringData]"
                            if($ComparisonOperator -eq 'or') {
                                $Note
                                continue note
                            }
                        }
                        else {
                            Write-Verbose "No query [$QueryString] match for [$($Note.Id)]"
                            $NoteAnd.add($false)
                            $And.add($false)
                        }
                    }
                    catch {
                        Write-Warning $_
                        Write-Verbose "Could not jsonify note ID $($Note.ID), skipping."
                        $NoteAnd.add($false)
                        $And.add($false)
                    }
                }
            }
            # We searched all the queries, did any switch output to true?
            if($ComparisonOperator -eq 'and') {
                if($And -contains $false -or -not $ThisMatched){
                    Write-Verbose "Skipping due to AND"
                    continue note
                }
                elseif($And -contains $true) {
                    Write-Verbose "Adding NoteAnd due to AND"
                    $NoteAnd.add($True)
                }
            }
        }
        # No query, return all data
        if($NoteAnd.Count -eq 0 -and
           -not $PSBoundParameters.ContainsKey('ID') -and
           -not $PSBoundParameters.ContainsKey('Query') -and
           -not $PSBoundParameters.ContainsKey('Tags') -and
           -not $PSBoundParameters.ContainsKey('Data')
        ) {
            $Note
            continue
        }
        if($ComparisonOperator -eq 'and' -and $NoteAnd -notcontains $false -and $NoteAnd -contains $true){
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
