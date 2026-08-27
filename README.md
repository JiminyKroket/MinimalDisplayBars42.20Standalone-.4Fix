Project Zomboid updated the "Stable" build 42 AGAIN and broke everything AGAIN, thankfully less stuff I use, but it was a pretty important bit to me.
Had to get this fixed, did not know how else to post the fix for others easily.

If you want "plug-n-play", replace the current Minimal Display Bars (A).lua that is in your "SteamLibrary\steamapps\workshop\content\108600\3775659041\mods\MinimalDisplayBarsB4220\42.20\media\lua\client" directory with the one in this repo.

If you edit code yourself, pull the io_persistence table from the io_persistence.lua file and replace it properly within the file located at "SteamLibrary\steamapps\workshop\content\108600\3775659041\mods\MinimalDisplayBarsB4220\42.20\media\lua\client"
