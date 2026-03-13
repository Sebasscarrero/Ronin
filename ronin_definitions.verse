
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Assets }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/Playspaces }

# Assets Path Module
Widgets := module:
    Test<public> := module:

Assets := module:
    Test<public> := module:
    Bestial<public> := module:
        Hunter<public> := module:
        Berserker<public> := module:
        Bloodfang<public> := module:
        Juggernaut<public> := module:
        Rampage<public> := module:

    Herbal<public> := module:
        Bloomweaver<public> := module:
        Thornheart<public> := module:
        Rootbound<public> := module:
        Frutal<public> := module:
        Verdant<public> := module:
    Winged<public> := module:
        Zephyrwing<public> := module:
        Cloudbreaker<public> := module:
        Featherbound<public> := module:
        Fierywing<public> := module:
        Stormcrest<public> := module:
    Reptilian<public> := module:
        Venomscale<public> := module:
        Dunestalker<public> := module:
        Ignifang<public> := module:
        Stoneclad<public> := module:
    Aquatic<public> := module:
    Bug<public> := module:
        Hiveborn<public> := module:
        Swarmcaller<public> := module:
        Nectarblade<public> := module: 
        Broodling<public> := module:
        Ladydae<public> := module:

UI := module:
    Materials<public> := module:

GetFirstPlayer(Playspace:fort_playspace)<transacts><decides>:player =
    Players := Playspace.GetPlayers()
    Players[0]

CreateMessage<localizes>(Str:string):message = "{Str}"
GetPlayerName<localizes>(Agent:agent):message = "{Agent}"
ConcatenateMessages<public><localizes>(Lhs:message, Rhs:message):message = "{Lhs}{Rhs}"

# Clamp float value to MaxValue
ClampFloatValues(Value:float, MaxValue: float)<transacts>:float =
    if (Value >= MaxValue) then MaxValue else Value

# Clamp int value to MaxValue
ClampIntValues(Value:int, MaxValue: int)<transacts>:int =
    if (Value >= MaxValue) then MaxValue else Value

# Clamp negatives to zero (avoid weird inputs)
ClampNonNegative(x:float)<transacts>:float =
    if (x < 0.0) then 0.0 else x    

FormatFloatTo1Decimal(Value:float):message =
        FullString := ToString(Value)
        var DecimalIndex : int = -1
        for (Index := 0..FullString.Length - 1):
            if (FullString[Index] = '.'):
                set DecimalIndex = Index
        # Truncate string to 1 digit after decimal if possible
        if (DecimalIndex >= 0 and DecimalIndex + 1 < FullString.Length):
            # Take up to 1 digit after the decimal
            if (ShortString := FullString.Slice[0, DecimalIndex + 2]):
                CreateMessage("{ShortString}")
            else:
                CreateMessage("{FullString}")
        else:
            CreateMessage("{FullString}")

FormatFloatTo1DecimalString(Value:float):string =
    FullString := ToString(Value)
    var DecimalIndex:int = -1

    # Find the decimal point
    for (Index := 0..FullString.Length - 1):
        if (FullString[Index] = '.'):
            set DecimalIndex = Index

    # If decimal exists and we can keep 1 digit after it
    if (DecimalIndex >= 0 and DecimalIndex + 1 < FullString.Length):
        if (ShortString := FullString.Slice[0, DecimalIndex + 2]):
            return ShortString
        else:
            return FullString
    else:
        return FullString

# Retunr the TargetValue as a value between 0.0 to 1.0 using MaxValue
NormalizeValue(TargetValue:float, MaxValue:float):float =
    if (MaxValue <= 0.0):
        return 0.0

    Normalized := TargetValue / MaxValue

    # Clamp to stay safely between 0.0 and 1.0
    return Clamp(Normalized, 0.0, 1.0)



# Code to be able to pass more arguments to event subscriptions. Works for events that send an agent and that don't send anything.
(Listenable : listenable(agent)).SubscribeAgent(OutputFunc : tuple(agent, t)->void, ExtraData : t where t:type) : cancelable =
    Wrapper := wrapper_agent(t){ExtraData := ExtraData, OutputFunc := OutputFunc}
    Listenable.Subscribe(Wrapper.InputFunc)
wrapper_agent(t : type) := class():
    ExtraData : t;
    OutputFunc : tuple(agent, t) -> void
    InputFunc(Agent : agent):void = OutputFunc(Agent, ExtraData)

# Code to be able to pass more arguments to event subscriptions. Works for events that send an ?agent and that don't send anything.
(Listenable : listenable(?agent)).SubscribeOptionalAgent(OutputFunc : tuple(?agent, t)->void, ExtraData : t where t:type) : cancelable =
    Wrapper := wrapper_optional_agent(t){ExtraData := ExtraData, OutputFunc := OutputFunc}
    Listenable.Subscribe(Wrapper.InputFunc)
wrapper_optional_agent(t:type) := class():
    ExtraData : t
    OutputFunc : tuple(?agent, t) -> void
    InputFunc(OptionalAgent : ?agent):void =
        OutputFunc(OptionalAgent, ExtraData)

# Code to be able to pass more arguments to event subscriptions. Works for events that send a widget_message and that don't send anything.
(Listenable : listenable(widget_message)).SubscribeWidgetMessage(OutputFunc : tuple(widget_message, t) -> void, ExtraData : t where t:type) : cancelable =
    Wrapper := wrapper_message(t){ExtraData := ExtraData, OutputFunc := OutputFunc}
    Listenable.Subscribe(Wrapper.InputFunc)
wrapper_message(t : type) := class():
    ExtraData : t
    OutputFunc : tuple(widget_message, t) -> void
 
    InputFunc(Msg : widget_message):void = OutputFunc(Msg, ExtraData)

# -------------------------------------------------------------------------------------------------------------------------------------

