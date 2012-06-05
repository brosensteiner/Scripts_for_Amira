$this proc sayHello {} {
	global moduleName
	echo "\n************ module \"$moduleName\" loaded successfully :) ************\n"
}
$this proc say { something } {
	global moduleName
	echo "$moduleName: $something"
}
# procedure which can add new parameters to a amira field. 1.arg: the field, 2.arg: a new Bundle, args: pairs of parameter/values (e.g. Color { 1 0 1 })
$this proc stampField { field theBundle args } {

	$field parameters newBundle $theBundle
	foreach { par val } $args {
		eval "$field parameters $theBundle setValue $par $val"
	}

}
# clear items in a specified Bundle in a amira field (saves some typing):
$this proc clearBundle { field args } {

	if { [llength $args] > 1 } {
		set lastElement [lindex $args end]
		set restElements [lrange $args 0 end-1]
	} else {# when only one bundle in args (e.g. Materials)
		set lastElement $args
		set restElements ""
	}
	
	foreach item [eval "$field $restElements parameters $lastElement list"] {
		eval "$field $restElements parameters $lastElement $item setFlag NO_DELETE 0"
		eval "$field $restElements parameters $lastElement remove $item"
	}
	
}

# simple port test: procedure returns 1 when module has port, otherwise it returns 0
$this proc hasPort {modul port} {
	upvar #1 $modul myModule
	if { [lsearch [$myModule allPorts] $port] != -1 } { return 1 } else { return 0 }
}

#simple proc for switching between positiv and negative numbers:
$this proc switchNumberSigns { args } {
	set list [list]
	foreach i $args { lappend list [expr -$i] }
	return $list
}

#proc which translates a point in 3D space. argument point has to be in cartesian coordinates
$this proc translateTo { point pointToTranslateTo } {

	set point [split $point " "]
	set pointToTranslateTo [split $pointToTranslateTo " "]

	set transformList [list]
	for { set i 0 } { $i < [llength $point]  } { incr i } {
		lappend transformList [expr [lindex $point $i] - [lindex $pointToTranslateTo $i]]
		echo "die rechunung: [expr [lindex $point $i] - [lindex $pointToTranslateTo $i]]"
	}
	return $transformList
}

# procs which rotates a given object(s) on a given axis (axis == world origin to evecPointAxis) \
  
$this proc rotateAll { theObjectList evecPointAxis { degrees 180 } } {

	upvar $theObjectList upvList $evecPointAxis upvevecPointAxis
	foreach item $upvList {
		eval "$item rotate $upvevecPointAxis $degrees"
	}
}
$this proc rotateObject { object evecPointAxis { degrees 180 } } {

	upvar $object upvObject $evecPointAxis upvevecPointAxis
	eval "$upvObject rotate $upvevecPointAxis $degrees"
}

# procedure for extracting a bunch of values from an amira spreadsheet object generated from the ShapeAnalysis modul. :\
  return value is an array which holds the values ("array set varName spreadExtractArray arg" catches the array returned \
  by extractFromSpreadsheet again in an array). This proc works only in conjunctions with the ShapeAnalysis module \
  because the generated spreadsheet from this module has a particular order of the labels (i.e. bundle index)!
