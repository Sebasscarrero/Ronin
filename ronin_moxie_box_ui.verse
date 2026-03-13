
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/UI }
using { /Verse.org/Colors }
using { /Verse.org/Random }

player_box_ui_info := class:

    PlayerMoxieDisplay: Widgets.Test.WBP_Moxie_Left

    MoxieName: text_block
    MoxieType: text_block
    MoxieId: text_block
    MoxieNature: text_block
    MoxieStats: text_block
    MoxieAttackInfo: text_block

    MoxieTeamWidget_0: Widgets.Test.WBP_Moxie_Team_Item_Small
    MoxieTeamWidget_1: Widgets.Test.WBP_Moxie_Team_Item_Small
    MoxieTeamWidget_2: Widgets.Test.WBP_Moxie_Team_Item_Small
    MoxieTeamWidget_3: Widgets.Test.WBP_Moxie_Team_Item_Small
    MoxieTeamWidget_4: Widgets.Test.WBP_Moxie_Team_Item_Small
    MoxieTeamWidget_5: Widgets.Test.WBP_Moxie_Team_Item_Small

    MoxieTeamButton_0: button_quiet
    MoxieTeamButton_1: button_quiet
    MoxieTeamButton_2: button_quiet
    MoxieTeamButton_3: button_quiet
    MoxieTeamButton_4: button_quiet
    MoxieTeamButton_5: button_quiet

    MoxieItemWidgetArray: []Widgets.Test.WBP_Moxie_Team_Item_Small
    SelectionButtonArray: []button_quiet

    Attack1Button: button_quiet
    Attack2Button: button_quiet
    Attack3Button: button_quiet
    Attack4Button: button_quiet

    var SelectedIndex: int = -1
    var AnimationLoopCancelledLeft: logic = false

    LeftPageButton: button_loud
    RightPageButton: button_loud

    BackButton: button_regular

    Canvas: canvas
# ____________________________________________________________________________________________________________________________________________________

