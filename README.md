# VSAV Training Mode - MAME

## About

A training mode for vsavj on MAME.

## Windows Installation 
  1. Copy `run_vsav_training.bat` to wherever your `mame.exe` is located (referred to after this as `<MAME installation>`). Make sure there are no spaces in the directory path.
  2. Copy the `/plugins/vsav_training/` folder to `<MAME installation>/plugins/`
  3. Copy the  `/plugins/vsav_training/vsavj/` folder to `<MAME installation>/artwork/`
  4. Run `run_vsav_training.bat`

## Use

### General

**Warning:** this plugin does not play well with the default MAME layout plugin. That's because I had to hack it for the input viewer. Please ensure it is **disabled**.

Press whatever key you use to bring up the MAME in-system menu (`TAB` by default) and navigate to `Plugin Options`. Here you will find myriad settings.

You may double click any numeric entries to type your own values. You must first press `BACKSPACE` to delete the old value, if desired. When you are finished, press `ENTER` or `ESCAPE` or double click the item once more or exit the MAME menu to save the setting.

Note that some values have numeric constraints; if you enter a value outside of a valid range, they will automatically be updated to reflect a valid value.

### Character Select

On character select, you may select a stage by pressing `COIN 1` on a character portrait. Each corresponds to a different stage. Random will return the selection to random.
| Character | Stage                   |
| --------- | ----------------------- |
| Bulleta   | War Agony               |
| Demitri   | Feast of the Damned     |
| Gallon    | Concrete Cave           |
| Victor    | Forever Torment         |
| Zabel     | Iron Horse, Iron Terror |
| Morrigan  | Deserted Chateau        |
| Anakaris  | Red Thirst              |
| Felicia   | Tower of Arrogance      |
| Bishamon  | Abaraya                 |
| Aulbath   | Green Scream            |
| Sasquatch | Forever Torment         |
| Q-Bee     | Vanity Paradise         |
| Lei-Lei   | Vanity Paradise         |
| Lilith    | Deserted Chateau        |
| Jedah     | Fetus of God            |
| Random    | Random (default)        |

### Input Viewer

In order to enable/disable the input viewer, open the OSD menu (`TAB` by default) then navigate to `Video Options > Screen #0`. To enable the input viewer, select `Input Display`. To disable the  input viewer, select any of the other options (`Screen 0 Standard (4:3)` by default).