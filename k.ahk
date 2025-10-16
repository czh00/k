; ======================================================================================================================
; Script:           On-Screen Keyboard (螢幕小鍵盤)
; Language:         AutoHotkey v1.1
; Author:           (原始作者未知，由 Gem Gemini AI 整理與修改)
; Description:      一個可自訂主題、可縮放、支援中英切換的螢幕小鍵盤。
;
; ----------------------------------------------------------------------------------------------------------------------
; § 功能特性 (Features)
; ----------------------------------------------------------------------------------------------------------------------
;   - 主題與外觀:
;     - 深色主題 (顏色可在 §3 的 __New 方法中透過變數自訂)。
;     - 可透過按鈕調整鍵盤的縮放大小與透明度。
;     - 支援視窗拖動。
;
;   - 鍵盤佈局與輸入法:
;     - 支援 QWERTY (英文) 與 Bopomofo (注音) 兩種鍵盤佈局切換。
;     - 按下實體鍵盤時，螢幕鍵盤會同步顯示按鍵狀態 (例如 Ctrl, Shift 按下時會變色)。
;
;   - 系統整合:
;     - 提供系統匣圖示，可快速顯示/隱藏、重置位置或離開程式。
;
; ----------------------------------------------------------------------------------------------------------------------
; § 熱鍵綁定 (Hotkeys - For Physical Keyboard)
; ----------------------------------------------------------------------------------------------------------------------
;   - Ctrl + Shift + O  : 顯示 / 隱藏螢幕鍵盤。
;   - Shift (單獨釋放)  : 切換 QWERTY / Bopomofo 佈局，並送出 Shift 訊號切換系統輸入法。
;   - Ctrl + Space      : (保留功能) 切換佈局，主要為相容微軟注音等特定輸入法。
;
; ----------------------------------------------------------------------------------------------------------------------
; § 螢幕鍵盤按鈕功能 (On-Screen Keyboard Button Functions)
; ----------------------------------------------------------------------------------------------------------------------
;   - [ㄅ/En]           : 切換鍵盤的顯示佈局 (注音/英文)，同時送出 `Shift` 訊號以切換系統目前的輸入法。
;   - [Ctrl] + [ㄅ/En]  : (先點擊OSK上的Ctrl，再點擊ㄅ/En) 只切換螢幕鍵盤的顯示佈局，不影響系統輸入法。
;                         此功能用於當OSK狀態與系統不一致時，手動進行同步。
;   - [⊖] / [⊕]         : 縮小 / 放大 鍵盤尺寸。
;   - [↺]               : 將鍵盤尺寸重置為預設大小。
;   - [◌]               : 循環切換四種不同的透明度等級。
;   - [✕]               : 關閉螢幕鍵盤程式 (會跳出確認視窗)。
;   - [⇲]               : 隱藏鍵盤視窗 (等同於按 Ctrl+Shift+O)。
; ======================================================================================================================

; ======================================================================================================================
; §1. 腳本初始化與全域設定 (Script Initialization & Global Settings)
; ======================================================================================================================

#SingleInstance
SendMode Input

; --- 主要啟動區塊 ---
If (A_ScriptFullPath = A_LineFile) { 
    ; 建立 OSK 物件的實例，並將其設為全域變數
    Global keyboard := new OSK("dark", "qwerty")

    ; --- 系統匣圖示右鍵選單設定 (Tray Menu Configuration) ---
    Menu, Tray, NoStandard        ; 移除所有預設的選單項目
    Menu, Tray, Add, 顯示/隱藏, ToggleTrayHandler 
    Menu, Tray, Add, 重置位置, ResetHandler         
    Menu, Tray, Add, 離開, ExitHandler          
    Menu, Tray, Default, 顯示/隱藏 ; 設定左鍵點擊的預設動作
    Menu, Tray, Click, 1                      
    Menu, Tray, Tip, 螢幕鍵盤 (Ctrl+Shift+O) ; 設定滑鼠懸停時的提示文字

    ; --- 熱鍵設定 (Hotkey Definitions) ---
    ; 綁定 Ctrl+Shift+O 來顯示/隱藏鍵盤
    toggle := ObjBindMethod(keyboard, "toggle")
    Hotkey, ^+O, % toggle 

    ; 綁定 Ctrl+Space 來切換佈局 (保留)
    toggleLayout := ObjBindMethod(keyboard, "ToggleLayout")
    Hotkey, ~$^Space, % toggleLayout

    ; --- 使用 Shift 鍵釋放來切換佈局 ---
    Hotkey, ~LShift Up, HandleShiftRelease
    Hotkey, ~RShift Up, HandleShiftRelease

    ; --- 視窗訊息監聽 (Window Message Monitoring) ---
    ; 監聽滑鼠左鍵點擊訊息，用於實現無邊框視窗的拖動
    OnMessage(0x201, "HandleBackgroundClick")

    ; 初始顯示鍵盤
    keyboard.Show()
}
Return ; 結束自動執行區段。

