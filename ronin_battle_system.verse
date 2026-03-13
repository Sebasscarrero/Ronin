
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }

battle_side := enum:
    A,
    B

BattleSideToString(Side:battle_side)<transacts>:string =
    case(Side):
        battle_side.A => "Side A"
        battle_side.B => "Side B"

# One creature instance in battle.
battler_state := struct:
    Creature : ronin_creature
    # Persists across battles (you will load/save this via your manager)
    #CurrentHP : float
    # Battle-only modifiers (reset each battle)
    AtkMult : float
    DefMult : float
    SpdMult : float

    IsFainted : logic

# A team can be any size (1..6 typical)
team_state := struct:
    Members : []battler_state
    ActiveIndex : int     # which member is currently active (0..Members.Length-1)

battle_action := enum:
    None,
    Fight,
    Items,
    Run,
    Info,
    Switch

battle_input := struct:
    Action: battle_action
    AttackIndex: int        # 0..2 for attacks, -1 if not used
    ItemIndex: int          # 0..N for items, -1 if not used
    SwitchIndex: int

# ____________________________________________________________________________________________________________________________________________________

ronin_battle_core := class:

    var BattleSystemManager: ronin_battle_system = ronin_battle_system{}

    # Configuration
    var TeamSize:int = 1

    # Teams
    var TeamA:team_state = team_state{ Members := array{}, ActiveIndex := 0 }
    var TeamB:team_state = team_state{ Members := array{}, ActiveIndex := 0 }

    # Critic config
    var CritChance : float = 0.12
    var CritMultiplier : float = 1.75

    # Reward config
    var XPRewardPerWildWin:float = 4500.0

    Init(InBattleSystemManager: ronin_battle_system, TeamCreaturesA:[]ronin_creature, TeamCreaturesB:[]ronin_creature, InTeamSize:int):void =
        set BattleSystemManager = InBattleSystemManager
        
        set TeamSize = ClampTeamSize(InTeamSize)

        set TeamA = BuildTeamState(TeamCreaturesA, TeamSize)
        set TeamB = BuildTeamState(TeamCreaturesB, TeamSize)

        FixActiveIndex(battle_side.A)
        FixActiveIndex(battle_side.B)
    # -------------------------------------------------------------------------------------------------------------------------------------

    InitWithHP(TeamCreaturesA:[]ronin_creature, TeamHPsA:[]float, TeamCreaturesB:[]ronin_creature, TeamHPsB:[]float, InTeamSize:int):void =
        set TeamSize = ClampTeamSize(InTeamSize)

        set TeamA = BuildTeamStateWithHP(TeamCreaturesA, TeamHPsA, TeamSize)
        set TeamB = BuildTeamStateWithHP(TeamCreaturesB, TeamHPsB, TeamSize)

        FixActiveIndex(battle_side.A)
        FixActiveIndex(battle_side.B)
    # -------------------------------------------------------------------------------------------------------------------------------------

    ClampTeamSize(InSize:int):int =
        if (InSize < 1):
            return 1
        if (InSize > 6):
            return 6
        return InSize
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetTeamCreatures(Side:battle_side)<transacts>:[]ronin_creature =
        T := GetTeam(Side)
        var Out:[]ronin_creature = array{}
        for (B : T.Members):
            set Out = Out + array{ B.Creature }
        return Out
    # -------------------------------------------------------------------------------------------------------------------------------------

    BuildTeamState(Creatures:[]ronin_creature, MaxSize:int):team_state =
        var OutMembers:[]battler_state = array{}
        var Count:int = 0

        for (C : Creatures, Count < MaxSize):
            set OutMembers = OutMembers + array{
                battler_state{
                    Creature := C,
                    #CurrentHP := C.Health,
                    AtkMult := 1.0,
                    DefMult := 1.0,
                    SpdMult := 1.0,
                    IsFainted := false
                }
            }
            set Count += 1

        return team_state{ Members := OutMembers, ActiveIndex := 0 }
    # -------------------------------------------------------------------------------------------------------------------------------------

    BuildTeamStateWithHP(Creatures:[]ronin_creature, HPs:[]float, MaxSize:int):team_state =
        var OutMembers:[]battler_state = array{}
        var Index:int = 0

        loop:
            if (Index >= Creatures.Length or Index >= MaxSize):
                break

            if (C := Creatures[Index]):
                var StartHP:float = C.Health
                if (Index < HPs.Length):
                    if (HPValue := HPs[Index]):
                        set StartHP = HPValue

                # Clamp HP between 0.0 and base Health
                if (StartHP < 0.0):
                    set StartHP = 0.0
                if (StartHP > C.Health):
                    set StartHP = C.Health

                set OutMembers = OutMembers + array{
                    battler_state{
                    Creature := C,
                    #CurrentHP := StartHP,
                    AtkMult := 1.0,
                    DefMult := 1.0,
                    SpdMult := 1.0,
                    IsFainted := logic{ StartHP <= 0.0 }
                    }
                }
            set Index += 1

        return team_state{ Members := OutMembers, ActiveIndex := 0 }
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetEffectiveAttack(B:battler_state):float =
        return B.Creature.Attack * B.AtkMult
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetEffectiveDefense(B:battler_state):float =
        return B.Creature.Defense * B.DefMult
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetEffectiveSpeed(B:battler_state)<transacts>:float =
        return B.Creature.Speed * B.SpdMult
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetActiveEffectiveSpeed(Side:battle_side)<transacts>:float =
        if (B := GetActiveBattler(Side)?):
            return GetEffectiveSpeed(B)
        return 0.0
    # -------------------------------------------------------------------------------------------------------------------------------------

    FixActiveIndex(Side:battle_side):void =
        if (Side = battle_side.A):
            set TeamA = team_state{
                Members := TeamA.Members,
                ActiveIndex := FindFirstAliveIndex(TeamA)
            }
        else:
            set TeamB = team_state{
                Members := TeamB.Members,
                ActiveIndex := FindFirstAliveIndex(TeamB)
            }
    # -------------------------------------------------------------------------------------------------------------------------------------

    # Decide if a battler is alive
    IsBattlerAlive(B:battler_state):logic =
        return logic{ (not B.IsFainted?) and (B.Creature.Health > 0.0) }
    # -------------------------------------------------------------------------------------------------------------------------------------

    FindFirstAliveIndex(T:team_state):int =
        if (T.Members.Length <= 0):
            return -1
 
        for (Idx -> B : T.Members):
            if (not B.IsFainted? and B.Creature.Health > 0.0):
                return Idx
 
        return -1
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetTeam(Side:battle_side)<transacts>:team_state =
        if (Side = battle_side.A) then TeamA else TeamB
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetTeamHPs(Side:battle_side):[]float =
        T := GetTeam(Side)
        var Out:[]float = array{}
        for (B : T.Members):
            set Out = Out + array{ B.Creature.Health }
        return Out
    # -------------------------------------------------------------------------------------------------------------------------------------

    SetTeam(Side:battle_side, NewTeam:team_state)<transacts>:void =
        if (Side = battle_side.A):
            set TeamA = NewTeam
        else:
            set TeamB = NewTeam
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetActiveBattler(Side:battle_side)<transacts>:?battler_state =
        T := GetTeam(Side)
        if (T.ActiveIndex < 0 or T.ActiveIndex >= T.Members.Length):
            return false
        return option{ T.Members[T.ActiveIndex] }
    # -------------------------------------------------------------------------------------------------------------------------------------

    IsTeamDefeated(Side:battle_side)<decides><transacts>:void =
        T := GetTeam(Side)
        # Fail if any member is NOT fainted and has HP > 0
        for (B : T.Members, not B.IsFainted? and B.Creature.Health > 0.0):
            false?
    # -------------------------------------------------------------------------------------------------------------------------------------
    
    IsOver()<decides><transacts>:void =
        IsTeamDefeated[battle_side.A] or IsTeamDefeated[battle_side.B]
    # -------------------------------------------------------------------------------------------------------------------------------------

    # Writes a battler back into the team at a given index
    SetBattlerAtIndex(Side:battle_side, Index:int, NewBattler:battler_state):void =
        T := GetTeam(Side)
        if (Index < 0 or Index >= T.Members.Length):
            return

        var NewMembers:[]battler_state = array{}
        for (Idx -> B : T.Members):
            if (Idx = Index):
                set NewMembers = NewMembers + array{ NewBattler }
            else:
                set NewMembers = NewMembers + array{ B }

        SetTeam(Side, team_state{ Members := NewMembers, ActiveIndex := T.ActiveIndex })
    # -------------------------------------------------------------------------------------------------------------------------------------

    SetActiveBattler(Side:battle_side, NewBattler:battler_state):void =
        T := GetTeam(Side)
        SetBattlerAtIndex(Side, T.ActiveIndex, NewBattler)
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetAliveIndices(T:team_state)<transacts>:[]int =
        var Out:[]int = array{}
        for (Idx -> B : T.Members):
            if (not B.IsFainted? and B.Creature.Health > 0.0):
                set Out += array{Idx}
        return Out
    # -------------------------------------------------------------------------------------------------------------------------------------

    PickRandomAliveIndex(T:team_state)<transacts>:int =
        Alive := GetAliveIndices(T)
        AliveLength := Alive.Length
        
        if (AliveLength <= 0):
            return -1
        if (AliveLength = 1):
            if (Index := Alive[0]):
                return Index
            return -1
        RandomIndex := GetRandomInt(0, AliveLength - 1)
        if (Index := Alive[RandomIndex]):
            return Index
        return -1
    # -------------------------------------------------------------------------------------------------------------------------------------

    SetXPRewardPerWildWin(NewReward:float):void =
        if (NewReward < 0.0):
            set XPRewardPerWildWin = 0.0
        else:
            set XPRewardPerWildWin = NewReward
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetXPRewardPerWildWin():float =
        return XPRewardPerWildWin
    # -------------------------------------------------------------------------------------------------------------------------------------

    # Returns true if team still has someone alive after the check.
    # OutSwapped becomes true only if a swap happened (active was fainted).
    # Returns:
    #  tuple[0] = Team still alive?
    #  tuple[1] = Did a swap happen?
    AutoSwapRandomIfActiveFainted(Side:battle_side)<transacts>:tuple(logic, logic) =
        var Swapped:logic = false

        T := GetTeam(Side)
        if (T.Members.Length <= 0):
            return (false, false)

        # Validate active index
        if (T.ActiveIndex < 0 or T.ActiveIndex >= T.Members.Length):
            Fixed := PickRandomAliveIndex(T)
            SetTeam(Side, team_state{ Members := T.Members, ActiveIndex := Fixed })
            return (logic{ Fixed <> -1 }, true)

        # Active still alive → no swap
        if (Active := GetActiveBattler(Side)?):
            if (not Active.IsFainted? and Active.Creature.Health > 0.0):
                return (true, false)

        # Active fainted → pick random alive
        NextIdx := PickRandomAliveIndex(T)
        if (NextIdx = -1):
            return (false, false)

        SetTeam(Side, team_state{ Members := T.Members, ActiveIndex := NextIdx })
        set Swapped = true

        return (true, Swapped)
    # -------------------------------------------------------------------------------------------------------------------------------------

    # Apply raw damage to the defender ACTIVE battler (returns actual damage applied)
    ApplyDamageToActive(Player:player, DefenderSide:battle_side, Damage:float):float =
        if (Damage <= 0.0):
            return 0.0
    
        if (Def := GetActiveBattler(DefenderSide)?):
            # Calculate new HP, ensuring it's not negative
            NewHP := ClampNonNegative(Def.Creature.Health - Damage)

            # UPDATE THE MOXIE HEALTH STAT
            Def.Creature.SetHealthAfterDamage(NewHP)

            # Set fainted if HP is 0 or less
            NewFainted := logic{ NewHP <= 0.0 }

            spawn{ BattleSystemManager.AnimateHealthbarDelta(Player, DefenderSide, NewHP, Damage, Def.Creature.MaxHealth) }
    
            # Create a new struct instance (immutable update pattern)
            NewDef := battler_state{
                Creature := Def.Creature,
                #CurrentHP := NewHP,
                AtkMult := Def.AtkMult,
                DefMult := Def.DefMult,
                SpdMult := Def.SpdMult,
                IsFainted := NewFainted
            }
    
            SetActiveBattler(DefenderSide, NewDef)
            return Damage
    
        return 0.0
    # -------------------------------------------------------------------------------------------------------------------------------------

    # If active is fainted, try to switch to next alive.
    # Returns true if switch happened, false if no alive members exist (team defeated)
    AutoSwitchIfNeeded(Side:battle_side):logic =
        T := GetTeam(Side)

        if (T.Members.Length <= 0):
            return false

        # If active index invalid, fix it by setting the team directly (no local reassignment)
        if (T.ActiveIndex < 0 or T.ActiveIndex >= T.Members.Length):
            FixedIdx := FindFirstAliveIndex(T)
            SetTeam(Side, team_state{ Members := T.Members, ActiveIndex := FixedIdx })

        # Re-read after potential fix
        T2 := GetTeam(Side)
        if (T2.ActiveIndex = -1):
            return false

        if (Active := GetActiveBattler(Side)?):
            # If not fainted, no switch needed
            if (not Active.IsFainted? and Active.Creature.Health > 0.0):
                return true

        # Active is fainted -> find next alive index
        NextIdx := FindFirstAliveIndex(T2)
        if (NextIdx = -1):
            return false

        SetTeam(Side, team_state{ Members := T2.Members, ActiveIndex := NextIdx })
        return true
    # -------------------------------------------------------------------------------------------------------------------------------------

    RollCriticalHit(Chance:float):logic =
        R := GetRandomFloat(0.0, 1.0)
        return logic{ R <= Chance }
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetActiveCreature(Side:battle_side)<transacts>:?ronin_creature =
        if (B := GetActiveBattler(Side)?):
            return option{ B.Creature }
        return false
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetCurrentHealthOfActiveMoxieSide(Side:battle_side)<transacts>:float =
        if (B := GetActiveBattler(Side)?):
            return B.Creature.Health
        return 0.0
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetMaxHealthOfActiveMoxieSide(Side:battle_side)<transacts>:float =
        if (B := GetActiveBattler(Side)?):
            return B.Creature.Health
        return 0.0


    # -------------------------------------------------------------------------------------------------------------------------------------

    # DEPRECATED
    # 0 (DidHit), 1 (DamageDealt), 2 (WasCrit), 3 (Attack), 4 (AttackEffectiveness)
    ApplyDamageOnly_Team(AttackerSide:battle_side, DefenderSide:battle_side, AttackIndex:int):tuple(logic, float, logic, ronin_attack, ronin_attack_effectiveness) =

        EmptyAttack:ronin_attack = ronin_attack{}
        EmptyEff:ronin_attack_effectiveness = ronin_attack_effectiveness.Neutral

        if (IsOver[]):
            return (false, 0.0, false, EmptyAttack, EmptyEff)

        AttBattlerOpt := GetActiveBattler(AttackerSide)
        DefBattlerOpt := GetActiveBattler(DefenderSide)

        if (AttBattler := AttBattlerOpt?, DefBattler := DefBattlerOpt?):

            AttCreature := AttBattler.Creature

            if (AttackIndex < 0 or AttackIndex >= AttCreature.Attacks.Length):
                return (false, 0.0, false, EmptyAttack, EmptyEff)

            if (Atk := AttCreature.Attacks[AttackIndex]):

                DmgTuple := ComputeDamageFromBattlers(AttBattler, DefBattler, Atk.Damage, Atk.Type)
                BaseDamage:float = DmgTuple(0)
                Eff:ronin_attack_effectiveness = DmgTuple(1)

                var WasCrit:logic = false
                var FinalDamage:float = BaseDamage

                if (BaseDamage > 0.0):
                    set WasCrit = RollCriticalHit(CritChance)
                    set FinalDamage = if (WasCrit?) then (BaseDamage * CritMultiplier) else BaseDamage

                #Applied:float = ApplyDamageToActive(Player, DefenderSide, FinalDamage)

                # If defender fainted, auto switch to next alive (optional but good)
                #AutoSwitchIfNeeded(DefenderSide)

                return (true, 0.0, WasCrit, Atk, Eff)

        return (false, 0.0, false, EmptyAttack, EmptyEff)
    # -------------------------------------------------------------------------------------------------------------------------------------

    # 0 (DidHit), 1 (DamageDealt), 2 (WasCrit), 3 (Attack), 4 (AttackEffectiveness)
    ApplyDamageOnly(Player:player, AttackerSide:battle_side, DefenderSide:battle_side, AttackIndex:int):tuple(logic, float, logic, ronin_attack, ronin_attack_effectiveness) =

        EmptyAttack:ronin_attack = ronin_attack{}
        EmptyEff:ronin_attack_effectiveness = ronin_attack_effectiveness.Neutral

        if (IsOver[]):
            return (false, 0.0, false, EmptyAttack, EmptyEff)

        AttBattlerOpt := GetActiveBattler(AttackerSide)
        DefBattlerOpt := GetActiveBattler(DefenderSide)

        if (AttBattler := AttBattlerOpt?, DefBattler := DefBattlerOpt?):

            AttCreature := AttBattler.Creature

            if (AttackIndex < 0 or AttackIndex >= AttCreature.Attacks.Length):
                return (false, 0.0, false, EmptyAttack, EmptyEff)

            if (Atk := AttCreature.Attacks[AttackIndex]):

                DmgTuple := ComputeDamageFromBattlers(AttBattler, DefBattler, Atk.Damage, Atk.Type)
                BaseDamage:float = DmgTuple(0)
                Eff:ronin_attack_effectiveness = DmgTuple(1)

                var WasCrit:logic = false
                var FinalDamage:float = BaseDamage

                if (BaseDamage > 0.0):
                    set WasCrit = RollCriticalHit(CritChance)
                    set FinalDamage = if (WasCrit?) then (BaseDamage * CritMultiplier) else BaseDamage

                Applied:float = ApplyDamageToActive(Player, DefenderSide, FinalDamage)

                # If defender fainted, auto switch to next alive (optional but good)
                #AutoSwitchIfNeeded(DefenderSide)

                return (true, Applied, WasCrit, Atk, Eff)

        return (false, 0.0, false, EmptyAttack, EmptyEff)


    # -------------------------------------------------------------------------------------------------------------------------------------

    ComputeDamage(Attacker:ronin_creature, Defender:ronin_creature, Power:float, AttackType:creature_type):tuple(float, ronin_attack_effectiveness) =
        # Setup / non-damaging move
        if (Power <= 0.0):
            return (0.0, ronin_attack_effectiveness.Neutral)

        # 1) Level scaling 
        L : float = Attacker.Level * 1.0
        LevelFactor : float = (2.0 * L / 5.0) + 2.0

        # 2) ATK vs DEF ratio
        StatRatio : float = (Attacker.Attack + 6.0) / (Defender.Defense + 10.0)

        # 3) Base damage
        Divider : float = 6.0
        FlatBonus : float = 6.0
        Base : float = ((LevelFactor * Power * StatRatio) / Divider) + FlatBonus

        # 4) Modifiers
        TypeMult : float = GetTypeEffectivenessMultiplier(AttackType, Defender.Type)

        # 5) Same Parts Multiplier 
        SameCount : int = CountSameTypeParts(Attacker)
        SamePartsMult : float = GetSamePartsMultiplier(SameCount)

        # 6) Light randomness
        Rand : float = GetRandomFloat(0.90, 1.00)

        # FINAL RAW DAMAGE VALUE
        Final : float = Base * TypeMult * SamePartsMult * Rand

        var Eff: ronin_attack_effectiveness = ronin_attack_effectiveness.Neutral
        if (TypeMult > 1.0):
            set Eff = ronin_attack_effectiveness.SuperEffective
        else if (TypeMult < 1.0):
            set Eff = ronin_attack_effectiveness.NotEffective

        # Minimum damage if the move deals damage
        if (Final < 1.0):
            return (1.0, Eff)

        return (Final, Eff)
    # -------------------------------------------------------------------------------------------------------------------------------------

    ComputeDamageFromBattlers(AttB:battler_state, DefB:battler_state, Power:float, AttackType:creature_type):tuple(float, ronin_attack_effectiveness) =
        if (Power <= 0.0):
            return (0.0, ronin_attack_effectiveness.Neutral)

        Attacker := AttB.Creature
        Defender := DefB.Creature

        L: float = Attacker.Level * 1.0
        LevelFactor : float = (2.0 * L / 5.0) + 2.0

        AttAtk:float = GetEffectiveAttack(AttB)
        DefDef:float = GetEffectiveDefense(DefB)

        StatRatio : float = (AttAtk + 6.0) / (DefDef + 10.0)

        Divider : float = 6.0
        FlatBonus : float = 6.0
        Base : float = ((LevelFactor * Power * StatRatio) / Divider) + FlatBonus

        TypeMult : float = GetTypeEffectivenessMultiplier(AttackType, Defender.Type)

        SameCount : int = CountSameTypeParts(Attacker)
        SamePartsMult : float = GetSamePartsMultiplier(SameCount)

        Rand : float = GetRandomFloat(0.90, 1.00)

        Final : float = Base * TypeMult * SamePartsMult * Rand

        var Eff: ronin_attack_effectiveness = ronin_attack_effectiveness.Neutral
        if (TypeMult > 1.0):
            set Eff = ronin_attack_effectiveness.SuperEffective
        else if (TypeMult < 1.0):
            set Eff = ronin_attack_effectiveness.NotEffective

        if (Final < 1.0):
            return (1.0, Eff)

        return (Final, Eff)
    # -------------------------------------------------------------------------------------------------------------------------------------


    SideToName(Side:battle_side):string =
        if (Side = battle_side.A) then "Your Moxie" else "Wild Moxie"
    # -------------------------------------------------------------------------------------------------------------------------------------


    # Same “super effective / not effective” text
    EffectivenessToText(Eff:ronin_attack_effectiveness):string =
        if (Eff = ronin_attack_effectiveness.SuperEffective):
            "\nIt's super effective!"
        else if (Eff = ronin_attack_effectiveness.NotEffective):
            "\nIt's not very effective..."
        else:
            ""
    # -------------------------------------------------------------------------------------------------------------------------------------

    # Optional: make crit line consistent
    CritToText(WasCrit:logic):string =
        if (WasCrit?) then "\nA critical hit!" else ""
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetTargetNameForEffect(AttackerSide:battle_side, Target:ronin_effect_target):string =
        if (AttackerSide = battle_side.A):
            if (Target = ronin_effect_target.Myself) then "Your Moxie" else "Wild Moxie"
        else:
            if (Target = ronin_effect_target.Myself) then "Wild Moxie" else "Your Moxie"
    # -------------------------------------------------------------------------------------------------------------------------------------


    EffectToText(E:ronin_effect, AttackerSide:battle_side):string =
        TargetName : string = GetTargetNameForEffect(AttackerSide, E.Target)
        StatName : string = StatToString(E.Stat)
        Dir : string = if (E.Percent < 0.0) then "dropped" else "raised"
        return "{TargetName} {StatName} {Dir}!"
    # -------------------------------------------------------------------------------------------------------------------------------------


    BuildEffectsSummary(Effects:[]ronin_effect, AttackerSide:battle_side):string =
        if (Effects.Length <= 0):
            return ""

        var Out:string = ""
        for (Idx -> E : Effects):
            Line := EffectToText(E, AttackerSide)
            if (Idx = 0):
                set Out = Line
            else:
                set Out = "{Out}\n{Line}"
        return Out
    # -------------------------------------------------------------------------------------------------------------------------------------

    ApplyEffects_Team(AttackerSide:battle_side, DefenderSide:battle_side, Effects:[]ronin_effect):void =
        for (E : Effects):
            TargetSide := 
                if (E.Target = ronin_effect_target.Myself) 
                    then AttackerSide 
                    else DefenderSide

            T := GetTeam(TargetSide)
            # Use failable context for index and member access
            if (T.ActiveIndex >= 0 and T.ActiveIndex < T.Members.Length):
                if (B := T.Members[T.ActiveIndex]):
                    NewB := ApplyEffectToBattler(B, E)
                    SetBattlerAtIndex(TargetSide, T.ActiveIndex, NewB)
    # -------------------------------------------------------------------------------------------------------------------------------------

    ApplyEffect(AttackerSide:battle_side, DefenderSide:battle_side, Effects:[]ronin_effect):void =
        for (E : Effects):
            TargetSide := 
                if (E.Target = ronin_effect_target.Myself) 
                    then AttackerSide 
                    else DefenderSide

            if (B := GetActiveBattler(TargetSide)?):
                NewB := ApplyEffectToBattler(B, E)
                SetActiveBattler(TargetSide, NewB)
    # -------------------------------------------------------------------------------------------------------------------------------------

    #  0.25  = +25%
    # -0.10  = -10%
    GetEffectFactorNormalized(Current:float, Percent:float):float =
        var Factor:float = Current + Percent
        if (Factor < 0.05):
            set Factor = 0.05
        #Print("Get Factor: {Current} + {Percent} = {Factor}")

        return Factor
    # -------------------------------------------------------------------------------------------------------------------------------------

    ApplyEffectToBattler(B:battler_state, E:ronin_effect):battler_state =

        var Factor:float = 0.0

        if (E.Stat = ronin_stat.Attack):
            set Factor = GetEffectFactorNormalized(B.AtkMult, E.Percent)
            #Print("Effect - Attack Effect Applied. Old Factor: {B.AtkMult} | New Factor: {Factor} | Old Value: {B.Creature.Attack * B.AtkMult} | New Value: {B.Creature.Attack * Factor}")
            return battler_state{
                Creature := B.Creature,
                #CurrentHP := B.CurrentHP,
                AtkMult := Factor,
                DefMult := B.DefMult,
                SpdMult := B.SpdMult,
                IsFainted := B.IsFainted
            }
        else if (E.Stat = ronin_stat.Defense):
            set Factor = GetEffectFactorNormalized(B.DefMult, E.Percent)
            #Print("Effect - Defense Effect Applied. Old Factor: {B.DefMult} | New Factor: {Factor} | Old Value: {B.Creature.Defense * B.DefMult} | New Value: {B.Creature.Defense * Factor}")
            return battler_state{
                Creature := B.Creature,
                #CurrentHP := B.CurrentHP,
                AtkMult := B.AtkMult,
                DefMult := Factor,
                SpdMult := B.SpdMult,
                IsFainted := B.IsFainted
            }
        else if (E.Stat = ronin_stat.Speed):
            set Factor = GetEffectFactorNormalized(B.SpdMult, E.Percent)
            #Print("Effect - Speed Effect Applied. Old Factor: {B.SpdMult} | New Factor: {Factor} | Old Value: {B.Creature.Speed * B.SpdMult} | New Value: {B.Creature.Speed * Factor}")
            return battler_state{
                Creature := B.Creature,
                #CurrentHP := B.CurrentHP,
                AtkMult := B.AtkMult,
                DefMult := B.DefMult,
                SpdMult := Factor,
                IsFainted := B.IsFainted
            }

        # Unknown stat => unchanged
        return B
    # -------------------------------------------------------------------------------------------------------------------------------------

    # DEPRECATED
    # 0 (DidHit), 1 (DamageDealt), 2 (WasCrit), 3 (AttackUsed), 4 (Effectiveness), 5 (MainText), 6 (EffectsText)
    DoAttackSequence_Team(AttackerSide:battle_side, DefenderSide:battle_side, AttackIndex:int):tuple(logic,float,logic,ronin_attack,ronin_attack_effectiveness,string,string) =
        Result := ApplyDamageOnly_Team(AttackerSide, DefenderSide, AttackIndex)

        DidHit := Result(0)
        DamageDealt := Result(1)
        WasCrit := Result(2)
        Attack := Result(3)
        Eff := Result(4)

        if (not DidHit?):
            return (false, 0.0, false, ronin_attack{}, ronin_attack_effectiveness.Neutral, "Attack failed.", "")

        AttackerName := SideToName(AttackerSide)
        AttackName := Attack.Name

        DamageLine : string =
            if (DamageDealt > 0.0):
                "\nDeals {FormatFloatTo1DecimalString(DamageDealt)} damage."
            else:
                ""

        MainText : string =
            "{AttackerName} used {AttackName}!{DamageLine}{EffectivenessToText(Eff)}{CritToText(WasCrit)}"

        var EffectsText:string = ""
        if (Attack.Effects.Length > 0):
            ApplyEffects_Team(AttackerSide, DefenderSide, Attack.Effects)
            set EffectsText = BuildEffectsSummary(Attack.Effects, AttackerSide)

        return (true, DamageDealt, WasCrit, Attack, Eff, MainText, EffectsText)
    # -------------------------------------------------------------------------------------------------------------------------------------

    # 0 (DidHit), 1 (DamageDealt), 2 (WasCrit), 3 (AttackUsed), 4 (Effectiveness), 5 (MainText), 6 (EffectsText)
    DoAttackSequence(Player:player, AttackerSide:battle_side, DefenderSide:battle_side, AttackIndex:int)<suspends>: logic =
        Result := ApplyDamageOnly(Player, AttackerSide, DefenderSide, AttackIndex)
        DidHit := Result(0)
        DamageDealt := Result(1)
        WasCrit := Result(2)
        Attack := Result(3)
        Eff := Result(4)

        if (not DidHit?):
            return false

        # Only play damage animation if actual damage happened
        if (DamageDealt > 0.0):
            if (PlayerBattleInfo := BattleSystemManager.PlayerBattleInfoMap[Player]):
                if(AttackerSide = battle_side.A) then spawn{BattleSystemManager.PlayDamagedAnimUIRight(Player, PlayerBattleInfo.MoxieWidgeRight)}
                else spawn{BattleSystemManager.PlayDamagedAnimUILeft(Player, PlayerBattleInfo.MoxieWidgeLeft)}

        AttackerName := SideToName(AttackerSide)
        AttackName := Attack.Name

        DamageLine : string =
            if (DamageDealt > 0.0):
                "\nDeals {FormatFloatTo1DecimalString(DamageDealt)} damage."
            else:
                ""
        MainText : string =
            "{AttackerName} used {AttackName}!{DamageLine}{EffectivenessToText(Eff)}{CritToText(WasCrit)}"

        # Display the Main Text (Attack Info)
        BattleSystemManager.UpdateBattleInformationText(Player, "{MainText}", 2.0)

        if (IsOver[]):
                return true

        var EffectsText:string = ""
        if (Attack.Effects.Length > 0):
            ApplyEffect(AttackerSide, DefenderSide, Attack.Effects)
            set EffectsText = BuildEffectsSummary(Attack.Effects, AttackerSide)
            # Display the Main Text (Attack Info)
            BattleSystemManager.UpdateBattleInformationText(Player, "{EffectsText}", 2.0)

        return true
    # -------------------------------------------------------------------------------------------------------------------------------------

    CanSwitchTo(Side:battle_side, NewIndex:int)<transacts>:logic =
        T := GetTeam(Side)
        if (T.Members.Length <= 0):
            return false

        if (NewIndex < 0 or NewIndex >= T.Members.Length):
            return false

        if (NewIndex = T.ActiveIndex):
            return false

        # Must be alive
        if (B := T.Members[NewIndex]):
            return logic{ (not B.IsFainted?) and (B.Creature.Health > 0.0) }

        return false
    # -------------------------------------------------------------------------------------------------------------------------------------

    TrySwitchActive(Side:battle_side, NewIndex:int)<transacts>:logic =
        if (not CanSwitchTo(Side, NewIndex)?):
            return false

        T := GetTeam(Side)
        SetTeam(Side, team_state{ Members := T.Members, ActiveIndex := NewIndex })
        return true
    # -------------------------------------------------------------------------------------------------------------------------------------
    # TODO: For now is only the Type as String
    GetActiveName(Side:battle_side):string =
        if (B := GetActiveBattler(Side)?):
            return CreatureTypeToString(B.Creature.Type)
        return "???"
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetSwitchText(Side:battle_side):string =
        # Example: "Your Moxie swapped to Fluffy!"
        NewName := GetActiveName(Side)
        SideName := SideToName(Side)
        return "{SideName} swapped to {NewName}!"
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetAutoSwapText(Side:battle_side):string =
        # Example: "Your Moxie swapped to Bestial!"
        NewName := GetActiveName(Side)
        SideName := SideToName(Side)
        return "{SideName} swapped to {NewName}!"
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetFaintedText(Side:battle_side):string =
        if (Side = battle_side.A):
            "Your Moxie fainted!"
        else:
            "Wild Moxie fainted!"
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetBattleEndText(PlayerWon:logic):string =
        if (PlayerWon?):
            return "Victory! Your Moxie team wins the battle!"
        else:
            return "Defeat... Your Moxie team was overwhelmed!"
    # -------------------------------------------------------------------------------------------------------------------------------------


    # Returns true if SideA acts first, false if SideB acts first
    DoesASideActFirst()<transacts>:logic =
        SpdA := GetActiveEffectiveSpeed(battle_side.A)
        SpdB := GetActiveEffectiveSpeed(battle_side.B)

        if (SpdA > SpdB):
            return true
        if (SpdB > SpdA):
            return false

        # Tie breaker
        return logic{ GetRandomInt(0, 1) = 0 }
    # -------------------------------------------------------------------------------------------------------------------------------------

    PickRandomAttackIndex(Side:battle_side):int =
        if (C := GetActiveCreature(Side)?):
            if (C.Attacks.Length > 0):
                return GetRandomInt(0, C.Attacks.Length - 1)
        return -1
    # -------------------------------------------------------------------------------------------------------------------------------------

    PickRandomAttackIndexByLevel(Player:player, Side:battle_side):int =
        if (C := GetActiveCreature(Side)?):
            Lvl:int = C.Level

            # Max allowed by level (0..3)
            MaxByLevel := BattleSystemManager.GetMaxUnlockedAttackIndexForLevel(Lvl)

            # Clamp by actual attacks array length
            AttacksCount:int = C.Attacks.Length
            if (AttacksCount <= 0):
                return 0

            var MaxByMoves:int = AttacksCount - 1
            if (MaxByMoves < 0):
                set MaxByMoves = 0

            # Final max index
            var FinalMax:int = MaxByLevel
            if (FinalMax > MaxByMoves):
                set FinalMax = MaxByMoves

            # If only one option, return it
            if (FinalMax <= 0):
                return 0

            # Random int in [0..FinalMax]
            return GetRandomInt(0, FinalMax)

        # Fallback
        return 0
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetActiveHPProgress(Side:battle_side)<transacts>:float =
        if (B := GetActiveBattler(Side)?):
            MaxHP := B.Creature.Health
            if (MaxHP <= 0.0):
                return 0.0

            P := B.Creature.Health / MaxHP
            if (P < 0.0): 
                return 0.0
            if (P > 1.0): 
                return 1.0
            return P

        return 0.0
    # -------------------------------------------------------------------------------------------------------------------------------------

