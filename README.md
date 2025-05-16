# PS2-VMC-GUI

PS2-VMC-GUI is a GUI for [Bucanero's PS2VMC Tool](https://github.com/bucanero/ps2vmc-tool).  
Tested working on windows 10 and 11.  

## What does it do?


This is a PC tool used to manage PS2 virtual memory cards.  
Supports `.psu` and/or `.PSV` to `.bin` VMC file importing.  
Supports `.bin` VMC to `.psu` file exporting.  
PS2-VMC-GUI is used to manage saves on a `.bin` virtual memory card file for use with [OPL](https://github.com/ps2homebrew/Open-PS2-Loader) or [neutrino](https://github.com/rickgaiser/neutrino).  
It functions similarly to [mymc-gui](http://www.csclub.uwaterloo.ca:11068/mymc/).  
Mymc is used to manage saves on a `.ps2` memory card file for use with [PCSX2](https://pcsx2.net/).  


## How do I use it?

### Caution! Importing two saves from the same game will OVERWRITE the previous save.
- If you import two different saves for the same game,  
they will be merged and overwritten without waring.  

Clone this repository or download it as a ZIP file then extract all files to a folder.  
In the extracted folder run `PS2-VMC-GUI-Offline.ps1` with PowerShell.  
The software license will show, click OK then the main interface will appear.  

## Credits:


- PS2VMC Tool:  
Copyright (C) 2023 - by Bucanero <https://www.bucanero.com.ar/>  
Forked from <https://github.com/bucanero/ps2vmc-tool>  
Forked to <https://github.com/MegaBitmap/ps2vmc-tool/tree/EasyParsing>  
Version: ps2vmctool-371f4de3-Win64  


- ps2-covers:  
<https://github.com/xlenore/ps2-covers>  

Based on ps3mca-tool by [jimmikaelkael](https://github.com/jimmikaelkael)

```
 * ps3mca-tool - PlayStation 3 Memory Card Adaptor Software
 * Copyright (C) 2011 - jimmikaelkael <jimmikaelkael@wanadoo.fr>
 * Copyright (C) 2011 - "someone who wants to stay anonymous"
```

## License

This software is licensed under GNU GPLv3, please review the [LICENSE](https://github.com/bucanero/ps2vmc-tool/blob/main/LICENSE)
file for further details. No warranty provided.
