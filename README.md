# Donkey Kong 3

Analogue Pocket port of Donkey Kong 3

## Features

* Dip switches for difficulty, starting lives, and bonuses.

## Known Issues

* High Score saving doesn't work.
* Tate mode isn't supported.

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