ronin_moxie_box_ui := class(creative_device):

    @editable
    MoxieManager: ronin_creature_manager = ronin_creature_manager{}

    # UI object per player
    var PlayerBoxInfoMap : [player]player_box_ui_info = map{}

    @editable
    TestButton: button_device = button_device{} 

    # Moxie Widget and Buttons construction (30 elements per page)
    var MoxieItemWidgetArray: []Widgets.Test.WBP_Moxie_Team_Item_Small = array{}
    var SelectionButtonArray: []button_quiet = array{}
    var PageIndexSelected: int = 1
    var CardButtonSubscription : []?cancelable = array{}
    


    OnBegin<override>()<suspends>:void=
        # Test Button
        TestButton.InteractedWithEvent.Subscribe(TestFunct)

    TestFunct(Agent:agent):void = 
        if (Player := player[Agent]):
            CreateMoxieBoxCanvas(Player)

    CreateMoxieBoxCanvas(Player:player): void = 

        # LEFT SECTION
        PlayerMoxieDisplay: Widgets.Test.WBP_Moxie_Left = Widgets.Test.WBP_Moxie_Left{}

        var PlayerMoxie_HealthbarMat : UI.Materials.M_MoxieBaseBar = UI.Materials.M_MoxieBaseBar{}
        PlayerMoxie_HealthbarMaterialBlock:=material_block{DefaultImage:=PlayerMoxie_HealthbarMat}

        Attack1Button:=button_quiet{DefaultText:=CreateMessage("Attack 1")}
        Attack2Button:=button_quiet{DefaultText:=CreateMessage("Attack 2")}
        Attack3Button:=button_quiet{DefaultText:=CreateMessage("Attack 3")}
        Attack4Button:=button_quiet{DefaultText:=CreateMessage("Attack 4")}

        MoxieName:= text_block{DefaultText := CreateMessage("Moxie Name"), DefaultTextColor := NamedColors.White, DefaultShadowColor:= NamedColors.Black, DefaultShadowOpacity := 1.0, DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}}}
        MoxieType:= text_block{DefaultText := CreateMessage("Moxie Type"), DefaultTextColor := NamedColors.White, DefaultShadowColor:= NamedColors.Black, DefaultShadowOpacity := 1.0, DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}}}
        MoxieId:= text_block{DefaultText := CreateMessage("Id #9999999999"), DefaultTextColor := NamedColors.White, DefaultShadowColor:= NamedColors.Black, DefaultShadowOpacity := 1.0, DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}}}
        MoxieNature:= text_block{DefaultText := CreateMessage("Nature: Timid (+Spd, -Atk)"), DefaultTextColor := NamedColors.White, DefaultShadowColor:= NamedColors.Black, DefaultShadowOpacity := 1.0, DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}}}
        MoxieStats:= text_block{DefaultText := CreateMessage("Lv. 10.0\nAtk. 20.0\nDef. 18.0\nSpd. 16.0"), DefaultTextColor := NamedColors.White, DefaultShadowColor:= NamedColors.Black, DefaultShadowOpacity := 1.0, DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}}}
        MoxieAttackInfo:= text_block{DefaultText := CreateMessage("Attack 1\nAttack Description\nAttack Description"), DefaultTextColor := NamedColors.White, DefaultJustification:= text_justification.Center, DefaultShadowColor:= NamedColors.Black, DefaultShadowOpacity := 1.0, DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}}}

        # RIGHT SECTION
        MoxieTeamWidget_0: Widgets.Test.WBP_Moxie_Team_Item_Small = Widgets.Test.WBP_Moxie_Team_Item_Small{}
        MoxieTeamWidget_1: Widgets.Test.WBP_Moxie_Team_Item_Small = Widgets.Test.WBP_Moxie_Team_Item_Small{} 
        MoxieTeamWidget_2: Widgets.Test.WBP_Moxie_Team_Item_Small = Widgets.Test.WBP_Moxie_Team_Item_Small{} 
        MoxieTeamWidget_3: Widgets.Test.WBP_Moxie_Team_Item_Small = Widgets.Test.WBP_Moxie_Team_Item_Small{} 
        MoxieTeamWidget_4: Widgets.Test.WBP_Moxie_Team_Item_Small = Widgets.Test.WBP_Moxie_Team_Item_Small{} 
        MoxieTeamWidget_5: Widgets.Test.WBP_Moxie_Team_Item_Small = Widgets.Test.WBP_Moxie_Team_Item_Small{}

        MoxieTeamButton_0:= button_quiet{DefaultText:=CreateMessage("!")}
        MoxieTeamButton_1:= button_quiet{DefaultText:=CreateMessage("!")}
        MoxieTeamButton_2:= button_quiet{DefaultText:=CreateMessage("!")}
        MoxieTeamButton_3:= button_quiet{DefaultText:=CreateMessage("!")}
        MoxieTeamButton_4:= button_quiet{DefaultText:=CreateMessage("!")}
        MoxieTeamButton_5:= button_quiet{DefaultText:=CreateMessage("!")}

        LeftPageButton:=button_loud{DefaultText:=CreateMessage(" < ")}
        RightPageButton:=button_loud{DefaultText:=CreateMessage(" > ")}

        BackButton:=button_regular{DefaultText:=CreateMessage(" Close ")}

        # Moxie Name, Id and Type widget to display in the Main Canvas
        MoxieNameIdTypeWidget:= overlay:
            Slots:=array:
                overlay_slot:
                    HorizontalAlignment:=horizontal_alignment.Left
                    VerticalAlignment:=vertical_alignment.Center
                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                    Widget:=stack_box:
                        Orientation:=orientation.Vertical
                        Slots:=array:
                            # Moxie Name
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Left
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:= MoxieName
                            # Moxie ID
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Left
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:= MoxieId
                            # Moxie Type
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Left
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:= MoxieType

        # Moxie Image and Stats widget to display in the Main Canvas
        MoxieImageStatsWidget:= overlay:
            Slots:=array:
                overlay_slot:
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Center
                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                    Widget:=stack_box:
                        Orientation:=orientation.Horizontal
                        Slots:=array:
                            # Moxie Image
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:= PlayerMoxieDisplay
                            # Moxie Stats
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Left
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:=stack_box:
                                    Orientation:=orientation.Vertical
                                    Slots:=array:
                                        # Moxie Nature
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Left
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{0.4} 
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                            Widget:= MoxieNature
                                        # Moxie Stats
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Left
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{0.4} 
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                            Widget:= MoxieStats
                                        # Moxie Healthbar
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Left
                                            VerticalAlignment:=vertical_alignment.Center
                                            #Distribution:=option{0.4} 
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                            Widget:= PlayerMoxie_HealthbarMaterialBlock

        # Moxie Attack Info widget to display in the Main Canvas
        MoxieAttacksInfoWidget:=overlay:
            Slots:=array:
                overlay_slot:
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Center
                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                    Widget:=stack_box:
                        Orientation:=orientation.Horizontal
                        Slots:=array:
                            # Moxie Image
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Fill
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:=stack_box:
                                    Orientation:=orientation.Horizontal
                                    Slots:=array:
                                        # Moxie Attacks Buttons Col 1
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Fill
                                            #Distribution:=option{0.4} 
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                            Widget:=stack_box:
                                                Orientation:=orientation.Vertical
                                                Slots:=array:
                                                    # Moxie Attack Buttons 1, Col 1
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Fill
                                                        #Distribution:=option{0.4} 
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= Attack1Button
                                                    # Moxie Attack Buttons 3, Col 1
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Fill
                                                        #Distribution:=option{0.4} 
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= Attack3Button
                                        # Moxie Attacks Buttons Col 2
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Fill
                                            #Distribution:=option{0.4} 
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                            Widget:=stack_box:
                                                Orientation:=orientation.Vertical
                                                Slots:=array:
                                                    # Moxie Attack Buttons 2, Col 2
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Fill
                                                        #Distribution:=option{0.4} 
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= Attack2Button
                                                    # Moxie Attack Buttons 4, Col 2
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Fill
                                                        #Distribution:=option{0.4} 
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= Attack4Button
                            # Moxie Attack Info
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:= MoxieAttackInfo

        # Moxie Body Parts Info widget to display in the Main Canvas
        MoxieBodyPartsInfoWidget:=overlay:
            Slots:=array:
                overlay_slot:
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Center
                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                    Widget:=stack_box:
                        Orientation:=orientation.Vertical
                        Slots:=array:
                            # Moxie Attack Info
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:= text_block{DefaultText := CreateMessage("--- Body Parts ---"), DefaultTextColor := NamedColors.White, DefaultShadowColor:= NamedColors.Black, DefaultShadowOpacity := 1.0, DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}}}                                   
                                                    
                            # Moxie Image
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Fill
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:=stack_box:
                                    Orientation:=orientation.Vertical
                                    Slots:=array:
                                        # Moxie Body Parts Row 1 (3 Parts)
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Fill
                                            #Distribution:=option{0.4} 
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                            Widget:=stack_box:
                                                Orientation:=orientation.Horizontal
                                                Slots:=array:
                                                    # Moxie Body Part 1
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Fill
                                                        #Distribution:=option{0.4} 
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= button_quiet{DefaultText:=CreateMessage("Body Part 1")}
                                                    # Moxie Body Part 2
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Fill
                                                        #Distribution:=option{0.4} 
                                                        Padding:= margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= button_quiet{DefaultText:=CreateMessage("Body Part 2")}
                                                    # Moxie Body Part 3
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Fill
                                                        #Distribution:=option{0.4} 
                                                        Padding:= margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= button_quiet{DefaultText:=CreateMessage("Body Part 3")}
                                        # Moxie Body Parts Row 2 (3 Parts)
                                        stack_box_slot:
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Fill
                                            #Distribution:=option{0.4} 
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                            Widget:=stack_box:
                                                Orientation:=orientation.Horizontal
                                                Slots:=array:
                                                    # Moxie Body Part 4
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Fill
                                                        #Distribution:=option{0.4} 
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= button_quiet{DefaultText:=CreateMessage("Body Part 4")}
                                                    # Moxie Body Part 5
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Fill
                                                        #Distribution:=option{0.4} 
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= button_quiet{DefaultText:=CreateMessage("Body Part 5")}
                                                    # Moxie Body Part 6
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Fill
                                                        #Distribution:=option{0.4} 
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:= button_quiet{DefaultText:=CreateMessage("Body Part 6")}

        PlayerTeamWidgets:= overlay:
            Slots:=array:
                overlay_slot:
                    HorizontalAlignment:=horizontal_alignment.Left
                    VerticalAlignment:=vertical_alignment.Center
                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                    Widget:=stack_box:
                        Orientation:=orientation.Horizontal
                        Slots:=array:
                            # Moxie Team Slot 0
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=-560.0}
                                Widget:= MoxieTeamWidget_0
                            # Moxie Team Slot 1
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=-560.0}
                                Widget:= MoxieTeamWidget_1
                            # Moxie Team Slot 2
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=-560.0}
                                Widget:= MoxieTeamWidget_2
                            # Moxie Team Slot 3
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=-560.0}
                                Widget:= MoxieTeamWidget_3
                            # Moxie Team Slot 4
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=-560.0}
                                Widget:= MoxieTeamWidget_4
                            # Moxie Team Slot 5
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=-560.0}
                                Widget:= MoxieTeamWidget_5

        # Begin - Item Grid Stack Box creation for refresh


        set SelectionButtonArray = array{}
        set MoxieItemWidgetArray = array{}

        for(Index:= 0..29):
            var newButton: button_quiet = button_quiet{}
            set SelectionButtonArray += array{newButton}

            var newWidget: Widgets.Test.WBP_Moxie_Team_Item_Small = Widgets.Test.WBP_Moxie_Team_Item_Small{}
            set MoxieItemWidgetArray += array{newWidget}
                            
        # Moxie Item Grid
        var ItemGridStackBox:stack_box=stack_box:
            Orientation:=orientation.Vertical 
              
        GridRow1:=stack_box:
            Orientation:=orientation.Horizontal

        GridRow2:=stack_box:
            Orientation:=orientation.Horizontal

        GridRow3:=stack_box:
            Orientation:=orientation.Horizontal

        GridRow4:=stack_box:
            Orientation:=orientation.Horizontal

        GridRow5:=stack_box:
            Orientation:=orientation.Horizontal

        # Item Grid Row 1/4 - Columns (0-5 Index)   
        for(Index:= 0..5):

            if:
                TargetMoxieWidget:= MoxieItemWidgetArray[Index]
                SelectionButton:= SelectionButtonArray[Index]
            then:
                Print("jcarrero - Valid information found for Row 1!")
                #set TargetCollectedCardMaterial.ColorSelectorSwitch = 1.0

                # Set the button with the right Button Index Selection
                ButtonIndex:= GetButtonSelectionIndexWithPage(Index,PageIndexSelected)
                Data := (Player, ButtonIndex)
                Subscription := SelectionButton.OnClick().SubscribeWidgetMessage(MoxieBoxButtonInteracted, Data)
                set CardButtonSubscription += array{option{Subscription}}
                
                MosaicWeaponOverlay:=stack_box_slot:
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Center
                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                    Widget:=overlay:
                        Slots:=array:                  
                            overlay_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                Padding:=margin{Top:=-100.0, Right:=0.0, Bottom:=0.0, Left:=-560.0}
                                Widget:= TargetMoxieWidget 
                            overlay_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                Padding:=margin{Top:=-100.0, Right:=0.0, Bottom:=0.0, Left:=-560.0}
                                Widget:= SelectionButton
                            
                GridRow1.AddWidget(MosaicWeaponOverlay) 
            else:
                Print("jcarrero - INVALID information found for Row 1!")

        # Item Grid Row 2/4 - Columns (6-11 Index)   
        for(Index:= 6..11):

            if:
                TargetMoxieWidget:= MoxieItemWidgetArray[Index]
                SelectionButton:= SelectionButtonArray[Index]
            then:
                Print("jcarrero - Valid information found for Row 1!")
                #set TargetCollectedCardMaterial.ColorSelectorSwitch = 1.0

                # Set the button with the right Button Index Selection
                ButtonIndex:= GetButtonSelectionIndexWithPage(Index,PageIndexSelected)
                Data := (Player, ButtonIndex)
                Subscription := SelectionButton.OnClick().SubscribeWidgetMessage(MoxieBoxButtonInteracted, Data)
                set CardButtonSubscription += array{option{Subscription}}
                
                MosaicWeaponOverlay:=stack_box_slot:
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Center
                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                    Widget:=overlay:
                        Slots:=array:                  
                            overlay_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                Padding:=margin{Top:=-340.0, Right:=0.0, Bottom:=0.0, Left:=-560.0}
                                Widget:= TargetMoxieWidget 
                            overlay_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                Padding:=margin{Top:=-340.0, Right:=0.0, Bottom:=0.0, Left:=-560.0}
                                Widget:= SelectionButton

                # Check if the Player have that Moxie index in their Persistent Data, and display the widgets if so           
                #UpdateMoxieBoxVisibilityInfo(Player, Index)            
                GridRow2.AddWidget(MosaicWeaponOverlay) 
            else:
                Print("jcarrero - INVALID information found for Row 2!")

        # Item Grid Row 3/4 - Columns (12-17 Index)   
        for(Index:= 12..17):

            if:
                TargetMoxieWidget:= MoxieItemWidgetArray[Index]
                SelectionButton:= SelectionButtonArray[Index]
            then:
                Print("jcarrero - Valid information found for Row 1!")
                #set TargetCollectedCardMaterial.ColorSelectorSwitch = 1.0

                # Set the button with the right Button Index Selection
                ButtonIndex:= GetButtonSelectionIndexWithPage(Index,PageIndexSelected)
                Data := (Player, ButtonIndex)
                Subscription := SelectionButton.OnClick().SubscribeWidgetMessage(MoxieBoxButtonInteracted, Data)
                set CardButtonSubscription += array{option{Subscription}}
                
                MosaicWeaponOverlay:=stack_box_slot:
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Center
                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                    Widget:=overlay:
                        Slots:=array:                  
                            overlay_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                Padding:=margin{Top:=-420.0, Right:=0.0, Bottom:=0.0, Left:=-560.0}
                                Widget:= TargetMoxieWidget 
                            overlay_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                Padding:=margin{Top:=-420.0, Right:=0.0, Bottom:=0.0, Left:=-560.0}
                                Widget:= SelectionButton

                # Check if the Player have that Moxie index in their Persistent Data, and display the widgets if so           
                #UpdateMoxieBoxVisibilityInfo(Player, Index)           
                GridRow3.AddWidget(MosaicWeaponOverlay) 
            else:
                Print("jcarrero - INVALID information found for Row 3!")

        # Item Grid Row 4/4 - Columns (18-23 Index)   
        for(Index:= 18..23):

            if:
                TargetMoxieWidget:= MoxieItemWidgetArray[Index]
                SelectionButton:= SelectionButtonArray[Index]
            then:
                Print("jcarrero - Valid information found for Row 1!")
                #set TargetCollectedCardMaterial.ColorSelectorSwitch = 1.0

                # Set the button with the right Button Index Selection
                ButtonIndex:= GetButtonSelectionIndexWithPage(Index,PageIndexSelected)
                Data := (Player, ButtonIndex)
                Subscription := SelectionButton.OnClick().SubscribeWidgetMessage(MoxieBoxButtonInteracted, Data)
                set CardButtonSubscription += array{option{Subscription}}
                
                MosaicWeaponOverlay:=stack_box_slot:
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Center
                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                    Widget:=overlay:
                        Slots:=array:                  
                            overlay_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                Padding:=margin{Top:=-450.0, Right:=0.0, Bottom:=0.0, Left:=-560.0}
                                Widget:= TargetMoxieWidget 
                            overlay_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                Padding:=margin{Top:=-450.0, Right:=0.0, Bottom:=0.0, Left:=-560.0}
                                Widget:= SelectionButton
                # Check if the Player have that Moxie index in their Persistent Data, and display the widgets if so           
                #UpdateMoxieBoxVisibilityInfo(Player, Index)
                GridRow4.AddWidget(MosaicWeaponOverlay) 
            else:
                Print("jcarrero - INVALID information found for Row 3!")

        ItemGridStackBox.AddWidget(
            stack_box_slot:
                VerticalAlignment:=vertical_alignment.Center
                HorizontalAlignment:=horizontal_alignment.Center
                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}                                          
                Widget:=GridRow1
            )
        ItemGridStackBox.AddWidget(
            stack_box_slot:
                VerticalAlignment:=vertical_alignment.Center
                HorizontalAlignment:=horizontal_alignment.Center
                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}                                          
                Widget:=GridRow2
            )
        ItemGridStackBox.AddWidget(
            stack_box_slot:
                VerticalAlignment:=vertical_alignment.Center
                HorizontalAlignment:=horizontal_alignment.Center
                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}                                          
                Widget:=GridRow3
            )
        ItemGridStackBox.AddWidget(
            stack_box_slot:
                VerticalAlignment:=vertical_alignment.Center
                HorizontalAlignment:=horizontal_alignment.Center
                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}                                          
                Widget:=GridRow4
            )

        # MAIN CANVAS
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
                                Widget:= texture_block{DefaultImage:=Assets.BattleBG, DefaultDesiredSize:=vector2{X:=1920.0, Y:=1080.0}} 

                            overlay_slot:
                                HorizontalAlignment:=horizontal_alignment.Fill
                                VerticalAlignment:=vertical_alignment.Fill
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:=stack_box:
                                    Orientation:=orientation.Horizontal
                                    Slots:=array:
                                        # LEFT SECTION
                                        stack_box_slot:
                                            VerticalAlignment:=vertical_alignment.Fill
                                            HorizontalAlignment:=horizontal_alignment.Left
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0} 
                                            Widget:=stack_box:
                                                Orientation:=orientation.Vertical
                                                Slots:=array:
                                                    # MOXIE INFO MAIN LABEL  
                                                    stack_box_slot:
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0} 
                                                        Widget:= overlay:
                                                            Slots:=array:                                                                                                              
                                                                overlay_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    VerticalAlignment:=vertical_alignment.Center
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= text_block{DefaultText := CreateMessage("Moxie"), DefaultTextColor := NamedColors.White, DefaultShadowColor:= NamedColors.Black, DefaultShadowOpacity := 1.0, DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}}}                                   
                                                    # MOXIE NAME, ID, TYPE  
                                                    stack_box_slot:
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        HorizontalAlignment:=horizontal_alignment.Left
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0} 
                                                        Widget:= overlay:
                                                            Slots:=array:                                                                                                              
                                                                overlay_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Left
                                                                    VerticalAlignment:=vertical_alignment.Center
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= MoxieNameIdTypeWidget
                                                    # MOXIE IMAGE DISPLAY AND STATS
                                                    stack_box_slot:
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0} 
                                                        Widget:= overlay:
                                                            Slots:=array:                                                                                                              
                                                                overlay_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    VerticalAlignment:=vertical_alignment.Center
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= MoxieImageStatsWidget
                                                    # MOXIE ATTACKS INFO
                                                    stack_box_slot:
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0} 
                                                        Widget:= overlay:
                                                            Slots:=array:                                                                                                              
                                                                overlay_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    VerticalAlignment:=vertical_alignment.Center
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= MoxieAttacksInfoWidget
                                                    # MOXIE BODY PARTS INFO
                                                    stack_box_slot:
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0} 
                                                        Widget:= overlay:
                                                            Slots:=array:                                                                                                              
                                                                overlay_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    VerticalAlignment:=vertical_alignment.Center
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= MoxieBodyPartsInfoWidget

                                        # RIGHT SECTION
                                        stack_box_slot:
                                            VerticalAlignment:=vertical_alignment.Fill
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0} 
                                            Widget:=stack_box:
                                                Orientation:=orientation.Vertical
                                                Slots:=array:
                                                    # MOXIE INFO MAIN LABEL  
                                                    stack_box_slot:
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0} 
                                                        Widget:= overlay:
                                                            Slots:=array:                                                                                                              
                                                                overlay_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    VerticalAlignment:=vertical_alignment.Center
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= text_block{DefaultText := CreateMessage("Team"), DefaultTextColor := NamedColors.White, DefaultShadowColor:= NamedColors.Black, DefaultShadowOpacity := 1.0, DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}}}                                   
                                                    # TEAM ROW 
                                                    stack_box_slot:
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        Padding:=margin{Top:=-65.0, Right:=0.0, Bottom:=0.0, Left:=405.0} 
                                                        Widget:= overlay:
                                                            Slots:=array:                                                                                                              
                                                                overlay_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Right
                                                                    VerticalAlignment:=vertical_alignment.Center
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= PlayerTeamWidgets
                                                    # MOXIE PLAYER INVENTORY 
                                                    stack_box_slot:
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        Padding:=margin{Top:=-180.0, Right:=140.0, Bottom:=0.0, Left:=0.0} 
                                                        Widget:= overlay:
                                                            Slots:=array:                                                                                                              
                                                                overlay_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    VerticalAlignment:=vertical_alignment.Center
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:=stack_box:
                                                                        Orientation:=orientation.Horizontal
                                                                        Slots:=array:
                                                                            stack_box_slot:
                                                                                VerticalAlignment:=vertical_alignment.Center
                                                                                HorizontalAlignment:=horizontal_alignment.Left
                                                                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0} 
                                                                                Widget:= LeftPageButton
                                                                            stack_box_slot:
                                                                                VerticalAlignment:=vertical_alignment.Center
                                                                                HorizontalAlignment:=horizontal_alignment.Center
                                                                                Padding:=margin{Top:=0.0, Right:=305.0, Bottom:=0.0, Left:=310.0} 
                                                                                Widget:= text_block{DefaultText := CreateMessage("BOX 1"), DefaultTextColor := NamedColors.White, DefaultShadowColor:= NamedColors.Black, DefaultShadowOpacity := 1.0, DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}}}                                   
                                                                            stack_box_slot:
                                                                                VerticalAlignment:=vertical_alignment.Center
                                                                                HorizontalAlignment:=horizontal_alignment.Right
                                                                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0} 
                                                                                Widget:= RightPageButton
                                                    # TEAM ROW 
                                                    stack_box_slot:
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        Padding:=margin{Top:=-60.0, Right:=0.0, Bottom:=0.0, Left:=405.0} 
                                                        Widget:= overlay:
                                                            Slots:=array:                                                                                                              
                                                                overlay_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Right
                                                                    VerticalAlignment:=vertical_alignment.Center
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= ItemGridStackBox

                            overlay_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Bottom
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:= BackButton

        UIPlayerBoxInfo := player_box_ui_info:
            PlayerMoxieDisplay := PlayerMoxieDisplay

            MoxieName := MoxieName
            MoxieType := MoxieType
            MoxieId := MoxieId
            MoxieNature := MoxieNature
            MoxieStats := MoxieStats
            MoxieAttackInfo := MoxieAttackInfo

            MoxieTeamWidget_0 := MoxieTeamWidget_0
            MoxieTeamWidget_1 := MoxieTeamWidget_1
            MoxieTeamWidget_2 := MoxieTeamWidget_2
            MoxieTeamWidget_3 := MoxieTeamWidget_3
            MoxieTeamWidget_4 := MoxieTeamWidget_4
            MoxieTeamWidget_5 := MoxieTeamWidget_5

            MoxieTeamButton_0 := MoxieTeamButton_0
            MoxieTeamButton_1 := MoxieTeamButton_1
            MoxieTeamButton_2 := MoxieTeamButton_2
            MoxieTeamButton_3 := MoxieTeamButton_3
            MoxieTeamButton_4 := MoxieTeamButton_4
            MoxieTeamButton_5 := MoxieTeamButton_5

            MoxieItemWidgetArray := MoxieItemWidgetArray
            SelectionButtonArray := SelectionButtonArray

            Attack1Button := Attack1Button
            Attack2Button := Attack2Button
            Attack3Button := Attack3Button
            Attack4Button := Attack4Button

            LeftPageButton := LeftPageButton
            RightPageButton := RightPageButton

            BackButton:= BackButton

            Canvas := Canvas       

        # Initial state
        set UIPlayerBoxInfo.SelectedIndex = -1
        set UIPlayerBoxInfo.AnimationLoopCancelledLeft = false

        # Store the Player Box Info to the Player, so each player has it's own information displayed
        if(set PlayerBoxInfoMap[Player] = UIPlayerBoxInfo): 
            if(PlayerUI:=GetPlayerUI[Player]):
                # Get the Player's Team Info
                if (PlayerBoxInfo := PlayerBoxInfoMap[Player]):
                    # Add the Player's Canva
                    PlayerUI.AddWidget(PlayerBoxInfo.Canvas, player_ui_slot{ZOrder:=12, InputMode:=ui_input_mode.All}) 

                    # Start Info in Moxie 0
                    UpdateTargetMoxieInfo(Player, 0)

                    PlayerBoxInfo.BackButton.OnClick().Subscribe(MoxieBoxCloseWidget)
                     
                    # Check if the Player have that Moxie index in their Persistent Data, and display the widgets if so
                    for (Idx := 0..PlayerBoxInfo.MoxieItemWidgetArray.Length - 1):
                        UpdateMoxieBoxVisibilityInfo(Player, Idx)

    # -------------------------------------------------------------------------------------------------------------------------------------

    MoxieBoxButtonInteracted(Message: widget_message, Data:tuple(player, int)): void = # Data is: Data(0) Player, Data(1) Moxie Index
        Print("jcarrero - Moxie Button{Data(1)} Pressed!")
        UpdateTargetMoxieInfo(Data(0), Data(1))
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetButtonSelectionIndexWithPage(ButtonIndex:int, PageIndex:int):int =
        PerPage := 24
        Multiplier := (PageIndex - 1) * PerPage
        return ButtonIndex + Multiplier #+ 1 # Add 1 to avoid zero-indexed
    # -------------------------------------------------------------------------------------------------------------------------------------

    UpdateTargetMoxieInfo(Player:player, MoxieIndex:int):void = 
        if (UITeamInfo := PlayerBoxInfoMap[Player]):
            MaybeTargetMoxie:= MoxieManager.GetPlayerMoxieTeamWithIndex(Player, MoxieIndex)
            if(TargetMoxie:= MaybeTargetMoxie?):

                # Set Selected Moxie Name on the Team Info
                UITeamInfo.MoxieName.SetText(CreateMessage("{CreatureTypeToString(TargetMoxie.Type)} Moxie"))
                # TODO - Set Selected Moxie Typem Icon on the Team Info
                UITeamInfo.MoxieType.SetText(CreateMessage("{CreatureTypeToString(TargetMoxie.Type)}"))
                # Set Selected Moxie Id on the Team Info
                UITeamInfo.MoxieId.SetText(CreateMessage("Id #{TargetMoxie.CollectibleId}"))
                # Set Selected Moxie Nature on the Team Info
                UITeamInfo.MoxieNature.SetText(CreateMessage("Nature {NatureToString(TargetMoxie.Nature)}"))
                # Set Selected Moxie Nature on the Team Info
                UITeamInfo.MoxieStats.SetText(CreateMessage("LV. {TargetMoxie.Level} | HP. {FormatFloatTo1DecimalString(TargetMoxie.Health)}\nATK. {FormatFloatTo1DecimalString(TargetMoxie.Attack)}\nDEF. {FormatFloatTo1DecimalString(TargetMoxie.Defense)}\nSPD. {FormatFloatTo1DecimalString(TargetMoxie.Speed)}"))
                # Set Selected Moxie Nature on the Team Info
                UITeamInfo.MoxieAttackInfo.SetText(CreateMessage("Select an\nattack!"))
                # Set Moxie parts to the main Moxie Image
                SetMoxiePartsToUILeft(TargetMoxie, UITeamInfo.PlayerMoxieDisplay)
                # Spawn the animations of the main Moxie Image
                spawn { LoopIdleAnimationUILeft(Player, UITeamInfo.PlayerMoxieDisplay) }

    # -------------------------------------------------------------------------------------------------------------------------------------

    UpdateMoxieBoxVisibilityInfo(Player:player, MoxieIndex:int):void = 
        if (UITeamInfo := PlayerBoxInfoMap[Player]):
            MaybeTargetMoxie:= MoxieManager.GetPlayerMoxieTeamWithIndex(Player, MoxieIndex)
            if(TargetMoxie:= MaybeTargetMoxie?):
                Print("Box - Moxie Exists!")
                # Enable the Moxie Image Widget and Selection Button
                if:
                    TargetMoxieWidget:= UITeamInfo.MoxieItemWidgetArray[MoxieIndex]
                    SelectionButton:= UITeamInfo.SelectionButtonArray[MoxieIndex] 
                then:
                    SetMoxiePartsToTeamSmallUI(TargetMoxie, TargetMoxieWidget)
                    TargetMoxieWidget.SetVisibility(widget_visibility.Visible)
                    SelectionButton.SetVisibility(widget_visibility.Visible)
                    Print("Box - Setting to be visible and set parts!")
            else:
                Print("Box - Moxie Exists!")
                if:
                    TargetMoxieWidget:= UITeamInfo.MoxieItemWidgetArray[MoxieIndex]
                    SelectionButton:= SelectionButtonArray[MoxieIndex] 
                then:
                    TargetMoxieWidget.SetVisibility(widget_visibility.Hidden)
                    SelectionButton.SetVisibility(widget_visibility.Hidden)
    # -------------------------------------------------------------------------------------------------------------------------------------

    var Left_IsIdleNext:logic = true
    # Loop the animation forever
    LoopIdleAnimationUILeft(Player:player, MoxieWidget: Widgets.Test.WBP_Moxie_Left)<suspends>:void =
        #Print("Moxie - Anim Loop Started")
        var TimeToWait: float = 0.0
        loop:
            if (UITeamInfo := PlayerBoxInfoMap[Player], UITeamInfo.AnimationLoopCancelledLeft = true):
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

    # Cancel all button subscriptions stored in the array
    CancelAllCardButtonSubscription(): void =
        for (Subscription : CardButtonSubscription):
            if (ValidSub := Subscription?):
                ValidSub.Cancel()
        set CardButtonSubscription = array{}
    # -------------------------------------------------------------------------------------------------------------------------------------

    MoxieBoxCloseWidget(Message: widget_message): void =
        Print("jcarrero - Close Button")
        RemoveMoxieBoxWidgetWidget(Message.Player)
    # -------------------------------------------------------------------------------------------------------------------------------------

    RemoveMoxieBoxWidgetWidget(Player:player): void = 
        if (PlayerUI:=GetPlayerUI[Player], UITeamInfo := PlayerBoxInfoMap[Player]):
            set UITeamInfo.AnimationLoopCancelledLeft = true
            PlayerUI.RemoveWidget(UITeamInfo.Canvas)