$this proc extractFromSpreadsheet { spreadObj } {
	
	array set spreadExtractArray {}
	#put volume in array:
	for { set i 0 } { $i < [$spreadObj getNumRows]  } { incr i } {
		set spreadExtractArray([$spreadObj getValue 0 $i],v) [list [$spreadObj getValue 1 $i]]
	}
	#put mass in array:
	for { set i 0 } { $i < [$spreadObj getNumRows]  } { incr i } {
		set spreadExtractArray([$spreadObj getValue 0 $i],m) [list [$spreadObj getValue 32 $i]]
	}
	#put area in array:
	for { set i 0 } { $i < [$spreadObj getNumRows]  } { incr i } {
		set spreadExtractArray([$spreadObj getValue 0 $i],a) [list [$spreadObj getValue 33 $i]]
	}
	#put center point x, y, z in array:
	for { set i 0 } { $i < [$spreadObj getNumRows]  } { incr i } {
		set spreadExtractArray([$spreadObj getValue 0 $i],c) [list	[$spreadObj getValue 2 $i]\
																	[$spreadObj getValue 3 $i]\
																	[$spreadObj getValue 4 $i]\
																	]
	}
	#put eigenvalues x, y, z in array:
	for { set i 0 } { $i < [$spreadObj getNumRows]  } { incr i } {
		set spreadExtractArray([$spreadObj getValue 0 $i],evalue) [list	[$spreadObj getValue 8 $i]\
																		[$spreadObj getValue 9 $i]\
																		[$spreadObj getValue 10 $i]\
																		]
	}
	#put eigenvector 1x, 1y, 1z in array:
	for { set i 0 } { $i < [$spreadObj getNumRows]  } { incr i } {
		set spreadExtractArray([$spreadObj getValue 0 $i],evector1) [list	[$spreadObj getValue 11 $i]\
																			[$spreadObj getValue 12 $i]\
																			[$spreadObj getValue 13 $i]\
																			]
	}
	#put eigenvector 2x, 2y, 2z in array:
	for { set i 0 } { $i < [$spreadObj getNumRows]  } { incr i } {
		set spreadExtractArray([$spreadObj getValue 0 $i],evector2) [list	[$spreadObj getValue 14 $i]\
																			[$spreadObj getValue 15 $i]\
																			[$spreadObj getValue 16 $i]\
																			]
	}
	#put eigenvector 3x, 3y, 3z in array:
	for { set i 0 } { $i < [$spreadObj getNumRows]  } { incr i } {
		set spreadExtractArray([$spreadObj getValue 0 $i],evector3) [list	[$spreadObj getValue 17 $i]\
																			[$spreadObj getValue 18 $i]\
																			[$spreadObj getValue 19 $i]\
																			]
	}
	#put moments of inertia ixx, Iyy, Izz in array:
	for { set i 0 } { $i < [$spreadObj getNumRows]  } { incr i } {
		set spreadExtractArray([$spreadObj getValue 0 $i],moinertia) [list	[$spreadObj getValue 28 $i]\
																			[$spreadObj getValue 29 $i]\
																			[$spreadObj getValue 30 $i]\
																			]
	}
	return [array get spreadExtractArray]
}

# proc for finding some shape parameters of labels in a given labelfield and return of an array which holds the shape parameters\
  (e.g. eigenvalues, eigenvectors, mass -> see procedure "extractFromSpreadsheet")\
  this proc uses the ShapeAnalysis module to obtain the shape parameters. If the mass (voxel grey values) should be included in the shape parameter calculation the optional value "massCalc" must be 1
$this proc makeShapeAnalysis { labelfield { shapeAnalysisModul "defaultShapeAnalysisModule" } { massCalc 0 } } {
	
	# the shape analysis:
	$this createModuleAndConnectIfOkToSource HxShapeAnalysis $shapeAnalysisModul $labelfield;#$shapeAnalysisModul is global!!! so it has to be deleted in the destructor proc, otherwise it remains in the pool (it´s global because then it has not every time be generated anew for every call of "makeShapeAnalysis" and stays in the pool)
	if { $massCalc } then { $shapeAnalysisModul Field connect [$labelfield getControllingData] }
	$shapeAnalysisModul action setValue 0
	$shapeAnalysisModul fire
	
	set theResultFromShapeAnalysis [$shapeAnalysisModul getResult]
	array set extrValFromSprdsht [$this extractFromSpreadsheet $theResultFromShapeAnalysis]
	$theResultFromShapeAnalysis master disconnect 
	remove $theResultFromShapeAnalysis
	return [array get extrValFromSprdsht]
	
}

