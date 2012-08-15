# procedure which connects $this to all surface fields in the pool when invoked:
$this proc autoConnectToSurface {} {

	set allSurfacesInPoolList [all HxSurface]
	set allConPorts [$this connectionPorts]
	
	foreach item $allConPorts {
		if { [$this $item isOfType "HxConnection"] } then { $this $item disconnect };#disconnects only HxConnection connection ports (e.g. not colormap port)
	}
	#(re)connects to all labelfields in pool: 
	foreach item $allSurfacesInPoolList {
		$this [lindex $allEmptyConPorts 0] connect $item
		$this compute
	}
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