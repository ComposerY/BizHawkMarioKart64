--This Lua script was developed by Drew Weatherton for the BizHawk emulator (additional authors: micro500, adelikat)--
--Purpose: Partially automate the process of executing perfect maneuvers in Mario Kart 64-----------------------------
console.clear()

local InputQueue = nil
local queueIterator = nil

function GetInputQueue()
    return bizstring.split(forms.gettext(InputQueueTextBox), "\r\n")
end

function SetInputQueue(table_data)
    local tableStr = ""
    local i = 1

    while i <= #table_data do
        if (i > 1) then
          tableStr = tableStr .. "\r\n"
        end
        
        tableStr = tableStr .. table_data[i]
        i = i +1
    end
    
    forms.settext(InputQueueTextBox, tableStr)
end

--User has clicked the "Generate Input" button
function GenerateButton()
--Variables, from Interface:
    Direction = forms.gettext(DirectionDropdown)
    Maneuver = forms.gettext(ManeuverDropdown)
    GlideType = forms.gettext(GlideDropdown)
    BlankLeadingFrames = tonumber(forms.gettext(TextBoxBlankLeadingFrames))

    --Input Catalog Logic-----------------------------------------------------------------
    --NOTE: We use the bk2 N64 movie mnemonic format (|..|    0,    0,...........A......|)
    --|rP| -XXX, -YYY,UDLRUDLRSZBAudrllr|
    --|rP| -XXX, -YYY,
    --      (+ analog)UDLR
    --             (D-pad)UDLR
    --                        SZBA
    --                 (C buttons)udrl
    --                      (Shoulder)lr|

    --Add an array to store inputs in
    FramesQueue = {}

    -- Add any desired blank frames to the start
    local CatalogFrameCount = 1

    while CatalogFrameCount <= tonumber(forms.gettext(TextBoxBlankLeadingFrames)) do
        FramesQueue[#FramesQueue+1] = string.format("%06i", CatalogFrameCount)..":|..|    0,    0,...........A......|"
        CatalogFrameCount = CatalogFrameCount + 1
    end

    -- Add specific maneuver inputs
    if Maneuver == "1.Outward MT (fastest)" then
        X_Array = {65,20,20,20,-35,65,-65,-65,-60,-60,-60,-60,-60,-60,-60,39,-50,-50,-50,-50,39,-65,-65,-65,-65,-65,-65,-65,-65,-65,-65,63}
        R_End = 21
        ManeuverComment = "Outward MT"

    elseif Maneuver == "2.Straight MT (faster)" then
        X_Array = {62,20,20,20,-35,64,-60,-60,-60,-60,-60,-60,-60,-60,-60,39,-50,-50,-50,-50,50,-56,-65,-65,-65,-65,-65,-65,-65,-65,-65,-65,61}
        R_End = 21
        ManeuverComment = "Straight MT"

    elseif Maneuver == "3.Inward MT (fast)" then
        X_Array = {65,65,65,20,20,65,-65,-65,-65,-60,-60,-60,-60,-60,-60,39,-50,-50,-50,-50,40,-55,-65,-65,-65,-65,-65,-65,-65,-65,-65,-65,-65,65}
        R_End = 21
        ManeuverComment = "Inward MT"

    elseif Maneuver == "4.Shroom Slide" then
        OuterFramesPer = tonumber(forms.gettext(TextBoxOuterFramesPer))
        InnerMagnitude = tonumber(forms.gettext(TextBoxInnerMagnitude))
        ShroomSlideFrames = tonumber(forms.gettext(TextBoxTotalShroomSlideFrames))
        X_Array = {}
        ManeuverComment = "Shroom Slide"

        local i = 0
        while i <= ShroomSlideFrames do
            local j = 0
            while j < OuterFramesPer do
                X_Array[#X_Array+1] = -65
                j = j + 1
                i = i +1
            end

            X_Array[#X_Array+1] = InnerMagnitude
            i = i +1
        end

        R_End = table.getn(X_Array)
    end

    TableSize = table.getn(X_Array)

    -- Make turn glide, if needed
    if GlideType == "Turn" then
        X_Array[R_End] = 65
        
        i = 1
        while i <= 10 do
            X_Array[R_End + i] = 65
            i = i + 1
        end

        X_Array[R_End + 11] = -55

        TableSize = R_End + 11
    end

    -- Generate the input in the mnemonic format
    local MT_Iterator = 1
    while MT_Iterator <= TableSize do

        X_Value = X_Array[MT_Iterator]
        if Direction == "Left" then
            X_Value = -X_Array[MT_Iterator]
        end
   
        FramesQueue[#FramesQueue+1] = string.format("%06i", CatalogFrameCount)..":|..| "
        FramesQueue[#FramesQueue] = FramesQueue[#FramesQueue]..string.format("%4i", X_Value)

        if MT_Iterator == 1 then
            FramesQueue[#FramesQueue] = FramesQueue[#FramesQueue]..",    0,...........A.....r|#"..ManeuverComment
        elseif MT_Iterator <= R_End then
            FramesQueue[#FramesQueue] = FramesQueue[#FramesQueue]..",    0,...........A.....r|#"
        else
            FramesQueue[#FramesQueue] = FramesQueue[#FramesQueue]..",    0,...........A......|#"
        end

        MT_Iterator = MT_Iterator + 1
        CatalogFrameCount = CatalogFrameCount + 1
    end

    -- Append any desired blank frames to the end
    local BlankTrailingFrameIterator = 0

    while BlankTrailingFrameIterator < tonumber(forms.gettext(TextBoxBlankTrailingFrames)) do
        FramesQueue[#FramesQueue+1] = string.format("%06i", CatalogFrameCount)..":|..|    0,    0,...........A......|#"
        CatalogFrameCount = CatalogFrameCount + 1
        BlankTrailingFrameIterator = BlankTrailingFrameIterator + 1
    end

    -- Convert the FramesQueue table
    local i = 1
    local tableStr = ""
    while i <= #FramesQueue do
        if (i > 1) then
            tableStr = tableStr .. "\r\n"
        end
        tableStr = tableStr .. FramesQueue[i]
        i = i +1
    end
    -- Verify output to the console
    -- console.log(tableStr)
    -- Output to the Main Window
    forms.settext(GeneratedTextBox, tableStr)
end

--User has clicked the "Execute Input" button
function ExecuteButton()
    
    if forms.ischecked(QueueJournalingCheckBox) == true then
        local handle = io.open("MarioKart64_InputQueueJournal"..os.date("_%Y-%m-%d")..".txt", "a+")
        handle:write("\r\n" .. "\r\n" .. os.date("%c") .. "\r\n" .. forms.gettext(InputQueueTextBox))
        handle:close()
    end

    InputQueue = GetInputQueue()
    queueIterator = 1
    
    forms.setproperty(ExecuteButtonHandle, "Enabled", false)
    forms.setproperty(RecordButtonHandle, "Enabled", false)
    forms.setproperty(ExecuteItemBotButtonHandle, "Enabled", false)
end

--For storing hud option states
Check_LapPosition = true
Check_Coordinates = true
Check_Rivals = true
Check_Time = true
Check_SpeedState = true

function CheckLapPosition()
    Check_LapPosition = not Check_LapPosition
end
function CheckCoordinates()
    Check_Coordinates = not Check_Coordinates
end
function CheckRivals()
    Check_Rivals = not Check_Rivals
end
function CheckTime()
    Check_Time = not Check_Time
end
function CheckSpeedState()
    Check_SpeedState = not Check_SpeedState
end

--User has clicked the "HUD Options" button
function HudButton()
    HudWindow = forms.newform(225, 120, "HUD Options")

    --HUD Customizations
    forms.label(HudWindow, "HUD Settings: (Uncheck to hide)", 10, 6, 240, 18)
    CheckboxHUD_LapPosition = forms.checkbox(HudWindow, "Lap / Position", 10, 21)
    CheckboxHUD_Coordinates = forms.checkbox(HudWindow, "Coordinates", 10, 40)
    CheckboxHUD_Rivals = forms.checkbox(HudWindow, "Rivals", 10, 59)
    CheckboxHUD_Time = forms.checkbox(HudWindow, "Time", 120, 21)
    CheckboxHUD_SpeedState = forms.checkbox(HudWindow, "Speed / State", 120, 40)
    
    forms.setproperty(CheckboxHUD_LapPosition, "Checked", Check_LapPosition)
    forms.setproperty(CheckboxHUD_Coordinates, "Checked", Check_Coordinates)
    forms.setproperty(CheckboxHUD_Rivals, "Checked", Check_Rivals)
    forms.setproperty(CheckboxHUD_Time, "Checked", Check_Time)
    forms.setproperty(CheckboxHUD_SpeedState, "Checked", Check_SpeedState)
    
    forms.addclick(CheckboxHUD_LapPosition, CheckLapPosition)
    forms.addclick(CheckboxHUD_Coordinates, CheckCoordinates)
    forms.addclick(CheckboxHUD_Rivals, CheckRivals)
    forms.addclick(CheckboxHUD_Time, CheckTime)
    forms.addclick(CheckboxHUD_SpeedState, CheckSpeedState)
end
HudButton()
forms.destroy(HudWindow)


WaypointsWindow = forms.newform(482, 700, "Mario Kart 64 Waypoint Dashboard")
forms.destroy(WaypointsWindow)

--User has clicked the "Waypoints" button
function WaypointsButton()

    WaypointsWindow = forms.newform(482, 700, "Mario Kart 64 Waypoint Dashboard")

    WaypointFilename = forms.textbox(WaypointsWindow, "WaypointFile", 366, 18, "", 53, 3, true, true)
    SaveWaypoint1Handle = forms.button(WaypointsWindow, "Save", SaveWaypoint1Button, 0, 0, 50, 23)
    OpenWaypoint1Handle = forms.button(WaypointsWindow, "Open", OpenWaypoint1Button, 422, 0, 50, 23)

-- Waypoint 1------------------------------------------------------------------------------------------------------------
-- Waypoint 1, Point 1

    forms.label(WaypointsWindow, "____________________________________________________________________________________", 0, 11, 477, 14)
    
    forms.label(WaypointsWindow, "Waypoint 1:", 0, 30, 64, 18)

    SetWaypoint1Handle = forms.button(WaypointsWindow, "Set from location", SetWaypoint1Button, 185, 110, 94, 23)
    Waypoint1TitleTextBox = forms.textbox(WaypointsWindow, "Waypoint 1", 408, 20, "", 64, 27, true, true)

    Waypoint1XTextBox = forms.textbox(WaypointsWindow, "0", 132, 20, SIGNED, 185, 50, false, true)
    Waypoint1XLabel = forms.label(WaypointsWindow, "X:", 171, 55, 17, 15)
    Waypoint1X = tonumber(forms.gettext(Waypoint1XTextBox))

    Waypoint1YTextBox = forms.textbox(WaypointsWindow, "0", 132, 20, SIGNED, 185, 70, false, true)
    forms.label(WaypointsWindow, "Y:", 171, 75, 17, 15) 
    Waypoint1Y = tonumber(forms.gettext(Waypoint1YTextBox))

    Waypoint1ZTextBox = forms.textbox(WaypointsWindow, "0", 132, 20, SIGNED, 185, 90, false, true)
    forms.label(WaypointsWindow, "Z:", 171, 95, 17, 15)
    Waypoint1Z = tonumber(forms.gettext(Waypoint1ZTextBox))

-- Waypoint 1, Point 2
    SetWaypoint1Handle2 = forms.button(WaypointsWindow, "Set from location", SetWaypoint1Button2, 378, 110, 94, 23)
    -- Create checkbox for toggling this waypoint's visiblity
    CheckboxWayline1 = forms.checkbox(WaypointsWindow, "Line segment", 295, 110)
    -- This starts as invisible (size 0,0) but size is changed to cover all related inputs
    Waypoint1Cover2 = forms.label(WaypointsWindow, "", 320, 50, 0, 0)

    Waypoint1X2TextBox = forms.textbox(WaypointsWindow, "0", 132, 20, SIGNED, 340, 50, false, true)
    forms.label(WaypointsWindow, "X2:", 320, 55, 24, 15)
    Waypoint1X2 = tonumber(forms.gettext(Waypoint1X2TextBox))

    Waypoint1Y2TextBox = forms.textbox(WaypointsWindow, "0", 132, 20, SIGNED, 340, 70, false, true)
    forms.label(WaypointsWindow, "Y2:", 320, 75, 24, 15)
    Waypoint1Y2 = tonumber(forms.gettext(Waypoint1Y2TextBox))

    Waypoint1Z2TextBox = forms.textbox(WaypointsWindow, "0", 132, 20, SIGNED, 340, 90, false, true)
    forms.label(WaypointsWindow, "Z2:", 320, 95, 24, 15)
    Waypoint1Z2 = tonumber(forms.gettext(Waypoint1Z2TextBox))

-- Distances
    forms.label(WaypointsWindow, "Distances:", 10, 53, 60, 15)
    Waypoint1XYTextBox = forms.textbox(WaypointsWindow, "0", 132, 20, SIGNED, 33, 70, false, true)
    forms.label(WaypointsWindow, "XY:", 10, 75, 25, 20)
    forms.checkbox(WaypointsWindow,"On-Screen",70,100)

    Waypoint1XYZTextBox = forms.textbox(WaypointsWindow, "0", 132, 20, SIGNED, 33, 90, false, true)
    forms.label(WaypointsWindow, "XYZ:", 3, 95, 32, 20)

-- Waypoint 2------------------------------------------------------------------------------------------------------------
-- Waypoint 2, Point 1

    forms.label(WaypointsWindow, "____________________________________________________________________________________", 0, 123, 477, 14)
    
    Waypoint2TitleTextBox = forms.textbox(WaypointsWindow, "Waypoint 2", 388, 20, "", 84, 139, true, true)

    CheckboxWaypoint2 = forms.checkbox(WaypointsWindow, "Waypoint 2:", 3, 137)
    
    SetWaypoint1Handle = forms.button(WaypointsWindow, "Set from location", SetWaypoint2Button, 185, 222, 94, 23)

    Waypoint2XTextBox = forms.textbox(WaypointsWindow, "0", 132, 20, SIGNED, 185, 162, false, true)
    Waypoint2XLabel = forms.label(WaypointsWindow, "X:", 171, 167, 17, 15)
    Waypoint2X = tonumber(forms.gettext(Waypoint1XTextBox))

    Waypoint2YTextBox = forms.textbox(WaypointsWindow, "0", 132, 20, SIGNED, 185, 182, false, true)
    forms.label(WaypointsWindow, "Y:", 171, 187, 17, 15) 
    Waypoint2Y = tonumber(forms.gettext(Waypoint1YTextBox))

    Waypoint2ZTextBox = forms.textbox(WaypointsWindow, "0", 132, 20, SIGNED, 185, 202, false, true)
    forms.label(WaypointsWindow, "Z:", 171, 207, 17, 15)
    Waypoint2Z = tonumber(forms.gettext(Waypoint1ZTextBox))

-- Waypoint 1, Point 2

    SetWaypoint2Handle2 = forms.button(WaypointsWindow, "Set from location", SetWaypoint2Button2, 378, 222, 94, 23)

    -- Create checkbox for toggling this waypoint's visiblity
    CheckboxWayline2 = forms.checkbox(WaypointsWindow, "Line segment", 295, 222)
    -- This starts as invisible (size 0,0) but size is changed to cover all related inputs
    Waypoint2Cover2 = forms.label(WaypointsWindow, "", 320, 162, 0, 0)

    Waypoint2X2TextBox = forms.textbox(WaypointsWindow, "0", 132, 20, SIGNED, 340, 162, false, true)
    forms.label(WaypointsWindow, "X2:", 320, 167, 24, 15)
    Waypoint2X2 = tonumber(forms.gettext(Waypoint1X2TextBox))

    Waypoint2Y2TextBox = forms.textbox(WaypointsWindow, "0", 132, 20, SIGNED, 340, 182, false, true)
    forms.label(WaypointsWindow, "Y2:", 320, 187, 24, 15)
    Waypoint2Y2 = tonumber(forms.gettext(Waypoint1Y2TextBox))

    Waypoint2Z2TextBox = forms.textbox(WaypointsWindow, "0", 132, 20, SIGNED, 340, 202, false, true)
    forms.label(WaypointsWindow, "Z2:", 320, 207, 24, 15)
    Waypoint2Z2 = tonumber(forms.gettext(Waypoint1Z2TextBox))

-- Distances
    forms.label(WaypointsWindow, "Distances:", 10, 165, 60, 15)
    Waypoint2XYTextBox = forms.textbox(WaypointsWindow, "0", 132, 20, SIGNED, 33, 182, false, true)
    forms.label(WaypointsWindow, "XY:", 10, 187, 25, 20)    

    Waypoint2XYZTextBox = forms.textbox(WaypointsWindow, "0", 132, 20, SIGNED, 33, 202, false, true)
    forms.label(WaypointsWindow, "XYZ:", 3, 207, 32, 20)

end


--User has clicked the "Save" button
function SaveWaypoint1Button()

    if forms.ischecked(CheckboxWayline1) == true then
        CheckboxWayline1State = "true"
    else 
        CheckboxWayline1State = "false"
    end

    if forms.ischecked(CheckboxWaypoint2) == true then
        CheckboxWaypoint2State = "true"
    else 
        CheckboxWaypoint2State = "false"
    end

    if forms.ischecked(CheckboxWayline2) == true then
        CheckboxWayline2State = "true"
    else 
        CheckboxWayline2State = "false"
    end

    local handle = io.open(forms.gettext(WaypointFilename) .. ".wpt", "w+")
    handle:write(
        CheckboxWayline1State .. "\n" ..
        CheckboxWaypoint2State .. "\n" ..
        CheckboxWayline2State .. "\n" ..

        forms.gettext(Waypoint1TitleTextBox) .. "\n" ..
        forms.gettext(Waypoint1XTextBox) .. "\n" ..
        forms.gettext(Waypoint1YTextBox) .. "\n" ..
        forms.gettext(Waypoint1ZTextBox) .. "\n" ..

        forms.gettext(Waypoint1X2TextBox) .. "\n" ..
        forms.gettext(Waypoint1Y2TextBox) .. "\n" ..
        forms.gettext(Waypoint1Z2TextBox) .. "\n" ..

        forms.gettext(Waypoint2TitleTextBox) .. "\n" ..
        forms.gettext(Waypoint2XTextBox) .. "\n" ..
        forms.gettext(Waypoint2YTextBox) .. "\n" ..
        forms.gettext(Waypoint2ZTextBox) .. "\n" ..

        forms.gettext(Waypoint2X2TextBox) .. "\n" ..
        forms.gettext(Waypoint2Y2TextBox) .. "\n" ..
        forms.gettext(Waypoint2Z2TextBox))
    handle:close()

    console.log("Waypoint File Saved")

end

--User has clicked the "Open" button
function OpenWaypoint1Button()

    SavedVariables = { }

    SavedVariables[0] = CheckboxWayline1
    SavedVariables[1] = CheckboxWaypoint2
    SavedVariables[2] = CheckboxWayline2

    SavedVariables[3] = Waypoint1TitleTextBox
    SavedVariables[4] = Waypoint1XTextBox
    SavedVariables[5] = Waypoint1YTextBox
    SavedVariables[6] = Waypoint1ZTextBox
    SavedVariables[7] = Waypoint1X2TextBox
    SavedVariables[8] = Waypoint1Y2TextBox
    SavedVariables[9] = Waypoint1Z2TextBox
    SavedVariables[10] = Waypoint2TitleTextBox
    SavedVariables[11] = Waypoint2XTextBox
    SavedVariables[12] = Waypoint2YTextBox
    SavedVariables[13] = Waypoint2ZTextBox
    SavedVariables[14] = Waypoint2X2TextBox
    SavedVariables[15] = Waypoint2Y2TextBox
    SavedVariables[16] = Waypoint2Z2TextBox

    WaypointDirectory = forms.openfile()

    local i = 0

    for line in io.lines(WaypointDirectory) do

        console.log(line)
        if i < 3 then
            forms.setproperty(SavedVariables[i],"Checked",line)
        else
            forms.settext(SavedVariables[i], line)
        end

        i = i + 1

    end

end

function SetWaypoint1Button()

    forms.settext(Waypoint1XTextBox, PlayerX)
    forms.settext(Waypoint1YTextBox, PlayerY)
    forms.settext(Waypoint1ZTextBox, PlayerZ)

end

function SetWaypoint1Button2()

    forms.settext(Waypoint1X2TextBox, PlayerX)
    forms.settext(Waypoint1Y2TextBox, PlayerY)
    forms.settext(Waypoint1Z2TextBox, PlayerZ)

end

function SetWaypoint2Button()

    forms.settext(Waypoint2XTextBox, PlayerX)
    forms.settext(Waypoint2YTextBox, PlayerY)
    forms.settext(Waypoint2ZTextBox, PlayerZ)

end

function SetWaypoint2Button2()

    forms.settext(Waypoint2X2TextBox, PlayerX)
    forms.settext(Waypoint2Y2TextBox, PlayerY)
    forms.settext(Waypoint2Z2TextBox, PlayerZ)

end

function SaveInputQueueStateButton()
    local handle = io.open(forms.gettext(SaveInputQueueFileName)..os.date("_%Y-%m-%d_%H'%M'%S")..".que","w")
    handle:write(forms.gettext(InputQueueTextBox))
    handle:close()
    console.log("Input Queue file saved")

    if forms.ischecked(QueueSavestateCheckbox) == true then
        savestate.save(forms.gettext(SaveInputQueueFileName)..os.date("_%Y-%m-%d_%H'%M'%S")..".State")
        console.log("Input Queue save state stored")
    end 
end

function OpenInputQueueStateButton()
    InputQueueDirectory = forms.openfile()
    LoadedFramesQueue = {}

    if InputQueueDirectory ~= '' then
        for line in io.lines(InputQueueDirectory) do
            console.log(line)
            LoadedFramesQueue[#LoadedFramesQueue+1] = line
        end

        -- Convert the FramesQueue table
        local i = 1
        local LoadedTableStr = ""
        while i <= #LoadedFramesQueue do
            if (i > 1) then
                LoadedTableStr = LoadedTableStr .. "\r\n"
            end
            LoadedTableStr = LoadedTableStr .. LoadedFramesQueue[i]
            i = i +1
        end
        -- Verify output to the console
        -- console.log(LoadedTableStr)
        -- Output to the Main Window
        forms.settext(InputQueueTextBox, LoadedTableStr)
    end
end

--WaypointsButton()
--forms.destroy(HudWindow)

--Generate the User Interface
------------INPUTS ARE X,Y,WIDTH,HEIGHT  -- For Text Boxes: WIDTH, HEIGHT, "signed", X, Y-------
MainWindow = forms.newform(905, 800, "Mario Kart 64 Automatic Transmission v1.30")

-- Blank frames
TextBoxBlankLeadingFrames = forms.textbox(MainWindow, "0", 20, 18, "UNSIGNED", 10, 5)
forms.label(MainWindow, "Blank leading frames", 28, 8, 105, 18)

TextBoxBlankTrailingFrames = forms.textbox(MainWindow, "10", 20, 18, "UNSIGNED", 140, 5)
forms.label(MainWindow, "Blank trailing frames", 158, 8, 105, 18)

--Direction dropdown
LabelDirection = forms.label(MainWindow, "facing", 58, 31, 40, 20)
a = { }
a[1] = "Left"
a[2] = "Right"
DirectionDropdown = forms.dropdown(MainWindow, a, 10, 28, 48, 20)

--Maneuver dropdown
a = { }
a[1] = "1.Outward MT (fastest)"
a[2] = "2.Straight MT (faster)"
a[3] = "3.Inward MT (fast)"
a[4] = "4.Shroom Slide"
ManeuverDropdown = forms.dropdown(MainWindow, a, 98, 28, 132, 20)

--Turn dropdown
LabelGlide = forms.label(MainWindow, "glide", 295, 32, 60, 20)
a = { }
a[1] = "Straight"
a[2] = "Turn"
GlideDropdown = forms.dropdown(MainWindow, a, 235, 28, 60, 20)


--Shroomslide options
forms.label(MainWindow, "Shroom slide", 12, 57, 67, 14)
forms.label(MainWindow, "parameters", 14, 68, 66, 14)
forms.label(MainWindow, "(                       :", 5, 62, 90, 14)

TextBoxTotalShroomSlideFrames = forms.textbox(MainWindow, "60", 20, 18, "UNSIGNED", 95, 59)
forms.label(MainWindow, "Total frames", 113, 61, 65, 18)

forms.label(MainWindow, "Outer frames", 282, 55, 67, 14)
forms.label(MainWindow, "per inner", 287, 66, 60, 14)
forms.label(MainWindow, ")", 346, 60, 8, 14)
TextBoxOuterFramesPer = forms.textbox(MainWindow, "1", 20, 18, "UNSIGNED", 260, 59)

forms.label(MainWindow, "Inner", 207, 55, 40, 14)
forms.label(MainWindow, "magnitude", 201, 66, 60, 14)
TextBoxInnerMagnitude = forms.textbox(MainWindow, "32", 20, 18, "UNSIGNED", 181, 59)

--Create Input
GenerateButtonHandle = forms.button(MainWindow, "Generate Input", GenerateButton, 1, 95, 86, 23)

--Multi-Line Textbox for Generating Input
forms.label(MainWindow, "INPUT CATALOG:", 166, 101, 110, 15)
GeneratedTextBox = forms.textbox(MainWindow, "000001:|..|    0,    0,...........A......|#Comment", 408, 615, "", 1, 118, true, true,"BOTH")
forms.setproperty(GeneratedTextBox, "MaxLength", "1000000000")


--HUD window creation
HUDButtonHandle = forms.button(MainWindow, "HUD Options", HudButton, 1, 735, 86, 23)

--Waypoints Button
forms.button(MainWindow, "Waypoints", WaypointsButton, 135, 735, 86, 23)

--Input Queue Save Button
forms.button(MainWindow, "Save^", SaveInputQueueStateButton, 426, 735, 50, 23)

--Input Queue Save Name
SaveInputQueueFileName = forms.textbox(MainWindow, "InputQueueFile",  230, 23, "", 560, 735, true, true)

--Input Queue Save Includes State
QueueSavestateCheckbox = forms.checkbox(MainWindow, "+ Savestate", 479,735)

--Input Queue Open Button
forms.button(MainWindow, "Open", OpenInputQueueStateButton, 790, 735, 45, 23)

--Input Queue Journaling
QueueJournalingCheckBox = forms.checkbox(MainWindow, "Journal to file", 426, 0)
forms.setproperty(QueueJournalingCheckBox,"Checked",true)

--Coordinate Units
a = { }
a[1] = " Meters"
a[2] = "Game Units"
UnitsDropdown = forms.dropdown(MainWindow, a, 325, 735, 85, 23)
forms.label(MainWindow, "Coordinates:", 260, 739, 66, 23)

--Populate the Frame Reference Table
function PopulateFrameReference()
    local LoadFramecount = emu.framecount()
    local i = 1 
    
    local input_queue = GetInputQueue()
    console.log(input_queue)
    
    while i <= #input_queue do
        local cur_line = input_queue[i]
        local input_start = string.find(cur_line, "|")
        
        cur_line = string.sub(cur_line, input_start)
        cur_line = string.format("%06i", (LoadFramecount + (i-1)*2)) .. ":" .. cur_line
    
        input_queue[i] = cur_line
        i = i +1
    end
    
    SetInputQueue(input_queue)
end

event.onloadstate(PopulateFrameReference)

--Item selection dropdown
itemOptions = { }
itemOptions[0] = "01. Banana"
itemOptions[1] = "02. Banana Bunch"
itemOptions[2] = "03. Green Shell"
itemOptions[3] = "04. Triple Green Shell"
itemOptions[4] = "05. Red Shell"
itemOptions[5] = "06. Triple Red Shell"
itemOptions[6] = "07. Spiny Shell"
itemOptions[7] = "08. Thunder Bolt"
itemOptions[8] = "09. Fake Item Box"
itemOptions[9] = "10. Super Star"
itemOptions[10] = "11. Boo"
itemOptions[11] = "12. Mushroom"
itemOptions[13] = "14. Triple Mushrooms"
itemOptions[14] = "15. Super Mushroom"
ItemSelectionDropdown = forms.dropdown(MainWindow, itemOptions, 712, 2, 125, 20)

BooModeCheckbox = forms.checkbox(MainWindow, "Boo", 844,23)

--Multi-Line Textbox for Input Queue
forms.label(MainWindow, "INPUT QUEUE:", 576, 9, 150, 15)
--forms.label(MainWindow, "<-Format", 682, 26, 60, 18)
forms.textbox(MainWindow, "Frame#:|rP| -XXX, -YYY,UDLRUDLRSZBAudrllr|#Mnemonic", 409, 20, "", 426, 24, true, true)
InputQueueTextBox = forms.textbox(MainWindow, "000001:|..|    0,    0,...........A......|#Comment", 409, 690, "", 426, 43, true, true,"BOTH")
forms.setproperty(InputQueueTextBox, "MaxLength", "1000000000")

--Execute Input
ExecuteButtonHandle = forms.button(MainWindow, "Execute Input", ExecuteButton, 834, 46, 55, 688)

RecordButtonHandle = nil

RecordState = 0

function RecordButton()
  if (RecordState == 0) then
    forms.setproperty(ExecuteButtonHandle, "Enabled", false)
    forms.setproperty(ExecuteItemBotButtonHandle, "Enabled", false)
    
    -- Clear the queue
    forms.settext(GeneratedTextBox, "")
    
    -- set flag to indicate in record mode
    RecordState = 1
    
    forms.settext(RecordButtonHandle, "Stop Recording")
  else
    forms.setproperty(ExecuteButtonHandle, "Enabled", true)
    forms.setproperty(ExecuteItemBotButtonHandle, "Enabled", true)
  
    RecordState = 0
  
    forms.settext(RecordButtonHandle, "Record Input")
  end
end

RecordButtonHandle = forms.button(MainWindow, "Record Input", RecordButton, 334, 95, 77, 23)

function ClearQueue()
    InputQueue = nil
    queueIterator = nil
    forms.setproperty(ExecuteButtonHandle, "Enabled", true)
    forms.setproperty(RecordButtonHandle, "Enabled", true)
    forms.setproperty(ExecuteItemBotButtonHandle, "Enabled", true)
end

function CopyInputButton()
    forms.settext(InputQueueTextBox, forms.gettext(GeneratedTextBox))
end

CopyInputHandle = forms.button(MainWindow, ">", CopyInputButton, 404, 150, 30, 23)

function AppendInputButton()
    forms.settext(InputQueueTextBox, forms.gettext(InputQueueTextBox) .. "\r\n" .. forms.gettext(GeneratedTextBox))
end

AppendInputHandle = forms.button(MainWindow, ">>", AppendInputButton, 404, 200, 30, 23)

-- Bot variables

-- Item bot States:
-- -1: not active
-- 0: searching for first chance to hit Z
-- 1: about to press Z
-- 2: Waiting to see what item we got
-- 3: advancing one input frame past the last time we tried
-- 4. Successful cleanup

ItemBotState = -1

ItemBotIteratorSave = -1

ItemBotWantedItem = -1

ExecuteItemBotButtonHandle = nil

function ExecuteItemBotButton()
    if (ItemBotState ~= -1) then
        -- disable the bot
        ItemBotState = -1
        ClearQueue()

        -- Change the button text to something
        forms.settext(ExecuteItemBotButtonHandle, "Item Bot")
    else
        -- Set up the input queue
        ExecuteButton()

        -- Make both buttons disabled
        forms.setproperty(ExecuteButtonHandle, "Enabled", false)
        
        -- Make a starting state
        savestate.save("ItemBotStartingState")
        
        -- Find the desired item
        itemSelection = forms.gettext(ItemSelectionDropdown)
        local i = 0
        while (i < 15) do
            if (itemOptions[i] == itemSelection) then
                ItemBotWantedItem = i + 1
            end
            i = i + 1
        end

        forms.setproperty(ExecuteItemBotButtonHandle, "Enabled", true)
        forms.settext(ExecuteItemBotButtonHandle, "Stop Bot")
        
        ItemBotState = 0
    end
end

--Item Select Bot Execute
ExecuteItemBotButtonHandle = forms.button(MainWindow, "Item Bot", ExecuteItemBotButton, 835, 1, 55, 23)

function load_state_handler() 
    if (ItemBotState == -1) then
        ClearQueue()
    end
    
    if (RecordState == 1) then
      forms.setproperty(ExecuteButtonHandle, "Enabled", true)
      forms.setproperty(ExecuteItemBotButtonHandle, "Enabled", true)
    
      RecordState = 0
    
      forms.settext(RecordButtonHandle, "Record Input")
    end
end

loadstateEventHandle = event.onloadstate(load_state_handler, "load_state_handler")

while true do

    if Check_Time then
        local TimerAddr = 0x0DC598

        Timer=mainmemory.readfloat(TimerAddr, true)
        gui.text(0,0, "TIME ".. string.format("%.3f", Timer),"orange",0x50000000,"topright")
    end

    if Check_LapPosition then
        local LapAddr = 0x164390
        local PathAddr = 0x163288
        local PlaceAddr = 0x1643BB

        Lap=mainmemory.read_s32_be(LapAddr) + 1
        Path=mainmemory.read_s32_be(PathAddr)
        Place=mainmemory.read_u8(PlaceAddr) + 1
        gui.text(client.borderwidth()+client.bufferwidth()*.35,0, "LAP ".. Lap .. "/3, Path " .. Path .. ", Place " .. Place .. "/8",0xFFC758FF,0x50000000)
    end

    if Check_Coordinates then
        local Xaddr = 0x0F69A4
        local XvAddr = 0x0F69C4
        local Yaddr = 0x0F69AC
        local YvAddr = 0x0F69CC
        local Zaddr = 0xF69A8
        local ZvAddr = 0x0F69C8
        local ZgroundAddr = 0x0F6A04

        UnitsChoice = forms.gettext(UnitsDropdown)

        if UnitsChoice == " Meters" then
            Units = 18
        else
            Units = 1
        end

        --A note about units
        --In-game velocities are multipled by 12 to arrive at the values used for the in-game speedometer (oddly, in-game velocities do not correspond directly
        -----to game units as traveling for 1 velocity unit per hour for one second results in traveling 60 game units (where a direct relationship would give 3.6)
        --To convert the coordinate game units to meters, I tested using reverse which is a constant 12.000... km/h on flat ground. At this speed 60.000... game units
        -----are traveled. 12 km/h is 3.333... m/s so we should be covering (10/3) meters. Thus (10/3) meters = 60 game units and thus 1 meter = (3/10) * 60 = 18 game units
        -----Thus, to show coordinates in meters we must divide them by 18. This is helpful to do as then velocities and coordinates are provided in km/h and meters respectively

        PlayerX=mainmemory.readfloat(Xaddr, true) / Units
        gui.text(0,17, "X ".. string.format("%.3f", PlayerX),"white","black","bottomleft")
        PlayerXv=mainmemory.readfloat(XvAddr, true) * 12
        gui.text(0,2, "Xv ".. string.format("%.3f", PlayerXv),"white","black","bottomleft")

        PlayerY=mainmemory.readfloat(Yaddr, true) / Units
        gui.text(120,17, "Y ".. string.format("%.3f", PlayerY),"white","black","bottomleft")
        PlayerYv=mainmemory.readfloat(YvAddr, true) * 12
        gui.text(120,2, "Yv ".. string.format("%.3f", PlayerYv),"white","black","bottomleft")

        PlayerZ=mainmemory.readfloat(Zaddr, true) / Units
        gui.text(240,17, "Z ".. string.format("%.3f", PlayerZ),"white","black","bottomleft")
        PlayerZv=mainmemory.readfloat(ZvAddr, true) * 12
        gui.text(240,2, "Zv ".. string.format("%.3f", PlayerZv),"white","black","bottomleft")

        gui.text(360,2, "XYZv " .. string.format("%.3f", math.sqrt (PlayerXv^2+PlayerYv^2+PlayerZv^2)) .. " km/h","white","black","bottomleft")

        GroundHeight=mainmemory.readfloat(ZgroundAddr, true)
        PlayerHeight=mainmemory.readfloat(Zaddr, true)
        PlayerAGL=(PlayerHeight-GroundHeight-5.317) / Units
        gui.text(360,17, "Z[AGL] " .. string.format("%.2f", PlayerAGL),"white","black","bottomleft")
    end
    
    if Check_Rivals then

        --Rivals
        local Rival1Addr = 0x163349
        local Rival2Addr = 0x16334B

        characters = {
            "Mario","Luigi","Yoshi","Toad","DK","Wario","Peach","Bowser"
        }
	
        Rival1=mainmemory.read_u8(Rival1Addr)
        Rival2=mainmemory.read_u8(Rival2Addr)

        characters = {
            "Mario","Luigi","Yoshi","Toad","DK","Wario","Peach","Bowser"
        }

        Rival1=mainmemory.read_u8(Rival1Addr)
        Rival2=mainmemory.read_u8(Rival2Addr)

        gui.text(536,17, "R1: " .. characters[Rival1+1],"yellow","black","bottomleft")
        gui.text(536,2, "R2: " .. characters[Rival2+1],"yellow","black","bottomleft")
    end

    if Check_SpeedState then

        local MTglideAddr = 0x0F6BCB

        MTglide=mainmemory.read_u8(MTglideAddr)
        if MTglide > 0 then
            gui.text(client.screenwidth()*.5-30,client.screenheight()*.5 - 30, "MT " .. 31 - MTglide,"red")
        end

        local StateEAddr = 0x0F6A4E
        StateE=mainmemory.read_u8(StateEAddr)

        if bit.check(StateE,5) then
            gui.text(client.screenwidth()*.5-50,client.screenheight()*.5 - 15, "SHROOMING","red")
        end

        --This speed address is what actually feeds the speedometer but it is only the XY velocity and also stops reporting after a race ends
        --local SpeedAddr = 0x18CFE4
        --Speed=mainmemory.readfloat(SpeedAddr, true)
        --I chose to calculate the velocity based on the XY velocity rather than reading the speedometer memory value

        gui.text(client.screenwidth()*.5-60,client.screenheight()*.5, string.format("%.3f", math.sqrt (PlayerXv^2+PlayerYv^2)) .. " km/h","white","black")
        
        local StateFAddr = 0x0F6A4F
        StateF=mainmemory.read_u8(StateFAddr)

        if bit.check(StateF,5) then
            gui.text(client.screenwidth()*.5-60,client.screenheight()*.5 + 15, "AB SPINNING","red")
        end

        if bit.check(StateF,3) then
            gui.text(client.screenwidth()*.5-55,client.screenheight()*.5 + 30, "OFF GROUND","red")
        end
    end

    if forms.getproperty(WaypointsWindow,"WindowState") ~= "" then
        -- Waypoint 1 Logic
        Waypoint1X = tonumber(forms.gettext(Waypoint1XTextBox))
        Waypoint1Y = tonumber(forms.gettext(Waypoint1YTextBox))
        Waypoint1Z = tonumber(forms.gettext(Waypoint1ZTextBox))

        Waypoint1XY = math.sqrt ((Waypoint1X-PlayerX)^2+(Waypoint1Y-PlayerY)^2)
        forms.settext( Waypoint1XYTextBox, string.format("%.3f",Waypoint1XY))
        --gui.text(240,2, "Zv ".. string.format("%.3f", PlayerZv),"white","black","bottomleft")

        Waypoint1XYZ = math.sqrt ((Waypoint1X-PlayerX)^2+(Waypoint1Y-PlayerY)^2+(Waypoint1Z-PlayerZ)^2)
        forms.settext(Waypoint1XYZTextBox, string.format("%.3f",Waypoint1XYZ))

        if forms.ischecked(CheckboxWayline1) == false then

            forms.setproperty(Waypoint1Cover2,"Visible",true)
            forms.setproperty(SetWaypoint1Handle2,"Visible",false)

        else

            forms.setproperty(Waypoint1Cover2,"Visible",false)
            forms.setproperty(SetWaypoint1Handle2,"Visible",true)

            Waypoint1X2 = tonumber(forms.gettext(Waypoint1X2TextBox))
            Waypoint1Y2 = tonumber(forms.gettext(Waypoint1Y2TextBox))
            Waypoint1Z2 = tonumber(forms.gettext(Waypoint1Z2TextBox))

        end

        if forms.ischecked(CheckboxWaypoint2) == false then

            forms.setsize(WaypointsWindow, 482, 182)
            forms.setproperty(Waypoint2TitleTextBox,"Visible",false)


        else

            forms.setsize(WaypointsWindow, 482, 272)
            forms.setproperty(Waypoint2TitleTextBox,"Visible",true)

            -- Waypoint 2 Logic
            Waypoint2X = tonumber(forms.gettext(Waypoint2XTextBox))
            Waypoint2Y = tonumber(forms.gettext(Waypoint2YTextBox))
            Waypoint2Z = tonumber(forms.gettext(Waypoint2ZTextBox))

            Waypoint2XY = math.sqrt ((Waypoint2X-PlayerX)^2+(Waypoint2Y-PlayerY)^2)
            forms.settext(Waypoint2XYTextBox, string.format("%.3f",Waypoint2XY))

            Waypoint2XYZ = math.sqrt ((Waypoint2X-PlayerX)^2+(Waypoint2Y-PlayerY)^2+(Waypoint2Z-PlayerZ)^2)
            forms.settext(Waypoint2XYZTextBox, string.format("%.3f",Waypoint2XYZ))

        end

        if forms.ischecked(CheckboxWayline2) == false then

            forms.setproperty(Waypoint2Cover2,"Visible",true)
            forms.setproperty(SetWaypoint2Handle2,"Visible",false)

        else

            forms.setproperty(Waypoint2Cover2,"Visible",false)
            forms.setproperty(SetWaypoint2Handle2,"Visible",true)

            Waypoint2X2 = tonumber(forms.gettext(Waypoint2X2TextBox))
            Waypoint2Y2 = tonumber(forms.gettext(Waypoint2Y2TextBox))
            Waypoint2Z2 = tonumber(forms.gettext(Waypoint2Z2TextBox))

        end
    end
    
    -- Detect if this is a lag frame
    isLag = emu.islagged()
    
    if (RecordState == 1) then
        if (isLag == false) then
            forms.settext(GeneratedTextBox, forms.gettext(GeneratedTextBox) .. movie.getinputasmnemonic(emu.framecount()-1) .. "\r\n")
        end
    elseif (InputQueue ~= nil) then
        if (isLag == false) then
            queueIterator = queueIterator + 1
        end
        
        local toPut = ""
        
        if (queueIterator < table.getn(InputQueue) + 1) then
            toPut = bizstring.replace(InputQueue[queueIterator], "\n", "")
            
            -- Remove the frame number and comments if present
            local input_start = string.find(toPut, "|")
            toPut = string.sub(toPut, input_start)
            toPut = string.sub(toPut, 1, 35)
        else
            ClearQueue()
        end
        
        if (ItemBotState >= 0) then
            if (toPut == "") then
                -- We failed!
                
                -- print out a message?
                console.log("Item bot ran out of queued input!")
                
                -- Re-enable the button
                forms.settext(ExecuteItemBotButtonHandle, "Item Bot")
                
                ItemBotState = -1
            else
                -- If looking for the first chance to press z, check now
                if (ItemBotState == 0) then
                    -- Read the delay timer value
                    local delayTimerAddr = 0x165F07
                    z_delay_timer = memory.read_u8(delayTimerAddr)
                    
                    -- Found it, switch states
                    if (((z_delay_timer == 0 or z_delay_timer == 1) and isLag == true) or forms.ischecked(BooModeCheckbox)) then
                        -- Make a state here
                        savestate.save("ItemBotIterator")
                        
                        -- Remember what spot we're on in the queue
                        ItemBotIteratorSave = queueIterator
                        
                        -- Change State
                        ItemBotState = 1
                    else
                        -- Still looking
                    end
                elseif (ItemBotState == 1) then
                    if (isLag == false) then
                        -- We just successfully pressed Z

                        -- Change state to detection mode
                        ItemBotState = 2
                    end
                    
                -- If waiting to see what item we got, check if its set yet, and if its what we want
                elseif (ItemBotState == 2) then
                    item_we_got = memory.read_s8(0x165F5B)
                    z_delay_timer = memory.read_u8(0x165F07)

                    if (item_we_got > 0 or (z_delay_timer == 255 and forms.ischecked(BooModeCheckbox))) then
                        if (item_we_got == ItemBotWantedItem) then
                            -- We succeeded
                            
                            local to_edit = bizstring.replace(InputQueue[ItemBotIteratorSave], "\n", "")
                            to_edit = string.sub(to_edit,0,25) .. "Z" .. string.sub(to_edit,27)
                            InputQueue[ItemBotIteratorSave] = to_edit
                            SetInputQueue(InputQueue)
                            
                            -- Clean up the queue
                            ClearQueue()
                            
                            -- Load the starting state
                            savestate.load("ItemBotStartingState")
                            
                            -- turn off the bot
                            ItemBotState = 4
                            
                            -- Pause
                            client.pause()
                        else
                            -- We failed
                            -- load the state
                            savestate.load("ItemBotIterator")
                            
                            -- load the iterator value
                            queueIterator = ItemBotIteratorSave

                            -- Switch to skip a frame mode
                            ItemBotState = 3
                        end
                    end

                elseif (ItemBotState == 3) then
                    if (isLag == false) then
                        -- Save the state
                        savestate.save("ItemBotIterator")

                        -- Save the iterator
                        ItemBotIteratorSave = queueIterator

                        -- Switch to hitting state
                        ItemBotState = 1
                    end
                elseif (ItemBotState == 4) then
                    ItemBotState = -1

                    -- Re-enable the button
                    forms.settext(ExecuteItemBotButtonHandle, "Item Bot")
                end
            end
            
            if (ItemBotState == 1) then
                -- Inject the Z to next state
                toPut = string.sub(toPut,0,25) .. "Z" .. string.sub(toPut,27)
            end
        end
        
        if (toPut ~= "") then
            joypad.setfrommnemonicstr(toPut)
        end
        
    end

    emu.frameadvance()
end