# proc for cropping the extracted voxel fields (will be executed everytime the "Auto Crop" button in the "Resample options1" port is pressed). \
  this proc is really slow because of the "brutal force" approach of the algorithm (for about 160 x 160 x 160 voxel fields to crop to about 60 x 60 x 60 it takes about 1:20 minutes on intel core 2 duo 2.8Ghz)!!! \
  some optimization brings the algorithm nevertheless down from 3 minutes to 58 seconds: after every for loop the range in which the nodes of the voxel field are evaluated is newly adjusted, \
  so that no unnecessary iteratons have to be made \
  i think this slowness is the Tcl "scripting tradeoff" - much faster is the "C++ Auto Crop" from Amira´s crop editor
$this proc autoCrop { item { treshhold 0.000000 } } {

	upvar $item upvItem
	
	set cropPoints [list 0 [lindex [$upvItem getDims] 0] 0 [lindex [$upvItem getDims] 1] 0 [lindex [$upvItem getDims] 2]];#will hold imin, imax, jmin, jmax, kmin and kmax
	set collectedCandidates [list];#will hold all values which could possibly be the treshold value at which should be cropped
	set theDimsList [$upvItem getDims]
	#makes shure treshold is not out of max value (when treshold is greater than max value it will be set to max value):
	if { $treshhold >= [lindex [$upvItem getRange] 1] } then {
		set treshhold [expr [lindex [$upvItem getRange] 1] - 1]
		$this say "treshold is greater than max value in voxel field! Will be set to: [expr [lindex [$upvItem getRange] 1] - 1]"
	}
	
	workArea startWorking;#a progress indicator makes sense in this slow proc
	workArea setProgressInfo "cropping 1/6"
	
	#imin:
	set newDeep [lindex $theDimsList 0]
	for { set k 0 } { $k < [lindex $theDimsList 2]  } { incr k } {
		
		for { set j 0 } { $j < [lindex $theDimsList 1]  } { incr j } {
			
			for { set i 0 } { $i < $newDeep } { incr i } {
				
				if { [$upvItem getValue $i $j $k] > $treshhold } then { lappend collectedCandidates $i; break }
			}
			if { $collectedCandidates ne [list] } then { set newDeep [expr int([::math::statistics::min $collectedCandidates])] }
		}
		workArea wasInterrupted
		workArea setProgressValue [expr (1/6.)*($k/double([lindex $theDimsList 2]))]
	}
	
	if { $collectedCandidates ne [list] } then { set cropPoints [lreplace $cropPoints 0 0 [expr int([::math::statistics::min $collectedCandidates])]] }
	set collectedCandidates [list]
	
	workArea setProgressInfo "cropping 2/6"
	#imax:
	set newDeep [lindex $cropPoints 0]
	for { set k 0 } { $k < [lindex $theDimsList 2]  } { incr k } {
		
		for { set j 0 } { $j < [lindex $theDimsList 1]  } { incr j } {
			
			for { set i [expr [lindex $theDimsList 0] - 1] } { $i >= $newDeep } { incr i -1 } {
				
				if { [$upvItem getValue $i $j $k] > $treshhold } then {
					lappend collectedCandidates $i
					break 
				}
			}
			if { $collectedCandidates ne [list] } then { set newDeep [expr int([::math::statistics::max $collectedCandidates])] }
		}
		workArea wasInterrupted
		workArea setProgressValue [expr (1/6.)+(1/6.)*($k/double([lindex $theDimsList 2]))]
	}
	if { $collectedCandidates ne [list] } then { set cropPoints [lreplace $cropPoints 1 1 [expr int([::math::statistics::max $collectedCandidates])]] }
	set collectedCandidates [list]
	
	workArea setProgressInfo "cropping 3/6"
	#jmin:
	set newDeep [lindex $theDimsList 1]
	for { set k 0 } { $k < [lindex $theDimsList 2]  } { incr k } {
		
		for { set i [lindex $cropPoints 0] } { $i < [lindex $cropPoints 1]  } { incr i } {
			
			for { set j 0 } { $j < $newDeep  } { incr j } {
				
				if { [$upvItem getValue $i $j $k] > $treshhold } then { lappend collectedCandidates $j; break }
			}
			if { $collectedCandidates ne [list] } then { set newDeep [expr int([::math::statistics::min $collectedCandidates])] }
		}
		workArea wasInterrupted
		workArea setProgressValue [expr (2/6.)+(1/6.)*($k/double([lindex $theDimsList 2]))]
	}
	if { $collectedCandidates ne [list] } then { set cropPoints [lreplace $cropPoints 2 2 [expr int([::math::statistics::min $collectedCandidates])]] }
	set collectedCandidates [list]
	
	workArea setProgressInfo "cropping 4/6"
	#jmax:
	set newDeep [lindex $cropPoints 2]
	for { set k 0 } { $k < [lindex $theDimsList 2]  } { incr k } {
		
		for { set i [lindex $cropPoints 0] } { $i < [lindex $cropPoints 1]  } { incr i } {
			
			for { set j [expr [lindex $theDimsList 1] - 1] } { $j >= $newDeep } { incr j -1 } {
				
				if { [$upvItem getValue $i $j $k] > $treshhold } then {
					lappend collectedCandidates $j
					break 
				}
			}
			if { $collectedCandidates ne [list] } then { set newDeep [expr int([::math::statistics::max $collectedCandidates])] }
		}
		workArea wasInterrupted
		workArea setProgressValue [expr (3/6.)+(1/6.)*($k/double([lindex $theDimsList 2]))]
	}
	if { $collectedCandidates ne [list] } then { set cropPoints [lreplace $cropPoints 3 3 [expr int([::math::statistics::max $collectedCandidates])]] }
	set collectedCandidates [list]
	
	workArea setProgressInfo "cropping 5/6"
	#kmin:
	set newDeep [lindex $theDimsList 2]
	for { set i [lindex $cropPoints 0] } { $i < [lindex $cropPoints 1]  } { incr i } {
		
		for { set j [lindex $cropPoints 2] } { $j < [lindex $cropPoints 3]  } { incr j } {
			
			for { set k 0 } { $k < $newDeep  } { incr k } {
				
				if { [$upvItem getValue $i $j $k] > $treshhold } then { lappend collectedCandidates $k; break }
			}
			if { $collectedCandidates ne [list] } then { set newDeep [expr int([::math::statistics::min $collectedCandidates])] }
		}
		workArea wasInterrupted
		workArea setProgressValue [expr (4/6.)+(1/6.)*($i/double([lindex $cropPoints 1]))]
	}
	if { $collectedCandidates ne [list] } then { set cropPoints [lreplace $cropPoints 4 4 [expr int([::math::statistics::min $collectedCandidates])]] }
	set collectedCandidates [list]
	
	#kmax:
	set newDeep [lindex $cropPoints 4]
	for { set i [lindex $cropPoints 0] } { $i < [lindex $cropPoints 1]  } { incr i } {
		
		for { set j [lindex $cropPoints 2] } { $j < [lindex $cropPoints 3]  } { incr j } {
			
			for { set k [expr [lindex $theDimsList 2] - 1] } { $k >= $newDeep } { incr k -1 } {
				
				if { [$upvItem getValue $i $j $k] > $treshhold } then {
					lappend collectedCandidates $k
					break 
				}
			}
			if { $collectedCandidates ne [list] } then { set newDeep [expr int([::math::statistics::max $collectedCandidates])] }
		}
		workArea wasInterrupted
		workArea setProgressValue [expr (5/6.)+(1/6.)*($i/double([lindex $cropPoints 1]))]
	}
	if { $collectedCandidates ne [list] } then { set cropPoints [lreplace $cropPoints 5 5 [expr int([::math::statistics::max $collectedCandidates])]] }
	
	$this say "cropPoints for $upvItem: $cropPoints"
	eval $upvItem crop $cropPoints
	$upvItem fire;#connected volren module should also be updated, so here is fire
	
	workArea setProgressInfo "cropping finished"
	workArea stopWorking	
}

