
# Where Is GTA Installed?
$installData = Get-ItemProperty "HKLM:\Software\Wow6432Node\Rockstar Games\Grand Theft Auto V" | Select-Object InstallFolder
$installLocation = $installData.InstallFolder

# If GTA is NOT installed
if($installLocation -eq $null){
	Write-Error "Could not locate GTA Installation, Please Install before running this script."
	exit
}
# Hey Nathan.
# Test for Drop Zone, create INE
if(Test-Path "$($installLocation)/dropZone"){
	$trackedModItems = (Get-ChildItem "$($installLocation)/dropZone")
}
else{
	New-Item -path "$($installLocation)/dropZone" -itemtype directory -force
}

# Match og files that will be replaced by mods.
$dict = @{}
$installedItems = (Get-ChildItem "$($installLocation)")
$installedItems | ForEach-Object -Proces {Write-Host $_}
$installedItems | % { $dict.Set_Item($_,1) }

[System.Collections.ArrayList]$modNamesMatchingOrigNames = New-Object System.Collections.ArrayList;
$scriptBlock = {
#$modNamesMatchingOrigNames
	$outter = $_
	$dict.Keys | % { if($_.Name -eq $outter){ $modNamesMatchingOrigNames.Add($_.Name)}}
}
$trackedModItems | % $scriptBlock

$preserveScriptBlock = {

	if(Test-Path "$($installLocation)/.ogv"){
		Write-Host "Backup Dir Exists"
	}
	else{
		New-Item -path "$($installLocation)/.ogv" -itemtype directory | %{$_.Attributes = "hidden"}
	}
	
	$path1 = "$($installLocation)/" + $_
	$path2 = "$($installLocation)/.ogv/" + $_
	
	Move-Item $path1 $path2
}

#Step 1, preserve all original files that are going to be replaced by mods
$modNamesMatchingOrigNames | % $preserveScriptBlock

#step 2, move modded files into the mix
$moveModsScriptBlock = {
	Move-Item "$($installLocation)/dropZone/$($_)" "$($installLocation)/$($_)"
}

Get-ChildItem "$($installLocation)/dropZone/" | % $moveModsScriptBlock

#step 3 play the game (block internet from modded game)
Set-ExecutionPolicy Unrestricted -Scope Process
New-NetFirewallRule -Program "$($installLocation)\GTA5.exe" -Action Block -Profile Public, Domain, Private -DisplayName "BlockGTA5TEMP" -Description "Block  GTA" -Direction Outbound
New-NetFirewallRule -Program "$($installLocation)\GTAVLauncher.exe" -Action Block -Profile Public, Domain, Private -DisplayName "BlockGTALauncherTEMP" -Description "Block  GTA" -Direction Outbound
New-NetFirewallRule -Program "C:\Program Files (x86)\Rockstar Games\Social Club\subprocess.exe" -Action Block -Profile Public, Domain, Private -DisplayName "BlockGTASCTEMP" -Description "Block  GTA" -Direction Outbound

$fp = "$($installLocation)\GTAVLauncher.exe"
Start-Process -FilePath $fp -Wait -Passthru

Remove-NetFirewallRule -DisplayName "BlockGTA5TEMP"
Remove-NetFirewallRule -DisplayName "BlockGTALauncherTEMP"
Remove-NetFirewallRule -DisplayName "BlockGTASCTEMP"

# step 4 Close game
# step 5
$unmoveModsScriptBlock = {
	Move-Item "$($installLocation)/$($_)" "$($installLocation)/dropZone/$($_)"
}
$trackedModItems | % $unmoveModsScriptBlock

# Step 6
$restoreScriptBlock = {
	Move-Item "$($installLocation)/.ogv/$($_)" "$($installLocation)/$($_)"
}
$modNamesMatchingOrigNames | % $restoreScriptBlock
Set-ExecutionPolicy RemoteSigned -Scope Process

exit
Set-ExecutionPolicy Unrestricted -Scope Process
New-NetFirewallRule -Program "$($installLocation)\GTA5.exe" -Action Block -Profile Public, Domain, Private -DisplayName "BlockGTA5TEMP" -Description "Block  GTA" -Direction Outbound
New-NetFirewallRule -Program "$($installLocation)\GTAVLauncher.exe" -Action Block -Profile Public, Domain, Private -DisplayName "BlockGTALauncherTEMP" -Description "Block  GTA" -Direction Outbound
New-NetFirewallRule -Program "C:\Program Files (x86)\Rockstar Games\Social Club\subprocess.exe" -Action Block -Profile Public, Domain, Private -DisplayName "BlockGTASCTEMP" -Description "Block  GTA" -Direction Outbound

Rename-Item $installLocation "$($installLocation)_Vanilla"
Rename-Item "$($installLocation)_Mod" $installLocation 

$fp = "$($installLocation)\GTAVLauncher.exe"
Start-Process -FilePath $fp -Wait -Passthru

Rename-Item $installLocation "$($installLocation)_Mod"
Rename-Item "$($installLocation)_Vanilla" $installLocation

Remove-NetFirewallRule -DisplayName "BlockGTA5TEMP"
Remove-NetFirewallRule -DisplayName "BlockGTALauncherTEMP"
Remove-NetFirewallRule -DisplayName "BlockGTASCTEMP"
Set-ExecutionPolicy RemoteSigned -Scope Process