#Requires AutoHotkey v2.0
; divider := 12
divider := (A_ScreenWidth * A_ScreenHeight * 3) / (1920 * 1080) 

Windows := Map()
Rows := []

Options := {}

Options.setHotkey := "^``"
Options.switchHotkey := "!``"
; 1 for MsgBox, 2 for TrayTip, 3 for ToolTip, 4 for None
Options.shout := 2
; Time to hide Tool/TrayTip in ms
Options.tip_timer := 2000
; Extra tooltip to tell the user to press key
Options.extra_tooltips := 1
; Extra tooltip to tell the user what buttons do
Options.extra_extra_tooltips := 1
;1 for small, 2 for medium, 3 for large, 4 for ex large, 5 for too large
Options.gui_size := 2
; Scroll direction
Options.scroll_dir := 0
; current tab of gui
Options.tab := 1

!q::MsgBox A_ScreenWidth . " x " . A_ScreenHeight


sFile := "Cole's_Hot_Windows.sto"
if(FileExist(sFile)){
    temp := FileRead(sFile)
    tempRows := StrSplit(temp, "`n", " `n")
    
        for row in tempRows{
            tempR := StrSplit(row, "`t", " `t`n")
            if(A_Index = 1){
                Options.setHotkey := tempR[1]
                Options.switchHotkey := tempR[2]
                Options.shout := Number(tempR[3])
                Options.tip_timer := Number(tempR[4])
                Options.extra_tooltips := Number(tempR[5])
                Options.extra_extra_tooltips := Number(tempR[6])
                Options.gui_size := Number(tempR[7])
                Options.scroll_dir := Number(tempR[8])
                Options.tab := Number(tempR[9])
                continue
            }
            if tempR.Capacity < 3
                continue
            Windows[tempR[1]] := Map("N", tempR[2], "T" tempR[3], "ID", Number(tempR[4]))
        }
    
    
}

SaveFile(){
    if(FileExist(sFile))
        FileDelete(sFile)
    opts := Options.setHotkey "`t" Options.switchHotkey "`t" Options.shout "`t" Options.tip_timer "`t" Options.extra_tooltips "`t" Options.extra_extra_tooltips "`t" Options.gui_size "`t" Options.scroll_dir "`t" Options.tab "`n"
    FileAppend opts, sFile
    
    for key, window in Windows{
        tempR := key "`t" window["N"] "`t" window["T"] "`t" window["ID"] "`n"
        FileAppend tempR, sFile
    }
}

w := (A_ScreenWidth / divider) + ((A_ScreenWidth / divider) * (Options.gui_size / 2))
h := w * (2/3)

Hotkey Options.setHotkey, HotWinSet
Hotkey Options.switchHotkey, (*) => HotWinSwitch()



; #`::HotWinGetKeys()
; #Esc::HotWinPrint()

<!r::Reload

; Function to Assign window to a key
; If a window is associated with that key, prompt the user if they want to replace it
HotWinSet(*){
    
    assignment := KeyWait("Press the hotkey you want to assign this window to!")
    if(not assignment) 
        Return

    ; Send "|" . assignment . "|"
    a  := ""
    If(window := WinGetTitle("A")){
        If(Windows.Has(assignment)){
            a := MsgBox("The hotkey '" . assignment . "' is already assigned to the window '" . Windows[assignment]["N"] . 
                "'! Do you want to replace it with '" . window . "'?",,"YN")
            if(a = "No"){
                return
            }
        }
        Windows[assignment] := Map("N", window, "T", window, "ID", WinExist(window))
        SaveFile()
        Shout "Active window '" . window . "' has been assigned to the hotkey '" . assignment . "'!"
        if(a){
            For row in Rows{
                if (row["key"] = assignment){
                    row["nameEdit"].Text := window
                }
            }
        }else{
            AddRow(assignment)
        }
            
    }

}

; Function to switch to the window with a key
; Command hotkey activates fn which listens for the next key
; Warn the user if that key is not assigned AND if the window the key is assigned to does not exist
HotWinSwitch(key := "", *){
    search := (key ? key : KeyWait("Press the hotkey for the window you want to switch to!"))
    if(not search) 
        Return
    
    If(not Windows.Has(search)){
        Shout "No window is assigned to the hotkey '" . search . "'!"
        return
    }
    
    window := Windows[search]
    If(not WinExist(window["ID"])){
        if(WinExist(window["T"])){
            window["ID"] := WinExist(window["T"])
            ; Windows[search]["ID"] := WinExist(window["T"])
        }else{
            Shout "The window '" . window["T"] . "' assigned to the hotkey '" . search . "' doesn't seem to exist! You may need to reassign it."
            return
        }
    }

    WinActivate(window["ID"])

}

