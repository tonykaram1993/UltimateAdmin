/*
	AMX Mod X script.

	This plugin is free software; you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation; either version 2 of the License, or (at
	your option) any later version.
	
	This plugin is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
	General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this plugin; if not, write to the Free Software Foundation,
	Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
*/

/*
	Change Log
	
	v0.0.1	beta:	* plugin written
	
	v0.0.2	beta:	+ added multi lingual support
			+ changed defined prefix to cvar prefix
			x added cvar reload on plugin start
*/
#define PLUGIN_VERSION		"0.0.2b"

/* Includes */
#include < amxmodx >
#include < amxmisc >

/* Defines */
#define SetBit(%1,%2)		(%1 |= (1<<(%2&31)))
#define ClearBit(%1,%2)		(%1 &= ~(1 <<(%2&31)))
#define CheckBit(%1,%2)		(%1 & (1<<(%2&31)))

#define is_str_empty(%1)	(%1[0] == EOS)

/*
	Below is the section where normal people can safely edit
	its values.
	Please if you don't know how to code, refrain from editing
	anything outside the safety zone.
	
	Experienced coders are free to edit what they want, but I
	will not reply to any private messages nor emails about hel-
	ping you with it.
	
	SAFETY ZONE STARTS HERE
*/

/*
	Set this to your maximum number of players your server can
	hold.
*/
#define MAX_PLAYERS		32

/*
	This is where you stop. Editing anything below this point
	might lead to some serious errors, and you will not get any
	support if you do.
	
	SAFETY ZONE ENDS HERE
*/

/* Enumerations */
enum ( ) {
	ADMIN_DISCONNECTED		= 0,
	ADMIN_IS_UNDERCOVER,
	ADMIN_NOT_UNDERCOVER,
	ADMIN_NAME_CHANGE,
	ADMIN_COMMAND
};

/* Constants */
new const g_strPluginName[ ]		= "UltimateAdmin";
new const g_strPluginVersion[ ]		= PLUGIN_VERSION;
new const g_strPluginAuthor[ ]		= "tonykaram1993";

/* Variables */
new g_iInitialFlags[ MAX_PLAYERS + 1 ];
new g_iUserFlags;
new g_iPrintToImmuneAdmins;

/* Bitsums */
new g_bitIsAnonymous;
new g_bitHasImmunity;
new g_bitHasRcon;

/* Pcvars */
new g_pcvarPluginPrefix;
new g_pcvarPrintToImmunie;

/* Strings */
new g_strPluginPrefix[ 32 ];

/* Plugin Natives */
public plugin_init( ) {
	/* Plugin Registration */
	register_plugin( g_strPluginName, g_strPluginVersion, g_strPluginAuthor );
	register_cvar( g_strPluginName, g_strPluginVersion, FCVAR_SERVER | FCVAR_EXTDLL | FCVAR_UNLOGGED | FCVAR_SPONLY );
	register_dictionary( "UltimateAdmin.txt" );
	
	/* Pcvars */
	g_pcvarPluginPrefix		= register_cvar( "ua_prefix",		"[UA]" );
	g_pcvarPrintToImmunie		= register_cvar( "ua_print_to_immune",	"1" );
	
	/* Variables */
	g_iUserFlags = read_flags( "z" );
	
	/* Reload cvars for the first time */
	ReloadCvars( );
	
	/* ConCmd */
	register_concmd( "amx_ua_toggle",		"ConCmd_Toggle", ADMIN_ALL );
	register_concmd( "amx_ua_list",			"ConCmd_List" );
	register_concmd( "amx_ua_command",		"ConCmd_Command" );
	
	/* Events */
	register_event( "HLTV",		"Event_HLTV",		"a", "1=0", "2=0" );
}

