using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Random }

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Creature Types Data
creature_type := enum<persistable>:
    Bestial,
    Bug,
    Winged,
    Aquatic,
    Herbal,
    Reptilian,
    Aurora,
    Zenith,
    Gloam

# Creature Type to String Helper
CreatureTypeToString(Type:creature_type)<transacts>:string =
    case(Type):
        creature_type.Bestial => "Bestial"
        creature_type.Bug => "Bug"
        creature_type.Winged => "Winged"
        creature_type.Aquatic => "Aquatic"
        creature_type.Herbal => "Herbal"
        creature_type.Reptilian => "Reptilian"
        creature_type.Aurora => "Aurora"
        creature_type.Zenith => "Zenith"
        creature_type.Gloam => "Gloam"
        
# Creature Type to String Helper
CreatureTypeToColorIndex(Type:creature_type):float =
    case(Type):
        creature_type.Bestial => 1.0
        creature_type.Bug => 2.0
        creature_type.Winged => 3.0
        creature_type.Aquatic => 4.0
        creature_type.Herbal => 5.0
        creature_type.Reptilian => 6.0
        creature_type.Aurora => 7.0
        creature_type.Zenith => 8.0
        creature_type.Gloam => 9.0

# String to Creature Type Helper
StringToCreatureType(TypeName:string)<transacts>:creature_type =
    case(TypeName):
        "Bestial" => creature_type.Bestial
        "Bug" => creature_type.Bug
        "Winged" => creature_type.Winged
        "Aquatic" => creature_type.Aquatic
        "Herbal" => creature_type.Herbal
        "Reptilian" => creature_type.Reptilian
        "Aurora" => creature_type.Aurora
        "Zenith" => creature_type.Zenith
        "Gloam" => creature_type.Gloam
        _ => creature_type.Bestial


# Base types (no rare classes here)
GetBaseTypes():[]creature_type =
    return array{
        creature_type.Bestial,
        creature_type.Bug,
        creature_type.Winged,
        creature_type.Aquatic,
        creature_type.Herbal,
        creature_type.Reptilian
    }

NatureToString(N:ronin_nature)<transacts>:string =
    case(N):
        ronin_nature.Hardy =>   "Hardy (+HP, -SPD)   "
        ronin_nature.Brave =>   "Brave (+ATK, -SPD)  "
        ronin_nature.Bold =>    "Bold (+DEF, -ATK)   "
        ronin_nature.Calm =>    "Calm (+DEF, -SPD)   "
        ronin_nature.Timid =>   "Timid (+SPD, -ATK)  "
        ronin_nature.Jolly =>   "Jolly (+SPD, -DEF)  "
        ronin_nature.Adamant => "Adamant (+ATK, -DEF)" #20 chars
        ronin_nature.Careful => "Careful (+HP, -ATK) "
        ronin_nature.Neutral => "Neutral             "

# Gene data for a body part
creature_gene := struct<persistable>:
    # D, R1, R2 are variant names (Hunter, Rampage, etc.)
    Dominant: string,
    Recessive1: string,
    Recessive2: string

# 6 body parts: Eyes, Ears, Horn, Mouth, Back, Tail
creature_parts := struct<persistable>:
    Eyes: creature_gene,
    Ears: creature_gene,
    Horn: creature_gene,
    Mouth: creature_gene,
    Back: creature_gene,
    Tail: creature_gene

# Returns a completely random Moxie Type from all 9 types
GetRandomType():creature_type =
    AllAllowedTypes := array{
        creature_type.Bestial,
        creature_type.Bug,
        creature_type.Winged,
        creature_type.Aquatic,
        creature_type.Herbal,
        creature_type.Reptilian
    }

    MaxNum := AllAllowedTypes.Length - 1
    RandomIndex := GetRandomInt(0, MaxNum)

    if (Chosen := AllAllowedTypes[RandomIndex]):
        return Chosen

    # Fallback (should never trigger)
    return creature_type.Bestial

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Creature Attack Sytem Data
ronin_part := enum:
    Eyes,
    Ears,
    Horn,
    Mouth,
    Back,
    Tail

PartToString(P:ronin_part):string =
    case(P):
        ronin_part.Eyes => "Eyes"
        ronin_part.Ears => "Ears"
        ronin_part.Horn => "Horn"
        ronin_part.Mouth => "Mouth"
        ronin_part.Back => "Back"
        ronin_part.Tail => "Tail"

ronin_stat := enum<persistable>:
    Health,
    Attack,
    Defense,
    Speed

StatToString(S:ronin_stat):string =
    case(S):
        ronin_stat.Health => "Health"
        ronin_stat.Attack => "Attack"
        ronin_stat.Defense => "Defense"
        ronin_stat.Speed => "Speed"

ronin_effect_target := enum<persistable>:
    Myself,
    Enemy

EffectTargetToString(T:ronin_effect_target):string =
    case(T):
        ronin_effect_target.Myself => "Self"
        ronin_effect_target.Enemy => "Enemy"

ronin_effect := struct<persistable>:
    Target: ronin_effect_target
    Stat: ronin_stat
    Percent: float
    DurationTurns:int # 0 means "apply now" (we’ll use it as instant for now)

ronin_attack_effectiveness := enum:
    SuperEffective,
    NotEffective, 
    Neutral

# TYPE EFFECTIVENESS (based on the triangle diagram)
GetTypeGroup(T:creature_type):int =
    case(T):
        # Group A
        creature_type.Bestial => 0
        creature_type.Bug => 0
        creature_type.Aurora => 0

        # Group B
        creature_type.Winged => 1
        creature_type.Aquatic => 1
        creature_type.Zenith => 1

        # Group C
        creature_type.Reptilian => 2
        creature_type.Herbal => 2
        creature_type.Gloam => 2



# -------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Creature Nature System Data
ronin_nature := enum<persistable>: # All 8 Natures for the Moxies
    Hardy,      # +HP, -SPD
    Brave,      # +ATK, -SPD
    Bold,       # +DEF, -ATK
    Calm,       # +DEF, -SPD
    Timid,      # +SPD, -ATK
    Jolly,      # +SPD, -DEF
    Adamant,    # +ATK, -DEF
    Careful,    # +HP, -ATK
    Neutral     # Neutral

ronin_stat_mult := struct: # Multipliers for each stat
    Health:float
    Attack:float
    Defense:float
    Speed:float

ronin_base_stats := struct<persistable>: # Base stats
    Health:float
    Attack:float
    Defense:float
    Speed:float

GetNatureMultipliers(N:ronin_nature)<transacts>:ronin_stat_mult =
    case(N):
        ronin_nature.Hardy =>
            return ronin_stat_mult{Health := 1.10, Attack := 1.0, Defense := 1.0, Speed := 0.90}

        ronin_nature.Brave =>
            return ronin_stat_mult{Health := 1.0, Attack := 1.10, Defense := 1.0, Speed := 0.90}

        ronin_nature.Bold =>
            return ronin_stat_mult{Health := 1.0, Attack := 0.90, Defense := 1.10, Speed := 1.0}

        ronin_nature.Calm =>
            return ronin_stat_mult{Health := 1.0, Attack := 1.0, Defense := 1.10, Speed := 0.90}

        ronin_nature.Timid =>
            return ronin_stat_mult{Health := 1.0, Attack := 0.90, Defense := 1.0, Speed := 1.10}

        ronin_nature.Jolly =>
            return ronin_stat_mult{Health := 1.0, Attack := 1.0, Defense := 0.90, Speed := 1.10}

        ronin_nature.Adamant =>
            return ronin_stat_mult{Health := 1.0, Attack := 1.10, Defense := 0.90, Speed := 1.0}

        ronin_nature.Careful =>
            return ronin_stat_mult{Health := 1.10, Attack := 0.90, Defense := 1.0, Speed := 1.0}

        ronin_nature.Neutral =>
            return ronin_stat_mult{Health := 1.0, Attack := 1.0, Defense := 1.0, Speed := 1.0}

# Default baseline Stats (Level 1)
GetDefaultBaseStats()<transacts>:ronin_base_stats =
    return ronin_base_stats{Health := 80.0, Attack := 11.0, Defense := 11.0, Speed := 11.0}

# Per-creature_type offsets (small, balanced)
GetTypeOffsets(T:creature_type)<transacts>:ronin_base_stats =
    case(T):
        # Common Types
        creature_type.Bestial =>
            return ronin_base_stats{Health := 10.0, Attack := 2.0, Defense := 0.0, Speed := 0.0}

        creature_type.Bug =>
            return ronin_base_stats{Health := -5.0, Attack := 0.0, Defense := -1.0, Speed := 2.0}

        creature_type.Winged =>
            return ronin_base_stats{Health := -10.0, Attack := 1.0, Defense := -1.0, Speed := 3.0}

        creature_type.Aquatic =>
            return ronin_base_stats{Health := 15.0, Attack := 0.0, Defense := 2.0, Speed := -1.0}

        creature_type.Herbal =>
            return ronin_base_stats{Health := 5.0, Attack := -1.0, Defense := 2.0, Speed := 0.0}

        creature_type.Reptilian =>
            return ronin_base_stats{Health := 5.0, Attack := 1.0, Defense := 1.0, Speed := -1.0}

        # Rare Types
        creature_type.Aurora =>
            return ronin_base_stats{Health := 5.0, Attack := 1.0, Defense := 1.0, Speed := 1.0}

        creature_type.Zenith =>
            return ronin_base_stats{Health := 0.0, Attack := 3.0, Defense := 0.0, Speed := 1.0}

        creature_type.Gloam =>
            return ronin_base_stats{Health := 15.0, Attack := 1.0, Defense := 2.0, Speed := -1.0}

# Final base stats for the creature at Level 1, before Nature
GetBaseStatsForType(T:creature_type)<transacts>:ronin_base_stats =
    Default := GetDefaultBaseStats()
    Offset := GetTypeOffsets(T)

    return ronin_base_stats{
        Health := Default.Health + Offset.Health,
        Attack := Default.Attack + Offset.Attack,
        Defense := Default.Defense + Offset.Defense,
        Speed := Default.Speed + Offset.Speed
    }

# Level 1	~1000
# Level 2	~2200
# Level 3	~3300
# Level 5	~5200
# Level 10	~11.000
# Level 20	~29.000
# Level 30	~56.000 – 60.000
GetXPToNextLevel(Level:int)<transacts>:float =
    if (Level < 1):
        return 0.0

    # Tuned to match design targets
    BaseXP:float = 800.0
    LinearGrowth:float = 900.0
    QuadraticGrowth:float = 12.0
    ExponentialGrowth:float = 1.015   # very soft

    L := Level * 1.0

    XP :=
        BaseXP
        + (L * LinearGrowth)
        + (L * L * QuadraticGrowth)
        + (Pow(ExponentialGrowth, L) * 50.0)

    NewXP:= BaseXP * L

    return NewXP


