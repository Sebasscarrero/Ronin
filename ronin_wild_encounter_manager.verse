
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Random }

ronin_wild_moxie_zone := class():
    @editable
    Volumes : []volume_device = array{}
    @editable
    MinDelay : float = 2.0
    @editable
    MaxDelay : float = 5.0
    @editable
    AllowedTypes : []creature_type = array{}

    GetRandomAllowedType(): creature_type =
        Rand:= GetRandomInt(0, AllowedTypes.Length)
        Print("Got random type between {0} and {AllowedTypes.Length}")
        if(RandType:= AllowedTypes[Rand]):
            return RandType
        return creature_type.Bestial
    # -------------------------------------------------------------------------------------------------------------------------------------


ronin_wild_encounter_manager := class(creative_device):

    @editable
    WildZones : []ronin_wild_moxie_zone = array{}

    var PlayerInGrass : [player]logic = map{}
    var PlayerAlreadyInWildBattle : [player]logic = map{}

    @editable
    BattleManager: ronin_battle_system = ronin_battle_system{}

    OnBegin<override>()<suspends>:void=

        for(WildZone : WildZones):
            for(Volume : WildZone.Volumes):
                Volume.AgentEntersEvent.SubscribeAgent(OnWildZoneVolumeEnter, WildZone)
                Volume.AgentExitsEvent.SubscribeAgent(OnWildZoneVolumeExit, WildZone)

    # -------------------------------------------------------------------------------------------------------------------------------------


    OnWildZoneVolumeEnter(Agent:agent, WildMoxieZone:ronin_wild_moxie_zone):void =
        if (Player := player[Agent]):
            #Print("Grass - Player entered to grass!")
            if(set PlayerInGrass[Player] = true){}
            if(set PlayerAlreadyInWildBattle[Player] = false){}
            spawn { CheckSpawnRandMoxie(Player, WildMoxieZone) }
    # -------------------------------------------------------------------------------------------------------------------------------------

    OnWildZoneVolumeExit(Agent:agent, WildMoxieZone:ronin_wild_moxie_zone):void =
        if (Player := player[Agent]):
            #Print("Grass - Player exits grass!")
            if(set PlayerInGrass[Player] = false){}
            if(set PlayerAlreadyInWildBattle[Player] = false){}
    # -------------------------------------------------------------------------------------------------------------------------------------

    CheckSpawnRandMoxie(Player:player, WildMoxieZone:ronin_wild_moxie_zone)<suspends>:void =
        RandDelayToSpawn:= GetRandomFloat(WildMoxieZone.MinDelay, WildMoxieZone.MaxDelay)
        loop:
            Sleep(RandDelayToSpawn)
            if(PlayerAlreadyInWildBattle[Player] = false):
                if(PlayerInGrass[Player] = true):
                    #Print("Grass - Player in grass, Should Start Battle")
                    BattleManager.StartBattleForPlayer(Player, WildMoxieZone.GetRandomAllowedType(), 1)
                    if(set PlayerInGrass[Player] = false){}
                    if(set PlayerAlreadyInWildBattle[Player] = true){}

                else:
                    #Print("Grass - Player not in grass. Should not Start Battle")
                    if(set PlayerInGrass[Player] = false){}
                    break
            else:
                #Print("Player already in a battle. Waiting till that end to look for another one!")

            

    # -------------------------------------------------------------------------------------------------------------------------------------

       