/* Client Commands */
public client_authorized( iPlayerID ) {
	ClearBit( g_bitIsAnonymous, iPlayerID );
	
	static iFlags;
	iFlags = get_user_flags( iPlayerID );
	g_iInitialFlags[ iPlayerID ] = iFlags;
	
	if( iFlags & ADMIN_IMMUNITY ) 	SetBit( g_bitHasImmunity, 	iPlayerID );
	if( iFlags & ADMIN_RCON ) 	SetBit( g_bitHasRcon, 		iPlayerID );
}

public client_disconnect( iPlayerID ) {
	if( CheckBit( g_bitIsAnonymous, iPlayerID ) ) {
		PrintToImmuneAdmins( iPlayerID, ADMIN_DISCONNECTED );
		
		ClearBit( g_bitIsAnonymous, iPlayerID );
	}
	
	ClearBit( g_bitHasImmunity, 	iPlayerID );
	ClearBit( g_bitHasRcon,		iPlayerID );
}

public client_infochanged( iPlayerID ) {
	if( CheckBit( g_bitIsAnonymous, iPlayerID ) ) {
		remove_user_flags( iPlayerID, g_iInitialFlags[ iPlayerID ] );
		set_user_flags( iPlayerID, g_iUserFlags );
		
		new strPlayerName[ 32 ], strPlayerAuthID[ 36 ];
		get_user_name( iPlayerID, strPlayerName, 31 );
		get_user_authid( iPlayerID, strPlayerAuthID, 35 );
		
		PrintToImmuneAdmins( iPlayerID, ADMIN_NAME_CHANGE );
		log_amx( "Admin %s (%s) is now anonymous after name change.", strPlayerName, strPlayerAuthID );
	}
}

/* ConCmd */
public ConCmd_Toggle( iPlayerID, iLevel, iCid ) {
	if( !CheckBit( g_bitHasRcon, iPlayerID ) ) {
		return PLUGIN_CONTINUE;
	}
	
	new strAdminName[ 32 ], strAdminAuthID[ 36 ];
	get_user_name( iPlayerID, strAdminName, 31 );
	get_user_authid( iPlayerID, strAdminAuthID, 35 );
	
	if( CheckBit( g_bitIsAnonymous, iPlayerID ) ) {
		ClearBit( g_bitIsAnonymous, iPlayerID );
		
		remove_user_flags( iPlayerID, g_iUserFlags );
		set_user_flags( iPlayerID, g_iInitialFlags[ iPlayerID ] );
		
		PrintToImmuneAdmins( iPlayerID, ADMIN_NOT_UNDERCOVER );
		
		console_print( iPlayerID, "%s %L", g_strPluginPrefix, iPlayerID, "ADMIN_ANONYMOUS_NOT" );
		
		log_amx( "Admin %s (%s) is no longer anonymous.", strAdminName, strAdminAuthID );
	} else {
		SetBit( g_bitIsAnonymous, iPlayerID );
		
		remove_user_flags( iPlayerID, g_iInitialFlags[ iPlayerID ] );
		set_user_flags( iPlayerID, g_iUserFlags );
		
		PrintToImmuneAdmins( iPlayerID, ADMIN_IS_UNDERCOVER );
		
		console_print( iPlayerID, "%s %L", g_strPluginPrefix, iPlayerID, "ADMIN_ANONYMOUS" );
		console_print( iPlayerID, "%s %L", g_strPluginPrefix, iPlayerID, "ADMIN_ANONYMOUS_INFO" );
		
		log_amx( "Admin %s (%s) is now an anonymous admin.", strAdminName, strAdminAuthID );
	}
	
	return PLUGIN_HANDLED;
}