# procedure which returns all parameters of a given amira field in a formatted array, were every parameter/value can be fetched. \
  procedure is needed, because amira´s tcl interface can´t do it in one step \
  amira field parameter lists are not that big, so this recursive approach should make not to much overhead. \
  procedure needs as the only argument a amira field (e.g. label field). the rest of the optional arguments are for the recursion
$this proc makeArrayFromAmiraParameters { field { theComplValArr {} } { concatBundles {} } { recloop 0 } } {
		
	upvar 1 $theComplValArr theComplValArrUpvar;# this is neccesary because theComplValArrUpvar should always point one level up (yeah! Tcl has some sort of pointers ;)) to theComplValArr,\
	 so that theComplValArr gets every time modified even the recursion is in a stackframe deeper
	
	set theList [eval "$field parameters [join $concatBundles] list"]
	if { [llength $theList] == 0 } { echo "$field has no parameters"; return 1 }
	
	foreach element $theList {
		
		if { [eval "$field parameters [join $concatBundles] $element isBundle"] } {
			
			$this makeArrayFromAmiraParameters $field theComplValArrUpvar [concat $concatBundles $element] [incr recloop]
			
		} else {
		
			set theValue [eval "$field parameters [join $concatBundles] $element getValue"]
			if { ![info exists theComplValArrUpvar([join $concatBundles ,],$element)] } {
				 set theComplValArrUpvar([join $concatBundles ,],$element) [list $element $theValue]
			}
		}
	}
	return [array get theComplValArrUpvar]
	
}