battle_ui_info := struct:
    FightButton: button_regular
    ItemsButton: button_regular
    RunButton: button_regular
    TeamInfoButton: button_regular
    StatsText: text_block
    Attack1Button: button_regular
    Attack2Button: button_regular
    Attack3Button: button_regular
    Attack4Button: button_regular

    Attack1_MoxieColorMat: UI.Materials.M_MoxieColorBG = UI.Materials.M_MoxieColorBG{}
    Attack2_MoxieColorMat: UI.Materials.M_MoxieColorBG = UI.Materials.M_MoxieColorBG{}
    Attack3_MoxieColorMat: UI.Materials.M_MoxieColorBG = UI.Materials.M_MoxieColorBG{}
    Attack4_MoxieColorMat: UI.Materials.M_MoxieColorBG = UI.Materials.M_MoxieColorBG{}

    PlayerMoxie_HealthbarMat: UI.Materials.M_MoxieBaseBar = UI.Materials.M_MoxieBaseBar{}
    WildMoxie_HealthbarMat: UI.Materials.M_MoxieBaseBar = UI.Materials.M_MoxieBaseBar{}
    PlayerMoxie_XPMat: UI.Materials.M_MoxieBaseBar = UI.Materials.M_MoxieBaseBar{}

    AttackBackButton: button_quiet
    ConfirmAttackButton:button_regular
    CancelAttackButton:button_regular
    ContinueBattleTextButton: button_quiet
    TeamInfoBackButton: button_quiet

    BattleSelectionInfoOverlay: overlay
    AttackSelectionInfoOverlay: overlay
    ConfirmAttackInfo: overlay
    BattleInformationOverlay: overlay
    PlayerTeamWidgetOverlay: overlay
    PlayerTeamButtonsOverlay: overlay

    ConfirmAttackInfoName: text_block
    ConfirmAttackInfoDesc: text_block
    BattleInformationText: text_block

    MoxieWidgeRight: Widgets.Test.WBP_Moxie_Right
    MoxieWidgeLeft: Widgets.Test.WBP_Moxie_Left

    MoxieTeamWidget_0: Widgets.Test.WBP_Moxie_Team_Item
    MoxieTeamWidget_1: Widgets.Test.WBP_Moxie_Team_Item
    MoxieTeamWidget_2: Widgets.Test.WBP_Moxie_Team_Item
    MoxieTeamWidget_3: Widgets.Test.WBP_Moxie_Team_Item
    MoxieTeamWidget_4: Widgets.Test.WBP_Moxie_Team_Item
    MoxieTeamWidget_5: Widgets.Test.WBP_Moxie_Team_Item

    MoxieTeamButton_0: button_quiet
    MoxieTeamButton_1: button_quiet
    MoxieTeamButton_2: button_quiet
    MoxieTeamButton_3: button_quiet
    MoxieTeamButton_4: button_quiet
    MoxieTeamButton_5: button_quiet

    AnimationLoopCancelledRight: logic 
    AnimationLoopCancelledLeft: logic

    #AnimationLoopCancelledRight: [player]logic 
    #AnimationLoopCancelledLeft: [player]logic

    Canvas: canvas
# ____________________________________________________________________________________________________________________________________________________
     
catch_result := enum:
    None,
    Success,
    Failed,
    Canceled
# ____________________________________________________________________________________________________________________________________________________

catch_attempt := struct:
    Done:event()
    Result:catch_result
    SubSuccess:cancelable
    SubFail:cancelable
    SubCancel:cancelable
# ____________________________________________________________________________________________________________________________________________________