# Get the Moxie Texture using the Moxie Type, Moxie Part and Moxie Part Variant
GetMoxiePartTexture(Moxie:ronin_creature, MoxiePart:ronin_part):[]texture = 
    MoxieType:= Moxie.Type
    #Print("Getting Moxie Texture for Part: {PartToString(MoxiePart)}")

    case (MoxiePart):
        # Eyes
        ronin_part.Eyes => 
            MoxieVariant:= Moxie.Parts.Eyes.Dominant # if Hunter, Rampage, Berserker...
            MoxieVariantType:= GetVariantTypeName(MoxieVariant) # if Bestial, Bug, Aquatic...
            case (StringToCreatureType(MoxieVariantType)):
                # Besial Eyes
                creature_type.Bestial => 
                    case (MoxieVariant):
                        "Hunter" => array{Assets.Bestial.Hunter.Eyes}
                        "Rampage" => array{Assets.Bestial.Rampage.Eyes}
                        "Berserker" => array{Assets.Bestial.Berserker.Eyes}
                        "Juggernaut" => array{Assets.Bestial.Juggernaut.Eyes}
                        "Bloodfang" => array{Assets.Bestial.Bloodfang.Eyes}
                        _ => array{Assets.Test.Test_Eyes}
                # Bug Eyes
                creature_type.Bug => 
                    case (MoxieVariant):
                        "Hiveborn" => array{Assets.Bug.Hiveborn.Eyes}
                        "Swarmcaller" => array{Assets.Bug.Swarmcaller.Eyes}
                        "Ladydae" => array{Assets.Bug.Ladydae.Eyes}
                        "Nectarblade" => array{Assets.Bug.Nectarblade.Eyes}
                        "Broodling" => array{Assets.Bug.Broodling.Eyes}
                        _ => array{Assets.Test.Test_Eyes}
                # Winged Eyes
                creature_type.Winged => 
                    case (MoxieVariant):
                        "Fierywing" => array{Assets.Winged.Fierywing.Eyes}
                        "Featherbound" => array{Assets.Winged.Featherbound.Eyes}
                        "Zephyrwing" => array{Assets.Winged.Zephyrwing.Eyes}
                        "Stormcrest" => array{Assets.Winged.Stormcrest.Eyes}
                        "Cloudbreaker" => array{Assets.Winged.Cloudbreaker.Eyes}
                        _ => array{Assets.Test.Test_Eyes}
                # Reptilian Eyes
                creature_type.Reptilian => 
                    case (MoxieVariant):
                        #"Frenzygaze" => array{Assets.Reptilian.Frenzygaze.Eyes}
                        "Venomscale" => array{Assets.Reptilian.Venomscale.Eyes}
                        "Dunestalker" => array{Assets.Reptilian.Dunestalker.Eyes}
                        "Ignifang" => array{Assets.Reptilian.Ignifang.Eyes}
                        "Stoneclad" => array{Assets.Reptilian.Stoneclad.Eyes}
                        _ => array{Assets.Test.Test_Eyes}
                # Aquatic Eyes
                creature_type.Aquatic => 
                    case (MoxieVariant):
                        #"Tideborn" => array{Assets.Aquatic.Tideborn.Eyes}
                        #"Coralguard" => array{Assets.Aquatic.Coralguard.Eyes}
                        #"Abyssal" => array{Assets.Aquatic.Abyssal.Eyes}
                        #"Wavebinder" => array{Assets.Aquatic.Wavebinder.Eyes}
                        #"Deepcurrent" => array{Assets.Aquatic.Deepcurrent.Eyes}
                        _ => array{Assets.Test.Test_Eyes}
                # Herbal Eyes
                creature_type.Herbal => 
                    case (MoxieVariant):
                        "Frutal" => array{Assets.Herbal.Frutal.Eyes}
                        "Bloomweaver" => array{Assets.Herbal.Bloomweaver.Eyes}
                        "Thornheart" => array{Assets.Herbal.Thornheart.Eyes}
                        "Verdant" => array{Assets.Herbal.Verdant.Eyes}
                        "Rootbound" => array{Assets.Herbal.Rootbound.Eyes}
                        _ => array{Assets.Test.Test_Eyes}
                # Aurora Eyes
                creature_type.Aurora =>
                    case (MoxieVariant):
                            #"Prismguard" => array{Assets.Aurora.Prismguard.Eyes}
                            #"Luminborn" => array{Assets.Aurora.Luminborn.Eyes}
                            #"Fluxweaver" => array{Assets.Aurora.Fluxweaver.Eyes}
                            #"Chromatic" => array{Assets.Aurora.Chromatic.Eyes}
                            #"Radiantforge" => array{Assets.Aurora.Radiantforge.Eyes}
                            _ => array{Assets.Test.Test_Eyes}
                # Zenith Eyes
                creature_type.Zenith => 
                    case (MoxieVariant):
                        #"Sunborne" => array{Assets.Zenith.Sunborne.Eyes}
                        #"Dawnbreak" => array{Assets.Zenith.Dawnbreak.Eyes}
                        #"Haloed" => array{Assets.Zenith.Haloed.Eyes}
                        #"Ascendant" => array{Assets.Zenith.Ascendant.Eyes}
                        #"Goldflare" => array{Assets.Zenith.Goldflare.Eyes}
                        _ => array{Assets.Test.Test_Eyes}
                # Gloam Eyes
                creature_type.Gloam => 
                    case (MoxieVariant):
                        #"Voidborn" => array{Assets.Gloam.Voidborn.Eyes}
                        #"Umbral" => array{Assets.Gloam.Umbral.Eyes}
                        #"Nightveil" => array{Assets.Gloam.Nightveil.Eyes}
                        #"Shadowborne" => array{Assets.Gloam.Shadowborne.Eyes}
                        #"Eclipsed" => array{Assets.Gloam.Eclipsed.Eyes}
                        _ => array{Assets.Test.Test_Eyes}


        # Mouth
        ronin_part.Mouth => 
            MoxieVariant:= Moxie.Parts.Mouth.Dominant # if Hunter, Rampage, Berserker...
            MoxieVariantType:= GetVariantTypeName(MoxieVariant) # if Bestial, Bug, Aquatic...
            case (StringToCreatureType(MoxieVariantType)):
                # Besial Mouth
                creature_type.Bestial => 
                    case (MoxieVariant):
                        "Hunter" => array{Assets.Bestial.Hunter.Mouth}
                        "Rampage" => array{Assets.Bestial.Rampage.Mouth}
                        "Berserker" => array{Assets.Bestial.Berserker.Mouth}
                        "Juggernaut" => array{Assets.Bestial.Juggernaut.Mouth}
                        "Bloodfang" => array{Assets.Bestial.Bloodfang.Mouth}
                        _ => array{Assets.Test.Test_Mouth}
                # Bug Mouth
                creature_type.Bug => 
                    case (MoxieVariant):
                        "Hiveborn" => array{Assets.Bug.Hiveborn.Mouth}
                        "Swarmcaller" => array{Assets.Bug.Swarmcaller.Mouth}
                        "Ladydae" => array{Assets.Bug.Ladydae.Mouth}
                        "Nectarblade" => array{Assets.Bug.Nectarblade.Mouth}
                        "Broodling" => array{Assets.Bug.Broodling.Mouth}
                        _ => array{Assets.Test.Test_Mouth}
                # Winged Mouth
                creature_type.Winged => 
                    case (MoxieVariant):
                        "Fierywing" => array{Assets.Winged.Fierywing.Mouth}
                        "Featherbound" => array{Assets.Winged.Featherbound.Mouth}
                        "Zephyrwing" => array{Assets.Winged.Zephyrwing.Mouth}
                        "Stormcrest" => array{Assets.Winged.Stormcrest.Mouth}
                        "Cloudbreaker" => array{Assets.Winged.Cloudbreaker.Mouth}
                        _ => array{Assets.Test.Test_Mouth}
                # Reptilian Mouth
                creature_type.Reptilian => 
                    case (MoxieVariant):
                        #"Frenzygaze" => array{Assets.Reptilian.Frenzygaze.Mouth}
                        "Venomscale" => array{Assets.Reptilian.Venomscale.Mouth}
                        "Dunestalker" => array{Assets.Reptilian.Dunestalker.Mouth}
                        "Ignifang" => array{Assets.Reptilian.Ignifang.Mouth}
                        "Stoneclad" => array{Assets.Reptilian.Stoneclad.Mouth}
                        _ => array{Assets.Test.Test_Mouth}
                # Aquatic Mouth
                creature_type.Aquatic => 
                    case (MoxieVariant):
                        #"Tideborn" => array{Assets.Aquatic.Tideborn.Mouth}
                        #"Coralguard" => array{Assets.Aquatic.Coralguard.Mouth}
                        #"Abyssal" => array{Assets.Aquatic.Abyssal.Mouth}
                        #"Wavebinder" => array{Assets.Aquatic.Wavebinder.Mouth}
                        #"Deepcurrent" => array{Assets.Aquatic.Deepcurrent.Mouth}
                        _ => array{Assets.Test.Test_Mouth}
                # Herbal Mouth
                creature_type.Herbal => 
                    case (MoxieVariant):
                        "Frutal" => array{Assets.Herbal.Frutal.Mouth}
                        "Bloomweaver" => array{Assets.Herbal.Bloomweaver.Mouth}
                        "Thornheart" => array{Assets.Herbal.Thornheart.Mouth}
                        "Verdant" => array{Assets.Herbal.Verdant.Mouth}
                        "Rootbound" => array{Assets.Herbal.Rootbound.Mouth}
                        _ => array{Assets.Test.Test_Mouth}
                # Aurora Mouth
                creature_type.Aurora =>
                    case (MoxieVariant):
                            #"Prismguard" => array{Assets.Aurora.Prismguard.Mouth}
                            #"Luminborn" => array{Assets.Aurora.Luminborn.Mouth}
                            #"Fluxweaver" => array{Assets.Aurora.Fluxweaver.Mouth}
                            #"Chromatic" => array{Assets.Aurora.Chromatic.Mouth}
                            #"Radiantforge" => array{Assets.Aurora.Radiantforge.Mouth}
                            _ => array{Assets.Test.Test_Mouth}
                # Zenith Mouth
                creature_type.Zenith => 
                    case (MoxieVariant):
                        #"Sunborne" => array{Assets.Zenith.Sunborne.Mouth}
                        #"Dawnbreak" => array{Assets.Zenith.Dawnbreak.Mouth}
                        #"Haloed" => array{Assets.Zenith.Haloed.Mouth}
                        #"Ascendant" => array{Assets.Zenith.Ascendant.Mouth}
                        #"Goldflare" => array{Assets.Zenith.Goldflare.Mouth}
                        _ => array{Assets.Test.Test_Mouth}
                # Gloam Mouth
                creature_type.Gloam => 
                    case (MoxieVariant):
                        #"Voidborn" => array{Assets.Gloam.Voidborn.Mouth}
                        #"Umbral" => array{Assets.Gloam.Umbral.Mouth}
                        #"Nightveil" => array{Assets.Gloam.Nightveil.Mouth}
                        #"Shadowborne" => array{Assets.Gloam.Shadowborne.Mouth}
                        #"Eclipsed" => array{Assets.Gloam.Eclipsed.Mouth}
                        _ => array{Assets.Test.Test_Mouth}
                        

        # Tail
        ronin_part.Tail => 
            MoxieVariant:= Moxie.Parts.Tail.Dominant # if Hunter, Rampage, Berserker...
            MoxieVariantType:= GetVariantTypeName(MoxieVariant) # if Bestial, Bug, Aquatic...
            case (StringToCreatureType(MoxieVariantType)):
                # Besial Tail
                creature_type.Bestial => 
                    case (MoxieVariant):
                        "Hunter" => array{Assets.Bestial.Hunter.Tail}
                        "Rampage" => array{Assets.Bestial.Rampage.Tail}
                        "Berserker" => array{Assets.Bestial.Berserker.Tail}
                        "Juggernaut" => array{Assets.Bestial.Juggernaut.Tail}
                        "Bloodfang" => array{Assets.Bestial.Bloodfang.Tail}
                        _ => array{Assets.Test.Test_Tail}
                # Bug Tail
                creature_type.Bug => 
                    case (MoxieVariant):
                        "Hiveborn" => array{Assets.Bug.Hiveborn.Tail}
                        "Swarmcaller" => array{Assets.Bug.Swarmcaller.Tail}
                        "Ladydae" => array{Assets.Bug.Ladydae.Tail}
                        "Nectarblade" => array{Assets.Bug.Nectarblade.Tail}
                        "Broodling" => array{Assets.Bug.Broodling.Tail}
                        _ => array{Assets.Test.Test_Tail}
                # Winged Tail
                creature_type.Winged => 
                    case (MoxieVariant):
                        "Fierywing" => array{Assets.Winged.Fierywing.Tail}
                        "Featherbound" => array{Assets.Winged.Featherbound.Tail}
                        "Zephyrwing" => array{Assets.Winged.Zephyrwing.Tail}
                        "Stormcrest" => array{Assets.Winged.Stormcrest.Tail}
                        "Cloudbreaker" => array{Assets.Winged.Cloudbreaker.Tail}
                        _ => array{Assets.Test.Test_Tail}
                # Reptilian Tail
                creature_type.Reptilian => 
                    case (MoxieVariant):
                        #"Frenzygaze" => array{Assets.Reptilian.Frenzygaze.Tail}
                        "Venomscale" => array{Assets.Reptilian.Venomscale.Tail}
                        "Dunestalker" => array{Assets.Reptilian.Dunestalker.Tail}
                        "Ignifang" => array{Assets.Reptilian.Ignifang.Tail}
                        "Stoneclad" => array{Assets.Reptilian.Stoneclad.Tail}
                        _ => array{Assets.Test.Test_Tail}
                # Aquatic Tail
                creature_type.Aquatic => 
                    case (MoxieVariant):
                        #"Tideborn" => array{Assets.Aquatic.Tideborn.Tail}
                        #"Coralguard" => array{Assets.Aquatic.Coralguard.Tail}
                        #"Abyssal" => array{Assets.Aquatic.Abyssal.Tail}
                        #"Wavebinder" => array{Assets.Aquatic.Wavebinder.Tail}
                        #"Deepcurrent" => array{Assets.Aquatic.Deepcurrent.Tail}
                        _ => array{Assets.Test.Test_Tail}
                # Herbal Tail
                creature_type.Herbal => 
                    case (MoxieVariant):
                        "Frutal" => array{Assets.Herbal.Frutal.Tail}
                        "Bloomweaver" => array{Assets.Herbal.Bloomweaver.Tail}
                        "Thornheart" => array{Assets.Herbal.Thornheart.Tail}
                        "Verdant" => array{Assets.Herbal.Verdant.Tail}
                        "Rootbound" => array{Assets.Herbal.Rootbound.Tail}
                        _ => array{Assets.Test.Test_Tail}
                # Aurora Tail
                creature_type.Aurora =>
                    case (MoxieVariant):
                            #"Prismguard" => array{Assets.Aurora.Prismguard.Tail}
                            #"Luminborn" => array{Assets.Aurora.Luminborn.Tail}
                            #"Fluxweaver" => array{Assets.Aurora.Fluxweaver.Tail}
                            #"Chromatic" => array{Assets.Aurora.Chromatic.Tail}
                            #"Radiantforge" => array{Assets.Aurora.Radiantforge.Tail}
                            _ => array{Assets.Test.Test_Tail}
                # Zenith Tail
                creature_type.Zenith => 
                    case (MoxieVariant):
                        #"Sunborne" => array{Assets.Zenith.Sunborne.Tail}
                        #"Dawnbreak" => array{Assets.Zenith.Dawnbreak.Tail}
                        #"Haloed" => array{Assets.Zenith.Haloed.Tail}
                        #"Ascendant" => array{Assets.Zenith.Ascendant.Tail}
                        #"Goldflare" => array{Assets.Zenith.Goldflare.Tail}
                        _ => array{Assets.Test.Test_Tail}
                # Gloam Tail
                creature_type.Gloam => 
                    case (MoxieVariant):
                        #"Voidborn" => array{Assets.Gloam.Voidborn.Tail}
                        #"Umbral" => array{Assets.Gloam.Umbral.Tail}
                        #"Nightveil" => array{Assets.Gloam.Nightveil.Tail}
                        #"Shadowborne" => array{Assets.Gloam.Shadowborne.Tail}
                        #"Eclipsed" => array{Assets.Gloam.Eclipsed.Tail}
                        _ => array{Assets.Test.Test_Tail}


        # Horn
        ronin_part.Horn => 
            MoxieVariant:= Moxie.Parts.Horn.Dominant # if Hunter, Rampage, Berserker...
            MoxieVariantType:= GetVariantTypeName(MoxieVariant) # if Bestial, Bug, Aquatic...
            case (StringToCreatureType(MoxieVariantType)):
                # Besial Horn
                creature_type.Bestial => 
                    case (MoxieVariant):
                        "Hunter" => array{Assets.Bestial.Hunter.Horn}
                        "Rampage" => array{Assets.Bestial.Rampage.Horn}
                        "Berserker" => array{Assets.Bestial.Berserker.Horn}
                        "Juggernaut" => array{Assets.Bestial.Juggernaut.Horn}
                        "Bloodfang" => array{Assets.Bestial.Bloodfang.Horn}
                        _ => array{Assets.Test.Test_Horn}
                # Bug Horn
                creature_type.Bug => 
                    case (MoxieVariant):
                        "Hiveborn" => array{Assets.Bug.Hiveborn.Horn}
                        "Swarmcaller" => array{Assets.Bug.Swarmcaller.Horn}
                        "Ladydae" => array{Assets.Bug.Ladydae.Horn}
                        "Nectarblade" => array{Assets.Bug.Nectarblade.Horn}
                        "Broodling" => array{Assets.Bug.Broodling.Horn}
                        _ => array{Assets.Test.Test_Horn}
                # Winged Horn
                creature_type.Winged => 
                    case (MoxieVariant):
                        "Fierywing" => array{Assets.Winged.Fierywing.Horn}
                        "Featherbound" => array{Assets.Winged.Featherbound.Horn}
                        "Zephyrwing" => array{Assets.Winged.Zephyrwing.Horn}
                        "Stormcrest" => array{Assets.Winged.Stormcrest.Horn}
                        "Cloudbreaker" => array{Assets.Winged.Cloudbreaker.Horn}
                        _ => array{Assets.Test.Test_Horn}
                # Reptilian Horn
                creature_type.Reptilian => 
                    case (MoxieVariant):
                        #"Frenzygaze" => array{Assets.Reptilian.Frenzygaze.Horn}
                        "Venomscale" => array{Assets.Reptilian.Venomscale.Horn}
                        "Dunestalker" => array{Assets.Reptilian.Dunestalker.Horn}
                        "Ignifang" => array{Assets.Reptilian.Ignifang.Horn}
                        "Stoneclad" => array{Assets.Reptilian.Stoneclad.Horn}
                        _ => array{Assets.Test.Test_Horn}
                # Aquatic Horn
                creature_type.Aquatic => 
                    case (MoxieVariant):
                        #"Tideborn" => array{Assets.Aquatic.Tideborn.Horn}
                        #"Coralguard" => array{Assets.Aquatic.Coralguard.Horn}
                        #"Abyssal" => array{Assets.Aquatic.Abyssal.Horn}
                        #"Wavebinder" => array{Assets.Aquatic.Wavebinder.Horn}
                        #"Deepcurrent" => array{Assets.Aquatic.Deepcurrent.Horn}
                        _ => array{Assets.Test.Test_Horn}
                # Herbal Horn
                creature_type.Herbal => 
                    case (MoxieVariant):
                        "Frutal" => array{Assets.Herbal.Frutal.Horn}
                        "Bloomweaver" => array{Assets.Herbal.Bloomweaver.Horn}
                        "Thornheart" => array{Assets.Herbal.Thornheart.Horn}
                        "Verdant" => array{Assets.Herbal.Verdant.Horn}
                        "Rootbound" => array{Assets.Herbal.Rootbound.Horn}
                        _ => array{Assets.Test.Test_Horn}
                # Aurora Horn
                creature_type.Aurora =>
                    case (MoxieVariant):
                            #"Prismguard" => array{Assets.Aurora.Prismguard.Horn}
                            #"Luminborn" => array{Assets.Aurora.Luminborn.Horn}
                            #"Fluxweaver" => array{Assets.Aurora.Fluxweaver.Horn}
                            #"Chromatic" => array{Assets.Aurora.Chromatic.Horn}
                            #"Radiantforge" => array{Assets.Aurora.Radiantforge.Horn}
                            _ => array{Assets.Test.Test_Horn}
                # Zenith Horn
                creature_type.Zenith => 
                    case (MoxieVariant):
                        #"Sunborne" => array{Assets.Zenith.Sunborne.Horn}
                        #"Dawnbreak" => array{Assets.Zenith.Dawnbreak.Horn}
                        #"Haloed" => array{Assets.Zenith.Haloed.Horn}
                        #"Ascendant" => array{Assets.Zenith.Ascendant.Horn}
                        #"Goldflare" => array{Assets.Zenith.Goldflare.Horn}
                        _ => array{Assets.Test.Test_Horn}
                # Gloam Horn
                creature_type.Gloam => 
                    case (MoxieVariant):
                        #"Voidborn" => array{Assets.Gloam.Voidborn.Horn}
                        #"Umbral" => array{Assets.Gloam.Umbral.Horn}
                        #"Nightveil" => array{Assets.Gloam.Nightveil.Horn}
                        #"Shadowborne" => array{Assets.Gloam.Shadowborne.Horn}
                        #"Eclipsed" => array{Assets.Gloam.Eclipsed.Horn}
                        _ => array{Assets.Test.Test_Horn}


        # Back
        ronin_part.Back => 
            MoxieVariant:= Moxie.Parts.Back.Dominant # if Hunter, Rampage, Berserker...
            MoxieVariantType:= GetVariantTypeName(MoxieVariant) # if Bestial, Bug, Aquatic...
            case (StringToCreatureType(MoxieVariantType)):
                # Besial Back
                creature_type.Bestial => 
                    case (MoxieVariant):
                        "Hunter" => array{Assets.Bestial.Hunter.Back}
                        "Rampage" => array{Assets.Bestial.Rampage.Back}
                        "Berserker" => array{Assets.Bestial.Berserker.Back}
                        "Juggernaut" => array{Assets.Bestial.Juggernaut.Back}
                        "Bloodfang" => array{Assets.Bestial.Bloodfang.Back}
                        _ => array{Assets.Test.Test_Back}
                # Bug Back
                creature_type.Bug => 
                    case (MoxieVariant):
                        "Hiveborn" => array{Assets.Bug.Hiveborn.Back}
                        "Swarmcaller" => array{Assets.Bug.Swarmcaller.Back}
                        "Ladydae" => array{Assets.Bug.Ladydae.Back}
                        "Nectarblade" => array{Assets.Bug.Nectarblade.Back}
                        "Broodling" => array{Assets.Bug.Broodling.Back}
                        _ => array{Assets.Test.Test_Back}
                # Winged Back
                creature_type.Winged => 
                    case (MoxieVariant):
                        "Fierywing" => array{Assets.Winged.Fierywing.Back}
                        "Featherbound" => array{Assets.Winged.Featherbound.Back}
                        "Zephyrwing" => array{Assets.Winged.Zephyrwing.Back}
                        "Stormcrest" => array{Assets.Winged.Stormcrest.Back}
                        "Cloudbreaker" => array{Assets.Winged.Cloudbreaker.Back}
                        _ => array{Assets.Test.Test_Back}
                # Reptilian Back
                creature_type.Reptilian => 
                    case (MoxieVariant):
                        #"Frenzygaze" => array{Assets.Reptilian.Frenzygaze.Back}
                        "Venomscale" => array{Assets.Reptilian.Venomscale.Back}
                        "Dunestalker" => array{Assets.Reptilian.Dunestalker.Back}
                        "Ignifang" => array{Assets.Reptilian.Ignifang.Back}
                        "Stoneclad" => array{Assets.Reptilian.Stoneclad.Back}
                        _ => array{Assets.Test.Test_Back}
                # Aquatic Back
                creature_type.Aquatic => 
                    case (MoxieVariant):
                        #"Tideborn" => array{Assets.Aquatic.Tideborn.Back}
                        #"Coralguard" => array{Assets.Aquatic.Coralguard.Back}
                        #"Abyssal" => array{Assets.Aquatic.Abyssal.Back}
                        #"Wavebinder" => array{Assets.Aquatic.Wavebinder.Back}
                        #"Deepcurrent" => array{Assets.Aquatic.Deepcurrent.Back}
                        _ => array{Assets.Test.Test_Back}
                # Herbal Back
                creature_type.Herbal => 
                    case (MoxieVariant):
                        "Frutal" => array{Assets.Herbal.Frutal.Back}
                        "Bloomweaver" => array{Assets.Herbal.Bloomweaver.Back}
                        "Thornheart" => array{Assets.Herbal.Thornheart.Back}
                        "Verdant" => array{Assets.Herbal.Verdant.Back}
                        "Rootbound" => array{Assets.Herbal.Rootbound.Back}
                        _ => array{Assets.Test.Test_Back}
                # Aurora Back
                creature_type.Aurora =>
                    case (MoxieVariant):
                            #"Prismguard" => array{Assets.Aurora.Prismguard.Back}
                            #"Luminborn" => array{Assets.Aurora.Luminborn.Back}
                            #"Fluxweaver" => array{Assets.Aurora.Fluxweaver.Back}
                            #"Chromatic" => array{Assets.Aurora.Chromatic.Back}
                            #"Radiantforge" => array{Assets.Aurora.Radiantforge.Back}
                            _ => array{Assets.Test.Test_Back}
                # Zenith Back
                creature_type.Zenith => 
                    case (MoxieVariant):
                        #"Sunborne" => array{Assets.Zenith.Sunborne.Back}
                        #"Dawnbreak" => array{Assets.Zenith.Dawnbreak.Back}
                        #"Haloed" => array{Assets.Zenith.Haloed.Back}
                        #"Ascendant" => array{Assets.Zenith.Ascendant.Back}
                        #"Goldflare" => array{Assets.Zenith.Goldflare.Back}
                        _ => array{Assets.Test.Test_Back}
                # Gloam Back
                creature_type.Gloam => 
                    case (MoxieVariant):
                        #"Voidborn" => array{Assets.Gloam.Voidborn.Back}
                        #"Umbral" => array{Assets.Gloam.Umbral.Back}
                        #"Nightveil" => array{Assets.Gloam.Nightveil.Back}
                        #"Shadowborne" => array{Assets.Gloam.Shadowborne.Back}
                        #"Eclipsed" => array{Assets.Gloam.Eclipsed.Back}
                        _ => array{Assets.Test.Test_Back}


        # Ears
        ronin_part.Ears => 
            MoxieVariant:= Moxie.Parts.Ears.Dominant # if Hunter, Rampage, Berserker...
            MoxieVariantType:= GetVariantTypeName(MoxieVariant) # if Bestial, Bug, Aquatic...
            case (StringToCreatureType(MoxieVariantType)):
                # Besial Ears
                creature_type.Bestial => 
                    case (MoxieVariant):
                        "Hunter" => array{Assets.Bestial.Hunter.Ear_Top, Assets.Bestial.Hunter.Ear_Bottom}
                        "Rampage" => array{Assets.Bestial.Rampage.Ear_Top, Assets.Bestial.Rampage.Ear_Bottom}
                        "Berserker" => array{Assets.Bestial.Berserker.Ear_Top, Assets.Bestial.Berserker.Ear_Bottom}
                        "Juggernaut" => array{Assets.Bestial.Juggernaut.Ear_Top, Assets.Bestial.Juggernaut.Ear_Bottom}
                        "Bloodfang" => array{Assets.Bestial.Bloodfang.Ear_Top, Assets.Bestial.Bloodfang.Ear_Bottom}
                        _ => array{Assets.Test.Test_Ear_Top, Assets.Test.Test_Ear_Bottom}
                # Bug Ears
                creature_type.Bug => 
                    case (MoxieVariant):
                        "Hiveborn" => array{Assets.Bug.Hiveborn.Ear_Top, Assets.Bug.Hiveborn.Ear_Bottom}
                        "Swarmcaller" => array{Assets.Bug.Swarmcaller.Ear_Top, Assets.Bug.Swarmcaller.Ear_Bottom}
                        "Ladydae" => array{Assets.Bug.Ladydae.Ear_Top, Assets.Bug.Ladydae.Ear_Bottom}
                        "Nectarblade" => array{Assets.Bug.Nectarblade.Ear_Top, Assets.Bug.Nectarblade.Ear_Bottom}
                        "Broodling" => array{Assets.Bug.Broodling.Ear_Top, Assets.Bug.Broodling.Ear_Bottom}
                        _ => array{Assets.Test.Test_Ear_Top, Assets.Test.Test_Ear_Bottom}
                # Winged Ears
                creature_type.Winged => 
                    case (MoxieVariant):
                        "Fierywing" => array{Assets.Winged.Fierywing.Ear_Top, Assets.Winged.Fierywing.Ear_Bottom}
                        "Featherbound" => array{Assets.Winged.Featherbound.Ear_Top, Assets.Winged.Featherbound.Ear_Bottom}
                        "Zephyrwing" => array{Assets.Winged.Zephyrwing.Ear_Top, Assets.Winged.Zephyrwing.Ear_Bottom}
                        "Stormcrest" => array{Assets.Winged.Stormcrest.Ear_Top, Assets.Winged.Stormcrest.Ear_Bottom}
                        "Cloudbreaker" => array{Assets.Winged.Cloudbreaker.Ear_Top, Assets.Winged.Cloudbreaker.Ear_Bottom}
                        _ => array{Assets.Test.Test_Ear_Top, Assets.Test.Test_Ear_Bottom}
                # Reptilian Ears
                creature_type.Reptilian => 
                    case (MoxieVariant):
                        #"Frenzygaze" => array{Assets.Reptilian.Frenzygaze.Ear_Top, Assets.Reptilian.Frenzygaze.Ear_Bottom}
                        "Venomscale" => array{Assets.Reptilian.Venomscale.Ear_Top, Assets.Reptilian.Venomscale.Ear_Bottom}
                        "Dunestalker" => array{Assets.Reptilian.Dunestalker.Ear_Top, Assets.Reptilian.Dunestalker.Ear_Bottom}
                        "Ignifang" => array{Assets.Reptilian.Ignifang.Ear_Top, Assets.Reptilian.Ignifang.Ear_Bottom}
                        "Stoneclad" => array{Assets.Reptilian.Stoneclad.Ear_Top, Assets.Reptilian.Stoneclad.Ear_Bottom}
                        _ => array{Assets.Test.Test_Ear_Top, Assets.Test.Test_Ear_Bottom}
                # Aquatic Ears
                creature_type.Aquatic => 
                    case (MoxieVariant):
                        #"Tideborn" => array{Assets.Aquatic.Tideborn.Ear_Top, Assets.Aquatic.Tideborn.Ear_Bottom}
                        #"Coralguard" => array{Assets.Aquatic.Coralguard.Ear_Top, Assets.Aquatic.Coralguard.Ear_Bottom}
                        #"Abyssal" => array{Assets.Aquatic.Abyssal.Ear_Top, Assets.Aquatic.Abyssal.Ear_Bottom}
                        #"Wavebinder" => array{Assets.Aquatic.Wavebinder.Ear_Top, Assets.Aquatic.Wavebinder.Ear_Bottom}
                        #"Deepcurrent" => array{Assets.Aquatic.Deepcurrent.Ear_Top, Assets.Aquatic.Deepcurrent.Ear_Bottom}
                        _ => array{Assets.Test.Test_Ear_Top, Assets.Test.Test_Ear_Bottom}
                # Herbal Ears
                creature_type.Herbal => 
                    case (MoxieVariant):
                        "Frutal" => array{Assets.Herbal.Frutal.Ear_Top, Assets.Herbal.Frutal.Ear_Bottom}
                        "Bloomweaver" => array{Assets.Herbal.Bloomweaver.Ear_Top, Assets.Herbal.Bloomweaver.Ear_Bottom}
                        "Thornheart" => array{Assets.Herbal.Thornheart.Ear_Top, Assets.Herbal.Thornheart.Ear_Bottom}
                        "Verdant" => array{Assets.Herbal.Verdant.Ear_Top, Assets.Herbal.Verdant.Ear_Bottom}
                        "Rootbound" => array{Assets.Herbal.Rootbound.Ear_Top, Assets.Herbal.Rootbound.Ear_Bottom}
                        _ => array{Assets.Test.Test_Ear_Top, Assets.Test.Test_Ear_Bottom}
                # Aurora Ears
                creature_type.Aurora =>
                    case (MoxieVariant):
                            #"Prismguard" => array{Assets.Aurora.Prismguard.Ear_Top, Assets.Aurora.Prismguard.Ear_Bottom}
                            #"Luminborn" => array{Assets.Aurora.Luminborn.Ear_Top, Assets.Aurora.Luminborn.Ear_Bottom}
                            #"Fluxweaver" => array{Assets.Aurora.Fluxweaver.Ear_Top, Assets.Aurora.Fluxweaver.Ear_Bottom}
                            #"Chromatic" => array{Assets.Aurora.Chromatic.Ear_Top, Assets.Aurora.Chromatic.Ear_Bottom}
                            #"Radiantforge" => array{Assets.Aurora.Radiantforge.Ear_Top, Assets.Aurora.Radiantforge.Ear_Bottom}
                            _ => array{Assets.Test.Test_Ear_Top, Assets.Test.Test_Ear_Bottom}
                # Zenith Ears
                creature_type.Zenith => 
                    case (MoxieVariant):
                        #"Sunborne" => array{Assets.Zenith.Sunborne.Ear_Top, Assets.Zenith.Sunborne.Ear_Bottom}
                        #"Dawnbreak" => array{Assets.Zenith.Dawnbreak.Ear_Top, Assets.Zenith.Dawnbreak.Ear_Bottom}
                        #"Haloed" => array{Assets.Zenith.Haloed.Ear_Top, Assets.Zenith.Haloed.Ear_Bottom}
                        #"Ascendant" => array{Assets.Zenith.Ascendant.Ear_Top, Assets.Zenith.Ascendant.Ear_Bottom}
                        #"Goldflare" => array{Assets.Zenith.Goldflare.Ear_Top, Assets.Zenith.Goldflare.Ear_Bottom}
                        _ => array{Assets.Test.Test_Ear_Top, Assets.Test.Test_Ear_Bottom}
                # Gloam Ears
                creature_type.Gloam => 
                    case (MoxieVariant):
                        #"Voidborn" => array{Assets.Gloam.Voidborn.Ear_Top, Assets.Gloam.Voidborn.Ear_Bottom}
                        #"Umbral" => array{Assets.Gloam.Umbral.Ear_Top, Assets.Gloam.Umbral.Ear_Bottom}
                        #"Nightveil" => array{Assets.Gloam.Nightveil.Ear_Top, Assets.Gloam.Nightveil.Ear_Bottom}
                        #"Shadowborne" => array{Assets.Gloam.Shadowborne.Ear_Top, Assets.Gloam.Shadowborne.Ear_Bottom}
                        #"Eclipsed" => array{Assets.Gloam.Eclipsed.Ear_Top, Assets.Gloam.Eclipsed.Ear_Bottom}
                        _ => array{Assets.Test.Test_Ear_Top, Assets.Test.Test_Ear_Bottom}
        

