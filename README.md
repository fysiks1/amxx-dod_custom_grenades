# Overview

This plugin sets a custom model to be used in place of grenades based on various conditions (configured via cvars).

# Configuration

## Config File

Location:  \<AMXX configs dir\>/custom_nades.ini

Configures model files and the corresponding probability (used when custom_nade_model is set to -1).

### Example Config File
```
"models/mapmodels/cow.mdl" 10
"models/chicken.mdl" 60
"models/mapmodels/bunny.mdl" 30
```
These probability values are relative to the sum of all the values (i.e. it's not necessarily percent)

## CVARS
### custom_nade_mode

0. Custom model is disabled
1. Custom model for unprimed nades (at 'custom_nade_time' after thrown)
2. Custom model for primed nades (immediately)
3. Custom model for primed nades (if thrown within the last 'custom_nade_time' second before explosion)
4. Custom model for all nades (at 'custom_nade_time' after thrown)

### custom_nade_chance

The probability that a custom grenade model will be used.

### custom_nade_time

Time in seconds used by time-based modes.

### custom_nade_model

Selection for which model will be used for the custom grenade.  Models are zero-based indexed (0 is the first model).

#### Special Values
- -1 will randomly choose one of the nade models based on the probability values defined in the config file.
- -2 will cycle through all nade models

### custom_nade_modelspermap

Number of models to load per map.  This subset of maps will then cycle through all the maps configured in the INI file on each map change.

#### Example
If `custom_nade_modelspermap` is set to 2 and the INI file is configured as:

```
"models/grenades/Model1.mdl" 10
"models/grenades/Model2.mdl" 60
"models/grenades/Model3.mdl" 30
```

Then, `Model1` and `Model2` will be loaded on the first map, `Model2` and `Model3` will be loaded on the second map, and `Model3` and `Model1` will be loaded on the third map.  And so on.

#### Special Values
A value of zero will load all models in the INI file.

# Commands
## custom_nade_testmode <1|0>
Enables (1) or disables (0) test mode.  Run the command without arguments to query the test mode state.

Test mode is used for testing grenade models.  It sets god mode for all players (so you don't die from the grenades) and gives infinite grenades to accelerate testing.

