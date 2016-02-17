# dropzone
A Game Modding Tool that manages a modding workspace and the default Installation by using a quick file mapping and moving technique.
Currently supports Grand Theft Auto V

#### Terms
 - Vanilla ( A Factory Install with no modification )
 - Open IV ( A Modding Tool )
 - Wrapper ( A program that serves the purpose of running another program )
 - Mod ( A Modification )
 - RPF ( Rage Package Files )
 - Root ( The top level of something, i.e. the 'Root' directory )
 
## Description
This is a `wrapper` program that performs some additional setup and tear-down steps around running a GTA V Session. 

## Requirements
Powershell 3.0 or Above
Windows 7 Professional or Above

## Usage

#### IMPORTANT!!!!
For the first run of this tool, it is recommended that you start with a completely vanilla version of your game. 

### First Run
The First run of DropZone.exe peforms a few preliminary actions:
 - create a workspace directory (called 'dropZone') within the Root of your game's installation directory
 - Scans the installtion directory state and writes a 'Vanilla files manifest'
 - creates the initial 'dropZone' directory in the Root of the Game's Installation Directory `(i.e. C:\Program Files\GTA V)`.
 - You will see an alert explaining that you should move your mods. The location will be in the alert.
This is where you will place all of your mods. Consider this directory to be treated like a 'mirror' of the Games installation directory. You can place mods here that will replace files in the Vanilla install, or new files/directories. Files include RPF files, DLLs Lua, sounds, or really anything the game supports from a media format perspective.

### Subequent Runs
For every subsequent run, the Vanilla Game directory is scanned and verified against the manifest file that was created upon first run. If all goes well, an Offline Mod Session is started, using the contents of the dropZone directory as the src for your games runtime. 

If any files are missing, an Alert is shown asking you to update your game using the games patcher. Clicking OK will automatically run the patcher as is, with no Blocking of the internet. At this point, you should insure your dropzone directory contains all of your files prior to running this tool. If you update the game, it will overwrite any files currently residing in the root diretcory of the installation of your game.


## Step 1.
Install GTA (Or Run your Vanilla installed version and let it update to the latest and greatest from RockStar Games)

## Step 2.
Run playGta.exe from the location where you saved Dropzone. This will create the 'dropZone' directory under the installation
of GTA V (if it is found). If GTA V is not installed, the process will quit.

## Step 3. Close the game!
After the first run of the tool, the directories and vanilla file manifest will be written. Dropzone will use this manifest to insure
that the game is in the 'Vanilla' state prior to making any migrations from the dropZone mods directory.

### Step 4. Automagical Cleanup. 
After the game process has shutdown, DropZone will clean up your Game Directory, and restore all the mods back to dropZone, and restore the vanilla files that were replaced by mods back to the root of the installation of GTA V. Thus the game should appear as if no changes were ever made, and your mods will be safely contained in drop zone.

# Benefits
You can run this tool from any location and it will recognize your Game Directory and create the necessary folders inside it. 
You can add new/remove modded files anytime and dropzone will know what to do with them. 
You can now play your Modded version of GTA V, and dropZone will always leave your game in a vanilla state so you don't get tagged, it force offline play.
dropZone can be edited to work for other games too!
