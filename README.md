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

1. Custom model for unprimed nades (at 'custom_nade_time' after thrown)
2. Custom model for primed nades (immediately)
3. Custom model for primed nades (if thrown within the last 'custom_nade_time' second before explosion)

### custom_nade_chance

The probability that a custom grenade model will be used.

### custom_nade_time

Time in seconds used by time-based modes.

### custom_nade_model

Selection for which model will be used for the custom grenade.  Models are zero-based indexed (0 is the first model) and a value of -1 will randomly choose one of the nade models based on the probabily values defined in the config file.
