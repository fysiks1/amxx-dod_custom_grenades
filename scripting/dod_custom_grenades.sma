#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <dodfun>
#include <fun>

#define chance(%1) ( %1 > random(100) )

new g_szModels[6][64], g_iModelCount = 0
new g_iChances[sizeof g_szModels], g_iChanceSum = 0
new g_pChanceCvar, g_pTimeCvar, g_pModeCvar, g_pNadeModel
new g_pInfiniteGrenades

public plugin_init()
{
	register_plugin("DOD Custom Grenades", "1.0", "Fysiks")
	
	g_pModeCvar = register_cvar("custom_nade_mode", "1")
	g_pChanceCvar = register_cvar("custom_nade_chance", "50")
	g_pTimeCvar = register_cvar("custom_nade_time", "4.8")
	g_pNadeModel = register_cvar("custom_nade_model", "0")
	
	g_pInfiniteGrenades = register_cvar("infinite_nades", "0") // Infinite nades (for testing, mostly)
}

public plugin_precache()
{
	LoadSettings()
	
	for(new i = 0; i < sizeof g_szModels; i++)
	{
		if( file_exists(g_szModels[i]) )
		{
			precache_model(g_szModels[i])
			copy(g_szModels[g_iModelCount], charsmax(g_szModels[]), g_szModels[i])
			g_iChances[g_iModelCount] = g_iChances[i]
			g_iChanceSum += g_iChances[g_iModelCount]
			g_iModelCount++
		}
	}

	if( !g_iModelCount )
	{
		set_fail_state("Failed to load any custom nade models")
	}
}

public grenade_throw(id, ent, iType)
{
	remove_task(ent)
	
	switch( get_pcvar_num(g_pModeCvar) )
	{
		case 1: // Custom model for unprimed nades (at custom_nade_time)
		{
			switch( iType )
			{
				case DODW_HANDGRENADE, DODW_STICKGRENADE:  // Unprimed nades
				{
					if( chance(get_pcvar_num(g_pChanceCvar)) )
					{
						set_task(get_pcvar_float(g_pTimeCvar), "set_nade_model", ent)
					}
				}
			}
		}
		case 2: // Custom model for primed nades (immediately)
		{
			switch( iType )
			{
				case DODW_HANDGRENADE_EX, DODW_STICKGRENADE_EX:  // Secondhand or primed nades
				{
					if( chance(get_pcvar_num(g_pChanceCvar)) )
					{
						set_task(0.1, "set_nade_model", ent)
					}
				}
			}
		}
		case 3: // Custom model only if thrown within the last X seconds before explosion
		{
			switch( iType )
			{
				case DODW_HANDGRENADE_EX, DODW_STICKGRENADE_EX:  // Secondhand or primed nades
				{
					if( chance(get_pcvar_num(g_pChanceCvar)) )
					{
						set_task(0.1, "set_nade_model_mode3", ent)
					}
				}
			}
		}
	}
	
	if( get_pcvar_num(g_pInfiniteGrenades) )
	{
		// give nade
		switch( iType )
		{
			case DODW_HANDGRENADE:
			{
				give_item(id, "weapon_handgrenade")
			}
			case DODW_STICKGRENADE:
			{
				give_item(id, "weapon_stickgrenade")
			}
		}
	}
}

public set_nade_model(ent)
{
	if( pev_valid(ent) )
	{
		entity_set_model(ent, g_szModels[model_selector()])
	}
}

public set_nade_model_mode3(ent)
{
	if( pev_valid(ent) )
	{
		static Float:fDamageTime, Float:fGameTime
		pev(ent, pev_dmgtime, fDamageTime)
		fGameTime = get_gametime()

		if( fDamageTime  < (fGameTime + get_pcvar_float(g_pTimeCvar)) )
		{
			entity_set_model(ent, g_szModels[model_selector()])
		}
	}
}

model_selector()
{
	new select = get_pcvar_num(g_pNadeModel)
	return select < 0 ? random_item(g_iChances, g_iModelCount) : clamp(select, 0, g_iModelCount-1)
}

stock random_item(itemChances[], count=sizeof itemChances)
{
	static rand, i, sum
	rand = random(g_iChanceSum)
	i = sum = 0
	for( i = 0; i < count; i++ )
	{
		sum += itemChances[i]
		if( sum > rand )
			break
	}
	return i
}

LoadSettings()
{
	// Load models and chance values from file
	new szConfigsDir[64], szFilePath[128]

	get_configsdir(szConfigsDir, charsmax(szConfigsDir))
	formatex(szFilePath, charsmax(szFilePath), "%s/custom_nades.ini", szConfigsDir)

	new f = fopen(szFilePath, "rt")

	if( f )
	{
		new szBuffer[64], i = 0, szModel[64], szChance[5]
		
		while( fgets(f, szBuffer, charsmax(szBuffer)) )
		{
			parse(szBuffer, szModel, charsmax(szModel), szChance, charsmax(szChance))

			if( szModel[0] )
			{
				copy(g_szModels[i], charsmax(g_szModels[]), szModel)
				g_iChances[i] = str_to_num(szChance)
				i++
			}
		}
		fclose(f)
	}
}
