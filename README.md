# TireFire

This is a PowerShell module to simplify managing notes and their metadata, with a pluggable back end.

Why TireFire?  Totally not because we might use this as an index to point to our various documentation tirefires.  Nope.

## Overview

Use this to create, read, update, or delete notes.

Note schema:

```text
ID:         User specified unique ID for a note.  Defaults to a GUID
Data:       Your note!  Some backends support serialization
Tags:       One or more tags to help organize and search for notes
UpdatedBy:  User specified UpdatedBy field.  Defaults to $ENV:USERNAME
UpdateDate: Date a note was updated
Source:     User specified source for a note.  Default depends on backend.
```

This is barebones and has minimal testing, just enough to meet my needs for a POC.  Use at your own risk : )

## Installation

```powershell
Install-Module TireFire
Get-Command -Module TireFire
```

## Examples

We'll start with the simplest built in backend:  `File`

```powershell

# Set up a default path for all our notes, so we don't have to specify BackendConfig on every single command:
$NoteHome = 'C:\notes'
mkdir $NoteHome
Set-TireFireConfig -Backend File -BackendConfig @{
    RootPath = $NoteHome
}

# Create a note!

```

## Back ends

TireFire supports multiple back ends.  Some details:

### File

Parameters:

* `RootPath`:  Path under which we create one file per note

Notes:

* `Filename`:  We take the note's ID, and prepend `pstf-`.  e.g. RootPath = C:\temp, ID abc-123 leads to a Note at C:\temp\pstf-abc-123
* `Serialization`:  We support serialization, and use `Import-Clixml` and `Export-Clixml`
* `When to use`:  When you don't have another back end, and don't need to scale.  We use Clixml so storage won't be very efficient, and use single files per note in a single directory, so don't go crazy creating too many notes!
