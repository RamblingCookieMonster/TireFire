Set-StrictMode -Version latest

# Make sure MetaFixers.psm1 is loaded - it contains Get-TextFilesList
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'MetaFixers.psm1') -Verbose:$false -Force

$projectRoot = $ENV:BHProjectPath
if(-not $projectRoot) {
    $projectRoot = $PSScriptRoot
}

Set-TireFireConfig -Backend File -BackendConfig @{RootPath = (Join-Path -Path $PSScriptRoot -ChildPath "Data/notes")}


Describe "Test Get-Note" {
    It 'should get all notes' {
        $Notes = Get-Note
        $Notes.Count | Should be 4
        'Same-1' | Should BeIn $Notes.ID
        'Same-2' | Should BeIn $Notes.ID
        'Same-3' | Should BeIn $Notes.ID
        'Different-1' | Should BeIn $Notes.ID
    }
    It 'should filter tags' {
        $Notes = Get-Note -Tags tag1
        $Notes.count | Should be 3
        'Same-1' | Should BeIn $Notes.ID
        'Same-2' | Should BeIn $Notes.ID
        'Same-3' | Should BeIn $Notes.ID
    }
    It 'should filter tags using AND' {
        $Notes = Get-Note -Tags tag1, tag3 -ComparisonOperator And
        $Notes.count | Should be 2
        'Same-2' | Should BeIn $Notes.ID
        'Same-3' | Should BeIn $Notes.ID
    }
    It 'should filter tags using OR' {
        $Notes = Get-Note -Tags tag1, tag3 -ComparisonOperator Or
        $Notes.count | Should be 4
        'Same-1' | Should BeIn $Notes.ID
        'Same-2' | Should BeIn $Notes.ID
        'Same-3' | Should BeIn $Notes.ID
        'Different-1' | Should BeIn $Notes.ID
    }
    It 'should filter data' {
        $Notes = Get-Note -Data This
        $Notes.count | Should be 3
        'Same-1' | Should BeIn $Notes.ID
        'Same-2' | Should BeIn $Notes.ID
        'Same-3' | Should BeIn $Notes.ID
    }
    It 'should filter data using AND' {
        $Notes = Get-Note -Data this, three -ComparisonOperator And
        $Notes.count | Should be 2
        'Same-1' | Should BeIn $Notes.ID
        'Same-2' | Should BeIn $Notes.ID
    }
    It 'should filter data using OR' {
        $Notes = Get-Note -Data three, four -ComparisonOperator Or
        $Notes.count | Should be 4
        'Same-1' | Should BeIn $Notes.ID
        'Same-2' | Should BeIn $Notes.ID
        'Same-3' | Should BeIn $Notes.ID
        'Different-1' | Should BeIn $Notes.ID
    }
    It 'should filter via query' {
        $Notes = Get-Note -Query 2
        $Notes.count | Should be 3
        'Same-1' | Should BeIn $Notes.ID
        'Same-2' | Should BeIn $Notes.ID
        'Different-1' | Should BeIn $Notes.ID
    }
    It 'should filter via query using AND' {
        $Notes = @( Get-Note -Query 2, Different -ComparisonOperator And )
        $Notes.count | Should be 1
        'Different-1' | Should BeIn $Notes.ID
    }
    It 'should filter via query using OR' {
        $Notes = Get-Note -Data three, four -ComparisonOperator Or
        $Notes.count | Should be 4
        'Same-1' | Should BeIn $Notes.ID
        'Same-2' | Should BeIn $Notes.ID
        'Same-3' | Should BeIn $Notes.ID
        'Different-1' | Should BeIn $Notes.ID
    }
    It 'should filter IDs' {
        $Notes = Get-Note -ID Same-3, Different-1
        $Notes.count | Should be 2
        'Same-3' | Should BeIn $Notes.ID
        'Different-1' | Should BeIn $Notes.ID
    }
    It 'should filter IDs with a wildcard' {
        $Notes = Get-Note -ID *-1, *-3 -ComparisonOperator Or
        $Notes.count | Should be 3
        'Same-1' | Should BeIn $Notes.ID
        'Same-3' | Should BeIn $Notes.ID
        'Different-1' | Should BeIn $Notes.ID
    }
    It 'should apply comparisonoperator AND across all parameters' {
        $Notes = Get-Note -ID *-1 -Data other -Tags tag2 -ComparisonOperator And
        @($Notes).count | Should be 1
        $Notes = Get-Note -ID *-1 -Data other -Tags tag3 -ComparisonOperator And
        @($Notes).count | Should be 0
    }
}
