#requires -version 2
<#
.SYNOPSIS
  Find and manage inactive Active Directory users.

.DESCRIPTION
  This script allows you to specify the criteria required to identify inactive users within your AD environment. This script also allows
  for the management of found users. Management of users includes one or more of the following options:
    - Reporting
    - Disabling Users
    - Deleting Users

.PARAMETER SearchScope
  Optional. Determines the search scope of what type of user you would like to include in the inactive user search. Options available are:
   - All                        : Default option. All user types including all standard users, service accounts and never logged on accounts.
   - OnlyInactiveUsers          : Only standard user accounts. This option excludes service accounts and never logged on accounts.
   - OnlyServiceAccounts        : Only server accounts. This option excludes standard user accounts and never logged on accounts.
   - OnlyNeverLoggedOn          : Only never logged on accounts. This option excludes standard user accounts and service accounts.
   - AllExceptServiceAccounts   : All user account types excluding service accounts.
   - AllExceptNeverLoggedOn     : All user account types excluding never logged on accounts.

   Note: If not specified, the default search scope is All (i.e. all user accounts, service accounts and never logged on accounts).

.PARAMETER DaysInactive
  Optional. The number of days a user account hasn't logged into the domain for in order to classify it as inactive. The default option is 90
  days, which means any user account that hasn't logged into the domain for 90 days or more is considered inactive and therefore managed by this
  script.

.PARAMETER ServiceAccountIdentifier
  Optional. The username prefix or postfix that is used to indetify a service account from a standard user account. The default option is 'svc'.
  Determining whether an account is a service account is useful in order to be able to include or exclude service accounts from the search scope.

  Note: For more information see the help information on the parameter SearchScope. 

  Example: All accounts with the prefix or postfix of svc (e.g. svc-MyAccount or MyAccount-svc) are identified as service accounts and can
  therefore be included or exclueded from the search scope.

.PARAMETER ReportFilePath
  Optional. This is the location where the report of inactive users will be saved to. If this parameter is not specified, the default location the
  report is saved to is C:\InactiveUsers.csv.

  Note: When specifying the file path, you MUST include the file name with the extension of .csv. Example: 'C:\MyReport.csv'.

.PARAMETER DisableUsers
  Optional. If this parameter is specified, this script will disable the inactive users found based on the search scope specified.

  Note: If this parameter is not specified, then by default this script WILL NOT disable any inactive users found.

.PARAMETER DeleteUsers
  Optional. If this parameter is specified, this script will delete the inactive users found based on the search scope specified.

  Note: If this parameter is not specified, then by default this script WILL NOT delete any inactive users found.

.INPUTS
  None.

.OUTPUTS
  Report of inactive users found. See ReportFilePath parameter for more information.

.NOTES
  Version:        1.0
  Author:         Luca Sturlese
  Creation Date:  16.07.2016
  Purpose/Change: Initial script development

.EXAMPLE
  Execution of script using default parameters. Default execution performs reporting of inactive AD user only, not disabling or deleting any accounts.
  By default the report is saved in C:\.

  .\Find-ADInactiveUsers.ps1

.EXAMPLE
  Reporting and disabling all user accounts, except never logged on accounts. Storing the report in C:\Reports.

  .\Find-ADInactiveUsers.ps1 -SeachScope AllExceptNeverLoggedOn -ReportFilePath 'C:\Reports\DisabledUsers.csv' -DisableUsers

.EXAMPLE
  Find & delete all inactive users (not service accounts) that haven't logged in for the last 30 days. Include never logged on accounts in this search.

  .\Find-ADInactiveUsers.ps1 -SeachScope AllExceptServiceAccounts -DaysInactive 30 -DeleteUsers

.EXAMPLE
  Delete all user accounts that have never been logged into. Store the report in C:\Reports.

  .\Find-ADInactiveUsers.ps1 -SeachScope OnlyNeverLoggedOn -ReportFilePath 'C:\Reports\NotLoggedOnAccounts.csv' -DeleteUsers
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