GetRandomNature():ronin_nature =
    Options := array{
        ronin_nature.Hardy,
        ronin_nature.Brave,
        ronin_nature.Bold,
        ronin_nature.Calm,
        ronin_nature.Timid,
        ronin_nature.Jolly,
        ronin_nature.Adamant,
        ronin_nature.Careful,
        ronin_nature.Neutral
    }

    MaxIdx := Options.Length - 1
    Idx := GetRandomInt(0, MaxIdx)
    if (Val := Options[Idx]):
        return Val
    return ronin_nature.Neutral


# -------------------------------------------------------------------------------------------------------------------------------------------------------------------

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------
# CREATURE CLASS FOR A SINGLE ONE
ronin_creature:= class:

    var OwnerLocalId : int = -1 # Stable identity within player
    var CollectibleId : int = -1 # Collectible 0 .. 8,000,000,000 

    # Moxie Type
    var Type: creature_type = creature_type.Bestial

    # Nature
    var Nature:ronin_nature = ronin_nature.Neutral

    # Moxie Progression
    var Level:int = 1
    var CurrentXP:float = 0.0
    var XPToLevelUp:float = 0.0

    # Stats design:
    # - Base* are the "raw" stats (growth, leveling, items, etc.)
    # - Final* are what you actually use in battle (Base * Nature multipliers)
    var BaseHealth:float = 80.0
    var BaseAttack:float = 11.0
    var BaseDefense:float = 11.0
    var BaseSpeed:float = 11.0

    var Health:float = 0.0
    var MaxHealth:float = 0.0
    var Attack:float = 0.0
    var Defense:float = 0.0
    var Speed:float = 0.0

    # Moxie Parts
    var Parts: creature_parts = creature_parts{
        Eyes := creature_gene{Dominant := "Eyes_Default", Recessive1 := "Eyes_Default_R1", Recessive2 := "Eyes_Default_R2"},
        Ears := creature_gene{Dominant := "Ears_Default", Recessive1 := "Ears_Default_R1", Recessive2 := "Ears_Default_R2"},
        Horn := creature_gene{Dominant := "Horn_Default", Recessive1 := "Horn_Default_R1", Recessive2 := "Horn_Default_R2"},
        Mouth := creature_gene{Dominant := "Mouth_Default", Recessive1 := "Mouth_Default_R1", Recessive2 := "Mouth_Default_R2"},
        Back := creature_gene{Dominant := "Back_Default", Recessive1 := "Back_Default_R1", Recessive2 := "Back_Default_R2"},
        Tail := creature_gene{Dominant := "Tail_Default", Recessive1 := "Tail_Default_R1", Recessive2 := "Tail_Default_R2"}
    }

    # Id Management
    SetLocalId(NewId:int)<transacts>:void =
        set OwnerLocalId = NewId
    SetCollectibleId(NewId:int)<transacts>:void =
        set CollectibleId = NewId

    Init(InClass:creature_type, InParts:creature_parts):void =
        #set OwnerLocalId = -1
        set Type = InClass
        set Parts = InParts

        # Set level to 1 on creation
        set Level = 1 #GetRandomInt(1,5) #1 GetXPToNextLevel
        set CurrentXP = 0.0
        set XPToLevelUp = GetXPToNextLevel(Level)

        # Random nature on creation
        set Nature = GetRandomNature()

        # Set default stats with Type offsets
        Base := GetBaseStatsForType(Type)
        SetStats(Base.Health, Base.Attack, Base.Defense, Base.Speed)

        # Set randomly 3 attacks
        InitRandomAttacks()

    InitFromData(NewMoxieData:persistent_ronin_creature)<transacts>:void =
        set OwnerLocalId = NewMoxieData.OwnerLocalId
        set CollectibleId = NewMoxieData.CollectibleId

        set Type = NewMoxieData.Type
        set Parts = NewMoxieData.Parts
        set Level = NewMoxieData.Level
        set CurrentXP = NewMoxieData.CurrentXP
        set XPToLevelUp = GetXPToNextLevel(NewMoxieData.Level)
        set Nature = NewMoxieData.Nature

        Base := GetBaseStatsForType(Type)
        SetStats(Base.Health, Base.Attack, Base.Defense, Base.Speed)

        set Health = NewMoxieData.Health


        set AttacksPersistable = NewMoxieData.AttacksPersistable

        # Set randomly 3 attacks
        set Attacks = InitAttacksFromData(AttacksPersistable)

    # Level management
    SetLevel(NewLevel:int):void =
        set Level = ClampIntValues(NewLevel, 50)

    AddLevel(Delta:int):void =
        SetLevel(Level + Delta)

    AddXP(NewXP:float):void =
        set CurrentXP += NewXP

    LevelUp():void =
        AddLevel(1)
        CheckLevelUp()

    CheckLevelUp():void =
        var NewCurrentXP: float = 0.0
        if(CurrentXP >= XPToLevelUp):
            set NewCurrentXP = Abs(CurrentXP - XPToLevelUp)
        set CurrentXP = NewCurrentXP
        set XPToLevelUp = GetXPToNextLevel(Level)


    # SetStats applies Nature multipliers to produce final stats
    # You pass BASE stats, we compute FINAL stats based on Nature.
    SetStats(InBaseHealth:float, InBaseAttack:float, InBaseDefense:float, InBaseSpeed:float)<transacts>:void =
        set BaseHealth = ClampNonNegative(InBaseHealth)
        set BaseAttack = ClampNonNegative(InBaseAttack)
        set BaseDefense = ClampNonNegative(InBaseDefense)
        set BaseSpeed = ClampNonNegative(InBaseSpeed)

        ApplyNatureToFinalStats()

    # Change nature (recomputes final stats from current BASE stats)
    SetNature(NewNature:ronin_nature):void =
        set Nature = NewNature
        ApplyNatureToFinalStats()

    # Modifiers (operate on BASE, then recalc FINAL)
    AddHealth(Delta:float):void =
        set BaseHealth = ClampNonNegative(BaseHealth + Delta)
        ApplyNatureToFinalStats()

    # Set Health after Damage (Battles)
    SetMaxHealth()<transacts>:float =
        Mult := GetNatureMultipliers(Nature)
        LevelMult:= 1.0 + (Level - 1) * 0.05
        NewMaxHealth:= ClampNonNegative(BaseHealth * Mult.Health * LevelMult) 
        Print("Health - Base Health: {BaseHealth}, Health Nat Mult: {Mult.Health}, Lv Mult: {LevelMult}, New Max Health: {NewMaxHealth}")
        return NewMaxHealth

    # Set Health after Damage (Battles)
    SetHealthAfterDamage(NewHealth:float):void =
        set Health = NewHealth

    AddAttack(Delta:float):void =
        set BaseAttack = ClampNonNegative(BaseAttack + Delta)
        ApplyNatureToFinalStats()

    AddDefense(Delta:float):void =
        set BaseDefense = ClampNonNegative(BaseDefense + Delta)
        ApplyNatureToFinalStats()

    AddSpeed(Delta:float):void =
        set BaseSpeed = ClampNonNegative(BaseSpeed + Delta)
        ApplyNatureToFinalStats()

    MultiplyHealth(Mult:float):void =
        set BaseHealth = ClampNonNegative(BaseHealth * Mult)
        ApplyNatureToFinalStats()

    MultiplyAttack(Mult:float):void =
        set BaseAttack = ClampNonNegative(BaseAttack * Mult)
        ApplyNatureToFinalStats()

    MultiplyDefense(Mult:float):void =
        set BaseDefense = ClampNonNegative(BaseDefense * Mult)
        ApplyNatureToFinalStats()

    MultiplySpeed(Mult:float):void =
        set BaseSpeed = ClampNonNegative(BaseSpeed * Mult)
        ApplyNatureToFinalStats()

    ApplyStatDeltas(DeltaHealth:float, DeltaAttack:float, DeltaDefense:float, DeltaSpeed:float):void =
        set BaseHealth = ClampNonNegative(BaseHealth + DeltaHealth)
        set BaseAttack = ClampNonNegative(BaseAttack + DeltaAttack)
        set BaseDefense = ClampNonNegative(BaseDefense + DeltaDefense)
        set BaseSpeed = ClampNonNegative(BaseSpeed + DeltaSpeed)
        ApplyNatureToFinalStats()

    ApplyStatMultipliers(HealthMult:float, AttackMult:float, DefenseMult:float, SpeedMult:float):void =
        set BaseHealth = ClampNonNegative(BaseHealth * HealthMult)
        set BaseAttack = ClampNonNegative(BaseAttack * AttackMult)
        set BaseDefense = ClampNonNegative(BaseDefense * DefenseMult)
        set BaseSpeed = ClampNonNegative(BaseSpeed * SpeedMult)
        ApplyNatureToFinalStats()

    # Attacks (generated from 3 random parts on Init)
    var Attacks:[]ronin_attack = array{} 
    # Attacks Persistable
    var AttacksPersistable:[]ronin_attack_persistable = array{}

    InitRandomAttacks():void =
        SelectedParts := PickRandomUniqueParts(4) # How many attacks do we want?
        var NewAttacks:[]ronin_attack = array{}
        var NewAttacksPersistable:[]ronin_attack_persistable = array{}
    
        for (Idx -> P : SelectedParts):
            set NewAttacks += array{ CreateAttackForPart(P) }
    
        set Attacks = NewAttacks

        # Now save the Attacks in the persistable logic
        for(Att : Attacks):
            NewAttackPers: ronin_attack_persistable = ronin_attack_persistable{
            Type:=Att.Type, Name:=Att.Name, Description:=Att.Description, 
            Damage:= Att.Damage, Effects:= Att.Effects}

            set NewAttacksPersistable += array{ NewAttackPers }
        set AttacksPersistable = NewAttacksPersistable

    InitAttacksFromData(MoxieAttackData:[]ronin_attack_persistable)<transacts>:[]ronin_attack =
        var NewAttacks:[]ronin_attack = array{}

        for (PersAtk : MoxieAttackData):
            Print("Attack - Persistent attack found, creating attack.")
            set NewAttacks += array{ CreateAttackFromData(PersAtk) }

        return NewAttacks

    CreateAttackFromData(Data:ronin_attack_persistable)<transacts>:ronin_attack =
        NewAttack:ronin_attack = ronin_attack{}
        NewAttack.Init(
            Data.Type,
            Data.Name,
            Data.Description,
            Data.Damage,
            Data.Effects
        )
        return NewAttack

    GetPartType(P:ronin_part):creature_type =
        PartTypeName:string =
            case(P):
                ronin_part.Eyes  => GetVariantTypeName(Parts.Eyes.Dominant)
                ronin_part.Ears  => GetVariantTypeName(Parts.Ears.Dominant)
                ronin_part.Horn  => GetVariantTypeName(Parts.Horn.Dominant)
                ronin_part.Mouth => GetVariantTypeName(Parts.Mouth.Dominant)
                ronin_part.Back  => GetVariantTypeName(Parts.Back.Dominant)
                ronin_part.Tail  => GetVariantTypeName(Parts.Tail.Dominant)

        return StringToCreatureType(PartTypeName)

    # ATTACK GENERATION (3 random parts -> 3 attacks)
    PickRandomUniqueParts(Count:int):[]ronin_part =
        All := array{
            ronin_part.Eyes,
            ronin_part.Ears,
            ronin_part.Horn,
            ronin_part.Mouth,
            ronin_part.Back,
            ronin_part.Tail
        }

        var Pool:[]ronin_part = All
        var Result:[]ronin_part = array{}

        # Clamp count
        var Want:int = Count
        if (Want < 0):
            set Want = 0
        if (Want > Pool.Length):
            set Want = Pool.Length

        # Draw without replacement
        for (I := 1..Want):
            MaxIdx := Pool.Length - 1
            Idx := GetRandomInt(0, MaxIdx)

            if (Picked := Pool[Idx]):
                set Result = Result + array{Picked}
                set Pool = RemovePartAtIndex(Pool, Idx)

        return Result

    RemovePartAtIndex(Input:[]ronin_part, RemoveIdx:int):[]ronin_part =
        var Out:[]ronin_part = array{}
        for (Idx -> P : Input):
            if (Idx <> RemoveIdx):
                set Out = Out + array{P}
        return Out

    CreateAttackForPart(P:ronin_part):ronin_attack =
        NewAttack:ronin_attack = ronin_attack{}

        PartType:creature_type = GetPartType(P)
        Def:ronin_attack_def = GetAttackDefinition(P, PartType)

        Desc:string = BuildAttackDesc(Def.Power, Def.Effects)

        NewAttack.Init(
            PartType,
            Def.Name,
            Desc,
            Def.Power,
            Def.Effects
        )

        return NewAttack

    # EFFECT APPLICATION (percent-based, uses your Base* pipeline)
    ApplyPercentToStat(S:ronin_stat, Percent:float):void =
        var Mult: float = 0.0
        set Mult = 1.0 + Percent

        # Prevent weird negatives like -200% nuking stats into negative territory
        if (Mult < 0.0):
            set Mult = 0.0

        case(S):
            ronin_stat.Health => MultiplyHealth(Mult)
            ronin_stat.Attack => MultiplyAttack(Mult)
            ronin_stat.Defense => MultiplyDefense(Mult)
            ronin_stat.Speed => MultiplySpeed(Mult)

    # ---------------------------
    # Internal: compute FINAL stats from BASE * Nature multipliers
    ApplyNatureToFinalStats()<transacts>:void =
        Mult := GetNatureMultipliers(Nature)
        set Health = ClampNonNegative(BaseHealth * Mult.Health) 
        set MaxHealth = SetMaxHealth() #ClampNonNegative(BaseHealth * Mult.Health) 
        set Attack = ClampNonNegative(BaseAttack * Mult.Attack)
        set Defense = ClampNonNegative(BaseDefense * Mult.Defense)
        set Speed = ClampNonNegative(BaseSpeed * Mult.Speed)

    PrintInfo():void =
        Print("Moxie Type: {CreatureTypeToString(Type)}")
        Print("Parts:")
        Print("- Eyes: D[{FormatVariantWithType(Parts.Eyes.Dominant)}]")#, R1[{FormatVariantWithType(Parts.Eyes.Recessive1)}], R2[{FormatVariantWithType(Parts.Eyes.Recessive2)}]")
        Print("- Ears: D[{FormatVariantWithType(Parts.Ears.Dominant)}]")#, R1[{FormatVariantWithType(Parts.Ears.Recessive1)}], R2[{FormatVariantWithType(Parts.Ears.Recessive2)}]")
        Print("- Horn: D[{FormatVariantWithType(Parts.Horn.Dominant)}]")#, R1[{FormatVariantWithType(Parts.Horn.Recessive1)}], R2[{FormatVariantWithType(Parts.Horn.Recessive2)}]")
        Print("- Mouth: D[{FormatVariantWithType(Parts.Mouth.Dominant)}]")#, R1[{FormatVariantWithType(Parts.Mouth.Recessive1)}], R2[{FormatVariantWithType(Parts.Mouth.Recessive2)}]")
        Print("- Back: D[{FormatVariantWithType(Parts.Back.Dominant)}]")#, R1[{FormatVariantWithType(Parts.Back.Recessive1)}], R2[{FormatVariantWithType(Parts.Back.Recessive2)}]")
        Print("- Tail: D[{FormatVariantWithType(Parts.Tail.Dominant)}]")#, R1[{FormatVariantWithType(Parts.Tail.Recessive1)}], R2[{FormatVariantWithType(Parts.Tail.Recessive2)}]")

    PrintDominantParts():void =
        Print("Moxie Type: {CreatureTypeToString(Type)}")
        Print("Dominant Parts:")
        Print("- Eyes: {FormatVariantWithType(Parts.Eyes.Dominant)}")
        Print("- Ears: {FormatVariantWithType(Parts.Ears.Dominant)}")
        Print("- Horn: {FormatVariantWithType(Parts.Horn.Dominant)}")
        Print("- Mouth: {FormatVariantWithType(Parts.Mouth.Dominant)}")
        Print("- Back: {FormatVariantWithType(Parts.Back.Dominant)}")
        Print("- Tail: {FormatVariantWithType(Parts.Tail.Dominant)}")

    # ------------------------------------------------------------------
    PrintStatSummary():void =
        Print(
            "[{CreatureTypeToString(Type)} | {NatureToString(Nature)}] " +
            "BASE(H:{BaseHealth}, A:{BaseAttack}, D:{BaseDefense}, S:{BaseSpeed}) -> " +
            "FINAL(H:{Health}, A:{Attack}, D:{Defense}, S:{Speed})"
        )

    PrintAttacks():void =
        Print("Attacks for {CreatureTypeToString(Type)} ({NatureToString(Nature)}):")
        for (Idx -> A : Attacks):
            Print("  [{Idx}] {A.Name} | DMG:{A.Damage} | Effects:{A.Effects.Length}")


