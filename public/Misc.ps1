## Boot Times!
function Get-siLastBootTime {
	<#
    .SYNOPSIS
        Local machine last brought online

    .DESCRIPTION
        This function pulls the date when the local machine was last brought online. It really only runs the Get-siOSInfo function and returns the lastboot param.

    .EXAMPLE
        PS C:\> Get-siLastBootTime

    .INPUTS
        None
    #>
	(Get-siOSInfo).BootDate
}

function Get-siUptime {
	<#
    .SYNOPSIS
    Timespan that the computer has been running
    .DESCRIPTION
    This returns a timespan for how long the specified computer has been up and running. As a timespan, serveral formatting options are available (like (get-siuptime).TotalDays and (get-siuptime) -f {0})
    .EXAMPLE
    PS C:\> Get-siUptime
    .EXAMPLE
    PS C:\> (Get-siUptime).TotalDays
    .EXAMPLE
    PS C:\> (Get-siUptime).ToString()
    .OUTPUTS
    TimeSpan
#>
	New-TimeSpan -start (Get-siLastBootTime) -end $(get-date)
}

function Get-siBattery {
	<#
    .SYNOPSIS
        Battery info via WMI

    .DESCRIPTION
        This function pulls the following information from WMI:
            Computername
            Name
            Description
            BatteryStatus (in numeric form)
            BatteryStatusText (full text)
            BatteryStatusChar (2 char abrev)
            Health
            EstimatedChargeRemaining
            RunTimeMinutes (lots of minutes)
            RunTime (human readable)
            RunTimeSpan (easily translatable)

        Note: This function is used in the prompt

    .PARAMETER  ComputerName
        The name of the computer to query (localhost is default)

    .EXAMPLE
        PS C:\> Get-Battery

    .EXAMPLE
        PS C:\> Get-Battery -ComputerName MyVM

    .EXAMPLE
        PS C:\> Get-Battery MyVM

    .INPUTS
        System.String

    #>
	Param (
		[Parameter(Position = 0)]
		[string] $hostname = "localhost"
	)
	Get-CimInstance -Class win32_Battery -ComputerName $hostname | ForEach-Object {
		switch ($_.BatteryStatus) {
			1 { $textstat = "Discharging"; $charstat = "--"; break }
			2 { $textstat = "On AC"; $charstat = "AC"; break } #Actually AC
			3 { $textstat = "Charged"; $charstat = "=="; break }
			4 { $textstat = "Low"; $charstat = "__"; break }
			5 { $textstat = "Critical"; $charstat = "!!"; break }
			6 { $textstat = "Charging"; $charstat = "++"; break }
			7 { $textstat = "Charging/High"; $charstat = "++"; break }
			8 { $textstat = "Charging/Low"; $charstat = "+_"; break }
			9 { $textstat = "Charging/Critical"; $charstat = "+!"; break }
			10 { $textstat = "Undefined"; $charstat = "??"; break }
			11 { $textstat = "Partially Charged"; $charstat = "//"; break }
			Default { $textstat = "Unknown"; $charstat = "??"; break }
		}
		$ts = New-TimeSpan -Minutes $_.EstimatedRunTime
		$InfoHash = @{
			Computername             = $_.PSComputerName
			BatteryStatus            = $_.BatteryStatus
			BatteryStatusText        = $textstat
			BatteryStatusChar        = $charstat
			Name                     = $_.Name
			Description              = $_.Description
			EstimatedChargeRemaining = $_.EstimatedChargeRemaining
			RunTimeMinutes           = $_.EstimatedRunTime
			RunTime                  = '{0:00}h {1:00}m' -f $ts.Hours, $ts.Minutes
			RunTimeSpan              = $ts
			Health                   = $_.Status
		}

		$InfoStack = New-Object -TypeName PSObject -Property $InfoHash

		#Add a (hopefully) unique object type name
		$InfoStack.PSTypeNames.Insert(0, "CPU.Information")

		#Sets the "default properties" when outputting the variable... but really for setting the order
		$defaultProperties = @('Computername', 'Name', 'Description', 'BatteryStatus', 'BatteryStatusText', 'BatteryStatusChar', 'Health', 'EstimatedChargeRemaining', 'RunTimeMinutes', 'RunTime', 'RunTimeSpan')
		$defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet', [string[]]$defaultProperties)
		$PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
		$InfoStack | Add-Member MemberSet PSStandardMembers $PSStandardMembers

		$InfoStack
	}
}

