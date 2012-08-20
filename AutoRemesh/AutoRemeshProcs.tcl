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