# PERSISTENT CREATURE CLASS FOR A SINGLE ONE
persistent_ronin_creature:= class<final><persistable>:
    OwnerLocalId : int
    CollectibleId : int
    Health: float
    #MaxHealth: float
    Type: creature_type
    Nature: ronin_nature
    Level: int
    CurrentXP: float
    Parts: creature_parts

    AttacksPersistable: []ronin_attack_persistable


# -------------------------------------------------------------------------------------------------------------------------------------------------------------------
# VARIANT DATA & HELPERS

# 5 variants per TYPE (shared for all parts)
GetTypeVariants(Type:creature_type)<transacts>:[]string =
    if (Type = creature_type.Bestial):
        return array{"Hunter", "Rampage", "Berserker", "Juggernaut", "Bloodfang"}

    if (Type = creature_type.Bug):
        return array{"Hiveborn", "Swarmcaller", "Ladydae", "Nectarblade", "Broodling"}

    if (Type = creature_type.Winged):
        return array{"Fierywing", "Featherbound", "Zephyrwing", "Stormcrest", "Cloudbreaker"}

    if (Type = creature_type.Aquatic):
        return array{"Tideborn", "Coralguard", "Abyssal", "Wavebinder", "Deepcurrent"}

    if (Type = creature_type.Herbal):
        return array{"Frutal", "Bloomweaver", "Thornheart", "Verdant", "Rootbound"}

    if (Type = creature_type.Reptilian):
        return array{"Frenzygaze", "Venomscale", "Dunestalker", "Ignifang", "Stoneclad"}

    if (Type = creature_type.Aurora):
        return array{"Prismguard", "Luminborn", "Fluxweaver", "Chromatic", "Radiantforge"}

    if (Type = creature_type.Zenith):
        return array{"Sunborne", "Dawnbreak", "Haloed", "Ascendant", "Goldflare"}

    if (Type = creature_type.Gloam):
        return array{"Voidborn", "Umbral", "Nightveil", "Shadowborne", "Eclipsed"}

    return array{}

# Infer the Moxie Type from a variant name (Hunter, Tempest, Bloomweaver, etc.)
GetVariantTypeName(Variant:string)<transacts>:string =
    # Bestial
    for (Idx -> Name : GetTypeVariants(creature_type.Bestial)):
        if (Variant = Name or Variant = "{Name}_Mut"):
            return CreatureTypeToString(creature_type.Bestial)

    # Bug
    for (Idx -> Name : GetTypeVariants(creature_type.Bug)):
        if (Variant = Name or Variant = "{Name}_Mut"):
            return CreatureTypeToString(creature_type.Bug)

    # Winged
    for (Idx -> Name : GetTypeVariants(creature_type.Winged)):
        if (Variant = Name or Variant = "{Name}_Mut"):
            return CreatureTypeToString(creature_type.Winged)

    # Aquatic
    for (Idx -> Name : GetTypeVariants(creature_type.Aquatic)):
        if (Variant = Name or Variant = "{Name}_Mut"):
            return CreatureTypeToString(creature_type.Aquatic)

    # Herbal
    for (Idx -> Name : GetTypeVariants(creature_type.Herbal)):
        if (Variant = Name or Variant = "{Name}_Mut"):
            return CreatureTypeToString(creature_type.Herbal)

    # Reptilian
    for (Idx -> Name : GetTypeVariants(creature_type.Reptilian)):
        if (Variant = Name or Variant = "{Name}_Mut"):
            return CreatureTypeToString(creature_type.Reptilian)

    # Aurora
    for (Idx -> Name : GetTypeVariants(creature_type.Aurora)):
        if (Variant = Name or Variant = "{Name}_Mut"):
            return CreatureTypeToString(creature_type.Aurora)

    # Zenith
    for (Idx -> Name : GetTypeVariants(creature_type.Zenith)):
        if (Variant = Name or Variant = "{Name}_Mut"):
            return CreatureTypeToString(creature_type.Zenith)

    # Gloam
    for (Idx -> Name : GetTypeVariants(creature_type.Gloam)):
        if (Variant = Name or Variant = "{Name}_Mut"):
            return CreatureTypeToString(creature_type.Gloam)

    # If we don't recognize it (weird string, debug, etc.)
    return "Unknown"
    

