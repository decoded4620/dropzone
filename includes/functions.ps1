if($global:utilities_ps1_included -ne $true)
{

[System.Collections.ArrayList]$transactionQueue = New-Object System.Collections.ArrayList
function StartTransaction{
    $transactionQueue = New-Object System.Collections.ArrayList
}
function NewMoveAction{

    param(
        [Parameter(Mandatory=$true)]
        $src,
        [Parameter(Mandatory=$true)]
        $dst
    )
    $MoveAction = New-Object psobject;
    $MoveAction | Add-Member NoteProperty Src $src;
    $MoveAction | Add-Member NoteProperty Dst $dst;
}

function CommitMoveAction{

    param(
        [Parameter(Mandatory=$true)]
        [PSObject]$MoveAction
    )
    

    if($MoveAction -ne $null){
        # push to the front
        $transactionQueue.Insert(0, $MoveAction);
    }
}
function RollBack{

    [System.Collections.ArrayList]$testForEmpty = New-Object System.Collections.ArrayList
    $transactionQueue | % {
        #un move
        #migrate the files one by one back to their previous locations
        
        $MoveAction = $_
        
        if(Test-Path $MoveAction.Dst -pathType container){
            $testForEmpty.add($MoveAction.Dst);
        }
        #un move the file or directory
        (MigrateFile -src $MoveAction.Dst -dst $MoveAction.Src)
    }
    
    # clean up after ourselves.
    (CleanEmptyDirectories -FlatList $testForEmpty)
}
########################################################################################################################
# Make a directory if it doesn't already exist
########################################################################################################################
function MkDirINE{
    param(
        [Parameter(Mandatory=$true)]
        $path,
        [Parameter(Mandatory=$true)]
        $attributes
    )
    
    Write-Host "MakeDirINE - $($path) , $($attributes)"
    if(Test-Path "$($path)"){
        Write-Verbose "File: $($path) Exists"
    }
    else{
        Write-Verbose "Creating Directory $($path)";
        $silent = New-Item -path "$($path)" -itemtype directory | % {$_.Attributes = $attributes }
    }
}



########################################################################################################################
# Build a temp firewall rule for a single program
########################################################################################################################
function FirewallRule{
    param(
        [Parameter(Mandatory=$true)]
        [string]$forProgramLocation,
        [Parameter(Mandatory=$true)]
        [string]$ruleName
    )
    # insure format is backslash
    $forProgramLocation = $forProgramLocation.Replace('/','\');
    $silent = (New-NetFirewallRule -Program "$($forProgramLocation)" -Action Block -Profile Public, Domain, Private -DisplayName "$($ruleName)" -Description "Blocking Outbound Communication Temporarily" -Direction Outbound)
}



########################################################################################################################
# Remove a Firewall Rule by its Name
########################################################################################################################
function NoFirewallRule{
    param(
        [Parameter(Mandatory=$true)]
        [string]$ruleName
    )
    
    $silent = (Remove-NetFirewallRule -DisplayName $ruleName)
}


########################################################################################################################
# Function that Cleans up empty folders once migration is complete.
########################################################################################################################

function CleanEmptyDirectories{
    param(
        [Parameter(Mandatory=$false)]
        [System.Collections.ArrayList]$FlatList,
        [Parameter(Mandatory=$false)]
        [System.Collections.ArrayList]$RootDir
    )
    
    if($FlatList -ne $null -and $FlatList.Count -gt 0){
	    $atLeastOneRemoved = $false;
	    Write-Verbose "Testing $($testForEmpty.Count) Folders for deletion"
	    
	    $cleanEmptyDirectories = {
	    
	        if(Test-Path $_){
	            # check current item for children
	            # if none, we're good.
	            $children = Get-ChildItem -Path $_
	            
	            if($children.Count -eq 0){
	                $atLeastOneRemoved = $true;
	                $silent = Remove-Item -path "$($_)"
	                $migrateLog = $migrateLog + ("removing empty dir $($_)")
	                Write-Host "    - removing empty dir $($_)"
	            }
	        }
	    }
	    
	    # may require a few repeats since we're going 'leaves' first
	    # this will repeat once for each 'level' in the tree, starting with the deepest leaves
	    # up to the roots of the topmost empty diredctories
	    do{
	        Write-Host "  cleaning empty directories..."
	        $atLeastOneRemoved = $false
	        $FlatList | % $cleanEmptyDirectories
	        Write-Host "        At least one removed? $($atLeastOneRemoved)"
	    }while($atLeastOneRemoved -eq $true)
    }
}


########################################################################################################################
# Function that migrates a single file
########################################################################################################################
function MigrateFile{
    param(
        [Parameter(Mandatory=$true)]
        [string]$src,
        [Parameter(Mandatory=$true)]
        [string]$dst,
        [Parameter(Mandatory=$false)]
        [bool]$overwrite
    )
    
    $originFile = $src
    $destFile = $dst
    
    # existence test, originFile is important. we can't migrate
    # without it. If it is missing we throw an error 
    $originFileExists = Test-Path $originFile
    
    if(-not($originFileExists)){
        throw "Error, Origin file $($originFile) doesn't exist!"
    }
    
    $originFileIsDir = ($originFileExists -and (Test-Path $originFile -pathType container))
    
    # existence test destination
    # we only care to check overwrite conditions if the destination file is not a directory.
    # otherwise, we'll be mirroring it anyway
    $destFileExists = (Test-Path $destFile)
    
    $migrateLog = $migrateLog + ("Migrating $($originFile) to $($destFile)  (origin is directory: $($originFileIsDir) )`r`n") 
    
    # if current item is directory, mirror it on the other
    # side. This is an item that we'll check later after
    # migration for empty
    if($originFileIsDir){

        if(-not($destFileExists)){
            $migrateLog = $migrateLog + ("    Mirroring $($originFile) to $($destFile)`r`n")
            # since files are being moved FROM this dir,
            # we'll want to test it for empty later.
            $silent = $testForEmpty.Add($originFile);
            
            # mirror
            $silent = New-Item -path $destFile -type directory
            Write-Verbose "        - MkDir $($destFile)"
        }
        else{
            Write-Verbose "Directory Exists: $($destFile)"
        }
    }
    # current file is not a directory, but a leaf file. Move it on over.
    else{

       $migrateLog  = $migrateLog + ("    Moving $($originFile) to $($destFile)`r`n")
       
       # only move non-existing leaf items we dont' want to be destructive
       # unless the overwrite flag is explicitly stated.
       if(-not($destFileExists) -or ($overwrite -eq $true)){
           # just move
           $silent = Move-Item $originFile $destFile
           Write-Verbose "        - Move $($originFile) --> $($destFile)"
       }
       else{
            throw "Cannot migrate $($src), failed to overwrite existing destination item: $($dst)"
       }
    }
}


########################################################################################################################
# Function that migrates files (leaf by leaf) from their current directory ($srcDir) to a new destination ($dstDir)
# Cleans up empty folders once migration is complete.
########################################################################################################################

function Migrate{

    param(
        [Parameter(Mandatory=$true)]
        [System.Collections.ArrayList]$files,
        [Parameter(Mandatory=$true)]
        [string]$srcDir,
        [Parameter(Mandatory=$true)]
        [string]$dstDir,
        [Parameter(Mandatory=$false)]
        [bool]$overwrite
    )
    
    # used to collect empty directories after migration
    [System.Collections.ArrayList] $testForEmpty      = New-Object System.Collections.ArrayList
    
    $rootOriginExists         = Test-Path "$($srcDir)"
    $rootDestExists           = Test-Path "$($dstDir)"
    $srcDirIsDirectory          = ($rootOriginExists -and (Test-Path "$($srcDir)" -pathType container))
    
    Write-Verbose "** Migrating $($files.Count) file(s) $($srcDir) (exists: $($rootOriginExists) ) ==>  $($dstDir) ( exists: $($rootDestExists) )"
    # insure that we're not overwriting antoher file
    if((-not($rootDestExists) -and $rootOriginExists) -or $srcDirIsDirectory){
    }
    else{
        throw "Item $($srcDir)$($_) not migrated!"
    }
    
    
    $migrateLog = "";
    
    $migrateFile = {
        
        # current file to be migrated
        $originFile = "$($srcDir)$($_)";
        
        # destination for this file
        $destFile = "$($dstDir)$($_)"
        
        (MigrateFile -src $originFile -dst $destFile -overwrite $overwrite)
    }

    $files | % $migrateFile
    
    # clean up the list of directories we collected during migration (from the src location)
    (CleanEmptyDirectories -FlatList $testForEmpty)
    
    
    Write-Verbose "Migration from $($srcDir) to $($dstDir) completed"
}

$global:utilities_ps1_included = $true
}