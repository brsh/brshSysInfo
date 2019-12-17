function Get-siWIDDatabase {
	<#
	.SYNOPSIS
	Tries to pull DB info from WID

	.DESCRIPTION
	The Windows Internal Database... that is, SQL Express. This is a query
	listing the DBs and logs, as well as where they are located.

	.EXAMPLE
	Get-siWIDDatabase
	#>

	[CmdletBinding()]
	$Command = @"
SELECT
  db.name AS DBName,
  type_desc AS FileType,
  Physical_Name AS Location
FROM
  sys.master_files mf
INNER JOIN
  sys.databases db ON db.database_id = mf.database_id
"@

	## WID2012+
	[string] $ConnectionString = 'server=\\.\pipe\MICROSOFT##WID\tsql\query;database=master;trusted_connection=true;'

	if ((Get-CimInstance -ClassName win32_OperatingSystem).Caption -match 2008) {
		$ConnectionString = 'server=\\.\pipe\MSSQL$MICROSOFT##SSEE\sql\query;database=master;trusted_connection=true;'
	}

	try {
		$SQLConnection = New-Object System.Data.SQLClient.SQLConnection($ConnectionString)
		$SQLConnection.Open()
		$SQLCommand = $SQLConnection.CreateCommand()
		$SQLCommand.CommandText = $Command
		$SqlDataReader = $SQLCommand.ExecuteReader()
		$SQLDataResult = New-Object System.Data.DataTable
		$SQLDataResult.Load($SqlDataReader)
		$SQLConnection.Close()
		$SQLDataResult
	} catch {
		Write-Verbose 'Could not connect to WID'
		Write-Verbose $_.Exception.Message
	}
}