# format a single gene variant. Example: Juggernaut (Bestial)
FormatVariantWithType(Variant:string):string =
    VariantType := GetVariantTypeName(Variant)
    return "{Variant} ({VariantType})"

# Elige un nombre de variante aleatorio para un Type
GetRandomVariantName(Type:creature_type, PartName:string):string =
    Variants := GetTypeVariants(Type)
    if (Variants.Length = 0):
        return "{CreatureTypeToString(Type)}_{PartName}_Default"

    MaxIdx := Variants.Length - 1
    Idx := GetRandomInt(0, MaxIdx)
    if (Val := Variants[Idx]):
        return Val
    return "{CreatureTypeToString(Type)}_{PartName}_Default"

# Crea un gene (D, R1, R2) para un tipo usando SOLO nombres de variante
GenerateVariantGeneForType(PartName:string, Type:creature_type):creature_gene =
    DName := GetRandomVariantName(Type, PartName)
    R1Name := GetRandomVariantName(Type, PartName)
    R2Name := GetRandomVariantName(Type, PartName)

    return creature_gene{
        Dominant := DName,
        Recessive1 := R1Name,
        Recessive2 := R2Name
    }

# Creates a gene where D, R1 and R2 are all the same variant
GenerateFixedGeneForVariant(Variant:string):creature_gene =
    return creature_gene{
        Dominant := Variant,
        Recessive1 := Variant,
        Recessive2 := Variant
    }

# Check if a variant name belongs to a given Moxie Type
IsVariantInType(Type:creature_type, Variant:string)<transacts>:logic =
    Variants := GetTypeVariants(Type)
    for (Idx -> Name : Variants):
        if (Variant = Name or Variant = "{Name}_Mut"):
            return true
    return false

# Returns true if the variant is already in its mutated form: SomeName_Mut
IsMutatedVariant(Variant:string)<transacts>:logic =
    # Bestial
    for (Idx -> Name : GetTypeVariants(creature_type.Bestial)):
        if (Variant = "{Name}_Mut"):
            return true

    # Bug
    for (Idx -> Name : GetTypeVariants(creature_type.Bug)):
        if (Variant = "{Name}_Mut"):
            return true

    # Winged
    for (Idx -> Name : GetTypeVariants(creature_type.Winged)):
        if (Variant = "{Name}_Mut"):
            return true

    # Aquatic
    for (Idx -> Name : GetTypeVariants(creature_type.Aquatic)):
        if (Variant = "{Name}_Mut"):
            return true

    # Herbal
    for (Idx -> Name : GetTypeVariants(creature_type.Herbal)):
        if (Variant = "{Name}_Mut"):
            return true

    # Reptilian
    for (Idx -> Name : GetTypeVariants(creature_type.Reptilian)):
        if (Variant = "{Name}_Mut"):
            return true

    # Aurora
    for (Idx -> Name : GetTypeVariants(creature_type.Aurora)):
        if (Variant = "{Name}_Mut"):
            return true

    # Zenith
    for (Idx -> Name : GetTypeVariants(creature_type.Zenith)):
        if (Variant = "{Name}_Mut"):
            return true

    # Gloam
    for (Idx -> Name : GetTypeVariants(creature_type.Gloam)):
        if (Variant = "{Name}_Mut"):
            return true

    return false



# -------------------------------------------------------------------------------------------------------------------------------------------------------------------
# BREEDING LOGIC

# Inherit one allele (string) from two parent genes
InheritAllele(GeneA:creature_gene, GeneB:creature_gene, MutationChance:float):string =
    Options := array{
        GeneA.Dominant,
        GeneA.Recessive1,
        GeneA.Recessive2,
        GeneB.Dominant,
        GeneB.Recessive1,
        GeneB.Recessive2
    }

    Weights := array{ 6, 3, 1, 6, 3, 1 }

    Base := WeightedChooseString(Options, Weights)

    if (GetRandomFloat(0.0, 1.0) < MutationChance and IsMutatedVariant(Base) = false):
        return "{Base}_Mut"

    return Base

WeightedChooseString(Options:[]string, Weights:[]int):string =
    if (Options.Length = 0): 
        return ""

    var Total:int = 0
    for (Idx -> W : Weights):
        set Total += W

    Roll := GetRandomInt(1, Total)

    var Acc:int = 0
    for (Idx -> W : Weights):
        set Acc += W
        if (Roll <= Acc):
            if (Val := Options[Idx]):
                return Val

    if (First := Options[0]):
        return First
    return ""

BreedGene(PartA:creature_gene, PartB:creature_gene, MutationChance:float):creature_gene =
    NewD := InheritAllele(PartA, PartB, MutationChance)
    NewR1 := InheritAllele(PartA, PartB, MutationChance)
    NewR2 := InheritAllele(PartA, PartB, MutationChance)

    return creature_gene{
        Dominant := NewD,
        Recessive1 := NewR1,
        Recessive2 := NewR2
    }

BreedParts(PartsA:creature_parts, PartsB:creature_parts, MutationChance:float):creature_parts =
    return creature_parts{
        Eyes := BreedGene(PartsA.Eyes, PartsB.Eyes, MutationChance),
        Ears := BreedGene(PartsA.Ears, PartsB.Ears, MutationChance),
        Horn := BreedGene(PartsA.Horn, PartsB.Horn, MutationChance),
        Mouth := BreedGene(PartsA.Mouth, PartsB.Mouth, MutationChance),
        Back := BreedGene(PartsA.Back, PartsB.Back, MutationChance),
        Tail := BreedGene(PartsA.Tail, PartsB.Tail, MutationChance)
    }

DetermineChildClass(ClassA:creature_type, ClassB:creature_type):creature_type =
    if (ClassA = ClassB):
        return ClassA

    # If Parents are Bestial and Bug, we have a chance to get an Aurora Moxie
    if:
        (ClassA = creature_type.Bestial and ClassB = creature_type.Bug) or
        (ClassA = creature_type.Bug and ClassB = creature_type.Bestial)
    then:
        if (GetRandomFloat(0.0, 1.0) < 0.3 ):
            return creature_type.Aurora

    # If Parents are Winged and Aquatic, we have a chance to get an Zenith Moxie
    if:
        (ClassA = creature_type.Winged and ClassB = creature_type.Aquatic) or
        (ClassA = creature_type.Aquatic and ClassB = creature_type.Winged)
    then:
        if (GetRandomFloat(0.0, 1.0) < 0.3 ):
            return creature_type.Zenith

    # If Parents are Reptilian and Herbal, we have a chance to get an Aurora Moxie
    if:
        (ClassA = creature_type.Reptilian and ClassB = creature_type.Herbal) or
        (ClassA = creature_type.Herbal and ClassB = creature_type.Reptilian)
    then:
        if (GetRandomFloat(0.0, 1.0) < 0.3 ):
            return creature_type.Gloam

    if (GetRandomInt(0, 1) = 0):
        return ClassA
    else:
        return ClassB

# Decide child class based on its dominant genes
DetermineChildClassFromGenes(Parts:creature_parts, ClassA:creature_type, ClassB:creature_type):creature_type =
    # 1) Collect all dominant variants from the body parts
    DominantVariants := array{
        Parts.Eyes.Dominant,
        Parts.Ears.Dominant,
        Parts.Horn.Dominant,
        Parts.Mouth.Dominant,
        Parts.Back.Dominant,
        Parts.Tail.Dominant
    }

    # 2) Count how many times each TYPE appears in those dominant variants
    var BestialCount:int = 0
    var BugCount:int = 0
    var WingedCount:int = 0
    var AquaticCount:int = 0
    var HerbalCount:int = 0
    var ReptilianCount:int = 0
    var AuroraCount:int = 0
    var ZenithCount:int = 0
    var GloamCount:int = 0

    for (Idx -> Variant : DominantVariants):
        # For each variant, find which Type it belongs to and increment that counter
        if (IsVariantInType(creature_type.Bestial, Variant)?):
            set BestialCount += 1
        else if (IsVariantInType(creature_type.Bug, Variant)?):
            set BugCount += 1
        else if (IsVariantInType(creature_type.Winged, Variant)?):
            set WingedCount += 1
        else if (IsVariantInType(creature_type.Aquatic, Variant)?):
            set AquaticCount += 1
        else if (IsVariantInType(creature_type.Herbal, Variant)?):
            set HerbalCount += 1
        else if (IsVariantInType(creature_type.Reptilian, Variant)?):
            set ReptilianCount += 1
        else if (IsVariantInType(creature_type.Aurora, Variant)?):
            set AuroraCount += 1
        else if (IsVariantInType(creature_type.Zenith, Variant)?):
            set ZenithCount += 1
        else if (IsVariantInType(creature_type.Gloam, Variant)?):
            set GloamCount += 1
        else:
            Print("Unknown variant name: ignore it for counting")

    # 3) Store types and counts in arrays so we can find the max
    Types := array{
        creature_type.Bestial,
        creature_type.Bug,
        creature_type.Winged,
        creature_type.Aquatic,
        creature_type.Herbal,
        creature_type.Reptilian,
        creature_type.Aurora,
        creature_type.Zenith,
        creature_type.Gloam
    }

    Counts := array{
        BestialCount,
        BugCount,
        WingedCount,
        AquaticCount,
        HerbalCount,
        ReptilianCount,
        AuroraCount,
        ZenithCount,
        GloamCount
    }

    # 4) Find the maximum count
    var MaxCount:int = 0
    for (Idx -> C : Counts):
        if (C > MaxCount):
            set MaxCount = C

    # If no type got any vote (MaxCount == 0), fall back to parent-based logic
    if (MaxCount = 0):
        return DetermineChildClass(ClassA, ClassB)

    # 5) Collect all Types that tie for MaxCount
    var TiedTypes:[]creature_type = array{}
    for (Idx -> C : Counts):
        if (C = MaxCount):
            if (MaybeType := Types[Idx]):
                set TiedTypes = TiedTypes + array{MaybeType}

    # 6) If only one winner, return it
    if (TiedTypes.Length = 1):
        if (OnlyType := TiedTypes[0]):
            return OnlyType

    # 7) If several types are tied, pick one at random among them
    MaxIdx := TiedTypes.Length - 1
    RandIdx := GetRandomInt(0, MaxIdx)
    if (Chosen := TiedTypes[RandIdx]):
        return Chosen

    # Final fallback (should basically never hit)
    return DetermineChildClass(ClassA, ClassB)


