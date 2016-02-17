# dropzone
GTA V Tool to Mod

#### Terms
 - Vanilla ( A Factory Install with no modification )
 - Open IV ( A Modding Tool )
 - Wrapper ( A program that serves the purpose of running another program )
 - Mod ( A Modification )
 - RPF ( Rage Package Files )
 - Root ( The top level of something, i.e. the 'Root' directory )
 
## Description
This is a `wrapper` program that performs some additional setup and tear-down steps around running a GTA V Session. 

### How it works
#### IMPORTANT FIRST STEP!!!!
The First run of DropZone creates a workspace directory (called 'dropZone') within the Root of your games installation directory, Scans the installtion, 
writes a 'Vanilla files manifest' and exits. **This is the crucial setup step!!!**

#### After The Important first step has completed...
You will see an alert explaining that you should move your mods. The location will be in the alert.
This is where you will place all of your mods. Consider this directory to be treated like a 'mirror' of the Games installation directory.
You can place mods here that will replace files in the Vanilla install, or new files/directories. Files include RPF files, DLLs Lua, sounds, 
or really anything the game supports from a media format perspective.

Much like 'Open-IV' works with a 'mods' folder this tool will is designed to be run from a vanilla installation,
with a child directory containing your mod workspace, known as 'dropZone'

Again, all files in dropZone mirror the 'root' of your games installation location `(i.e. C:\Program Files\GTA V)`

#### Run again (and again...)
For Subsequent runs, the Vanilla Game directory is scanned and verified against the manifest file that was created upon first run.

## Usage
For the first run of this tool, it is recommended that you start with a completely vanilla version of your game. 

### Step 1.
Install GTA (Or Run your Vanilla installed version and let it update to the latest and greatest from RockStar Games)

### Step 2.
Run playGta.exe from the location where you saved Dropzone. This will create the 'dropZone' directory under the installation
of GTA V (if it is found). If GTA V is not installed, the process will quit.

#### Close the game!
After the first run of the tool, the directories and vanilla file manifest will be written. Dropzone will use this manifest to insure
that the game is in the 'Vanilla' state prior to making any migrations from the dropZone mods directory.

### Step 3. 
After the game process has shutdown, DropZone will clean up your Game Directory, and restore all the mods back to dropZone, and restore the vanilla
files that were replaced by mods back to the root of the installation of GTA V. Thus the game should appear as if no changes were ever
made, and your mods will be safely contained in drop zone.

## Benefits
You can now play your Modded version of GTA V, and roll back to playing the Vanilla version (Online, with friends, etc) simply by clicking an icon.