ronin_battle_system := class(creative_device):

    @editable
    MoxieManager: ronin_creature_manager = ronin_creature_manager{}

    @editable
    MaybePlayerDataDevice: ?ronin_player_data = false

    @editable
    TeamInfoUI: ronin_team_info_ui = ronin_team_info_ui{}

    @editable
    MoxieCatchDevice: skilled_interaction_device = skilled_interaction_device{}

    # Per-player battle core instance (holds TeamA/TeamB state, HP, multipliers, etc.)
    var CoreByPlayer : [player]ronin_battle_core = map{}
    # Per-player pending input coming from UI (SideA / Human)
    var PendingInputByPlayer : [player]battle_input = map{}
    # Per-player wake event (signals when UI submits something)
    var InputEventByPlayer : [player]event() = map{}
    # UI object per player
    var PlayerBattleInfoMap : [player]battle_ui_info = map{}
    # Confirm flow
    var SelectedAttackIndexByPlayer : [player]int = map{}
    # Typewriter & Continue pacing
    var BattleTextVersionByPlayer : [player]int = map{}
    var ContinueEventByPlayer : [player]event() = map{}
    # Highest attack index the player may use right now (0..3)
    var MaxUnlockedAttackIdxByPlayer : [player]int = map{}

    var BattleEndAnnouncedByPlayer: [player]logic = map{}
    # Map to Catch a Moxie
    var CatchAttemptByPlayer : [player]?catch_attempt = map{}

    # Event to wake the turn engine when something relevant happens
    InputEvent : event() = event(){}

    var LeftAnimVersionByPlayer : [player]int = map{}
    var RightAnimVersionByPlayer : [player]int = map{}

    # Levels to unlock the Attack Buttons
    var UnlockAttack3MinLevel:int = 5     # Level >= 6  (i.e. > 5)
    var UnlockAttack4MinLevel:int = 10     # Level >= 11 (i.e. > 10)

    @editable
    TestButton: button_device = button_device{} 

    OnBegin<override>()<suspends>:void=
        TestButton.InteractedWithEvent.Subscribe(TestFunction)
        Print("Hello, world!")

    TestFunction(Agent: agent): void =
        if(Player:= player[Agent]):
            StartBattleForPlayer(Player, GetRandomType(), 2)
    # -------------------------------------------------------------------------------------------------------------------------------------

    StartBattleForPlayer(Player:player, CreatureType: creature_type, EnemyTeamSize:int):void =
        # If the UI is already open, close it first (prevents stacking canvases)
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            RemoveEndBattleWidget(Player, UIBattleInfo)
            UpdateShouldCancelAnimations(Player, false)

        # Create/get core and initialize teams
        Core := GetOrCreateCore(Player)

        # --- Pick creatures for testing ---
        # Option A (recommended): ask your MoxieManager for a player creature + a random wild
        # Replace these with the actual functions you have in your ronin_creature_manager.
        TeamA := GetTestTeam(Player)
        TeamB := GetTestTeam2(Player, CreatureType, EnemyTeamSize)

        # If we failed to get creatures, bail with a debug
        if (TeamA.Length <= 0 or TeamB.Length <= 0):
            Print("StartBattleForPlayer failed: TeamA or TeamB empty!!")
            return

        Core.Init(Self, TeamA, TeamB, 3)

        # Create UI + start loops (your CreateBattleCanvas already calls InitBattleCanvasFromCore,
        # ListenForBattleUI and StartTurnBasedBattle)
        CreateBattleCanvas(Player)
    # -------------------------------------------------------------------------------------------------------------------------------------

    CreateTestTeam(Player:player):void =
        if(PlayerDataDevice:= MaybePlayerDataDevice?):
            PlayerData:= PlayerDataDevice.GetPlayerData(Player)
            var MoxiesArr: []ronin_creature = array{} 
            if(PlayerData.PlayerMoxiesArray.Length < 0 ):
            for (Idx := 0..5): # 5
                NewMoxie := MoxieManager.CreateAddCreature(Player, GetRandomType()) #CreatePureCreature creature_type.Bestial GetRandomType()
                #set MoxiesArr = MoxiesArr + array{NewMoxie}

                #if(PlayerDataDevice:= MaybePlayerDataDevice?):
                    #PlayerDataDevice.UpsertMoxieInPersistentData(Player, NewMoxie)

    
    GetTestTeam(Player:player):[]ronin_creature =
        CreateTestTeam(Player)

        if(PlayerDataDevice:= MaybePlayerDataDevice?):
            PlayerData:= PlayerDataDevice.GetPlayerData(Player)
            var MoxieTeam: []ronin_creature = array{}
            for (Idx := 0..5): #5
                if(MoxieDataFromPlayer:= PlayerData.PlayerMoxiesArray[Idx]):
                    set MoxieTeam += array{MoxieManager.CreateCreatureFromData(MoxieDataFromPlayer)} #PlayerDataDevice.GetPlayerMoxieTeamPersistent(Player)
            return MoxieTeam
        return array{}

    GetTestTeam2(Player:player, CreatureType: creature_type, TeamSize:int):[]ronin_creature =
        var MoxiesArr: []ronin_creature = array{}
        for (Idx := 0..TeamSize-1):
            NewMoxie := MoxieManager.CreateCreature(creature_type.Herbal) #CreatureType
            set MoxiesArr = MoxiesArr + array{NewMoxie}
        return MoxiesArr
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetOrCreateCore(Player:player)<transacts>:ronin_battle_core =
        if (C := CoreByPlayer[Player]):
            return C
        NewC:ronin_battle_core = ronin_battle_core{}
        if (set CoreByPlayer[Player] = NewC) {}
        return NewC
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetActiveCreatureOrNull(Player:player, Side:battle_side):?ronin_creature =
        Core := GetOrCreateCore(Player)
        return Core.GetActiveCreature(Side)
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetOrCreateInputEvent(Player:player):event() =
        if (E := InputEventByPlayer[Player]):
            return E
        NewE:event() = event(){}
        if (set InputEventByPlayer[Player] = NewE) {}
        return NewE
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetOrCreateContinueEvent(Player:player):event() =
        if (E := ContinueEventByPlayer[Player]):
            return E
        NewE:event() = event(){}
        if (set ContinueEventByPlayer[Player] = NewE) {}
        return NewE
    # -------------------------------------------------------------------------------------------------------------------------------------

    SetSelectedAttackIndex(Player:player, Idx:int):void =
        if (set SelectedAttackIndexByPlayer[Player] = Idx) {}
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetSelectedAttackIndex(Player:player):int =
        if (Idx := SelectedAttackIndexByPlayer[Player]):
            return Idx
        return -1
    # -------------------------------------------------------------------------------------------------------------------------------------

    ClearSelectedAttackIndex(Player:player):void =
        if (set SelectedAttackIndexByPlayer[Player] = -1) {}
    # -------------------------------------------------------------------------------------------------------------------------------------

    UpdatePlayerMoxieTeamData(Player:player):void =
        Core := GetOrCreateCore(Player)
        PlayerMoxieTeam := Core.GetTeamCreatures(battle_side.A)
        if(PlayerDataDevice:= MaybePlayerDataDevice?):
            PlayerDataDevice.UpdateAllPlayerMoxieTeamData(Player, PlayerMoxieTeam)
    # -------------------------------------------------------------------------------------------------------------------------------------

    OpenAttackSelectionInfoOverlay(Player:player):void =
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            UIBattleInfo.BattleSelectionInfoOverlay.SetVisibility(widget_visibility.Hidden)
            UIBattleInfo.AttackSelectionInfoOverlay.SetVisibility(widget_visibility.Visible)
            UIBattleInfo.BattleInformationOverlay.SetVisibility(widget_visibility.Hidden)
            UIBattleInfo.PlayerTeamWidgetOverlay.SetVisibility(widget_visibility.Hidden)
            UIBattleInfo.PlayerTeamButtonsOverlay.SetVisibility(widget_visibility.Hidden)
            UIBattleInfo.TeamInfoButton.SetVisibility(widget_visibility.Hidden)

    # -------------------------------------------------------------------------------------------------------------------------------------

    CloseAttackSelectionInfoOverlay(Player:player):void =
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            UIBattleInfo.BattleSelectionInfoOverlay.SetVisibility(widget_visibility.Visible)
            UIBattleInfo.AttackSelectionInfoOverlay.SetVisibility(widget_visibility.Hidden)
            UIBattleInfo.BattleInformationOverlay.SetVisibility(widget_visibility.Visible)
            UIBattleInfo.PlayerTeamWidgetOverlay.SetVisibility(widget_visibility.Visible)
            UIBattleInfo.PlayerTeamButtonsOverlay.SetVisibility(widget_visibility.Visible)
            HidePlayerTeamMenu(Player)
            spawn{FastTypewriteBattleText(Player, "What will your Moxie do?", 1.0)}

    # -------------------------------------------------------------------------------------------------------------------------------------

    ShowOnlyBattleInformation(Player:player):void =
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            UIBattleInfo.BattleSelectionInfoOverlay.SetVisibility(widget_visibility.Hidden)
            UIBattleInfo.AttackSelectionInfoOverlay.SetVisibility(widget_visibility.Collapsed)
            UIBattleInfo.ConfirmAttackInfo.SetVisibility(widget_visibility.Collapsed)
            UIBattleInfo.BattleInformationOverlay.SetVisibility(widget_visibility.Visible)
            UIBattleInfo.PlayerTeamWidgetOverlay.SetVisibility(widget_visibility.Hidden)
            UIBattleInfo.PlayerTeamButtonsOverlay.SetVisibility(widget_visibility.Hidden)
            UIBattleInfo.TeamInfoButton.SetVisibility(widget_visibility.Hidden)
    # -------------------------------------------------------------------------------------------------------------------------------------

    ShowBattleSelectionInfoOverlay(Player:player):void =
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            UIBattleInfo.BattleSelectionInfoOverlay.SetVisibility(widget_visibility.Visible)
            UIBattleInfo.AttackSelectionInfoOverlay.SetVisibility(widget_visibility.Collapsed)
            UIBattleInfo.ConfirmAttackInfo.SetVisibility(widget_visibility.Collapsed)
            UIBattleInfo.BattleInformationOverlay.SetVisibility(widget_visibility.Visible)
            UIBattleInfo.PlayerTeamWidgetOverlay.SetVisibility(widget_visibility.Visible)
            UIBattleInfo.PlayerTeamButtonsOverlay.SetVisibility(widget_visibility.Visible)
            UIBattleInfo.TeamInfoButton.SetVisibility(widget_visibility.Visible)
            HidePlayerTeamMenu(Player)
    # -------------------------------------------------------------------------------------------------------------------------------------
    
    ShowOnlyTeamSwapAndBattleTextInformation(Player:player):void =
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            UIBattleInfo.BattleSelectionInfoOverlay.SetVisibility(widget_visibility.Hidden)
            UIBattleInfo.AttackSelectionInfoOverlay.SetVisibility(widget_visibility.Collapsed)
            UIBattleInfo.ConfirmAttackInfo.SetVisibility(widget_visibility.Collapsed)
            UIBattleInfo.BattleInformationOverlay.SetVisibility(widget_visibility.Visible)
            UIBattleInfo.PlayerTeamWidgetOverlay.SetVisibility(widget_visibility.Visible)
            UIBattleInfo.PlayerTeamButtonsOverlay.SetVisibility(widget_visibility.Visible)
            UIBattleInfo.TeamInfoButton.SetVisibility(widget_visibility.Hidden)
            UIBattleInfo.TeamInfoBackButton.SetVisibility(widget_visibility.Hidden)
    # -------------------------------------------------------------------------------------------------------------------------------------

    # Shows the Moxies Images and Buttons to get Moxie Info
    ShowOnlyPlayerTeamMenu(Player:player):void =
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            UIBattleInfo.PlayerTeamWidgetOverlay.SetVisibility(widget_visibility.Visible)
            UIBattleInfo.PlayerTeamButtonsOverlay.SetVisibility(widget_visibility.Visible)
            UIBattleInfo.TeamInfoBackButton.SetVisibility(widget_visibility.Visible)
            UIBattleInfo.BattleSelectionInfoOverlay.SetVisibility(widget_visibility.Hidden)
            UIBattleInfo.AttackSelectionInfoOverlay.SetVisibility(widget_visibility.Collapsed)
            UIBattleInfo.ConfirmAttackInfo.SetVisibility(widget_visibility.Collapsed)
            UIBattleInfo.BattleInformationOverlay.SetVisibility(widget_visibility.Hidden)
            UIBattleInfo.TeamInfoButton.SetVisibility(widget_visibility.Hidden)

    # -------------------------------------------------------------------------------------------------------------------------------------

    # Hide the Moxies Images and Buttons to get Moxie Info
    HidePlayerTeamMenu(Player:player):void =
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            UIBattleInfo.PlayerTeamWidgetOverlay.SetVisibility(widget_visibility.Hidden)
            UIBattleInfo.PlayerTeamButtonsOverlay.SetVisibility(widget_visibility.Hidden)
            UIBattleInfo.TeamInfoButton.SetVisibility(widget_visibility.Visible)
    # -------------------------------------------------------------------------------------------------------------------------------------

    OpenConfirmAttackOverlay(Player:player, AttackIndexOneBased:int):void =
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            UIBattleInfo.ConfirmAttackInfo.SetVisibility(widget_visibility.Visible)
            UIBattleInfo.AttackSelectionInfoOverlay.SetVisibility(widget_visibility.Collapsed)

            AttackIdx := AttackIndexOneBased - 1

            # Use TeamA active creature name/desc (not old PlayerMoxie_A)
            Core := GetOrCreateCore(Player)
            if (C := Core.GetActiveCreature(battle_side.A)?):
                if (AttackIdx >= 0 and AttackIdx < C.Attacks.Length):
                    if (Atk := C.Attacks[AttackIdx]):
                        UIBattleInfo.ConfirmAttackInfoName.SetText(CreateMessage(Atk.Name))
                        UIBattleInfo.ConfirmAttackInfoDesc.SetText(CreateMessage(Atk.Description))
    # -------------------------------------------------------------------------------------------------------------------------------------

    CloseConfirmAttackOverlay(Player:player):void =
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            UIBattleInfo.ConfirmAttackInfo.SetVisibility(widget_visibility.Collapsed)
            UIBattleInfo.AttackSelectionInfoOverlay.SetVisibility(widget_visibility.Visible)
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetNextBattleTextVersion(Player:player):int =
        var V:int = 0
        if (Cur := BattleTextVersionByPlayer[Player]):
            set V = Cur + 1
        else:
            set V = 1
        if (set BattleTextVersionByPlayer[Player] = V) {}
        return V
    # -------------------------------------------------------------------------------------------------------------------------------------

    UpdateBattleInformationText(Player:player, NewText:string, TotalTime:float)<suspends>:void =
        TypewriteBattleText(Player, NewText, 0.5) #TODO: change here, for now im testing
    # -------------------------------------------------------------------------------------------------------------------------------------

    TypewriteBattleText(Player:player, FullText:string, TotalTime:float)<suspends>:void =
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            Version := GetNextBattleTextVersion(Player)
            UIBattleInfo.BattleInformationText.SetText(CreateMessage(""))

            CharCount:int = FullText.Length
            if (CharCount <= 0):
                return

            Step:float = TotalTime / (CharCount * 1.0)
            StepValue:float = if (Step < 0.005) then 0.005 else Step

            var Acc:message = CreateMessage("")
            for (Ch : FullText):
                if (CurV := BattleTextVersionByPlayer[Player], CurV <> Version):
                    return
                set Acc = ConcatenateMessages(Acc, CreateMessage("{Ch}"))
                UIBattleInfo.BattleInformationText.SetText(Acc)
                Sleep(StepValue) #0.005

        # After line finishes: wait for Continue button (Pokemon-style pacing)
        Sleep(1.75) 
        #GetOrCreateContinueEvent(Player).Await()
    # -------------------------------------------------------------------------------------------------------------------------------------

    FastTypewriteBattleText(Player:player, FullText:string, TotalTime:float)<suspends>:void =
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            Version := GetNextBattleTextVersion(Player)
            UIBattleInfo.BattleInformationText.SetText(CreateMessage(""))

            CharCount:int = FullText.Length
            if (CharCount <= 0):
                return

            Step:float = 0.1 / (CharCount * 1.0)  #TODO: change here, for now im testing (TotalTime)
            StepValue:float = if (Step < 0.005) then 0.005 else Step

            var Acc:message = CreateMessage("")
            for (Ch : FullText):
                if (CurV := BattleTextVersionByPlayer[Player], CurV <> Version):
                    return
                set Acc = ConcatenateMessages(Acc, CreateMessage("{Ch}"))
                UIBattleInfo.BattleInformationText.SetText(Acc)
                Sleep(StepValue)  #0.005

        # After line finishes, fast finish to hear new inputs
        Sleep(0.5)
        #GetOrCreateContinueEvent(Player).Await()
    # -------------------------------------------------------------------------------------------------------------------------------------

    InitBattleCanvasFromCore(Player:player):void =

        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            Core := GetOrCreateCore(Player)

            # --- LEFT (Side A) ---
            if (CA := Core.GetActiveCreature(battle_side.A)?):
                SetMoxiePartsToUILeft(CA, UIBattleInfo.MoxieWidgeLeft)
                spawn { PlaySwappedAnimUILeft(Player, UIBattleInfo.MoxieWidgeLeft) }
                spawn { LoopIdleAnimationUILeft(Player, UIBattleInfo.MoxieWidgeLeft) }

                # Attack buttons (safe: not all creatures have 4 attacks)
                SetAttackButtonsFromCreature(UIBattleInfo, CA)
                UpdateAttackButtonLocksFromActiveMoxie(Player)

                # Healthbar progress (safe)
                #SetHealthbarFromCore(Player, battle_side.A)
                spawn { SetMoxieValueBars(Player, battle_side.A) }

                # Set the previwe for the Team Moxies in the UI
                PlayerMoxiesTeam := Core.GetTeamCreatures(battle_side.A)
                TeamWidgets := GetPlayerTeamWidgetArray(UIBattleInfo)
                TeamButtons := GetPlayerTeamButtonsArray(UIBattleInfo)
                UpdateAllPlayerMoxieTeamDisplay(Player)

                for (Idx -> TeamWidget : TeamWidgets):
                    if(TeamButton:= TeamButtons[Idx]):
                        if (Idx < PlayerMoxiesTeam.Length):
                            if (C := PlayerMoxiesTeam[Idx]):
                                # If your team-item widget uses the SAME function, this is perfect:
                                SetMoxiePartsToTeamUI(C, TeamWidget)
                                # Optional: make sure it’s visible
                                TeamWidget.SetVisibility(widget_visibility.Visible)
                                TeamButton.SetVisibility(widget_visibility.Visible)
                        else:
                            # Hide unused slots so empty widgets don’t show garbage
                            TeamWidget.SetVisibility(widget_visibility.Hidden)
                            TeamButton.SetVisibility(widget_visibility.Hidden)

            # --- RIGHT (Side B) ---
            if (CB := Core.GetActiveCreature(battle_side.B)?):
                SetMoxiePartsToUIRight(CB, UIBattleInfo.MoxieWidgeRight)
                spawn { PlaySwappedAnimUIRight(Player, UIBattleInfo.MoxieWidgeRight) }
                spawn { LoopIdleAnimationUIRight(Player, UIBattleInfo.MoxieWidgeRight) }

                #SetHealthbarFromCore(Player, battle_side.B)
                #spawn { SetHealthbarFromCoreAnimated(Player, battle_side.B)}
                spawn { SetMoxieValueBars(Player, battle_side.B) }

            # stats text depends on your existing function (but it should also read from Core now)
            UpdatePlayerMoxieStatsInfo(Player)
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetPlayerTeamWidgetArray(UIBattleInfo:battle_ui_info):[]Widgets.Test.WBP_Moxie_Team_Item = return array{
        UIBattleInfo.MoxieTeamWidget_0,
        UIBattleInfo.MoxieTeamWidget_1,
        UIBattleInfo.MoxieTeamWidget_2,
        UIBattleInfo.MoxieTeamWidget_3,
        UIBattleInfo.MoxieTeamWidget_4,
        UIBattleInfo.MoxieTeamWidget_5
    }
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetPlayerTeamButtonsArray(UIBattleInfo:battle_ui_info):[]button_quiet = return array{
        UIBattleInfo.MoxieTeamButton_0,
        UIBattleInfo.MoxieTeamButton_1,
        UIBattleInfo.MoxieTeamButton_2,
        UIBattleInfo.MoxieTeamButton_3,
        UIBattleInfo.MoxieTeamButton_4,
        UIBattleInfo.MoxieTeamButton_5
    }
    # -------------------------------------------------------------------------------------------------------------------------------------

    SetAttackButtonsFromCreature(UIBattleInfo:battle_ui_info, C:ronin_creature):void =
        # Defaults
        UIBattleInfo.Attack1Button.SetText(CreateMessage("—"))
        UIBattleInfo.Attack2Button.SetText(CreateMessage("—"))
        UIBattleInfo.Attack3Button.SetText(CreateMessage("—"))
        UIBattleInfo.Attack4Button.SetText(CreateMessage("—"))

        # If attacks exist, set them one by one safely
        if (C.Attacks.Length > 0):
            if (A0 := C.Attacks[0]):
                UIBattleInfo.Attack1Button.SetText(CreateMessage(A0.Name))
                set UIBattleInfo.Attack1_MoxieColorMat.ColorSelectorSwitch = CreatureTypeToColorIndex(A0.Type)

        if (C.Attacks.Length > 1):
            if (A1 := C.Attacks[1]):
                UIBattleInfo.Attack2Button.SetText(CreateMessage(A1.Name))
                set UIBattleInfo.Attack2_MoxieColorMat.ColorSelectorSwitch = CreatureTypeToColorIndex(A1.Type)

        if (C.Attacks.Length > 2):
            if (A2 := C.Attacks[2]):
                UIBattleInfo.Attack3Button.SetText(CreateMessage(A2.Name))
                set UIBattleInfo.Attack3_MoxieColorMat.ColorSelectorSwitch = CreatureTypeToColorIndex(A2.Type)

        if (C.Attacks.Length > 3):
            if (A3 := C.Attacks[3]):
                UIBattleInfo.Attack4Button.SetText(CreateMessage(A3.Name))
                set UIBattleInfo.Attack4_MoxieColorMat.ColorSelectorSwitch = CreatureTypeToColorIndex(A3.Type)
    # -------------------------------------------------------------------------------------------------------------------------------------

    SetHealthbarFromCore(Player:player, Side:battle_side):void =
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            Core := GetOrCreateCore(Player)
            if (B := Core.GetActiveBattler(Side)?):
                MaxHP := B.Creature.Health
                CurHP := B.Creature.Health

                var Progress:float = 0.0
                if (MaxHP > 0.0):
                    set Progress = CurHP / MaxHP

                # clamp just in case
                if (Progress < 0.0): 
                    set Progress = 0.0
                if (Progress > 1.0): 
                    set Progress = 1.0

                if (Side = battle_side.A):
                    set UIBattleInfo.PlayerMoxie_HealthbarMat.Progress = Progress
                else:
                    set UIBattleInfo.WildMoxie_HealthbarMat.Progress = Progress
    # -------------------------------------------------------------------------------------------------------------------------------------

    SetPendingInput(Player:player, NewInput:battle_input):void =
        if (set PendingInputByPlayer[Player] = NewInput) {}
        InputEvent.Signal()
    # -------------------------------------------------------------------------------------------------------------------------------------

    ClearPendingInput(Player:player):void =
        if (set PendingInputByPlayer[Player] = battle_input{Action := battle_action.None, AttackIndex := -1, ItemIndex := -1, SwitchIndex := -1}) {}
        #ClearSelectedAttack(Player)
    # -------------------------------------------------------------------------------------------------------------------------------------

    SetSelectedAttack(Player:player, Idx:int):void =
        if (set SelectedAttackIndexByPlayer[Player] = Idx) {}
    # -------------------------------------------------------------------------------------------------------------------------------------

    ClearSelectedAttack(Player:player):void =
        if (set SelectedAttackIndexByPlayer[Player] = -1) {}
    # -------------------------------------------------------------------------------------------------------------------------------------
    
    ListenForBattleUI(Player:player)<suspends>:void =
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            # init
            #if (set PendingActionByPlayer[Player] = MakeNoneAction()) {}
            ClearSelectedAttackIndex(Player)

            race:
                # FIGHT => open attack selection
                loop:
                    UIBattleInfo.FightButton.OnClick().Await()
                    OpenAttackSelectionInfoOverlay(Player)
                    # mark intent (not confirmed)
                    SetPendingInput(Player, battle_input{Action := battle_action.Fight, AttackIndex := -1, ItemIndex := -1, SwitchIndex := -1})

                # ITEMS => immediate action (placeholder)
                loop:
                    UIBattleInfo.ItemsButton.OnClick().Await()
                    spawn { TryCatchViaSkilledInteraction(Player) }


                    # if(MoxieCatchDevice.BeginInteraction[Player]):
                    #     ShowOnlyBattleInformation(Player)
                    #     FastTypewriteBattleText(Player, "You're trying to catch the Wild Moxie!", 1.0)

                    #SetPendingInput(Player, battle_input{Action := battle_action.Items, AttackIndex := -1, ItemIndex := -1, SwitchIndex := -1})
                    #SetPendingAction(Player, team_battle_action{ Type := battle_action_type.Item, AttackIndex := -1, SwitchIndex := -1, ItemIndex := 0 })


                # RUN => end battle!
                loop:
                    UIBattleInfo.RunButton.OnClick().Await()
                    SetPendingInput(Player, battle_input{Action := battle_action.Run, AttackIndex := -1, ItemIndex := -1, SwitchIndex := -1})
                    # Update All the Moxie Team Data when we Run from the battle
                    UpdatePlayerMoxieTeamData(Player)
                    #SetPendingAction(Player, team_battle_action{ Type := battle_action_type.Run, AttackIndex := -1, SwitchIndex := -1, ItemIndex := -1 })


                # INFO => you can expand later
                loop:
                    UIBattleInfo.TeamInfoButton.OnClick().Await()
                    # no gameplay action for now
                    #ShowOnlyPlayerTeamMenu(Player)
                    # SHOW HERE 
                    #SetPendingInput(Player, battle_input{Action := battle_action.Info, AttackIndex := -1, ItemIndex := -1, SwitchIndex := -1})

                    # Show the Team UI on top
                    IdxToSwap:= TeamInfoUI.OpenTeamInfoAndAwaitSwap(Player)
                    Print("Idx to Swap in the battle: {IdxToSwap}")
                    if(IdxToSwap >= 0):
                        # Player confirmed swap. Use your existing swap (updates UI + sets pending input)
                        #Swapped := SwapPlayerMoxie(Player, IdxToSwap)
                        #if (not Swapped?):
                        #    # Optional: show a quick message if invalid (fainted / same slot / etc)
                        #    FastTypewriteBattleText(Player, "Can't swap to that Moxie.", 1.25)
                        SetPendingInput(Player, battle_input{Action := battle_action.Switch, AttackIndex := -1, ItemIndex := -1, SwitchIndex := IdxToSwap})

                    else:
                        # cancelled => just continue battle UI as normal
                        #ShowOnlyBattleInformation(Player)
                        CloseAttackSelectionInfoOverlay(Player)

                # Attack buttons pick attack index (0..2) and open confirm overlay
                # Attack 1
                loop:
                    UIBattleInfo.Attack1Button.OnClick().Await()
                    SetSelectedAttackIndex(Player, 0)
                    OpenConfirmAttackOverlay(Player, 1) 

                # Attack 2
                loop:
                    UIBattleInfo.Attack2Button.OnClick().Await()
                    SetSelectedAttackIndex(Player, 1)
                    OpenConfirmAttackOverlay(Player, 2)

                # Attack 3
                loop:
                    UIBattleInfo.Attack3Button.OnClick().Await()
                    if (IsAttackUnlocked(Player, 2) = true):
                        SetSelectedAttackIndex(Player, 2)
                        OpenConfirmAttackOverlay(Player, 3)
                    else:
                        FastTypewriteBattleText(Player, "That attack is locked.", 1.0)

                # Attack 4
                loop:
                    UIBattleInfo.Attack4Button.OnClick().Await()
                    if (IsAttackUnlocked(Player, 3) = true):
                        SetSelectedAttackIndex(Player, 3)
                        OpenConfirmAttackOverlay(Player, 4)
                    else:
                        FastTypewriteBattleText(Player, "That attack is locked.", 1.0)

                loop:
                    UIBattleInfo.MoxieTeamButton_0.OnClick().Await() 
                    SetPendingInput(Player, battle_input{Action := battle_action.Switch, AttackIndex := -1, ItemIndex := -1, SwitchIndex := 0})


                # Swap Moxie from Player Team Array [1]
                loop:
                    UIBattleInfo.MoxieTeamButton_1.OnClick().Await()
                    SetPendingInput(Player, battle_input{Action := battle_action.Switch, AttackIndex := -1, ItemIndex := -1, SwitchIndex := 1})

                # Swap Moxie from Player Team Array [2]
                loop:
                    UIBattleInfo.MoxieTeamButton_2.OnClick().Await()
                    SetPendingInput(Player, battle_input{Action := battle_action.Switch, AttackIndex := -1, ItemIndex := -1, SwitchIndex := 2})

                # Swap Moxie from Player Team Array [3]
                loop:
                    UIBattleInfo.MoxieTeamButton_3.OnClick().Await()
                    SetPendingInput(Player, battle_input{Action := battle_action.Switch, AttackIndex := -1, ItemIndex := -1, SwitchIndex := 3})

                # Swap Moxie from Player Team Array [4]
                loop:
                    UIBattleInfo.MoxieTeamButton_4.OnClick().Await()
                    SetPendingInput(Player, battle_input{Action := battle_action.Switch, AttackIndex := -1, ItemIndex := -1, SwitchIndex := 4})

                # Swap Moxie from Player Team Array [5]
                loop:
                    UIBattleInfo.MoxieTeamButton_5.OnClick().Await()
                    SetPendingInput(Player, battle_input{Action := battle_action.Switch, AttackIndex := -1, ItemIndex := -1, SwitchIndex := 5})

                # Close Player Team Menu
                loop:
                    UIBattleInfo.TeamInfoBackButton.OnClick().Await()
                    CloseAttackSelectionInfoOverlay(Player)

                # Back from attack selection 
                loop:
                    UIBattleInfo.AttackBackButton.OnClick().Await()
                    CloseAttackSelectionInfoOverlay(Player)
                    ClearSelectedAttackIndex(Player)
                    SetPendingInput(Player, battle_input{Action := battle_action.None, AttackIndex := -1, ItemIndex := -1, SwitchIndex := -1})

                # Cancel confirm
                loop:
                    UIBattleInfo.CancelAttackButton.OnClick().Await()
                    ClearSelectedAttackIndex(Player)
                    CloseConfirmAttackOverlay(Player)
                    OpenAttackSelectionInfoOverlay(Player)


                # Confirm attack => submit action
                loop:
                    UIBattleInfo.ConfirmAttackButton.OnClick().Await()
                    Idx := GetSelectedAttackIndex(Player)
                    if (Idx >= 0): # TODO PendingInputByPlayer[Player].Action = battle_action.Fight
                        ShowOnlyBattleInformation(Player)
                        SetPendingInput(Player, battle_input{Action := battle_action.Fight, AttackIndex := Idx, ItemIndex := -1, SwitchIndex := -1})
                        #GetOrCreateContinueEvent(Player).Signal()
    # -------------------------------------------------------------------------------------------------------------------------------------

    UpdateAttackButtonLocksFromActiveMoxieOld(Player:player):void =
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            Core := GetOrCreateCore(Player)

            # Active creature is always Side A for player UI
            if (C := Core.GetActiveCreature(battle_side.A)?):

                Lvl:int = C.Level

                # Always unlocked
                SetAttackButtonEnabled(UIBattleInfo.Attack1Button, true)
                SetAttackButtonEnabled(UIBattleInfo.Attack2Button, true)

                # Attack 3 gate
                if (Lvl >= UnlockAttack3MinLevel):
                    SetAttackButtonEnabled(UIBattleInfo.Attack3Button, true)
                    SetAttackButtonsFromCreature(UIBattleInfo, C)
                    # Keep the real attack name (already set by SetAttackButtonsFromCreature)
                else:
                    SetAttackButtonEnabled(UIBattleInfo.Attack3Button, false)
                    set UIBattleInfo.Attack3_MoxieColorMat.ColorSelectorSwitch = 0.0
                    UIBattleInfo.Attack3Button.SetText(CreateMessage("Locked (Lv {UnlockAttack3MinLevel}+)"))

                # Attack 4 gate
                if (Lvl >= UnlockAttack4MinLevel):
                    SetAttackButtonEnabled(UIBattleInfo.Attack4Button, true)
                    SetAttackButtonsFromCreature(UIBattleInfo, C)
                else:
                    SetAttackButtonEnabled(UIBattleInfo.Attack4Button, false)
                    set UIBattleInfo.Attack4_MoxieColorMat.ColorSelectorSwitch = 0.0
                    UIBattleInfo.Attack4Button.SetText(CreateMessage("Locked (Lv {UnlockAttack4MinLevel}+)"))
    # -------------------------------------------------------------------------------------------------------------------------------------

    UpdateAttackButtonLocksFromActiveMoxie(Player:player):void =
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            Core := GetOrCreateCore(Player)
    
            if (C := Core.GetActiveCreature(battle_side.A)?):
                Lvl:int = C.Level
    
                # compute and store max unlocked attack idx
                MaxIdx := GetMaxUnlockedAttackIndexForLevel(Lvl)
                if (set MaxUnlockedAttackIdxByPlayer[Player] = MaxIdx) {}
    
                # Always keep enabled so gamepad focus chain stays intact
                SetAttackButtonEnabled(UIBattleInfo.Attack1Button, true)
                SetAttackButtonEnabled(UIBattleInfo.Attack2Button, true)
                SetAttackButtonEnabled(UIBattleInfo.Attack3Button, true)
                SetAttackButtonEnabled(UIBattleInfo.Attack4Button, true)
    
                # Put real names/colors first
                SetAttackButtonsFromCreature(UIBattleInfo, C)
    
                # Now visually “lock” 3/4 if needed (but still enabled)
                if (MaxIdx < 2):
                    set UIBattleInfo.Attack3_MoxieColorMat.ColorSelectorSwitch = 0.0
                    UIBattleInfo.Attack3Button.SetText(CreateMessage("Locked (Lv {UnlockAttack3MinLevel}+)"))
    
                if (MaxIdx < 3):
                    set UIBattleInfo.Attack4_MoxieColorMat.ColorSelectorSwitch = 0.0
                    UIBattleInfo.Attack4Button.SetText(CreateMessage("Locked (Lv {UnlockAttack4MinLevel}+)"))
    # -------------------------------------------------------------------------------------------------------------------------------------

    SetAttackButtonEnabled(B:button_regular, Enabled:logic):void =
        B.SetEnabled(Enabled)
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetMaxUnlockedAttackIndexForLevel(Level:int):int =
        # Default: 2 attacks (indices 0..1)
        var MaxIdx:int = 1

        # Unlock attack 3 (index 2)
        if (Level >= UnlockAttack3MinLevel):
            set MaxIdx = 2

        # Unlock attack 4 (index 3)
        if (Level >= UnlockAttack4MinLevel):
            set MaxIdx = 3

        return MaxIdx
    # -------------------------------------------------------------------------------------------------------------------------------------

    IsAttackUnlocked(Player:player, AttackIndex:int)<transacts>:logic =
        return logic {AttackIndex <= GetMaxUnlockedAttackIndex(Player)}
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetMaxUnlockedAttackIndex(Player:player)<transacts>:int =
        if (V := MaxUnlockedAttackIdxByPlayer[Player]):
            return V
        return 1 # default: only attack 1-2 (indices 0-1)
        
    # -------------------------------------------------------------------------------------------------------------------------------------

    StartTurnBasedBattle(Player:player, MaxTurns:int)<suspends>:void =
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            var Turn:int = 1
            var SafetyMaxTurns:int = 200

            ResetBattleEndAnnounced(Player)

            # Get Actual Battle Core Info and initialize teams
            BattleCoreData := GetOrCreateCore(Player)

            ClearPendingInput(Player)
            # Ensure menus are in the base state
            UIBattleInfo.BattleSelectionInfoOverlay.SetVisibility(widget_visibility.Visible)
            UIBattleInfo.AttackSelectionInfoOverlay.SetVisibility(widget_visibility.Hidden)
            UIBattleInfo.ConfirmAttackInfo.SetVisibility(widget_visibility.Hidden)
            HidePlayerTeamMenu(Player)

            Sleep(0.2)
            FastTypewriteBattleText(Player, "What will your Moxie do?", 1.0)
            #UpdateBattleInformationText(Player, "What will your Moxie do?", 2.0)

            loop:
                if (BattleCoreData.IsOver[] or Turn > SafetyMaxTurns):
                    break

                Print("===== TURN {Turn} =====")

                # --- 1) WAIT FOR PLAYER DECISION ---
                var PlayerAtkIdx:int = -1
                var UsedItem:logic = false
                var UsedItemIndex:int = -1
                var WantsRun:logic = false
                var UsedSwitch:logic = false
                var PlayerSwitchIdx:int = -1

                loop:
                    # Wait until UI signals something happened
                    InputEvent.Await()

                    if (Pending := PendingInputByPlayer[Player]):

                        # Player wants to run
                        if (Pending.Action = battle_action.Run):
                            Print("ACTION RECEIVED - Player wants to RUN")
                            set WantsRun = true
                            ClearPendingInput(Player)
                            break

                        # Player chose items (does nothing for now) 
                        if (Pending.Action = battle_action.Items):
                            Print("ACTION RECEIVED - Player wants to USE ITEM")
                            set UsedItem = true
                            set UsedItemIndex = Pending.ItemIndex
                            ClearPendingInput(Player)
                            break

                        # Player wants to switch (team button)
                        if (Pending.Action = battle_action.Switch and Pending.SwitchIndex >= 0):
                            Idx := Pending.SwitchIndex

                            # Validate immediately so we don't consume the turn with an invalid selection
                            if (BattleCoreData.CanSwitchTo(battle_side.A, Idx)?):
                                Print("ACTION RECEIVED - Player wants to SWITCH to index {Idx}")
                                set UsedSwitch = true
                                set PlayerSwitchIdx = Idx
                                ClearPendingInput(Player)
                                break
                            else:
                                ShowOnlyBattleInformation(Player)
                                FastTypewriteBattleText(Player, "Can't swap to that Moxie.", 1.0)
                                ClearPendingInput(Player)                             
                                Sleep(0.6)
                                ShowBattleSelectionInfoOverlay(Player)
                                FastTypewriteBattleText(Player, "What will your Moxie do?", 1.0)
                                # keep waiting

                        # Fight flow: we only proceed if there is a CONFIRMED attack index
                        if (Pending.Action = battle_action.Fight and Pending.AttackIndex >= 0):
                            set PlayerAtkIdx = Pending.AttackIndex
                            Print("ACTION RECEIVED - Player wants to Attack with Attack: {PlayerAtkIdx}")
                            ClearPendingInput(Player)
                            break

                    # Otherwise keep waiting
                

                if (WantsRun?):
                    Print("Player chose RUN. Ending battle UI.")
                    RemoveEndBattleWidget(Player, UIBattleInfo)
                    return

                # Wild random attack
                var EnemyAtkIdx:int = 0
                MoxieSideB := BattleCoreData.GetActiveCreature(battle_side.B)
                set EnemyAtkIdx = BattleCoreData.PickRandomAttackIndexByLevel(Player, battle_side.B)

                # --- 2) WHO GOES FIRST? (speed order) ---
                var FirstIsA:logic = false
                if (BattleCoreData.DoesASideActFirst() = true):
                    set FirstIsA = true
                    Print("Attack - Moxie A will attack first!")
                else:
                    set FirstIsA = false
                    Print("Attack - Debug. Moxie B will attack first!")

                # --- 3) EXECUTE TURN ACTIONS (with narration + waits) ---
                var EndTurnNow:logic = false

                # 3.0) Items 
                if (UsedItem?):
                    Print("Player used an item.")
                    Sleep(1.0)

                    if (not BattleCoreData.IsOver[]):
                        # Wild acts after item
                        BattleCoreData.DoAttackSequence(Player, battle_side.B, battle_side.A, EnemyAtkIdx)

                        if (not BattleCoreData.IsOver[]):
                            # If player fainted, force manual team-button swap.
                            CanContinue := RequireManualPlayerSwapIfFainted(Player)
                            if (not CanContinue?):
                                break

                            # If a manual swap occurred due to faint, the turn is done.
                            # (RequireManualPlayerSwapIfFainted only swaps when you were at 0 HP)
                            set EndTurnNow = true

                else:
                    # 3.1) SWITCH IS ALWAYS PRIORITY (ignores speed)
                    if (UsedSwitch?):
                        ShowOnlyBattleInformation(Player)

                        SwapOk := SwapPlayerMoxie(Player, PlayerSwitchIdx)
                        if (not SwapOk?):
                            FastTypewriteBattleText(Player, "Can't swap to that Moxie.", 1.0)
                            set EndTurnNow = true
                        else:
                            # Switch consumes your turn. Then wild acts.
                            if (not BattleCoreData.IsOver[]):
                                BattleCoreData.DoAttackSequence(Player, battle_side.B, battle_side.A, EnemyAtkIdx)

                                if (not BattleCoreData.IsOver[]):
                                    # If Wild KOs the new active, force manual swap.
                                    CanContinue := RequireManualPlayerSwapIfFainted(Player)
                                    if (not CanContinue?):
                                        break

                            set EndTurnNow = true

                    else:
                        # 3.2) NORMAL ATTACK FLOW (speed order)
                        if (FirstIsA?):
                            # A attacks B
                            BattleCoreData.DoAttackSequence(Player, battle_side.A, battle_side.B, PlayerAtkIdx)
                            Print("A is attacking now!")

                            #if (not BattleCoreData.IsOver[]):
                            # Wild side auto swap, but now with XP/leveling phase in the middle
                            SwapRes := TryAutoSwapAndRefresh_WithXP(Player, battle_side.B)
                            CanContinue := SwapRes(0)
                            DidSwap := SwapRes(1)

                            if (not CanContinue?):
                                break

                            if (DidSwap?):
                                set EndTurnNow = true

                            # B attacks A (only if not aborted)
                            if (not EndTurnNow? and not BattleCoreData.IsOver[]):
                                BattleCoreData.DoAttackSequence(Player, battle_side.B, battle_side.A, EnemyAtkIdx)

                                if (not BattleCoreData.IsOver[]):
                                    CanContinue2 := RequireManualPlayerSwapIfFainted(Player)
                                    if (not CanContinue2?):
                                        break

                                    # If faint swap happened here, turn ends
                                    set EndTurnNow = true

                        else:
                            # B attacks A first
                            BattleCoreData.DoAttackSequence(Player, battle_side.B, battle_side.A, EnemyAtkIdx)

                            if (BattleCoreData.IsOver[]):
                                # battle ended from this hit
                                set EndTurnNow = true
                            else:
                                # Only force manual swap if A actually fainted
                                if (not BattleCoreData.IsOver[] and BattleCoreData.GetCurrentHealthOfActiveMoxieSide(battle_side.A) <= 0.0):
                                    CanContinue := RequireManualPlayerSwapIfFainted(Player)
                                    if (not CanContinue?):
                                        break

                                    # If you had to swap because you fainted, your action is consumed this turn
                                    set EndTurnNow = true
                                else:
                                    # A survived, so A should still act this turn
                                    set EndTurnNow = false

                            # A attacks B second (only if not aborted)
                            if (not EndTurnNow? and not BattleCoreData.IsOver[]):
                                BattleCoreData.DoAttackSequence(Player, battle_side.A, battle_side.B, PlayerAtkIdx)

                                #if (not BattleCoreData.IsOver[]):
                                # Wild side auto swap, but now with XP/leveling phase in the middle
                                SwapRes := TryAutoSwapAndRefresh_WithXP(Player, battle_side.B)
                                CanContinueB := SwapRes(0)
                                DidSwapB := SwapRes(1)

                                if (not CanContinueB?):
                                    break

                                if (DidSwapB?):
                                    set EndTurnNow = true



                if (BattleCoreData.IsOver[]):
                    AnnounceBattleEnd(Player)
                    break

                # Update the Player's Moxie Stats
                UpdatePlayerMoxieStatsInfo(Player)

                CurrentHPA := BattleCoreData.GetCurrentHealthOfActiveMoxieSide(battle_side.A)
                CurrentHPB := BattleCoreData.GetCurrentHealthOfActiveMoxieSide(battle_side.B)

                # --- 4) END TURN ---
                Print("TURN END => HP(A:{CurrentHPA} B:{CurrentHPB})")
                Print("")
                ClearPendingInput(Player)
                # Update All Moxie Team Data when a turn is ended.
                UpdatePlayerMoxieTeamData(Player)
                set Turn += 1

                # Show the UI for the Battle Selection
                ShowBattleSelectionInfoOverlay(Player)
                FastTypewriteBattleText(Player, "What will your Moxie do?", 1.0)

            # End battle result
            if (Turn > SafetyMaxTurns):
                Print("Battle ended by SafetyMaxTurns.")
                AnnounceBattleEnd(Player)
                RemoveEndBattleWidget(Player, UIBattleInfo)
            else:
                if (BattleCoreData.IsOver[]):
                    AnnounceBattleEnd(Player)
                RemoveEndBattleWidget(Player, UIBattleInfo)

    # -------------------------------------------------------------------------------------------------------------------------------------
  
    ResetBattleEndAnnounced(Player:player):void =
            if (set BattleEndAnnouncedByPlayer[Player] = false) {}
    # -------------------------------------------------------------------------------------------------------------------------------------

    HasAnnouncedBattleEnd(Player:player)<transacts>:logic =
        if (B := BattleEndAnnouncedByPlayer[Player]):
            return B
        return false
    # -------------------------------------------------------------------------------------------------------------------------------------

    TryAnnounceBattleEndOnce(Player:player):void =
        # already announced?
        if (HasAnnouncedBattleEnd(Player)?):
            return 

        BattleCoreData := GetOrCreateCore(Player)
        if (BattleCoreData.IsOver[]):
            # lock it
            if (set BattleEndAnnouncedByPlayer[Player] = true) {}

            # ensure only text is visible
            ShowOnlyBattleInformation(Player)

            # announce
            spawn { AnnounceBattleEnd(Player) }

    # -------------------------------------------------------------------------------------------------------------------------------------

    AnnounceBattleEnd(Player:player)<suspends>:void =

        if (HasAnnouncedBattleEnd(Player)?):
            return 

        # Update All the Moxie Team Data when Battle Is Over.
        UpdatePlayerMoxieTeamData(Player)

        # Only show the battle information text (hide buttons/overlays)
        ShowOnlyBattleInformation(Player)

        Core := GetOrCreateCore(Player)

        # Player = Side A. If A still has an active living moxie, player won.
        # (When the battle is over, one team is defeated.)
        PlayerHP := Core.GetCurrentHealthOfActiveMoxieSide(battle_side.A)        

        PlayerWon : logic = logic{ PlayerHP > 0.0 }

        # Play fainted animation to Wild (last) Moxie
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            if(PlayerWon?):
                #PlayFaintedAnimUIRight(Player, UIBattleInfo.MoxieWidgeRight)
            else:
                PlayFaintedAnimUILeft(Player, UIBattleInfo.MoxieWidgeLeft)

        EndText := Core.GetBattleEndText(PlayerWon)
        UpdateBattleInformationText(Player, EndText, 2.0)

        # small pause so the player actually sees it
        Sleep(2.0)

        if (set BattleEndAnnouncedByPlayer[Player] = true) {}
    # -------------------------------------------------------------------------------------------------------------------------------------

    RemoveEndBattleWidget(Player:player, UIBattleInfo:battle_ui_info): void = 
        if (PlayerUI:=GetPlayerUI[Player]):
            UpdateShouldCancelAnimations(Player, true)  
            PlayerUI.RemoveWidget(UIBattleInfo.Canvas)
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetNextLeftAnimVersion(Player:player):int =
        var V:int = 0
        if (Cur := LeftAnimVersionByPlayer[Player]):
            set V = Cur + 1
        else:
            set V = 1
        if (set LeftAnimVersionByPlayer[Player] = V) {}
        return V
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetNextRightAnimVersion(Player:player):int =
        var V:int = 0
        if (Cur := RightAnimVersionByPlayer[Player]):
            set V = Cur + 1
        else:
            set V = 1
        if (set RightAnimVersionByPlayer[Player] = V) {}
        return V
    # -------------------------------------------------------------------------------------------------------------------------------------
    ResetMoxieAnimsLeft(MoxieWidget:Widgets.Test.WBP_Moxie_Left):void =
        set MoxieWidget.PlayIdleAnim = 0.0
        set MoxieWidget.PlayScratchAnim = 0.0
        Print("Anim - ResetMoxieAnimsLeft")
    # -------------------------------------------------------------------------------------------------------------------------------------

    PlayIdleLeft(MoxieWidget:Widgets.Test.WBP_Moxie_Left):void =
        ResetMoxieAnimsLeft(MoxieWidget)
        set MoxieWidget.PlayIdleAnim = 1.0
        Print("Anim - PlayIdleLeft")
    # -------------------------------------------------------------------------------------------------------------------------------------

    ResetMoxieAnimsRight(MoxieWidget:Widgets.Test.WBP_Moxie_Right):void =
        set MoxieWidget.PlayIdleAnim = 0.0
        set MoxieWidget.PlayScratchAnim = 0.0
    # -------------------------------------------------------------------------------------------------------------------------------------

    PlayIdleRight(MoxieWidget:Widgets.Test.WBP_Moxie_Right):void =
        ResetMoxieAnimsRight(MoxieWidget)
        set MoxieWidget.PlayIdleAnim = 1.0
    # -------------------------------------------------------------------------------------------------------------------------------------

    var Left_IsIdleNext:logic = true
    # Loop the animation forever
    LoopIdleAnimationUILeft(Player:player, MoxieWidget: Widgets.Test.WBP_Moxie_Left)<suspends>:void =
        #Print("Moxie - Anim Loop Started")
        var TimeToWait: float = 0.0
        loop:
            if (UIBattle1v1Info := PlayerBattleInfoMap[Player], UIBattle1v1Info.AnimationLoopCancelledLeft = true):
                #Print("Animation Left loop cancelled, breaking out")
                break
            if (Left_IsIdleNext?):
                #Print("Moxie - Idle anim selected")
                # Time where the animation restart, if Idle Animation changes, change these ones.
                Rand:= GetRandomInt(0,2)
                case(Rand):
                    0 => set TimeToWait = 6.30
                    1 => set TimeToWait = 9.0
                    2 => set TimeToWait = 11.80
                    _ => set TimeToWait = 9.0
                #Print("Anim - Got Rand: {Rand}, waiting: {TimeToWait}s")
                set MoxieWidget.PlayIdleAnim = 1.0  
                set MoxieWidget.PlayScratchAnim = 0.0 
            else:
                #Print("Moxie - Scratch anim selected")
                set TimeToWait = 0.05
                set MoxieWidget.PlayScratchAnim = 1.0 
                set MoxieWidget.PlayIdleAnim = 0.0 

            if (Left_IsIdleNext?):
                set Left_IsIdleNext = false
                #Print("Moxie - IsIdleNext is true turning to false")
            else:
                set Left_IsIdleNext = true
                #Print("Moxie - IsIdleNext is false turning to true")

            Sleep(TimeToWait)
            #Print("Moxie - Anim Loop End, setting a new one")
            spawn{LoopIdleAnimationUILeft(Player, MoxieWidget)}
            break
    # -------------------------------------------------------------------------------------------------------------------------------------

    var Right_IsIdleNext:logic = false
    # Loop the animation forever
    LoopIdleAnimationUIRight(Player:player, MoxieWidget: Widgets.Test.WBP_Moxie_Right)<suspends>:void =
        #Print("Moxie - Anim Loop Started")
        var TimeToWait: float = 0.0
        loop:
            if (UIBattle1v1Info := PlayerBattleInfoMap[Player], UIBattle1v1Info.AnimationLoopCancelledRight = true):
                #Print("Animation Right loop cancelled, breaking out")
                break
            if (Right_IsIdleNext?):	
                #Print("Moxie - Idle anim selected")
                # Time where the animation restart, if Idle Animation changes, change these ones.
                Rand:= GetRandomInt(0,2)
                case(Rand):
                    0 => set TimeToWait = 6.30
                    1 => set TimeToWait = 9.0
                    2 => set TimeToWait = 11.80
                    _ => set TimeToWait = 9.0

                set TimeToWait = GetRandomFloat(8.0, 12.0)
                set MoxieWidget.PlayIdleAnim = 1.0  
                set MoxieWidget.PlayScratchAnim = 0.0 
            else:
                #Print("Moxie - Scratch anim selected")
                set TimeToWait = 0.05
                set MoxieWidget.PlayScratchAnim = 1.0 
                set MoxieWidget.PlayIdleAnim = 0.0 

            if (Right_IsIdleNext?):
                set Right_IsIdleNext = false
                #Print("Moxie - IsIdleNext is true turning to false")
            else:
                set Right_IsIdleNext = true
                #Print("Moxie - IsIdleNext is false turning to true")

            Sleep(TimeToWait)
            #Print("Moxie - Anim Loop End, setting a new one")
            spawn{LoopIdleAnimationUIRight(Player, MoxieWidget)}
            break
    # -------------------------------------------------------------------------------------------------------------------------------------

    PlayDamagedAnimUILeft(Player:player, MoxieWidget: Widgets.Test.WBP_Moxie_Left)<suspends>:void =   
        Print("Moxie - Left Damaged anim selected")
        Sleep(1.9)
        set MoxieWidget.PlayDamagedAnim = 1.0 
        set MoxieWidget.PlayIdleAnim = 0.0  
        set MoxieWidget.PlayScratchAnim = 0.0 
        Sleep(0.4)
        set MoxieWidget.PlayDamagedAnim = 0.0
    # -------------------------------------------------------------------------------------------------------------------------------------

    PlayDamagedAnimUIRight(Player:player, MoxieWidget: Widgets.Test.WBP_Moxie_Right)<suspends>:void =   
        Print("Moxie - Right Damaged anim selected")
        Sleep(1.9)
        set MoxieWidget.PlayDamagedAnim = 1.0 
        set MoxieWidget.PlayIdleAnim = 0.0  
        set MoxieWidget.PlayScratchAnim = 0.0 
        Sleep(0.4)
        set MoxieWidget.PlayDamagedAnim = 0.0
    # -------------------------------------------------------------------------------------------------------------------------------------
    
    PlayFaintedAnimUILeft(Player:player, MoxieWidget: Widgets.Test.WBP_Moxie_Left)<suspends>:void =   
        Print("Moxie - Left Fainted anim selected")
        set MoxieWidget.PlayFaintedAnim = 1.0 
        set MoxieWidget.PlayDamagedAnim = 0.0 
        set MoxieWidget.PlaySwapAnim = 0.0 
        set MoxieWidget.PlayIdleAnim = 0.0  
        set MoxieWidget.PlayScratchAnim = 0.0 
        Sleep(0.5)
        set MoxieWidget.PlayFaintedAnim = 0.0
    # -------------------------------------------------------------------------------------------------------------------------------------

    PlayFaintedAnimUIRight(Player:player, MoxieWidget: Widgets.Test.WBP_Moxie_Right)<suspends>:void =   
        Print("Moxie - Right Fainted anim selected")
        set MoxieWidget.PlayFaintedAnim = 1.0 
        set MoxieWidget.PlayDamagedAnim = 0.0 
        set MoxieWidget.PlaySwapAnim = 0.0 
        set MoxieWidget.PlayIdleAnim = 0.0  
        set MoxieWidget.PlayScratchAnim = 0.0 
        Sleep(0.5)
        set MoxieWidget.PlayFaintedAnim = 0.0
    # -------------------------------------------------------------------------------------------------------------------------------------

    PlaySwappedAnimUILeft(Player:player, MoxieWidget: Widgets.Test.WBP_Moxie_Left)<suspends>:void =   
        Print("Moxie - Left Swapped anim selected")
        set MoxieWidget.PlaySwapAnim = 1.0 
        set MoxieWidget.PlayIdleAnim = 0.0  
        set MoxieWidget.PlayFaintedAnim = 0.0 
        set MoxieWidget.PlayDamagedAnim = 0.0 
        set MoxieWidget.PlayScratchAnim = 0.0 
        Sleep(0.5)
        set MoxieWidget.PlaySwapAnim = 0.0 
    # -------------------------------------------------------------------------------------------------------------------------------------

    PlaySwappedAnimUIRight(Player:player, MoxieWidget: Widgets.Test.WBP_Moxie_Right)<suspends>:void =   
        Print("Moxie - Right Swapped anim selected")
        set MoxieWidget.PlaySwapAnim = 1.0 
        set MoxieWidget.PlayIdleAnim = 0.0 
        set MoxieWidget.PlayFaintedAnim = 0.0  
        set MoxieWidget.PlayDamagedAnim = 0.0 
        set MoxieWidget.PlayScratchAnim = 0.0 
        Sleep(0.5)
        set MoxieWidget.PlaySwapAnim = 0.0 
    # -------------------------------------------------------------------------------------------------------------------------------------


    UpdateShouldCancelAnimations(Player:player, ShouldCancel:logic): void =
        if(UIBattleInfo := PlayerBattleInfoMap[Player]):  
            NewUIBattleInfo := battle_ui_info:
                FightButton:= UIBattleInfo.FightButton
                ItemsButton:= UIBattleInfo.ItemsButton
                RunButton:= UIBattleInfo.RunButton
                TeamInfoButton:= UIBattleInfo.TeamInfoButton
                StatsText:= UIBattleInfo.StatsText
                Attack1Button:= UIBattleInfo.Attack1Button
                Attack2Button:= UIBattleInfo.Attack2Button
                Attack3Button:= UIBattleInfo.Attack3Button
                Attack4Button:= UIBattleInfo.Attack4Button
                AttackBackButton:= UIBattleInfo.AttackBackButton
                ConfirmAttackButton:= UIBattleInfo.ConfirmAttackButton
                CancelAttackButton:= UIBattleInfo.CancelAttackButton
                ContinueBattleTextButton:= UIBattleInfo.ContinueBattleTextButton
                TeamInfoBackButton:= UIBattleInfo.TeamInfoBackButton

                PlayerMoxie_HealthbarMat:= UIBattleInfo.PlayerMoxie_HealthbarMat
                WildMoxie_HealthbarMat:= UIBattleInfo.WildMoxie_HealthbarMat
                PlayerMoxie_XPMat:= UIBattleInfo.PlayerMoxie_XPMat

                BattleSelectionInfoOverlay:= UIBattleInfo.BattleSelectionInfoOverlay
                AttackSelectionInfoOverlay:= UIBattleInfo.AttackSelectionInfoOverlay
                ConfirmAttackInfo:= UIBattleInfo.ConfirmAttackInfo
                BattleInformationOverlay:= UIBattleInfo.BattleInformationOverlay
                PlayerTeamWidgetOverlay:= UIBattleInfo.PlayerTeamWidgetOverlay
                PlayerTeamButtonsOverlay:= UIBattleInfo.PlayerTeamButtonsOverlay

                ConfirmAttackInfoName:= UIBattleInfo.ConfirmAttackInfoName
                ConfirmAttackInfoDesc:= UIBattleInfo.ConfirmAttackInfoDesc
                BattleInformationText:= UIBattleInfo.BattleInformationText

                MoxieWidgeRight:= UIBattleInfo.MoxieWidgeRight
                MoxieWidgeLeft:= UIBattleInfo.MoxieWidgeLeft

                MoxieTeamWidget_0:= UIBattleInfo.MoxieTeamWidget_0
                MoxieTeamWidget_1:= UIBattleInfo.MoxieTeamWidget_1
                MoxieTeamWidget_2:= UIBattleInfo.MoxieTeamWidget_2
                MoxieTeamWidget_3:= UIBattleInfo.MoxieTeamWidget_3
                MoxieTeamWidget_4:= UIBattleInfo.MoxieTeamWidget_4
                MoxieTeamWidget_5:= UIBattleInfo.MoxieTeamWidget_5

                MoxieTeamButton_0:= UIBattleInfo.MoxieTeamButton_0
                MoxieTeamButton_1:= UIBattleInfo.MoxieTeamButton_1
                MoxieTeamButton_2:= UIBattleInfo.MoxieTeamButton_2
                MoxieTeamButton_3:= UIBattleInfo.MoxieTeamButton_3
                MoxieTeamButton_4:= UIBattleInfo.MoxieTeamButton_4
                MoxieTeamButton_5:= UIBattleInfo.MoxieTeamButton_5

                AnimationLoopCancelledRight:= ShouldCancel
                AnimationLoopCancelledLeft:= ShouldCancel

                Canvas:= UIBattleInfo.Canvas

            if(set PlayerBattleInfoMap[Player] = NewUIBattleInfo){}

    # =====================================================================================================================================

    CreateBattleCanvas(Player:player):void =

        MoxieWidgeRight: Widgets.Test.WBP_Moxie_Right = Widgets.Test.WBP_Moxie_Right{}
        MoxieWidgeLeft: Widgets.Test.WBP_Moxie_Left = Widgets.Test.WBP_Moxie_Left{}

        MoxieTeamWidget_0: Widgets.Test.WBP_Moxie_Team_Item = Widgets.Test.WBP_Moxie_Team_Item{}
        MoxieTeamWidget_1: Widgets.Test.WBP_Moxie_Team_Item = Widgets.Test.WBP_Moxie_Team_Item{} 
        MoxieTeamWidget_2: Widgets.Test.WBP_Moxie_Team_Item = Widgets.Test.WBP_Moxie_Team_Item{} 
        MoxieTeamWidget_3: Widgets.Test.WBP_Moxie_Team_Item = Widgets.Test.WBP_Moxie_Team_Item{} 
        MoxieTeamWidget_4: Widgets.Test.WBP_Moxie_Team_Item = Widgets.Test.WBP_Moxie_Team_Item{} 
        MoxieTeamWidget_5: Widgets.Test.WBP_Moxie_Team_Item = Widgets.Test.WBP_Moxie_Team_Item{} 

        MoxieTeamButton_0:= button_quiet{DefaultText:=CreateMessage("!")}
        MoxieTeamButton_1:= button_quiet{DefaultText:=CreateMessage("!")}
        MoxieTeamButton_2:= button_quiet{DefaultText:=CreateMessage("!")}
        MoxieTeamButton_3:= button_quiet{DefaultText:=CreateMessage("!")}
        MoxieTeamButton_4:= button_quiet{DefaultText:=CreateMessage("!")}
        MoxieTeamButton_5:= button_quiet{DefaultText:=CreateMessage("!")}


        var AnimationLoopCancelledRight: logic = false
        var AnimationLoopCancelledLeft: logic = false

        ImageBackground :=texture_block{DefaultImage:=Assets.BattleBG, DefaultDesiredSize:=vector2{X:=1920.0, Y:=1080.0}}

        FightButton:=button_regular{DefaultText:=CreateMessage("Fight")}
        ItemsButton:=button_regular{DefaultText:=CreateMessage("Catch")} # TODO -  Change here
        # TODO - DISABLE THIS UNTIL ITEMS ARE IMPLEMENTED
        ItemsButton.SetEnabled(true)

        RunButton:=button_regular{DefaultText:=CreateMessage(" Run ")}

        TeamInfoButton:=button_regular{DefaultText:=CreateMessage("    \nTEAM\n    ")}
        StatsText:= text_block{DefaultText := CreateMessage("Stats"), DefaultTextColor := NamedColors.White}

        Attack1Button:=button_regular{DefaultText:=CreateMessage("Attack 1")}
        Attack2Button:=button_regular{DefaultText:=CreateMessage("Attack 2")}
        Attack3Button:=button_regular{DefaultText:=CreateMessage("Attack 3")}
        Attack4Button:=button_regular{DefaultText:=CreateMessage("Attack 4")}
        
        var Attack1_MoxieColorMat : UI.Materials.M_MoxieColorBG = UI.Materials.M_MoxieColorBG{}
        var Attack2_MoxieColorMat : UI.Materials.M_MoxieColorBG = UI.Materials.M_MoxieColorBG{}
        var Attack3_MoxieColorMat : UI.Materials.M_MoxieColorBG = UI.Materials.M_MoxieColorBG{}
        var Attack4_MoxieColorMat : UI.Materials.M_MoxieColorBG = UI.Materials.M_MoxieColorBG{}

        Attack1_MaterialBlock:=material_block{DefaultImage:=Attack1_MoxieColorMat}
        Attack2_MaterialBlock:=material_block{DefaultImage:=Attack2_MoxieColorMat}
        Attack3_MaterialBlock:=material_block{DefaultImage:=Attack3_MoxieColorMat}
        Attack4_MaterialBlock:=material_block{DefaultImage:=Attack4_MoxieColorMat}

        var PlayerMoxie_HealthbarMat : UI.Materials.M_MoxieBaseBar = UI.Materials.M_MoxieBaseBar{}
        var WildMoxie_HealthbarMat : UI.Materials.M_MoxieBaseBar = UI.Materials.M_MoxieBaseBar{}
        var PlayerMoxie_XPMat : UI.Materials.M_MoxieBaseBar = UI.Materials.M_MoxieBaseBar{}

        PlayerMoxie_HealthbarMaterialBlock:=material_block{DefaultImage:=PlayerMoxie_HealthbarMat}
        WildMoxie_HealthbarMaterialBlock:=material_block{DefaultImage:=WildMoxie_HealthbarMat}
        PlayerMoxie_XPMaterialBlock:=material_block{DefaultImage:=PlayerMoxie_XPMat}

        ConfirmAttackButton:=button_regular{DefaultText:=CreateMessage("Attack")}
        CancelAttackButton:=button_regular{DefaultText:=CreateMessage("Back")}
        AttackBackButton:=button_quiet{DefaultText:=CreateMessage("   Back   ")}
        ContinueBattleTextButton:=button_quiet{DefaultText:=CreateMessage("Continue")}
        TeamInfoBackButton:=button_quiet{DefaultText:=CreateMessage("   Back   ")}

        ConfirmAttackInfoName:= text_block{DefaultText := CreateMessage("Attack Name"), DefaultTextColor := NamedColors.White}
        ConfirmAttackInfoDesc:= text_block{DefaultText := CreateMessage("Attack Description"), DefaultTextColor := NamedColors.White}
        BattleInformationText:= text_block{DefaultText := CreateMessage(""), DefaultTextColor := NamedColors.White, DefaultJustification:= text_justification.Center}


        PlayerTeamWidgets:= overlay:
            Slots:=array:
                overlay_slot:
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Center
                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                    Widget:=stack_box:
                        Orientation:=orientation.Vertical
                        Slots:=array:
                            # FIRST ROW
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=-450.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:=stack_box:
                                    Orientation:=orientation.Horizontal
                                    Slots:=array:
                                        # Moxie Team Slot 0
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{0.4} 
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                            Widget:= overlay:
                                                Slots:=array:                                                  
                                                    overlay_slot:
                                                        # Moxie 0 Display Widget
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= MoxieTeamWidget_0

                                        # Moxie Team Slot 1
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{0.4} 
                                            Padding:=margin{Top:=0.0, Right:=-500.0, Bottom:=0.0, Left:=-500.0}
                                            Widget:= overlay:
                                                Slots:=array:                                      
                                                    overlay_slot:
                                                        # Moxie 1 Display Widget
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= MoxieTeamWidget_1

                                        # Moxie Team Slot 2
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{0.4} 
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                            Widget:= overlay:
                                                Slots:=array:                                      
                                                    overlay_slot:
                                                        # Moxie 2 Display Widget
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= MoxieTeamWidget_2

                            # SECOND ROW
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=-450.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:=stack_box:
                                    Orientation:=orientation.Horizontal
                                    Slots:=array:
                                        # Moxie Team Slot 3
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{0.4} 
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                            Widget:= overlay:
                                                Slots:=array:                                                  
                                                    overlay_slot:
                                                        # Moxie 3 Display Widget
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= MoxieTeamWidget_3

                                        # Moxie Team Slot 4
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{0.4} 
                                            Padding:=margin{Top:=0.0, Right:=-500.0, Bottom:=0.0, Left:=-500.0}
                                            Widget:= overlay:
                                                Slots:=array:                                      
                                                    overlay_slot:
                                                        # Moxie 4 Display Widget
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= MoxieTeamWidget_4

                                        # Moxie Team Slot 5
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{0.4} 
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                            Widget:= overlay:
                                                Slots:=array:                                      
                                                    overlay_slot:
                                                        # Moxie 5 Display Widget
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= MoxieTeamWidget_5

        PlayerTeamButtons:= overlay:
            Slots:=array:
                overlay_slot:
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Center
                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                    Widget:=stack_box:
                        Orientation:=orientation.Vertical
                        Slots:=array:
                            # FIRST ROW
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:=stack_box:
                                    Orientation:=orientation.Horizontal
                                    Slots:=array:
                                        # Moxie Team Slot 0
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{0.4} 
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                            Widget:= overlay:
                                                Slots:=array:                                                  
                                                    overlay_slot:
                                                        # Moxie 0 Selection Button
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= MoxieTeamButton_0

                                        # Moxie Team Slot 1
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{0.4} 
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=100.0}
                                            Widget:= overlay:
                                                Slots:=array:                                      
                                                    overlay_slot:
                                                        # Moxie 1 Selection Button
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= MoxieTeamButton_1

                                        # Moxie Team Slot 2
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{0.4} 
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=135.0}
                                            Widget:= overlay:
                                                Slots:=array:                                      
                                                    overlay_slot:
                                                        # Moxie 2 Selection Button
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= MoxieTeamButton_2

                            # SECOND ROW
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=75.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:=stack_box:
                                    Orientation:=orientation.Horizontal
                                    Slots:=array:
                                        # Moxie Team Slot 3
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{0.4} 
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                            Widget:= overlay:
                                                Slots:=array:                                                  
                                                    overlay_slot:
                                                        # Moxie 3 Selection Button
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= MoxieTeamButton_3

                                        # Moxie Team Slot 4
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{0.4} 
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=100.0}
                                            Widget:= overlay:
                                                Slots:=array:                                      
                                                    overlay_slot:
                                                        # Moxie 4 Selection Button
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= MoxieTeamButton_4

                                        # Moxie Team Slot 5
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{0.4} 
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=135.0}
                                            Widget:= overlay:
                                                Slots:=array:                                      
                                                    overlay_slot:
                                                        # Moxie 5 Selection Button
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= MoxieTeamButton_5

                overlay_slot:
                        HorizontalAlignment:=horizontal_alignment.Center
                        VerticalAlignment:=vertical_alignment.Center
                        Padding:=margin{Top:=100.0, Right:=0.0, Bottom:=0.0, Left:=400.0}
                        Widget:= TeamInfoBackButton

        BattleSelectionInfo:=overlay:
            Slots:=array:
                overlay_slot:
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Center
                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                    Widget:=stack_box:
                        Orientation:=orientation.Horizontal
                        Slots:=array:
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Right
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.6}
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:=stack_box:
                                    Orientation:=orientation.Vertical
                                    Slots:=array:
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{0.4}
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=20.0, Left:=0.0}
                                            Widget:=FightButton
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{0.4}
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=20.0, Left:=0.0}
                                            Widget:=ItemsButton
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{0.4}
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=15.0, Left:=0.0}
                                            Widget:=RunButton                        
                        
        AttackSelectionInfo:=overlay:
            Slots:=array:
                overlay_slot:
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Bottom
                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                    Widget:=stack_box:
                        Orientation:=orientation.Vertical
                        Slots:=array:
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Right
                                VerticalAlignment:=vertical_alignment.Bottom
                                #Distribution:=option{0.6}
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:=stack_box:
                                    Orientation:=orientation.Horizontal
                                    Slots:=array:
                                        # LEFT COLUMN: Attack 1 and Back
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{0.4}
                                            Padding:=margin{Top:=0.0, Right:=10.0, Bottom:=20.0, Left:=0.0}
                                            Widget:=stack_box:
                                                Orientation:=orientation.Vertical
                                                Slots:=array:
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Right
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        #Distribution:=option{0.4}
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=20.0, Left:=0.0}
                                                        Widget:= overlay:
                                                            Slots:=array:
                                                                overlay_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Fill
                                                                    VerticalAlignment:=vertical_alignment.Fill
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= Attack1_MaterialBlock      
                                                                overlay_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    VerticalAlignment:=vertical_alignment.Bottom
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= Attack1Button                                                                                                        
                    
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Right
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        #Distribution:=option{0.4}
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=10.0, Left:=0.0}
                                                        Widget:= overlay:
                                                            Slots:=array:
                                                                overlay_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Fill
                                                                    VerticalAlignment:=vertical_alignment.Fill
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= Attack3_MaterialBlock      
                                                                overlay_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    VerticalAlignment:=vertical_alignment.Bottom
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= Attack3Button   
                                        # RIGHT COLUMN: Attack 2 and Attack 3
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{10.0}
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=20.0, Left:=10.0}
                                            Widget:=stack_box:
                                                Orientation:=orientation.Vertical
                                                Slots:=array:
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Left
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        #Distribution:=option{5.0}
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=20.0, Left:=0.0}
                                                        Widget:= overlay:
                                                            Slots:=array:
                                                                overlay_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Fill
                                                                    VerticalAlignment:=vertical_alignment.Fill
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= Attack2_MaterialBlock      
                                                                overlay_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Fill
                                                                    VerticalAlignment:=vertical_alignment.Fill
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= Attack2Button 
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Left
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        #Distribution:=option{5.0}
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=10.0, Left:=0.0}
                                                        Widget:= overlay:
                                                            Slots:=array:
                                                                overlay_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Fill
                                                                    VerticalAlignment:=vertical_alignment.Fill
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= Attack4_MaterialBlock      
                                                                overlay_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Fill
                                                                    VerticalAlignment:=vertical_alignment.Fill
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= Attack4Button

                            # Back from Attack Selection
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Bottom
                                #Distribution:=option{5.0}
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=10.0, Left:=10.0}
                                Widget:= AttackBackButton

        ConfirmAttackInfo:=overlay:
            Slots:=array:
                overlay_slot:
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Bottom
                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                    Widget:=stack_box:
                        Orientation:=orientation.Vertical
                        Slots:=array:
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Bottom
                                #Distribution:=option{0.4}
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=20.0, Left:=0.0}
                                Widget:= ConfirmAttackInfoName


                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Bottom
                                #Distribution:=option{0.6}
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=20.0, Left:=0.0}
                                Widget:= ConfirmAttackInfoDesc

                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Bottom
                                #Distribution:=option{0.6}
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=20.0}
                                 Widget:=stack_box:
                                    Orientation:=orientation.Horizontal
                                    Slots:=array:
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Left
                                            VerticalAlignment:=vertical_alignment.Bottom
                                            #Distribution:=option{0.4}
                                            Padding:=margin{Top:=0.0, Right:=25.0, Bottom:=20.0, Left:=0.0}
                                            Widget:= CancelAttackButton

                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Bottom
                                            #Distribution:=option{0.6}
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=20.0, Left:=25.0}
                                            Widget:= ConfirmAttackButton

        MoxieWidgetRight:=overlay:
            Slots:=array:
                overlay_slot:
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Center
                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                    Widget:=stack_box:
                        Orientation:=orientation.Vertical
                        Slots:=array:
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Top
                                #Distribution:=option{0.4}
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=20.0, Left:=0.0}
                                Widget:= text_block{DefaultText := CreateMessage("Wild Moxie"), DefaultTextColor := NamedColors.White}

                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Fill
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4}
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:= WildMoxie_HealthbarMaterialBlock

                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Bottom
                                #Distribution:=option{0.4}
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=20.0, Left:=0.0}
                                Widget:= MoxieWidgeRight

        MoxieWidgetLeft:=overlay:
            Slots:=array:
                overlay_slot:
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Center
                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                    Widget:=stack_box:
                        Orientation:=orientation.Vertical
                        Slots:=array:
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Top
                                #Distribution:=option{0.4}
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=20.0, Left:=0.0}
                                Widget:= text_block{DefaultText := CreateMessage("Your Moxie"), DefaultTextColor := NamedColors.White} 

                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Fill
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4}
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:= PlayerMoxie_HealthbarMaterialBlock

                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Fill
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4}
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=10.0, Left:=0.0}
                                Widget:= PlayerMoxie_XPMaterialBlock

                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Bottom
                                #Distribution:=option{0.4}
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=20.0, Left:=0.0}
                                Widget:= MoxieWidgeLeft 

        BattleInformation:=overlay:
            Slots:=array:
                overlay_slot:
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Bottom
                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                    Widget:=stack_box:
                        Orientation:=orientation.Vertical
                        Slots:=array:
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:= BattleInformationText 



        Canvas:=canvas:
            Slots:=array:
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    Widget:=overlay:
                        Slots:=array:
                            overlay_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:= ImageBackground

                            overlay_slot:
                                VerticalAlignment:=vertical_alignment.Center
                                HorizontalAlignment:=horizontal_alignment.Center
                                Padding:=margin{Top:=815.0, Right:=640.0, Bottom:=0.0, Left:=0.0} 
                                Widget:= PlayerTeamWidgets               

                            overlay_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:= stack_box:
                                    Orientation:=orientation.Vertical
                                    Slots:=array:
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Top
                                            #Distribution:=option{0.4}
                                            Padding:=margin{Top:=130.0, Right:=0.0, Bottom:=20.0, Left:=0.0}
                                            Widget:=stack_box:
                                                Orientation:=orientation.Horizontal
                                                Slots:=array:
                                                    # Left Moxie Widget Display
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Left
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        #Distribution:=option{0.4}
                                                        Padding:=margin{Top:=0.0, Right:=120.0, Bottom:=20.0, Left:=0.0}
                                                        Widget:= MoxieWidgetLeft
                                                    # Right Moxie Widget Display
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Right
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        #Distribution:=option{0.4}
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=20.0, Left:=120.0}
                                                        Widget:= MoxieWidgetRight

                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{0.4}
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=60.0, Left:=0.0}
                                            Widget:=overlay:
                                                Slots:=array:

                                                    overlay_slot:
                                                        VerticalAlignment:=vertical_alignment.Fill
                                                        HorizontalAlignment:=horizontal_alignment.Fill
                                                        Widget:= text_block{DefaultText := CreateMessage(""), DefaultTextColor := NamedColors.White} # Any background?                                                  
                                                
                                                    overlay_slot:
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        HorizontalAlignment:=horizontal_alignment.Fill
                                                        Padding:=margin{Top:=10.0, Right:=0.0, Bottom:=80.0, Left:=0.0} 
                                                        Widget:= overlay:
                                                            Slots:=array:
                                                                overlay_slot:
                                                                    VerticalAlignment:=vertical_alignment.Bottom
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=35.0, Left:=600.0} 
                                                                    Widget:= BattleSelectionInfo
                                                                overlay_slot:
                                                                    VerticalAlignment:=vertical_alignment.Bottom
                                                                    HorizontalAlignment:=horizontal_alignment.Right
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=40.0, Left:=1050.0} 
                                                                    Widget:= AttackSelectionInfo
                                                                overlay_slot:
                                                                    VerticalAlignment:=vertical_alignment.Bottom
                                                                    HorizontalAlignment:=horizontal_alignment.Right
                                                                    Padding:=margin{Top:=0.0, Right:=80.0, Bottom:=50.0, Left:=1300.0} 
                                                                    Widget:= ConfirmAttackInfo
                                                                overlay_slot:
                                                                    VerticalAlignment:=vertical_alignment.Center
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=35.0, Left:=0.0} 
                                                                    Widget:= BattleInformation

                            overlay_slot:
                                VerticalAlignment:=vertical_alignment.Center
                                HorizontalAlignment:=horizontal_alignment.Center
                                Padding:=margin{Top:=390.0, Right:=575.0, Bottom:=0.0, Left:=0.0} 
                                Widget:= PlayerTeamButtons

                            overlay_slot:
                                VerticalAlignment:=vertical_alignment.Bottom
                                HorizontalAlignment:=horizontal_alignment.Center
                                Padding:=margin{Top:=0.0, Right:=590.0, Bottom:=128.0, Left:=0.0} 
                                Widget:= TeamInfoButton
                                                                                                        
        # Hide the Attack Selectio Info on Canvas Created                         
        #AttackSelectionInfo.SetVisibility(widget_visibility.Hidden)
        #ConfirmAttackInfo.SetVisibility(widget_visibility.Hidden)                                              

        UIBattleInfo := battle_ui_info:
            FightButton:= FightButton
            ItemsButton:= ItemsButton
            RunButton:= RunButton
            TeamInfoButton:= TeamInfoButton
            StatsText:= StatsText

            Attack1Button:= Attack1Button
            Attack2Button:= Attack2Button
            Attack3Button:= Attack3Button
            Attack4Button:= Attack4Button

            Attack1_MoxieColorMat:= Attack1_MoxieColorMat
            Attack2_MoxieColorMat:= Attack2_MoxieColorMat
            Attack3_MoxieColorMat:= Attack3_MoxieColorMat
            Attack4_MoxieColorMat:= Attack4_MoxieColorMat

            PlayerMoxie_HealthbarMat:= PlayerMoxie_HealthbarMat
            WildMoxie_HealthbarMat:= WildMoxie_HealthbarMat
            PlayerMoxie_XPMat:= PlayerMoxie_XPMat

            AttackBackButton:= AttackBackButton
            ConfirmAttackButton:= ConfirmAttackButton
            CancelAttackButton:= CancelAttackButton
            ContinueBattleTextButton:= ContinueBattleTextButton
            TeamInfoBackButton:= TeamInfoBackButton

            BattleSelectionInfoOverlay:= BattleSelectionInfo
            AttackSelectionInfoOverlay:= AttackSelectionInfo
            ConfirmAttackInfo:= ConfirmAttackInfo
            BattleInformationOverlay:= BattleInformation
            PlayerTeamWidgetOverlay:= PlayerTeamWidgets
            PlayerTeamButtonsOverlay:= PlayerTeamButtons

            ConfirmAttackInfoName:= ConfirmAttackInfoName
            ConfirmAttackInfoDesc:= ConfirmAttackInfoDesc
            BattleInformationText:= BattleInformationText
            
            MoxieWidgeRight:= MoxieWidgeRight
            MoxieWidgeLeft:= MoxieWidgeLeft

            MoxieTeamWidget_0:= MoxieTeamWidget_0
            MoxieTeamWidget_1:= MoxieTeamWidget_1
            MoxieTeamWidget_2:= MoxieTeamWidget_2
            MoxieTeamWidget_3:= MoxieTeamWidget_3
            MoxieTeamWidget_4:= MoxieTeamWidget_4
            MoxieTeamWidget_5:= MoxieTeamWidget_5

            MoxieTeamButton_0:= MoxieTeamButton_0
            MoxieTeamButton_1:= MoxieTeamButton_1
            MoxieTeamButton_2:= MoxieTeamButton_2
            MoxieTeamButton_3:= MoxieTeamButton_3
            MoxieTeamButton_4:= MoxieTeamButton_4
            MoxieTeamButton_5:= MoxieTeamButton_5

            AnimationLoopCancelledRight:= AnimationLoopCancelledRight
            AnimationLoopCancelledLeft:= AnimationLoopCancelledLeft

            Canvas:= Canvas

        # Store the Battle 1v1 Info to the Player, so each player has it's own information displayed
        if(set PlayerBattleInfoMap[Player] = UIBattleInfo): 
            if(PlayerUI:=GetPlayerUI[Player]):
                # Get the Player's Battle 1v1 Info
                if (PlayerBattleInfo := PlayerBattleInfoMap[Player]):
                    # Add the Player's Canva
                    PlayerUI.AddWidget(PlayerBattleInfo.Canvas, player_ui_slot{ZOrder:=12, InputMode:=ui_input_mode.All}) 

                    # After adding the widget:
                    InitBattleCanvasFromCore(Player)

                    spawn { ListenForBattleUI(Player) }
                    spawn { StartTurnBasedBattle(Player, 200) } # Max Turns here
    # =====================================================================================================================================

    UpdatePlayerMoxieStatsInfo(Player:player): void =
        if (PlayerBattleInfo := PlayerBattleInfoMap[Player]):
            Core := GetOrCreateCore(Player)

            # Get ACTIVE battler from Side A (Player)
            if (B := Core.GetActiveBattler(battle_side.A)?):
                C := B.Creature

                # ---- Values (NO multipliers) ----
                CurrentHPMsg : message = FormatFloatTo1Decimal(B.Creature.Health)
                MaxHPMsg     : message = FormatFloatTo1Decimal(C.MaxHealth)

                AtkMsg : message = FormatFloatTo1Decimal(C.Attack * B.AtkMult)
                DefMsg : message = FormatFloatTo1Decimal(C.Defense * B.DefMult)
                SpdMsg : message = FormatFloatTo1Decimal(C.Speed * B.SpdMult)

                Print("Effect - Base Atk: {C.Attack} | Atk Mult: {B.AtkMult} | Final Atk: {C.Attack * B.AtkMult}")
                Print("Effect - Base Def: {C.Defense} | Def Mult: {B.DefMult} | Final Def: {C.Defense * B.DefMult}")
                Print("Effect - Base Spd: {C.Speed} | Spd Mult: {B.SpdMult} | Final Spd: {C.Speed * B.SpdMult}")

                # ---- Build text (same structure as old code) ----
                var Info : message = CreateMessage("Player's Moxie\n\n")

                set Info = ConcatenateMessages(Info, CreateMessage("Lv: "))
                set Info = ConcatenateMessages(Info, CreateMessage("{C.Level}\n"))

                set Info = ConcatenateMessages(Info, CreateMessage("PS: "))
                set Info = ConcatenateMessages(Info, CurrentHPMsg)
                set Info = ConcatenateMessages(Info, CreateMessage("/"))
                set Info = ConcatenateMessages(Info, MaxHPMsg)
                set Info = ConcatenateMessages(Info, CreateMessage("\n"))

                set Info = ConcatenateMessages(Info, CreateMessage("Atk: "))
                set Info = ConcatenateMessages(Info, AtkMsg)
                set Info = ConcatenateMessages(Info, CreateMessage(" | Def: "))
                set Info = ConcatenateMessages(Info, DefMsg)
                set Info = ConcatenateMessages(Info, CreateMessage(" | Spd: "))
                set Info = ConcatenateMessages(Info, SpdMsg)

                PlayerBattleInfo.StatsText.SetText(Info)
            else:
                # Battle not ready yet
                PlayerBattleInfo.StatsText.SetText(CreateMessage("Player's Moxie\n\n--"))
    # -------------------------------------------------------------------------------------------------------------------------------------
    
    # Helper: apply alive/fainted visuals to a team slot widget
    SetTeamSlotVisualState(TeamWidget:Widgets.Test.WBP_Moxie_Team_Item, IsAlive:logic):void =
        if (IsAlive?):
            Print("Moxie is alive, set to Available!")
            set TeamWidget.SetFaintedState = 0.0
            set TeamWidget.SetAvailableState = 1.0
        else:
            Print("Moxie is NOT alive, set to Fainted!")
            set TeamWidget.SetFaintedState = 1.0
            set TeamWidget.SetAvailableState = 0.0
    # -------------------------------------------------------------------------------------------------------------------------------------

    # Updates ONE team slot display (0..5) based on Core TeamA state
    UpdateSinglePlayerMoxieTeamDisplay(Player:player, MoxieTeamIndex:int): void =
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            Core := GetOrCreateCore(Player)
            T := Core.GetTeam(battle_side.A)

            # Safety: validate index both for UI slots and actual team size
            if (MoxieTeamIndex < 0 or MoxieTeamIndex >= 6):
                return

            TeamWidgets := GetPlayerTeamWidgetArray(UIBattleInfo)

            # Get widget for that slot
            if (SlotWidget := TeamWidgets[MoxieTeamIndex]):
                # If the team doesn't even have that member, treat as "not available"
                if (MoxieTeamIndex < 0 or MoxieTeamIndex >= T.Members.Length):
                    SetTeamSlotVisualState(SlotWidget, false)
                    return

                # Read battler + set alive/fainted state
                if (B := T.Members[MoxieTeamIndex]):
                    IsAlive:= Core.IsBattlerAlive(B)
                    SetTeamSlotVisualState(SlotWidget, IsAlive)
                else:
                    # Super defensive fallback
                    SetTeamSlotVisualState(SlotWidget, false)
    # -------------------------------------------------------------------------------------------------------------------------------------

    UpdateAllPlayerMoxieTeamDisplay(Player:player):void =
        for (Idx := 0..5):
            Print("Updating Moxie: {Idx} Widget!")
            UpdateSinglePlayerMoxieTeamDisplay(Player, Idx)
    # -------------------------------------------------------------------------------------------------------------------------------------

    RefreshSideUIFromCore(Player:player, Side:battle_side):void =
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            Core := GetOrCreateCore(Player)

            # Update model/parts to correct widget (A=Left, B=Right)
            if (C := Core.GetActiveCreature(Side)?):
                if (Side = battle_side.A):
                    SetMoxiePartsToUILeft(C, UIBattleInfo.MoxieWidgeLeft)
                    # Attacks only belong to player side UI
                    SetAttackButtonsFromCreature(UIBattleInfo, C)
                    UpdateAttackButtonLocksFromActiveMoxie(Player)
                else:
                    SetMoxiePartsToUIRight(C, UIBattleInfo.MoxieWidgeRight)
                    spawn { PlaySwappedAnimUIRight(Player, UIBattleInfo.MoxieWidgeRight) }

            # Healthbar progress from core for that side
            #SetHealthbarFromCore(Player, Side)
            spawn { SetMoxieValueBars(Player, Side) }

            # Reset delta visuals so it doesn't show a weird "old hit" bar
            if (Side = battle_side.A):
                set UIBattleInfo.PlayerMoxie_HealthbarMat.DeltaFactor = 0.0
                set UIBattleInfo.PlayerMoxie_HealthbarMat.DeltaProgress = 0.0
            else:
                set UIBattleInfo.WildMoxie_HealthbarMat.DeltaFactor = 0.0
                set UIBattleInfo.WildMoxie_HealthbarMat.DeltaProgress = 0.0

            # Stats only show player side in your UI
            if (Side = battle_side.A):
                UpdatePlayerMoxieStatsInfo(Player)
    # -------------------------------------------------------------------------------------------------------------------------------------

    # Rebuilds only Side A UI from Core (parts, anim loop, attacks, healthbar, stats)
    RefreshLeftUIFromCore(Player:player):void =
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            Core := GetOrCreateCore(Player)

            if (CA := Core.GetActiveCreature(battle_side.A)?):
                # --- IMPORTANT: restart the LEFT idle loop cleanly ---
                # Cancel any existing loop instance
                #UpdateShouldCancelAnimations(Player, true)

                # Update the creature visuals (the thing you said is not changing)
                SetMoxiePartsToUILeft(CA, UIBattleInfo.MoxieWidgeLeft)

                spawn { PlaySwappedAnimUILeft(Player, UIBattleInfo.MoxieWidgeLeft) }

                # Reset anim params and restart loop (same pattern as InitBattleCanvasFromCore)
                ResetMoxieAnimsLeft(UIBattleInfo.MoxieWidgeLeft)
                spawn { LoopIdleAnimationUILeft(Player, UIBattleInfo.MoxieWidgeLeft) }

                # Update attack buttons to match the NEW active creature
                SetAttackButtonsFromCreature(UIBattleInfo, CA)
                UpdateAttackButtonLocksFromActiveMoxie(Player)

                # Update healthbar progress to match the NEW active battler HP
                #SetHealthbarFromCore(Player, battle_side.A)
                spawn { SetMoxieValueBars(Player, battle_side.A) }

                # Force delta visuals to a stable baseline (so it doesn't look "stuck")
                # (Matches your existing "reset delta" idea used elsewhere)
                set UIBattleInfo.PlayerMoxie_HealthbarMat.DeltaFactor = 0.0
                set UIBattleInfo.PlayerMoxie_HealthbarMat.DeltaProgress = UIBattleInfo.PlayerMoxie_HealthbarMat.Progress

                # Update stat text for the new active moxie
                UpdatePlayerMoxieStatsInfo(Player)
    # -------------------------------------------------------------------------------------------------------------------------------------

    SwapPlayerMoxieOld(Player:player, NewIndex:int)<suspends>:logic =
        Core := GetOrCreateCore(Player)

        # Validate: exists, alive, not same as active
        if (not Core.CanSwitchTo(battle_side.A, NewIndex)?):
            Print("SwapPlayerMoxie - Cant Switch To Moxie")
            return false

        if (not Core.TrySwitchActive(battle_side.A, NewIndex)?):
            Print("SwapPlayerMoxie - Cant Switch Active Moxie")
            return false

        # Refresh left UI (player side) + healthbar/stats
        #RefreshSideUIFromCore(Player, battle_side.A)
        RefreshLeftUIFromCore(Player)

        # Swap text
        SwapText := Core.GetSwitchText(battle_side.A)
        UpdateBattleInformationText(Player, SwapText, 1.25)
        Sleep(0.15)

        return true
    # -------------------------------------------------------------------------------------------------------------------------------------

    SwapPlayerMoxie(Player:player, SwitchIdx:int)<suspends>:logic =
        Core := GetOrCreateCore(Player)

        # Validate active + requested switch
        T := Core.GetTeam(battle_side.A)
        if (SwitchIdx < 0 or SwitchIdx >= T.Members.Length):
            Print("SwapPlayerMoxie - No Moxie to swap. Cant swap!!")
            return false
        if (SwitchIdx = T.ActiveIndex):
            Print("SwapPlayerMoxie - Same Moxie. Cant swap!!")
            return false

        # Must be alive
        if (B := T.Members[SwitchIdx]):
            if (B.IsFainted? or B.Creature.Health <= 0.0):
                Print("SwapPlayerMoxie - Selected Moxie is fainted. Cant swap!!")
                return false

        # Do the switch|
        Core.TrySwitchActive(battle_side.A, SwitchIdx)

        # Hard refresh left UI from Core (parts + bar + attacks + stats)
        RefreshLeftUIFromCore(Player)

        ShowOnlyBattleInformation(Player)

        # Show text (your existing working part)
        UpdateBattleInformationText(Player, Core.GetSwitchText(battle_side.A), 1.25)

        # IMPORTANT: a successful manual swap should generally end the turn
        SetPendingInput(Player, battle_input{Action := battle_action.Switch, AttackIndex := -1, ItemIndex := -1, SwitchIndex := SwitchIdx})

        return true

    # -------------------------------------------------------------------------------------------------------------------------------------

    RequireManualPlayerSwapIfFaintedNotUI(Player:player)<suspends>:logic =
        Core := GetOrCreateCore(Player)

        # If player active is NOT fainted, nothing to do
        if (Core.GetCurrentHealthOfActiveMoxieSide(battle_side.A) > 0.0):
            return true

        # Show faint text
        FaintText := Core.GetFaintedText(battle_side.A)
        # Play Left Moxie Fainted Animation
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            PlayFaintedAnimUILeft(Player, UIBattleInfo.MoxieWidgeLeft)

        UpdateBattleInformationText(Player, FaintText, 1.1)
        UpdateAllPlayerMoxieTeamDisplay(Player)
        Sleep(0.25)

        # If team defeated, battle ends
        if (Core.IsTeamDefeated[battle_side.A]):
            return false

        # Prompt for manual selection
        ShowOnlyTeamSwapAndBattleTextInformation(Player)
        FastTypewriteBattleText(Player, "Choose a Moxie to send out!", 9999.0)

        # Clear any previous pending input
        ClearPendingInput(Player)

        loop:
            InputEvent.Await()

            if (Pending := PendingInputByPlayer[Player]):
                if (Pending.Action = battle_action.Switch):
                    Idx := Pending.SwitchIndex

                    # Try swap
                    Swapped:= SwapPlayerMoxie(Player, Idx) 
                    if (Swapped?):
                        
                        # success -> continue battle
                        ClearPendingInput(Player)
                        return true
                    else:
                        # keep waiting; show a quick rejection
                        FastTypewriteBattleText(Player, "Can't swap to that Moxie.", 1.0)
                        ClearPendingInput(Player)
    # -------------------------------------------------------------------------------------------------------------------------------------

    RequireManualPlayerSwapIfFainted(Player:player)<suspends>:logic =
        Core := GetOrCreateCore(Player)
    
        # If player active is NOT fainted, nothing to do
        if (Core.GetCurrentHealthOfActiveMoxieSide(battle_side.A) > 0.0):
            return true
    
        # --- FAINT presentation ---
        FaintText := Core.GetFaintedText(battle_side.A)
    
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            PlayFaintedAnimUILeft(Player, UIBattleInfo.MoxieWidgeLeft)
    
        # Update All Moxie Team Data when a your Moxie is fainted.
        UpdatePlayerMoxieTeamData(Player)

        UpdateBattleInformationText(Player, FaintText, 1.1)
        #UpdateAllPlayerMoxieTeamDisplay(Player)
        Sleep(0.25)
    
        # If team defeated, battle ends
        if (Core.IsTeamDefeated[battle_side.A]):
            return false
    
        # --- Force swap UI prompt ---
        #ShowOnlyTeamSwapAndBattleTextInformation(Player)
        #FastTypewriteBattleText(Player, "Choose a Moxie to send out!", 9999.0)
    
        # We don't want previous pending input to interfere
        ClearPendingInput(Player)
    
        # --- NEW FLOW: open TeamInfo UI and await valid swap ---
        loop:
            Idx := TeamInfoUI.OpenTeamInfoAndAwaitSwap(Player)
    
            if (Idx >= 0 and Idx <= 5):
                Swapped := SwapPlayerMoxie(Player, Idx)
                if (Swapped?):
                    # Forced swap should NOT count as a normal "Switch action" input
                    ClearPendingInput(Player)
    
                    # Restore normal battle UI and continue flow
                    ShowOnlyBattleInformation(Player)
                    return true
                else:
                    # Invalid target (same moxie, fainted target, etc.)
                    FastTypewriteBattleText(Player, "Can't swap to that Moxie.", 1.0)
                    ClearPendingInput(Player)
                    # loop repeats automatically (no continue needed)
    
            else:
                # Player closed/cancelled (-1). For forced faint swap, they must pick one.
                FastTypewriteBattleText(Player, "You must choose a Moxie to continue!", 1.0)
                ClearPendingInput(Player)
                # loop repeats automatically (no continue needed)
    
    


    # -------------------------------------------------------------------------------------------------------------------------------------


    # Returns:
    #   tuple[0] = CanContinue (team still alive)
    #   tuple[1] = DidSwap (a swap occurred → end turn)
    TryAutoSwapAndRefresh(Player:player, Side:battle_side)<suspends>:tuple(logic, logic) =
        Core := GetOrCreateCore(Player)

        Result := Core.AutoSwapRandomIfActiveFainted(Side)
        TeamStillAlive := Result(0)
        DidSwap := Result(1)

        if (not TeamStillAlive?):
            return (false, false)

        if (DidSwap?):
            # 1) FAINT TEXT
            FaintText := Core.GetFaintedText(Side)
            # Play Left Moxie Fainted Animation
            if (UIBattleInfo := PlayerBattleInfoMap[Player]):
                PlayFaintedAnimUIRight(Player, UIBattleInfo.MoxieWidgeRight)
            UpdateBattleInformationText(Player, FaintText, 1.1)

            # Give the message a tiny beat
            Sleep(0.25)

            # 2) REFRESH UI FOR NEW MOXIE
            RefreshSideUIFromCore(Player, Side)

            # 3) SWAP TEXT (WAIT, DO NOT SPAWN)
            SwapText := Core.GetAutoSwapText(Side)
            UpdateBattleInformationText(Player, SwapText, 1.25)

            # Small pacing pause
            Sleep(0.25)

            return (true, true)

        return (true, false)

    # -------------------------------------------------------------------------------------------------------------------------------------

    TryAutoSwapAndRefresh_WithXP(Player:player, Side:battle_side)<suspends>:tuple(logic, logic) =
        BattleCoreData := GetOrCreateCore(Player)

        # Only needed for wild side (B). If called with A by mistake, do nothing.
        if (Side <> battle_side.B):
            return (true, false)

        # Only run if wild active actually fainted
        if (BattleCoreData.GetCurrentHealthOfActiveMoxieSide(battle_side.B) > 0.0):
            return (true, false)

        # --- faint UI + text (same idea as your current flow) ---
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            PlayFaintedAnimUIRight(Player, UIBattleInfo.MoxieWidgeRight)

        UpdateBattleInformationText(Player, BattleCoreData.GetFaintedText(battle_side.B), 1.0)
        Sleep(0.20)

        # --- XP + leveling phase ---
        AwardXPAndHandleLevelUps(Player, BattleCoreData.GetXPRewardPerWildWin())
        Sleep(0.2)

        # --- auto swap random if team still alive ---
        SwapRes := BattleCoreData.AutoSwapRandomIfActiveFainted(battle_side.B)
        TeamAlive := SwapRes(0)
        DidSwap := SwapRes(1)

        if (not TeamAlive?):
            #return (false, false)
            return (true, false)

        if (DidSwap?):
            RefreshSideUIFromCore(Player, battle_side.B)
            UpdateBattleInformationText(Player, BattleCoreData.GetAutoSwapText(battle_side.B), 1.0)
            Sleep(0.20)

        return (true, DidSwap)
    # -------------------------------------------------------------------------------------------------------------------------------------

    AnimateHealthbarDelta(Player:player, DamagedSide:battle_side, Progress:float, DeltaProgress:float, MaxValue:float)<suspends>:void =
        if (PlayerBattleInfo := PlayerBattleInfoMap[Player]):
            Sleep(1.9)

            # Normalize to [0..1]
            NormalizedProgress := NormalizeValue(Progress, MaxValue)
            NormalizedDeltaProgress := NormalizeValue(DeltaProgress, MaxValue)

            # Determine bar color from CURRENT health
            HealthColor := GetHealthBarColorIndex(NormalizedProgress)

            if (DamagedSide = battle_side.A):
                # -------------------------
                # Player (left bar)
                set PlayerBattleInfo.PlayerMoxie_HealthbarMat.BarColor = HealthColor
                set PlayerBattleInfo.PlayerMoxie_HealthbarMat.Progress = NormalizedProgress
                set PlayerBattleInfo.PlayerMoxie_HealthbarMat.DeltaProgress = NormalizedDeltaProgress
                set PlayerBattleInfo.PlayerMoxie_HealthbarMat.DeltaFactor = 1.0

                loop:
                    var CurrentDF:float = PlayerBattleInfo.PlayerMoxie_HealthbarMat.DeltaFactor
                    if (CurrentDF <= 0.0):
                        set PlayerBattleInfo.PlayerMoxie_HealthbarMat.DeltaFactor = 0.0
                        break

                    Sleep(0.1)
                    set PlayerBattleInfo.PlayerMoxie_HealthbarMat.DeltaFactor -= 0.1

            else:
                # -------------------------
                # Wild (right bar)
                set PlayerBattleInfo.WildMoxie_HealthbarMat.BarColor = HealthColor
                set PlayerBattleInfo.WildMoxie_HealthbarMat.Progress = NormalizedProgress
                set PlayerBattleInfo.WildMoxie_HealthbarMat.DeltaProgress = NormalizedDeltaProgress
                set PlayerBattleInfo.WildMoxie_HealthbarMat.DeltaFactor = 1.0

                loop:
                    var CurrentDF:float = PlayerBattleInfo.WildMoxie_HealthbarMat.DeltaFactor
                    if (CurrentDF <= 0.0):
                        set PlayerBattleInfo.WildMoxie_HealthbarMat.DeltaFactor = 0.0
                        break

                    Sleep(0.1)
                    set PlayerBattleInfo.WildMoxie_HealthbarMat.DeltaFactor -= 0.1

    # -------------------------------------------------------------------------------------------------------------------------------------

    # Animates any material Progress value from 0.0 -> TargetNormalized
    AnimateProgressTo(TargetMat:UI.Materials.M_MoxieBaseBar, TargetNormalized:float, Step:float, Delay:float)<suspends>:void =
        var T:float = TargetNormalized

        # Clamp safety
        if (T < 0.0): 
            set T = 0.0
        if (T > 1.0): 
            set T = 1.0

        set TargetMat.Progress = 0.0

        var P:float = 0.0
        loop:
            set P += Step
            if (P >= T):
                set P = T

            set TargetMat.Progress = P

            if (P >= T):
                break

            Sleep(Delay)
    # -------------------------------------------------------------------------------------------------------------------------------------

    AnimateProgressFromTo(TargetMat:UI.Materials.M_MoxieBaseBar, FromNormalized:float, ToNormalized:float, Step:float, Delay:float)<suspends>:void =
        var From:float = FromNormalized
        var To:float = ToNormalized

        # Clamp
        if (From < 0.0): 
            set From = 0.0
        if (From > 1.0): 
            set From = 1.0
        if (To < 0.0): 
            set To = 0.0
        if (To > 1.0): 
            set To = 1.0

        # Ensure starting point
        set TargetMat.Progress = From

        # If going backwards (shouldn't happen for XP), just snap
        if (To <= From):
            set TargetMat.Progress = To
            return

        var P:float = From
        loop:
            set P += Step
            if (P >= To):
                set P = To

            set TargetMat.Progress = P

            if (P >= To):
                break

            Sleep(Delay)
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetHealthBarColorIndex(NormalizedHealth:float):float =
        var H:float = NormalizedHealth

        # Clamp just in case
        if (H < 0.0): 
            set H = 0.0
        if (H > 1.0): 
            set H = 1.0

        # 1 = green, 2 = orange, 3 = red
        if (H > 0.50):
            return 1.0
        else if (H >= 0.20):
            return 2.0
        else:
            return 3.0
    # -------------------------------------------------------------------------------------------------------------------------------------

    SetMoxieValueBars(Player:player, Side:battle_side)<suspends>:void =
        if (PlayerBattleInfo := PlayerBattleInfoMap[Player]):
            Core := GetOrCreateCore(Player)

            if (B := Core.GetActiveBattler(Side)?):
                Step := 0.1
                Delay := 0.05

                # -------------------------
                # HEALTH
                HealthMax := B.Creature.MaxHealth
                HealthNow := B.Creature.Health
                HealthN := NormalizeValue(HealthNow, HealthMax)

                Print("Health - {BattleSideToString(Side)} - Current: {HealthNow}, Max: {HealthMax}")

                HealthColor := GetHealthBarColorIndex(HealthN)

                if (Side = battle_side.A):
                    # XP (player only)
                    XpMax := B.Creature.XPToLevelUp
                    XpNow := B.Creature.CurrentXP
                    XpN := NormalizeValue(XpNow, XpMax)

                    set PlayerBattleInfo.PlayerMoxie_XPMat.BarColor = 0.0
                    set PlayerBattleInfo.PlayerMoxie_XPMat.Progress = XpN
                    #AnimateProgressTo(PlayerBattleInfo.PlayerMoxie_XPMat, XpN, Step, Delay)

                    # -------------------------

                    # Player Health
                    set PlayerBattleInfo.PlayerMoxie_HealthbarMat.BarColor = HealthColor
                    AnimateProgressTo(PlayerBattleInfo.PlayerMoxie_HealthbarMat, HealthN, Step, Delay)
                    

                else:
                    # Wild Health
                    set PlayerBattleInfo.WildMoxie_HealthbarMat.BarColor = HealthColor
                    AnimateProgressTo(PlayerBattleInfo.WildMoxie_HealthbarMat, HealthN, Step, Delay)

    # -------------------------------------------------------------------------------------------------------------------------------------

    HPToProgress(CurHP:float, MaxHP:float):float =
        if (MaxHP <= 0.0):
            return 0.0

        P := CurHP / MaxHP

        if (P < 0.0):
            return 0.0
        if (P > 1.0):
            return 1.0
        return P
    # -------------------------------------------------------------------------------------------------------------------------------------

    AwardXPAndHandleLevelUps(Player:player, XpEarned:float)<suspends>:void =
        if (XpEarned <= 0.0):
            return

        BattleCoreData := GetOrCreateCore(Player)

        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            if (ActiveMoxie := BattleCoreData.GetActiveCreature(battle_side.A)?):

                set UIBattleInfo.PlayerMoxie_XPMat.BarColor = 0.0

                Step:float = 0.02
                Delay:float = 0.01

                # --- OLD values (before XP is applied) ---
                OldXP:float = ActiveMoxie.CurrentXP
                OldMax:float = ActiveMoxie.XPToLevelUp
                OldLevel:int = ActiveMoxie.Level

                # 1) XP message
                FastTypewriteBattleText(
                    Player,
                    "The Player Moxie won {FormatFloatTo1DecimalString(XpEarned)} XP!",
                    1.2
                )

                # 2) Apply XP
                ActiveMoxie.AddXP(XpEarned)

                # IMPORTANT: Update All the Moxie Team Data when we won XP. Eventually Benched Moxies will win XP so we do to all.
                UpdatePlayerMoxieTeamData(Player)

                # 3) Animate gain within OLD max first
                NewXP:float = ActiveMoxie.CurrentXP
                OldFromN:float = NormalizeValue(OldXP, OldMax)
                OldToN:float = NormalizeValue(NewXP, OldMax)

                AnimateProgressFromTo(
                    UIBattleInfo.PlayerMoxie_XPMat,
                    OldFromN,
                    OldToN,
                    Step,
                    Delay
                )

                Sleep(0.25)

                # 4) Level up loop (guarded)
                var Iter:int = 0
                var MaxIter:int = 10

                loop:
                    set Iter += 1
                    if (Iter > MaxIter):
                        break

                    CurXP:float = ActiveMoxie.CurrentXP
                    CurMax:float = ActiveMoxie.XPToLevelUp

                    if (CurMax <= 0.0):
                        break

                    if (CurXP < CurMax):
                        break

                    # 4.1) Fill bar to 100%
                    AnimateProgressFromTo(
                        UIBattleInfo.PlayerMoxie_XPMat,
                        UIBattleInfo.PlayerMoxie_XPMat.Progress,
                        1.0,
                        Step,
                        Delay
                    )

                    # Snapshot BEFORE LevelUp
                    PrevXP:float = ActiveMoxie.CurrentXP
                    PrevMax:float = ActiveMoxie.XPToLevelUp
                    PrevLevel:int = ActiveMoxie.Level

                    # 4.2) Level up announcement
                    FastTypewriteBattleText(Player, "Your Moxie Level Up!\nLevel {PrevLevel} to {PrevLevel+1}!", 1.0)

                    # 4.3) Apply level up
                    ActiveMoxie.LevelUp()

                    # Read AFTER LevelUp
                    AfterXP:float = ActiveMoxie.CurrentXP
                    AfterMax:float = ActiveMoxie.XPToLevelUp
                    AfterLevel:int = ActiveMoxie.Level

                    UpdatePlayerMoxieStatsInfo(Player)
                    UpdateAttackButtonLocksFromActiveMoxie(Player)

                    # --- SAFETY GUARDS ---
                    if (AfterLevel = PrevLevel):
                        break

                    if (AfterMax = PrevMax and AfterXP = PrevXP and AfterLevel = PrevLevel):
                        break

                    if (AfterMax <= 0.0):
                        break

                    if (AfterXP >= AfterMax and AfterMax <= PrevMax):
                        break

                    Sleep(0.5)

                    # 4.4) Re-animate bar using NEW XP scale
                    set UIBattleInfo.PlayerMoxie_XPMat.Progress = 0.0

                    AnimateProgressTo(
                        UIBattleInfo.PlayerMoxie_XPMat,
                        NormalizeValue(AfterXP, AfterMax),
                        Step,
                        Delay
                    )

                    Sleep(0.5)


    # -------------------------------------------------------------------------------------------------------------------------------------

    # CATCH SYSTEM
    CancelCatchSubscriptions(Player:player):void =
        if (Attempt := CatchAttemptByPlayer[Player]?):
            Attempt.SubSuccess.Cancel()
            Attempt.SubFail.Cancel()
            Attempt.SubCancel.Cancel()
    # -------------------------------------------------------------------------------------------------------------------------------------
  
    SetCatchResultAndFinish(Player:player, NewResult:catch_result):void =
        if (Attempt := CatchAttemptByPlayer[Player]?):
            # first event wins
            if (Attempt.Result <> catch_result.None):
                return
    
            Updated:catch_attempt =
                catch_attempt{
                    Done := Attempt.Done,
                    Result := NewResult,
                    SubSuccess := Attempt.SubSuccess,
                    SubFail := Attempt.SubFail,
                    SubCancel := Attempt.SubCancel
                }
    
            # store updated attempt
            if (set CatchAttemptByPlayer[Player] = option{Updated}) {}
    
            # cleanup subscriptions immediately (prevents chaining)
            CancelCatchSubscriptions(Player)
    
            # wake waiter
            Updated.Done.Signal()
    # -------------------------------------------------------------------------------------------------------------------------------------
   
    OnCatchSucceeded(Agent:agent):void =
        if (P := player[Agent]):
            SetCatchResultAndFinish(P, catch_result.Success)
    # -------------------------------------------------------------------------------------------------------------------------------------
 
    OnCatchFailed(Agent:agent):void =
        if (P := player[Agent]):
            SetCatchResultAndFinish(P, catch_result.Failed)
    # -------------------------------------------------------------------------------------------------------------------------------------

    OnCatchCanceled(Agent:agent):void =
        if (P := player[Agent]):
            SetCatchResultAndFinish(P, catch_result.Canceled)
    # -------------------------------------------------------------------------------------------------------------------------------------

    TryCatchViaSkilledInteraction(Player:player)<suspends>:void =
        # if there is already an attempt, ignore
        if (CatchAttemptByPlayer[Player]?):
            return
    
        ShowOnlyBattleInformation(Player)
        FastTypewriteBattleText(Player, "You're trying to catch the Wild Moxie!", 1.0)
        if (MoxieCatchDevice.BeginInteraction[Player]){}

        Done:event() = event(){}
    
        S := MoxieCatchDevice.InteractionSucceededEvent.Subscribe(OnCatchSucceeded)
        F := MoxieCatchDevice.InteractionFailedEvent.Subscribe(OnCatchFailed)
        C := MoxieCatchDevice.InteractionCanceledEvent.Subscribe(OnCatchCanceled)
    
        NewAttempt:catch_attempt =
            catch_attempt{
                Done := Done,
                Result := catch_result.None,
                SubSuccess := S,
                SubFail := F,
                SubCancel := C
            }
    
        if (set CatchAttemptByPlayer[Player] = option {NewAttempt}) {}
    
        Done.Await()
    
        var Final:catch_result = catch_result.Canceled
        if (Attempt := CatchAttemptByPlayer[Player]?):
            set Final = Attempt.Result
    
        # clear attempt
        if (set CatchAttemptByPlayer[Player] = false) {}
    
        if (Final = catch_result.Success):
            FastTypewriteBattleText(Player, "Moxie should be catched!", 1.0)
            Sleep(0.75)
    
            HandleSuccessfulCatchAndEndBattle(Player)
            return
    
        else if (Final = catch_result.Failed):
            FastTypewriteBattleText(Player, "The Wild Moxie scaped...", 1.0)
            Sleep(0.75)
    
            SetPendingInput(Player, battle_input{
                Action := battle_action.Items,
                AttackIndex := -1,
                ItemIndex := 1,
                SwitchIndex := -1
            })
            return
    
        else:
            FastTypewriteBattleText(Player, "You decide not to catch...", 1.0)
            Sleep(0.60)
    
            ShowBattleSelectionInfoOverlay(Player)
            FastTypewriteBattleText(Player, "What will your Moxie do?", 1.0)
            return
    
    # -------------------------------------------------------------------------------------------------------------------------------------

    HandleSuccessfulCatchAndEndBattle(Player:player)<suspends>:void =
        Core := GetOrCreateCore(Player)
    
        if (UIBattleInfo := PlayerBattleInfoMap[Player]):
            # Force wild to be defeated so Core.IsOver[] becomes true.
            # Using big damage keeps your faint/healthbar logic consistent.
            #Core.ApplyDamageToActive(Player, battle_side.B, 9999999.0)
            PlayFaintedAnimUIRight(Player, UIBattleInfo.MoxieWidgeRight)
        
            Sleep(0.35)
        
            # Grant XP like a normal win
            XpEarned := Core.GetXPRewardPerWildWin()
            AwardXPAndHandleLevelUps(Player, XpEarned)
            # Update All the Moxie Team Data when Battle Is Over.
            UpdatePlayerMoxieTeamData(Player)

            FastTypewriteBattleText(Player, "The battle is over!", 1.0)
            Sleep(2.0)

            # Wake any Await() in the battle loop (so it can notice IsOver and end)
            SetPendingInput(Player, battle_input{
                Action := battle_action.None,
                AttackIndex := -1,
                ItemIndex := -1,
                SwitchIndex := -1
            })

            RemoveEndBattleWidget(Player, UIBattleInfo)
        
            
        
