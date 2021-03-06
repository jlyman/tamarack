properties {
    $artifacts_directory   =   "$build_directory\$framework\"
    $working_directory     =   "$build_directory\$framework\build\"   
}

FormatTaskName (("~"*25) + "[{0}]" + ("~"*25))

task Default -depends Finish

Task Finish -depends Copy {
    
    # Delete working directory
    rd $working_directory  -rec -force | out-null
    
}

Task Copy -depends Test {    
    
    # Copy release files in release directory
    foreach($file in $release_files) {
        cp "$working_directory\$file" $artifacts_directory   
    }    
    
    Write-Host "Copied release files" -ForegroundColor Green
    
}

Task Test -depends Build {

    # Execute all tests. Build will fail if a test fails
    Write-Host "Starting tests" -ForegroundColor Green
    
    $testAssemblies = @(Get-ChildItem $working_directory -Recurse -Include *.Test*.dll )
    
    foreach($assembly in $testAssemblies) {                   
        
        Write-Host "Testing $assembly" -ForegroundColor Green
        exec{ & "$nunit_path" $assembly /framework="$framework" /nologo}
    }
    
    Write-Host "Finished tests" -ForegroundColor Green
}

Task Build -Depends Clean {	
	
    # Actual build. Target version is set by caller of this script
    Write-Host "Building $solution_path" -ForegroundColor Green
	
    Exec { msbuild "$solution_path" /t:Build /p:Configuration=Release /p:OutDir="$working_directory;ReferencePath=$base_directory\packages" /v:q  } 
    
    Write-Host "Build finished" -ForegroundColor Green
}

Task Clean {
	  
    # Creates necessary folders and cleans the solution    
    Write-Host "Creating BuildArtifacts directory" -ForegroundColor Green
    
	if (Test-Path $artifacts_directory) 
	{	
		rd $artifacts_directory -rec -force | out-null
	}
	
	mkdir $artifacts_directory | out-null
    mkdir $working_directory | out-null
	
	Write-Host "Cleaning $solution_path" -ForegroundColor Green
	Exec { msbuild "$solution_path" /t:Clean /p:Configuration=Release /v:q } 
}