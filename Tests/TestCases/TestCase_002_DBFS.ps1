# Set-DatabricksEnvironment is already done by the caller!
# Current Directory is set by Test-Module.ps1 to the root of this repository!
$testCaseName = $myInvocation.MyCommand.Name
Write-Information "Starting Testcase $testCaseName ..."

# if executed from PowerShell ISE
if (-not $PSCommandPath) { 
	$rootPath = Switch ($Host.name) {
		'Visual Studio Code Host' { Split-Path $psEditor.GetEditorContext().CurrentFile.Path }
		'Windows PowerShell ISE Host' { Split-Path -Path $psISE.CurrentFile.FullPath }
		'ConsoleHost' { $PSScriptRoot }
	}
	$rootPath = $rootPath | Split-Path -Parent | Split-Path -Parent
}
else {
	# when executed as script (not via UI/ISE), the location was already set
	$rootPath = Get-Location
}

Write-Information "Testing DBFS API ..."
$fileName = "myFile.txt"
$localFilePath = "$rootPath\Tests\Content\DBFS\$script:testDBFSFolder\$fileName"
$dbfsPath = "$script:testDBFSFolder$fileName"
$localTempFolder = "$rootPath\Tests\Content\DBFS\_TEMP"
try {
	Upload-DatabricksFSFile -Path $dbfsPath -LocalPath $localFilePath -Overwrite $true -BatchSize 10
	
	New-Item -Path $localTempFolder -ItemType "directory" -Force
	Download-DatabricksFSFile -Path $dbfsPath -LocalPath "$localTempFolder\$fileName" -Overwrite $true -BatchSize 10

	$origFile = Get-Content $localFilePath
	$downloadedFile = Get-Content "$localTempFolder\$fileName"

	if (Compare-Object $origFile $downloadedFile) {
		Write-Warning "Expected Content:"
		Write-Warning $origFile
		Write-Warning "Actual Content:"
		Write-Warning $downloadedFile
		Write-Error "DBFS upload and download did not match!"
	}

	Write-Information "S U C C E S S  -  Testcase '$testCaseName' finished successfully!"
}
catch {
	throw $_
}
finally {
	Write-Information "Starting Cleanup for testcase '$testCaseName' ..."
	Remove-Item -Path $localTempFolder -Recurse -Force -ErrorAction SilentlyContinue
	Remove-DatabricksFSItem $dbfsPath -ErrorAction SilentlyContinue
	Write-Information "Finished Cleanup for testcase '$testCaseName'!"
}



