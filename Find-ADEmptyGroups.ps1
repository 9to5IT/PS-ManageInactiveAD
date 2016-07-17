#requires -version 2
<#
.SYNOPSIS
  Find and manage empty Active Directory groups.

.DESCRIPTION
  This script allows you to find and manage empty security and distribution groups withing your AD environment. This script also allows
  for the management of found groups. Management of empty groups includes one or more of the following options:
    - Reporting
    - Deleting

.PARAMETER SearchScope
  Optional. Specifies an Active Directory Path to search under. This is primarily used to narrow down your search within a certain OU and it's children.
  Search Scope must be specfied in LDAP format. If not specified, the default search scope is the root of the domain.

  Example: -SearchScope "OU=GROUPS,DC=testlab,DC=com"

.PARAMETER ReportFilePath
  Optional. This is the location where the report of empty groups will be saved to. If this parameter is not specified, the default location
  the report is saved to is C:\EmptyGroups.csv.

  Note: When specifying the file path, you MUST include the file name with the extension of .csv. Example: 'C:\MyReport.csv'.

.PARAMETER DeleteObjects
  Optional. If this parameter is specified, this script will delete the empty groups found based on the search scope specified.

  Note: If this parameter is not specified, then by default this script WILL NOT delete any empty groups found.

.INPUTS
  None.

.OUTPUTS
  Report of empty groups found. See ReportFilePath parameter for more information.

.NOTES
  Version:        1.0
  Author:         Luca Sturlese
  Creation Date:  16.07.2016
  Purpose/Change: Initial script development

.EXAMPLE
  Execution of script using default parameters. Default execution performs reporting of empty AD gruops only, not deleting any objects.
  By default the report is saved in C:\.

  .\Find-ADEmptyGroups.ps1

.EXAMPLE
  Reporting and deleting all empty groups found within the GROUPS OU. Store the report in C:\Reports.

  .\Find-ADEmptyGroups.ps1 -SeachScope "OU=GROUPS,DC=testlab,DC=com" -ReportFilePath 'C:\Reports\DeletedGroups.csv' -DeleteObjects
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

Param (
  [Parameter(Mandatory = $false)][string]$SearchScope,
  [Parameter(Mandatory = $false)][string]$ReportFilePath = 'C:\EmptyGroups.csv',
  [Parameter(Mandatory = $false)][switch]$DeleteObjects = $false
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = 'SilentlyContinue'

#Import Modules & Snap-ins
Import-Module ActiveDirectory

#----------------------------------------------------------[Declarations]----------------------------------------------------------



#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function Find-Objects {
  Param ()

  Begin {
    Write-Host "Finding empty groups based on search scope specified..."
  }

  Process {
    Try {
      If($SearchScope) {
        $global:Results = Get-ADGroup -Filter { Members -notlike "*" } -SearchBase $SearchScope | Select-Object Name, GroupCategory, DistinguishedName
      } Else {
        $global:Results = Get-ADGroup -Filter { Members -notlike "*" } | Select-Object Name, GroupCategory, DistinguishedName
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
    Write-Host "Creating report of empty groups in specified path [$ReportFilePath]..."
  }

  Process {
    Try {
      #Check file path to ensure correct
      If ($ReportFilePath -notlike '*.csv') {
        $ReportFilePath = Join-Path -Path $ReportFilePath -ChildPath '\EmptyGroups.csv'
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

Function Delete-Objects {
  Param ()

  Begin {
    Write-Host 'Deleting empty groups...'
  }

  Process {
    Try {
      ForEach ($Item in $global:Results){
        Remove-ADGroup -Identity $Item.DistinguishedName -Confirm:$false
        Write-Host "$($Item.Name) - Deleted"
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

Find-Objects
Create-Report

If ($DeleteObjects) {
  Delete-Objects
}