; Sends the correct shout
Shout(text){
    switch Options.shout{
        Case 1:
            MsgBox text, , "T" Options.tip_timer/1000
        Case 2:
            TrayTip text,, 16
            SetTimer TrayTip, -Options.tip_timer
        Case 3:
            ToolTip text
            SetTimer ToolTip, -Options.tip_timer
        default: 
            return
    }
}

; Shortens inputHook, waits for 1 key and returns
KeyWait(text){
    If(Options.extra_tooltips) 
        ToolTip text
    ih := InputHook("L1 E T5")
    ih.Start()
    ih.Wait()
    ToolTip
    Return ih.Input
}

myGui := Gui()
myGui.SetFont("s" 6 + (2*Options.gui_size))
myGui.Title := "Cole's Hot Windows"
myGui.Show("w" w " h" h)

Tab := myGui.AddTab3("x0 y0 w" w " h" 14 + (4*Options.gui_size), ["Keys", "Options", "Guide"])
Tab.Value := Options.tab
Tab.OnEvent("Change", SwitchTab)

KeysGroup := Gui("Parent" myGui.Hwnd " -Caption AlwaysOnTop")
KeysGroup.SetFont("s" 6 + (2*Options.gui_size))
For key, window in Windows{
    AddRow(key)
}

AddRow(key){
    r := Rows.Length + 1
    Rows.Push(Map())
    Rows[r]["key"] := key

    if(r >1){
        Rows[r-1]["keyButton"].GetPos(&px, &py, &pw, &ph)
    }else{
        py := 0
        ph := 0
    }

    Rows[r]["keyButton"] := KeysGroup.AddButton("x8 y" py+ph+8, key)
    Rows[r]["keyButton"].OnEvent("Click", (*) => UpdateKey(key))
    Rows[r]["keyButton"].GetPos(&kbx,&kby,&kbw,&kbh)
    Rows[r]["keyButton"].ToolTip := "Click to change this window's key!"

    Rows[r]["nameEdit"] := KeysGroup.AddEdit("y" kby " h" kbh " r1.2 x" kbx+kbw+8, Windows[key]["N"])
    Rows[r]["nameEdit"].OnEvent("Change", (*) => UpdateTitle(key, Rows[key]["nameEdit"].Text))
    Rows[r]["nameEdit"].ToolTip := "You can rename this window to better remember it!"
    
    
    Rows[r]["switchButton"] := KeysGroup.AddButton("y" kby, "Switch")
    Rows[r]["switchButton"].OnEvent("Click", (*) => HotWinSwitch(Rows[r]["key"]))
    Rows[r]["switchButton"].ToolTip := "Click switch to this window!"

    Rows[r]["deleteButton"] := KeysGroup.AddButton("y" kby " ", " x ")
    Rows[r]["deleteButton"].OnEvent("Click", (*) => DeleteKey(Rows[r]["key"]))
    Rows[r]["deleteButton"].ToolTip := "Click to delete this hotkey!`nShift + Click to clear all hotkeys!`nAlt+Click to clear all hotkeys for nonexistant windows!"
    
    Rows[r]["deleteButton"].GetPos(&dbx,&dby,&dbw,&dbh)
    Rows[r]["deleteButton"].Move(w-8-dbw)

    Rows[r]["switchButton"].GetPos(&sbx,&sby,&sbw,&sbh)
    Rows[r]["switchButton"].Move(w-8-dbw-8-sbw)

    Rows[r]["nameEdit"].Move(,, w-8-dbw-8-sbw-8 - (kbx+kbw+8))
}