# Get the Moxie Body Part, including the Body, Body Marks and Body and Hands (Top and Bottom)
GetMoxieBodyPartTexture(Moxie:ronin_creature):[]texture = 
    MoxieType:= Moxie.Type
    #Print("Getting Moxie Texture for Body!")
    case (MoxieType):
        # Bestial Moxies
        creature_type.Bestial => array{Assets.Bestial.Body, Assets.Bestial.BodyMarks, Assets.Bestial.Hand_Top, Assets.Bestial.Hand_Bottom}

        # Bug Moxies
        creature_type.Bug => array{Assets.Bug.Body, Assets.Bug.BodyMarks, Assets.Bug.Hand_Top, Assets.Bug.Hand_Bottom}

        # Winged Moxies
        creature_type.Winged => array{Assets.Winged.Body, Assets.Winged.BodyMarks, Assets.Winged.Hand_Top, Assets.Winged.Hand_Bottom}#, Assets.Winged.BodyMarks, Assets.Winged.Hand_Top, Assets.Winged.Hand_Bottom}

        # Reptilian Moxies
        creature_type.Reptilian => array{Assets.Reptilian.Body, Assets.Reptilian.BodyMarks, Assets.Reptilian.Hand_Top, Assets.Reptilian.Hand_Bottom}#, Assets.Reptilian.BodyMarks, Assets.Reptilian.Hand_Top, Assets.Reptilian.Hand_Bottom}

        # Aquatic Moxies
        creature_type.Aquatic => array{Assets.Aquatic.Body, Assets.Test.Test_BodyMarks, Assets.Test.Test_Hand_Top, Assets.Test.Test_Hand_Bottom}#, Assets.Aquatic.BodyMarks, Assets.Aquatic.Hand_Top, Assets.Aquatic.Hand_Bottom}

        # Herbal Moxies
        creature_type.Herbal => array{Assets.Herbal.Body, Assets.Herbal.BodyMarks, Assets.Herbal.Hand_Top, Assets.Herbal.Hand_Bottom}#, Assets.Herbal.BodyMarks, Assets.Herbal.Hand_Top, Assets.Herbal.Hand_Bottom}

        # Aurora Moxies
        #creature_type.Aurora => array{Assets.Aurora.Body, Assets.Aurora.BodyMarks, Assets.Aurora.Hand_Top, Assets.Aurora.Hand_Bottom}

        # Zenith Moxies
        #creature_type.Zenith => array{Assets.Zenith.Body, Assets.Zenith.BodyMarks, Assets.Zenith.Hand_Top, Assets.Zenith.Hand_Bottom}

        # Gloam Moxies
        #creature_type.Gloam => array{Assets.Gloam.Body, Assets.Gloam.BodyMarks, Assets.Gloam.Hand_Top, Assets.Gloam.Hand_Bottom}

        _ => array{Assets.Test.Test_Body, Assets.Test.Test_BodyMarks, Assets.Test.Test_Hand_Top, Assets.Test.Test_Hand_Bottom}

