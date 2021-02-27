# Lost and Found
This repo contains a recreation of the Lost and Found system from Call of Duty: Infinite Warfare in Call of Duty: Black Ops III.

## Installation
**IMPORTANT**: If you already have a custom HUD, don't accidentally overwrite it with the provided HUD file! Use a diffchecker to see what you need to add.

Drag the source_data and texture_assets folders into your Black Ops III directory, and the contents of ZM_YOURMAPNAME into your map's folder inside usermaps.

Change the following file names:  
`<root>\usermaps\ZM_YOURMAPNAME\gamedata\tables\zm\ZM_YOURMAPNAME_objectives.json` - Replace ZM_YOURMAPNAME with the map name (eg. zm_testlevel_objectives.json)  
`<root>\usermaps\ZM_YOURMAPNAME\gamedata\tables\zm\WORKSHOPID_objectives.json` - Replace WORKSHOPID with the map's workshop ID (eg. 123456789_objectives.json)

### Including files
In your zm_levelname.gsc file, add this line to the top of the file:  
```
#using scripts\zm\_zm_lost_n_found;
```  
In your zm_levelname.csc file, again add this line to the top of the file:  
```
#using scripts\zm\_zm_lost_n_found;
```  
In your zm_levelname.zone file, add these lines (changing the filenames here too): 
```
structuredtable,gamedata/tables/zm/ZM_YOURMAPNAME_objectives.json
structuredtable,gamedata/tables/zm/WORKSHOPID_objectives.json

localize,lostnfound

image,uie_t7_zm_hud_generic_arrow
material,uie_t7_zm_hud_generic_arrow
image,uie_t7_zm_hud_lostnfound_skull
material,uie_t7_zm_hud_lostnfound_skull

rawfile,ui/uieditor/menus/hud/t7hud_zm_custom.lua
rawfile,ui/uieditor/widgets/hud/zm_lostnfound/zm_lostnfoundwaypointcontainer.lua
rawfile,ui/uieditor/widgets/hud/zm_lostnfound/zm_lostnfoundwaypoint.lua
rawfile,ui/uieditor/widgets/hud/zm_lostnfound/zm_lostnfoundwidget.lua

scriptparsetree,scripts/zm/_zm_lost_n_found.gsc
scriptparsetree,scripts/zm/_zm_lost_n_found.csc
```

For Lua to actually compile as part of your map, you need [L3akMod](https://wiki.modme.co/wiki/black_ops_3/lua_(lui)/Installation.html).

By default, the MR6 and Bloodhound are considered 'limited weapons', similar to wonder weapons such as the Thundergun, however the limit for these
weapons is 0. The Lost and Found will not return weapons if it would cause the players to exceed the weapon limit (to prevent duping wonder weapons), and will
therefore NOT return these weapons. You should fix this by removing their limit in zm_levelcommon_weapons.csv, firstly by setting the is_limited column to FALSE,
and then by making the limit column blank.

### Placing Recover Points in Radiant
Placing the location for players to retrieve their weapons in Radiant is very easy. Simply place a script_struct, and give it the targetname lnf_recover_point.
It is recommended that you place the recover point somewhere in the spawn room, so that it is accessible no matter what. Having multiple recover points on the map
is possible, but this is not recommended because they will clutter the respawning player's HUD. You should decorate the recover point appropriately, good props
include cardboard boxes or drawers.

### Customization
By default, the player has 75 seconds to retrieve their weapons, but this can be changed in _zm_lost_n_found.gsh. For example, you may want to give the player 90
seconds if your map is quite large (Origins size).

## Contributing
Pull requests are welcome.

## Credits
Scobalula - Cerberus, HydraX  
DTZxPorter - Wraith  
JariK - Lua decompiler  
The D3V Team (DTZxPorter, SE2Dev, Nukem) - L3akMod, t7hud_zm_custom.lua  
oper10 - Waypoint Icon  
Green Donut - Testing
