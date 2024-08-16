#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = {
    name = "Admin Stealth",
    author = "Crazy",
    description = "Makes Admins invisible in status, spectator, when they spectate someone and when they join/leave no connection/disconnect message show up",
    version = "1.0",
    url = "https://github.com/CrazyShootin"
};

public void OnPluginStart() {
    HookEvent("player_connect", OnPlayerConnect);
    HookEvent("player_disconnect", OnPlayerDisconnect);
    HookEvent("player_death", OnPlayerDeath);
    HookEvent("player_team", OnPlayerTeam);
    AddCommandListener(CommandListener, "spec_list");
    AddCommandListener(CommandListener, "status");
    AddCommandListener(CommandListener, "status_ip");
    AddCommandListener(CommandListener, "spec_status");
    AddCommandListener(CommandListener, "players");
    AddCommandListener(CommandListener, "who");
    LogMessage("Admin Stealth plugin started");
}

// Suppress connection message
public Action:OnPlayerConnect(Handle:event, const String:name[], bool:dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    LogMessage("Player %d connected", client);

    if (IsValidClient(client) && IsClientAdmin(client)) {
        LogMessage("Admin %d connected and will be made invisible", client);
        ToggleAdminVisibility(client, false);
    }
    return Plugin_Continue;
}

// Suppress disconnection message
public Action:OnPlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    LogMessage("Player %d disconnected", client);

    if (IsValidClient(client) && IsClientAdmin(client)) {
        LogMessage("Admin %d disconnected and will be made visible", client);
        ToggleAdminVisibility(client, true);
    }
    return Plugin_Continue;
}

// Event handler for player death (to handle respawns when one joins spectator from a Team :P)
public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    LogMessage("Player %d died", client);

    if (IsValidClient(client) && IsClientAdmin(client)) {
        LogMessage("Admin %d died and will be made invisible on respawn", client);
        ToggleAdminVisibility(client, false);
    }
    return Plugin_Continue;
}

// Event handler for player team change (to manage spectators)
public Action:OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int team = GetEventInt(event, "team");
    LogMessage("Player %d changed team to %d", client, team);

    if (IsValidClient(client) && IsClientAdmin(client)) {
        if (team == 1) { // Spectator team
            LogMessage("Admin %d joined spectators and will be made invisible", client);
            ToggleAdminVisibility(client, false);
        } else {
            LogMessage("Admin %d joined a team and will be made visible", client);
            ToggleAdminVisibility(client, true);
        }
    }
    return Plugin_Continue;
}

// Function to check if the client is valid
bool:IsValidClient(int client) {
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

// Function to toggle Admin visibility
void ToggleAdminVisibility(int client, bool:visible) {
    if (!IsClientInGame(client)) {
        LogMessage("ToggleAdminVisibility called for client %d who is not in game", client);
        return;
    }

    if (visible) {
        LogMessage("Making client %d visible", client);
        SetEntityRenderMode(client, RENDER_NORMAL);
        SetEntProp(client, Prop_Send, "m_iTeamNum", GetClientTeam(client));
        SetEntProp(client, Prop_Send, "m_iObserverMode", 0); // When client exit spectator mode or if they decide not to join spectate but a team
    } else {
        LogMessage("Making client %d invisible", client);
        SetEntityRenderMode(client, RENDER_NONE);
        SetEntProp(client, Prop_Send, "m_iTeamNum", 0);
        SetEntProp(client, Prop_Send, "m_iObserverMode", 1); // When client joins spectator mode either from when they have joined or from either team
    }
}

// Checks if the client connecting is an Admin and hides their connection if they are one
bool:IsClientAdmin(int client) {                                      // You can find the specific mappings for flags here https://wiki.alliedmods.net/Adding_Admins_(SourceMod)
    bool isAdmin = (GetUserFlagBits(client) & ADMFLAG_GENERIC) != 0; // Examples: (ADMFLAG_GENERIC | ADMFLAG_BAN | ADMFLAG_KICK) or (ADMFLAG_CUSTOM1 | ADMFLAG_CUSTOM2) and so on
    LogMessage("IsClientAdmin called for client %d, result: %b", client, isAdmin);
    return isAdmin;
}

public Action:Event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client <= 0 || !IsClientInGame(client)) {
        return Plugin_Continue;
    }
    // Admin connecting gets their connection message hidden and not broadcasted to other players
    if (IsClientAdmin(client)) {
        dontBroadcast = true;
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

// Command listener to block players from using spectator-related commands
public Action:CommandListener(int client, const String:command[], int argc) {
    if (StrEqual(command, "spec_list") || StrEqual(command, "status") || StrEqual(command, "status_ip") || StrEqual(command, "spec_status") || StrEqual(command, "players") || StrEqual(command, "who")) {
        if (!IsClientAdmin(client)) {
            LogMessage("Non-admin player %d tried to use '%s'", client, command);
            ReplyToCommand(client, "You are not allowed to use this command.");
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}