WeightedChooseType(Options:[]creature_type, Weights:[]int):creature_type =
    if (Options.Length = 0):
        return creature_type.Bestial

    var Total:int = 0
    for (Idx -> W : Weights):
        set Total += W

    Roll := GetRandomInt(1, Total)

    var Acc:int = 0
    for (Idx -> W : Weights):
        set Acc += W
        if (Roll <= Acc):
            if (Val := Options[Idx]):
                return Val

    if (First := Options[0]):
        return First
    return creature_type.Bestial

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Attack Sytem

ronin_attack_def := struct:
        Name: string
        Power: float
        Effects: []ronin_effect

ronin_attack := class:
    var Type: creature_type = creature_type.Bestial
    var Name:string = "Attack"
    var Description:string = ""
    var Damage:float = 0.0
    var Effects:[]ronin_effect = array{}

    Init(InType:creature_type, InName:string, InDesc:string, InDamage:float, InEffects:[]ronin_effect)<transacts>:void =
        set Type = InType
        set Name = InName
        set Description = InDesc
        set Damage = InDamage
        set Effects = InEffects

    PrintSummary():void =
        Print("Attack: {Name} | DMG:{Damage} | Effects:{Effects.Length}")

ronin_attack_persistable := class<final><persistable>:
    Type:creature_type
    Name:string
    Description:string
    Damage:float
    Effects:[]ronin_effect

GetTypeEffectivenessMultiplier(AttackType : creature_type, DefendType : creature_type) : float =
    AttGroup := GetTypeGroup(AttackType)
    DefGroup := GetTypeGroup(DefendType)
    
    # Same group = neutral
    if (AttGroup = DefGroup):
        Print("Attack was neutral! {CreatureTypeToString(AttackType)} to {CreatureTypeToString(DefendType)}")
        return 1.0
    
    # Diagram cycle:
    # Group A: Bestial, Bug, Aurora
    # Group B: Winged, Aquatic, Zenith
    # Group C: Reptilian, Herbal, Gloam
    # A(0) -> B(1) super
    # B(1) -> C(2) super
    # C(2) -> A(0) super
    if (Mod[AttGroup + 1, 3] = DefGroup):
        Print("Attack was super effective! {CreatureTypeToString(AttackType)} to {CreatureTypeToString(DefendType)}")
        return 2.0
    
    # Reverse direction = not very effective
    if (Mod[DefGroup + 1, 3] = AttGroup):
        Print("Attack was not very effective! {CreatureTypeToString(AttackType)} to {CreatureTypeToString(DefendType)}")
        return 0.5
    
    return 1.0

MakeEffect(Target:ronin_effect_target, Stat:ronin_stat, Percent:float):ronin_effect =
    return ronin_effect{
        Target := Target,
        Stat := Stat,
        Percent := Percent,
        DurationTurns := 0
    }

BuildAttackDesc(Power:float, Effects:[]ronin_effect):string =
    # Description style:
    # Base Damage: 34
    # +15% Self ATK
    # -10% Enemy DEF

    # For setup moves (Power <= 0): show ONLY effects.
    # For damage moves: show base damage first, then effects.
    var Out:string = ""

    if (Power > 0.0):
        set Out = "Base Damage: {FormatFloatTo1DecimalString(Power)}"
        if(Effects.Length <= 0):
            set Out = "Base Damage: {FormatFloatTo1DecimalString(Power)}\n"

    for (E : Effects):
        TargetText:string = if (E.Target = ronin_effect_target.Myself) then "Self" else "Enemy"
        StatText:string = StatToString(E.Stat)

        # Convert 0.15 => 15
        PctInt:int = if (IntVal := Int[Abs(E.Percent) * 100.0]) then IntVal else 0
        Dir:string = if (E.Percent >= 0.0) then "+" else "-"

        Line:string = "{Dir}{PctInt}% {TargetText} {StatText}"

        if (Out = ""):
            set Out = "{Line}\n"
        else:
            set Out = "{Out}\n{Line}"

    return Out

GetAttackDefinition(P:ronin_part, T:creature_type):ronin_attack_def =
    case(P):

        # =======================
        # EYES (mix)
        # =======================
        ronin_part.Eyes =>
            case(T):
                creature_type.Bestial   => return ronin_attack_def{Name := "Predator Focus", Power := 28.0, Effects := array{ MakeEffect(ronin_effect_target.Enemy, ronin_stat.Defense, -0.15) } }
                creature_type.Bug       => return ronin_attack_def{Name := "Compound Read",  Power := 22.0, Effects := array{ MakeEffect(ronin_effect_target.Enemy, ronin_stat.Speed,   -0.15) } }
                creature_type.Winged    => return ronin_attack_def{Name := "Skyline Glint",  Power := 26.0, Effects := array{} }
                creature_type.Aquatic   => return ronin_attack_def{Name := "Deep Stare",     Power := 24.0, Effects := array{ MakeEffect(ronin_effect_target.Enemy, ronin_stat.Attack,  -0.15) } }
                creature_type.Herbal    => return ronin_attack_def{Name := "Pollen Haze",    Power := 20.0, Effects := array{
                                                    MakeEffect(ronin_effect_target.Enemy, ronin_stat.Attack, -0.10),
                                                    MakeEffect(ronin_effect_target.Enemy, ronin_stat.Speed,  -0.10)} }
                creature_type.Reptilian => return ronin_attack_def{Name := "Cold Lock",      Power := 30.0, Effects := array{} }
                creature_type.Aurora    => return ronin_attack_def{Name := "Prismatic Tell", Power := 24.0, Effects := array{} }
                creature_type.Zenith    => return ronin_attack_def{Name := "Solar Aim",      Power := 32.0, Effects := array{} }
                creature_type.Gloam     => return ronin_attack_def{Name := "Dusk Pressure",  Power := 0.0,  Effects := array{ MakeEffect(ronin_effect_target.Enemy, ronin_stat.Attack, -0.20) } }

        # =======================
        # EARS (support/tempo)
        # =======================
        ronin_part.Ears =>
            case(T):
                creature_type.Bestial   => return ronin_attack_def{Name := "War Howl",        Power := 0.0,  Effects := array{ MakeEffect(ronin_effect_target.Myself, ronin_stat.Attack,  0.20) } }
                creature_type.Bug       => return ronin_attack_def{Name := "Buzz Tempo",      Power := 0.0,  Effects := array{ MakeEffect(ronin_effect_target.Myself, ronin_stat.Speed,   0.25) } }
                creature_type.Winged    => return ronin_attack_def{Name := "Wind Cadence",    Power := 16.0, Effects := array{} }
                creature_type.Aquatic   => return ronin_attack_def{Name := "Tide Rhythm",     Power := 0.0,  Effects := array{
                                                    MakeEffect(ronin_effect_target.Myself, ronin_stat.Defense, 0.20),
                                                    MakeEffect(ronin_effect_target.Myself, ronin_stat.Attack,  0.10)} }
                creature_type.Herbal    => return ronin_attack_def{Name := "Soothing Whisper",Power := 0.0,  Effects := array{
                                                    MakeEffect(ronin_effect_target.Myself, ronin_stat.Defense, 0.15),
                                                    MakeEffect(ronin_effect_target.Myself, ronin_stat.Speed,   0.15)} }
                creature_type.Reptilian => return ronin_attack_def{Name := "Threat Rattle",   Power := 18.0, Effects := array{ MakeEffect(ronin_effect_target.Enemy, ronin_stat.Attack, -0.15) } }
                creature_type.Aurora    => return ronin_attack_def{Name := "Harmonic Shift",  Power := 20.0, Effects := array{} }
                creature_type.Zenith    => return ronin_attack_def{Name := "Overclock Chant", Power := 22.0, Effects := array{
                                                    MakeEffect(ronin_effect_target.Myself, ronin_stat.Attack,  0.20),
                                                    MakeEffect(ronin_effect_target.Myself, ronin_stat.Defense, -0.10)} }
                creature_type.Gloam     => return ronin_attack_def{Name := "Grave Murmur",    Power := 24.0, Effects := array{ MakeEffect(ronin_effect_target.Enemy, ronin_stat.Speed,  -0.20) } }

        # =======================
        # HORN (burst)
        # =======================
        ronin_part.Horn =>
            case(T):
                creature_type.Bestial   => return ronin_attack_def{Name := "Gore Charge",    Power := 50.0, Effects := array{} }
                creature_type.Bug       => return ronin_attack_def{Name := "Chitin Lance",   Power := 44.0, Effects := array{ MakeEffect(ronin_effect_target.Enemy, ronin_stat.Defense, -0.15) } }
                creature_type.Winged    => return ronin_attack_def{Name := "Dive Pierce",    Power := 48.0, Effects := array{} }
                creature_type.Aquatic   => return ronin_attack_def{Name := "Breaker Tusk",   Power := 42.0, Effects := array{ MakeEffect(ronin_effect_target.Myself, ronin_stat.Defense, 0.10) } }
                creature_type.Herbal    => return ronin_attack_def{Name := "Bramble Thrust", Power := 40.0, Effects := array{} }
                creature_type.Reptilian => return ronin_attack_def{Name := "Scale Splitter", Power := 52.0, Effects := array{
                                                    MakeEffect(ronin_effect_target.Enemy,  ronin_stat.Defense, -0.20),
                                                    MakeEffect(ronin_effect_target.Myself, ronin_stat.Speed,   -0.05)} }
                creature_type.Aurora    => return ronin_attack_def{Name := "Prism Ram",      Power := 46.0, Effects := array{} }
                creature_type.Zenith    => return ronin_attack_def{Name := "Sunspike",       Power := 55.0, Effects := array{ MakeEffect(ronin_effect_target.Myself, ronin_stat.Defense, -0.15) } }
                creature_type.Gloam     => return ronin_attack_def{Name := "Night Impale",   Power := 47.0, Effects := array{} }

        # =======================
        # MOUTH (main DPS)
        # =======================
        ronin_part.Mouth =>
            case(T):
                creature_type.Bestial   => return ronin_attack_def{Name := "Savage Bite",     Power := 40.0, Effects := array{} }
                creature_type.Bug       => return ronin_attack_def{Name := "Mandible Rend",   Power := 34.0, Effects := array{ MakeEffect(ronin_effect_target.Enemy, ronin_stat.Defense, -0.10) } }
                creature_type.Winged    => return ronin_attack_def{Name := "Gale Peck",       Power := 36.0, Effects := array{} }
                creature_type.Aquatic   => return ronin_attack_def{Name := "Reef Crush",      Power := 38.0, Effects := array{} }
                creature_type.Herbal    => return ronin_attack_def{Name := "Vine Chomp",      Power := 32.0, Effects := array{ MakeEffect(ronin_effect_target.Myself, ronin_stat.Defense, 0.15) } }
                creature_type.Reptilian => return ronin_attack_def{Name := "Fang Clamp",      Power := 42.0, Effects := array{ MakeEffect(ronin_effect_target.Enemy, ronin_stat.Speed, -0.15) } }
                creature_type.Aurora    => return ronin_attack_def{Name := "Glitter Fang",   Power := 37.0, Effects := array{} }
                creature_type.Zenith    => return ronin_attack_def{Name := "Solar Maw",      Power := 45.0, Effects := array{} }
                creature_type.Gloam     => return ronin_attack_def{Name := "Dread Bite",     Power := 39.0, Effects := array{} }

        # =======================
        # BACK (defense kit)
        # =======================
        ronin_part.Back =>
            case(T):
                creature_type.Bestial   => return ronin_attack_def{Name := "Iron Pelt",       Power := 0.0,  Effects := array{ MakeEffect(ronin_effect_target.Myself, ronin_stat.Defense, 0.25) } }
                creature_type.Bug       => return ronin_attack_def{Name := "Carapace Up",     Power := 0.0,  Effects := array{
                                                    MakeEffect(ronin_effect_target.Myself, ronin_stat.Defense, 0.30),
                                                    MakeEffect(ronin_effect_target.Myself, ronin_stat.Speed,  -0.05)} }
                creature_type.Winged    => return ronin_attack_def{Name := "Feather Veil",    Power := 14.0, Effects := array{
                                                    MakeEffect(ronin_effect_target.Myself, ronin_stat.Speed,   0.10),
                                                    MakeEffect(ronin_effect_target.Myself, ronin_stat.Defense, 0.10)} }
                creature_type.Aquatic   => return ronin_attack_def{Name := "Shell Brace",     Power := 18.0, Effects := array{
                                                    MakeEffect(ronin_effect_target.Myself, ronin_stat.Defense, 0.20),
                                                    MakeEffect(ronin_effect_target.Enemy,  ronin_stat.Attack, -0.10)} }
                creature_type.Herbal    => return ronin_attack_def{Name := "Barkskin",        Power := 0.0,  Effects := array{
                                                    MakeEffect(ronin_effect_target.Myself, ronin_stat.Defense, 0.25),
                                                    MakeEffect(ronin_effect_target.Myself, ronin_stat.Attack,  0.10)} }
                creature_type.Reptilian => return ronin_attack_def{Name := "Scale Wall",      Power := 22.0, Effects := array{} }
                creature_type.Aurora    => return ronin_attack_def{Name := "Prism Guard",     Power := 0.0,  Effects := array{
                                                    MakeEffect(ronin_effect_target.Myself, ronin_stat.Defense, 0.15),
                                                    MakeEffect(ronin_effect_target.Myself, ronin_stat.Speed,   0.15)} }
                creature_type.Zenith    => return ronin_attack_def{Name := "Heat Shield",     Power := 24.0, Effects := array{} }
                creature_type.Gloam     => return ronin_attack_def{Name := "Umbral Bulwark",  Power := 20.0, Effects := array{
                                                    MakeEffect(ronin_effect_target.Myself, ronin_stat.Defense, 0.20),
                                                    MakeEffect(ronin_effect_target.Enemy,  ronin_stat.Speed,  -0.10)} }

        # =======================
        # TAIL (mostly clean hits)
        # =======================
        ronin_part.Tail =>
            case(T):
                creature_type.Bestial   => return ronin_attack_def{Name := "Savage Sweep",   Power := 30.0, Effects := array{} }
                creature_type.Bug       => return ronin_attack_def{Name := "Stinger Flick",  Power := 26.0, Effects := array{} }
                creature_type.Winged    => return ronin_attack_def{Name := "Gust Lash",      Power := 28.0, Effects := array{} }
                creature_type.Aquatic   => return ronin_attack_def{Name := "Current Whip",   Power := 24.0, Effects := array{} }
                creature_type.Herbal    => return ronin_attack_def{Name := "Thorn Lash",     Power := 22.0, Effects := array{ MakeEffect(ronin_effect_target.Enemy, ronin_stat.Attack, -0.15) } }
                creature_type.Reptilian => return ronin_attack_def{Name := "Rattle Sweep",   Power := 32.0, Effects := array{} }
                creature_type.Aurora    => return ronin_attack_def{Name := "Gleam Sweep",    Power := 27.0, Effects := array{} }
                creature_type.Zenith    => return ronin_attack_def{Name := "Suntrail Cut",   Power := 34.0, Effects := array{} }
                creature_type.Gloam     => return ronin_attack_def{Name := "Shadow Trip",    Power := 20.0, Effects := array{} }