CountSameTypeParts(C:ronin_creature):int =
    var Count:int = 0

    if (StringToCreatureType(GetVariantTypeName(C.Parts.Eyes.Dominant)) = C.Type): 
        set Count += 1
    if (StringToCreatureType(GetVariantTypeName(C.Parts.Mouth.Dominant)) = C.Type): 
        set Count += 1
    if (StringToCreatureType(GetVariantTypeName(C.Parts.Horn.Dominant)) = C.Type): 
        set Count += 1
    if (StringToCreatureType(GetVariantTypeName(C.Parts.Ears.Dominant)) = C.Type): 
        set Count += 1
    if (StringToCreatureType(GetVariantTypeName(C.Parts.Back.Dominant)) = C.Type): 
        set Count += 1
    if (StringToCreatureType(GetVariantTypeName(C.Parts.Tail.Dominant)) = C.Type): 
        set Count += 1

    return Count

GetSamePartsMultiplier(SamePartsQuantity:int):float =
    case(SamePartsQuantity):
        3 => return 1.2
        4 => return 1.4
        5 => return 1.6
        6 => return 1.8
        _ => return 1.0


SetMoxiePartsToUILeft(Moxie:ronin_creature, MoxieWidget: Widgets.Test.WBP_Moxie_Left):void =
    # Set Moxie Eyes
    EyesArray:= GetMoxiePartTexture(Moxie, ronin_part.Eyes)
    if(Eyes:= EyesArray[0]):
        set MoxieWidget.EyesTexture = Eyes
    # Set Moxie Mouth
    MouthArray:= GetMoxiePartTexture(Moxie, ronin_part.Mouth)
    if(Mouth:= MouthArray[0]):
        set MoxieWidget.MouthTexture = Mouth
    # Set Moxie Horn
    HornArray:= GetMoxiePartTexture(Moxie, ronin_part.Horn)
    if(Horn:= HornArray[0]):
        set MoxieWidget.HornTexture = Horn
    # Set Moxie Back
    BackArray:= GetMoxiePartTexture(Moxie, ronin_part.Back)
    if(Back:= BackArray[0]):
        set MoxieWidget.BackTexture = Back
    # Set Moxie Tail
    TailArray:= GetMoxiePartTexture(Moxie, ronin_part.Tail)
    if(Tail:= TailArray[0]):
        set MoxieWidget.TailTexture = Tail
    # Set Moxie Ears (Top and Bottom)
    EarsArray:= GetMoxiePartTexture(Moxie, ronin_part.Ears)
    if(Ear_Top:= EarsArray[0], Ear_Bottom:= EarsArray[1]):
        set MoxieWidget.Ear_TopTexture = Ear_Top
        set MoxieWidget.Ear_BottomTexture = Ear_Bottom

    # Set Moxie Body (Body, Body Marks and Body and Hands (Top and Bottom))
    BodyArray:= GetMoxieBodyPartTexture(Moxie)
    if(Body:= BodyArray[0], BodyMarks:= BodyArray[1], Hand_Top:= BodyArray[2], Hand_Bottom:= BodyArray[3]):
        set MoxieWidget.BodyTexture = Body
        set MoxieWidget.BodyMarksTexture = BodyMarks
        set MoxieWidget.Hand_TopTexture = Hand_Top
        set MoxieWidget.Hand_BottomTexture = Hand_Bottom