UpdateKey(key, *){
    newKey := KeyWait("Press the hotkey you want to reassign this window to!")

    update := Windows[key]
    Windows[newKey] := update
    Windows.Delete(key)

    For row in Rows{
        if (row["key"] = key){
            row["keyButton"].Text := newKey
            row["key"] := newKey
        }
    }
    SaveFile()
}
UpdateTitle(key, text, *){
    Windows[key]["N"] := text
    SaveFile()
}
DeleteKey(key, *){
    if(GetKeyState("Shift")){
        Windows.Clear()
    }else If(GetKeyState("Alt")){
        for key, window in Windows{
            if(not WinExist(window["ID"])){
                if(WinExist(window["T"])){
                    Windows[key]["ID"] := WinExist(window["T"])
                }else{
                    Windows.Delete(key)
                }
            }
        }
    }else{
        Windows.Delete(key)
    }

    SaveFile()
    Reload
}

On_WM_MOUSEMOVE(wParam, lParam, msg, Hwnd)
{
    static PrevHwnd := 0
    if (Hwnd != PrevHwnd)
    {
        Text := "", ToolTip() ; Turn off any previous tooltip.
        CurrControl := GuiCtrlFromHwnd(Hwnd)
        if CurrControl
        {
            if !CurrControl.HasProp("ToolTip") or not Options.extra_extra_tooltips
                return ; No tooltip for this control.
            Text := CurrControl.ToolTip
            ToolTip(Text)
            SetTimer () => ToolTip(), -Options.tip_timer ; Remove the tooltip.
        }
        PrevHwnd := Hwnd
    }
}
#HotIf WinActive(myGui.Hwnd) and Tab.Value = 1
    WheelUp::Scroll("up")
    WheelDown::Scroll("down")
#HotIf
Scroll(wheel){
    dist := 50
    if((wheel = "down" and not Options.scroll_dir) or (wheel = "up" and Options.scroll_dir)){
        Rows[Rows.Length]["keyButton"].GetPos(&lx, &ly, &lw, &lh)
        if(ly+lh < h-(24+(8*Options.gui_size))){
            dist := 0
        }
        for row in Rows{
            row["keyButton"].GetPos(&ix, &iy, &iw, &ih)
            row["keyButton"].Move(, iy-dist)
            row["nameEdit"].Move(, iy-dist)
            row["switchButton"].Move(, iy-dist)
            row["deleteButton"].Move(, iy-dist)
        }
    }else{
        Rows[1]["keyButton"].GetPos(&fx, &fy, &fw, &fh)
        if(fy > 0){
            dist := 0
        }

        loop Rows.Length{
            row := Rows[Rows.Length - A_Index + 1]
            row["keyButton"].GetPos(&ix, &iy, &iw, &ih)
            row["keyButton"].Move(, iy+dist)
            row["nameEdit"].Move(, iy+dist)
            row["switchButton"].Move(, iy+dist)
            row["deleteButton"].Move(, iy+dist)
        }
    }
}

; Toggle/hold shortcut
; shortcut keys

OptionsGroup := Gui("Parent" myGui.Hwnd " -Caption AlwaysOnTop")
OptionsGroup.SetFont("s" 6 + (2*Options.gui_size))

setHotkeyText := OptionsGroup.AddText("x8 y8", "Shortcut to set a window's hotkey: ")
setHotkeyText.GetPos(&shtx,&shty,&shtw,&shth)
setHotkey := OptionsGroup.AddHotkey("x" shtx+shtw+3+(1*Options.gui_size) " y" shty " w" shtw, Options.setHotkey)
setHotkey.GetPos(&shkx,&shky,&shkw,&shkh)
setWinCheck := OptionsGroup.AddCheckbox("x" shkx+shkw+3+(1*Options.gui_size) " y" shty . (InStr(Options.setHotkey, "#") ? " Checked" : ""), "+ 'Windows' key")
setWinCheck.GetPos(&swcx,&swcy,&swcw,&swch)
setHotkeyButton := OptionsGroup.AddButton("x" swcx+swcw+3+(1*Options.gui_size) " y" shty, "Update")
setHotkeyButton.OnEvent("Click", UpdateSetHotkey)
                                                                                    
switchHotkeyText := OptionsGroup.AddText("x8 y" shty+shth+12+(4*Options.gui_size), "Shortcut to switch to a window:      ")
switchHotkeyText.GetPos(&shtx,&shty,&shtw,&shth)
switchHotkey := OptionsGroup.AddHotkey("x" shtx+shtw+3+(1*Options.gui_size) " y" shty " w" shtw, Options.switchHotkey)
switchHotkey.GetPos(&shkx,&shky,&shkw,&shkh)
switchWinCheck := OptionsGroup.AddCheckbox("x" shkx+shkw+3+(1*Options.gui_size) " y" shty . (InStr(Options.switchHotkey, "#") ? " Checked" : ""), "+ 'Windows' key")
switchWinCheck.GetPos(&swcx,&swcy,&swcw,&swch)
switchHotkeyButton := OptionsGroup.AddButton("x" swcx+swcw+3+(1*Options.gui_size) " y" shty, "Update")
switchHotkeyButton.OnEvent("Click", UpdateSwitchHotkey)

