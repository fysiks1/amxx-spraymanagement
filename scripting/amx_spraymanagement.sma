#include <amxmodx>
#include <amxmisc>

#define MAX_SPRAYID 10
new const MAX_DISTANCE = 50

enum _:SprayData {
	SprayOrigin[3],
	SprayOwner,
	SpraySprayer
}

new g_Sprays[MAX_SPRAYID][SprayData]
new g_iSprayCounter

public plugin_init()
{
	register_plugin("Spray Management", "Fysiks", "1.0")

	register_clcmd("sprayid", "cmdQuerySpray", ADMIN_KICK)
	register_clcmd("makespray", "cmdMakeSpray", ADMIN_KICK, "<name or #userid> - Sprays another player's spray")

	register_event("23", "evSpray", "a", "1=112")	// SVC_TEMPENTITY (TE_PLAYERDECAL)
}

public client_disconnect(id)
{
	// Clear any stored sprays for this slot
	for(new i = 0; i < sizeof(g_Sprays); i++)
	{
		if( g_Sprays[i][SprayOwner] == id )
		{
			g_Sprays[i][SprayOwner] = 0
		}
	}
}

public cmdQuerySpray(id, level, cid)
{
	if( !cmd_access(id, level, cid, 1) )
		return PLUGIN_HANDLED

	// Finding the owner of the spray we are pointing at

	new Spray[SprayData], iTargetOrigin[3], iOrigin[3]

	get_user_origin(id, iTargetOrigin, 3) // 3 = hitpoint for weapon

	for( new i = 0; i < sizeof(g_Sprays); i++)
	{
		// get_distance() doesn't like the complex data structure
		iOrigin[0] = g_Sprays[i][SprayOrigin][0]
		iOrigin[1] = g_Sprays[i][SprayOrigin][1]
		iOrigin[2] = g_Sprays[i][SprayOrigin][2]

		if( g_Sprays[i][SprayOwner] && get_distance(iTargetOrigin, iOrigin) < MAX_DISTANCE )
		{
			// Spray within max distance found
			Spray = g_Sprays[i]
			break
		}
	}

	if( Spray[SprayOwner] )
	{
		new szName[32]; get_user_name(Spray[SprayOwner], szName, charsmax(szName))
		
		if( Spray[SprayOwner] == Spray[SpraySprayer] )
		{
			client_print(id, print_chat, "Spray is owned by %s", szName)
		}
		else
		{
			client_print(id, print_chat, "Spray is owned by %s (sprayed by an admin)", szName)
		}
	}
	else
	{
		client_print(id, print_chat, "No spray found")
	}

	return PLUGIN_HANDLED
}

/* Spray any player's spray */
public cmdMakeSpray(id, level, cid)
{
	if( !cmd_access(id, level, cid, 1) )
		return PLUGIN_HANDLED

	new szArg[32]
	new iTargetOrigin[3]

	read_argv(1, szArg, 31)
	new iPlayer = cmd_target(id, szArg)
	if( !iPlayer )
	{
		get_user_origin(id, iTargetOrigin, 3) // 3 = hitpoint for weapon

		message_begin(MSG_ALL, SVC_TEMPENTITY)
		write_byte(112) // TE_PLAYERDECAL
		write_byte(iPlayer)
		write_coord(iTargetOrigin[0])
		write_coord(iTargetOrigin[1])
		write_coord(iTargetOrigin[2])
		write_short(0) // ???
		write_byte(1)
		message_end()

		pushSpray(iTargetOrigin, iPlayer, id)

		client_print(id, print_console, "[AMX] Spray successful")
	}

	return PLUGIN_HANDLED
}

public evSpray()
{
	static id, iCoords[3]
	
	id = read_data(2)	// Spray Owner
	iCoords[0] = read_data(3)	// Spray coord x
	iCoords[1] = read_data(4)	// Spray coord y
	iCoords[2] = read_data(5)	// Spray coord z

	pushSpray(iCoords, id, id)
}

pushSpray(iOrigin[3], iOwner, iSprayer)
{
	g_Sprays[g_iSprayCounter][SprayOrigin][0] = iOrigin[0]
	g_Sprays[g_iSprayCounter][SprayOrigin][1] = iOrigin[1]
	g_Sprays[g_iSprayCounter][SprayOrigin][2] = iOrigin[2]
	g_Sprays[g_iSprayCounter][SprayOwner] = iOwner
	g_Sprays[g_iSprayCounter][SpraySprayer] = iSprayer
	g_iSprayCounter = ++g_iSprayCounter % sizeof(g_Sprays)
}
