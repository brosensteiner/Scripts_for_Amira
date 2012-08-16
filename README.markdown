# Scripts for Amira

this Amira scipt-object collection is the result of a "little" sideproject of my diploma thesis at the Department of Theoretical Biology at the University of Vienna.
For convenience there is for every script-object a .rc file for integrating the script-object in the Amira context menu (must be copied in the share/resources folder of $AMIRA\_LOCAL or $AMIRA\_ROOT).
Under some circumstances the .rc file has to be adapted at the hosts environment:

- if you have no local amira directory ($AMIRA\_LOCAL) and want to copy the .rc file in amira´s root directory, then change the $AMIRA\_LOCAL variable to $AMIRA\_ROOT
- if you don´t like the name of the menu entry change the argument of the "name" switch in the .rc file
- if you don´t like the submenu entry change the argument of the "category" switch in the .rc file
- The script-object (and all dependent files) must be copied to [$AMIRA\_LOCAL|$AMIRA\_ROOT]/share/script-objects

If someone has suggestions or questions please let me know and [email me](mailto:brosensteiner@gmail.com)

## Installation

Type the following in terminal:

```bash
    cd ~/***here comes your download path***
    git clone git://github.com/brosensteiner/Scripts_for_Amira.git
```

IMPORTANT: all modules will use a custom tcl package with shared procedures, so in order to get this script-objects to work one must install this package in a path where tcl searches for packages.
Probably the easiest way is to append the package path to the "auto\_path" variable. To do this execute the following steps:

- open the Amira.init file ($AMIRA\_ROOT/share/resources/Amira/Amira.init)
- add the following line: lappend auto\_path "here stands the path to the package file"
- at the next start of Amira control write in the amira console: "echo $auto\_path"
- if the output contains your path all is ok :)

## Documentation

sorry, not ready in this early stage, but will be provided in the native Amira documetation format. 

## MIT License and citeware

Copyright (c) 2012 Bernhard Rosensteiner

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Additional Info

Please cite: Bernhard Rosensteiner, A custom Amira Script-Object. "https://github.com/brosensteiner/Scripts_for_Amira", 2012.

When you use one of my Amira script objects in a scientific publication please [send me a message](mailto:brosensteiner@gmail.com) about for what and how it was used — i´m curious :)