# -------------------------------------------------------------------------------------------------------------------------------------------------------------------
ronin_creature_manager := class(creative_device):

    var CreatureList:[]ronin_creature = array{}

    @editable
    PlayerDataDevice: ronin_player_data = ronin_player_data{}

    @editable
    MaybeBattle1v1: ?ronin_1vs1_battle = false

    # Probabilities for part type selection
    @editable
    FavoredTypeWeight:int = 3    # weight when type == Moxie main Type
    @editable
    OtherTypeWeight:int = 1      # weight for the other normal types

    # Extra array just for this multi-generation test
    var MultiGenChildren:[]ronin_creature = array{}

    # How many cycles of breeding you want to simulate
    @editable
    NumBreedingCycles:int = 30

    # Mutation chance to use in the multi-gen test
    @editable
    MultiGenMutationChance:float = 0.01

    # If true, the test will try to reuse existing creatures as parents
    # If false, it will spawn fresh random parents for the test
    @editable
    UseExistingParentsForMultiGen:logic = false

    @editable
    TestButton: button_device = button_device{} 
    @editable
    TestButton2: button_device = button_device{}

    OnBegin<override>()<suspends>:void=
        TestButton.InteractedWithEvent.Subscribe(TestFunction)
        TestButton2.InteractedWithEvent.Subscribe(TestFunction2)

    TestFunction(Agent: agent): void =
        
        #DebugSpawnPureAndBreed()
        #DebugSpawnPureeAndBreed()
        #spawn{DebugMultiGenerationBreed()}
        #DebugSpawnAndFightOnce()
        if(Player:= player[Agent]):
            #DebugSpawnAndBreed(Player)
            #DebugSpawnCreatureAndStore(Player)
            #spawn{ DebugSpawnAndFightFull(Player) }
            DebugBattle1v1(Player)

    TestFunction2(Agent: agent): void =
        
        #DebugSpawnPureAndBreed()
        #DebugSpawnPureeAndBreed()
        #spawn{DebugMultiGenerationBreed()}
        #DebugSpawnAndFightOnce()
        if(Player:= player[Agent]):
            #DebugSpawnAndBreed(Player)
            #DebugSpawnCreatureAndStore(Player)
            spawn{ DebugSpawnAndFightFull(Player) }
            #DebugBattle1v1(Player)


    # Returns the player's current team as ronin_creature[]
    GetPlayerMoxieTeam(Player:player):[]ronin_creature =
        
        PlayerData := PlayerDataDevice.GetPlayerData(Player)
        var Team:[]ronin_creature = array{}

        # Team is fixed-size (0..5)
        for (Idx := 0..5):
            if (PersistentData := PlayerData.PlayerMoxieTeamArray[Idx]):
                set Team += array{
                    CreateCreatureFromData(PersistentData)
                }
        if(Team.Length > 0):
            Print("Can get Moxies from Player. {Team.Length }")
        else:
            Print("Can NOT get Moxies from Player. {Team.Length }")

        return Team

    # Returns a single Moxie from the player's team by index (0..5)
    GetPlayerMoxieTeamWithIndex(Player:player, Index:int):?ronin_creature = 
        # Hard guard (team max is 6)
        if (Index < 0 or Index > 5):
            Print("Invalid team index: {Index}")
            return false

        PlayerData := PlayerDataDevice.GetPlayerData(Player)

        if (PersistentData := PlayerData.PlayerMoxieTeamArray[Index]):
            Creature := CreateCreatureFromData(PersistentData)
            Print("Got Moxie at index {Index}")
            return option{Creature}

        Print("No Moxie found at index {Index}")
        return false


    

    # Pick a type for a part, biased toward the Moxie main Type
    GetRandomTypeForPart(MainType:creature_type):creature_type =
        BaseTypes := GetBaseTypes()

        var Weights:[]int = array{}
        for (Idx -> T : BaseTypes):
            if (T = MainType):
                set Weights = Weights + array{FavoredTypeWeight}
            else:
                set Weights = Weights + array{OtherTypeWeight}

        return WeightedChooseType(BaseTypes, Weights)

    # All parts use the Moxie Type, only the variant changes
    GenerateRandomParts(Type:creature_type):creature_parts =
        EyesType := GetRandomTypeForPart(Type)
        EarsType := GetRandomTypeForPart(Type)
        HornType := GetRandomTypeForPart(Type)
        MouthType := GetRandomTypeForPart(Type)
        BackType := GetRandomTypeForPart(Type)
        TailType := GetRandomTypeForPart(Type)

        return creature_parts{
            Eyes := GenerateVariantGeneForType("Eyes", EyesType),
            Ears := GenerateVariantGeneForType("Ears", EarsType),
            Horn := GenerateVariantGeneForType("Horn", HornType),
            Mouth := GenerateVariantGeneForType("Mouth", MouthType),
            Back := GenerateVariantGeneForType("Back", BackType),
            Tail := GenerateVariantGeneForType("Tail", TailType)
        }

    # All 6 parts are same Type, but variants can differ
    GeneratePureParts(Type:creature_type):creature_parts =
        return creature_parts{
            Eyes := GenerateVariantGeneForType("Eyes", Type),
            Ears := GenerateVariantGeneForType("Ears", Type),
            Horn := GenerateVariantGeneForType("Horn", Type),
            Mouth := GenerateVariantGeneForType("Mouth", Type),
            Back := GenerateVariantGeneForType("Back", Type),
            Tail := GenerateVariantGeneForType("Tail", Type)
        }

    # All 6 parts use the SAME variant name (pure variant Moxie)
    GeneratePartsWithVariant(Type:creature_type, Variant:string):creature_parts =
        return creature_parts{
            Eyes := GenerateFixedGeneForVariant(Variant),
            Ears := GenerateFixedGeneForVariant(Variant),
            Horn := GenerateFixedGeneForVariant(Variant),
            Mouth := GenerateFixedGeneForVariant(Variant),
            Back := GenerateFixedGeneForVariant(Variant),
            Tail := GenerateFixedGeneForVariant(Variant)
        }


    CreateCreature(Type:creature_type):ronin_creature =
        Parts := GenerateRandomParts(Type)
        NewCreature:ronin_creature = ronin_creature{}
        NewCreature.Init(Type, Parts)
        set CreatureList = CreatureList + array{NewCreature}
        return NewCreature

    CreateCreatureFromData(MoxieData:persistent_ronin_creature):ronin_creature =
        NewCreature:ronin_creature = ronin_creature{}
        NewCreature.InitFromData(MoxieData)
        return NewCreature

    CreateAddCreature(Player:player, Type:creature_type):void =
        Parts := GenerateRandomParts(Type) #  GenerateRandomParts GeneratePureParts
        NewCreature:ronin_creature = ronin_creature{}
        NewCreature.Init(Type, Parts)
        PlayerDataDevice.UpsertMoxieInPersistentData(Player, NewCreature)

    # Creates a Pure Creature. Example: Pure Bestial (All parts are Bestial but can be different variant)
    CreatePureCreature(Type:creature_type):ronin_creature =
        Parts := GeneratePureParts(Type)
        NewCreature:ronin_creature = ronin_creature{}
        NewCreature.Init(Type, Parts)
        set CreatureList = CreatureList + array{NewCreature}
        return NewCreature

    # Creates a Pure VariantName Creature. Example: Pure Hunter Bestial (All parts are Bestial Hunter)
    CreatePureCreature(Type:creature_type, Variant:string):ronin_creature =
        if (IsVariantInType(Type, Variant) = false):
            Print("Warning: Variant {Variant} is not defined for Type {CreatureTypeToString(Type)}")
            return EmptyCreature:ronin_creature = ronin_creature{} 

        Parts := GeneratePartsWithVariant(Type, Variant)
        NewCreature:ronin_creature = ronin_creature{}
        NewCreature.Init(Type, Parts)

        set CreatureList = CreatureList + array{NewCreature}
        return NewCreature

    BreedCreature(ParentA:ronin_creature, ParentB:ronin_creature, MutationChance:float):ronin_creature =
        ChildClass := DetermineChildClass(ParentA.Type, ParentB.Type)
        ChildParts := BreedParts(ParentA.Parts, ParentB.Parts, MutationChance)
        Child:ronin_creature = ronin_creature{}
        Child.Init(ChildClass, ChildParts)
        set CreatureList = CreatureList + array{Child}
        return Child

    BreedCreature2(ParentA:ronin_creature, ParentB:ronin_creature, MutationChance:float):ronin_creature =
        ChildParts := BreedParts(ParentA.Parts, ParentB.Parts, MutationChance)
        ChildClass := DetermineChildClassFromGenes(ChildParts, ParentA.Type, ParentB.Type)
        Child:ronin_creature = ronin_creature{}
        Child.Init(ChildClass, ChildParts)
        set CreatureList = CreatureList + array{Child}
        return Child

    DebugSpawnAndBreed(Player:player):void =
        Parent1 := CreateCreature(GetRandomType())
        Parent2 := CreateCreature(GetRandomType())

        Print("Random Parents ----------------")
        Print("Parent 1:")
        Parent1.PrintInfo()
        Parent1.PrintStatSummary()
        Print("Parent 2:")
        Parent2.PrintInfo()
        Parent2.PrintStatSummary()

        Child := BreedCreature(Parent1, Parent2, MultiGenMutationChance)
        Print("Child:")
        Child.PrintInfo()
        Child.PrintStatSummary()
        Child.PrintAttacks()
        PlayerDataDevice.AddMoxieToPersistentData(Player, Child)
        Print("-------------------------------")


    DebugSpawnCreatureAndStore(Player:player):void =
        NewMoxie := CreateCreature(creature_type.Bestial)

        Print("Random Moxie Generated! ----------------")
        NewMoxie.PrintInfo()
        NewMoxie.PrintStatSummary()
        Print("----------------------------------------")
        Print("Storing Moxie Generated! ---------------")
        PlayerDataDevice.AddMoxieToPersistentData(Player, NewMoxie)

    DebugSpawnPureAndBreed():void =
        Parent1 := CreatePureCreature(GetRandomType())
        Parent2 := CreatePureCreature(GetRandomType())

        Print("PURE Parents ----------------")
        Print("Parent 1:")
        Parent1.PrintInfo()
        Print("Parent 2:")
        Parent2.PrintInfo()

        Child := BreedCreature(Parent1, Parent2, MultiGenMutationChance)
        Print("Child:")
        Child.PrintInfo()
        Print("-------------------------------")

    DebugSpawnPureeAndBreed():void =
        Print("PURE X Parents ----------------")
        Parent1 := CreatePureCreature(creature_type.Bestial, "Hunter")
        Parent2 := CreatePureCreature(creature_type.Aquatic, "Coralguard")

       
        Print("Parent 1:")
        Parent1.PrintInfo()
        Print("Parent 2:")
        Parent2.PrintInfo()

        Child := BreedCreature(Parent1, Parent2, MultiGenMutationChance)
        Print("Child:")
        Child.PrintInfo()
        Print("-------------------------------")

    DebugSpawnAndFightOnce():void =
        # 1) Spawn two random creatures
        FighterA : ronin_creature = CreateCreature(GetRandomType())
        FighterB : ronin_creature = CreateCreature(GetRandomType())
    
        Print("===== DEBUG FIGHT (1 RANDOM ATTACK) =====")
    
        Print("Fighter A (Before):")
        FighterA.PrintInfo()
        FighterA.PrintStatSummary()
        FighterA.PrintAttacks()
    
        Print("Fighter B (Before):")
        FighterB.PrintInfo()
        FighterB.PrintStatSummary()
        FighterB.PrintAttacks()
    
        # 2) Start battle (battle HP is separate from creature stats)
        Battle : ronin_1vs1_battle = ronin_1vs1_battle{}
        #Battle.InitBattleWitnRandomMoxie(FighterA, FighterB)
    
        # 3) Decide who attacks first by Speed (tie -> random)
        var AttackerIsA : logic = false
        if (FighterA.Speed > FighterB.Speed):
            set AttackerIsA = true
        else if (FighterB.Speed > FighterA.Speed):
            set AttackerIsA = false
        else:
            set AttackerIsA = logic{GetRandomInt(0, 1) = 0}
    
        Attacker : ronin_creature = if (AttackerIsA?) then FighterA else FighterB
        Defender : ronin_creature = if (AttackerIsA?) then FighterB else FighterA
    
        PrevBattleHPA : float = Battle.CurrentHPA
        PrevBattleHPB : float = Battle.CurrentHPB
    
        PrevAttackerH : float = Attacker.Health
        PrevAttackerA : float = Attacker.Attack
        PrevAttackerD : float = Attacker.Defense
        PrevAttackerS : float = Attacker.Speed
    
        PrevDefenderH : float = Defender.Health
        PrevDefenderA : float = Defender.Attack
        PrevDefenderD : float = Defender.Defense
        PrevDefenderS : float = Defender.Speed
    
        Print("----------------------------------------")
        Print("Turn: {CreatureTypeToString(Attacker.Type)} attacks first (SPD {Attacker.Speed} vs {Defender.Speed})")
    
        # 4) Choose random attack from attacker
        if (Attacker.Attacks.Length = 0):
            Print("ERROR: Attacker has no attacks.")
            return
    
        MaxAtkIdx : int = Attacker.Attacks.Length - 1
        ChosenAtkIdx : int = GetRandomInt(0, MaxAtkIdx)
    
        # Print attack info
        if (ChosenAtk := Attacker.Attacks[ChosenAtkIdx]):
            Print("Chosen Attack: [{ChosenAtkIdx}] {ChosenAtk.Name} | BaseDMG:{ChosenAtk.Damage} | Effects:{ChosenAtk.Effects.Length}")
            Print("Desc: {ChosenAtk.Description}")
    
        # 5) Execute attack
        Battle.ExecuteAttack(AttackerIsA, ChosenAtkIdx)
    
        # 6) Print AFTER values
        Print("----------------------------------------")
        Print("BATTLE HP (Before -> After):")
        Print("  A: {PrevBattleHPA} -> {Battle.CurrentHPA}")
        Print("  B: {PrevBattleHPB} -> {Battle.CurrentHPB}")
    
        Print("STATS (Before -> After)  [NOTE: HP here is STAT HP, battle HP is above]")
        Print("Attacker [{CreatureTypeToString(Attacker.Type)} | {NatureToString(Attacker.Nature)}]:")
        Print("  H: {PrevAttackerH} -> {Attacker.Health} | A: {PrevAttackerA} -> {Attacker.Attack} | D: {PrevAttackerD} -> {Attacker.Defense} | S: {PrevAttackerS} -> {Attacker.Speed}")
    
        Print("Defender [{CreatureTypeToString(Defender.Type)} | {NatureToString(Defender.Nature)}]:")
        Print("  H: {PrevDefenderH} -> {Defender.Health} | A: {PrevDefenderA} -> {Defender.Attack} | D: {PrevDefenderD} -> {Defender.Defense} | S: {PrevDefenderS} -> {Defender.Speed}")
    
        Print("===== END DEBUG FIGHT =====")


    # -------------------------------------------------------------------------------------------------------------------------------------------------------------------
