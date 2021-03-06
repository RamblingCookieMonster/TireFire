@{
RootModule = 'TireFire.psm1'
ModuleVersion = '0.0.5'
GUID = 'd613d5da-37d8-45d6-8f6e-2f0629a535bd'
Author = 'Warren Frame'
CompanyName = 'Unknown'
Copyright = '(c) 2019 Warren Frame. All rights reserved.'
Description = 'Manage notes and tags, with a pluggable back end'
PowerShellVersion = '5.0'
FunctionsToExport = @(
    'Get-BackendHelp',
    'Get-Note',
    'Get-TireFireConfig',
    'New-Note',
    'Remove-Note',
    'Set-Note',
    'Set-TireFireConfig'
)
PrivateData = @{
    PSData = @{
        Tags = @('Note', 'Notes', 'Index')
        LicenseUri = 'https://github.com/RamblingCookieMonster/TireFire/blob/master/LICENSE'
        ProjectUri = 'https://github.com/RamblingCookieMonster/TireFire'
        # ReleaseNotes = ''
    }
}
}