# procedure which connects $this to all label fields in the pool when invoked:
$this proc autoConnectToLabelField {} {

	global allConnectedLabFields allEmptyConPorts
	set allLabelFieldsInPoolList [all HxUniformLabelField3]
	set allConPorts [$this connectionPorts]
	
	foreach item $allConPorts {
		if { [$this $item isOfType "HxConnection"] } then { $this $item disconnect };#disconnects only HxConnection connection ports (e.g. not colormap port)
	}
	#(re)connects to all labelfields in pool: 
	foreach item $allLabelFieldsInPoolList {
		$this [lindex $allEmptyConPorts 0] connect $item
		$this compute
	}
}

# function which checks on some $this states and sets the labels of "label set" ports, so every time something happens with $this \
  it knows it´s actual state and it can be asked about it:
$this proc checkModuleStateAndSetVariables {} {

	global allConnectedLabFields allEmptyConPorts labCountList
	global lastLabSetArray userLabListSelState labSetList emptyConPorts labOKFlagList
	global userResultSelState userSaveState
	
	$this fire
	
	# first make all empty:
	array unset userLabListSelState
	array unset lastLabSetArray
	set allConnectedLabFields [list]
	set allEmptyConPorts [list]
	set labCountList [list]
	set labSetList [list]
	set emptyConPorts 0
	set labOKFlagList [list]
	
	# and then update again the lists/arrays:
	for { set i 1 } { $i < [expr [llength [$this connectionPorts]] - 1] } { incr i } {
	
		if { [$this  [lindex [$this connectionPorts] [expr $i + 1]] source] ne "" } {
			
			if { [[$this  [lindex [$this connectionPorts] [expr $i + 1]] source] getControllingData] eq "" } {# test if label field has a image data field attached (e.g. needed for arithmetic calculations)
				$this say "warning! [$this  [lindex [$this connectionPorts] [expr $i + 1]] source] has no image data field connected,\nfor processing of \"[$this result getLabel 2]\" and \"[$this result getLabel 2]\" results this is required"
				lappend labOKFlagList 0
			} else { lappend labOKFlagList 1 }
			
			lappend allConnectedLabFields [$this [lindex [$this connectionPorts] [expr $i + 1]] source]
			lappend labCountList [[$this labFieldPortCon$i source] parameters Materials nBundles]
			lappend labSetList labSet$i
			set userLabListSelState($i) [$this labSet$i getState]
			
			for { set x 0 } { $x < [$this labSet$i getNum] } { incr x } {
				set lastLabSetArray($x) [$this labSet$i getLabel $x]
			}

			# show the ports when connected to label field:
			$this labSeparator$i show
			$this labSetSelBottons$i show
			$this labSet$i show
			
		} else {
			
			if { [regexp {labFieldPortCon\d} [lindex [$this connectionPorts] [expr $i + 1]]] } then {# count every empty connection port when connection port is a LabFieldCon 
				incr emptyConPorts
			}
			lappend allEmptyConPorts [lindex [$this connectionPorts] [expr $i + 1]]
			
			# hide the ports when not connected to label field:
			$this labSeparator$i hide
			$this labSetSelBottons$i hide
			$this labSet$i hide
			
		}
		
	}
	
	# saving states for the static gui elements:
	set userResultSelState [$this result getState]
	set userSaveState [$this saveResults getState]
	
	# this loop sets the labels for each dynamic toggle in labSet ports:
	for { set x 1 } { $x < [expr [llength [$this connectionPorts]] - 1] } { incr x } {
	
		if { [$this labFieldPortCon$x isNew] == 1 && [$this labFieldPortCon$x source] ne ""  } {#set the labels only new when connection port is new - reduces overhead
					
			$this labSet$x setNum [[$this labFieldPortCon$x source] parameters Materials nBundles];# get the number of material from the source and set number of toogles
			for { set y 0 } { $y < [$this labSet$x getNum] } { incr y } {
				$this labSet$x setLabel $y [lindex [[$this labFieldPortCon$x source] parameters Materials list] $y]
			}
			
		}
		
	}
	
	# printing $this info (only for debugging):
#	$this say "\nuserLabListSelState: [array get userLabListSelState]"
#	$this say "lastLabSetArray: [array get lastLabSetArray]"
#	$this say "allConnectedLabFields: $allConnectedLabFields"
#	$this say "allEmptyConPorts: $allEmptyConPorts"
#	$this say "emptyConPorts: $emptyConPorts"
#	$this say "labOKFlagList: $labOKFlagList"
#	$this say "labCountList: $labCountList"
#	$this say "labSetList: $labSetList"
#	$this say "userResultSelState: $userResultSelState"
#	$this say "userSaveState: $userSaveState\n"
	
}