; --- 處理實體 Shift 鍵釋放事件 ---
HandleShiftRelease:
    ; 確保這是一個單獨的 Shift 鍵釋放動作，而不是組合鍵的一部分
    if (A_PriorKey = "LShift" or A_PriorKey = "RShift")
    {
        if (keyboard.Enabled) {
            keyboard.ToggleLayout()
        }
    }
    return

; ======================================================================================================================
; §2. 事件處理函式與標籤 (Event Handlers & Labels)
; ======================================================================================================================

; --- 系統匣選單處理函式 (Tray Menu Handlers) ---
ToggleTrayHandler:
    keyboard.toggle()
    return

ResetHandler:
    Reload ; 重新載入腳本，所有狀態和位置都會恢復到初始設定
    return

ExitHandler:
    ExitApp
    return

; --- GUI 背景點擊處理 (Background Click Handler) ---
HandleBackgroundClick(wParam, lParam, msg, hwnd) {
    Gui, OSK: +LastFound
    ; 如果點擊的是鍵盤的背景 (而非按鈕)
    if (hwnd = WinExist()) {
        MouseGetPos, , , , clicked_control
        if (clicked_control = "") {
            ; 傳送一個模擬的標題列點擊訊息，觸發系統的視窗移動功能
            PostMessage, 0xA1, 2
        }
    }
}

; --- 語境敏感熱鍵區段 (Context-sensitive Hotkeys) ---
#If (keyboard.Enabled) 
#If 

; --- OSK 按鈕點擊處理 (OSK Button Click Handler) ---
HandleOSKClick() {
    ; A_GuiControl 是一個內建變數，會回傳被點擊的控制項名稱 (在此即為按鍵的掃描碼)
    keyboard.HandleOSKClick(A_GuiControl)
    return
}

