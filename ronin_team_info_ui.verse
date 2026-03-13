
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }
using { /Verse.org/Random }

team_ui_info := class:

    PlayerMoxieDisplay: Widgets.Test.WBP_Moxie_Left

    MoxieName: text_block
    MoxieType: text_block
    MoxieId: text_block
    MoxieNature: text_block
    MoxieStats: text_block
    MoxieAttackInfo: text_block

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

    Attack1Button: button_regular
    Attack2Button: button_regular
    Attack3Button: button_regular
    Attack4Button: button_regular

    var SelectedIndex: int = -1
    var AnimationLoopCancelledLeft: logic = false

    CloseButton: button_regular
    SwapButton: button_loud

    Canvas: canvas


ronin_team_info_ui := class(creative_device):

    # UI object per player
    var PlayerTeamInfoMap : [player]team_ui_info = map{}

    @editable
    MoxieManager: ronin_creature_manager = ronin_creature_manager{}

    # Highest attack index the player may use right now (0..3)
    var MaxUnlockedAttackIdxByPlayer : [player]int = map{}

    @editable
    TestButton: button_device = button_device{} 

    OnBegin<override>()<suspends>:void=
        # Test Button
        TestButton.InteractedWithEvent.Subscribe(TestFunct)

    TestFunct(Agent:agent):void = 
        if (Player := player[Agent]):
            CreateTeamInfoCanvas(Player)
    # -------------------------------------------------------------------------------------------------------------------------------------

    CreateTeamInfoCanvas(Player:player): void = 

        PlayerMoxieDisplay: Widgets.Test.WBP_Moxie_Left = Widgets.Test.WBP_Moxie_Left{}

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

        var PlayerMoxie_HealthbarMat : UI.Materials.M_MoxieBaseBar = UI.Materials.M_MoxieBaseBar{}
        PlayerMoxie_HealthbarMaterialBlock:=material_block{DefaultImage:=PlayerMoxie_HealthbarMat}

        Attack1Button:=button_regular{DefaultText:=CreateMessage("Attack 1")}
        Attack2Button:=button_regular{DefaultText:=CreateMessage("Attack 2")}
        Attack3Button:=button_regular{DefaultText:=CreateMessage("Attack 3")}
        Attack4Button:=button_regular{DefaultText:=CreateMessage("Attack 4")}

        MoxieName:= text_block{DefaultText := CreateMessage("Moxie Name"), DefaultTextColor := NamedColors.White, DefaultShadowColor:= NamedColors.Black, DefaultShadowOpacity := 1.0, DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}}}
        MoxieType:= text_block{DefaultText := CreateMessage("   |   Moxie Type"), DefaultTextColor := NamedColors.White, DefaultShadowColor:= NamedColors.Black, DefaultShadowOpacity := 1.0, DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}}}
        MoxieId:= text_block{DefaultText := CreateMessage("Id #9999999999"), DefaultTextColor := NamedColors.White, DefaultShadowColor:= NamedColors.Black, DefaultShadowOpacity := 1.0, DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}}}
        MoxieNature:= text_block{DefaultText := CreateMessage("Nature: Timid (+Spd, -Atk)"), DefaultTextColor := NamedColors.White, DefaultShadowColor:= NamedColors.Black, DefaultShadowOpacity := 1.0, DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}}}
        MoxieStats:= text_block{DefaultText := CreateMessage("Lv. 10.0 | Atk. 20.0 | Def. 18.0 | Spd. 16.0"), DefaultTextColor := NamedColors.White, DefaultShadowColor:= NamedColors.Black, DefaultShadowOpacity := 1.0, DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}}}
        MoxieAttackInfo:= text_block{DefaultText := CreateMessage("Attack 1\nAttack Description\nAttack Description"), DefaultTextColor := NamedColors.White, DefaultJustification:= text_justification.Center, DefaultShadowColor:= NamedColors.Black, DefaultShadowOpacity := 1.0, DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}}}

        CloseButton:=button_regular{DefaultText:=CreateMessage(" Close ")}
        SwapButton:=button_loud{DefaultText:=CreateMessage(" Swap ")}

        # PlayerTeamWidgets:= overlay:
        #     Slots:=array:
        #         overlay_slot:
        #             HorizontalAlignment:=horizontal_alignment.Center
        #             VerticalAlignment:=vertical_alignment.Center
        #             Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
        #             Widget:=stack_box:
        #                 Orientation:=orientation.Vertical
        #                 Slots:=array:
        #                     # FIRST ROW
        #                     stack_box_slot:
        #                         HorizontalAlignment:=horizontal_alignment.Center
        #                         VerticalAlignment:=vertical_alignment.Center
        #                         #Distribution:=option{0.4} 
        #                         Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
        #                         Widget:=stack_box:
        #                             Orientation:=orientation.Horizontal
        #                             Slots:=array:
        #                                 # Moxie Team Slot 0
        #                                 stack_box_slot:
        #                                     HorizontalAlignment:=horizontal_alignment.Center
        #                                     VerticalAlignment:=vertical_alignment.Center
        #                                     #Distribution:=option{0.4} 
        #                                     Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=-470.0}
        #                                     Widget:= overlay:
        #                                         Slots:=array:                                                  
        #                                             overlay_slot:
        #                                                 # Moxie 0 Display Widget
        #                                                 HorizontalAlignment:=horizontal_alignment.Center
        #                                                 VerticalAlignment:=vertical_alignment.Center
        #                                                 Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
        #                                                 Widget:= MoxieTeamWidget_0
        #                                 # Moxie Team Slot 1
        #                                 stack_box_slot:
        #                                     HorizontalAlignment:=horizontal_alignment.Center
        #                                     VerticalAlignment:=vertical_alignment.Center
        #                                     #Distribution:=option{0.4} 
        #                                     Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=-470.0}
        #                                     Widget:= overlay:
        #                                         Slots:=array:                                                  
        #                                             overlay_slot:
        #                                                 # Moxie 1 Display Widget
        #                                                 HorizontalAlignment:=horizontal_alignment.Center
        #                                                 VerticalAlignment:=vertical_alignment.Center
        #                                                 Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
        #                                                 Widget:= MoxieTeamWidget_1
        #                                 # Moxie Team Slot 2
        #                                 stack_box_slot:
        #                                     HorizontalAlignment:=horizontal_alignment.Center
        #                                     VerticalAlignment:=vertical_alignment.Center
        #                                     #Distribution:=option{0.4} 
        #                                     Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=-470.0}
        #                                     Widget:= overlay:
        #                                         Slots:=array:                                                  
        #                                             overlay_slot:
        #                                                 # Moxie 2 Display Widget
        #                                                 HorizontalAlignment:=horizontal_alignment.Center
        #                                                 VerticalAlignment:=vertical_alignment.Center
        #                                                 Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
        #                                                 Widget:= MoxieTeamWidget_2
        #                     # SECOND ROW
        #                     stack_box_slot:
        #                         HorizontalAlignment:=horizontal_alignment.Center
        #                         VerticalAlignment:=vertical_alignment.Center
        #                         #Distribution:=option{0.4} 
        #                         Padding:=margin{Top:=-280.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
        #                         Widget:=stack_box:
        #                             Orientation:=orientation.Horizontal
        #                             Slots:=array:
        #                                 # Moxie Team Slot 3
        #                                 stack_box_slot:
        #                                     HorizontalAlignment:=horizontal_alignment.Center
        #                                     VerticalAlignment:=vertical_alignment.Center
        #                                     #Distribution:=option{0.4} 
        #                                     Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=-470.0}
        #                                     Widget:= overlay:
        #                                         Slots:=array:                                                  
        #                                             overlay_slot:
        #                                                 # Moxie 3 Display Widget
        #                                                 HorizontalAlignment:=horizontal_alignment.Center
        #                                                 VerticalAlignment:=vertical_alignment.Center
        #                                                 Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
        #                                                 Widget:= MoxieTeamWidget_3
        #                                 # Moxie Team Slot 4
        #                                 stack_box_slot:
        #                                     HorizontalAlignment:=horizontal_alignment.Center
        #                                     VerticalAlignment:=vertical_alignment.Center
        #                                     #Distribution:=option{0.4} 
        #                                     Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=-470.0}
        #                                     Widget:= overlay:
        #                                         Slots:=array:                                                  
        #                                             overlay_slot:
        #                                                 # Moxie 4 Display Widget
        #                                                 HorizontalAlignment:=horizontal_alignment.Center
        #                                                 VerticalAlignment:=vertical_alignment.Center
        #                                                 Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
        #                                                 Widget:= MoxieTeamWidget_4
        #                                 # Moxie Team Slot 5
        #                                 stack_box_slot:
        #                                     HorizontalAlignment:=horizontal_alignment.Center
        #                                     VerticalAlignment:=vertical_alignment.Center
        #                                     #Distribution:=option{0.4} 
        #                                     Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=-470.0}
        #                                     Widget:= overlay:
        #                                         Slots:=array:                                                  
        #                                             overlay_slot:
        #                                                 # Moxie 5 Display Widget
        #                                                 HorizontalAlignment:=horizontal_alignment.Center
        #                                                 VerticalAlignment:=vertical_alignment.Center
        #                                                 Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
        #                                                 Widget:= MoxieTeamWidget_5

    
        PlayerTeamWidgets:= overlay:
            Slots:=array:
                overlay_slot:
                    HorizontalAlignment:=horizontal_alignment.Center
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
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=-500.0}
                                Widget:= MoxieTeamWidget_0
                            # Moxie Team Slot 1
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=-500.0}
                                Widget:= MoxieTeamWidget_1
                            # Moxie Team Slot 2
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=-500.0}
                                Widget:= MoxieTeamWidget_2
                            # Moxie Team Slot 3
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=-500.0}
                                Widget:= MoxieTeamWidget_3
                            # Moxie Team Slot 4
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=-500.0}
                                Widget:= MoxieTeamWidget_4
                            # Moxie Team Slot 5
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=-500.0}
                                Widget:= MoxieTeamWidget_5

        PlayerTeamButtons:= overlay:
            Slots:=array:
                overlay_slot:
                    HorizontalAlignment:=horizontal_alignment.Center
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
                                Padding:=margin{Top:=0.0, Right:=150.0, Bottom:=0.0, Left:=0.0}
                                Widget:= MoxieTeamButton_0
                            # Moxie Team Slot 1
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=150.0, Bottom:=0.0, Left:=0.0}
                                Widget:= MoxieTeamButton_1
                            # Moxie Team Slot 2
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=150.0, Bottom:=0.0, Left:=0.0}
                                Widget:= MoxieTeamButton_2
                            # Moxie Team Slot 3
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=150.0, Bottom:=0.0, Left:=0.0}
                                Widget:= MoxieTeamButton_3
                            # Moxie Team Slot 4
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=150.0, Bottom:=0.0, Left:=0.0}
                                Widget:= MoxieTeamButton_4
                            # Moxie Team Slot 5
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=150.0, Bottom:=0.0, Left:=0.0}
                                Widget:= MoxieTeamButton_5
                                   
        # TODO: Something like this must go the selection buttons

        PlayerMoxieDisplayWidget:= overlay:
            Slots:=array:
                overlay_slot:
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Center
                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                    Widget:=stack_box:
                        Orientation:=orientation.Horizontal
                        Slots:=array:
                            # Moxie Display
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:= overlay:
                                    Slots:=array:                                                  
                                        overlay_slot:
                                            # Moxie Display Widget
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                            Widget:= PlayerMoxieDisplay

        PlayerMoxieInfoWidget:= overlay:
            Slots:=array:
                overlay_slot:
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Center
                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                    Widget:=stack_box:
                        Orientation:=orientation.Horizontal
                        Slots:=array:
                            # Moxie Display
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:= overlay:
                                    Slots:=array:                                                  
                                        overlay_slot:
                                            # Moxie Display Widget
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                            Widget:= PlayerMoxieDisplay
                                            
                            # Moxie Info
                            stack_box_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                #Distribution:=option{0.4} 
                                Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:= overlay:
                                    Slots:=array:                                                  
                                        overlay_slot:
                                            # Background
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                            Widget:= text_block{DefaultText := CreateMessage(""), DefaultTextColor := NamedColors.White} # BACKGROUND
                                        overlay_slot:
                                            # Stats Info
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            VerticalAlignment:=vertical_alignment.Center
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                            Widget:=stack_box:
                                                Orientation:=orientation.Vertical
                                                Slots:=array:
                                                    # Moxie Name Info
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Left
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        #Distribution:=option{0.4} 
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:=stack_box:
                                                            Orientation:=orientation.Horizontal
                                                            Slots:=array:
                                                                # Moxie Name
                                                                stack_box_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    VerticalAlignment:=vertical_alignment.Center
                                                                    #Distribution:=option{0.4} 
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= MoxieName
                                                                # Moxie Type
                                                                stack_box_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    VerticalAlignment:=vertical_alignment.Center
                                                                    #Distribution:=option{0.4} 
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= MoxieType
                                                    # Moxie Id Info
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Left
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        #Distribution:=option{0.4} 
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:=stack_box:
                                                            Orientation:=orientation.Horizontal
                                                            Slots:=array:
                                                                # Moxie Id
                                                                stack_box_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    VerticalAlignment:=vertical_alignment.Center
                                                                    #Distribution:=option{0.4} 
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= MoxieId
                                                                # Some extra info?
                                                                stack_box_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    VerticalAlignment:=vertical_alignment.Center
                                                                    #Distribution:=option{0.4} 
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= text_block{DefaultText := CreateMessage(""), DefaultTextColor := NamedColors.White}
                                                    # Moxie Nature Info
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Left
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        #Distribution:=option{0.4} 
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:=stack_box:
                                                            Orientation:=orientation.Horizontal
                                                            Slots:=array:
                                                                # Moxie Nature
                                                                stack_box_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    VerticalAlignment:=vertical_alignment.Center
                                                                    #Distribution:=option{0.4} 
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= MoxieNature
                                                                # Some extra info?
                                                                stack_box_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    VerticalAlignment:=vertical_alignment.Center
                                                                    #Distribution:=option{0.4} 
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= text_block{DefaultText := CreateMessage(""), DefaultTextColor := NamedColors.White}
                                                    # Moxie Stats Info
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Left
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        #Distribution:=option{0.4} 
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:=stack_box:
                                                            Orientation:=orientation.Horizontal
                                                            Slots:=array:
                                                                # Moxie Stats
                                                                stack_box_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    VerticalAlignment:=vertical_alignment.Center
                                                                    #Distribution:=option{0.4} 
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= MoxieStats
                                                                # Some extra info?
                                                                stack_box_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    VerticalAlignment:=vertical_alignment.Center
                                                                    #Distribution:=option{0.4} 
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= text_block{DefaultText := CreateMessage(""), DefaultTextColor := NamedColors.White}
                                                    # Moxie Health Info
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        #Distribution:=option{0.4} 
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:=stack_box:
                                                            Orientation:=orientation.Horizontal
                                                            Slots:=array:
                                                                # Moxie Health bar
                                                                stack_box_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    VerticalAlignment:=vertical_alignment.Fill
                                                                    #Distribution:=option{0.4} 
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= PlayerMoxie_HealthbarMaterialBlock
                                                                # Some extra info?
                                                                stack_box_slot:
                                                                    HorizontalAlignment:=horizontal_alignment.Center
                                                                    VerticalAlignment:=vertical_alignment.Center
                                                                    #Distribution:=option{0.4} 
                                                                    Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                                    Widget:= text_block{DefaultText := CreateMessage(""), DefaultTextColor := NamedColors.White}
                                                    # Moxie Attacks Info
                                                    stack_box_slot:
                                                        HorizontalAlignment:=horizontal_alignment.Center
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        #Distribution:=option{0.4} 
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                                        Widget:=stack_box:
                                                            Orientation:=orientation.Horizontal
                                                            Slots:=array:
                                                                # Moxie Attacks Buttons
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
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                Padding:=margin{Top:=60.0, Right:=0.0, Bottom:=0.0, Left:=0.0}
                                Widget:=stack_box:
                                    Orientation:=orientation.Vertical
                                    Slots:=array:
                                        stack_box_slot:
                                            VerticalAlignment:=vertical_alignment.Top
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=-160.0, Left:=0.0} 
                                            Widget:= PlayerMoxieInfoWidget
                                        stack_box_slot:
                                            VerticalAlignment:=vertical_alignment.Bottom
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=470.0} 
                                            Widget:= PlayerTeamWidgets
                                        stack_box_slot:
                                            VerticalAlignment:=vertical_alignment.Center
                                            HorizontalAlignment:=horizontal_alignment.Center
                                            Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=250.0, Left:=0.0} 
                                            Widget:=stack_box:
                                                Orientation:=orientation.Horizontal
                                                Slots:=array:
                                                    stack_box_slot:
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        HorizontalAlignment:=horizontal_alignment.Left
                                                        Padding:=margin{Top:=0.0, Right:=20.0, Bottom:=0.0, Left:=0.0} 
                                                        Widget:= CloseButton
                                                    stack_box_slot:
                                                        VerticalAlignment:=vertical_alignment.Center
                                                        HorizontalAlignment:=horizontal_alignment.Right
                                                        Padding:=margin{Top:=0.0, Right:=0.0, Bottom:=0.0, Left:=20.0} 
                                                        Widget:= SwapButton

                            overlay_slot:
                                HorizontalAlignment:=horizontal_alignment.Center
                                VerticalAlignment:=vertical_alignment.Center
                                Padding:=margin{Top:=210.0, Right:=0.0, Bottom:=0.0, Left:=200.0}
                                Widget:= PlayerTeamButtons

        UITeamInfo := team_ui_info:
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

            Attack1Button := Attack1Button
            Attack2Button := Attack2Button
            Attack3Button := Attack3Button
            Attack4Button := Attack4Button

            CloseButton := CloseButton
            SwapButton := SwapButton

            Canvas := Canvas       

        # Initial state
        set UITeamInfo.SelectedIndex = -1
        set UITeamInfo.AnimationLoopCancelledLeft = false


        
        # Store the Team Info to the Player, so each player has it's own information displayed
        if(set PlayerTeamInfoMap[Player] = UITeamInfo): 
            if(PlayerUI:=GetPlayerUI[Player]):
                # Get the Player's Team Info
                if (PlayerBattleInfo := PlayerTeamInfoMap[Player]):
                    # Add the Player's Canva
                    PlayerUI.AddWidget(PlayerBattleInfo.Canvas, player_ui_slot{ZOrder:=12, InputMode:=ui_input_mode.All})

                    # Set the images to match 
                    InitTeamUICanvas(Player)

        spawn { ListenForTeamInfoUI(Player) }
    # -------------------------------------------------------------------------------------------------------------------------------------

    InitTeamUICanvas(Player:player):void =
        # Get the Player's Moxie Creature Team
        var PlayerMoxieTeam: []ronin_creature = array{}
        set PlayerMoxieTeam = MoxieManager.GetPlayerMoxieTeam(Player)
        # Get the Player's Moxie Team Widgets
        TeamWidgets := GetPlayerTeamWidgetArray(Player)
        # Get the Player's Moxie Team Buttons
        TeamButtons := GetPlayerTeamButtonsArray(Player)


        for (Idx -> TeamWidget : TeamWidgets):
            if(TeamButton:= TeamButtons[Idx]):
                if (Idx < PlayerMoxieTeam.Length):
                    if (C := PlayerMoxieTeam[Idx]):
                        # If your team-item widget uses the SAME function, this is perfect:
                        SetMoxiePartsToTeamUI(C, TeamWidget)
                        # Optional: make sure it’s visible
                        TeamWidget.SetVisibility(widget_visibility.Visible)
                        TeamButton.SetVisibility(widget_visibility.Visible)
                else:
                    # Hide unused slots so empty widgets don’t show garbage
                    TeamWidget.SetVisibility(widget_visibility.Hidden)
                    TeamButton.SetVisibility(widget_visibility.Hidden)

        # Set the first Moxie to be displayed
        UpdateTargetMoxieInfo(Player, 0)

    # -------------------------------------------------------------------------------------------------------------------------------------

    ListenForTeamInfoUI(Player:player)<suspends>:void =
        if (UITeamInfo := PlayerTeamInfoMap[Player]):
            race:
                # # Close Player's Team UI
                # loop:
                #     UITeamInfo.CloseButton.OnClick().Await()
                #     RemoveEndBattleWidget(Player)
                #     # Close

                # # Selects and swap a valid Moxie
                # loop:
                #     UITeamInfo.SwapButton.OnClick().Await()
                #     # Swap

                # # RUN => end battle
                # loop:
                #     UITeamInfo.SwapButton.OnClick().Await()
                #     # Close

                # Select Player Moxie Index 0
                loop:
                    UITeamInfo.MoxieTeamButton_0.OnClick().Await()
                    UpdateTargetMoxieInfo(Player, 0)
                    Print("Old Idx: {UITeamInfo.SelectedIndex}")
                    SetSelectedIndex(Player, 0)
                    Print("New Idx: {UITeamInfo.SelectedIndex}")

                # Select Player Moxie Index 1
                loop:
                    UITeamInfo.MoxieTeamButton_1.OnClick().Await()
                    UpdateTargetMoxieInfo(Player, 1)
                    Print("Old Idx: {UITeamInfo.SelectedIndex}")
                    SetSelectedIndex(Player, 1)
                    Print("New Idx: {UITeamInfo.SelectedIndex}")

                # Select Player Moxie Index 2
                loop:
                    UITeamInfo.MoxieTeamButton_2.OnClick().Await()
                    UpdateTargetMoxieInfo(Player, 2)
                    Print("Old Idx: {UITeamInfo.SelectedIndex}")
                    SetSelectedIndex(Player, 2)
                    Print("New Idx: {UITeamInfo.SelectedIndex}")

                # Select Player Moxie Index 3
                loop:
                    UITeamInfo.MoxieTeamButton_3.OnClick().Await()
                    UpdateTargetMoxieInfo(Player, 3)
                    Print("Old Idx: {UITeamInfo.SelectedIndex}")
                    SetSelectedIndex(Player, 3)
                    Print("New Idx: {UITeamInfo.SelectedIndex}")

                # Select Player Moxie Index 4
                loop:
                    UITeamInfo.MoxieTeamButton_4.OnClick().Await()
                    UpdateTargetMoxieInfo(Player, 4)
                    Print("Old Idx: {UITeamInfo.SelectedIndex}")
                    SetSelectedIndex(Player, 4)
                    Print("New Idx: {UITeamInfo.SelectedIndex}")

                # Select Player Moxie Index 5
                loop:
                    UITeamInfo.MoxieTeamButton_5.OnClick().Await()
                    UpdateTargetMoxieInfo(Player, 5)
                    Print("Old Idx: {UITeamInfo.SelectedIndex}")
                    SetSelectedIndex(Player, 5)
                    Print("New Idx: {UITeamInfo.SelectedIndex}")

                # Select Attack 1 Info 
                loop:
                    UITeamInfo.Attack1Button.OnClick().Await()
                    UpdateAttackDescriptionText(Player, 0)
                    Print("Attack 1 Selected")

                # Select Attack 2 Info 
                loop:
                    UITeamInfo.Attack2Button.OnClick().Await()
                    UpdateAttackDescriptionText(Player, 1)
                    Print("Attack 2 Selected")

                # Select Attack 3 Info 
                loop:
                    UITeamInfo.Attack3Button.OnClick().Await()
                    if (IsAttackUnlocked(Player, 2) = true):
                        UpdateAttackDescriptionText(Player, 2)
                        Print("Attack 3 Selected")
                    else:
                        UpdateAttackDescriptionText(Player, -2)

                # Select Attack 4 Info 
                loop:
                    UITeamInfo.Attack4Button.OnClick().Await()
                    if (IsAttackUnlocked(Player, 3) = true):
                        UpdateAttackDescriptionText(Player, 3)
                        Print("Attack 4 Selected")
                    else:
                        UpdateAttackDescriptionText(Player, -2)
    # -------------------------------------------------------------------------------------------------------------------------------------

    OpenTeamInfoAndAwaitSwap(Player:player)<suspends>:int =
        CreateTeamInfoCanvas(Player)
        SetSelectedIndex(Player, 0)
        UpdateAllPlayerMoxieTeamDisplay(Player)
    
        var Result:int = -1 
    
        race:
            block:
                if (UITeamInfo := PlayerTeamInfoMap[Player]):
                    UITeamInfo.CloseButton.OnClick().Await()
                RemoveEndBattleWidget(Player)
                set Result = -1
    
            block:
                if (UITeamInfo := PlayerTeamInfoMap[Player]):
                    UITeamInfo.SwapButton.OnClick().Await()
    
                Idx := GetSelectedIndex(Player)
                RemoveEndBattleWidget(Player)
    
                if (Idx >= 0 and Idx <= 5):
                    set Result = Idx
                else:
                    set Result = -1
    
        return Result
    # -------------------------------------------------------------------------------------------------------------------------------------

    SetSelectedIndex(Player:player, Idx:int):void =
        if (UITeamInfo := PlayerTeamInfoMap[Player]):
            Print("SetSelectedIndex => {UITeamInfo.SelectedIndex} -> {Idx}")
            set UITeamInfo.SelectedIndex = Idx

            if (UITeamInfoUpdated := PlayerTeamInfoMap[Player]):
                PlayerData:= MoxieManager.PlayerDataDevice.GetPlayerData(Player)
                if(MoxieDataFromPlayerTeam:= PlayerData.PlayerMoxieTeamArray[UITeamInfoUpdated.SelectedIndex]):
                    MoxieFromPlayerTeam:= MoxieManager.CreateCreatureFromData(MoxieDataFromPlayerTeam)
                    UpdateAttackButtonLocksFromActiveMoxie(Player, MoxieFromPlayerTeam)
                    UpdateAttackDescriptionText(Player, -1)
                    
    
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetSelectedIndex(Player:player):int =
        if (UITeamInfo := PlayerTeamInfoMap[Player]):
            Print("Index to swap: {UITeamInfo.SelectedIndex}")
            return UITeamInfo.SelectedIndex
        return -1
    # -------------------------------------------------------------------------------------------------------------------------------------

    UpdateAttackDescriptionText(Player:player, AtkIdx:int): void =
        if (UITeamInfo := PlayerTeamInfoMap[Player]):
            if(AtkIdx = -1):
                UITeamInfo.MoxieAttackInfo.SetText(CreateMessage("    Select an    \nattack!"))
            else if(AtkIdx = -2):
                UITeamInfo.MoxieAttackInfo.SetText(CreateMessage("           Locked!"))
            else:
                    PlayerData:= MoxieManager.PlayerDataDevice.GetPlayerData(Player)
                        if(MoxieDataFromPlayerTeam:= PlayerData.PlayerMoxieTeamArray[UITeamInfo.SelectedIndex]):
                            MoxieFromPlayerTeam:= MoxieManager.CreateCreatureFromData(MoxieDataFromPlayerTeam)
                            if (Atk := MoxieFromPlayerTeam.Attacks[AtkIdx]):
                                    UITeamInfo.MoxieAttackInfo.SetText(CreateMessage(Atk.Description))
    # -------------------------------------------------------------------------------------------------------------------------------------

    SetAttackButtonsFromCreature(UITeamInfo:team_ui_info, C:ronin_creature):void =
        # Defaults
        UITeamInfo.Attack1Button.SetText(CreateMessage("—"))
        UITeamInfo.Attack2Button.SetText(CreateMessage("—"))
        UITeamInfo.Attack3Button.SetText(CreateMessage("—"))
        UITeamInfo.Attack4Button.SetText(CreateMessage("—"))

        # If attacks exist, set them one by one safely
        if (C.Attacks.Length > 0):
            if (A0 := C.Attacks[0]):
                UITeamInfo.Attack1Button.SetText(CreateMessage(A0.Name))
                #set UITeamInfo.Attack1_MoxieColorMat.ColorSelectorSwitch = CreatureTypeToColorIndex(A0.Type)

        if (C.Attacks.Length > 1):
            if (A1 := C.Attacks[1]):
                UITeamInfo.Attack2Button.SetText(CreateMessage(A1.Name))
                #set UITeamInfo.Attack2_MoxieColorMat.ColorSelectorSwitch = CreatureTypeToColorIndex(A1.Type)

        if (C.Attacks.Length > 2):
            if (A2 := C.Attacks[2]):
                UITeamInfo.Attack3Button.SetText(CreateMessage(A2.Name))
                #set UITeamInfo.Attack3_MoxieColorMat.ColorSelectorSwitch = CreatureTypeToColorIndex(A2.Type)

        if (C.Attacks.Length > 3):
            if (A3 := C.Attacks[3]):
                UITeamInfo.Attack4Button.SetText(CreateMessage(A3.Name))
                #set UITeamInfo.Attack4_MoxieColorMat.ColorSelectorSwitch = CreatureTypeToColorIndex(A3.Type)
    # -------------------------------------------------------------------------------------------------------------------------------------

    UpdateAttackButtonLocksFromActiveMoxie(Player:player, C:ronin_creature):void =
        if (UITeamInfo := PlayerTeamInfoMap[Player]):
            Lvl:int = C.Level

            # Compute and store max unlocked attack idx
            MaxIdx := GetMaxUnlockedAttackIndexForLevel(Lvl)
            if (set MaxUnlockedAttackIdxByPlayer[Player] = MaxIdx) {}

            # Always keep enabled so gamepad focus chain stays intact
            # SetAttackButtonEnabled(UIBattleInfo.Attack1Button, true)
            # SetAttackButtonEnabled(UIBattleInfo.Attack2Button, true)
            # SetAttackButtonEnabled(UIBattleInfo.Attack3Button, true)
            # SetAttackButtonEnabled(UIBattleInfo.Attack4Button, true)

            # Put real names/colors first
            SetAttackButtonsFromCreature(UITeamInfo, C)

            # Now visually “lock” 3/4 if needed (but still enabled)
            if (MaxIdx < 2):
                #set UITeamInfo.Attack3_MoxieColorMat.ColorSelectorSwitch = 0.0
                UITeamInfo.Attack3Button.SetText(CreateMessage("Locked (Lv 5+)")) # TODO - Add this with variable, for now its hardcoded

            if (MaxIdx < 3):
                #set UITeamInfo.Attack4_MoxieColorMat.ColorSelectorSwitch = 0.0
                UITeamInfo.Attack4Button.SetText(CreateMessage("Locked (Lv 10+)"))
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetMaxUnlockedAttackIndexForLevel(Level:int):int =
        # Default: 2 attacks (indices 0..1)
        var MaxIdx:int = 1

        # Unlock attack 3 (index 2)
        if (Level >= 5): # TODO - Add this with variable, for now its hardcoded
            set MaxIdx = 2

        # Unlock attack 4 (index 3)
        if (Level >= 10):
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

    RemoveEndBattleWidget(Player:player): void = 
        if (PlayerUI:=GetPlayerUI[Player]):
            if (UITeamInfo := PlayerTeamInfoMap[Player]):
                UpdateShouldCancelAnimations(Player, true)  
                PlayerUI.RemoveWidget(UITeamInfo.Canvas)
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetPlayerTeamWidgetArray(Player:player):[]Widgets.Test.WBP_Moxie_Team_Item = 
        if (UITeamInfo := PlayerTeamInfoMap[Player]):
            return array{
            UITeamInfo.MoxieTeamWidget_0,
            UITeamInfo.MoxieTeamWidget_1,
            UITeamInfo.MoxieTeamWidget_2,
            UITeamInfo.MoxieTeamWidget_3,
            UITeamInfo.MoxieTeamWidget_4,
            UITeamInfo.MoxieTeamWidget_5
            }
        return array{}
    # -------------------------------------------------------------------------------------------------------------------------------------

    GetPlayerTeamButtonsArray(Player:player):[]button_quiet = 
        if (UITeamInfo := PlayerTeamInfoMap[Player]):
            return array{
            UITeamInfo.MoxieTeamButton_0,
            UITeamInfo.MoxieTeamButton_1,
            UITeamInfo.MoxieTeamButton_2,
            UITeamInfo.MoxieTeamButton_3,
            UITeamInfo.MoxieTeamButton_4,
            UITeamInfo.MoxieTeamButton_5
            }
        return array{}
    # -------------------------------------------------------------------------------------------------------------------------------------

    UpdateTargetMoxieInfo(Player:player, MoxieIndex:int):void = 
        if (UITeamInfo := PlayerTeamInfoMap[Player]):
            MaybeTargetMoxie:= MoxieManager.GetPlayerMoxieTeamWithIndex(Player, MoxieIndex)
            if(TargetMoxie:= MaybeTargetMoxie?):

                # Set Selected Moxie Name on the Team Info
                UITeamInfo.MoxieName.SetText(CreateMessage("{CreatureTypeToString(TargetMoxie.Type)} Moxie"))
                # TODO - Set Selected Moxie Typem Icon on the Team Info
                UITeamInfo.MoxieType.SetText(CreateMessage(""))
                # Set Selected Moxie Id on the Team Info
                UITeamInfo.MoxieId.SetText(CreateMessage("Id #{TargetMoxie.CollectibleId}"))
                # Set Selected Moxie Nature on the Team Info
                UITeamInfo.MoxieNature.SetText(CreateMessage("Nature {NatureToString(TargetMoxie.Nature)}"))
                # Set Selected Moxie Nature on the Team Info
                UITeamInfo.MoxieStats.SetText(CreateMessage("LV. {TargetMoxie.Level} | HP. {FormatFloatTo1DecimalString(TargetMoxie.Health)} | ATK. {FormatFloatTo1DecimalString(TargetMoxie.Attack)} | DEF. {FormatFloatTo1DecimalString(TargetMoxie.Defense)} | SPD. {FormatFloatTo1DecimalString(TargetMoxie.Speed)}"))
                # Set Selected Moxie Nature on the Team Info
                UITeamInfo.MoxieAttackInfo.SetText(CreateMessage("Select an\nattack!"))
                # Set Moxie parts to the main Moxie Image
                SetMoxiePartsToUILeft(TargetMoxie, UITeamInfo.PlayerMoxieDisplay)
                # Spawn the animations of the main Moxie Image
                spawn { LoopIdleAnimationUILeft(Player, UITeamInfo.PlayerMoxieDisplay) }
    # -------------------------------------------------------------------------------------------------------------------------------------

    # Updates ONE team slot display (0..5) based on Target Moxie health
    UpdateSinglePlayerMoxieTeamDisplay(Player:player, MoxieTeamIndex:int):void =
        if (UITeamInfo := PlayerTeamInfoMap[Player]):
            TeamWidgets := GetPlayerTeamWidgetArray(Player)

            # Defensive index check
            if (MoxieTeamIndex < 0 or MoxieTeamIndex >= TeamWidgets.Length):
                return

            if (SlotWidget := TeamWidgets[MoxieTeamIndex]):
                MaybeTargetMoxie := MoxieManager.GetPlayerMoxieTeamWithIndex(Player, MoxieTeamIndex)

                if (TargetMoxie := MaybeTargetMoxie?):
                    # Core rule: alive if health > 0
                    IsAlive := logic{ TargetMoxie.Health > 0.0 }
                    SetTeamSlotVisualState(SlotWidget, IsAlive)
                else:
                    # No moxie in this slot
                    SetTeamSlotVisualState(SlotWidget, false)

    # -------------------------------------------------------------------------------------------------------------------------------------

    UpdateAllPlayerMoxieTeamDisplay(Player:player):void =
        for (Idx := 0..5):
            Print("Updating Moxie: {Idx} Widget!")
            UpdateSinglePlayerMoxieTeamDisplay(Player, Idx)
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

    var Left_IsIdleNext:logic = true
    # Loop the animation forever
    LoopIdleAnimationUILeft(Player:player, MoxieWidget: Widgets.Test.WBP_Moxie_Left)<suspends>:void =
        #Print("Moxie - Anim Loop Started")
        var TimeToWait: float = 0.0
        loop:
            if (UITeamInfo := PlayerTeamInfoMap[Player], UITeamInfo.AnimationLoopCancelledLeft = true):
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

    UpdateShouldCancelAnimations(Player:player, ShouldCancel:logic): void =
        if (UITeamInfo := PlayerTeamInfoMap[Player]):
            set UITeamInfo.AnimationLoopCancelledLeft = ShouldCancel