SetMoxiePartsToUIRight(Moxie:ronin_creature,  MoxieWidget: Widgets.Test.WBP_Moxie_Right):void =
    # Set Moxie Eyes
    EyesArray:= GetMoxiePartTexture(Moxie, ronin_part.Eyes)
    if(Eyes:= EyesArray[0]):
        set MoxieWidget.EyesTexture = Eyes
    # Set Moxie Mouth
    MouthArray:= GetMoxiePartTexture(Moxie, ronin_part.Mouth)
    if(Mouth:= MouthArray[0]):
        set MoxieWidget.MouthTexture = Mouth
    # Set Moxie Horn
    HornArray:= GetMoxiePartTexture(Moxie, ronin_part.Horn)
    if(Horn:= HornArray[0]):
        set MoxieWidget.HornTexture = Horn
    # Set Moxie Back
    BackArray:= GetMoxiePartTexture(Moxie, ronin_part.Back)
    if(Back:= BackArray[0]):
        set MoxieWidget.BackTexture = Back
    # Set Moxie Tail
    TailArray:= GetMoxiePartTexture(Moxie, ronin_part.Tail)
    if(Tail:= TailArray[0]):
        set MoxieWidget.TailTexture = Tail
    # Set Moxie Ears (Top and Bottom)
    EarsArray:= GetMoxiePartTexture(Moxie, ronin_part.Ears)
    if(Ear_Top:= EarsArray[0], Ear_Bottom:= EarsArray[1]):
        set MoxieWidget.Ear_TopTexture = Ear_Top
        set MoxieWidget.Ear_BottomTexture = Ear_Bottom

    # Set Moxie Body (Body, Body Marks and Body and Hands (Top and Bottom))
    BodyArray:= GetMoxieBodyPartTexture(Moxie)
    if(Body:= BodyArray[0], BodyMarks:= BodyArray[1], Hand_Top:= BodyArray[2], Hand_Bottom:= BodyArray[3]):
        set MoxieWidget.BodyTexture = Body
        set MoxieWidget.BodyMarksTexture = BodyMarks
        set MoxieWidget.Hand_TopTexture = Hand_Top
        set MoxieWidget.Hand_BottomTexture = Hand_Bottom

