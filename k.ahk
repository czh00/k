#SingleInstance
SendMode Input

If (A_ScriptFullPath = A_LineFile) { ; if run as script rather than included elsewhere - for testing
    Global keyboard := new OSK("dark", "bopomofo")

    ; 設定新的熱鍵 Ctrl+Shift+O 來顯示或隱藏鍵盤
    toggle := ObjBindMethod(keyboard, "toggle")
    Hotkey, ^+O, % toggle 

    keyboard.Show()

    ; 移除舊的 ^Ins 熱鍵
    ; Hotkey, ^Ins, % toggle
}
Return 

; for context sensitive hotkeys
#If, keyboard.Enabled
#If

; 處理點擊事件
HandleOSKClick() {
    if (A_GuiControl = "") {
        return
    }
    
    ; 如果點擊的是按鈕，則傳遞給 Class 處理
    keyboard.HandleOSKClick(A_GuiControl)
    return
}

Class OSK
{

    __New(theme:="dark", layout:="qwerty") {
        this.Enabled := False
        this.current_trans := 1 ; 初始化透明度等級變數

        this.Keys := []
        this.Controls := []
        ; 僅保留左側修飾鍵和特殊鎖定鍵
        this.Modifiers := ["sc02a", "sc01d", "sc05b", "sc038", "sc03a", "ScrollLock"]

        if (theme = "light") {
            this.Background := "FDF6E3"
            this.ButtonColour := "EEE8D5"
            this.ClickFeedbackColour := "0078D7" ; 點擊回饋顏色 (藍色)
            this.ToggledButtonColour := "AC9D58" 
            this.TextColour := "657B83"
            this.ShiftSymbolColour := "87CEEB" ; 淡藍色
            this.SecondLineColour := "FF8C00"  ; 橘色
        }
        else { ; default dark theme
            this.Background := "2A2A2E"
            this.ButtonColour := "010409" ; 深黑色
            this.ClickFeedbackColour := "0078D7" 
            this.ToggledButtonColour := "553b6a" 
            this.TextColour := "ffffff"
            this.ShiftSymbolColour := "ADD8E6" ; 淡藍色
            this.SecondLineColour := "FFA500"  ; 橘色
        }

        this.MonitorKeyPresses := ObjBindMethod(this, "MonitorAllKeys") 
        
        ; 標準鍵盤每行第一個鍵的 X 座標偏移量
        this.RowStartOffsets := {}
        this.RowStartOffsets[2] := 0      ; Row 2 (數字行)
        this.RowStartOffsets[3] := 0      ; Row 3 (QWERTY 行)
        this.RowStartOffsets[4] := 0      ; Row 4 (ASDFG 行)
        this.RowStartOffsets[5] := 0      ; Row 5 (ZXCVB 行)
        this.RowStartOffsets[6] := 0      ; Row 6 (Ctrl 行)

        this.Layout := []

        if (layout = "bopomofo") {
            
            StdKey := 45 ; 標準鍵寬
            
            ; 【Row 1】功能鍵：將 Close (sc053) 改為 Hide
            this.Layout.Push([ ["sc001", StdKey], ["Move", 550], ["Transparent"], ["Hide", StdKey] ]) ; 將 Close 替換為 Hide
            
            ; 【Row 2】數字列
            this.Layout.Push([ ["sc029", StdKey],["sc002", StdKey],["sc003", StdKey],["sc004", StdKey],["sc005", StdKey],["sc006", StdKey],["sc007", StdKey],["sc008", StdKey],["sc009", StdKey],["sc00a", StdKey],["sc00b", StdKey],["sc00c", StdKey],["sc00d", StdKey],["sc00e", 63] ]) ; sc00e=BS
            
            ; 【Row 3】QWERTY 列
            this.Layout.Push([ ["sc00f", 67.5],["sc010", StdKey],["sc011", StdKey],["sc012", StdKey],["sc013", StdKey],["sc014", StdKey],["sc015", StdKey],["sc016", StdKey],["sc017", StdKey],["sc018", StdKey],["sc019", StdKey],["sc01a", StdKey],["sc01b", StdKey],["sc02b", 41] ]) ; sc00f=Tab, sc02b=\

            ; 【Row 4】ASDFG 列
            this.Layout.Push([ ["sc03a", 90],["sc01e", StdKey],["sc01f", StdKey],["sc020", StdKey],["sc021", StdKey],["sc022", StdKey],["sc023", StdKey],["sc024", StdKey],["sc025", StdKey],["sc026", StdKey],["sc027", StdKey],["sc028", StdKey],["sc01c", 67] ]) ; sc03a=CapsLock, sc01c=Enter
            
            ; 【Row 5】 ZXCVB 列 - Up (sc048)
            this.Layout.Push([ ["sc02a", 112.5],["sc02c", StdKey],["sc02d", StdKey],["sc02e", StdKey],["sc02f", StdKey],["sc030", StdKey],["sc031", StdKey],["sc032", StdKey],["sc033", StdKey],["sc034", StdKey],["sc035", StdKey], ["sc048", 45], ["sc053", 44.5] ]) 
            
            ; 【Row 6】 LCtrl/LWin/LAlt/Space/箭頭鍵
            this.Layout.Push([ ["sc01d", 60], ["sc05b", 60], ["sc038", 60], ["sc039", 360], ["sc04b", 45], ["sc050", 45], ["sc04d", 45] ]) ; LCtrl, LWin, LAlt, Space, placeholder (45), Left, Down, Right
            
            ; --- 按鍵顯示文字 (鍵名已替換為掃描碼) ---
            this.PrettyName := {} 
            this.PrettyName["Move"]        := "移動"
            this.PrettyName["Transparent"] := "透明"
            this.PrettyName["Hide"]        := "隱藏" ; 將 Close 替換為 Hide
            this.PrettyName["placeholder"] := "" ; 佔位符，不顯示文字
            
            ; --- 修飾鍵和特殊功能鍵 (使用掃描碼) ---
            this.PrettyName["sc001"]       := "Esc"       
            this.PrettyName["sc00e"]       := "BS"       ; Backspace
            this.PrettyName["sc00f"]       := "Tab"       
            this.PrettyName["sc03a"]       := "Caps Lock" 
            this.PrettyName["sc01c"]       := "Enter"     
            this.PrettyName["sc02a"]       := "Shift"     ; LShift
            this.PrettyName["sc036"]       := "Shift"     ; RShift <-- 新增 RShift (但未在佈局中)
            this.PrettyName["sc01d"]       := "Ctrl"      ; LCtrl
            this.PrettyName["sc05b"]       := "Win"       ; LWin
            this.PrettyName["sc038"]       := "Alt"       ; LAlt
            this.PrettyName["sc039"]       := "Space"     ; Space (顯示 Space)
            this.PrettyName["sc048"]       := "↑"         ; sc048=Up
            this.PrettyName["sc050"]       := "↓"         ; sc050=Down
            this.PrettyName["sc04b"]       := "←"         ; sc04b=Left
            this.PrettyName["sc04d"]       := "→"         ; sc04d=Right
            this.PrettyName["sc053"]       := "Del"       
            
            ; --- 數字/符號/注音鍵 --- (內容與前版相同)
            this.PrettyName["sc029"]       := "`` ~"
            this.PrettyName["sc002"]       := "1 ! ㄅ"
            this.PrettyName["sc003"]       := "2 @ ㄉ"
            this.PrettyName["sc004"]       := "3 # ˇ"
            this.PrettyName["sc005"]       := "4 $ ˋ"
            this.PrettyName["sc006"]       := "5 % ㄓ"
            this.PrettyName["sc007"]       := "6 ^ ˊ"
            this.PrettyName["sc008"]       := "7 && ˙"
            this.PrettyName["sc009"]       := "8 * ㄚ"
            this.PrettyName["sc00a"]       := "9 ( ㄞ"
            this.PrettyName["sc00b"]       := "0 ) ㄢ"
            this.PrettyName["sc00c"]       := "- _ ㄦ"
            this.PrettyName["sc00d"]       := "= +"
            
            ; --- QWERTY 列 ---
            this.PrettyName["sc010"]       := "Q ㄆ"
            this.PrettyName["sc011"]       := "W ㄊ"
            this.PrettyName["sc012"]       := "E ㄍ"
            this.PrettyName["sc013"]       := "R ㄐ"
            this.PrettyName["sc014"]       := "T ㄔ"
            this.PrettyName["sc015"]       := "Y ㄗ"
            this.PrettyName["sc016"]       := "U ㄧ"
            this.PrettyName["sc017"]       := "I ㄛ"
            this.PrettyName["sc018"]       := "O ㄟ"
            this.PrettyName["sc019"]       := "P ㄣ"
            this.PrettyName["sc01a"]       := "[ {"
            this.PrettyName["sc01b"]       := "] }"
            this.PrettyName["sc02b"]       := "\ |"
            
            ; --- ASDFG 列 ---
            this.PrettyName["sc01e"]       := "A ㄇ"
            this.PrettyName["sc01f"]       := "S ㄋ"
            this.PrettyName["sc020"]       := "D ㄎ"
            this.PrettyName["sc021"]       := "F ㄑ"
            this.PrettyName["sc022"]       := "G ㄕ"
            this.PrettyName["sc023"]       := "H ㄘ"
            this.PrettyName["sc024"]       := "J ㄨ"
            this.PrettyName["sc025"]       := "K ㄜ"
            this.PrettyName["sc026"]       := "L ㄠ"
            this.PrettyName["sc027"]       := "; : ㄤ" 
            this.PrettyName["sc028"]       := "' """ 
            
            ; --- ZXCVB 列 ---
            this.PrettyName["sc02c"]       := "Z ㄈ"
            this.PrettyName["sc02d"]       := "X ㄌ"
            this.PrettyName["sc02e"]       := "C ㄏ"
            this.PrettyName["sc02f"]       := "V ㄒ"
            this.PrettyName["sc030"]       := "B ㄖ"
            this.PrettyName["sc031"]       := "N ㄙ"
            this.PrettyName["sc032"]       := "M ㄩ"
            this.PrettyName["sc033"]       := ", < ㄝ" 
            this.PrettyName["sc034"]       := ". > ㄡ" 
            this.PrettyName["sc035"]       := "/ ? ㄥ" 
        }
        this.Make()
    }

    SetTimer(TimerID, Period) {
        Timer := this[TimerID]
        SetTimer % Timer, % Period
        return
    }

    Make() {
        ScaleFactor := 1.5
        ButtonHeight := Round(30 * ScaleFactor)
        KeySpacing := Round(2 * ScaleFactor)
        StandardWidth := Round(45 * ScaleFactor)
        
        CurrentY := Round(10 * ScaleFactor) 
        MarginLeft := Round(10 * ScaleFactor)
        
        Gui, OSK: +AlwaysOnTop -DPIScale +Owner -Caption +E0x08000000 
        Gui, OSK: Font, s12, Microsoft JhengHei UI 
        Gui, OSK: Margin, 0, 0
        Gui, OSK: Color, % this.Background

        For Index, Row in this.Layout {
            
            X_Offset_Units := this.RowStartOffsets.HasKey(Index) ? this.RowStartOffsets[Index] : 0
            CurrentX := MarginLeft + Round(X_Offset_Units * StandardWidth) 
            
            if (Index > 1) {
                CurrentY += ButtonHeight + KeySpacing
            }
            
            For i, Button in Row {
                Width := Round((Button.2 ? Button.2 : 45) * ScaleFactor)
                HorizontalSpacing := Round((Button.3 ? Button.3 : KeySpacing) * ScaleFactor)
                
                ; 檢查是否為佔位符鍵
                KeyText := Button.1
                isPlaceholder := (KeyText = "placeholder")
                
                ; 僅在不是佔位符鍵時才繪製按鈕，否則只用它來增加 CurrentX
                if (!isPlaceholder) {
                    AbsolutePosition := "x" CurrentX " y" CurrentY
                    
                    ; 1. 繪製底層按鍵與邊框
                    Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " Background" this.ButtonColour " hwndbottomt gHandleOSKClick", % KeyText
                    ; Progress Bar 作為邊框 (在 Text 上方)
                    Gui, OSK:Add, Progress, % "xp yp w" Width " h" ButtonHeight " Background" this.ButtonColour " hwndborder", 100
                    GuiControl, % "OSK: +C" this.ButtonColour, % border

                    ; 2. 根據文字內容決定顯示方式與顏色
                    DisplayText := this.PrettyName.HasKey(KeyText) ? this.PrettyName[KeyText] : KeyText
                    parts := StrSplit(DisplayText, A_Space)
                    
                    ; 檢查是否為必須單色居中的控制鍵 (例如: Caps Lock, Enter, Shift)
                    IsControlKey := (KeyText = "sc001" or KeyText = "sc00e" or KeyText = "sc00f" 
                                  or KeyText = "sc03a" or KeyText = "sc01c" or KeyText = "sc02a" 
                                  or KeyText = "sc036" or KeyText = "sc01d" or KeyText = "sc05b" 
                                  or KeyText = "sc038" or KeyText = "sc039" or KeyText = "sc053" 
                                  or KeyText = "sc048" or KeyText = "sc050" or KeyText = "sc04b" 
                                  or KeyText = "sc04d" or KeyText = "Move" or KeyText = "Transparent" 
                                  or KeyText = "Hide") ; 關閉鍵改為 Hide
                                  
                    labels := [] 
                    BopomofoChars := "ㄅㄆㄇㄈㄉㄊㄋㄌㄍㄎㄏㄐㄑㄒㄓㄔㄕㄖㄗㄘㄙㄧㄨㄩㄚㄛㄜㄝㄞㄟㄠㄡㄢㄣㄤㄥㄦˊˇˋ˙"
                    
                    ; --- 計算文字區塊的絕對座標和尺寸 ---
                    TL_X := CurrentX + KeySpacing
                    TL_Y := CurrentY + KeySpacing
                    BR_Y := CurrentY + (ButtonHeight / 2)
                    Full_Text_W := Width - KeySpacing * 2 ; 內容區的寬度
                    Text_H := (ButtonHeight / 2) - KeySpacing * 2 ; 上半部或下半部的高度

                    if (IsControlKey) {
                        ; 情況 1: 控制鍵 (例如 "Esc", "Tab", "Space", "Caps Lock", "Hide") - 永遠單色居中
                        ; 即使 DisplayText 包含空格，也應視為單一標籤
                        Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " Center BackgroundTrans c" this.TextColour " hwndh", % DisplayText
                        labels.Push(h)
                    } else if (parts.Length() = 1 and parts[1] != "") {
                        ; 情況 2: 單純單字元 (例如 A, M) - 這裏通常不會走到，因為字母都有注音
                        Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " Center BackgroundTrans c" this.TextColour " hwndh", % parts[1]
                        labels.Push(h)
                    } else if (parts.Length() = 2) {
                        isBopomofo := InStr(BopomofoChars, parts[2])
                        
                        if (isBopomofo) {
                            ; 情況 3a: 字母 + 注音 (e.g., "Q ㄆ"). 保持上下居中分行。
                            topColour := this.TextColour
                            bottomColour := this.SecondLineColour
                            
                            ; 上方文字 (居中, QWERTY字符)
                            Gui, OSK:Add, Text, % "x" TL_X " y" TL_Y " w" Full_Text_W " h" Text_H " Center BackgroundTrans c" topColour " hwndh", % parts[1]
                            labels.Push(h)
                            ; 下方文字 (注音)
                            Gui, OSK:Add, Text, % "x" TL_X " y" BR_Y " w" Full_Text_W " h" Text_H " Center BackgroundTrans c" bottomColour " hwndh", % parts[2]
                            labels.Push(h)
                        } else {
                            ; 情況 3b: 符號 + Shift符號 (e.g., "`` ~", "[ {"). 調整為白色/淺藍色靠上並排。
                            ; 左上: 基本字元 (靠左對齊, 白色)
                            Gui, OSK:Add, Text, % "x" TL_X " y" TL_Y " w" (Width/2 - KeySpacing) " h" Text_H " Left BackgroundTrans c" this.TextColour " hwndh", % parts[1]
                            labels.Push(h)
                            ; 右上: Shift 符號 (靠右對齊, 淺藍色). 從按鍵中間開始繪製，佔據右半邊
                            Gui, OSK:Add, Text, % "x" (CurrentX + Width/2) " y" TL_Y " w" (Width/2 - KeySpacing) " h" Text_H " Right BackgroundTrans c" this.ShiftSymbolColour " hwndh", % parts[2]
                            labels.Push(h)
                        }
                    } else if (parts.Length() >= 3) {
                        ; 情況 4: 有三個文字 (例如 "1 ! ㄅ")
                        
                        ; 1. 白色字 (基本字元): 左上角 (Top-Left)
                        Gui, OSK:Add, Text, % "x" TL_X " y" TL_Y " w" Full_Text_W " h" Text_H " BackgroundTrans c" this.TextColour " Left hwndh", % parts[1]
                        labels.Push(h)
                        
                        ; 2. 淺藍色字 (Shift 符號): 右上角 (Top-Right)
                        Gui, OSK:Add, Text, % "x" TL_X " y" TL_Y " w" Full_Text_W " h" Text_H " BackgroundTrans c" this.ShiftSymbolColour " Right hwndh", % parts[2]
                        labels.Push(h)
                        
                        ; 3. 橘色字 (注音): 右下角 (Bottom-Right)
                        Gui, OSK:Add, Text, % "x" TL_X " y" BR_Y " w" Full_Text_W " h" Text_H " BackgroundTrans c" this.SecondLineColour " Right hwndh", % parts[3]
                        labels.Push(h)
                    } else {
                        ; 備用情況
                        Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " hwndh",
                        labels.Push(h)
                    }
                    
                    this.Keys[KeyText] := [Index, i]
                    this.Controls[Index, i] := {Progress: border, Labels: labels, Bottom: bottomt, Colour: this.ButtonColour}
                }
                
                ; 更新下一按鍵的起始 X 座標 (無論是否為佔位符)
                CurrentX += Width + HorizontalSpacing
            }
        }
        Return
    }
    
    ; ... (以下為與佈局無關的方法，保持不變) ...

    Show() {
        this.Enabled := True
        CurrentMonitorIndex := this.GetCurrentMonitorIndex()
        DetectHiddenWindows On
        Gui, OSK: +LastFound
        Gui, OSK:Show, Hide
        GUI_Hwnd := WinExist()
        this.GetClientSize(GUI_Hwnd,GUI_Width,GUI_Height)
        DetectHiddenWindows Off
        
        SysGet, MonWA, MonitorWorkArea, %CurrentMonitorIndex%
        
        GUI_X := ((MonWARight - MonWALeft - GUI_Width) / 2) + MonWALeft
        
        GUI_Y := MonWABottom - GUI_Height
        
        Gui, OSK:Show, % "x" GUI_X " y" GUI_Y " NA", 螢幕鍵盤
        this.SetTimer("MonitorKeyPresses", 30)
        Return
    }
    
    Hide() {
        this.Enabled := False
        Gui, OSK: Hide
        this.SetTimer("MonitorKeyPresses", "off")
        return
    }

    Toggle() {
        If this.Enabled
            this.Hide()
        Else
            this.Show()
        Return
    }
    
    ToggleTransparent() {
        trans_levels := [255, 220, 180]
        this.current_trans := Mod(this.current_trans, trans_levels.Length()) + 1
        WinSet, Transparent, % trans_levels[this.current_trans], 螢幕鍵盤
    }

    GetCurrentMonitorIndex() {
        CoordMode, Mouse, Screen
        MouseGetPos, mx, my
        SysGet, monitorsCount, 80
        Loop %monitorsCount%{
            SysGet, monitor, Monitor, %A_Index%
            if (monitorLeft <= mx && mx <= monitorRight && monitorTop <= my && my <= monitorBottom)
                Return A_Index
        }
        Return 1
    }

    GetClientSize(hwnd, ByRef w, ByRef h) {
        VarSetCapacity(rc, 16)
        DllCall("GetClientRect", "uint", hwnd, "uint", &rc)
        w := NumGet(rc, 8, "int")
        h := NumGet(rc, 12, "int")
        Return
    }

    HandleOSKClick(Key:="") {
        if not Key
            Key := A_GuiControl

        ; 忽略透明佔位符鍵的點擊
        if (Key = "placeholder") {
            Return
        }

        ; 處理 Move, Transparent, Hide 等內部功能鍵
        if (Key = "Move") {
            PostMessage, 0xA1, 2
            Return
        } else if (Key = "Transparent") {
            this.ToggleTransparent()
            Return
        } else if (Key = "Hide") { ; 點擊 Hide 時隱藏鍵盤
            this.Hide()
            Return
        }
        
        ; 複合鍵 (如 LShift/sc02a, LCtrl/sc01d) 會被送給 SendModifier 進行狀態切換（鎖定/解鎖）
        if (this.IsModifier(Key))
            this.SendModifier(Key)
        ; 普通鍵則送給 SendPress 進行單次按鍵輸入
        else
            this.SendPress(Key)
        return
    }

    IsModifier(Key) {
        ; 檢查 Key 是否為複合鍵（鎖定鍵）
        return (Key = "sc02a"    ; LShift
             or Key = "sc036"    ; RShift <-- 新增 RShift
             or Key = "sc01d"    ; LCtrl
             or Key = "sc05b"    ; LWin
             or Key = "sc038"    ; LAlt
             or Key = "sc03a"    ; CapsLock
             or Key = "ScrollLock")
    }

    MonitorAllKeys() {
        For _, Row in this.Layout {
            For i, Button in Row {
                ; 跳過佔位符鍵
                if (Button.1 = "placeholder")
                    continue
                
                if (this.Keys.HasKey(Button.1))
                    this.MonitorKey(Button.1)
            }
        }
        Return
    }

    MonitorKey(Key) {
        ; 檢查按鍵的狀態 (是否被鎖定/按下)。sc03a (CapsLock) 和 ScrollLock 使用 T 狀態。
        KeyOn := GetKeyState(Key, (Key = "sc03a" or Key = "ScrollLock" or Key = "Pause") ? "T" : "")
        
        if (!this.Keys.HasKey(Key))
            return

        KeyRow := this.Keys[Key][1]
        KeyColumn := this.Keys[Key][2]
        
        CurrentColour := this.Controls[KeyRow, KeyColumn].Colour
        NewColour := ""

        ; 如果按鍵被按下/鎖定，且顏色不是鎖定色，則變更為鎖定色
        if (KeyOn and CurrentColour != this.ToggledButtonColour)
            NewColour := this.ToggledButtonColour
        ; 如果按鍵未被按下/鎖定，且顏色是鎖定色，則變更為預設色
        else if (not KeyOn and CurrentColour = this.ToggledButtonColour)
            NewColour := this.ButtonColour
        
        if (NewColour)
            this.UpdateGraphics(this.Controls[KeyRow, KeyColumn], NewColour)

        Return
    }

    SendPress(Key) {
        KeyRow := this.Keys[Key][1]
        KeyCol := this.Keys[Key][2]
        
        this.UpdateGraphics(this.Controls[KeyRow, KeyCol], this.ClickFeedbackColour)
        
        ; 傳送按鍵。
        SendInput, % "{Blind}{" Key "}"

        Sleep, 100
        this.UpdateGraphics(this.Controls[KeyRow, KeyCol], this.ButtonColour)
        Return
    }

    SendModifier(Key) {
        ; 處理 CapsLock (sc03a) 和 ScrollLock 的切換
        if (Key = "sc03a") ; CapsLock
            SetCapsLockState, % not GetKeyState(Key, "T")
        else if (Key = "ScrollLock")
            SetScrollLockState, % not GetKeyState(Key, "T")
        ; 處理其他複合鍵的切換（鎖定/解鎖）
        else {
            if (GetKeyState(Key))
                SendInput, % "{" Key " up}" ; 如果鍵已按下，則送出釋放
            else
                SendInput, % "{" Key " down}" ; 如果鍵未按下，則送出按下（鎖定）
        }
        return
    }

    UpdateGraphics(Obj, Colour){
        GuiControl, % "OSK: +C" Colour, % Obj.Progress
        GuiControl, % "OSK: +Background" Colour, % Obj.Bottom 
        GuiControl, OSK: +Redraw, % Obj.Progress
        For _, hwnd in Obj.Labels
            GuiControl, OSK: +Redraw, % hwnd
        Obj.Colour := Colour
        Return
    }
}