public ConCmd_List( iPlayerID, iLevel, iCid ) {
	if( !CheckBit( g_bitHasImmunity, iPlayerID ) ) {
		return PLUGIN_CONTINUE;
	}
	
	console_print( iPlayerID, "%s %L", g_strPluginPrefix, iPlayerID, "LIST_HEADER" );
	
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum );
	
	new strPlayerName[ 32 ], iCount = 0;
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		get_user_name( iTempID, strPlayerName, 31 );
		console_print( iPlayerID, "#%d || %s || %s", get_user_userid( iTempID ), strPlayerName, CheckBit( g_bitIsAnonymous, iTempID ) ? "YES" : "NO" );
		
		if( CheckBit( g_bitIsAnonymous, iTempID ) ) {
			iCount++;
		}
	}
	
	console_print( iPlayerID, "%s %L", g_strPluginPrefix, iPlayerID, "LIST_FOOTER", iCount );
	
	new strAdminName[ 32 ], strAdminAuthID[ 36 ];
	get_user_name( iPlayerID, strAdminName, 31 );
	get_user_authid( iPlayerID, strAdminAuthID, 35 );
	
	log_amx( "Admin %s (%s) requested the list of anonymous admins.", strAdminName, strAdminAuthID );
	
	return PLUGIN_HANDLED;
}

public ConCmd_Command( iPlayerID ) {
	if( !CheckBit( g_bitIsAnonymous, iPlayerID ) ) {
		return PLUGIN_CONTINUE;
	}
	
	new strCommand[ 128 ];
	read_args( strCommand, 127 );
	
	if( is_str_empty( strCommand ) ) {
		console_print( iPlayerID, "Usage: amx_ua_command <command>" );
		
		return PLUGIN_HANDLED;
	}
	
	server_cmd( "%s", strCommand );
	
	console_print( iPlayerID, "%s %L", g_strPluginPrefix, iPlayerID, "COMMAND_SUCCESS" );
	
	PrintToImmuneAdmins( iPlayerID, ADMIN_COMMAND, strCommand );
	
	new strAdminName[ 32 ], strAdminAuthID[ 36 ];
	get_user_name( iPlayerID, strAdminName, 31 );
	get_user_authid( iPlayerID, strAdminAuthID, 35 );
	
	log_amx( "Admin %s (%s) issued to following command: %s.", strAdminName, strAdminAuthID, strCommand );
	
	return PLUGIN_HANDLED;
}

/* Events */
public Event_HLTV( ) {
	ReloadCvars( );
}

/* Other Functions */
ReloadCvars( ) {
	g_iPrintToImmuneAdmins = get_pcvar_num( g_pcvarPrintToImmunie );
	
	get_pcvar_string( g_pcvarPluginPrefix, g_strPluginPrefix, 31 );
}

PrintToImmuneAdmins( iPlayerID, iState, strCommand[ ] = "" ) {
	if( !g_iPrintToImmuneAdmins ) {
		return;
	}
	
	static strPlayerName[ 32 ];
	static iPlayers[ 32 ], iNum, iTempID, iLoop;
	get_players( iPlayers, iNum, "ch" );
	
	for( iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		if( CheckBit( g_bitHasImmunity, iTempID ) ) {
			get_user_name( iPlayerID, strPlayerName, 31 );
		
			switch( iState ) {
				case ADMIN_DISCONNECTED:	client_print( iTempID, print_chat, "%s %L", g_strPluginPrefix, iTempID, "PRINT_DISCONNECTED", strPlayerName );
				case ADMIN_NOT_UNDERCOVER:	client_print( iTempID, print_chat, "%s %L", g_strPluginPrefix, iTempID, "PRINT_NOT_UNDERCOVER", strPlayerName );
				case ADMIN_IS_UNDERCOVER:	client_print( iTempID, print_chat, "%s %L", g_strPluginPrefix, iTempID, "PRINT_IS_UNDERCOVER", strPlayerName );
				case ADMIN_NAME_CHANGE:		client_print( iTempID, print_chat, "%s %L", g_strPluginPrefix, iTempID, "PRINT_NAME_CHANGE", strPlayerName );
				case ADMIN_COMMAND:		client_print( iTempID, print_chat, "%s %L", g_strPluginPrefix, iTempID, "PRINT_COMMAND", strPlayerName, strCommand );
			}
		}
	}
	
	return;
}

/*
	Notepad++ Allied Modders Edition v6.3.1
	Style Configuration:	Default
	Font:			Consolas
	Font size:		10
	Indent Tab:		8 spaces
*/