Param (
  [Parameter(Mandatory = $false)][string][ValidateSet('All', 'OnlyInactiveUsers', 'OnlyServiceAccounts', 'OnlyNeverLoggedOn', 'AllExceptServiceAccounts', 'AllExceptNeverLoggedOn')]$SearchScope = 'All',
  [Parameter(Mandatory = $false)][int]$DaysInactive = 90,
  [Parameter(Mandatory = $false)][string]$ServiceAccountIdentifier = 'svc',
  [Parameter(Mandatory = $false)][string]$ReportFilePath = 'C:\InactiveUsers.csv',
  [Parameter(Mandatory = $false)][switch]$DisableUsers = $false,
  [Parameter(Mandatory = $false)][switch]$DeleteUsers = $false
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = 'SilentlyContinue'

#Import Modules & Snap-ins
Import-Module ActiveDirectory

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Set Inactive Date:
$InactiveDate = (Get-Date).Adddays(-($DaysInactive))

#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function Find-Accounts {
  Param ()

  Begin {
    Write-Host "Finding inactive user accounts based on search scope specified [$SearchScope]..."
  }

  Process {
    Try {
      #Set Service Account Identifier
      $ServiceAccountIdentifier = '*' + $ServiceAccountIdentifier + '*'

      Switch ($SearchScope) {
        'All' {
          $global:Results = Get-ADUser -Filter { LastLogonDate -lt $InactiveDate -or LastLogonDate -notlike "*" -and Enabled -eq $true } -Properties LastLogonDate | Select-Object @{ Name="Username"; Expression = {$_.SamAccountName} }, Name, LastLogonDate, DistinguishedName
        }

        'OnlyInactiveUsers' {
          $global:Results = Get-ADUser -Filter { LastLogonDate -lt $InactiveDate -and Enabled -eq $true -and SamAccountName -notlike $ServiceAccountIdentifier } -Properties LastLogonDate | Select-Object @{ Name="Username"; Expression = {$_.SamAccountName} }, Name, LastLogonDate, DistinguishedName
        }

        'OnlyServiceAccounts' {
          $global:Results = Get-ADUser -Filter { LastLogonDate -lt $InactiveDate -and Enabled -eq $true -and SamAccountName -like $ServiceAccountIdentifier } -Properties LastLogonDate | Select-Object @{ Name="Username"; Expression = {$_.SamAccountName} }, Name, LastLogonDate, DistinguishedName
        }

        'OnlyNeverLoggedOn' {
          $global:Results = Get-ADUser -Filter { LastLogonDate -notlike "*" -and Enabled -eq $true } -Properties LastLogonDate | Select-Object @{ Name="Username"; Expression = {$_.SamAccountName} }, Name, LastLogonDate, DistinguishedName
        }

        'AllExceptServiceAccounts' {
          $global:Results = Get-ADUser -Filter { LastLogonDate -lt $InactiveDate -and Enabled -eq $true -and SamAccountName -notlike $ServiceAccountIdentifier -or LastLogonDate -notlike "*" } -Properties LastLogonDate | Select-Object @{ Name="Username"; Expression = {$_.SamAccountName} }, Name, LastLogonDate, DistinguishedName
        }

        'AllExceptNeverLoggedOn' {
          $global:Results = Get-ADUser -Filter { LastLogonDate -lt $InactiveDate -and Enabled -eq $true } -Properties LastLogonDate | Select-Object @{ Name="Username"; Expression = {$_.SamAccountName} }, Name, LastLogonDate, DistinguishedName
        }

        Default {
          Write-Host -BackgroundColor Red "Error: An unknown error occcurred. Can't determine search scope. Exiting."
          Break
        }
      }
    }

    Catch {
      Write-Host -BackgroundColor Red "Error: $($_.Exception)"
      Break
    }

    End {
      If ($?) {
        Write-Host 'Completed Successfully.'
        Write-Host ' '
      }
    }
  }
}

Function Create-Report {
  Param ()

  Begin {
    Write-Host "Creating report of inactive users in specified path [$ReportFilePath]..."
  }

  Process {
    Try {
      #Check file path to ensure correct
      If ($ReportFilePath -notlike '*.csv') {
        $ReportFilePath = Join-Path -Path $ReportFilePath -ChildPath '\InactiveUsers.csv'
      }

      # Create CSV report
      $global:Results | Export-Csv $ReportFilePath -NoTypeInformation
    }

    Catch {
      Write-Host -BackgroundColor Red "Error: $($_.Exception)"
      Break
    }
  }

  End {
    If ($?) {
      Write-Host 'Completed Successfully.'
      Write-Host ' '
    }
  }
}

Function Disable-Accounts {
  Param ()

  Begin {
    Write-Host 'Disabling inactive users...'
  }

  Process {
    Try {
      ForEach ($Item in $global:Results){
        Disable-ADAccount -Identity $Item.DistinguishedName
        Write-Host "$($Item.Username) - Disabled"
      }
    }

    Catch {
      Write-Host -BackgroundColor Red "Error: $($_.Exception)"
      Break
    }
  }

  End {
    If ($?) {
      Write-Host 'Completed Successfully.'
      Write-Host ' '
    }
  }
}

Function Delete-Accounts {
  Param ()

  Begin {
    Write-Host 'Deleting inactive users...'
  }

  Process {
    Try {
      ForEach ($Item in $global:Results){
        Remove-ADUser -Identity $Item.DistinguishedName -Confirm:$false
        Write-Host "$($Item.Username) - Deleted"
      }
    }

    Catch {
      Write-Host -BackgroundColor Red "Error: $($_.Exception)"
      Break
    }
  }

  End {
    If ($?) {
      Write-Host 'Completed Successfully.'
      Write-Host ' '
    }
  }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Find-Accounts
Create-Report

If ($DisableUsers) {
  Disable-Accounts
}

If ($DeleteUsers) {
  Delete-Accounts
}
