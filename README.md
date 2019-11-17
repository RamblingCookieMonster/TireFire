# TireFire

This is a PowerShell module to help manage notes and their metadata, with a pluggable back end.

Why TireFire?  Totally not because we might use this as an index to point to our various documentation tirefires.  Nope.

This is barebones and has minimal testing, just enough to meet my needs for a POC.  Use at your own risk : )

## Overview

Use this to create, read, update, or delete notes.

Note schema:

```text
ID:         User specified unique ID for a note.  Defaults to a GUID
Data:       Your note!  Some backends support serialization
Tags:       One or more tags to help organize and search for notes
RelatedIDs: One or more IDs of related notes.  No validation
UpdatedBy:  User specified UpdatedBy field.  Defaults to $ENV:USERNAME
UpdateDate: Date a note was updated
Source:     User specified source for a note.  Default depends on backend.
```

So!  Why might you use something like this?

* Have documentation in multiple sources, without a good index of it all?  Use notes with a predefined schema as an index to your various documentation islands
* Overabundance of acronyms, project names, groups, etc.?  Use notes to track wtf all this stuff means
* You don't have a solution in place for something like this already, and/or just want to experiment
* etc.

You might consider a variety of UIs.  Perhaps a PoshBot plugin that takes into account some common schema to simplify input and display, or a Dots plugin that pulls in notes and relates them to nodes in the DB.

## Installation

```powershell
Install-Module TireFire
Get-Command -Module TireFire

Get-BackendHelp # Outputs warning with list of backends
Get-BackendHelp -Name File

# Create and use a File backend for notes
$NoteHome = 'C:\notes'
mkdir $NoteHome
Set-TireFireConfig -Backend File -BackendConfig @{RootPath = $NoteHome}
```

## Examples

We'll start with the simplest built in backend:  `File`

#### Creating and querying notes

```powershell
# Set up a default path for all our notes, so we don't have to specify BackendConfig on every single command:
$NoteHome = 'C:\notes'
mkdir $NoteHome
Set-TireFireConfig -Backend File -BackendConfig @{ RootPath = $NoteHome }

# Create and read a no-frills note
New-Note -Data "this is completely useless!"
Get-Note
<#
    ID         : 70e3f983-f999-4674-a317-c32c3868dccd
    Data       : this is completely useless!
    Tags       :
    RelatedIDs :
    UpdatedBy  : wframe
    UpdateDate : 11/2/2019 9:35:39 PM
    Source     : C:\notes\pstf-70e3f983-f999-4674-a317-c32c3868dccd
#>

# Create a more useful note
New-Note -ID 'Define-SomeAcronym' -Tags Related, Keywords -Data ([pscustomobject]@{
    Name = 'Fully expanded Some Acronym'
    Description = 'A useful description of Some Acronym abc123'
    Uri = 'https://someacronym.fqdn'
    DocsUri = 'https://docs.fqdn/someacronym'
})

# Query for things
Get-Note # All the notes!

# Search ID, Tags, RelatedIDs, and Description with -Match $Query
Get-Note -Query abc123

<#
    ID         : Define-SomeAcronym
    Data       : @{Name=Fully expanded Some Acronym; Description=A useful
                description of Some Acronym abc123; Uri=https://someacronym.fqdn;
                DocsUri=https://docs.fqdn/someacronym}
    ...
#>

# Verbose messages point out what matched in verbose messages.  f999 was part of the randomly generated ID
Get-Note -Query f999 -Verbose
<#
    VERBOSE: Selecting ID [70e3f983-f999-4674-a317-c32c3868dccd] with query [f999] Tags [] IncludeRelated [False]
    VERBOSE: Query [f999] matched ID [70e3f983-f999-4674-a317-c32c3868dccd]
    VERBOSE: Selecting ID [Define-SomeAcronym] with query [f999] Tags [] IncludeRelated [False]

    ID         : 70e3f983-f999-4674-a317-c32c3868dccd
    Data       : this is completely useless!
    ...
#>

Get-Note -ID 'Define-SomeAcronym'
<#
    ID         : Define-SomeAcronym
    Data       : @{Name=Fully expanded Some Acronym; Description=A useful
                description of Some Acronym abc123; Uri=https://someacronym.fqdn;
                DocsUri=https://docs.fqdn/someacronym}
    ...
#>
```

#### Working with existing notes

```powershell
# Set up a default path for all our notes, so we don't have to specify BackendConfig on every single command:
$NoteHome = 'C:\notes'
Set-TireFireConfig -Backend File -BackendConfig @{ RootPath = $NoteHome }

# Delete all existing notes
Get-Note | Remove-Note

# Add some notes
1..10 | foreach-object {
    New-Note -ID "Note-Number-$_" `
             -Data "Some data for note $_" `
             -Tags (Get-Random tag1, tag2, tag3, tag4 -Count 2)
}

# Change some data and replace all tags for note 1
Set-Note -TargetID 'Note-Number-1' -Data "Oops!" -Tags 'Replace', 'all', 'tags'
Get-Note -ID Note-Number-1 | Select ID, Data, Tags
<#
    ID            Data  Tags
    --            ----  ----
    Note-Number-1 Oops! {Replace, all, tags}
#>

# Replace tag2 with tagtwo using pipeline input
Get-Note -Tags tag2 | Set-Note -RemoveTag tag2 -AddTag tagtwo
Get-Note -Tags tag2 | select ID, Tags # No output, tag2 is gone!
Get-Note -Tags tagtwo | select ID, Tags
<#
    ID            Tags
    --            ----
    Note-Number-3 {tag3, tagtwo}
    Note-Number-5 {tag1, tagtwo}
...
#>

# Clean up!
Get-Note | Remove-Note
Get-Note # all gone
```

## Back ends

TireFire supports multiple back ends.  Some details:

### Back end descriptions

#### File

Parameters:

* `RootPath`:  Path under which we create all notes.  We create one file per note

Details:

* `Filename`:  We take the note's ID, and prepend `pstf-`.  e.g. RootPath `C:\temp`, ID `abc-123` leads to a Note at `C:\temp\pstf-abc-123`
* `Serialization`:  We serialize the entire note via `Import-Clixml` and `Export-Clixml`
* `Scalability`:  Each note is a file in the RootPath.  This means you may run into performance issues in general with a large number of notes, and Get-Note with anything but `-ID` will read every single file
* `When to use`:  When you don't have another back end, or don't need to scale.  We use Clixml so storage won't be very efficient, and use single files per note in a single directory, so don't go crazy creating too many notes!

### Writing your own Back end

Each backend has a name, and parameters to configure it, that are set with Set-TireFireConfig:

```powershell
Set-TireFireConfig -Backend File -BackendConfig @{ RootPath = 'C:\notes' }
```

Want to write your own?  This is super janky.

* Create a backend folder in `TireFire/Backends/$BackendName` with `Get$BackendName`, `New$BackendName`, `Set$BackendName`, and `Remove$BackendName` ps1 files in it.  We rely on the this naming convention
* Allow every parameter that can be configured in `Get-Note`, `New-Note`, `Set-Note`, and `Remove-Note` in the respective backend script (e.g. `Get$BackendName` needs to support all parameters from `Get-Note`)
* Include parameters specific to your backend as needed
* Include help, and point out `BackEndConfig Parameters` in the `.Description` section, and for the `.Parameter` section of each backendconfig parameter
* Do stuff based on the parameters : )  See [TireFire/Backends/File/SetFile.ps1](TireFire/Backends/File/SetFile.ps1) for an example

Yeah.  It's janky af.  Sorry, this is a POC and not something I had time to do right : )
