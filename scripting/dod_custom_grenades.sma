#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <dodfun>
#include <fun>
#include <hamsandwich>

#define chance(%1) ( %1 > random(100) )

new g_szModels[32][64], g_iModelCount = 0
new g_iChances[sizeof g_szModels], g_iChanceSum = 0
new g_pChanceCvar, g_pTimeCvar, g_pModeCvar, g_pNadeModel
new g_iCounter
new g_iModelPointer = 0
new bool:g_bTestMode
new g_pModelPerMap
new HamHook:g_TestModeSpawnHook

public plugin_init()
{
	register_plugin("DOD Custom Grenades", "2.3.1", "Fysiks")
	
	g_pModeCvar = register_cvar("custom_nade_mode", "1")
	g_pChanceCvar = register_cvar("custom_nade_chance", "50")
	g_pTimeCvar = register_cvar("custom_nade_time", "4.8")
	g_pNadeModel = register_cvar("custom_nade_model", "0")
	
	register_concmd("custom_nade_testmode", "cmdTestMode", ADMIN_RCON)
	g_TestModeSpawnHook = RegisterHam(Ham_Spawn, "player", "hookSpawnPost", 1)
	DisableHamForward(g_TestModeSpawnHook)
}

public plugin_precache()
{
	g_pModelPerMap = register_cvar("custom_nade_modelspermap", "0")

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
	else
	{
		server_print("Loaded %d grenade models", g_iModelCount);
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
				case DODW_HANDGRENADE, DODW_STICKGRENADE, DODW_MILLS_BOMB:  // Unprimed nades
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
		case 4: // Custom model for all nades (at custom_nade_time)
		{
			switch( iType )
			{
				case DODW_HANDGRENADE, DODW_STICKGRENADE, DODW_HANDGRENADE_EX, DODW_STICKGRENADE_EX, DODW_MILLS_BOMB:  // Unprimed nades
				{
					if( chance(get_pcvar_num(g_pChanceCvar)) )
					{
						set_task(get_pcvar_float(g_pTimeCvar), "set_nade_model", ent)
					}
				}
			}
		}
	}
	
	if( g_bTestMode )
	{
		// give nade
		switch( iType )
		{
			case DODW_HANDGRENADE, DODW_MILLS_BOMB:
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
	new result

	switch( select )
	{
		case -1:
		{
			result = random_item(g_iChances, g_iModelCount)
		}
		case -2:
		{
			result = g_iCounter++ % g_iModelCount
		}
		default:
		{
			result = clamp(select, 0, g_iModelCount-1)
		}
	}
	return result
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
	// Get model pointer and set next value
	new szModelPointer[8]
	get_localinfo("MdlPtr", szModelPointer, charsmax(szModelPointer))
	g_iModelPointer = str_to_num(szModelPointer)
	num_to_str(g_iModelPointer+1, szModelPointer, charsmax(szModelPointer))
	set_localinfo("MdlPtr", szModelPointer)

	// Load models and chance values from file
	new szConfigsDir[64], szFilePath[128]
	new szModels[sizeof g_szModels][64], i = 0

	get_configsdir(szConfigsDir, charsmax(szConfigsDir))
	formatex(szFilePath, charsmax(szFilePath), "%s/custom_nades.ini", szConfigsDir)

	new f = fopen(szFilePath, "rt")

	if( f )
	{
		new szBuffer[64], szModel[sizeof szModels[]], szChance[5]
		
		while( fgets(f, szBuffer, charsmax(szBuffer)) )
		{
			trim(szBuffer)
			parse(szBuffer, szModel, charsmax(szModel), szChance, charsmax(szChance))

			if( szBuffer[0] && szModel[0] && szModel[0] != ';' && i < sizeof g_szModels && file_exists(szModel) ) // Check szBuffer also because parse() doesn't handle empty lines correctly
			{
				copy(szModels[i], charsmax(szModels[]), szModel)
				g_iChances[i] = str_to_num(szChance)
				i++
			}
		}
		fclose(f)
	}

	// Populate g_szModels based on model pointer & models per map setting
	new iModelsToLoad = clamp(get_pcvar_num(g_pModelPerMap), 0, i)
	iModelsToLoad = iModelsToLoad == 0 ? i : iModelsToLoad
	for(new j = 0; j < i && j < iModelsToLoad; j++)
	{
		copy(g_szModels[j], charsmax(g_szModels[]), szModels[(j+g_iModelPointer)%i])
	}
}

public cmdTestMode(id, level, cid)
{
	if( !cmd_access(id, level, cid, 1) )
		return PLUGIN_HANDLED

	if( read_argc() == 1 )
	{
		console_print(id, "Custom nade test mode is %s", g_bTestMode ? "Enabled": "Disable")
		return PLUGIN_HANDLED
	}
	else
	{
		g_bTestMode = !!read_argv_int(1)
	}

	new iPlayers[32], iPlayersNum
	get_players(iPlayers, iPlayersNum)
	for( new i = 0; i < iPlayersNum; i++ )
	{
		set_user_godmode(iPlayers[i], g_bTestMode)
	}

	if( g_bTestMode )
	{
		EnableHamForward(g_TestModeSpawnHook)
	}
	else
	{
		DisableHamForward(g_TestModeSpawnHook)
	}
	
	console_print(id, "Custom nade test mode was %s", g_bTestMode ? "Enabled": "Disable")

	return PLUGIN_HANDLED
}

public hookSpawnPost(id)
{
	if( is_user_alive(id) )
	{
		set_user_godmode(id, g_bTestMode)
	}
}
