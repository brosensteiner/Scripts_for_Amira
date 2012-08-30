# proc which iterates over all surfaces in the pool and remeshes theMain 
# results of remeshing are going to be saved in global theRemeshedSurfacesList
$this proc remeshAllSurfacesPlease { surfacelist } {

	global theSurfaceRemesher theRemeshedSurfacesList
	upvar $surfacelist surfacelistUpvar
	
	say "try to remesh [llength $surfacelistUpvar] surface(s):"
	echo $surfacelistUpvar
	
	set counter 1
	foreach item $surfacelistUpvar {
		
		say "remeshing $counter of [llength $surfacelistUpvar] surface(s) ($item)"
		createModuleAndConnectIfOkToSource HxRemeshSurface $theSurfaceRemesher $item;
		
		$theSurfaceRemesher remesh setValue 0
		$theSurfaceRemesher fire;#this will take much computation time ...
		set theResult [$theSurfaceRemesher getResult]
		$theResult master disconnect 
		#adding info in parameter list:
		stampField $theResult ModuleInfo [$this getVar theAuthor] [$this getVar moduleName]
		lappend theRemeshedSurfacesList $theResult
		incr counter
	}
}

$this proc settingStandardParameter {} {
	$this triangleArea setValues 5 3 3
	$this lloydRelaxation setValues 40
	$this desiredSize setValues 0 0 100
	$this errorThresholds setValues 0 0
	$this densityContrast setValues 0
	#$this densityRange setValues 8.58993e+09 8.58993e+09
	$this interpolateOrigSurface setValue 1
	$this remeshOptions1 setValue 0 0
	$this remeshOptions1 setValue 1 1
	$this remeshOptions2 setValue 0
	$this surfacePathOptions setValue 1 1
}

$this proc updateModuleState {} {
	
	global theSurfaceRemesher theRemeshedSurfacesList allSurfacesInPoolList
	
	#make all empty:
	set theRemeshedSurfacesList [list]
	set allSurfacesInPoolList [list]
	
	#updates global list(s):
	set tempList [list]
	foreach item $theRemeshedSurfacesList {
		if { [lsearch -exact [all] $item] != -1 } { lappend tempList $item }
	}
	set theRemeshedSurfacesList $tempList
	
	# make shure that not results from remeshing are in the allSurfacesInPoolList
	# (.surf and .remesh are the same Hx C++ class)
	set tempList [all HxSurface]
	foreach item $tempList {
		if { [string match *.remeshed $item] == 0 } { lappend allSurfacesInPoolList $item }
	}
	
}

$this proc savingRoutine { thePath theList } {
	
	if { [file isdirectory $thePath] } {
		
		set fileType	[$this filetype getOptLabel 0 [$this filetype getOptValue 0]]
		set fileName	[regsub {(.*?)\s\(.+?\)} $fileType {\1}]
		set fileEnding	[regsub {.*?\s\((.+?)\)} $fileType {\1}]
		
		foreach result $theList {
			
			switch -exact [$result getTypeId] {
				#HxUniformScalarField3 { $result save "Amiramesh ascii" $userSaveState/$result }
				HxSurface { $result save $fileName $thePath/$result$fileEnding }
			}
		}
		
	} else {
		theMsg warning "whatever you typed in the \"[$this saveResults getLabel]\" port ... , it is not a valid directory name, so nothing has been saved!"
	}
}


$this proc convertNow { } {

	#making shure userSaveState is set (gets the first time set when compute proc runs)
	set userSaveState [$this saveResults getState]
	if { $userSaveState eq "" } {
		theMsg warning "you have not specified a location for saving"
	} else {
	
		if { [theMsg question "[llength [all HxSurface]] surface(s) in the Pool will be converted to \n[$this filetype getOptLabel 0 [$this filetype getOptValue 0]]\nand saved in  the location:\n$userSaveState" "Ok" "Stop"] == 0 } {
			$this savingRoutine $userSaveState [all HxSurface]
		}	
	}
}