function Get-siDomainControllers {
	<#
    .SYNOPSIS
        List domain controllers

    .DESCRIPTION
        This function polls the domain for the following info on AD Domain Controllers:
            Name
            Domain
            FQDN
            IPAddress
            OS
            Site
            Current Time (with variance due to script run time)
            Roles
            Partitions
            Forest Name
            IsGC

    .EXAMPLE
        PS C:\> Get-DomainControllers

    .EXAMPLE
        PS C:\> Get-DomainControllers | format-list *

    .INPUTS
        None

    #>
	[system.directoryservices.activedirectory.domain]::GetCurrentDomain().DomainControllers | ForEach-Object {
		$OSmod = [string] $_.OSVersion
		try {
			if ($OSmod.Length -gt 0) {
				$OSmod = $OSmod.Replace("Windows", "")
				$OSmod = $OSmod.Replace("Server", "")
			}
		} catch { }

		try {
			if ($_.CurrentTime -eq $null) {
				$CurrentTime = [datetime] "1/1/1901"
			} else {
				$CurrentTime = [datetime] $_.CurrentTime
			}
		} catch { $CurrentTime = [datetime] "1/1/1901" }

		try {
			[String] $IsGC = "No"
			if (($_).IsGlobalCatalog()) { $IsGC = "Yes" }
		} catch { $IsGC = "Unknown" }

		$InfoHash = @{
			Name        = $_.Name.ToString().Split(".")[0]
			Domain      = $_.Domain
			FQDN        = $_.Name
			IPAddress   = $_.IPAddress
			OS          = $OSmod.Trim()
			Site        = $_.SiteName
			CurrentTime = $CurrentTime
			Roles       = $_.Roles
			Partitions  = $_.Partitions
			Forest      = $_.Forest
			IsGC        = $IsGC
		}
		$InfoStack = New-Object -TypeName PSObject -Property $InfoHash

		#Add a (hopefully) unique object type name
		$InfoStack.PSTypeNames.Insert(0, "DomainController.Information")

		#Sets the "default properties" when outputting the variable... but really for setting the order
		$defaultProperties = @('Name', 'IPAddress', 'OS', 'Site')
		$defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet', [string[]]$defaultProperties)
		$PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
		$InfoStack | Add-Member MemberSet PSStandardMembers $PSStandardMembers

		$InfoStack
	}
}

function Get-siFunctionalLevels {
	<#
.SYNOPSIS
    Forest and domain functional levels

.DESCRIPTION
    Queries AD to get the the forest and domain functional levels

.EXAMPLE
    Get-FunctionalLevels

    Windows2008R2Domain
    Windows2003Forest

#>
	[system.directoryservices.activedirectory.domain]::GetCurrentDomain().DomainMode
	[system.directoryservices.activedirectory.forest]::GetCurrentForest().ForestMode
}