resetHotkeyButton := OptionsGroup.AddButton("x32 y" shty+shth+12+(4*Options.gui_size), "Refresh shortcut inputs")
resetHotkeyButton.ToolTip := "Doesn't actually affect anything just resets the inputs to the current settings."
resetHotkeyButton.OnEvent("Click", resetHotkeyInputs)

shoutRadioText := OptionsGroup.AddText("x8 y" h/2.5, "Notification method (done when a new hotkey is assigned or when errors occur):")
shoutRadioText.GetPos(&srtx,&srty,&srtw,&srth)
shoutRadio1 := OptionsGroup.AddRadio("x8 y" srty+srth+3+(1*Options.gui_size) . (Options.shout = 1 ? " Checked" : ""), "Popup")
shoutRadio1.OnEvent("Click", (*) => UpdateShout(1))
shoutRadio1.GetPos(&sr1x,&sr1y,&sr1w,&sr1h)
shoutRadio2 := OptionsGroup.AddRadio("x" sr1x+sr1w+6+(2*Options.gui_size) " y" sr1y . (Options.shout = 2 ? " Checked" : ""), "Tray Notification")
shoutRadio2.OnEvent("Click", (*) => UpdateShout(2))
shoutRadio2.GetPos(&sr2x,&sr2y,&sr2w,&sr2h)
shoutRadio3 := OptionsGroup.AddRadio("x" sr2x+sr2w+6+(2*Options.gui_size) " y" sr1y . (Options.shout = 3 ? " Checked" : ""), "Tooltip")
shoutRadio3.OnEvent("Click", (*) => UpdateShout(3))
shoutRadio3.GetPos(&sr3x,&sr3y,&sr3w,&sr3h)
shoutRadio4 := OptionsGroup.AddRadio("x" sr3x+sr3w+6+(2*Options.gui_size) " y" sr1y . (Options.shout = 4 ? " Checked" : ""), "None")
shoutRadio4.OnEvent("Click", (*) => UpdateShout(4))

tipTimerEditText := OptionsGroup.AddText("x8 y" sr1y+sr1h+12+(4*Options.gui_size), "Notification sticking length (in milisectionds):")
tipTimerEditText.GetPos(&tttx,&ttty,&tttw,&ttth)
tipTimerEdit := OptionsGroup.AddEdit("x" tttx+tttw+6+(2*Options.gui_size) " y" ttty " w" tttw/4 " Right Number", Options.tip_timer)
tipTimerEdit.OnEvent("Change", SetTTEFocus)
tipTimerEdit.OnEvent("LoseFocus", (*) => UpdateTipTimer(true))
tipTimerEdit.GetPos(&ttex,&ttey,&ttew,&tteh)

extraTipsCheck := OptionsGroup.AddCheckbox("x8 y" ttey+tteh+6+(2*Options.gui_size) . (Options.extra_tooltips ? " Checked" : ""), "  Include extra tooltips (like prompts to press a key).")
extraTipsCheck.OnEvent("Click", UpdateExtraTips)
extraTipsCheck.GetPos(&etcx,&etcy,&etcw,&etch)

extraExtraTipsCheck := OptionsGroup.AddCheckbox("x8 y" etcy+etch+3+(1*Options.gui_size) . (Options.extra_extra_tooltips ? " Checked" : ""), "  Include extra extra tooltips (like what each button does).")
extraExtraTipsCheck.OnEvent("Click", UpdateExtraExtraTips)
extraExtraTipsCheck.GetPos(&etcx,&etcy,&etcw,&etch)

sizeSliderText := OptionsGroup.AddText("x8 y" etcy+etch+12+(4*Options.gui_size), "GUI Size:    1")
sizeSliderText.GetPos(&sstx,&ssty,&sstw,&ssth)
sizeSlider := OptionsGroup.AddSlider("x" sstx+sstw " y" ssty " w" sr1w+sr2w+sr3w+sr3w " Range1-5 ToolTip", Options.gui_size)
sizeSlider.OnEvent("Change", UpdateSize)
sizeSlider.GetPos(&ssx,&ssy,&ssw,&ssh)
sizeSliderEndText := OptionsGroup.AddText("x" ssx+ssw " y" ssy, "5")

