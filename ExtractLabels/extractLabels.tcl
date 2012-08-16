
# proc for finding some shape parameters of labels in a given labelfield and return of an array which holds the shape parameters\
  (e.g. eigenvalues, eigenvectors, mass -> see procedure "extractFromSpreadsheet")\
  this proc uses the ShapeAnalysis module to obtain the shape parameters. If the mass (voxel grey values) should be included in the shape parameter calculation the optional value "massCalc" must be 1
$this proc makeShapeAnalysis { labelfield { shapeAnalysisModul "defaultShapeAnalysisModule" } { massCalc 0 } } {
	
	global theAdditionalDataList
	# the shape analysis:
	$this createModuleAndConnectIfOkToSource HxShapeAnalysis $shapeAnalysisModul $labelfield;#$shapeAnalysisModul is global!!! so it has to be deleted in the destructor proc, otherwise it remains in the pool (it´s global because then it has not every time be generated anew for every call of "makeShapeAnalysis" and stays in the pool)
	if { $massCalc } then { $shapeAnalysisModul Field connect [$labelfield getControllingData] }
	$shapeAnalysisModul action setValue 0
	$shapeAnalysisModul fire
	
	set theResultFromShapeAnalysis [$shapeAnalysisModul getResult]
	array set extrValFromSprdsht [extractFromSpreadsheet $theResultFromShapeAnalysis]
	$theResultFromShapeAnalysis master disconnect 
	lappend theAdditionalDataList $theResultFromShapeAnalysis
	#remove $theResultFromShapeAnalysis
	return [array get extrValFromSprdsht]
	
}

# proc for cropping the extracted voxel fields (will be executed everytime the "Auto Crop" button in the "Resample options1" port is pressed). \
  this proc is really slow because of the "brutal force" approach of the algorithm (for about 160 x 160 x 160 voxel fields to crop to about 60 x 60 x 60 it takes about 58 seconds on intel core 2 duo 2.8Ghz)!!! \
  some optimization brings the algorithm nevertheless down from 3 minutes to 58 seconds: after every for loop the range in which the nodes of the voxel field are evaluated is newly adjusted, \
  so that no unnecessary iteratons have to be made \
  i think this slowness is the Tcl "scripting tradeoff" - much faster is the "C++ Auto Crop" from Amira´s crop editor (when one wants this native amira crop then override this autoCrop with something like: [object getEditor]... )
$this proc autoCrop { item { treshhold 0.000000 } } {

	upvar $item upvItem
	
	set cropPoints [list 0 [lindex [$upvItem getDims] 0] 0 [lindex [$upvItem getDims] 1] 0 [lindex [$upvItem getDims] 2]];#will hold imin, imax, jmin, jmax, kmin and kmax
	set collectedCandidates [list];#will hold all values which could possibly be the treshold value at which should be cropped
	set theDimsList [$upvItem getDims]
	#makes shure treshold is not out of max value (when treshold is greater than max value it will be set to max value -1):
	if { $treshhold >= [lindex [$upvItem getRange] 1] } then {
		set treshhold [expr [lindex [$upvItem getRange] 1] - 1]
		say "treshold you specified is greater than max value in voxel field! Will be set to: $treshhold"
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
	
	say "cropPoints for $upvItem: $cropPoints"
	eval $upvItem crop $cropPoints;#cropping of the item
	$upvItem fire;#connected volren module should also be updated, so here is fire
	
	workArea setProgressInfo "cropping finished"
	workArea stopWorking	
}

# helper procs to check some values of $this (are needed because some buttons have a "setcmd" and they must be able to \
  check this states outside the "compute" procedure loop):
$this proc voxelOptionMassIsChecked {} {
	set checked [$this voxelOptions getValue 1]
	return $checked
}
$this proc voxelOptionAxis1WhichIsChecked {} {
	set checked [$this axis1 getValue]
	return $checked
}
$this proc voxelOptionAxis2WhichIsChecked {} {
	set checked [$this axis2 getValue]
	return $checked
}