Function Get-siFSMORoleOwner {
	<#
.SYNOPSIS
    FSMO role owners

.DESCRIPTION
    Retrieves the list of FSMO role owners of a forest and domain

.NOTES
    Name: Get-FSMORoleOwner
    Author: Boe Prox
    DateCreated: 06/9/2011
    http://learn-powershell.net/2011/06/12/fsmo-roles-and-powershell/

.EXAMPLE
    Get-FSMORoleOwner

    DomainNamingMaster  : dc1.rivendell.com
    Domain              : rivendell.com
    RIDOwner            : dc1.rivendell.com
    Forest              : rivendell.com
    InfrastructureOwner : dc1.rivendell.com
    SchemaMaster        : dc1.rivendell.com
    PDCOwner            : dc1.rivendell.com

    Description
    -----------
    Retrieves the FSMO role owners each domain in a forest. Also lists the domain and forest.

#>
	[cmdletbinding()]
	Param()
	Try {
		$forest = [system.directoryservices.activedirectory.Forest]::GetCurrentForest()
		ForEach ($domain in $forest.domains) {
			$forestproperties = @{
				Forest             = $Forest.name
				Domain             = $domain.name
				SchemaRole         = $forest.SchemaRoleOwner
				NamingRole         = $forest.NamingRoleOwner
				RidRole            = $Domain.RidRoleOwner
				PdcRole            = $Domain.PdcRoleOwner
				InfrastructureRole = $Domain.InfrastructureRoleOwner
			}
			$newobject = New-Object PSObject -Property $forestproperties
			$newobject.PSTypeNames.Insert(0, "ForestRoles")
			$newobject
		}
	} Catch {
		Write-Warning "$($Error)"
	}
}

Function Get-siDaylightSavingsTime {
	<#
    .SYNOPSIS
        DST info

    .DESCRIPTION
        Have you ever wondered if you're in Standard or Daylight time? This function will tell you. It also tells you the start and stop dates.

    .EXAMPLE
        PS C:\> Get-DaylightSavingsTime

    .INPUTS
        None

    #>
	$TimeZone = Get-CimInstance -Class Win32_TimeZone
	[string] $Whatis = ""
	[bool] $DSTActive = $false

	[datetime] $DDate = TZ-Change $TimeZone.DaylightDay $TimeZone.DaylightDayOfWeek $TimeZone.DaylightMonth $TimeZone.DaylightHour
	[datetime] $SDate = TZ-Change $TimeZone.StandardDay $TimeZone.StandardDayOfWeek $TimeZone.StandardMonth $TimeZone.StandardHour

	$Today = Get-Date
	if (($Today -gt $DDate) -and ($Today -lt $SDate)) {
		$WhatIs = $TimeZone.DayLightName
		$DSTActive = $true
	} else {
		$WhatIs = $TimeZone.StandardName
		$DSTActive = $false
	}

	$InfoHash = @{
		TimeZone = $WhatIs
		Active   = $DSTActive
		Start    = $DDate
		End      = $SDate
	}

	$InfoStack = New-Object -TypeName PSObject -Property $InfoHash
	#Add a (hopefully) unique object type name
	$InfoStack.PSTypeNames.Insert(0, "NIC.Information")

	#Sets the "default properties" when outputting the variable... but really for setting the order
	$defaultProperties = @('Timezone', 'DSTActive')
	$defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet', [string[]]$defaultProperties)
	$PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
	$InfoStack | Add-Member MemberSet PSStandardMembers $PSStandardMembers
	$InfoStack
}

function Get-siLogon {
	<#
    .SYNOPSIS
        Current User, Domain, and LogonServer

    .DESCRIPTION
        Pulls basic logon information about the current user - including the domain controller responsible for authentication.

    .EXAMPLE
        PS C:\> Get-LogonUser

    .INPUTS
        None
    #>
	$InfoHash = @{
		UserName      = $env:USERNAME
		UserDomain    = $env:USERDOMAIN
		UserDNSDomain = $env:USERDNSDOMAIN
		LogonServer   = $env:LOGONSERVER.ToString().Replace("\", "")
	}

	$InfoStack = New-Object -TypeName PSObject -Property $InfoHash

	#Add a (hopefully) unique object type name
	$InfoStack.PSTypeNames.Insert(0, "LocalUser.Information")

	#Sets the "default properties" when outputting the variable... but really for setting the order
	$defaultProperties = @('UserName', 'UserDomain', 'LogonServer')
	$defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet', [string[]]$defaultProperties)
	$PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
	$InfoStack | Add-Member MemberSet PSStandardMembers $PSStandardMembers

	$InfoStack
}
