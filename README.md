# Donkey Kong 3

Analogue Pocket port of Donkey Kong 3

## Features

* Dip switches for difficulty, starting lives, and bonuses.

## Known Issues

* High Score saving doesn't work.
* Tate mode isn't supported.

Note:  File bugs for issues you encounter on the Github tracker.  Any issues are most likely with my integration, and not with the cores themselves.  Please do not engage the original core authors for support requests related to this port.

## Release Notes

v0.9.2
* Updated version fields 

v0.9.1
* Add coin pulse signal to avoid issues reported with inserting coins.

v0.9.0
* Initial release

## Attribution

```
---------------------------------------------------------------------------------
-- 
-- *** WORK IN PROGRESS VERSION ***
--
-- Arcade: Donkey Kong 3 for MiSTer by gaz68 (https://github.com/gaz68)
-- July 2020 
-- 
-- Original Donkey Kong port to MiSTer by Sorgelig
-- 18 April 2018
-- 
---------------------------------------------------------------------------------
-- 
-- dkong Copyright (c) 2003 - 2004 Katsumi Degawa
-- T80   Copyright (c) 2001-2002 Daniel Wallner (jesus@opencores.org) All rights reserved
-- T65   Copyright (c) 2002-2015 Daniel Wallner, Mike Johnson, Wolfgang Scherr, Morten Leikvoll
-- NES APU taken from the NES for MiSTer project
--
---------------------------------------------------------------------------------
-- 
```

-  Quartus template and core integration based on the Analogue Pocket port of [Donkey Kong by ericlewis](https://github.com/ericlewis/openFPGA-DonkeyKong)

## ROM Instructions

ROM files are not included, you must use [mra-tools-c](https://github.com/sebdel/mra-tools-c/) to convert to a singular `dkong3.rom` file, then place the ROM file in `/Assets/dkong3/common`.