#procedure for reslicing a voxel field to a given cut-plane.
$this proc reSlice { objectList } {

	global applyTransformModule obiqueSliceModule shapeAnalysisModul theCompleteExtractedList theResampledExtractedVoxelList
	upvar $objectList upvObjectList
	
	foreach object $upvObjectList {
		
		#calculating the volume of the original boundingbox:
		set theBBox [$object getBoundingBox]
		set bbox_X [expr abs([lindex $theBBox 0] - [lindex $theBBox 1])]
		set bbox_Y [expr abs([lindex $theBBox 2] - [lindex $theBBox 3])]
		set bbox_Z [expr abs([lindex $theBBox 4] - [lindex $theBBox 5])]
		set origVolume [expr $bbox_X * $bbox_Y * $bbox_Z]
		
		#make the connections:
		$this createModuleAndConnectIfOkToSource HxApplyTransform $applyTransformModule $object
		$this createModuleAndConnectIfOkToSource HxObliqueSlice $obiqueSliceModule $object
		$applyTransformModule reference connect $obiqueSliceModule
		
		#get the original labelfield/orig_bundleindex to which the "object" was connected:
		set orig_labelfield	 [$object parameters ModuleInfo orig_labelfield getValue]
		set orig_bundleindex [$object parameters ModuleInfo orig_bundleindex getValue]
		
		#extract the eigenvectors:
		
		array set valFromSprdsht [$this makeShapeAnalysis $orig_labelfield $shapeAnalysisModul [$this voxelOptionMassIsChecked]]
		
		#adjust the oliqueslice plane according to the axis1 and axis2 settings of $this (i.e axis1 and axis2 ports determine the direction of u- and v-vector of the plane):
		if {
			[$this voxelOptionAxis1WhichIsChecked] == 1 && [$this voxelOptionAxis2WhichIsChecked] == 0 || \
			[$this voxelOptionAxis1WhichIsChecked] == 0 && [$this voxelOptionAxis2WhichIsChecked] == 1
		} then {
		
			eval $obiqueSliceModule setPlane $valFromSprdsht($orig_bundleindex,c) \
											 $valFromSprdsht($orig_bundleindex,evector2) \
											 $valFromSprdsht($orig_bundleindex,evector1)
		}
		if {
			[$this voxelOptionAxis1WhichIsChecked] == 2 && [$this voxelOptionAxis2WhichIsChecked] == 0 || \
			[$this voxelOptionAxis1WhichIsChecked] == 0 && [$this voxelOptionAxis2WhichIsChecked] == 2
		} then {
			
			eval $obiqueSliceModule setPlane $valFromSprdsht($orig_bundleindex,c) \
											 $valFromSprdsht($orig_bundleindex,evector3) \
											 $valFromSprdsht($orig_bundleindex,evector1)
		}
		if {
			 [$this voxelOptionAxis1WhichIsChecked] == 2 && [$this voxelOptionAxis2WhichIsChecked] == 1 || \
			 [$this voxelOptionAxis1WhichIsChecked] == 1 && [$this voxelOptionAxis2WhichIsChecked] == 2
		} then {
			
			eval $obiqueSliceModule setPlane $valFromSprdsht($orig_bundleindex,c) \
											 $valFromSprdsht($orig_bundleindex,evector3) \
											 $valFromSprdsht($orig_bundleindex,evector2)
		}
		
		$obiqueSliceModule compute
		
		#set some port values:
		$applyTransformModule mode setValue 1;#set mode to extended -> need the result to contain all original voxel information
		set resampleOptions2_1 [$this resampleOptions2 getOptValue 0 1]
		$applyTransformModule interpolation setValue $resampleOptions2_1;#set Standard, Lanczos or Nearest Neighbor interpolation method from $this port resampleOptions2
		
		#apply transformation:
		$applyTransformModule action setValue 0 1
		$applyTransformModule fire
		
		#get result and append to global theCompleteExtractedList/theResampledExtractedVoxelList:
		set theResult [$applyTransformModule getResult]
		$theResult master disconnect
		lappend theCompleteExtractedList $theResult
		lappend theResampledExtractedVoxelList $theResult;#who knows for what i will need it ...
		
		#calculating the volume of the new boundingbox:
#		echo "origVolume: $bbox_X, $bbox_Y, $bbox_Z, $origVolume"
		set theBBox [$theResult getBoundingBox]
		set bbox_X [expr abs([lindex $theBBox 0] - [lindex $theBBox 1])]
		set bbox_Y [expr abs([lindex $theBBox 2] - [lindex $theBBox 3])]
		set bbox_Z [expr abs([lindex $theBBox 4] - [lindex $theBBox 5])]
		set newVolume [expr $bbox_X * $bbox_Y * $bbox_Z]
#		echo "newVolume: $bbox_X, $bbox_Y, $bbox_Z, $newVolume"
		
		#print some stats (like Amira´s own applyTransform command):
		say "Resample: interpol=$resampleOptions2_1, new dims=[string map { " " "x" } [$theResult getDims]], volume=[format "%.1f" [expr 100 * $newVolume / $origVolume]]\%"
	}
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

# proc for applying the transformation which $this made -> transformation matrix gets reset, but the object in 3D space stays at its position \
  this proc is needed, because when one wants to export for example a HxSurface Object in another application for further processing \
  most of the time the amira transformation matrix is not recognized by this applications (except the app can interpret amiramesh files)
$this proc applyTransformation {} {
	
	global theCompleteExtractedList
	
	say "try to apply transformaton to the following data objects:"
	echo $theCompleteExtractedList
	
	$this checkModuleStateAndSetVariables;#better check here also
	foreach item $theCompleteExtractedList {
		$item applyTransform
	}
}


# function which checks on some $this states and sets the labels of "label set" ports,
# so every time something happens with $this
# it knows it´s actual state and it can be asked about it:
$this proc checkModuleStateAndSetVariables {} {

	global allConnectedLabFields allEmptyConPorts labCountList theCompleteExtractedList
	global lastLabSetArray userLabListSelState labSetList emptyConPorts labOKFlagList
	global userResultSelState userSaveState
	
	$this fire;#make shure all is up to date
	
	# first make all empty:
	array unset userLabListSelState
	array unset lastLabSetArray
	set allConnectedLabFields [list]
	set allEmptyConPorts [list]
	set labCountList [list]
	set labSetList [list]
	set emptyConPorts 0
	set labOKFlagList [list]
	
	# updating the "theCompleteExtractedList" so that procedures which work with this list 
	# don´t throw an error - for example on generated fields which were renamed or deleted by the user
	set tempList [list]
	foreach item $theCompleteExtractedList {
		if { [lsearch -exact [all] $item] != -1 } { lappend tempList $item }
	}
	set theCompleteExtractedList $tempList
	unset -nocomplain tempList
	#say "updated internal list: $theCompleteExtractedList"
	
	# and then update again the lists/arrays (the "[expr $i + 1]" connectionport shift 
	# takes only the connectionport from the colormap port of $this into account):
	for { set i 1 } { $i < [expr [llength [$this connectionPorts]] - 1] } { incr i } {
	
		if { [$this  [lindex [$this connectionPorts] [expr $i + 1]] source] ne "" } {
			
			if { [$this [lindex [$this connectionPorts] [expr $i + 1]] isNew] && \
				 [[$this [lindex [$this connectionPorts] [expr $i + 1]] source] getControllingData] eq ""
			   } {# test if label field has a image data field attached (e.g. needed for arithmetic calculations)
			   
				theMsg warning "warning! [$this [lindex [$this connectionPorts] [expr $i + 1]] source] has no image data field connected,\nfor processing of \"[$this result getLabel 2]\" and \"[$this result getLabel 2] results\" this is required"
				$this [lindex [$this connectionPorts] [expr $i + 1]] untouch;#don´t know why connection port gets touched, so here is untouch that the warning window is only once not twice shown
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
	
		if { [$this labFieldPortCon$x isNew] == 1 && [$this labFieldPortCon$x source] ne "" } {#set the labels only new when connection port is new - reduces overhead
					
			$this labSet$x setNum [[$this labFieldPortCon$x source] parameters Materials nBundles];# get the number of material from the source and set number of toogles
			for { set y 0 } { $y < [$this labSet$x getNum] } { incr y } {
				$this labSet$x setLabel $y [lindex [[$this labFieldPortCon$x source] parameters Materials list] $y]
			}
			
		}
		
	}
	
	# printing $this info (only for debugging):
#	say "\nuserLabListSelState: [array get userLabListSelState]"
#	say "lastLabSetArray: [array get lastLabSetArray]"
#	say "allConnectedLabFields: $allConnectedLabFields"
#	say "allEmptyConPorts: $allEmptyConPorts"
#	say "emptyConPorts: $emptyConPorts"
#	say "labOKFlagList: $labOKFlagList"
#	say "labCountList: $labCountList"
#	say "labSetList: $labSetList"
#	say "userResultSelState: $userResultSelState"
#	say "userSaveState: $userSaveState\n"
	
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
  function returns the name of the newly created module
$this proc createModuleAndConnectIfOkToSource { moduleType moduleName sourceName { conPortIndex 0 } } {
	
	# test if module is already in the pool and assigne the moduleToReturn variable as appropriate:
	if { [lsearch [all $moduleType] $moduleName] == -1 } {
		set hideNewModules 1;#why does this not work!!!
		set moduleToReturn [create $moduleType $moduleName]
		$moduleToReturn hideIcon;#hiding like this is also possible :)
	} else {
		set moduleToReturn $moduleName
	}
	# sets the desired connectionPort name, default is 0:
	set theConnectionPort [lindex [$moduleName connectionPorts] $conPortIndex]
	# connect or echo error in console:
	if {
		[$moduleName $theConnectionPort validSource $sourceName] && \
		[$moduleName $theConnectionPort source] ne $sourceName
	} {
		$moduleName $theConnectionPort connect $sourceName
	}
	
	return $moduleToReturn
}

# switches the given module port remotely from $this ($this must have a corresponding (i.e. same) port!) \
  it works like the amira built in port connect "<modulename 1> <P0 name> connect < modulename 2> [<P1 name>]" exept, \
  that it works (e.g. there are some bugletts with menu entry numeration in amira modules)
$this proc setCorrespondingPort { module port { portIndex 0 } } {

	upvar #0 $module myModule
	
	if { [info exists myModule] == 0 } {
		say "hm\.\.\. $myModule module does not exist, maybe you deleted it - restart $moduleName"
	}
	
	$this fire;# infinit loop in Amira when here no update of all downstream modules - crashes most of the time Amira
	
	switch -exact [$this $port getTypeId] {
		HxPortMultiMenu { $myModule $port setValueString $portIndex [$this $port getLabel [$this $port getValue $portIndex]] }
		HxPortToggleList { $myModule $port setValue  $portIndex [$this $port getValue $portIndex] }
		default { say "proc setCorrespondingPort: could not find a corresponding port" }
	};# setValueString is more robust than index counting with setValue
	
	$myModule compute
}