SetMoxiePartsToTeamUI(Moxie:ronin_creature, MoxieWidget: Widgets.Test.WBP_Moxie_Team_Item):void =
    # Set Moxie Eyes
    EyesArray:= GetMoxiePartTexture(Moxie, ronin_part.Eyes)
    if(Eyes:= EyesArray[0]):
        set MoxieWidget.EyesTexture = Eyes
    # Set Moxie Mouth
    MouthArray:= GetMoxiePartTexture(Moxie, ronin_part.Mouth)
    if(Mouth:= MouthArray[0]):
        set MoxieWidget.MouthTexture = Mouth
    # Set Moxie Horn
    HornArray:= GetMoxiePartTexture(Moxie, ronin_part.Horn)
    if(Horn:= HornArray[0]):
        set MoxieWidget.HornTexture = Horn
    # Set Moxie Back
    BackArray:= GetMoxiePartTexture(Moxie, ronin_part.Back)
    if(Back:= BackArray[0]):
        set MoxieWidget.BackTexture = Back
    # Set Moxie Tail
    TailArray:= GetMoxiePartTexture(Moxie, ronin_part.Tail)
    if(Tail:= TailArray[0]):
        set MoxieWidget.TailTexture = Tail
    # Set Moxie Ears (Top and Bottom)
    EarsArray:= GetMoxiePartTexture(Moxie, ronin_part.Ears)
    if(Ear_Top:= EarsArray[0], Ear_Bottom:= EarsArray[1]):
        set MoxieWidget.Ear_TopTexture = Ear_Top
        set MoxieWidget.Ear_BottomTexture = Ear_Bottom

    # Set Moxie Body (Body, Body Marks and Body and Hands (Top and Bottom))
    BodyArray:= GetMoxieBodyPartTexture(Moxie)
    if(Body:= BodyArray[0], BodyMarks:= BodyArray[1], Hand_Top:= BodyArray[2], Hand_Bottom:= BodyArray[3]):
        set MoxieWidget.BodyTexture = Body
        set MoxieWidget.BodyMarksTexture = BodyMarks
        set MoxieWidget.Hand_TopTexture = Hand_Top
        set MoxieWidget.Hand_BottomTexture = Hand_Bottom

