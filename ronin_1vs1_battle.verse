
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }
using { /Verse.org/Random }
 using { /Verse.org/Concurrency }



ronin_1vs1_battle := class(creative_device):

    @editable
    MoxieManager: ronin_creature_manager = ronin_creature_manager{}

    var PlayerMoxie_A:ronin_creature = ronin_creature{}
    var WildMoxie_B:ronin_creature = ronin_creature{}

    # Current HP for battle (separate from creature base stats)
    var CurrentHPA:float = 0.0
    var CurrentHPB:float = 0.0

    var PendingInputByPlayer : [player]battle_input = map{}
    var SelectedAttackIndexByPlayer : [player]int = map{}
    # Typewriter state (prevents overlapping text animations)
    var BattleTextVersionByPlayer : [player]int = map{}
    # Signals when player presses Continue (per player)
    var ContinueEventByPlayer : [player]event() = map{}


    # Event to wake the turn engine when something relevant happens
    InputEvent : event() = event(){}

    # CRITICAL DAMAGE 
    CritChance : float = 0.12 # 0.12 12% baseline
    CritMultiplier : float = 1.75 # 1.75 extra damage

    # Rolls a crit using a threshold (chance). Returns true if crit.
    RollCriticalHit(Chance:float):logic =
        R := GetRandomFloat(0.0, 1.0)
        return logic{ R <= Chance }

    InitBattleWitnRandomMoxie(Player:player, InA:ronin_creature, InB:ronin_creature):void =
        set PlayerMoxie_A = InA
        set WildMoxie_B = InB
        set CurrentHPA = InA.Health
        set CurrentHPB = InB.Health

        CreateBattle1vs1Canvas(Player)

    IsOver()<transacts><decides>:void =
        CurrentHPA <= 0.0 or CurrentHPB <= 0.0

    # DEPRECATED - Returns true if attack was executed
    ExecuteAttack(AttackerIsA : logic, AttackIndex : int):logic =
        if (IsOver[]):
            Print("Battle is already over.")
            return false
 
        var Attacker : ?ronin_creature = false
        var Defender : ?ronin_creature = false
 
        if (AttackerIsA?):
            set Attacker = option{PlayerMoxie_A}
            set Defender = option{WildMoxie_B}
        else:
            set Attacker = option{WildMoxie_B}
            set Defender = option{PlayerMoxie_A}
 
        if (ValidAttacker := Attacker?, ValidDefender := Defender?):
            if (Attack := ValidAttacker.Attacks[AttackIndex]):
                Damage := ComputeDamage(ValidAttacker, ValidDefender, Attack.Damage, Attack.Type)
                DamageValue := Damage(0)

 
                if (AttackerIsA?):
                    set CurrentHPB = ClampNonNegative(CurrentHPB - DamageValue)
                else:
                    set CurrentHPA = ClampNonNegative(CurrentHPA - DamageValue)
 
                Print("Attack dealt {DamageValue}. HP(A:{CurrentHPA} B:{CurrentHPB})")
 
                ApplyEffects(ValidAttacker, ValidDefender, Attack.Effects, AttackerIsA)
                #ApplyEffects(ValidAttacker, ValidDefender, Attack.Effects)

                Print("AFTER EFFECTS:")
                Print(" A Stats => H:{PlayerMoxie_A.Health} A:{PlayerMoxie_A.Attack} D:{PlayerMoxie_A.Defense} S:{PlayerMoxie_A.Speed}")
                Print(" B Stats => H:{WildMoxie_B.Health} A:{WildMoxie_B.Attack} D:{WildMoxie_B.Defense} S:{WildMoxie_B.Speed}")

                return true
 
        return false
 
    ComputeDamage(Attacker:ronin_creature, Defender:ronin_creature, Power:float, AttackType:creature_type):tuple(float, ronin_attack_effectiveness) =

        # Setup / non-damaging move
        if (Power <= 0.0):
            Print("===== DAMAGE BREAKDOWN =====")
            Print("Power: 0 (SETUP MOVE) => No damage")
            Print("============================")
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

        # ---------------- DEBUG OUTPUT ----------------
        Print("===== DAMAGE BREAKDOWN =====")
        Print("Level: {Attacker.Level}")
        Print("Power: {Power}")
        Print("LevelFactor: {LevelFactor}")
        Print("StatRatio (Atk/Def): {StatRatio}")
        Print("Base Damage: {Base}")
        Print("Type Multiplier: {TypeMult}")
        Print("Same Parts Count: {SameCount}")
        Print("Same Parts Multiplier: {SamePartsMult}")
        Print("Random Factor: {Rand}")
        Print("FINAL DAMAGE: {Final}")
        Print("============================")

        var AttackEffectiveness: ronin_attack_effectiveness = ronin_attack_effectiveness.Neutral
        if (TypeMult > 1.0):
            set AttackEffectiveness = ronin_attack_effectiveness.SuperEffective
        else if (TypeMult < 1.0):
            set AttackEffectiveness = ronin_attack_effectiveness.NotEffective
    
        # Keep minimum damage after multiplier too
        if (Final < 1.0):
            return (1.0, AttackEffectiveness)
    
        return (Final, AttackEffectiveness)

    ApplyEffects(Attacker : ronin_creature, Defender : ronin_creature, Effects : []ronin_effect, AttackerIsA:logic):void =

        for (E : Effects):
            if (AttackerIsA?):
                if (E.Target = ronin_effect_target.Myself):
                    PlayerMoxie_A.ApplyPercentToStat(E.Stat, E.Percent)
                if (E.Target = ronin_effect_target.Enemy):
                    WildMoxie_B.ApplyPercentToStat(E.Stat, E.Percent)
            else:
                if (E.Target = ronin_effect_target.Myself):
                    WildMoxie_B.ApplyPercentToStat(E.Stat, E.Percent)
                if (E.Target = ronin_effect_target.Enemy):
                    PlayerMoxie_A.ApplyPercentToStat(E.Stat, E.Percent)

            #TargetCreature := if (E.Target = 0) then Attacker else Defender
            #TargetCreature.ApplyPercentToStat(E.Stat, E.Percent)

    # Apply effects correctly relative to attacker/defender
    ApplyEffects(Attacker : ronin_creature, Defender : ronin_creature, Effects : []ronin_effect):void =
        for (E : Effects):
            TargetCreature : ronin_creature =
                if (E.Target = ronin_effect_target.Myself) then Attacker else Defender

            TargetCreature.ApplyPercentToStat(E.Stat, E.Percent)

    # Helper: maps "who is the target?" to the right on-screen name
    GetTargetNameForEffect(AttackerIsA:logic, Target:ronin_effect_target):string =
        # If attacker is A, then:
        # - Myself => Your Moxie
        # - Enemy  => The Wild Moxie
        #
        # If attacker is B (wild), then:
        # - Myself => The Wild Moxie
        # - Enemy  => Your Moxie
        if (AttackerIsA?):
            return if (Target = ronin_effect_target.Myself) then "Your Moxie" else "The Wild Moxie"
        else:
            return if (Target = ronin_effect_target.Myself) then "The Wild Moxie" else "Your Moxie"


    # Constructs the Effect text to display
    EffectToText(E:ronin_effect, AttackerIsA:logic):string =
        TargetName : string = GetTargetNameForEffect(AttackerIsA, E.Target)
        StatName : string = StatToString(E.Stat)
        Dir : string = if (E.Percent < 0.0) then "dropped" else "raised"

        return "{TargetName} {StatName} {Dir}!"

    # Builds the Effect text to display for all the effects
    BuildEffectsSummary(Effects:[]ronin_effect, AttackerIsA:logic):string =
        if (Effects.Length <= 0):
            return "No additional effects."

        # If multiple effects exist, we print them in one line separated by " "
        var Out:string = ""
        for (Idx -> E : Effects):
            Line := EffectToText(E, AttackerIsA)
            if (Idx = 0):
                set Out = Line
            else:
                set Out = "{Out}\n{Line}"
        return Out

    # Applies damage (and returns amount). Effects are applied separately so we can control narration timing.
    # 0 (DidHit), 1 (DamageDealt), 2 (WasCritic), 3 (Attack), 4 (AttackEffectiveness)
    ApplyDamageOnly(Player:player, AttackerIsA:logic, AttackIndex:int):tuple(logic, float, logic, ronin_attack, ronin_attack_effectiveness) =
        EmptyAttack:ronin_attack = ronin_attack{}
        EmptyEffectiveness:= ronin_attack_effectiveness.Neutral
        if (IsOver[]):
            return (false, 0.0, false, EmptyAttack, EmptyEffectiveness)
    
        var Attacker : ?ronin_creature = false
        var Defender : ?ronin_creature = false
    
        if (AttackerIsA?):
            set Attacker = option{PlayerMoxie_A}
            set Defender = option{WildMoxie_B}
        else:
            set Attacker = option{WildMoxie_B}
            set Defender = option{PlayerMoxie_A}
    
        if (ValidAttacker := Attacker?, ValidDefender := Defender?):
            # Validate index (avoid crash)
            if (AttackIndex >= 0 and AttackIndex < ValidAttacker.Attacks.Length):
                if (Attack := ValidAttacker.Attacks[AttackIndex]):
                    Damage := ComputeDamage(ValidAttacker, ValidDefender, Attack.Damage, Attack.Type)
                    BaseDamageValue := Damage(0)
                    AttackEffectiveness := Damage(1)

                    # CRIT only if we actually deal damage
                    var WasCrit:logic = false
                    var FinalDamage:float = BaseDamageValue

                    if (BaseDamageValue > 0.0):
                        CritRollChance := CritChance
                        set WasCrit = RollCriticalHit(CritRollChance)
                        set FinalDamage = if (WasCrit?) then (BaseDamageValue * CritMultiplier) else BaseDamageValue

                    # Apply HP & healthbar only if damage > 0
                    if (FinalDamage > 0.0):
                        if (AttackerIsA?):
                            set CurrentHPB = ClampNonNegative(CurrentHPB - FinalDamage )
                            spawn {UpdateMoxieHealthbar(Player, true, NormalizeValue(CurrentHPB, WildMoxie_B.Health), NormalizeValue(FinalDamage , WildMoxie_B.Health))}
                        else:
                            set CurrentHPA = ClampNonNegative(CurrentHPA - FinalDamage )
                            spawn {UpdateMoxieHealthbar(Player, false, NormalizeValue(CurrentHPA, PlayerMoxie_A.Health), NormalizeValue(FinalDamage , PlayerMoxie_A.Health))}
            
                    return (true, FinalDamage, WasCrit, Attack, AttackEffectiveness)
    
        return (false, 0.0, false, EmptyAttack, EmptyEffectiveness)

    # Do the attack information (text), apply affects and also display their information
    DoAttackSequence(Player:player, AttackerIsA:logic, AttackIndex:int)<suspends>:logic =
        # 1) Damage
        Result := ApplyDamageOnly(Player, AttackerIsA, AttackIndex)
        DidHit := Result(0)
        DamageDealt := Result(1)
        WasCrit := Result(2)
        Attack := Result(3)
        AttackEffectiveness:= Result(4) 
        AttackName := Attack.Name
        AttackEffects := Attack.Effects

        if (not DidHit?):
            Print("Attack failed (invalid index or missing attack).")
            return false

        # Only play damage animation if actual damage happened
        if (DamageDealt > 0.0):
            if (PlayerBattle1v1Info := PlayerBattle1v1InfoMap[Player]):
                if(AttackerIsA?) then spawn{PlayDamagedAnimUIRight(Player, PlayerBattle1v1Info.MoxieWidgeRight)}
                else spawn{PlayDamagedAnimUILeft(Player, PlayerBattle1v1Info.MoxieWidgeLeft)}

        # Identify attacker/defender refs for effect text + application
        var Attacker : ?ronin_creature = false
        var Defender : ?ronin_creature = false
        if (AttackerIsA?):
            set Attacker = option{PlayerMoxie_A}
            set Defender = option{WildMoxie_B}
        else:
            set Attacker = option{WildMoxie_B}
            set Defender = option{PlayerMoxie_A}

        if (ValidAttacker := Attacker?, ValidDefender := Defender?):

            TargetName : string = if (AttackerIsA?) then "Your Moxie" else "The Wild Moxie"
            CritText : string = if (WasCrit?) then "\nA critical hit!" else ""
            EffectivenessText : string =
                if (AttackEffectiveness = ronin_attack_effectiveness.SuperEffective):
                    "\nIt's super effective!"
                else if (AttackEffectiveness = ronin_attack_effectiveness.NotEffective):
                    "\nIt's not very effective..."
                else:
                    ""

            # Damage line only when damage > 0
            DamageLine : string =
                if (DamageDealt > 0.0):
                    "\nDeals {FormatFloatTo1DecimalString(DamageDealt)} damage."
                else:
                    ""  # setup move => no deals text

            UpdateBattleInformationText(
                Player,
                "{TargetName} used {AttackName}!{DamageLine}{EffectivenessText}{CritText}",
                2.0
            )
            
            if (IsOver[]):
                return true

            #ApplyEffects(ValidAttacker, ValidDefender, Effects)
            ApplyEffects(ValidAttacker, ValidDefender, AttackEffects, AttackerIsA)

             # Only show effects text if there ARE effects (optional polish)
            if (AttackEffects.Length > 0):
                EffectsText := BuildEffectsSummary(AttackEffects, AttackerIsA)
                UpdateBattleInformationText(Player, EffectsText, 2.0)

            return true


        return false


