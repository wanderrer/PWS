# Folders structure:
# [category1] - subfolder1, subfolder2, subfolder3 
# [category2] - subfolder1, subfolder2, subfolder3
#---------------------------------------------------------------------
# In each subfolders you have your YFT and YTD files
# If you don't follow this pattern, it will not work !


# Set Verbose preference
$VerbosePreference = 'Continue'

# Specify the path of the stream folder INSIDE your resource !!!
$Path = "C:\Users\DeViOuS\Desktop\vehicle\stream"

# Get all the subdirectories
$Subfolders = Get-ChildItem -Path $Path -Directory -Recurse

# Filter out the ones with brackets []
$CategoryFolders = $Subfolders | Where-Object { $_.Name -match "\[.*\]" }

# Create/Open the cars.lua file
$LuaFile = New-Item -Path "C:\Users\DeViOuS\Desktop\vehicle" -Name "cars.lua" -ItemType "file" -Force

# Create/Open the cars.sql file
$SQLFile = New-Item -Path "C:\Users\DeViOuS\Desktop\vehicle" -Name "cars.sql" -ItemType "file" -Force

# For each category, get the subdirectories
foreach($Category in $CategoryFolders){
    Write-Verbose "Processing category: $($Category.FullName)"
    $SubfoldersInCategory = Get-ChildItem -LiteralPath $Category.FullName -Directory

    if (!$SubfoldersInCategory){
        Write-Verbose "No subfolders found in category: $($Category.FullName)"
    }

    # For each subfolder, look for .yft files that don't contain "-" or "_"
    foreach($Subfolder in $SubfoldersInCategory){
        Write-Verbose "Processing subfolder: $($Subfolder.FullName)"
        $YFTFiles = Get-ChildItem -LiteralPath $Subfolder.FullName -File -Filter "*.yft" | 
                    Where-Object { $_.Name -notmatch "-" -and $_.Name -notmatch "_" }

        # If there are files, output to the cars.lua and cars.sql file
        if ($YFTFiles){
            foreach($File in $YFTFiles){
                Write-Verbose "Processing file: $($File.FullName)"
                $Name = $File.BaseName.Trim()
                $Brand = $Category.Name.Trim("[]")
                # Same price for all the cars :)
                #$Price = 13000 
                # If you want to generate random prices for the cars comment the $Price line and uncomment
                # the one above.. that's a "nice" work around :)
                # $Price = Get-Random -Minimum 25000 -Maximum 140001
                $CreatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

                # Check if the car's name already exists in the cars.lua and cars.sql files
                $LuaFileContent = Get-Content -Path $LuaFile.FullName
                $SqlFileContent = Get-Content -Path $SQLFile.FullName

                if (($LuaFileContent | Select-String -Pattern "['$Name']" -SimpleMatch) -or ($SqlFileContent | Select-String -Pattern "VALUES ('$Name'," -SimpleMatch)) {
                    Write-Verbose "Car $Name already exists, skipping..."
                    continue
                }

                # Write the output to the cars.lua file
                Add-Content -Path $LuaFile.FullName -Value @"
['$Name'] = {
    ['name'] = '$Name',
    ['brand'] = '$Brand',
    ['model'] = '$Name',
    ['price'] = $Price,
    ['category'] = 'compacts',
    ['categoryLabel'] = 'Compacts',
    ['hash'] = `'$Name'`,
    ['shop'] = 'pdm',
},
"@

                # Write the output to the cars.sql file
                Add-Content -Path $SQLFile.FullName -Value "INSERT INTO dealership_vehicles (spawn_code, brand, model, category, price, created_at) VALUES ('$Name', '$Brand', '$Name', 'Compacts', $Price, '$CreatedAt');"
            }
        } else {
            Write-Verbose "No matching .yft files in: $($Subfolder.FullName)"
        }
    }
}
