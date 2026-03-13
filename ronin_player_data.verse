
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Random }

player_data := class<final><persistable>:
    # Flag to know if it's first time for player playing
    IsPlayerFirstTimePlaying : logic = true 
    # Array of Player's Moxies. 
    PlayerMoxiesArray : []persistent_ronin_creature = array{}
    # Array of Player's Moxie Team 
    PlayerMoxieTeamArray : []persistent_ronin_creature = array{}

    # Unique id generator for the Creatures Owner
    NextOwnerLocalId : int = 1


MakePlayerData<constructor>(Src : player_data)<transacts> := player_data:
    IsPlayerFirstTimePlaying := Src.IsPlayerFirstTimePlaying
    PlayerMoxiesArray := Src.PlayerMoxiesArray
    PlayerMoxieTeamArray := Src.PlayerMoxieTeamArray
    NextOwnerLocalId := Src.NextOwnerLocalId

# -----------------------------------------------------------------------------------------------
var PlayerDataMap:weak_map(player, player_data) = map{}
ronin_player_data := class(creative_device):

    MaxCollectibleId : int = 8000000000

    @editable
    TestButton: button_device = button_device{} 

    OnBegin<override>()<suspends>:void =
        Sleep(0.0)

        # Test Button
        TestButton.InteractedWithEvent.Subscribe(TestFunct)

        # When a player joins the play space, run the OnPlayerJoined method
        GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerJoined)
        for (Player : GetPlayspace().GetPlayers()) {
            OnPlayerJoined(Player)
        }

    # -------------------------------------------------------------------------------------------
    TestFunct(Agent:agent):void = 
        if (Player := player[Agent]):
            ResetPlayerMoxieProgress(Player)
    
    # -------------------------------------------------------------------------------------------
    OnPlayerJoined(Player:player)<transacts>:void =
        # Create player data if it does not exist
        if:
            not PlayerDataMap[Player]
            set PlayerDataMap[Player] = player_data{}

    # -------------------------------------------------------------------------------------------
    # Returns the player data for a given player, or creates a new one if it does not exist
    GetPlayerData(Player:player)<transacts>:player_data =
        if (PlayerData := PlayerDataMap[Player]):
            return PlayerData
        else:
            NewPlayerData := player_data{}
            if (set PlayerDataMap[Player] = NewPlayerData) {}
            Print("Player data created!")
            return NewPlayerData
       
    # -------------------------------------------------------------------------------------------
    # Updates the player data for a given player
    UpdatePlayerData(Player:player, NewData:player_data)<transacts>:void =
        if ( set PlayerDataMap[Player] = NewData ):
            Print("Player data updated!")               
        else:
            Print("Failed to update player data!")
    
    # -------------------------------------------------------------------------------------------
    Update_PlayerMoxiesArray(Player:player, NewMoxiesArray:[]persistent_ronin_creature)<transacts>:void =
        NewData := player_data{
            PlayerMoxiesArray := NewMoxiesArray
            MakePlayerData<constructor>(GetPlayerData(Player))
        }
        Print("Moxie Stored Sucessfully!--------")
        UpdatePlayerData(Player, NewData)

    # -------------------------------------------------------------------------------------------
    Update_PlayerMoxieTeamArray(Player:player, NewMoxiesArray:[]persistent_ronin_creature)<transacts>:void =
        NewData := player_data{
            PlayerMoxieTeamArray := NewMoxiesArray
            MakePlayerData<constructor>(GetPlayerData(Player))
        }
        UpdatePlayerData(Player, NewData)

    # -------------------------------------------------------------------------------------------

    Update_AddNextOwnerLocalId(Player:player, NewValue:int)<transacts>:void =
        PlayerData:= GetPlayerData(Player)
        # Add NewValue to the current value of the Player's NextOwnerLocalId
        NewNextOwnerLocalId := PlayerData.NextOwnerLocalId + NewValue
        NewData := player_data{
            NextOwnerLocalId := NewNextOwnerLocalId #PlayerData.NextOwnerLocalId + NewValue
            MakePlayerData<constructor>(GetPlayerData(Player))
        }
        Print("Local Id Updated to: {NewNextOwnerLocalId}")
        UpdatePlayerData(Player, NewData)
    # -------------------------------------------------------------------------------------------

    # Get the first 6 Moxies of the player
    GetPlayerMoxieTeamPersistent(Player:player)<transacts>:[]ronin_creature =
        Data := GetPlayerData(Player)
        Arr := Data.PlayerMoxiesArray

        var Team:[]ronin_creature = array{}

        for (Idx -> M : Arr):
            if (Team.Length < 6):
                Creature:= FromPersistentCreature(M)
                set Team = Team + array{Creature}

        return Team

    # -------------------------------------------------------------------------------------------

    # Return Creature from Moxie Persisten Data
    FromPersistentCreature(P:persistent_ronin_creature)<transacts>:ronin_creature =
        Creature: ronin_creature = ronin_creature{}
        Creature.InitFromData(P)
        return Creature
    # -------------------------------------------------------------------------------------------

    # Return Moxie Persisten Data from Creature
    ToPersistentCreature(C:ronin_creature)<transacts>:persistent_ronin_creature =
        return persistent_ronin_creature{
            OwnerLocalId := C.OwnerLocalId
            CollectibleId := C.CollectibleId
            Health := C.Health
            Type := C.Type
            Nature := C.Nature
            Level := C.Level
            CurrentXP := C.CurrentXP
            Parts := C.Parts
            AttacksPersistable := C.AttacksPersistable
        }
    # -------------------------------------------------------------------------------------------

    # Find Moxie index by id
    FindPersistentIndexById(Arr:[]persistent_ronin_creature, Id:int)<transacts>:int =
        for (Idx -> P : Arr):
            if (P.OwnerLocalId = Id):
                return Idx
        return -1
    # -------------------------------------------------------------------------------------------

    # Check if a CollectibleId already exists in the player's array (avoid duplicates per player)
    CollectibleIdExists(Arr:[]persistent_ronin_creature, Id:int)<transacts>:logic =
        for (P : Arr):
            if (P.CollectibleId = Id):
                return true
        return false
    # -------------------------------------------------------------------------------------------

    # Generate a CollectibleId in [0..8,000,000,000] that is unique inside THIS player's collection.
    GenerateCollectibleIdForPlayer(Arr:[]persistent_ronin_creature)<transacts>:int =
        Attempts:int = 30
        var Candidate:int = 0

        for (I := 0..Attempts):
            set Candidate = GetRandomInt(0, MaxCollectibleId)
            if (CollectibleIdExists(Arr, Candidate) = false):
                return Candidate

        # Fallback (extremely unlikely to collide repeatedly)
        return Candidate
    # -------------------------------------------------------------------------------------------

    # Ensure the runtime creature has IDs. If not, assign them and persist the counter update.
    EnsureMoxieHasIds(Player:player, C:ronin_creature)<transacts>:void =
        var Data: player_data = GetPlayerData(Player)

        Print("First Local Id: {C.OwnerLocalId}")
        # Assign OwnerLocalId if missing
        if (C.OwnerLocalId < 0):
            Print("Setting a new Local Id")
            NewOwnerId := Data.NextOwnerLocalId
            C.SetLocalId(NewOwnerId)

            # Add 1 to the counter in player data
            Update_AddNextOwnerLocalId(Player, 1)

            # re-read after update
            set Data = GetPlayerData(Player)

        # Assign CollectibleId if missing
        if (C.CollectibleId < 0):
            Print("Setting a new Collectible Id")
            NewCollectible := GenerateCollectibleIdForPlayer(Data.PlayerMoxiesArray)
            C.SetCollectibleId(NewCollectible)
    # -------------------------------------------------------------------------------------------

    # UPSERT: Update if found by OwnerLocalId, else Add.
    UpsertMoxieInPersistentData(Player:player, Updated:ronin_creature)<transacts>:void =
        # Make sure it has both IDs
        EnsureMoxieHasIds(Player, Updated)

        Data := GetPlayerData(Player)
        OldArr := Data.PlayerMoxiesArray

        Idx := FindPersistentIndexById(OldArr, Updated.OwnerLocalId)
        Persisted := ToPersistentCreature(Updated)

        var NewArr:[]persistent_ronin_creature = array{}

        if (Idx = -1):
            # Not found -> Append
            Print("Upserting Moxie - New one. Appending to Player's Persistent Moxie Array")
            set NewArr = OldArr + array{Persisted}
        else:
            # Found -> Replace that element
            Print("Upserting Moxie - Existing one. Updating to Player's Persistent Moxie Array")
            for (I -> P : OldArr):
                if (I = Idx):
                    set NewArr = NewArr + array{Persisted}
                else:
                    set NewArr = NewArr + array{P}

        # Update The Player's Persistent Moxie Array
        Update_PlayerMoxiesArray(Player, NewArr)
        Update_PlayerMoxieTeamArray(Player, NewArr)

        Print("Upserting Moxie - UPSERT OK => Type: {CreatureTypeToString(Persisted.Type)}, Health: {Persisted.Health}")
    # -------------------------------------------------------------------------------------------

    UpdateAllPlayerMoxieTeamData(Player:player, MoxieTeam:[]ronin_creature):void =
        for(Moxie : MoxieTeam):
            UpsertMoxieInPersistentData(Player, Moxie)
    # -------------------------------------------------------------------------------------------

    AddMoxieToPersistentData(Player:player, MoxieToAdd:ronin_creature):void = 
        var PlayerData: player_data = GetPlayerData(Player)
        var UpdatedMoxiesArray: []persistent_ronin_creature = array{}

        var NewMoxie: persistent_ronin_creature = persistent_ronin_creature{
            OwnerLocalId:= MoxieToAdd.OwnerLocalId, CollectibleId:= MoxieToAdd.CollectibleId, Health:=MoxieToAdd.Health, Type:=MoxieToAdd.Type, 
            Nature:=MoxieToAdd.Nature, Level:= MoxieToAdd.Level, CurrentXP:= MoxieToAdd.CurrentXP, Parts:= MoxieToAdd.Parts, AttacksPersistable:= MoxieToAdd.AttacksPersistable}

        set UpdatedMoxiesArray = PlayerData.PlayerMoxiesArray + array{NewMoxie}
        Update_PlayerMoxiesArray(Player, UpdatedMoxiesArray)
    
    # -------------------------------------------------------------------------------------------

    ResetPlayerMoxieProgress(Player:player)<transacts>:void =
        NewData := player_data{
            PlayerMoxiesArray := array{}
            NextOwnerLocalId := 1
            IsPlayerFirstTimePlaying := true
            MakePlayerData<constructor>(GetPlayerData(Player))
        }

        UpdatePlayerData(Player, NewData)
        Print("🧨 FULL RESET: Moxies cleared + NextOwnerLocalId reset to 1 + FirstTime flag true.")