; ======================================================================================================================
; §3. OSK 類別定義 (The OSK Class Definition)
; ======================================================================================================================
Class OSK
{
    LayoutMode := ""
    
    __New(theme:="dark", layout:="qwerty") {
        this.Enabled := False
        this.current_trans := 1
        this.ScaleFactor := 1.5
        this.CurrentX := ""
        this.CurrentY := ""
        
        this.Modifiers := ["sc01d", "sc05b", "sc038", "sc03a", "ScrollLock"]
        
        ; --- 顏色主題設定 ---
        this.Background := "2A2A2A"
        this.ButtonColour := "010101"
        this.ClickFeedbackColour := "0078D7"
        this.ToggledButtonColour := "553b6a"
        this.TextColour := "ffffff"
        this.ShiftSymbolColour := "ADD8E6"
        this.SecondLineColour := "FFA500"

        this.WhiteSymbolKeysList := "|sc029|sc00d|sc01a|sc01b|sc02b|sc028|"

        this.MonitorKeyPresses := ObjBindMethod(this, "MonitorAllKeys") 
        
        this.RowStartOffsets := {}
        this.RowStartOffsets[2] := 0
        this.RowStartOffsets[3] := 0
        this.RowStartOffsets[4] := 0
        this.RowStartOffsets[5] := 0
        this.RowStartOffsets[6] := 0

        this.Layout := []
        this.BopomofoNames := {}
        this.QwertyNames := {}
        this.LayoutMode := layout
        
        StdKey := 45

        ; --- 鍵盤佈局定義 (掃描碼, 寬度) ---
        this.Layout.Push([ ["sc001", StdKey], ["placeholder", 306], ["ToggleLayout", StdKey], ["ZoomOut", StdKey], ["ZoomIn", StdKey], ["Reset", StdKey], ["Transparent"], ["Close", StdKey], ["Hide", StdKey] ]) 
        this.Layout.Push([ ["sc029", StdKey],["sc002", StdKey],["sc003", StdKey],["sc004", StdKey],["sc005", StdKey],["sc006", StdKey],["sc007", StdKey],["sc008", StdKey],["sc009", StdKey],["sc00a", StdKey],["sc00b", StdKey],["sc00c", StdKey],["sc00d", StdKey],["sc00e", 63] ])
        this.Layout.Push([ ["sc00f", 67.5],["sc010", StdKey],["sc011", StdKey],["sc012", StdKey],["sc013", StdKey],["sc014", StdKey],["sc015", StdKey],["sc016", StdKey],["sc017", StdKey],["sc018", StdKey],["sc019", StdKey],["sc01a", StdKey],["sc01b", StdKey],["sc02b", 41] ])
        this.Layout.Push([ ["sc03a", 90],["sc01e", StdKey],["sc01f", StdKey],["sc020", StdKey],["sc021", StdKey],["sc022", StdKey],["sc023", StdKey],["sc024", StdKey],["sc025", StdKey],["sc026", StdKey],["sc027", StdKey],["sc028", StdKey],["sc01c", 67] ])
        this.Layout.Push([ ["sc02a", 112.5],["sc02c", StdKey],["sc02d", StdKey],["sc02e", StdKey],["sc02f", StdKey],["sc030", StdKey],["sc031", StdKey],["sc032", StdKey],["sc033", StdKey],["sc034", StdKey],["sc035", StdKey], ["sc048", 45], ["sc053", 44.5] ]) 
        this.Layout.Push([ ["sc01d", 60], ["sc05b", 60], ["sc038", 60], ["sc039", 360], ["sc04b", 45], ["sc050", 45], ["sc04d", 45] ]) 
        
        ; --- 按鍵顯示文字定義 ---
        SharedNames := {}
        SharedNames["Transparent"] := "◌"
        SharedNames["Close"]       := "✕"
        SharedNames["Hide"]        := "⇲"
        SharedNames["ZoomOut"]     := "⊖"
        SharedNames["ZoomIn"]      := "⊕"
        SharedNames["Reset"]       := "↺"
        SharedNames["placeholder"] := ""
        SharedNames["sc001"]       := "Esc"
        SharedNames["sc00e"]       := "←"
        SharedNames["sc00f"]       := "Tab"
        SharedNames["sc03a"]       := "⇭"
        SharedNames["sc01c"]       := "↩"
        SharedNames["sc02a"]       := "Shift"
        SharedNames["sc036"]       := "Shift"
        SharedNames["sc01d"]       := "Ctrl"
        SharedNames["sc05b"]       := "Win"
        SharedNames["sc038"]       := "Alt"
        SharedNames["sc039"]       := "Space"
        SharedNames["sc048"]       := "↑"
        SharedNames["sc050"]       := "↓"
        SharedNames["sc04b"]       := "←"
        SharedNames["sc04d"]       := "→"
        SharedNames["sc053"]       := "Del"
        
        ; --- 注音佈局的按鍵文字 ---
        BopomofoSpecificNames := SharedNames.Clone()
        BopomofoSpecificNames["sc029"]       := "`` ~"
        BopomofoSpecificNames["sc002"]       := "1 ! ㄅ"
        BopomofoSpecificNames["sc003"]       := "2 @ ㄉ"
        BopomofoSpecificNames["sc004"]       := "3 # ˇ"
        BopomofoSpecificNames["sc005"]       := "4 $ ˋ"
        BopomofoSpecificNames["sc006"]       := "5 % ㄓ"
        BopomofoSpecificNames["sc007"]       := "6 ^ ˊ"
        BopomofoSpecificNames["sc008"]       := "7 && ˙"
        BopomofoSpecificNames["sc009"]       := "8 ( ㄚ"
        BopomofoSpecificNames["sc00a"]       := "9 ) ㄞ"
        BopomofoSpecificNames["sc00b"]       := "0 ) ㄢ"
        BopomofoSpecificNames["sc00c"]       := "- _ ㄦ"
        BopomofoSpecificNames["sc00d"]       := "= +"
        BopomofoSpecificNames["sc010"]       := "ㄆ"
        BopomofoSpecificNames["sc011"]       := "ㄊ"
        BopomofoSpecificNames["sc012"]       := "ㄍ"
        BopomofoSpecificNames["sc013"]       := "ㄐ"
        BopomofoSpecificNames["sc014"]       := "ㄔ"
        BopomofoSpecificNames["sc015"]       := "ㄗ"
        BopomofoSpecificNames["sc016"]       := "ㄧ"
        BopomofoSpecificNames["sc017"]       := "ㄛ"
        BopomofoSpecificNames["sc018"]       := "ㄟ"
        BopomofoSpecificNames["sc019"]       := "ㄣ"
        BopomofoSpecificNames["sc01a"]       := "[ {"
        BopomofoSpecificNames["sc01b"]       := "] }"
        BopomofoSpecificNames["sc02b"]       := "\ |"
        BopomofoSpecificNames["sc01e"]       := "ㄇ"
        BopomofoSpecificNames["sc01f"]       := "ㄋ"
        BopomofoSpecificNames["sc020"]       := "ㄎ" 
        BopomofoSpecificNames["sc021"]       := "ㄑ"
        BopomofoSpecificNames["sc022"]       := "ㄕ"
        BopomofoSpecificNames["sc023"]       := "ㄘ"
        BopomofoSpecificNames["sc024"]       := "ㄨ"
        BopomofoSpecificNames["sc025"]       := "ㄜ"
        BopomofoSpecificNames["sc026"]       := "ㄠ"
        BopomofoSpecificNames["sc027"]       := "; : ㄤ" 
        BopomofoSpecificNames["sc028"]       := "' """ 
        BopomofoSpecificNames["sc02c"]       := "ㄈ"
        BopomofoSpecificNames["sc02d"]       := "ㄌ"
        BopomofoSpecificNames["sc02e"]       := "ㄏ"
        BopomofoSpecificNames["sc02f"]       := "ㄒ"
        BopomofoSpecificNames["sc030"]       := "ㄖ"
        BopomofoSpecificNames["sc031"]       := "ㄙ"
        BopomofoSpecificNames["sc032"]       := "ㄩ"
        BopomofoSpecificNames["sc033"]       := ", < ㄝ" 
        BopomofoSpecificNames["sc034"]       := ". > ㄡ" 
        BopomofoSpecificNames["sc035"]       := "/ ? ㄥ" 
        
        ; --- QWERTY 佈局的按鍵文字 ---
        QwertySpecificNames := SharedNames.Clone()
        QwertySpecificNames["sc029"]       := "`` ~"
        QwertySpecificNames["sc002"]       := "1 !"
        QwertySpecificNames["sc003"]       := "2 @"
        QwertySpecificNames["sc004"]       := "3 #"
        QwertySpecificNames["sc005"]       := "4 $"
        QwertySpecificNames["sc006"]       := "5 %"
        QwertySpecificNames["sc007"]       := "6 ^"
        QwertySpecificNames["sc008"]       := "7 &&"
        QwertySpecificNames["sc009"]       := "8 *"
        QwertySpecificNames["sc00a"]       := "9 ("
        QwertySpecificNames["sc00b"]       := "0 )"
        QwertySpecificNames["sc00c"]       := "- _"
        QwertySpecificNames["sc00d"]       := "= +"
        QwertySpecificNames["sc010"]       := "q Q"
        QwertySpecificNames["sc011"]       := "w W"
        QwertySpecificNames["sc012"]       := "e E"
        QwertySpecificNames["sc013"]       := "r R"
        QwertySpecificNames["sc014"]       := "t T"
        QwertySpecificNames["sc015"]       := "y Y"
        QwertySpecificNames["sc016"]       := "u U"
        QwertySpecificNames["sc017"]       := "i I"
        QwertySpecificNames["sc018"]       := "o O"
        QwertySpecificNames["sc019"]       := "p P"
        QwertySpecificNames["sc01a"]       := "[ {"
        QwertySpecificNames["sc01b"]       := "] }"
        QwertySpecificNames["sc02b"]       := "\ |"
        QwertySpecificNames["sc01e"]       := "a A"
        QwertySpecificNames["sc01f"]       := "s S"
        QwertySpecificNames["sc020"]       := "d D" 
        QwertySpecificNames["sc021"]       := "f F"
        QwertySpecificNames["sc022"]       := "g G"
        QwertySpecificNames["sc023"]       := "h H"
        QwertySpecificNames["sc024"]       := "j J"
        QwertySpecificNames["sc025"]       := "k K"
        QwertySpecificNames["sc026"]       := "l L"
        QwertySpecificNames["sc027"]       := "; :" 
        QwertySpecificNames["sc028"]       := "' """ 
        QwertySpecificNames["sc02c"]       := "z Z"
        QwertySpecificNames["sc02d"]       := "x X"
        QwertySpecificNames["sc02e"]       := "c C"
        QwertySpecificNames["sc02f"]       := "v V"
        QwertySpecificNames["sc030"]       := "b B"
        QwertySpecificNames["sc031"]       := "n N"
        QwertySpecificNames["sc032"]       := "m M"
        QwertySpecificNames["sc033"]       := ", <" 
        QwertySpecificNames["sc034"]       := ". >" 
        QwertySpecificNames["sc035"]       := "/ ?" 
        
        this.AllPrettyNames := {bopomofo: BopomofoSpecificNames, qwerty: QwertySpecificNames}
        
        this.PrettyName := this.AllPrettyNames[this.LayoutMode]
        this.UpdateLayoutButtonText()
        
        this.Keys := []
        this.Controls := []
        
        this.Make()
    }

    SetTimer(TimerID, Period) {
        Timer := this[TimerID]
        SetTimer % Timer, % Period
        return
    }

    ; 核心方法：建立鍵盤的 GUI 介面
    Make() {
        ScaleFactor := this.ScaleFactor
        ButtonHeight := Round(35 * ScaleFactor)
        KeySpacing := Round(2 * ScaleFactor)
        StandardWidth := Round(45 * ScaleFactor)
        CurrentY := Round(10 * ScaleFactor)
        MarginLeft := Round(10 * ScaleFactor)
        MaxRightEdge := 0
        LastButtonY := 0
        FontSize := "s" Round(10 * ScaleFactor)

        Gui, OSK: +AlwaysOnTop -DPIScale +Owner -Caption +E0x08000000 
        Gui, OSK: Font, %FontSize%, Microsoft JhengHei UI
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
                KeyText := Button.1
                isPlaceholder := (KeyText = "placeholder")
                
                if (!isPlaceholder) {
                    AbsolutePosition := "x" CurrentX " y" CurrentY
                    
                    ; 每個按鈕由三個控制項疊加而成：
                    ; 1. Text (bottomt): 決定按鈕的背景色和點擊事件。
                    ; 2. Progress (border): 作為按鈕的邊框。
                    ; 3. Text (h): 顯示按鍵上的文字，設定為透明背景。
                    Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " Background" this.ButtonColour " hwndbottomt gHandleOSKClick", % KeyText
                    Gui, OSK:Add, Progress, % "xp yp w" Width " h" ButtonHeight " Background" this.ButtonColour " hwndborder", 100
                    GuiControl, % "OSK: +C" this.ButtonColour, % border

                    DisplayText := this.PrettyName.HasKey(KeyText) ? this.PrettyName[KeyText] : KeyText
                    parts := StrSplit(DisplayText, A_Space)
                    
                    IsControlKey := (KeyText = "sc001" or KeyText = "sc00e" or KeyText = "sc00f" 
                                  or KeyText = "sc03a" or KeyText = "sc01c" or KeyText = "sc02a" 
                                  or KeyText = "sc036" or KeyText = "sc01d" or KeyText = "sc05b" 
                                  or KeyText = "sc038" or KeyText = "sc039" or KeyText = "sc053" 
                                  or KeyText = "sc048" or KeyText = "sc050" or KeyText = "sc04b" 
                                  or KeyText = "sc04d" 
                                  or KeyText = "Transparent" 
                                  or KeyText = "Hide" or KeyText = "Close" 
                                  or KeyText = "ZoomOut" or KeyText = "ZoomIn" or KeyText = "Reset"
                                  or KeyText = "ToggleLayout")
                    
                    LabelHandles := {Text: ""}

                    if (IsControlKey) {
                        Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " 0x200 Center BackgroundTrans c" this.TextColour " hwndh", % DisplayText
                        LabelHandles.Text := h
                    } else if (this.LayoutMode = "bopomofo") {
                        BopomofoChars := "ㄅㄆㄇㄈㄉㄊㄋㄌㄍㄎㄏㄐㄑㄒㄓㄔㄕㄖㄗㄘㄙㄧㄨㄩㄚㄛㄜㄝㄞㄟㄠㄡㄢㄣㄤㄥㄦˊˇˋ˙"
                        if (InStr(this.WhiteSymbolKeysList, "|" KeyText "|")) {
                            BopoText := parts[1]
                            Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " 0x200 Center BackgroundTrans c" this.TextColour " hwndh", % BopoText
                            LabelHandles.Text := h
                        } else {
                            if (StrLen(parts[1]) = 1 and InStr(BopomofoChars, parts[1]))
                                 BopoText := parts[1]
                            else if (parts.Length() >= 3)
                                BopoText := parts[3]
                            else if (parts.Length() = 2)
                                BopoText := parts[2]
                            else
                                BopoText := parts[1]
                            
                            Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " 0x200 Center BackgroundTrans c" this.SecondLineColour " hwndh", % BopoText
                            LabelHandles.Text := h
                        }
                    } else if (parts.Length() >= 2) {
                        CurrentShiftState := GetKeyState("sc02a") OR GetKeyState("sc036")
                        CurrentText := CurrentShiftState ? parts[2] : parts[1]
                        CurrentColour := CurrentShiftState ? this.ShiftSymbolColour : this.TextColour
                        Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " 0x200 Center BackgroundTrans c" CurrentColour " hwndh", % CurrentText
                        LabelHandles.Text := h
                    } else if (parts.Length() = 1 and parts[1] != "") {
                        Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " 0x200 Center BackgroundTrans c" this.TextColour " hwndh", % parts[1]
                        LabelHandles.Text := h
                    } 
                    
                    this.Keys[KeyText] := [Index, i]
                    
                    currentShiftState := GetKeyState("sc02a") OR GetKeyState("sc036")
                    
                    if ((KeyText = "sc02a" OR KeyText = "sc036") and currentShiftState) {
                        currentButtonColour := this.ToggledButtonColour
                    } else {
                        currentButtonColour := this.ButtonColour
                    }

                    this.Controls[Index, i] := {Progress: border, Labels: LabelHandles, Bottom: bottomt, Colour: currentButtonColour}
                    GuiControl, % "OSK: +C" currentButtonColour, % border
                    GuiControl, % "OSK: +Background" currentButtonColour, % bottomt
                    
                    RightEdge := CurrentX + Width
                    if (RightEdge > MaxRightEdge)
                        MaxRightEdge := RightEdge
                    LastButtonY := CurrentY
                }
                CurrentX += Width + HorizontalSpacing
            }
        }
        
        TotalWidth := MaxRightEdge + MarginLeft
        TotalHeight := LastButtonY + ButtonHeight + MarginLeft
        Gui, OSK:Show, % "w" TotalWidth " h" TotalHeight " Hide"
        Return
    }

    Resize(percent_change) {
        resize_delta := (percent_change > 0) ? 0.1 : -0.1
        new_scale := this.ScaleFactor * (1 + resize_delta)
        if (new_scale < 0.5)
            new_scale := 0.5
        else if (new_scale > 2.5)
            new_scale := 2.5

        if (Round(new_scale, 2) != Round(this.ScaleFactor, 2)) {
            this.ScaleFactor := new_scale
            this.RebuildGUI()
        }
    }
    
    ResetScale() {
        DefaultScale := 1.5 
        if (this.ScaleFactor != DefaultScale) {
            this.ScaleFactor := DefaultScale
            this.RebuildGUI()
        }
    }

    RebuildGUI() {
        DetectHiddenWindows On
        IfWinExist, 螢幕鍵盤
        {
            WinGetPos, currentX, currentY, , , 螢幕鍵盤
            this.CurrentX := currentX
            this.CurrentY := currentY
        }
        DetectHiddenWindows Off

        Gui, OSK: Hide
        Gui, OSK: Destroy
        this.Make()
        Sleep, 50
        
        GUI_X := this.CurrentX
        GUI_Y := this.CurrentY
        
        Gui, OSK:Show, % "x" GUI_X " y" GUI_Y " NA", 螢幕鍵盤
        trans_levels := [255, 220, 180, 100]
        WinSet, Transparent, % trans_levels[this.current_trans], 螢幕鍵盤
    }
    
    Show() {
        this.Enabled := True
        CurrentMonitorIndex := this.GetCurrentMonitorIndex()
        DetectHiddenWindows On
        Gui, OSK: +LastFound
        Gui, OSK:Show, Hide
        GUI_Hwnd := WinExist()
        this.GetClientSize(GUI_Hwnd,GUI_Width,GUI_Height)
        DetectHiddenWindows Off
        
        if (this.CurrentX != "" and this.CurrentY != "") {
            GUI_X := this.CurrentX
            GUI_Y := this.CurrentY
        } else {
            SysGet, MonWA, MonitorWorkArea, %CurrentMonitorIndex%
            GUI_X := ((MonWARight - MonWALeft - GUI_Width) / 2) + MonWALeft
            GUI_Y := MonWABottom - GUI_Height
            this.CurrentX := GUI_X
            this.CurrentY := GUI_Y
        }
        
        Gui, OSK:Show, % "x" GUI_X " y" GUI_Y " NA", 螢幕鍵盤
        this.SetTimer("MonitorKeyPresses", 30)
        Return
    }
    
    Hide() {
        DetectHiddenWindows On
        IfWinExist, 螢幕鍵盤
        {
            WinGetPos, currentX, currentY, , , 螢幕鍵盤
            this.CurrentX := currentX
            this.CurrentY := currentY
        }
        DetectHiddenWindows Off

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
    
    UpdateLayoutButtonText() {
        if (this.LayoutMode = "bopomofo") {
            this.PrettyName["ToggleLayout"] := "En"
        } else {
            this.PrettyName["ToggleLayout"] := "ㄅ"
        }
    }
    
    ToggleLayout() {
        if (this.LayoutMode = "bopomofo") {
            this.LayoutMode := "qwerty"
        } else {
            this.LayoutMode := "bopomofo"
        }
        
        this.PrettyName := this.AllPrettyNames[this.LayoutMode]
        this.UpdateLayoutButtonText()
        this.RebuildGUI()
    }

    ToggleTransparent() {
        trans_levels := [255, 220, 180, 100]
        this.current_trans := Mod(this.current_trans, trans_levels.Length()) + 1
        WinSet, Transparent, % trans_levels[this.current_trans], 螢幕鍵盤
    }

    ConfirmClose() {
        MsgBox, 4, 關閉確認, 是否確定要關閉螢幕鍵盤程式？
        IfMsgBox, Yes
            ExitApp
        Return
    }

    GetCurrentMonitorIndex() {
        CoordMode, Mouse, Screen
        MouseGetPos, mx, my
        SysGet, monitorsCount, 80
        Loop %monitorsCount%{
            SysGet, monitor, Monitor, %A_Index%
            if (monitorLeft <= mx && mx <= monitorRight && monitorTop <= my && monitorBottom)
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

        if (Key = "placeholder") {
            Return
        }

        ; 如果在OSK上按了Ctrl+Space，則模擬為點擊 "ToggleLayout" 按鈕
        if (Key = "sc039") {
            CtrlSC := "sc01d"
            if (this.Keys.HasKey(CtrlSC)) {
                ctrl_coords := this.Keys[CtrlSC]
                ctrl_row := ctrl_coords[1]
                ctrl_col := ctrl_coords[2]
                
                if (this.Controls[ctrl_row, ctrl_col].Colour = this.ToggledButtonColour) {
                    this.SendModifier(CtrlSC)
                    this.HandleOSKClick("ToggleLayout")
                    Return
                }
            }
        }
        
        ; --- 處理特殊功能按鈕 ---
        if (Key = "ToggleLayout") {
            KeyRow := this.Keys[Key][1]
            KeyCol := this.Keys[Key][2]
            
            this.UpdateGraphics(this.Controls[KeyRow, KeyCol], this.ClickFeedbackColour)
            this.ToggleLayout()
            
            isPhysicalCtrlDown := GetKeyState("Control", "P")
            isOSKCtrlDown := this.IsOSKModifierOn("sc01d")

            ; 如果 Ctrl 鍵沒有被按下，則送出 Shift 鍵訊號來切換系統輸入法
            if (!isPhysicalCtrlDown and !isOSKCtrlDown) {
                SendInput, {Shift}
            }
            
            Sleep, 50 
            Return
        } else if (Key = "ZoomOut") {
            this.Resize(-0.05)
            Return
        } else if (Key = "ZoomIn") {
            this.Resize(0.05)
            Return
        } else if (Key = "Reset") { 
            this.ResetScale()
            Return
        } else if (Key = "Transparent") {
            this.ToggleTransparent()
            Return
        } else if (Key = "Close") {
            this.ConfirmClose()
            Return
        } else if (Key = "Hide") {
            this.Toggle()
            Return
        }
        
        ; --- 處理一般按鍵與修飾鍵 ---
        if (this.IsModifier(Key))
            this.SendModifier(Key)
        else
            this.SendPress(Key)
        return
    }

    ; 輔助函式：檢查螢幕鍵盤上的修飾鍵 (如 Ctrl) 是否處於按下的狀態
    IsOSKModifierOn(Key) {
        if (!this.Keys.HasKey(Key))
            return false
        
        KeyCoords := this.Keys[Key]
        KeyRow := KeyCoords[1]
        KeyCol := KeyCoords[2]
        
        ; 透過檢查按鈕的背景顏色來判斷其是否為 "toggled" (按下) 狀態
        return (this.Controls[KeyRow, KeyCol].Colour = this.ToggledButtonColour)
    }

    IsModifier(Key) {
        return (Key = "sc02a"
             or Key = "sc036"
             or Key = "sc01d"
             or Key = "sc05b"
             or Key = "sc038"
             or Key = "sc03a"
             or Key = "ScrollLock")
    }

    ; 定時器觸發的函式，持續監控所有實體按鍵的狀態
    MonitorAllKeys() {
        For _, Row in this.Layout {
            For i, Button in Row {
                if (Button.1 = "placeholder" or Button.1 = "ToggleLayout")
                    continue
                if (this.Keys.HasKey(Button.1))
                    this.MonitorKey(Button.1)
            }
        }
        
        CurrentShiftState := GetKeyState("sc02a") OR GetKeyState("sc036")
        
        if (this.LayoutMode = "qwerty") {
             if (CurrentShiftState != this.LastDisplayedShiftState) {
                this.RefreshAllKeyDisplays()
                this.LastDisplayedShiftState := CurrentShiftState
             }
        }
        
        Return
    }

    ; 刷新所有按鍵的顯示 (主要用於 Shift 鍵按下時，切換 QWERTY 鍵盤的大小寫顯示)
    RefreshAllKeyDisplays() {
        isShiftOn := GetKeyState("sc02a") OR GetKeyState("sc036")
        
        if (this.LayoutMode != "qwerty") {
            return
        }

        For Index, Row in this.Layout {
            For i, Button in Row {
                KeyText := Button.1
                if (!this.Controls[Index, i])
                    continue
                KeyControls := this.Controls[Index, i]
                TextLabel := KeyControls.Labels.Text
                if (TextLabel = "")
                    continue

                DisplayText := this.PrettyName.HasKey(KeyText) ? this.PrettyName[KeyText] : KeyText
                parts := StrSplit(DisplayText, A_Space)
                
                if (parts.Length() >= 2) {
                    if (isShiftOn) {
                        newText := parts[2]
                        newColour := this.ShiftSymbolColour
                    } else {
                        newText := parts[1]
                        newColour := this.TextColour
                    }
                    
                    GuiControl, OSK: +c%newColour%, % TextLabel
                    GuiControl, OSK:, % TextLabel, % newText
                }
            }
        }
        
        Gui, OSK: +LastFound
        WinSet, Redraw, , 螢幕鍵盤
    }

    ; 監控單一按鍵的狀態，並更新其在 OSK 上的視覺外觀
    MonitorKey(Key) {
        KeyOn := GetKeyState(Key, (Key = "sc03a" or Key = "ScrollLock" or Key = "Pause") ? "T" : "")
        
        if (!this.Keys.HasKey(Key))
            return

        KeyRow := this.Keys[Key][1]
        KeyColumn := this.Keys[Key][2]
        
        CurrentColour := this.Controls[KeyRow, KeyColumn].Colour
        NewColour := ""
        
        if (KeyOn and CurrentColour != this.ToggledButtonColour)
            NewColour := this.ToggledButtonColour
        else if (not KeyOn and CurrentColour = this.ToggledButtonColour) 
            NewColour := this.ButtonColour
        
        if (NewColour)
            this.UpdateGraphics(this.Controls[KeyRow, KeyColumn], NewColour)

        Return
    }

    ; 模擬一次完整的按鍵點擊 (按下後立即放開)
    SendPress(Key) {
        KeyRow := this.Keys[Key][1]
        KeyCol := this.Keys[Key][2]
        
        this.UpdateGraphics(this.Controls[KeyRow, KeyCol], this.ClickFeedbackColour)
        SendInput, % "{Blind}{" Key "}"
        Sleep, 100
        this.UpdateGraphics(this.Controls[KeyRow, KeyCol], this.ButtonColour) 

        Return
    }

    ; 模擬修飾鍵的狀態切換 (按下或放開)
    SendModifier(Key) {
        KeyControls := this.Controls[this.Keys[Key][1], this.Keys[Key][2]]
        this.UpdateGraphics(KeyControls, this.ClickFeedbackColour)
        Sleep, 100
        
        if (Key = "sc03a")
            SetCapsLockState, % not GetKeyState(Key, "T")
        else if (Key = "ScrollLock")
            SetScrollLockState, % not GetKeyState(Key, "T")
        else {
            isShiftKey := (Key = "sc02a" or Key = "sc036")
            
            if (GetKeyState(Key)) {
                SendInput, % "{" Key " up}"
                
                if (isShiftKey) {
                    this.ToggleLayout()
                }
            }
            else {
                SendInput, % "{" Key " down}"
            }
        }
        return
    }

    ; 更新按鈕圖形的輔助函式 (背景色與邊框)
    UpdateGraphics(Obj, Colour){
        GuiControl, % "OSK: +C" Colour, % Obj.Progress
        GuiControl, % "OSK: +Background" Colour, % Obj.Bottom 
        GuiControl, OSK: +Redraw, % Obj.Progress
        GuiControl, OSK: +Redraw, % Obj.Bottom
        
        TextLabel := Obj.Labels.Text
        if (TextLabel != "") {
            GuiControl, OSK: +Redraw, % TextLabel
        }

        Obj.Colour := Colour
        Return
    }
}