# --------------------------------------------------------------------------------------------------------------------------------------------------------


    SetPendingInput(Player:player, NewInput:battle_input):void =
        if (set PendingInputByPlayer[Player] = NewInput) {}
        InputEvent.Signal()
        
    ClearPendingInput(Player:player):void =
        if (set PendingInputByPlayer[Player] = battle_input{Action := battle_action.None, AttackIndex := -1, ItemIndex := -1, SwitchIndex := -1}) {}
         ClearSelectedAttack(Player)

    SetSelectedAttack(Player:player, Idx:int):void =
        if (set SelectedAttackIndexByPlayer[Player] = Idx) {}

    ClearSelectedAttack(Player:player):void =
        if (set SelectedAttackIndexByPlayer[Player] = -1) {}



    var PlayerBattle1v1InfoMap : [player]battle_ui_info = map{}
    MoxieWidgeRight: Widgets.Test.WBP_Moxie_Right = Widgets.Test.WBP_Moxie_Right{}
    MoxieWidgeLeft: Widgets.Test.WBP_Moxie_Left = Widgets.Test.WBP_Moxie_Left{}

    CreateBattle1vs1Canvas(Player:player):void =

        #var AnimationLoopCancelledRight : [player]logic = map{} 
        #var AnimationLoopCancelledLeft : [player]logic = map{}

        var AnimationLoopCancelledRight: logic = false
        var AnimationLoopCancelledLeft: logic = false

        ImageBackground :=texture_block{DefaultImage:=Assets.BattleBG, DefaultDesiredSize:=vector2{X:=1920.0, Y:=1080.0}}

        FightButton:=button_regular{DefaultText:=CreateMessage("Fight")}
        ItemsButton:=button_regular{DefaultText:=CreateMessage("Items")}
        RunButton:=button_regular{DefaultText:=CreateMessage(" Run ")}

        TeamInfoButton:=button_regular{DefaultText:=CreateMessage("Info")}
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

        PlayerMoxie_HealthbarMaterialBlock:=material_block{DefaultImage:=PlayerMoxie_HealthbarMat}
        WildMoxie_HealthbarMaterialBlock:=material_block{DefaultImage:=WildMoxie_HealthbarMat}

        ConfirmAttackButton:=button_regular{DefaultText:=CreateMessage("Attack")}
        CancelAttackButton:=button_regular{DefaultText:=CreateMessage("Back")}
        AttackBackButton:=button_quiet{DefaultText:=CreateMessage("   Back   ")}
        ContinueBattleTextButton:=button_quiet{DefaultText:=CreateMessage("Continue")}

        ConfirmAttackInfoName:= text_block{DefaultText := CreateMessage("Attack Name"), DefaultTextColor := NamedColors.White}
        ConfirmAttackInfoDesc:= text_block{DefaultText := CreateMessage("Attack Description"), DefaultTextColor := NamedColors.White}
        BattleInformationText:= text_block{DefaultText := CreateMessage("Battle Info"), DefaultTextColor := NamedColors.White, DefaultJustification:= text_justification.Center}

        BattleSelectionInfo:=overlay:
            Slots:=array:
                overlay_slot:
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Bottom
                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                    Widget:=stack_box:
                        Orientation:=orientation.Horizontal
                        Slots:=array:
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Left
                                VerticalAlignment:=vertical_alignment.Fill
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=30.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:= StatsText

                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Bottom
                                #Distribution:=option{0.6}
                                Padding:=margin{Top:=0.0, Right:=500.0, Bottom:=20.0, Left:=400.0}
                                Widget:=TeamInfoButton

                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Right
                                VerticalAlignment:=vertical_alignment.Bottom
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

        ButtonTest:= overlay:
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
                    Widget:= text_block{DefaultText := CreateMessage("Click Me!")}#Attack1Button                                     

        ButtonText := text_block{DefaultText := CreateMessage("Click Me!")}
        ButtonSlot := button_slot{Widget := ButtonTest}
        MyButton := button{Slot := ButtonSlot}                         
                        
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
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=10.0}
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
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Top
                                Padding:=margin{Top:=30.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:= text_block{DefaultText := CreateMessage(""), DefaultTextColor := NamedColors.White}#ContinueBattleTextButton


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
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0} 
                                                        Widget:= overlay:
                                                            Slots:=array:
                                                                overlay_slot:
                                                                    VerticalAlignment:=vertical_alignment.Bottom
                                                                    HorizontalAlignment:=horizontal_alignment.Fill
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=20.0, Left:=0.0} 
                                                                    Widget:= BattleSelectionInfo
                                                                overlay_slot:
                                                                    VerticalAlignment:=vertical_alignment.Bottom
                                                                    HorizontalAlignment:=horizontal_alignment.Fill
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=30.0, Left:=1200.0} 
                                                                    Widget:= AttackSelectionInfo
                                                                overlay_slot:
                                                                    VerticalAlignment:=vertical_alignment.Bottom
                                                                    HorizontalAlignment:=horizontal_alignment.Right
                                                                    Padding:=margin{Top:=0.0, Right:=80.0, Bottom:=50.0, Left:=0.0} 
                                                                    Widget:= ConfirmAttackInfo
                                                                overlay_slot:
                                                                    VerticalAlignment:=vertical_alignment.Bottom
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=100.0, Left:=0.0} 
                                                                    Widget:= BattleInformation
                                                
                                    
                       

                    
        
        # Hide the Attack Selectio Info on Canvas Created                         
        #AttackSelectionInfo.SetVisibility(widget_visibility.Hidden)
        #ConfirmAttackInfo.SetVisibility(widget_visibility.Hidden)                                              

        UIBattle1v1Info := battle_ui_info:
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

            AttackBackButton:= AttackBackButton
            ConfirmAttackButton:= ConfirmAttackButton
            CancelAttackButton:= CancelAttackButton
            ContinueBattleTextButton:= ContinueBattleTextButton
            TeamInfoBackButton:= button_quiet{}

            BattleSelectionInfoOverlay:= BattleSelectionInfo
            AttackSelectionInfoOverlay:= AttackSelectionInfo
            ConfirmAttackInfo:= ConfirmAttackInfo
            BattleInformationOverlay:= BattleInformation
            PlayerTeamWidgetOverlay:= overlay{}
            PlayerTeamButtonsOverlay:= overlay{}

            ConfirmAttackInfoName:= ConfirmAttackInfoName
            ConfirmAttackInfoDesc:= ConfirmAttackInfoDesc
            BattleInformationText:= BattleInformationText
            

            MoxieWidgeRight:= MoxieWidgeRight
            MoxieWidgeLeft:= MoxieWidgeLeft

            MoxieTeamWidget_0:= Widgets.Test.WBP_Moxie_Team_Item{}
            MoxieTeamWidget_1:= Widgets.Test.WBP_Moxie_Team_Item{}
            MoxieTeamWidget_2:= Widgets.Test.WBP_Moxie_Team_Item{}
            MoxieTeamWidget_3:= Widgets.Test.WBP_Moxie_Team_Item{}
            MoxieTeamWidget_4:= Widgets.Test.WBP_Moxie_Team_Item{}
            MoxieTeamWidget_5:= Widgets.Test.WBP_Moxie_Team_Item{}

            MoxieTeamButton_0:= button_quiet{}
            MoxieTeamButton_1:= button_quiet{}
            MoxieTeamButton_2:= button_quiet{}
            MoxieTeamButton_3:= button_quiet{}
            MoxieTeamButton_4:= button_quiet{}
            MoxieTeamButton_5:= button_quiet{}

            AnimationLoopCancelledRight:= AnimationLoopCancelledRight
            AnimationLoopCancelledLeft:= AnimationLoopCancelledLeft

            Canvas:= Canvas

        # Store the Battle 1v1 Info to the Player, so each player has it's own information displayed
        if(set PlayerBattle1v1InfoMap[Player] = UIBattle1v1Info): 
            if(PlayerUI:=GetPlayerUI[Player]):
                # Get the Player's Battle 1v1 Info
                if (PlayerBattle1v1Info := PlayerBattle1v1InfoMap[Player]):
                    # Add the Player's Canva
                    PlayerUI.AddWidget(PlayerBattle1v1Info.Canvas, player_ui_slot{ZOrder:=12, InputMode:=ui_input_mode.All}) 

                    
                    # Add the Player Moxie to the Left Moxie Widget
                    SetMoxiePartsToUILeft(PlayerMoxie_A, PlayerBattle1v1Info.MoxieWidgeLeft) 
                    spawn{LoopIdleAnimationUILeft(Player, PlayerBattle1v1Info.MoxieWidgeLeft)} 

                    # Set the Player's Moxie Attacks Names and Descriptions
                    if(Att1:= PlayerMoxie_A.Attacks[0], Att2:= PlayerMoxie_A.Attacks[1], Att3:= PlayerMoxie_A.Attacks[2], Att4:= PlayerMoxie_A.Attacks[3]):
                        PlayerBattle1v1Info.Attack1Button.SetText(CreateMessage(Att1.Name))
                        PlayerBattle1v1Info.Attack2Button.SetText(CreateMessage(Att2.Name))
                        PlayerBattle1v1Info.Attack3Button.SetText(CreateMessage(Att3.Name))
                        PlayerBattle1v1Info.Attack4Button.SetText(CreateMessage(Att4.Name))

                        set PlayerBattle1v1Info.Attack1_MoxieColorMat.ColorSelectorSwitch = CreatureTypeToColorIndex(Att1.Type)
                        set PlayerBattle1v1Info.Attack2_MoxieColorMat.ColorSelectorSwitch = CreatureTypeToColorIndex(Att2.Type)
                        set PlayerBattle1v1Info.Attack3_MoxieColorMat.ColorSelectorSwitch = CreatureTypeToColorIndex(Att3.Type)
                        set PlayerBattle1v1Info.Attack4_MoxieColorMat.ColorSelectorSwitch = CreatureTypeToColorIndex(Att4.Type)

                    # Updated the player's Moxie stats info text
                    UpdatePlayerMoxieStatsInfo(Player)

                    # Add the Wild Moxie to the Right Moxie Widget
                    SetMoxiePartsToUIRight(WildMoxie_B, PlayerBattle1v1Info.MoxieWidgeRight)
                    spawn{LoopIdleAnimationUIRight(Player, PlayerBattle1v1Info.MoxieWidgeRight)} 

                    #if (PlayerBattle1v1Info.AnimationLoopCancelledLeft[Player] = false) {}   

                    # Await for Buttons Clicked
                    #spawn{AwaitPlayerInput(Player, UIBattle1v1Info)}

                    spawn{ListenForBattleUI(Player)}
                    spawn{StartTurnBasedBattle(Player)}

    UpdatePlayerMoxieStatsInfo(Player:player): void =
        if (PlayerBattle1v1Info := PlayerBattle1v1InfoMap[Player]):

            # Format stats to 1 decimal (message outputs)
            CurrentHPMsg : message = FormatFloatTo1Decimal(CurrentHPA)
            MaxHPMsg     : message = FormatFloatTo1Decimal(PlayerMoxie_A.Health)
            AtkMsg       : message = FormatFloatTo1Decimal(PlayerMoxie_A.Attack)
            DefMsg       : message = FormatFloatTo1Decimal(PlayerMoxie_A.Defense)
            SpdMsg       : message = FormatFloatTo1Decimal(PlayerMoxie_A.Speed)

            # Build final text by concatenating message pieces (no message-in-CreateMessage)
            var PlayerInfoText : message = CreateMessage("Player's Moxie\n\n")

            set PlayerInfoText = ConcatenateMessages(PlayerInfoText, CreateMessage("Lv: "))
            set PlayerInfoText = ConcatenateMessages(PlayerInfoText, CreateMessage("{PlayerMoxie_A.Level}\n"))

            set PlayerInfoText = ConcatenateMessages(PlayerInfoText, CreateMessage("PS: "))
            set PlayerInfoText = ConcatenateMessages(PlayerInfoText, CurrentHPMsg)
            set PlayerInfoText = ConcatenateMessages(PlayerInfoText, CreateMessage("/"))
            set PlayerInfoText = ConcatenateMessages(PlayerInfoText, MaxHPMsg)
            set PlayerInfoText = ConcatenateMessages(PlayerInfoText, CreateMessage("\n"))

            set PlayerInfoText = ConcatenateMessages(PlayerInfoText, CreateMessage("Atk: "))
            set PlayerInfoText = ConcatenateMessages(PlayerInfoText, AtkMsg)
            set PlayerInfoText = ConcatenateMessages(PlayerInfoText, CreateMessage(" | Def: "))
            set PlayerInfoText = ConcatenateMessages(PlayerInfoText, DefMsg)
            set PlayerInfoText = ConcatenateMessages(PlayerInfoText, CreateMessage(" | Spd: "))
            set PlayerInfoText = ConcatenateMessages(PlayerInfoText, SpdMsg)

            PlayerBattle1v1Info.StatsText.SetText(PlayerInfoText)

    UpdateBattleInformationText(Player:player, NewText:string, TotalTime:float)<suspends>:void =
        TypewriteBattleText(Player, NewText, TotalTime)

    GetNextBattleTextVersion(Player:player):int =
        var V:int = 0
        if (Cur := BattleTextVersionByPlayer[Player]):
            set V = Cur + 1
        else:
            set V = 1

        if (set BattleTextVersionByPlayer[Player] = V) {}
        return V

    TypewriteBattleText(Player:player, FullText:string, TotalTime:float)<suspends>:void =
        # Safely look up player info in the map
        if (PlayerBattle1v1Info := PlayerBattle1v1InfoMap[Player]):
            # Cancel any previous typing for this player
            Version := GetNextBattleTextVersion(Player)
    
            # Set empty initial text (for classic RPG vibe)
            PlayerBattle1v1Info.BattleInformationText.SetText(CreateMessage(""))
    
            # Prevent zero division, handle empty string
            CharCount : int = FullText.Length
            if (CharCount <= 0):
                return
    
            # Calculate step duration per character
            Step : float = TotalTime / (CharCount * 1.0)
            StepValue : float = if (Step < 0.005) { 0.005 } else { Step }  # 2x faster min
    
            # Start with an empty message
            var Acc:message = CreateMessage("")
    
            # Type out each character in sequence
            for (Ch : FullText):
                # Break if a new version/typesetting occurs (i.e. message replaced)
                if (CurrentVersion := BattleTextVersionByPlayer[Player], CurrentVersion <> Version):
                    return
    
                set Acc = ConcatenateMessages(Acc, CreateMessage("{Ch}"))
                PlayerBattle1v1Info.BattleInformationText.SetText(Acc)
                Sleep(0.005) #StepValue
    
            # Pause after finished text for readability
            Sleep(1.75)
            #GetOrCreateContinueEvent(Player).Await()


    GetOrCreateContinueEvent(Player:player):event() =
        if (E := ContinueEventByPlayer[Player]):
            return E
        NewE : event() = event(){}
        if (set ContinueEventByPlayer[Player] = NewE) {}
        return NewE

    UpdateMoxieHealthbar(Player:player, AttackerIsA:logic, Progress:float, DeltaProgress:float)<suspends>:void =
        if (PlayerBattle1v1Info := PlayerBattle1v1InfoMap[Player]):
            Sleep(1.9)
            if(AttackerIsA?):
                # Update Wild Moxie Healthbar
                set PlayerBattle1v1Info.WildMoxie_HealthbarMat.Progress = Progress
                set PlayerBattle1v1Info.WildMoxie_HealthbarMat.DeltaProgress = DeltaProgress
                # Update Wild Moxie Health animation
                set PlayerBattle1v1Info.WildMoxie_HealthbarMat.DeltaFactor = 1.0
                loop:
                    if (PlayerBattle1v1Info.WildMoxie_HealthbarMat.DeltaFactor <= 0.0):
                        set PlayerBattle1v1Info.WildMoxie_HealthbarMat.DeltaFactor = 0.0
                        break
                    Sleep(0.1)
                    set PlayerBattle1v1Info.WildMoxie_HealthbarMat.DeltaFactor -= 0.1
            else:
                # Update Player Moxie Healthbar
                
                set PlayerBattle1v1Info.PlayerMoxie_HealthbarMat.Progress = Progress
                set PlayerBattle1v1Info.PlayerMoxie_HealthbarMat.DeltaProgress = DeltaProgress
                # Update Wild Moxie Health animation
                set PlayerBattle1v1Info.PlayerMoxie_HealthbarMat.DeltaFactor = 1.0
                loop:
                    if (PlayerBattle1v1Info.PlayerMoxie_HealthbarMat.DeltaFactor <= 0.0):
                        set PlayerBattle1v1Info.PlayerMoxie_HealthbarMat.DeltaFactor = 0.0
                        break
                    Sleep(0.1)
                    set PlayerBattle1v1Info.PlayerMoxie_HealthbarMat.DeltaFactor -= 0.1

        



    AwaitPlayerInput(Player:player, UIBattle1v1Info:battle_ui_info)<suspends>: void =
        race:
            # Wait for the Fight Button Click to perform logic
            loop:
                UIBattle1v1Info.FightButton.OnClick().Await() 
                Sleep(0.0)
                OpenAttackSelectionInfoOverlay(Player)
                Print("Moxie Battle - Fight Button Pressed!")
            # Wait for the Items Button Click to perform logic
            loop:
                UIBattle1v1Info.ItemsButton.OnClick().Await() 
                Sleep(0.0)
                Print("Moxie Battle - Items Button Pressed!")
            # Wait for the Run Button Click to perform logic (EXIT)
            loop:
                UIBattle1v1Info.RunButton.OnClick().Await() 
                Sleep(0.0)
                Print("Moxie Battle - Run Button Pressed!")
                RemoveEndBattleWidget(Player, UIBattle1v1Info)
            # Wait for the Info Button Click to perform logic
            loop:
                UIBattle1v1Info.TeamInfoButton.OnClick().Await() 
                Sleep(0.0)
                Print("Moxie Battle - Info Button Pressed!")
            # Wait for the Attack1 Button Click to perform logic
            loop:
                UIBattle1v1Info.Attack1Button.OnClick().Await() 
                Sleep(0.0)
                Print("Moxie Battle - Attack 1 Button Pressed!")
                OpenConfirmAttackOverlay(Player, 1)
            # Wait for the Attack2 Button Click to perform logic
            loop:
                UIBattle1v1Info.Attack2Button.OnClick().Await() 
                Sleep(0.0)
                Print("Moxie Battle - Attack 2 Button Pressed!")
                OpenConfirmAttackOverlay(Player, 2)
            # Wait for the Attack3 Button Click to perform logic
            loop:
                UIBattle1v1Info.Attack3Button.OnClick().Await() 
                Sleep(0.0)
                Print("Moxie Battle - Attack 3 Button Pressed!")
                OpenConfirmAttackOverlay(Player, 3)
            # Wait for the Attack4 Button Click to perform logic
            loop:
                UIBattle1v1Info.Attack4Button.OnClick().Await() 
                Sleep(0.0)
                Print("Moxie Battle - Attack 4 Button Pressed!")
                OpenConfirmAttackOverlay(Player, 4)
            # Wait for the Attack Back Button Click to perform logic
            loop:
                UIBattle1v1Info.AttackBackButton.OnClick().Await() 
                Sleep(0.0)
                CloseAttackSelectionInfoOverlay(Player)
                Print("Moxie Battle - Attack Back Button Pressed!")
            # Wait for the Confirm Attack Button Click to perform logic
            loop:
                UIBattle1v1Info.ConfirmAttackButton.OnClick().Await() 
                Sleep(0.0)
                Print("Moxie Battle - Confirm Attack Button Pressed!")
            # Wait for the Cancel Attack Button Click to perform logic
            loop:
                UIBattle1v1Info.CancelAttackButton.OnClick().Await() 
                Sleep(0.0)
                Print("Moxie Battle - Cancel Attack Button Pressed!")
                CloseConfirmAttackOverlay(Player)


    ListenForBattleUI(Player:player)<suspends>:void =
        if(UIBattle1v1Info := PlayerBattle1v1InfoMap[Player]):
            # Initialize state
            ClearPendingInput(Player)

            race:
                # FIGHT opens attacks overlay (menu action)
                loop:
                    UIBattle1v1Info.FightButton.OnClick().Await() 
                    #Sleep(0.0)
                    OpenAttackSelectionInfoOverlay(Player)
                    SetPendingInput(Player, battle_input{Action := battle_action.Fight, AttackIndex := -1, ItemIndex := -1, SwitchIndex := -1})

                # ITEMS (you can open an items overlay later; for now just mark action)
                loop:
                    UIBattle1v1Info.ItemsButton.OnClick().Await() 
                    #Sleep(0.0)
                    # TODO: OpenItemsOverlay(Player, UI)
                    SetPendingInput(Player, battle_input{Action := battle_action.Items, AttackIndex := -1, ItemIndex := -1, SwitchIndex := -1})

                # RUN (exit battle)
                loop:
                    UIBattle1v1Info.RunButton.OnClick().Await() 
                    #Sleep(0.0)
                    SetPendingInput(Player, battle_input{Action := battle_action.Run, AttackIndex := -1, ItemIndex := -1, SwitchIndex := -1})

                # INFO
                loop:
                    UIBattle1v1Info.TeamInfoButton.OnClick().Await() 
                    #Sleep(0.0)
                    SetPendingInput(Player, battle_input{Action := battle_action.Info, AttackIndex := -1, ItemIndex := -1, SwitchIndex := -1})

                # Attack buttons pick attack index (0..2) and open confirm overlay
                loop:
                    UIBattle1v1Info.Attack1Button.OnClick().Await() 
                    #Sleep(0.0)
                    SetSelectedAttack(Player, 0)
                    if(AttackIdx:= SelectedAttackIndexByPlayer[Player], AttackIdx >= 0):
                        OpenConfirmAttackOverlay(Player, 1)
                    #SetPendingInput(Player, battle_input{Action := battle_action.Fight, AttackIndex := 0, ItemIndex := -1})

                loop:
                    UIBattle1v1Info.Attack2Button.OnClick().Await() 
                    #Sleep(0.0)
                    SetSelectedAttack(Player, 1)
                    if(AttackIdx:= SelectedAttackIndexByPlayer[Player], AttackIdx >= 0):
                        OpenConfirmAttackOverlay(Player, 2)
                    #SetPendingInput(Player, battle_input{Action := battle_action.Fight, AttackIndex := 1, ItemIndex := -1})

                loop:
                    UIBattle1v1Info.Attack3Button.OnClick().Await() 
                    #Sleep(0.0)
                    SetSelectedAttack(Player, 2)
                    if(AttackIdx:= SelectedAttackIndexByPlayer[Player], AttackIdx >= 0):
                        OpenConfirmAttackOverlay(Player, 3)
                    #SetPendingInput(Player, battle_input{Action := battle_action.Fight, AttackIndex := 2, ItemIndex := -1})

                loop:
                    UIBattle1v1Info.Attack4Button.OnClick().Await() 
                    #Sleep(0.0)
                    SetSelectedAttack(Player, 3)
                    if(AttackIdx:= SelectedAttackIndexByPlayer[Player], AttackIdx >= 0):
                        OpenConfirmAttackOverlay(Player, 4)
                    #SetPendingInput(Player, battle_input{Action := battle_action.Fight, AttackIndex := 3, ItemIndex := -1})

                # Back from attacks menu
                loop:
                    UIBattle1v1Info.AttackBackButton.OnClick().Await() 
                    #Sleep(0.0)
                    CloseAttackSelectionInfoOverlay(Player)
                    SetPendingInput(Player, battle_input{Action := battle_action.None, AttackIndex := -1, ItemIndex := -1, SwitchIndex := -1})

                # Continue text from battle info
                loop:
                    UIBattle1v1Info.ContinueBattleTextButton.OnClick().Await() 
                    GetOrCreateContinueEvent(Player).Signal()
                    #Sleep(0.0)

                # Confirm / Cancel confirm overlay
                loop:
                    UIBattle1v1Info.CancelAttackButton.OnClick().Await() 
                    ClearSelectedAttack(Player)
                    CloseConfirmAttackOverlay(Player)
                    OpenAttackSelectionInfoOverlay(Player)
                    # keep action as Fight, but clear attack so engine knows "not confirmed"
                    #SetPendingInput(Player, battle_input{Action := battle_action.Fight, AttackIndex := -1, ItemIndex := -1})

                loop:
                    UIBattle1v1Info.ConfirmAttackButton.OnClick().Await() 
                        # Signal that attack choice is CONFIRMED (engine will read AttackIndex)
                        var Idx:int = -1
                        if (Sel := SelectedAttackIndexByPlayer[Player]):
                            set Idx = Sel

                        # Only commit if player actually selected an attack
                        if (Idx >= 0):
                            ShowOnlyBattleInformation(Player)
                            SetPendingInput(Player, battle_input{Action := battle_action.Fight, AttackIndex := Idx, ItemIndex := -1, SwitchIndex := -1})
                        else:
                            Print("Confirm pressed but no attack selected (ignored).")

    StartTurnBasedBattle(Player:player)<suspends>:void =
        if(UIBattle1v1Info := PlayerBattle1v1InfoMap[Player]):
            var Turn:int = 1
            var SafetyMaxTurns:int = 200

            ClearPendingInput(Player)
            # Ensure menus are in the base state
            UIBattle1v1Info.BattleSelectionInfoOverlay.SetVisibility(widget_visibility.Visible)
            UIBattle1v1Info.AttackSelectionInfoOverlay.SetVisibility(widget_visibility.Hidden)
            UIBattle1v1Info.ConfirmAttackInfo.SetVisibility(widget_visibility.Hidden)
            #UIBattle1v1Info.ContinueBattleTextButton.SetEnabled(false)
            #UIBattle1v1Info.ContinueBattleTextButton.SetVisibility(widget_visibility.Hidden) 

            UpdateBattleInformationText(Player, "What will your Moxie do?", 2.0)

            loop:
                if (IsOver[] or Turn > SafetyMaxTurns):
                    break

                Print("===== TURN {Turn} =====")

                # --- 1) WAIT FOR PLAYER DECISION ---
                var PlayerAtkIdx:int = -1
                var UsedItem:logic = false
                var WantsRun:logic = false

                # Here 

                loop:
                    # Wait until UI signals something happened
                    InputEvent.Await()

                    if (Pending := PendingInputByPlayer[Player]):

                        # Player wants to run
                        if (Pending.Action = battle_action.Run):
                            Print("ACTION RECEIVED - Player wants to RUN")
                            set WantsRun = true
                            break

                        # Player chose items (for now: consume a "potion"-like effect)
                        if (Pending.Action = battle_action.Items):
                            # Example item effect: heal A by 15% of its base HP (or fixed)
                            #ApplyItem_PotionLike(Player, UI)
                            Print("ACTION RECEIVED - Player wants to USE ITEM")
                            set UsedItem = true
                            break

                        # Fight flow: we only proceed if there is a CONFIRMED attack index
                        if (Pending.Action = battle_action.Fight and Pending.AttackIndex >= 0):
                            Print("ACTION RECEIVED - Player wants to Attack!")
                            set PlayerAtkIdx = Pending.AttackIndex
                            break

                    # Otherwise keep waiting

                if (WantsRun?):
                    Print("Player chose RUN. Ending battle UI.")
                    RemoveEndBattleWidget(Player, UIBattle1v1Info)
                    return

                # If an item was used, enemy still gets a turn (like Pokemon).
                # If you want items to consume the whole turn, keep it as-is.
                # If you want items to NOT allow enemy action, just continue Turn+1.
                var EnemyAtkIdx:int = 0
                if (WildMoxie_B.Attacks.Length > 0):
                    set EnemyAtkIdx = GetRandomInt(0, WildMoxie_B.Attacks.Length - 1)

                # If player picked attack, close confirm overlay now (clean UI)
                #if (PlayerAtkIdx >= 0):
                #    UIBattle1v1Info.ConfirmAttackInfo.SetVisibility(widget_visibility.Hidden)
                #    UIBattle1v1Info.AttackSelectionInfoOverlay.SetVisibility(widget_visibility.Hidden)
                #    UIBattle1v1Info.BattleSelectionInfoOverlay.SetVisibility(widget_visibility.Visible)

                # --- 2) WHO GOES FIRST? (speed order) ---
                var FirstIsA:logic = false
                if (PlayerMoxie_A.Speed > WildMoxie_B.Speed):
                    set FirstIsA = true
                else if (WildMoxie_B.Speed > PlayerMoxie_A.Speed):
                    set FirstIsA = false
                else:
                    set FirstIsA = logic{GetRandomInt(0, 1) = 0}

                # --- 3) EXECUTE TURN ACTIONS (with narration + waits) ---
                if (UsedItem?):
                    Print("Player used an item.")
                    Sleep(1.0)
                    if (not IsOver[]):
                        DoAttackSequence(Player, false, EnemyAtkIdx)
                else:
                    if (FirstIsA?):
                        DoAttackSequence(Player, true, PlayerAtkIdx)
                        if (not IsOver[]):
                            DoAttackSequence(Player, false, EnemyAtkIdx)
                    else:
                        DoAttackSequence(Player, false, EnemyAtkIdx)
                        if (not IsOver[]):
                            DoAttackSequence(Player, true, PlayerAtkIdx)

                # Update the Player's Moxie Stats
                UpdatePlayerMoxieStatsInfo(Player)

                # --- 4) END TURN ---
                Print("TURN END => HP(A:{CurrentHPA} B:{CurrentHPB})")
                Print("")
                ClearPendingInput(Player)
                set Turn += 1

                # Show the UI for the Battle Selection
                ShowBattleSelectionInfoOverlay(Player)
                UpdateBattleInformationText(Player, "What will your Moxie do?", 2.0)

            # End battle result
            if (Turn > SafetyMaxTurns):
                Print("Battle ended by SafetyMaxTurns.")
                RemoveEndBattleWidget(Player, UIBattle1v1Info)
            else:
                Print("Battle ended. Winner: {if (CurrentHPA > 0.0) then "A" else "B"}")
                RemoveEndBattleWidget(Player, UIBattle1v1Info)      

    RemoveEndBattleWidget(Player:player, UIBattle1v1Info:battle_ui_info): void = 
        if (PlayerUI:=GetPlayerUI[Player]):
            UpdateShouldCancelAnimations(Player)  
            PlayerUI.RemoveWidget(UIBattle1v1Info.Canvas)

    UpdateShouldCancelAnimations(Player:player): void =
        if(UIBattle1v1Info := PlayerBattle1v1InfoMap[Player]):  
            NewUIBattle1v1Info := battle_ui_info:
                FightButton:= UIBattle1v1Info.FightButton
                ItemsButton:= UIBattle1v1Info.ItemsButton
                RunButton:= UIBattle1v1Info.RunButton
                TeamInfoButton:= UIBattle1v1Info.TeamInfoButton
                StatsText:= UIBattle1v1Info.StatsText
                Attack1Button:= UIBattle1v1Info.Attack1Button
                Attack2Button:= UIBattle1v1Info.Attack2Button
                Attack3Button:= UIBattle1v1Info.Attack3Button
                Attack4Button:= UIBattle1v1Info.Attack4Button
                AttackBackButton:= UIBattle1v1Info.AttackBackButton
                ConfirmAttackButton:= UIBattle1v1Info.ConfirmAttackButton
                CancelAttackButton:= UIBattle1v1Info.CancelAttackButton
                ContinueBattleTextButton:= UIBattle1v1Info.ContinueBattleTextButton
                TeamInfoBackButton:= button_quiet{}

                BattleSelectionInfoOverlay:= UIBattle1v1Info.BattleSelectionInfoOverlay
                AttackSelectionInfoOverlay:= UIBattle1v1Info.AttackSelectionInfoOverlay
                ConfirmAttackInfo:= UIBattle1v1Info.ConfirmAttackInfo
                BattleInformationOverlay:= UIBattle1v1Info.BattleInformationOverlay
                PlayerTeamWidgetOverlay:= overlay{}
                PlayerTeamButtonsOverlay:= overlay{}

                ConfirmAttackInfoName:= UIBattle1v1Info.ConfirmAttackInfoName
                ConfirmAttackInfoDesc:= UIBattle1v1Info.ConfirmAttackInfoDesc
                BattleInformationText:= UIBattle1v1Info.BattleInformationText

                MoxieWidgeRight:= UIBattle1v1Info.MoxieWidgeRight
                MoxieWidgeLeft:= UIBattle1v1Info.MoxieWidgeLeft

                MoxieTeamWidget_0:= UIBattle1v1Info.MoxieTeamWidget_0
                MoxieTeamWidget_1:= UIBattle1v1Info.MoxieTeamWidget_1
                MoxieTeamWidget_2:= UIBattle1v1Info.MoxieTeamWidget_2
                MoxieTeamWidget_3:= UIBattle1v1Info.MoxieTeamWidget_3
                MoxieTeamWidget_4:= UIBattle1v1Info.MoxieTeamWidget_4
                MoxieTeamWidget_5:= UIBattle1v1Info.MoxieTeamWidget_5

                MoxieTeamButton_0:= button_quiet{}
                MoxieTeamButton_1:= button_quiet{}
                MoxieTeamButton_2:= button_quiet{}
                MoxieTeamButton_3:= button_quiet{}
                MoxieTeamButton_4:= button_quiet{}
                MoxieTeamButton_5:= button_quiet{}


                AnimationLoopCancelledRight:= true
                AnimationLoopCancelledLeft:= true

                Canvas:= UIBattle1v1Info.Canvas

            if(set PlayerBattle1v1InfoMap[Player] = NewUIBattle1v1Info){}
            
    OpenAttackSelectionInfoOverlay(Player:player): void =
        if (PlayerBattle1v1Info := PlayerBattle1v1InfoMap[Player]):
            PlayerBattle1v1Info.BattleSelectionInfoOverlay.SetVisibility(widget_visibility.Hidden)
            PlayerBattle1v1Info.AttackSelectionInfoOverlay.SetVisibility(widget_visibility.Visible) 
            PlayerBattle1v1Info.BattleInformationOverlay.SetVisibility(widget_visibility.Hidden)

    CloseAttackSelectionInfoOverlay(Player:player): void =
        if (PlayerBattle1v1Info := PlayerBattle1v1InfoMap[Player]):
            PlayerBattle1v1Info.BattleSelectionInfoOverlay.SetVisibility(widget_visibility.Visible)
            PlayerBattle1v1Info.AttackSelectionInfoOverlay.SetVisibility(widget_visibility.Hidden)
            PlayerBattle1v1Info.BattleInformationOverlay.SetVisibility(widget_visibility.Visible)
            spawn{UpdateBattleInformationText(Player, "What will your Moxie do?", 2.0)}

    ShowOnlyBattleInformation(Player:player): void =
        if (PlayerBattle1v1Info := PlayerBattle1v1InfoMap[Player]):
            PlayerBattle1v1Info.BattleSelectionInfoOverlay.SetVisibility(widget_visibility.Hidden)
            PlayerBattle1v1Info.AttackSelectionInfoOverlay.SetVisibility(widget_visibility.Collapsed)
            PlayerBattle1v1Info.ConfirmAttackInfo.SetVisibility(widget_visibility.Collapsed)
            PlayerBattle1v1Info.BattleInformationOverlay.SetVisibility(widget_visibility.Visible) 
            #PlayerBattle1v1Info.ContinueBattleTextButton.SetEnabled(true)
            #PlayerBattle1v1Info.ContinueBattleTextButton.SetVisibility(widget_visibility.Visible) 

    ShowBattleSelectionInfoOverlay(Player:player): void =
        if (PlayerBattle1v1Info := PlayerBattle1v1InfoMap[Player]):
            PlayerBattle1v1Info.BattleSelectionInfoOverlay.SetVisibility(widget_visibility.Visible)
            PlayerBattle1v1Info.AttackSelectionInfoOverlay.SetVisibility(widget_visibility.Collapsed)
            PlayerBattle1v1Info.ConfirmAttackInfo.SetVisibility(widget_visibility.Collapsed)
            PlayerBattle1v1Info.BattleInformationOverlay.SetVisibility(widget_visibility.Visible)
            #PlayerBattle1v1Info.ContinueBattleTextButton.SetEnabled(false)
           # PlayerBattle1v1Info.ContinueBattleTextButton.SetVisibility(widget_visibility.Hidden)  

    OpenConfirmAttackOverlay(Player:player, AttackIndex:int): void =
        if (PlayerBattle1v1Info := PlayerBattle1v1InfoMap[Player]):
            PlayerBattle1v1Info.ConfirmAttackInfo.SetVisibility(widget_visibility.Visible)
            PlayerBattle1v1Info.AttackSelectionInfoOverlay.SetVisibility(widget_visibility.Collapsed)

            AttackIndexAdjusted:= AttackIndex - 1

            # Displaye the Player's first Moxie to the Left Moxie Widget
            #PlayerData := MoxieManager.PlayerDataDevice.GetPlayerData(Player)
            #PlayerMoxiesArray := PlayerData.PlayerMoxiesArray
            #if (PlayerMoxiesArray.Length > 0):
            #        if (FirstMoxieData := PlayerMoxiesArray[0]):
            if(AtkName:= PlayerMoxie_A.Attacks[AttackIndexAdjusted].Name, AtkDesc:= PlayerMoxie_A.Attacks[AttackIndexAdjusted].Description):
                Print("Attack found changing name and desc - AtkIdx: {AttackIndex} - AdjustedIdx: {AttackIndexAdjusted}")
                    PlayerBattle1v1Info.ConfirmAttackInfoName.SetText(CreateMessage(AtkName))
                    PlayerBattle1v1Info.ConfirmAttackInfoDesc.SetText(CreateMessage(AtkDesc))
            else:
                Print("Attack NOT found! - AtkIdx: {AttackIndex} - AdjustedIdx: {AttackIndexAdjusted}")

    CloseConfirmAttackOverlay(Player:player): void =
        if (PlayerBattle1v1Info := PlayerBattle1v1InfoMap[Player]):
            PlayerBattle1v1Info.ConfirmAttackInfo.SetVisibility(widget_visibility.Collapsed)
            PlayerBattle1v1Info.AttackSelectionInfoOverlay.SetVisibility(widget_visibility.Visible)

    PlayDamagedAnimUILeft(Player:player, MoxieWidget: Widgets.Test.WBP_Moxie_Left)<suspends>:void =   
        Print("Moxie - Left Damaged anim selected")
        Sleep(1.9)
        set MoxieWidget.PlayDamagedAnim = 1.0 
        set MoxieWidget.PlayIdleAnim = 0.0  
        set MoxieWidget.PlayScratchAnim = 0.0 
        Sleep(0.4)
        set MoxieWidget.PlayDamagedAnim = 0.0 


    PlayDamagedAnimUIRight(Player:player, MoxieWidget: Widgets.Test.WBP_Moxie_Right)<suspends>:void =   
        Print("Moxie - Right Damaged anim selected")
        Sleep(1.9)
        set MoxieWidget.PlayDamagedAnim = 1.0 
        set MoxieWidget.PlayIdleAnim = 0.0  
        set MoxieWidget.PlayScratchAnim = 0.0 
        Sleep(0.4)
        set MoxieWidget.PlayDamagedAnim = 0.0
    
    var Left_IsIdleNext:logic = true
    # Loop the animation forever
    LoopIdleAnimationUILeft(Player:player, MoxieWidget: Widgets.Test.WBP_Moxie_Left)<suspends>:void =
        #Print("Moxie - Anim Loop Started")
        var TimeToWait: float = 0.0
        loop:
            if (UIBattle1v1Info := PlayerBattle1v1InfoMap[Player], UIBattle1v1Info.AnimationLoopCancelledLeft = true):
                #Print("Animation Left loop cancelled, breaking out")
                break
            if (Left_IsIdleNext?):
                #Print("Moxie - Idle anim selected")
                set TimeToWait = GetRandomFloat(8.0, 12.0)
                set MoxieWidget.PlayIdleAnim = 1.0  
                set MoxieWidget.PlayScratchAnim = 0.0 
            else:
                #Print("Moxie - Scratch anim selected")
                set TimeToWait = 2.0
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

    var Right_IsIdleNext:logic = false
    # Loop the animation forever
    LoopIdleAnimationUIRight(Player:player, MoxieWidget: Widgets.Test.WBP_Moxie_Right)<suspends>:void =
        #Print("Moxie - Anim Loop Started")
        var TimeToWait: float = 0.0
        loop:
            if (UIBattle1v1Info := PlayerBattle1v1InfoMap[Player], UIBattle1v1Info.AnimationLoopCancelledRight = true):
                #Print("Animation Right loop cancelled, breaking out")
                break
            if (Right_IsIdleNext?):	
                #Print("Moxie - Idle anim selected")
                set TimeToWait = GetRandomFloat(8.0, 12.0)
                set MoxieWidget.PlayIdleAnim = 1.0  
                set MoxieWidget.PlayScratchAnim = 0.0 
            else:
                #Print("Moxie - Scratch anim selected")
                set TimeToWait = 2.0
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