scrollDirCheck := OptionsGroup.AddCheckbox("x8 y" ssty+ssth+6+(2*Options.gui_size) . (Options.scroll_dir ? " Checked" : ""), "  Invert Scrolling.")
scrollDirCheck.OnEvent("Click", UpdateScrollDir)


UpdateSetHotkey(*){
    Hotkey Options.setHotkey, HotWinSet, "Off"
    Options.setHotkey := "" . (setWinCheck.Value ? "#" : "") . setHotkey.Value
    Hotkey Options.setHotkey, HotWinSet, "On"
    if(Options.extra_tooltips ){
        Shout "Shortcut to set a window's hotkey updated to '" setHotkey.Value "', then hotkey!"
    }
    
    SaveFile
}

UpdateSwitchHotkey(*){
    Hotkey Options.switchHotkey, (*) => HotWinSwitch(), "Off"
    
    Options.switchHotkey := "" . (switchWinCheck.Value ? "#" : "") . switchHotkey.Value
    Hotkey Options.switchHotkey, (*) => HotWinSwitch(), "On"
    if(Options.extra_tooltips ){
        Shout "Shortcut to switch windows updated to '" switchHotkey.Value "', then hotkey!"
    }
    
    SaveFile
}

resetHotkeyInputs(*){
    setHotkey.Value := Options.setHotkey
    switchHotkey.Value := Options.switchHotkey
}

UpdateShout(opt, *){
    Options.shout := opt
    
    SaveFile
}

Options.tte_focus := 0
SetTTEFocus(*){
    Options.tte_focus := 1
}
UpdateTipTimer(loseFocus := false, *){
    Options.tte_focus := loseFocus ? 0 : Options.tte_focus
    if(tipTimerEdit.Value = Options.tip_timer)
        return
    if(tipTimerEdit.Value < 100 or tipTimerEdit.Value > 60000 or not IsNumber(tipTimerEdit.Value)){
        tipTimerEdit.Value := Options.tip_timer
        ToolTip "Please enter a number between 100 and 60000"
        SetTimer ToolTip, -Options.tip_timer
    }else{
        Options.tip_timer := tipTimerEdit.Value
        if(Options.extra_tooltips ){
            Shout "You just set the notification sticking length to this long!"
        }
        
        SaveFile
    }
}
#HotIf Options.tte_focus = 1
Enter::UpdateTipTimer()
#HotIf

UpdateExtraTips(*){
    Options.extra_tooltips := extraTipsCheck.Value
    
    SaveFile
}
UpdateExtraExtraTips(*){
    Options.extra_extra_tooltips := extraExtraTipsCheck.Value
    Sleep 100
    if(Options.extra_tooltips ){
        Tooltip "You just turned on extra extra tooltips!"
        SetTimer ToolTip, -Options.tip_timer
    } 
    
    SaveFile
}

UpdateSize(*){
    If(Options.gui_size = sizeSlider.Value)
        return
    
    Options.gui_size := sizeSlider.Value
    
    SaveFile
    Reload
}

UpdateScrollDir(*){
    Options.scroll_dir := scrollDirCheck.Value
}

GuideGroup := Gui("Parent" myGui.Hwnd " -Caption AlwaysOnTop")
GuideGroup.SetFont("s" 6 + (2*Options.gui_size))




SwitchTab
OnMessage(0x0200, On_WM_MOUSEMOVE)

SwitchTab(*){
    Options.tab := Tab.Value
    KeysGroup.Hide()
    OptionsGroup.Hide()
    GuideGroup.Hide()
    Switch Tab.Value{
        Case 1:
            KeysGroup.Show("y" 24+(8*Options.gui_size) " w" w " h" h-(24+(8*Options.gui_size)))
        Case 2:
            OptionsGroup.Show("y" 24+(8*Options.gui_size) " w" w " h" h-(24+(8*Options.gui_size)))
        Case 3:
            GuideGroup.Show("y" 24+(8*Options.gui_size) " w" w " h" h-(24+(8*Options.gui_size)))
            
    }

    SaveFile
}