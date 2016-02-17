
########################################################################################################################
# Script Configuration Inputs
########################################################################################################################
param(
    [Parameter(Mandatory=$false)]
    [string]$v
)

# Verbose Flag
if ($v -eq "true"){
    $VerbosePreference = "Continue"
}
else{
    $VerbosePreference = "SilentlyContinue"
}



# Dot-Source the Functions
. "includes\\functions.ps1"





########################################################################################################################
# START SCRIPT
########################################################################################################################
# used for alerts
$wshell = New-Object -ComObject Wscript.Shell

#----------------------------------------------------------------------------
# Location of your installed Program
$installData                    = Get-ItemProperty "HKLM:\Software\Wow6432Node\Rockstar Games\Grand Theft Auto V" | Select-Object InstallFolder
$installLocation                = "$($installData.InstallFolder)\".Replace('\','/');

$insLen = $installLocation.Length;

#----------------------------------------------------------------------------
# If Program is Not Installed ERROR NOW
if($installLocation -eq $null){
    Write-Error "Could not locate GTA Installation, Please Install before running this script."
    exit
}

$socialClubInstallLocation      = "C:\Program Files (x86)\Rockstar Games\Social Club\".Replace('\','/');


#----------------------------------------------------------------------------
# Location of Drop Zone
$dropZonePath                   = "$($installLocation)dropZone\".Replace('\','/');
$dzLen                          = $dropZonePath.Length;
#----------------------------------------------------------------------------
# DMZ - demilitiarized zone for original files that are being replaced by modded files.
$currentDrive = $installLocation.Substring(0,2)
$tempLoc = "$($currentDrive)\DZTEMP".Replace('\','/');
$dmz = "$($tempLoc)\.ogv\".Replace('\','/');

Write-Verbose "Install Location: $($installLocation), Drop Zone Path: $($dropZonePath), DMZ: $dmz"

#----------------------------------------------------------------------------
# If the Local Temp and DMZ Directories aren't here, create them. These hold any
# vanilla files that are overwritten by incomming mod files.
( MkDirINE -path $tempLoc -attributes "hidden" )
( MkDirINE -path $dmz -attributes "hidden" )

#----------------------------------------------------------------------------
# Create a collection of file names (not folders) that match 
# file names in the vanilla installation.
[System.Collections.ArrayList]$moddedExistingFilenames      = New-Object System.Collections.ArrayList;

# Create a collection of tracked mod items (all files, not folders) 
# that are in the dropZone directory.
[System.Collections.ArrayList]$trackedModItems              = New-Object System.Collections.ArrayList;


# Used to Match Original Filenames files that will be replaced by mods.
[PSObject]$vanillaFilesTable                                = @{}



$hiddenFiles = "_migratelog.txt", "_vanillaFiles.manifest"



########################################################################################################################
# END DECLARATIONS
########################################################################################################################

# Test for Drop Zone, create Tracked Mod Items by scanning all files in the dropZone directory
# which should be in the installation location of the game in a folder titled '.dropZone' or 'dropZone'
if(-not(Test-Path "$($dropZonePath)")){
    $silent = New-Item -path "$($dropZonePath)" -itemtype directory -force
}
Get-ChildItem -recurse "$($dropZonePath)"| % {

    # ignore our hidden files.
    if(-not($hiddenFiles -contains $_.Name)){
        $itemToAdd = $_.FullName.Substring($dzLen).Replace('\','/')
        $silent = $trackedModItems.Add($itemToAdd)
    }
}

# build the vanilla file table
Get-ChildItem -recurse "$($installLocation)" | % {

    # ignore our hidden files.
    if(-not($hiddenFiles -contains $_.Name)){
	    $name = $_.FullName.Substring($insLen).Replace('\','/')
	    $vanillaFilesTable.Set_Item($name, $_) 
    }
}
#----------------------------------------------------------------------------
# recursive list of installed items in the Vanilla location, stored by name (minus the installation location)
if(-not(Test-Path "$($dropZonePath)_vanillaFiles.manifest")){
    
    # write keys to a manifest
    $vanillaFilesTable.Keys | Out-File "$($dropZonePath)_vanillaFiles.manifest" 
}
else{
    $arr = Get-Content "$($dropZonePath)_vanillaFiles.manifest"
    
    $currentSupposedVanillaState = @{}
    
    # graft this onto a currentSupposedVanillaState object since we're reading from the 
    # file. This will help to do a sanity pass
    # to see if the vanilla directory is really vanilla.
    $arr | % { $currentSupposedVanillaState.Set_Item($_,1) }
    
    # check the manifest (currentSupposedVanillaState) against the current state of 'vanilla' to insure there
    # has been no mucking around.
    $vanillaFilesTable.Keys | % {  
        if(-not($currentSupposedVanillaState.Keys -contains $_)){
            
            $result = $wshell.Popup("ERROR: $($_), Vanilla Folder is NOT Vanilla. Delete the _vanillaFiles.manifest from dropZone, and update your GTA V. Once comlete, re-run this tool to regenerate the file table",0,"Done",0x1)
            # 1== ok 2 == cancel
            
            throw " ERROR: $($_), Vanilla Folder is NOT Vanilla. Delete the _vanillaFiles.manifest from dropZone, and update your GTA V. Once comlete, re-run this tool to regenerate the file table" 
        } 
    }
    
    
}


#----------------------------------------------------------------------------
# Processes all 'tracked mod items' from the mods folder
$findOverwritesScriptBlock = {
    # save the current element in an 'outter' scope object ($trackedModFile)
    # so the inner script block can use its own version of 'current Element'
    # as well as this current element.
    $trackedModFile = $_
    
    $getOnlyModdedVanillaFiles = {
        $vanillaFile = $_
        
        if(($vanillaFile -eq $trackedModFile)){
            $silent = $moddedExistingFilenames.Add($vanillaFile)
        } 
    }
    
    $vanillaFilesTable.Keys | % $getOnlyModdedVanillaFiles 
}


# a whole bunch of files in the drop zone directory
# will be process by the above block, and any files matching a file in the current vanilla
# directory will be considered tracked mod items
$trackedModItems | % $findOverwritesScriptBlock



#----------------------------------------------------------------------------
Write-Verbose "Staring Migration"
#----------------------------------------------------------------------------
# Step 1, preserve all original files that are going to be replaced by mods
# Mod files that are added will not be in the preserve list. they can simply 
# be 'removed' when going back to vanilla version
Write-Host "Step 1: Preserving All Original GTA V Files that will be replaced by mods, and moving to DMZ"
(Migrate -files $moddedExistingFilenames -srcDir "$($installLocation)" -dstDir "$($dmz)")



#----------------------------------------------------------------------------
#step 2, Migrate modded files into the mix (including new ones, and modded replacements for files we just preserved)
Write-Host "Step 2: Moving all Modded Files from DropZone to Install Location $($installLocation)"
(Migrate -files $trackedModItems -srcDir "$($dropZonePath)" -dstDir "$($installLocation)");


Set-ExecutionPolicy Unrestricted -Scope Process


#----------------------------------------------------------------------------
#step 3 play the game (block internet from modded game)
(FirewallRule -forProgramLocation "$($installLocation)GTA5.exe" -ruleName "BlockGTA5TEMP")
(FirewallRule -forProgramLocation "$($installLocation)GTAVLauncher.exe" -ruleName "BlockGTALauncherTEMP")
(FirewallRule -forProgramLocation "$($socialClubInstallLocation)subprocess.exe" -ruleName "BlockGTASCTEMP")

$fp = "$($installLocation)GTAVLauncher.exe"
Start-Process -FilePath $fp -Wait -Passthru

#----------------------------------------------------------------------------
# step 4 Close game and clear firewall rules.
(NoFirewallRule -ruleName "BlockGTA5TEMP")
(NoFirewallRule -ruleName "BlockGTALauncherTEMP")
(NoFirewallRule -ruleName "BlockGTASCTEMP")

#----------------------------------------------------------------------------
# step 5
# once the game has shutdown, we need to move our tracked modded files all back to drop zone
Write-Host "Step 5: Moving all Tracked Modded Files from Install Location $($installLocation) back to Drop Zone $($dropZonePath)"
(Migrate -files $trackedModItems -srcDir "$($installLocation)" -dstDir "$($dropZonePath)");

#----------------------------------------------------------------------------
# Step 6
# move all vanilla files from dmz back into the installation location
Write-Host "Step 6: Moving all DMZ Vanilla Files from DMZ $($dmz) to Install Location $($installLocation)"
(Migrate -files $moddedExistingFilenames -srcDir "$($dmz)" -dstDir "$($installLocation)");

Set-ExecutionPolicy RemoteSigned -Scope Process

#----------------------------------------------------------------------------
# Step 7. Log the results
$migrateLog | Out-File "$($dropZonePath)/_migratelog.txt"


########################################################################################################################
# END OF SCRIPT
########################################################################################################################
exit