# [Merling Avatar](https://github.com/Taurs-with-Keyboards/FiguraMerlingAvatar)
### Version: 3.7.3
This Figura avatar is a template designed around giving the user a customizable merfolk tail.

### Authors:
- Detrilogue
- FlossenMonster
- Total

### Credits:
- Snqwblind
- Dragonearuss
- Jimmy
- PoolloverNathan

### Libraries:
- Grandpa Scout (GSAnimBlend, GSCarrier)
- Squishy (SquAPI)
- Katt (OriginsAPI, KattArmor, DynamicCrosshair)
- 4P5 (GroundCheck)
- Manuel (Molang Conversions)
- Auria (Molang Conversions)

## Features
Below is a list of all features this Avatar contains, but you could always watch instead of read:

### Warning!
This list is extremely outdated, features may or may not exist.

[<img src="https://img.youtube.com/vi/rSYfbQ1mkgM/maxresdefault.jpg" alt="image" width="300" height="auto">](https://youtu.be/rSYfbQ1mkgM) 
(v3.0.0 release shown)

### Fully Animated tail
	- Standing and Crawling
	- Mounted and Sleeping
	- Twirling and Singing (v3.1.0)
	- Shark based movement
### Tail fully toggleable and dynamic
	- Uses Action Wheel and Keybinds
	- Has 4 different water based toggles
	- Customizeable drying & sound
### Emissive textures
	- Toggleable Glowing for both eyes and tail
	- Optional light & water based settings
### Misc features
	- Easy to use vanilla texture/model settings
	- Whirlpool while swimming (toggleable)
	- Camera settings (especially useful for crawling animation)
	- Squishy API, GSAnimBlend, GSCarrier, KattArmor API, and KattOrigin API preinstalled
	- And more!
## Installation
This avatar is installed the [same way](https://wiki.figuramc.org/start_here/Avatar%20File%20Format) as any other Figura avatar.
## Frequently Asked Questions
>Q: "How do I texture the tail?"
>A: "Using your favorite image editor, preferably one that can retain transparency of PNGs. If you are having a hard time understanding how to texture, treat this similar to editing a minecraft skin!"

>Q: "How do I add fins/change the size of the tail?"
>A: "Figura uses Blockbench for its avatar models, I recommend looking up a tutorial on using blockbench, however, I recommend looking into learning how to make flat planes.

>Q: "My emissive/glowing texture isn't working/working incorrectly!"
>A: "Make sure the emissive texture of choice `<Texture Name>_e.png` has the part you want glowing. If the tail isnt glowing correctly, add the new/modified part to the `GlowingTail.lua` script's `glowPart` table. Follow [model indexing](https://wiki.figuramc.org/tutorials/ModelPart%20Indexing) patterns!

>Q: "How do I modify the animations?"
>A: "This Avatar uses Blockbench for its animations, however, most use a custom lua based molang with a tick based timer for its sine waves. If you do not understand sinewaves, try messing with the values around the [sine equations](https://www.desmos.com/calculator/w9jrdpvsmk)!"

>Q: "Why does `x` part/feature exist?"
>A: "Various parts/features exist for the sake of streamlined customizeability. If you feel that a feature is not needed, removing it should be easy, but will most likely result in a script error. Deleting associated code should fix the issue."