# DEBUG FULL FIGHT (BOTH ATTACK EACH ROUND, ORDER BY SPEED)
# - Each "ROUND" both A and B get a chance to attack.
# - The faster one attacks first each round (tie -> random).
# - Stops immediately if someone hits 0 HP or less

    DebugBattle1v1(Player:player):void =
        MoxieDebug := CreateCreature(creature_type.Bestial) #CreatePureCreature(creature_type.Bestial)
        PlayerDataDevice.AddMoxieToPersistentData(Player, MoxieDebug)

        Data:= PlayerDataDevice.GetPlayerData(Player)
        if(FirstMoxieData:= Data.PlayerMoxiesArray[0]):
            PlayerMoxie:ronin_creature = ronin_creature{}
            PlayerMoxie.InitFromData(FirstMoxieData)

            EnemyMoxie:ronin_creature = CreateCreature(GetRandomType()) #CreateCreature(GetRandomType())

            if(Battle1v1:= MaybeBattle1v1?):
                Battle1v1.InitBattleWitnRandomMoxie(Player, MoxieDebug, EnemyMoxie)
                MoxieDebug.PrintInfo()
                MoxieDebug.PrintStatSummary()
                MoxieDebug.PrintAttacks()

                EnemyMoxie.PrintInfo()
                EnemyMoxie.PrintStatSummary()
                EnemyMoxie.PrintAttacks()
                #Battle1v1.CreateBattle1vs1Canvas(Player)

    DebugSpawnAndFightFull(Player:player)<suspends>:void =
        # 1) Spawn two random creatures
        FighterA:ronin_creature = CreateCreature(GetRandomType())
        FighterB:ronin_creature = CreateCreature(GetRandomType())

        PlayerDataDevice.AddMoxieToPersistentData(Player, FighterA)

        Print("===== DEBUG FULL FIGHT (BOTH ATTACK PER ROUND, SPEED ORDER) =====")

        Print("Fighter A (Start):")
        FighterA.PrintInfo()
        FighterA.PrintStatSummary()
        FighterA.PrintAttacks()

        Print("Fighter B (Start):")
        FighterB.PrintInfo()
        FighterB.PrintStatSummary()
        FighterB.PrintAttacks()

        # 2) Set up battle
        Battle:ronin_1vs1_battle = ronin_1vs1_battle{}
        Battle.InitBattleWitnRandomMoxie(Player, FighterA, FighterB)
        Battle.CreateBattle1vs1Canvas(Player)

        var BattleRound:int = 1
        var SafetyMaxRounds:int = 200

        loop:
            if (Battle.IsOver[] or BattleRound > SafetyMaxRounds):
                break

            Print("=========== ROUND {BattleRound} ===========")

            # Decide who goes first THIS ROUND based on current speed (effects can change speed)
            var FirstIsA:logic = false
            if (FighterA.Speed > FighterB.Speed):
                set FirstIsA = true
            else if (FighterB.Speed > FighterA.Speed):
                set FirstIsA = false
            else:
                set FirstIsA = logic{GetRandomInt(0, 1) = 0}

            Print("Turn order: {if(FirstIsA?) then "A then B" else "B then A"} (SPD A:{FighterA.Speed} vs B:{FighterB.Speed})")
            Print("----------------------------------------")

            # Execute first attack
            ExecuteDebugAttack(Battle, FighterA, FighterB, FirstIsA)

            # If first attack ended battle, stop (prevents dead creature from attacking)
            if (Battle.IsOver[]):
                break

            # Execute second attack (the other creature)
            #ExecuteDebugAttack(Battle, FighterA, FighterB, not FirstIsA)
            if(FirstIsA = true):
                ExecuteDebugAttack(Battle, FighterA, FighterB, false)
            else:  
                ExecuteDebugAttack(Battle, FighterA, FighterB, true)

            Print("=========== END ROUND {BattleRound} ===========")
            Print("")

            set BattleRound += 1
            Sleep(3.0)

        # End result
        if (BattleRound > SafetyMaxRounds):
            Print("===== DEBUG FULL FIGHT ENDED (SAFETY MAX ROUNDS HIT) =====")
            Print("Final battle HP: A:{Battle.CurrentHPA} B:{Battle.CurrentHPB}")
            return

        var Winner:string = "None (Double KO?)"
        var WinnerType:string = "None (Double KO?)"
        if (Battle.CurrentHPA > 0.0 and Battle.CurrentHPB <= 0.0):
            set Winner = "A"
            set WinnerType = CreatureTypeToString(FighterA.Type)
        else if (Battle.CurrentHPB > 0.0 and Battle.CurrentHPA <= 0.0):
            set Winner = "B"
            set WinnerType = CreatureTypeToString(FighterB.Type)

        Print("===== DEBUG FULL FIGHT OVER =====")
        Print("Winner: {Winner} - {WinnerType}")
        Print("Final battle HP: A:{Battle.CurrentHPA} B:{Battle.CurrentHPB}")


    # -------------------------------------------------------------------------------------------------------------------------------------------------------------------
    # Helper: executes ONE attack from either A or B with full before/after prints.
    # AttackerIsA = true means A attacks B. false means B attacks A.
    ExecuteDebugAttack(Battle:ronin_1vs1_battle, FighterA:ronin_creature, FighterB:ronin_creature, AttackerIsA:logic):void =
        Attacker:ronin_creature = if (AttackerIsA?) then FighterA else FighterB
        Defender:ronin_creature = if (AttackerIsA?) then FighterB else FighterA

        PrevBattleHPA:float = Battle.CurrentHPA
        PrevBattleHPB:float = Battle.CurrentHPB

        PrevAttackerH:float = Attacker.Health
        PrevAttackerA:float = Attacker.Attack
        PrevAttackerD:float = Attacker.Defense
        PrevAttackerS:float = Attacker.Speed

        PrevDefenderH:float = Defender.Health
        PrevDefenderA:float = Defender.Attack
        PrevDefenderD:float = Defender.Defense
        PrevDefenderS:float = Defender.Speed

        Print("Attacker: {if(AttackerIsA?) then "A" else "B"} [{CreatureTypeToString(Attacker.Type)} | {NatureToString(Attacker.Nature)}]")
        Print("Defender: {if(AttackerIsA?) then "B" else "A"} [{CreatureTypeToString(Defender.Type)} | {NatureToString(Defender.Nature)}]")

        if (Attacker.Attacks.Length = 0):
            Print("ERROR: Attacker has no attacks. Skipping.")
            Print("----------------------------------------")
            return

        MaxAtkIdx:int = Attacker.Attacks.Length - 1
        ChosenAtkIdx:int = GetRandomInt(0, MaxAtkIdx)

        if (ChosenAtk := Attacker.Attacks[ChosenAtkIdx]):
            Print("Chosen Attack: [{ChosenAtkIdx}] {ChosenAtk.Name} | BaseDMG:{ChosenAtk.Damage} | Effects:{ChosenAtk.Effects.Length}")
            Print("Desc: {ChosenAtk.Description}")

        # Execute attack
        Battle.ExecuteAttack(AttackerIsA, ChosenAtkIdx)

        # After results
        Print("BATTLE HP (Before -> After):")
        Print("  A: {PrevBattleHPA} -> {Battle.CurrentHPA}")
        Print("  B: {PrevBattleHPB} -> {Battle.CurrentHPB}")

        Print("STATS (Before -> After)  [NOTE: HP here is STAT HP, battle HP is above]")
        Print("Attacker [{CreatureTypeToString(Attacker.Type)} | {NatureToString(Attacker.Nature)}]:")
        Print("  H: {PrevAttackerH} -> {Attacker.Health} | A: {PrevAttackerA} -> {Attacker.Attack} | D: {PrevAttackerD} -> {Attacker.Defense} | S: {PrevAttackerS} -> {Attacker.Speed}")

        Print("Defender [{CreatureTypeToString(Defender.Type)} | {NatureToString(Defender.Nature)}]:")
        Print("  H: {PrevDefenderH} -> {Defender.Health} | A: {PrevDefenderA} -> {Defender.Attack} | D: {PrevDefenderD} -> {Defender.Defense} | S: {PrevDefenderS} -> {Defender.Speed}")

        Print("----------------------------------------")


    # Multi-generation breeding test:
    # - Start with 2 parents (either random or from CreatureList)
    # - Each cycle:
    #     1) P1 x P2 -> C
    #     2) C x P1 -> C1
    #     3) C x P2 -> C2
    #   Then we set P1 = C1, P2 = C2 and repeat.
    # - All children are stored in MultiGenChildren and printed with Dominant-only info.
    DebugMultiGenerationBreed()<suspends>:void =
        Print("===== Multi-Generation Breeding Test =====")

        var Parent1:ronin_creature = ronin_creature{}
        var Parent2:ronin_creature = ronin_creature{}

        # Decide where to take the initial parents from
        if (UseExistingParentsForMultiGen?):
            # If we have at least 2 Moxies in CreatureList, use them
            if (CreatureList.Length >= 2):
                if (MaybeP1 := CreatureList[0]):
                    set Parent1 = MaybeP1
                if (MaybeP2 := CreatureList[1]):
                    set Parent2 = MaybeP2
            else:
                # Not enough existing Moxies; create two new random ones
                set Parent1 = CreateCreature(creature_type.Bestial) #GetRandomType()
                set Parent2 = CreateCreature(creature_type.Bestial)
        else:
            # Always start with fresh parents for the test
            set Parent1 = CreateCreature(GetRandomType())
            set Parent2 = CreateCreature(GetRandomType())

        Print("Base Parent 1 (P1):")
        Parent1.PrintDominantParts()
        Print("Base Parent 2 (P2):")
        Parent2.PrintDominantParts()
        Print("----------------------------------------------")

        # Clear previous results
        set MultiGenChildren = array{}

        # Chain through multiple generations
        for (Cycle := 1..NumBreedingCycles):
            #Print("---- Cycle {Cycle} ----")

            # Step 1: P1 x P2 -> C
            Child := BreedCreature(Parent1, Parent2, MultiGenMutationChance)
            Print("Child C (P1 x P2):")
            Child.PrintDominantParts()
            set MultiGenChildren = MultiGenChildren + array{Child}
            Print("----------------------------------------------")
            # Step 2: C x P1  (child breeds with Parent1)
            ChildWithP1 := BreedCreature(Child, Parent1, MultiGenMutationChance)
            Print("Child C1 (C x P1):")
            ChildWithP1.PrintDominantParts()
            set MultiGenChildren = MultiGenChildren + array{ChildWithP1}
            Print("----------------------------------------------")
            # Step 3: C x P2  (child breeds with Parent2)
            ChildWithP2 := BreedCreature(Child, Parent2, MultiGenMutationChance)
            Print("Child C2 (C x P2):")
            ChildWithP2.PrintDominantParts()
            set MultiGenChildren = MultiGenChildren + array{ChildWithP2}
            Print("----------------------------------------------")
            # For the next cycle, we treat C1 and C2 as the new parents
            set Parent1 = ChildWithP1
            set Parent2 = ChildWithP2
            Sleep(0.1)
        

        Print("===== End of Multi-Generation Test =====")

