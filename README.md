# PS-ManageInactiveAD

## Overview
This repo contains scripts that I have developed that allow you to find, report on and manage inactive objects within your Active Directory environment. The scripts allow you to find and manage the following AD objects:

- Inactive user accounts
	- Standard user accounts
	- Service accounts
	- Never logged on users
- Inactive computer objects
	- Standard computer objects
	- Never logged on computers
- Empty groups
	- Security groups
	- Distribution groups
- Empty Organizational Units (OUs)

## Management Options
Once you have configured the search criteria to find (and possibly exclude) the objects you determine are inactive, you have the following options available to you:

- Reporting only (**default option**)
- Disable (available on user & computer accounts only)
- Delete (available on all object types)

## Installation Instructions
There are no "installation instructions" per say, but if you would like to get these going in your environment, then all you need to do is download or clone this repo, and execute them on a **domain joined machine** that has **administrative permissions** in AD.

### Prerequisites
There are a few prerequisites to being able to run these scripts in your environment. They are:

- PC \ Server must be domain joined to the AD environment you want to manage
- PowerShell 2.0 minimum
- Remote Server Administration Tools (RSAT) must be installed
- User account you are running these from must have administrative access within AD (only required if you want to disable and delete inactive objects)

### Help?
Each of the scripts have been completely documented following the PowerShell help standards. This help documentation includes full parameter definition and multiple examples to help understand the different use cases for each script.

To view the help, simply run `Get-Help Find-ADInactiveUsers` (or any other script name). In addition when running from a PowerShell window there is full intellisense code completion on all parameters and pre-defined values.

## Further Automation of Active Directory cleanup?
If you would like to completely automate the cleanup of your AD environment, then my suggestion would be to run these scripts regularly.

Once you have determined the parameters of how you would like to run each script, the easiest way to completely automate cleaning up and maintaining your AD environment would be to use Scheduled Tasks to automate the running of these scripts on your chosen frequency.

Enjoy your AD cleanup!
Luca