# procedure which will be executed when a "None" button is pressed
$this proc bottonNonePressed { num } {
	
	for { set i 0 } { $i <= [$this labSet$num getNum] } { incr i } {
		$this labSet$num setValue $i 0
	}
 	$this checkModuleStateAndSetVariables
 			
}
# procedure which will be executed when a "All" button is pressed
$this proc bottonAllPressed { num } {
 	
	for { set i 0 } { $i <= [$this labSet$num getNum] } { incr i } {
		$this labSet$num setValue $i 1
	}
	$this checkModuleStateAndSetVariables;
  			
}

# procedure creates gui elements (separator, bottons, toggles) for a connected lab field \
  argument i is the number of portname
$this proc createConPortButtonsToggles { i } {

	global allConnectedLabFields labCountList
	global lastLabSetArray labSetList
	global userLabListSelState userResultSelState userSaveState emptyConPorts
		
	$this newPortConnection labFieldPortCon$i HxUniformLabelField3
	
	# creates gui for material selection toggles:
	$this newPortSeparator labSeparator$i
	$this newPortButtonList labSetSelBottons$i 2
	$this labSetSelBottons$i setLabel "Selection $i"
	$this labSetSelBottons$i setLabel 0 "None"
	$this labSetSelBottons$i setLabel 1 "All"
	$this newPortToggleList labSet$i 0;# only init, right toggles numbers will be determind when label field is connected
	$this labSet$i setLabel "Label set $i"
	
	# build strings for setCmc commands, because $i has to be evaluated before it is given as argument for setCmd
	# every new botton set will get a individual procedure assigned (which will be executed every time a "None" or "All" botton is pressed),
	# because $i changes with every run of createConPortButtonsToggles procedure
	eval "\$this labSetSelBottons\$i setCmd 0 \{ \$this bottonNonePressed " "$i \}"
	eval "\$this labSetSelBottons\$i setCmd 1 \{ \$this bottonAllPressed " "$i \}"
	
	# ports should initially hidden:
	$this labSeparator$i hide
	$this labSetSelBottons$i hide
	$this labSet$i hide
	
	$this checkModuleStateAndSetVariables;
	
}
# procedure deletes gui elements (separator, bottons, toggles) for a connected lab field \
  argument i is the number of portname
