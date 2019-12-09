function Get-siServerRoleInfo {
	<#
	.SYNOPSIS
	Pulls system role information (what's this thing serving)

	.DESCRIPTION
	Servers (and workstations) can all serve various functions. Some are active directory servers,
	some host DHCP, some IIS... etc. This tries to enumerate the roles and parses "important" the
	more important (or, prolly more correctly, the more obvious ones).

	Naturally, Microsoft is always changing how this information is gathered. The newest way is
	valid on both servers and workstations, but requires Admin privs to enumerate. Really? I need
	admin privs just to get? Oy! Oh, and of course, they often use different discriptions for
	the same things ... cuz why wouldn't you.

	.EXAMPLE
	Get-siServerRoleInfo
	#>


	[CmdletBinding()]
	param ()

	try {
		Import-Module -Name ServerManager -Force -ErrorAction Stop -Verbose:$false
	} catch {
		Write-Verbose 'Could not import module ServerManager'
		Write-Verbose $_.Exception.Message
	}
	#Pull in all the installed "top level" roles
	if (get-module -Name ServerManager -ErrorAction SilentlyContinue) {
		try {
			$roles = Get-WindowsFeature -ErrorAction Stop -Verbose:$false | Where-Object { $_.Installed } | Where-Object { $_.Path -notmatch '\\' }
		} Catch {
			Write-Verbose 'Could not pull roles with Get-WindowsFeature'
			Write-Verbose $_.Exception.Message
		}
	}

	if ($null -eq $roles) {
		try {
			$stuff = @()
			Get-WindowsOptionalFeature -Online -ErrorAction Stop | Where-Object { $_.State -eq 'Enabled' } | foreach-object {
				$hash = @{
					DisplayName = $_.FeatureName
					Name        = $_.FeatureName
				}
				$stuff += $hash
			}
			if ($stuff.Count -gt 0) { $roles = $stuff; write-verbose "Found $($stuff.Count) Windows Optional Features" }
		} catch {
			Write-Verbose 'Could not pull Get-WindowsOptionalFeature'
			Write-Verbose $_.Exception.Message
		}
	}


	if ($roles) {
		#Create the array to hold the objects
		$all = @()

		#Parse through them for the ones we care about:
		$roles | ForEach-Object {
			if ( ($_.DisplayName -eq 'Active Directory Certificate Services') -or ($_.DisplayName -eq 'ADCertificateServicesRole ') ) {
				$SubItem = $null
				Try {
					#Let's see if we can pull the name of our Certificate Authority...
					$SubItem = (certutil.exe -CAInfo sanitizedname)
					$SubItem = (($SubItem -like "Sanitized*").Split(":")[1]).Trim()
				} Catch { $SubItem = $null }
				$Abbrev = "Cert/CA"
				$NickName = $Abbrev
				if ($SubItem.ToString().Length -gt 0) { $NickName = "$Abbrev ($SubItem)" }
				$all += New-Object -Type psobject -Property @{
					Role         = $_.DisplayName
					FeatureName  = $_.Name
					Abbreviation = $Abbrev
					SubItem      = $SubItem
					Qualified    = $NickName
				}
			}
			if ( ($_.DisplayName -eq 'Active Directory Domain Services') -or ($_.DisplayName -eq 'DirectoryServices-DomainController') ) {
				$SubItem = $null
				try {
					#Let's see if we can pull the domain name
					$SubItem = (get-addomain -Current LocalComputer).NetBIOSName
				} Catch { $SubItem = $null }
				$Abbrev = "DC"
				$NickName = $Abbrev
				if ($SubItem.ToString().Length -gt 0) { $NickName = "$Abbrev ($SubItem)" }
				$all += New-Object -Type psobject -Property @{
					Role         = $_.DisplayName
					FeatureName  = $_.Name
					Abbreviation = $Abbrev
					SubItem      = $SubItem
					Qualified    = $NickName
				}
			}
			if ( $_.DisplayName -eq 'Active Directory Federation Services') {
				$SubItem = $null
				Try {
					#Let's see if we tell if we're Federation or Proxy (or both)
					$IsFederation = (Get-WindowsFeature -Name ADFS-Federation -ErrorAction Stop -Verbose:$false).Installed
					$IsProxy = (Get-WindowsFeature -Name ADFS-Proxy -ErrorAction Stop -Verbose:$false).Installed
					$SubItem = ""
					if ($IsFederation) { $SubItem = "ADFS" }
					if ($IsProxy) {
						if ($SubItem.Length -gt 0) { $SubItem = $SubItem + " & " } else { $SubItem = "ADFS " }
						$SubItem = $SubItem + "Proxy"
					}
				} Catch { $SubItem = $null }
				$ADFSFound = $true
				$Abbrev = "ADFS"
				$NickName = $Abbrev
				if ($SubItem.ToString().Length -gt 0) { $NickName = $SubItem } else { $NickName = $Abbrev }
				$all += New-Object -Type psobject -Property @{
					Role         = $_.DisplayName
					FeatureName  = $_.Name
					Abbreviation = $Abbrev
					SubItem      = $SubItem
					Qualified    = $NickName
				}
			}
			if ( ($_.DisplayName -eq 'DHCP Server') -or ($_.DisplayName -eq 'DHCPServer') ) {
				$SubItem = $null
				$Abbrev = "DHCP"
				$NickName = $Abbrev
				$all += New-Object -Type psobject -Property @{
					Role         = $_.DisplayName
					FeatureName  = $_.Name
					Abbreviation = $Abbrev
					SubItem      = $SubItem
					Qualified    = $NickName
				}
			}
			if ( ($_.DisplayName -eq 'DNS Server') -or ($_.DisplayName -eq 'DNS-Server-Full-Role')) {
				$SubItem = $null
				try {
					#Let's see if we can pull the number of "real" domains this dns serves
					$SubItem = (Get-DnsServerZone -ErrorAction Stop -Verbose:$false | Where-Object { (-not $_.IsAutoCreated) -and ($_.IsDSIntegrated) }).Count
					$SubItem = "$SubItem zones"
				} Catch { $SubItem = $null }
				$Abbrev = "DNS"
				$NickName = $Abbrev
				if ($null -ne $SubItem) { $NickName = "$Abbrev ($SubItem)" }
				$all += New-Object -Type psobject -Property @{
					Role         = $_.DisplayName
					FeatureName  = $_.Name
					Abbreviation = $Abbrev
					SubItem      = $SubItem
					Qualified    = $NickName
				}
			}

			if ( ($_.DisplayName -eq 'Microsoft-Hyper-V') -or ($_.DisplayName -eq 'Hyper-V') ) {
				$SubItem = $null
				try {
					$SubItem = (hyper-v\get-vm -erroraction stop) | Where-Object { $_.State -eq 'Running' }
					$SubItem = "$($SubItem.Count) running VMs"
				} catch {
					write-verbose 'Errored counting VMs'
					Write-Verbose $_.Exception.Message
					$SubItem = $null
				}
				$Abbrev = "Hyper-V"
				$NickName = $Abbrev
				if ($SubItem.ToString().Length -gt 0) { $NickName = "$Abbrev ($SubItem)" }
				$all += New-Object -Type psobject -Property @{
					Role         = $_.DisplayName
					FeatureName  = $_.Name
					Abbreviation = $Abbrev
					SubItem      = $SubItem
					Qualified    = $NickName
				}
			}


			if ( ($_.DisplayName -eq 'Remote Desktop Services') -or ($_.DisplayName -eq 'Remote-Desktop-Services')) {
				$SubItem = $null
				$Abbrev = "RDP"
				$NickName = $Abbrev
				$all += New-Object -Type psobject -Property @{
					Role         = $_.DisplayName
					FeatureName  = $_.Name
					Abbreviation = $Abbrev
					SubItem      = $SubItem
					Qualified    = $NickName
				}
			}
			if ( ($_.DisplayName -eq 'Web Server (IIS)') -or ($_.DisplayName -eq 'IIS-WebServerRole')) {
				$SubItem = $null
				Try {
					#Let's see if we can count how many running sites we have...
					Import-Module WebAdministration -ErrorAction Stop -Verbose:$false
					$SubItem = (Get-ChildItem iis:\sites -ErrorAction Stop -Verbose:$false | Where-Object { $_.State -eq 'Started' }).Count
					$SubItem = "$SubItem sites"
				} Catch { $SubItem = $null }
				$Abbrev = "IIS"
				$NickName = $Abbrev
				if ($SubItem.ToString().Length -gt 0) { $NickName = "$Abbrev ($SubItem)" }
				$all += New-Object -Type psobject -Property @{
					Role         = $_.DisplayName
					FeatureName  = $_.Name
					Abbreviation = $Abbrev
					SubItem      = $SubItem
					Qualified    = $NickName
				}
			}

			if ( ($_.DisplayName -eq 'Microsoft-Windows-Subsystem-Linux')) {
				$SubItem = $null
				try {
					$SubItem = (wslconfig /l) | Where-Object { $_ -match '\w' }
					$SubItem = "$($SubItem.Count - 1) distros"
				} catch {
					write-verbose 'Errored counting Distros with WSLConfig'
					Write-Verbose $_.Exception.Message
					try {
						$SubItem = (wsl.exe /l) | Where-Object { $_ -match '\w' }
						$SubItem = "$($SubItem.Count - 1) distros"
					} catch {
						write-verbose 'Errored counting Distros with WSL'
						Write-Verbose $_.Exception.Message
					}
					$SubItem = $null
				}
				$Abbrev = "WSL"
				$NickName = $Abbrev
				if ($SubItem.ToString().Length -gt 0) { $NickName = "$Abbrev ($SubItem)" }
				$all += New-Object -Type psobject -Property @{
					Role         = $_.DisplayName
					FeatureName  = $_.Name
					Abbreviation = $Abbrev
					SubItem      = $SubItem
					Qualified    = $NickName
				}
			}

			if ( ($_.DisplayName -eq 'Windows Server Update Services') -or ($_.DisplayName -eq 'UpdateServices-Services')) {
				$SubItem = $null
				Try {
					#Let's see if we can pull the number of clients...
					[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | Out-Null
					$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($env:COMPUTERNAME, $false, 8530)
					$SubItem = $wsus.GetComputerTargetCount()
					$SubItem = "$SubItem clients"
				} Catch { $SubItem = $null }
				$Abbrev = "WSUS"
				$NickName = $Abbrev
				if ($SubItem.ToString().Length -gt 0) { $NickName = "$Abbrev ($SubItem)" }
				$all += New-Object -Type psobject -Property @{
					Role         = $_.DisplayName
					FeatureName  = $_.Name
					Abbreviation = $Abbrev
					SubItem      = $SubItem
					Qualified    = $NickName
				}
			}
			if ( $_.DisplayName -eq 'SMTP Server') {
				$SubItem = $null
				$Abbrev = "SMTP"
				$NickName = $Abbrev
				$all += New-Object -Type psobject -Property @{
					Role         = $_.DisplayName
					FeatureName  = $_.Name
					Abbreviation = $Abbrev
					SubItem      = $SubItem
					Qualified    = $NickName
				}
			}
			if ( ($_.DisplayName -eq 'Windows Internal Database') -or ($_.DisplayName -eq 'Windows-Internal-Database')) {
				$SubItem = $null
				$Abbrev = "WID"
				$NickName = $Abbrev
				$all += New-Object -Type psobject -Property @{
					Role         = $_.DisplayName
					FeatureName  = $_.Name
					Abbreviation = $Abbrev
					SubItem      = $SubItem
					Qualified    = $NickName
				}
			}
			if ( ($_.DisplayName -eq 'Failover Clustering') -or ($_.DisplayName -eq 'FailoverCluster-FullServer')) {
				$SubItem = $null
				Try {
					#Let's see if we can pull the name of the cluster
					Import-Module FailoverClusters -ErrorAction Stop -Verbose:$false
					$SubItem = (Get-Cluster -ErrorAction Stop).Name
				} Catch { $SubItem = $null }
				$Abbrev = "Cluster"
				$NickName = $Abbrev
				if ($SubItem.ToString().Length -gt 0) { $NickName = "$Abbrev ($SubItem)" }
				$all += New-Object -Type psobject -Property @{
					Role         = $_.DisplayName
					FeatureName  = $_.Name
					Abbreviation = $Abbrev
					SubItem      = $SubItem
					Qualified    = $NickName
				}
			}
			if ( $_.DisplayName -eq 'Containers') {
				$SubItem = $null
				$Abbrev = "Containers"
				$NickName = $Abbrev
				$all += New-Object -Type psobject -Property @{
					Role         = $_.DisplayName
					FeatureName  = $_.Name
					Abbreviation = $Abbrev
					SubItem      = $SubItem
					Qualified    = $NickName
				}
			}
		}

		if (-not $ADFSFound) {
			#Test For ADFS 2.0 (not show in the Roles/Features of 2008 R2 [native is 1.1])
			#We won't do this if we found ADFS in the roles...
			if (Get-PSSnapin -Registered -ErrorAction SilentlyContinue -Verbose:$false | Where-Object { $_.Name -match "Adfs" }) {
				#ADFS snappin is installed
				#Let's see if we tell if we're Federation or Proxy (or both)
				Try {
					Add-PSSnapin Microsoft.Adfs.PowerShell -ErrorAction Stop -Verbose:$false
					Try {
						$IsFederation = (Get-AdfsProperties -ErrorAction Stop).HostName
					} catch { $IsFederation = $false }
					Try {
						$IsProxy = (get-adfsproxyproperties -ErrorAction Stop).BaseHostName
					} catch { $IsProxy = $false }
					$SubItem = ""
					if ($IsFederation) { $SubItem = "ADFS (" + $IsFederation.Split(".")[0] + ")" }
					if ($IsProxy) {
						if ($SubItem.Length -gt 0) { $SubItem = $SubItem + " & " } else { $SubItem = "ADFS " }
						$SubItem = [String] ($SubItem + "Proxy (" + $IsProxy.Split(".")[0] + ")").Trim()
					}
					$Abbrev = "ADFS"
					if ($SubItem.ToString().Length -gt 0) { $NickName = $SubItem } else { $NickName = $Abbrev }
					$all += New-Object -Type psobject -Property @{
						Role         = "Active Directory Federation Services"
						FeatureName  = ""
						Abbreviation = $Abbrev
						SubItem      = $SubItem
						Qualified    = $NickName
					}
				} catch { }
			}
		}
		$all | ForEach-Object {
			$_.PSObject.TypeNames.Insert(0, 'brshSysInfo.ServerRoleInfo')
		}
		$all = $all | Sort-Object -Property Abbreviation
		$all | Select-Object Role, FeatureName, Abbreviation, SubItem, Qualified
	}

}