SetMoxiePartsToTeamSmallUI(Moxie:ronin_creature, MoxieWidget: Widgets.Test.WBP_Moxie_Team_Item_Small):void =
    # Set Moxie Eyes
    EyesArray:= GetMoxiePartTexture(Moxie, ronin_part.Eyes)
    if(Eyes:= EyesArray[0]):
        set MoxieWidget.EyesTexture = Eyes
    # Set Moxie Mouth
    MouthArray:= GetMoxiePartTexture(Moxie, ronin_part.Mouth)
    if(Mouth:= MouthArray[0]):
        set MoxieWidget.MouthTexture = Mouth
    # Set Moxie Horn
    HornArray:= GetMoxiePartTexture(Moxie, ronin_part.Horn)
    if(Horn:= HornArray[0]):
        set MoxieWidget.HornTexture = Horn
    # Set Moxie Back
    BackArray:= GetMoxiePartTexture(Moxie, ronin_part.Back)
    if(Back:= BackArray[0]):
        set MoxieWidget.BackTexture = Back
    # Set Moxie Tail
    TailArray:= GetMoxiePartTexture(Moxie, ronin_part.Tail)
    if(Tail:= TailArray[0]):
        set MoxieWidget.TailTexture = Tail
    # Set Moxie Ears (Top and Bottom)
    EarsArray:= GetMoxiePartTexture(Moxie, ronin_part.Ears)
    if(Ear_Top:= EarsArray[0], Ear_Bottom:= EarsArray[1]):
        set MoxieWidget.Ear_TopTexture = Ear_Top
        set MoxieWidget.Ear_BottomTexture = Ear_Bottom

    # Set Moxie Body (Body, Body Marks and Body and Hands (Top and Bottom))
    BodyArray:= GetMoxieBodyPartTexture(Moxie)
    if(Body:= BodyArray[0], BodyMarks:= BodyArray[1], Hand_Top:= BodyArray[2], Hand_Bottom:= BodyArray[3]):
        set MoxieWidget.BodyTexture = Body
        set MoxieWidget.BodyMarksTexture = BodyMarks
        set MoxieWidget.Hand_TopTexture = Hand_Top
        set MoxieWidget.Hand_BottomTexture = Hand_Bottom