$this proc deleteConPortButtonsToggles { i } {
		
	$this deletePort labFieldPortCon$i
	$this deletePort labSeparator$i
	$this deletePort labSetSelBottons$i
	$this deletePort labSet$i
	
	$this checkModuleStateAndSetVariables;
	
}

# procedure which will make shure that there is always a free connection port for connecting a label field \
  all connection ports at the end will be deleted if there is a free connection port somewhere in the middle \
  (is a smarter logic that for example the amira´s own ExtractSurface module has)
$this proc conPortLogic {} {

	global emptyConPorts
	
	# create new connecton port when the last connecton port in the list has connected a label field:
	if { [$this [lindex [$this connectionPorts] end] source] ne "" && $emptyConPorts == 0 } {
		
		$this createConPortButtonsToggles [expr [llength [$this connectionPorts]] - 1];
	}
	# delete all connection ports beginning at the end until the first connction port with a connected label field is found:
	for { set i 0 } { $i < [llength [$this connectionPorts]] } { incr i } {
	
		if { [$this [lindex [$this connectionPorts] end] source] eq "" && $emptyConPorts > 1 } {
			$this deleteConPortButtonsToggles [expr [llength [$this connectionPorts]] - 2];
		}
		
	}

}

# procedure which creates moduleType and connects it with sourceName module and checks if connection is valid \
  moduleName is the name of the module in the pool \
  if moduleName module does not exist it also gets created in the pool \
  function returns the name string of the newly created module
$this proc createModuleAndConnectIfOkToSource { moduleType moduleName sourceName { conPortIndex 0 } } {
	
	if { [lsearch [all $moduleType] $moduleName] == -1 } {# test if module is already in the pool -1 := not in pool
	
		 	set returnedModule [create $moduleType $moduleName]
		 	set theConnectionPort [lindex [$moduleName connectionPorts] $conPortIndex];# sets the desired connectionPort name, default is 0
		 	if { [$moduleName $theConnectionPort validSource $sourceName] == 1 } {
		 		if { [$moduleName $theConnectionPort source] ne $sourceName } { $moduleName $theConnectionPort connect $sourceName };
		 	} else { $this say "$sourceName is no valid source for $moduleName" }
		 	
		 } else {
		 	
		 	set returnedModule $moduleName
		 	set theConnectionPort [lindex [$moduleName connectionPorts] $conPortIndex]
		 	if { [$moduleName $theConnectionPort validSource $sourceName] == 1 } {
		 		if { [$moduleName $theConnectionPort source] ne $sourceName } { $moduleName $theConnectionPort connect $sourceName };
		 	} else { $this say "$sourceName is no valid source for $moduleName" }
		 	
	}
	
	return $returnedModule
	
}

# switches the given module port remotely from $this ($this must have a corresponding (i.e. same) port!) \
  it works like the amira built in port connect "<modulename 1> <P0 name> connect < modulename 2> [<P1 name>]" exept, \
  that it works (e.g. there are some bugs with menu entry numeration in amira modules)
$this proc setCorrespondingPort { module port { portIndex 0 } } {

	upvar #0 $module myModule
	
	if { [info exists myModule] == 0 } {
		$this say "hm\.\.\. $myModule module does not exist, maybe you deleted it - restart $moduleName"
	}
	
	$this fire;# infinit loop in Amira when here no update of all downstream modules - crashes most of the time Amira
	
	switch -exact [$this $port getTypeId] {
		HxPortMultiMenu { $myModule $port setValueString $portIndex [$this $port getLabel [$this $port getValue $portIndex]] }
		HxPortToggleList { $myModule $port setValue  $portIndex [$this $port getValue $portIndex] }
		default { $this say "proc setCorrespondingPort: could not find a corresponding port" }
	};# setValueString is more robust than index counting with setValue
	
	$myModule compute

}