# Loop the animation forever
LooapIdleAnimationUILeft(Player:player, MoxieWidget: Widgets.Test.WBP_Moxie_Left)<suspends>:void =
    Print("Moxie - Anim Loop Started")
    var TimeToWait: float = 0.0
    var IsIdleNext:logic = true
    loop:
        if (IsIdleNext?):
            Print("Moxie - Idle anim selected")
            set TimeToWait = 12.0
            set MoxieWidget.PlayIdleAnim = 1.0  
            set MoxieWidget.PlayScratchAnim = 0.0 
        else:
            Print("Moxie - Scratch anim selected")
            set TimeToWait = 2.0
            set MoxieWidget.PlayScratchAnim = 1.0 
            set MoxieWidget.PlayIdleAnim = 0.0 

        if (IsIdleNext?):
            set IsIdleNext = false
            Print("Moxie - IsIdleNext is true turning to false")
        else:
            set IsIdleNext = true
            Print("Moxie - IsIdleNext is false turning to true")

        Sleep(TimeToWait)
        Print("Moxie - Anim Loop End, setting a new one")
        #SpawnLoopAnimation(Player, MoxieWidget)
        break

# Loop the animation forever
LosopIdleAnimationUIRight(Player:player, MoxieWidget: Widgets.Test.WBP_Moxie_Right)<suspends>:void =
    Print("Moxie - Anim Loop Started")
    var TimeToWait: float = 0.0
    loop:
        Rand:= GetRandomFloat(0.0, 1.0)
        Print("Moxie - Anim Rand Num: {Rand}")
        if(Rand <= 0.6): #0.1
            Print("Moxie - Scratch anim selected")
            set TimeToWait = 2.0
            set MoxieWidget.PlayScratchAnim = 1.0 
            set MoxieWidget.PlayIdleAnim = 0.0 
        else:
            Print("Moxie - Idle anim selected")
            set TimeToWait = 3.0
            set MoxieWidget.PlayIdleAnim = 1.0  
            set MoxieWidget.PlayScratchAnim = 0.0 
        Sleep(TimeToWait)
        Print("Moxie - Anim Loop End, setting a new one")
        # SpawnLoopAnimation(Player, MoxieWidget)
        # break

