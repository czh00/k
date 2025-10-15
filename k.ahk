#SingleInstance
SendMode Input

; 程式啟動與熱鍵設定
If (A_ScriptFullPath = A_LineFile) { 
    ; *** 修改: 預設使用 QWERTY 英文佈局 ***
    Global keyboard := new OSK("dark", "qwerty")

    ; --- Tray 圖示右鍵選單設定 ---
    Menu, Tray, NoStandard ; 移除所有標準右鍵選單項目
    Menu, Tray, Add, 顯示/隱藏, ToggleTrayHandler ; 新增「顯示/隱藏」選項
    Menu, Tray, Add, 離開, ExitHandler         ; 新增「離開」選項
    Menu, Tray, Default, 顯示/隱藏             ; 設定左鍵單擊預設為「顯示/隱藏」
    Menu, Tray, Click, 1                       ; 設定單擊觸發預設動作
    Menu, Tray, Tip, 螢幕鍵盤 (Ctrl+Shift+O)   ; 設定滑鼠懸停提示文字

    ; 設定熱鍵 Ctrl+Shift+O 來顯示或隱藏鍵盤
    toggle := ObjBindMethod(keyboard, "toggle")
    Hotkey, ^+O, % toggle 

    ; --- 設定熱鍵 Ctrl+Space 來切換中/英佈局 ---
    toggleLayout := ObjBindMethod(keyboard, "ToggleLayout")
    Hotkey, ~$^Space, % toggleLayout ; 新增 "~" 前綴讓按鍵可穿透

    ; *** 核心修改：註冊視窗訊息監聽 ***
    ; 監聽 WM_LBUTTONDOWN (0x201) 這個 Windows 訊息。
    ; 每當此腳本的任何 GUI 視窗收到「滑鼠左鍵按下」的訊息時，
    ; 就會自動呼叫 HandleBackgroundClick 函式來進行處理。
    OnMessage(0x201, "HandleBackgroundClick")

    keyboard.Show()
}
Return 

; --- Tray 選單處理函式 ---
ToggleTrayHandler:
    keyboard.toggle()
    return

ExitHandler:
    ExitApp
    return

; *** 新增函式：處理 GUI 背景點擊事件 (由 OnMessage 觸發) ***
HandleBackgroundClick(wParam, lParam, msg, hwnd) {
    ; 這個函式由 OnMessage(0x201, ...) 註冊，專門監聽滑鼠左鍵在視窗上按下的訊息。
    
    ; 將 OSK 視窗設定為 "Last Found Window"，以便後續的 WinExist() 可以正確地針對它。
    Gui, OSK: +LastFound
    
    ; 檢查觸發此訊息的視窗控制代碼 (hwnd) 是否就是我們的螢幕鍵盤視窗。
    if (hwnd = WinExist()) {
        ; 獲取滑鼠指標當前位置下的控制項資訊。
        ; 第五個參數會接收控制項的 ClassNN (例如 Static1)。
        MouseGetPos, , , , clicked_control
        
        ; 如果 clicked_control 是空的，就代表滑鼠點擊的位置沒有任何控制項，也就是點擊了 GUI 的背景空白處。
        if (clicked_control = "") {
            ; 既然是點擊空白處，我們就觸發系統內建的視窗拖曳功能。
            ; PostMessage 0xA1, 2 是一個技巧，它模擬了在視窗標題列上按下滑鼠左鍵的行為。
            PostMessage, 0xA1, 2
        }
        ; 如果 clicked_control 不是空的，代表使用者點擊的是一個按鈕。
        ; 在這種情況下，我們什麼都不做，因為按鈕本身有 gHandleOSKClick 標籤，
        ; 它的點擊事件會由 HandleOSKClick() 函式獨立處理。
        ; 這個函式只專注於處理 "空白處" 的點擊。
    }
}

; 語境敏感熱鍵 (當 OSK 顯示時啟用)
#If (keyboard.Enabled) 

#If

; 處理 GUI 按鈕點擊事件 (由 g-label 觸發)
HandleOSKClick() {
    ; 這個函式只會由鍵盤上的按鈕(具體來說是作為按鈕底層的 Text 控制項)觸發。
    ; 因此 A_GuiControl 總會包含被點擊按鈕的名稱 (即它的掃描碼)。
    ; 我們將這個名稱傳遞給 OSK 物件的 HandleOSKClick 方法，由它來處理後續的按鍵模擬。
    keyboard.HandleOSKClick(A_GuiControl)
    return
}

Class OSK
{
    ; 追蹤當前佈局
    LayoutMode := ""  ; "qwerty" 或 "bopomofo"
    isShifted := false ; 追蹤 Shift 鎖定狀態 (僅供 OSK 點擊鎖定使用)
    
    __New(theme:="dark", layout:="qwerty") {
        this.Enabled := False
        this.current_trans := 1 ; 當前透明度等級 (1 = 255/完全不透明)
        this.ScaleFactor := 1.5 ; 鍵盤縮放比例 (預設 1.5)

        ; *** 修改: 初始化為空字串，用於判斷是否為首次顯示 ***
        this.CurrentX := "" ; 儲存當前 X 座標
        this.CurrentY := "" ; 儲存當前 Y 座標
        
        ; 左側修飾鍵和特殊鎖定鍵
        this.Modifiers := ["sc02a", "sc01d", "sc05b", "sc038", "sc03a", "ScrollLock"]
        
        ; 固定深黑色主題設定
        this.Background := "2A2A2A"     ; 鍵盤背景 (深灰)
        this.ButtonColour := "010101"   ; 按鈕主色 (深黑色)
        this.ClickFeedbackColour := "0078D7" ; 點擊回饋顏色 (亮藍色)
        this.ToggledButtonColour := "553b6a" ; 鎖定/已切換按鈕顏色 (深紫色)
        this.TextColour := "ffffff"     ; 主要文字顏色 (白色)
        this.ShiftSymbolColour := "ADD8E6" ; Shift 符號顏色 (淡藍色)
        this.SecondLineColour := "FFA500"  ; 第二行文字顏色 (橘色/注音色)

        ; 在注音模式下，這些鍵只顯示其基礎符號 (parts[1]) 並使用白色 (this.TextColour)。
        this.WhiteSymbolKeysList := "|sc029|sc00d|sc01a|sc01b|sc02b|sc028|"

        this.MonitorKeyPresses := ObjBindMethod(this, "MonitorAllKeys") 
        
        ; 每行第一個鍵的 X 座標偏移量
        this.RowStartOffsets := {}
        this.RowStartOffsets[2] := 0
        this.RowStartOffsets[3] := 0
        this.RowStartOffsets[4] := 0
        this.RowStartOffsets[5] := 0
        this.RowStartOffsets[6] := 0

        this.Layout := []
        this.BopomofoNames := {}
        this.QwertyNames := {}
        this.LayoutMode := layout ; 設置初始佈局
        
        ; 標準鍵寬
        StdKey := 45 

        ; *** 修改：移除 "Move" 按鈕，改為 placeholder 以維持版面 ***
        ; Row 1: 功能鍵 (Esc, 空白區, 佈局切換, 縮放, 重設, 透明度, 關閉, 隱藏)
        this.Layout.Push([ ["sc001", StdKey], ["placeholder", 306], ["ToggleLayout", StdKey], ["ZoomOut", StdKey], ["ZoomIn", StdKey], ["Reset", StdKey], ["Transparent"], ["Close", StdKey], ["Hide", StdKey] ]) 
        
        ; Row 2: 數字列
        this.Layout.Push([ ["sc029", StdKey],["sc002", StdKey],["sc003", StdKey],["sc004", StdKey],["sc005", StdKey],["sc006", StdKey],["sc007", StdKey],["sc008", StdKey],["sc009", StdKey],["sc00a", StdKey],["sc00b", StdKey],["sc00c", StdKey],["sc00d", StdKey],["sc00e", 63] ])
        
        ; Row 3: QWERTY 列
        this.Layout.Push([ ["sc00f", 67.5],["sc010", StdKey],["sc011", StdKey],["sc012", StdKey],["sc013", StdKey],["sc014", StdKey],["sc015", StdKey],["sc016", StdKey],["sc017", StdKey],["sc018", StdKey],["sc019", StdKey],["sc01a", StdKey],["sc01b", StdKey],["sc02b", 41] ])

        ; Row 4: ASDFG 列
        this.Layout.Push([ ["sc03a", 90],["sc01e", StdKey],["sc01f", StdKey],["sc020", StdKey],["sc021", StdKey],["sc022", StdKey],["sc023", StdKey],["sc024", StdKey],["sc025", StdKey],["sc026", StdKey],["sc027", StdKey],["sc028", StdKey],["sc01c", 67] ])
        
        ; Row 5: ZXCVB 列
        this.Layout.Push([ ["sc02a", 112.5],["sc02c", StdKey],["sc02d", StdKey],["sc02e", StdKey],["sc02f", StdKey],["sc030", StdKey],["sc031", StdKey],["sc032", StdKey],["sc033", StdKey],["sc034", StdKey],["sc035", StdKey], ["sc048", 45], ["sc053", 44.5] ]) 
        
        ; Row 6: LCtrl/LWin/LAlt/Space/箭頭鍵
        this.Layout.Push([ ["sc01d", 60], ["sc05b", 60], ["sc038", 60], ["sc039", 360], ["sc04b", 45], ["sc050", 45], ["sc04d", 45] ]) 
        
        ; --- 共享按鍵顯示文字定義 (控制鍵) ---
        SharedNames := {} 
        SharedNames["Transparent"] := "◌"
        SharedNames["Close"]       := "✕"
        SharedNames["Hide"]        := "⇲"
        SharedNames["ZoomOut"]     := "⊖"
        SharedNames["ZoomIn"]      := "⊕"
        SharedNames["Reset"]       := "↺" 
        SharedNames["placeholder"] := ""
        SharedNames["sc001"]       := "Esc"       
        SharedNames["sc00e"]       := "←"       ; Backspace
        SharedNames["sc00f"]       := "Tab"       
        SharedNames["sc03a"]       := "⇭"
        SharedNames["sc01c"]       := "↩"     
        SharedNames["sc02a"]       := "Shift"     ; LShift
        SharedNames["sc036"]       := "Shift"     ; RShift (雖然不在佈局中，但定義名稱)
        SharedNames["sc01d"]       := "Ctrl"      ; LCtrl
        SharedNames["sc05b"]       := "Win"       ; LWin
        SharedNames["sc038"]       := "Alt"       ; LAlt
        SharedNames["sc039"]       := "Space"     ; Space
        SharedNames["sc048"]       := "↑"         ; Up
        SharedNames["sc050"]       := "↓"         ; Down
        SharedNames["sc04b"]       := "←"         ; Left
        SharedNames["sc04d"]       := "→"         ; Right
        SharedNames["sc053"]       := "Del"       
        
        ; --- Bopomofo/注音 佈局專用名稱 (僅注音/聲調/符號) ---
        BopomofoSpecificNames := SharedNames.Clone()
        
        ; 數字/符號/注音鍵定義 (3行/2行顯示) - 隱藏 QWERTY 字母
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
        
        ; QWERTY 列定義 (注音) - 隱藏 QWERTY 字母
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
        
        ; ASDFG 列定義 (注音) - 隱藏 QWERTY 字母
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
        
        ; ZXCVB 列定義 (注音) - 隱藏 QWERTY 字母
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
        
        ; --- QWERTY/英文 佈局專用名稱 (增加小寫/大寫對應) ---
        QwertySpecificNames := SharedNames.Clone()
        
        ; 數字/符號鍵定義 (2行顯示，不顯示注音) - parts[1] (Unshifted) parts[2] (Shifted)
        QwertySpecificNames["sc029"]       := "`` ~"
        QwertySpecificNames["sc002"]       := "1 !"
        QwertySpecificNames["sc003"]       := "2 @"
        QwertySpecificNames["sc004"]       := "3 #"
        QwertySpecificNames["sc005"]       := "4 $"
        QwertySpecificNames["sc006"]       := "5 %"
        QwertySpecificNames["sc007"]       := "6 ^"
        QwertySpecificNames["sc008"]       := "7 &&"
        QwertySpecificNames["sc009"]       := "8 *"
        QwertySpecificNames["sc00b"]       := "0 )"
        QwertySpecificNames["sc00a"]       := "9 ("
        QwertySpecificNames["sc00c"]       := "- _"
        QwertySpecificNames["sc00d"]       := "= +"
        
        ; QWERTY 列定義 (小寫/大寫)
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
        
        ; ASDFG 列定義 (小寫/大寫)
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
        
        ; ZXCVB 列定義 (小寫/大寫)
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
        
        ; 根據初始佈局設定當前的 PrettyName
        this.PrettyName := this.AllPrettyNames[this.LayoutMode]
        this.UpdateLayoutButtonText() ; 設置切換按鈕的初始文字
        
        this.Keys := [] ; 鍵名與座標映射
        this.Controls := [] ; 控件 HWND 儲存
        
        this.Make()
    }

    ; 設定計時器 (用於監控按鍵狀態)
    SetTimer(TimerID, Period) {
        Timer := this[TimerID]
        SetTimer % Timer, % Period
        return
    }

    ; 繪製 GUI 介面與按鍵
    Make() {
        ScaleFactor := this.ScaleFactor 
        
        ; --- 修正關鍵點 1: 增加按鍵高度 (由 30 增加到 35)，確保字體在 DPI 縮放時不被裁切 ---
        ButtonHeight := Round(35 * ScaleFactor)
        
        KeySpacing := Round(2 * ScaleFactor)
        StandardWidth := Round(45 * ScaleFactor)
        
        CurrentY := Round(10 * ScaleFactor) 
        MarginLeft := Round(10 * ScaleFactor) ; 左右/底部邊界
        
        MaxRightEdge := 0 ; 追蹤最右邊按鍵的 X 座標 + 寬度
        LastButtonY := 0  ; 追蹤最後一個按鍵的 Y 座標

        
        ; GUI 基本設定
        ; --- 修正關鍵點 2: 增加基礎字體大小 (由 12 增加到 15)，解決 150% DPI 裝置字體偏小問題 ---
        FontSize := "s" Round(10 * ScaleFactor) 
        
        ; 確保不受系統縮放影響的核心設定: -DPIScale
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
                
                ; 繪製按鈕
                if (!isPlaceholder) {
                    AbsolutePosition := "x" CurrentX " y" CurrentY
                    
                    ; 繪製底層背景和邊框 (Progress Bar 作為邊框)
                    Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " Background" this.ButtonColour " hwndbottomt gHandleOSKClick", % KeyText
                    Gui, OSK:Add, Progress, % "xp yp w" Width " h" ButtonHeight " Background" this.ButtonColour " hwndborder", 100
                    GuiControl, % "OSK: +C" this.ButtonColour, % border

                    ; 處理多行或單行文字顯示
                    DisplayText := this.PrettyName.HasKey(KeyText) ? this.PrettyName[KeyText] : KeyText
                    parts := StrSplit(DisplayText, A_Space)
                    
                    ; 檢查是否為居中單色顯示的控制鍵
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
                        ; 情況 1: 控制鍵 - 單色居中
                        ; *** 修改: 新增 0x200 樣式以達成垂直置中 ***
                        Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " 0x200 Center BackgroundTrans c" this.TextColour " hwndh", % DisplayText
                        LabelHandles.Text := h
                    } else if (this.LayoutMode = "bopomofo") {
                        ; --- Bopomofo 模式: 注音/聲調置中放大 (使用橘色/注音色) ---
                        BopomofoChars := "ㄅㄆㄇㄈㄉㄊㄋㄌㄍㄎㄏㄐㄑㄒㄓㄔㄕㄖㄗㄘㄙㄧㄨㄩㄚㄛㄜㄝㄞㄟㄠㄡㄢㄣㄤㄥㄦˊˇˋ˙"

                        if (InStr(this.WhiteSymbolKeysList, "|" KeyText "|")) {
                            BopoText := parts[1]
                            ; *** 修改: 新增 0x200 樣式以達成垂直置中 ***
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
                            
                            ; *** 修改: 新增 0x200 樣式以達成垂直置中 ***
                            Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " 0x200 Center BackgroundTrans c" this.SecondLineColour " hwndh", % BopoText
                            LabelHandles.Text := h
                        }
                    } else if (parts.Length() >= 2) {
                        ; --- QWERTY 雙字元鍵: 根據 isShifted 決定顯示哪個字元 ---
                        
                        ; 檢查實際的 Shift 狀態：是鎖定 (this.isShifted) 或是實體按住 (GetKeyState)
                        CurrentShiftState := this.isShifted OR GetKeyState("sc02a") OR GetKeyState("sc036")

                        CurrentText := CurrentShiftState ? parts[2] : parts[1]
                        CurrentColour := CurrentShiftState ? this.ShiftSymbolColour : this.TextColour
                        
                        ; *** 修改: 新增 0x200 樣式以達成垂直置中 ***
                        Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " 0x200 Center BackgroundTrans c" CurrentColour " hwndh", % CurrentText
                        LabelHandles.Text := h
                        
                    } else if (parts.Length() = 1 and parts[1] != "") {
                        ; 情況 2: 單字元鍵
                        ; *** 修改: 新增 0x200 樣式以達成垂直置中 ***
                        Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " 0x200 Center BackgroundTrans c" this.TextColour " hwndh", % parts[1]
                        LabelHandles.Text := h
                    } 
                    
                    this.Keys[KeyText] := [Index, i]
                    
                    ; 確保 Shift 鍵的視覺狀態正確初始化 (檢查鎖定狀態或實體按住)
                    currentShiftState := this.isShifted OR GetKeyState("sc02a") OR GetKeyState("sc036")
                    
                    if ((KeyText = "sc02a" OR KeyText = "sc036") and currentShiftState) {
                        currentButtonColour := this.ToggledButtonColour
                    } else {
                        currentButtonColour := this.ButtonColour
                    }

                    this.Controls[Index, i] := {Progress: border, Labels: LabelHandles, Bottom: bottomt, Colour: currentButtonColour}
                    ; 重新設定 Shift 鍵的顏色以反映初始鎖定狀態
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

    ; 調整鍵盤大小的方法 (依百分比變化)
    Resize(percent_change) {
        resize_delta := (percent_change > 0) ? 0.1 : -0.1 
        new_scale := this.ScaleFactor * (1 + resize_delta)
        
        ; 限制縮放範圍：最小 0.5，最大 2.5
        if (new_scale < 0.5)
            new_scale := 0.5
        else if (new_scale > 2.5)
            new_scale := 2.5

        if (Round(new_scale, 2) != Round(this.ScaleFactor, 2)) {
            this.ScaleFactor := new_scale
            this.RebuildGUI()
        }
    }
    
    ; 重設為預設尺寸 (1.5倍)
    ResetScale() {
        DefaultScale := 1.5 
        if (this.ScaleFactor != DefaultScale) {
            this.ScaleFactor := DefaultScale
            this.RebuildGUI()
        }
    }

    ; 銷毀並重新建立 GUI (用於縮放/重設/切換佈局)
    RebuildGUI() {
        ; 1. 讀取 GUI 的當前實際位置 (如果已存在)
        DetectHiddenWindows On
        IfWinExist, 螢幕鍵盤
        {
            WinGetPos, currentX, currentY, , , 螢幕鍵盤
            this.CurrentX := currentX
            this.CurrentY := currentY
        }
        DetectHiddenWindows Off

        ; 2. 隱藏並銷毀舊的 GUI
        Gui, OSK: Hide
        Gui, OSK: Destroy
        
        ; 3. 重新建立 GUI (會使用新的 this.PrettyName 和字體大小)
        this.Make()
        
        Sleep, 50 
        
        ; 4. 使用上次儲存的位置顯示
        GUI_X := this.CurrentX
        GUI_Y := this.CurrentY
        
        ; *** 修改: 先顯示 GUI 再設定透明度，確保設定生效 ***
        Gui, OSK:Show, % "x" GUI_X " y" GUI_Y " NA", 螢幕鍵盤

        trans_levels := [255, 220, 180, 100]
        WinSet, Transparent, % trans_levels[this.current_trans], 螢幕鍵盤
    }
    
    ; 顯示鍵盤
    Show() {
        this.Enabled := True
        CurrentMonitorIndex := this.GetCurrentMonitorIndex()
        DetectHiddenWindows On
        Gui, OSK: +LastFound
        Gui, OSK:Show, Hide ; 先隱藏顯示以取得視窗 handle 和尺寸
        GUI_Hwnd := WinExist()
        this.GetClientSize(GUI_Hwnd,GUI_Width,GUI_Height)
        DetectHiddenWindows Off
        
        ; *** 修改: 如果已有位置，則使用上次的位置；否則計算初始位置 ***
        if (this.CurrentX != "" and this.CurrentY != "") {
            GUI_X := this.CurrentX
            GUI_Y := this.CurrentY
        } else {
            ; 計算初始置中位置 (螢幕工作區底部中央)
            SysGet, MonWA, MonitorWorkArea, %CurrentMonitorIndex%
            
            GUI_X := ((MonWARight - MonWALeft - GUI_Width) / 2) + MonWALeft
            GUI_Y := MonWABottom - GUI_Height
            
            ; 首次顯示時，儲存預設位置
            this.CurrentX := GUI_X
            this.CurrentY := GUI_Y
        }
        
        Gui, OSK:Show, % "x" GUI_X " y" GUI_Y " NA", 螢幕鍵盤
        ; 啟用按鍵狀態監控計時器
        this.SetTimer("MonitorKeyPresses", 30)
        Return
    }
    
    ; 隱藏鍵盤
    Hide() {
        ; *** 新增: 隱藏前先儲存當前視窗位置 ***
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
        ; 關閉按鍵狀態監控計時器
        this.SetTimer("MonitorKeyPresses", "off")
        ; 隱藏時必須解除 OSK 上的 Shift 鎖定，以免影響系統
        if (this.isShifted) {
             this.isShifted := false
             SendInput, {sc02a up} 
        }
        return
    }

    ; 切換鍵盤顯示/隱藏狀態
    Toggle() {
        If this.Enabled
            this.Hide()
        Else
            this.Show()
        Return
    }
    
    ; 更新佈局切換按鈕的文字
    UpdateLayoutButtonText() {
        if (this.LayoutMode = "bopomofo") {
            ; 當前是注音，按鈕顯示 'En' (切換到英文)
            this.PrettyName["ToggleLayout"] := "En" 
        } else {
            ; 當前是英文，按鈕顯示 '中' (切換到中文)
            this.PrettyName["ToggleLayout"] := "ㄅ" 
        }
    }
    
    ; 切換注音/英文佈局
    ToggleLayout() {
        if (this.LayoutMode = "bopomofo") {
            this.LayoutMode := "qwerty"
        } else {
            this.LayoutMode := "bopomofo"
        }
        
        ; 1. 更新當前的 PrettyName 映射
        this.PrettyName := this.AllPrettyNames[this.LayoutMode]
        
        ; 2. 更新切換按鈕的文字 (在新的 PrettyName 映射中)
        this.UpdateLayoutButtonText() 
        
        ; 3. 重建 GUI
        this.RebuildGUI()
    }

    ; 循環切換透明度等級
    ToggleTransparent() {
        trans_levels := [255, 220, 180, 100]
        this.current_trans := Mod(this.current_trans, trans_levels.Length()) + 1
        WinSet, Transparent, % trans_levels[this.current_trans], 螢幕鍵盤
    }

    ; 提示使用者確認關閉程式
    ConfirmClose() {
        MsgBox, 4, 關閉確認, 是否確定要關閉螢幕鍵盤程式？
        IfMsgBox, Yes
            ExitApp ; 關閉整個腳本
        Return
    }

    ; 取得當前滑鼠所在螢幕的編號
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

    ; 取得 GUI 窗口的客戶區尺寸
    GetClientSize(hwnd, ByRef w, ByRef h) {
        VarSetCapacity(rc, 16)
        DllCall("GetClientRect", "uint", hwnd, "uint", &rc)
        w := NumGet(rc, 8, "int")
        h := NumGet(rc, 12, "int")
        Return
    }
    
    ; 處理按鈕點擊後的邏輯分發
    HandleOSKClick(Key:="") {
        
        if not Key
            Key := A_GuiControl

        if (Key = "placeholder") {
            Return
        }

        ; --- 處理虛擬鍵盤上的 Ctrl+Space ---
        if (Key = "sc039") { ; 如果按下的是空白鍵
            CtrlSC := "sc01d" ; Ctrl 的掃描碼
            if (this.Keys.HasKey(CtrlSC)) {
                ctrl_coords := this.Keys[CtrlSC]
                ctrl_row := ctrl_coords[1]
                ctrl_col := ctrl_coords[2]
                
                ; 檢查 Ctrl 鍵是否在 OSK 上處於 "按下" 狀態
                if (this.Controls[ctrl_row, ctrl_col].Colour = this.ToggledButtonColour) {
                    this.SendModifier(CtrlSC)
                    this.HandleOSKClick("ToggleLayout")
                    Return
                }
            }
        }
        ; --- 結束 Ctrl+Space 處理 ---
        
        ; 處理 OSK Shift 鍵點擊 (鎖定/解鎖模式)
        if (Key = "sc02a" or Key = "sc036") { ; LShift 或 RShift
            
            KeyRow := this.Keys[Key][1]
            KeyCol := this.Keys[Key][2]
            KeyControls := this.Controls[KeyRow, KeyCol]
            
            this.UpdateGraphics(KeyControls, this.ClickFeedbackColour) ; 點擊回饋
            
            ; 1. 切換 OSK 內部鎖定狀態
            this.isShifted := !this.isShifted
            
            ; 2. 發送 Shift 按下/釋放系統事件來同步 OSK 鎖定狀態
            if (this.isShifted) {
                SendInput, {sc02a down}
                NewColour := this.ToggledButtonColour
            } else {
                SendInput, {sc02a up}
                NewColour := this.ButtonColour
            }
            
            ; 3. 更新視覺和所有鍵盤顯示
            this.UpdateGraphics(KeyControls, NewColour)
            this.RefreshAllKeyDisplays()

            Return ; 處理完成
        }
        
        ; *** 修改：移除 "Move" 按鈕的處理邏輯 ***
        ; 處理內部控制功能鍵
        if (Key = "ToggleLayout") {
			KeyRow := this.Keys[Key][1]
			KeyCol := this.Keys[Key][2]
			
			this.UpdateGraphics(this.Controls[KeyRow, KeyCol], this.ClickFeedbackColour)
			this.ToggleLayout()
			SendInput, ^{Space}
			
			Sleep, 100
			Return
        } else if (Key = "ZoomOut") {
            this.Resize(-0.05) ; 縮小
            Return
        } else if (Key = "ZoomIn") {
            this.Resize(0.05) ; 放大
            Return
        } else if (Key = "Reset") { 
            this.ResetScale() ; 重設尺寸
            Return
        } else if (Key = "Transparent") {
            this.ToggleTransparent() ; 切換透明度
            Return
        } else if (Key = "Close") {
            this.ConfirmClose() ; 關閉程式確認
            Return
        } else if (Key = "Hide") {
            this.Toggle() ; 切換顯示/隱藏
            Return
        }
        
        ; 處理複合鍵 (Ctrl, Alt, Win, CapsLock)
        if (this.IsModifier(Key))
            this.SendModifier(Key)
        ; 處理普通按鍵
        else
            this.SendPress(Key)
        return
    }

    ; 檢查按鍵是否為修飾鍵/鎖定鍵
    IsModifier(Key) {
        ; sc02a/sc036 (Shift) 在 HandleOSKClick 中已經被特殊處理了
        return (Key = "sc01d"    ; LCtrl
             or Key = "sc05b"    ; LWin
             or Key = "sc038"    ; LAlt
             or Key = "sc03a"    ; CapsLock
             or Key = "ScrollLock")
    }

    ; 監控所有按鍵的實體狀態
    MonitorAllKeys() {
        ; 1. 監控所有按鍵的實體狀態
        For _, Row in this.Layout {
            For i, Button in Row {
                if (Button.1 = "placeholder" or Button.1 = "ToggleLayout")
                    continue
                    
                if (this.Keys.HasKey(Button.1))
                    this.MonitorKey(Button.1)
            }
        }
        
        ; 2. 只有在 QWERTY 模式且 Shift 狀態不一致時才更新顯示 (避免注音閃爍)
        ; 檢查 isShifted (OSK鎖定) 或 實體 Shift 鍵狀態
        CurrentShiftState := this.isShifted OR GetKeyState("sc02a") OR GetKeyState("sc036")
        
        ; 如果當前顯示的狀態 (由 this.isShifted 決定) 與實際需要顯示的狀態不一致，則強制刷新
        ; 這裡使用一個內部標記來判斷是否需要刷新顯示
        if (this.LayoutMode = "qwerty") {
             if (CurrentShiftState != this.LastDisplayedShiftState) {
                this.RefreshAllKeyDisplays()
                this.LastDisplayedShiftState := CurrentShiftState
             }
        }
        
        Return
    }

    ; 根據 Shift 狀態更新所有按鍵的顯示（文字和顏色）
    RefreshAllKeyDisplays() {
        ; Shift 狀態由 OSK 鎖定狀態 (this.isShifted) 或實體 Shift 鍵狀態決定
        isShiftOn := this.isShifted OR GetKeyState("sc02a") OR GetKeyState("sc036")
        
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
                
                ; 只更新有兩個或更多顯示選項的鍵
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


    ; 檢查單一按鍵狀態並更新視覺效果
    MonitorKey(Key) {
        ; CapsLock/ScrollLock 檢查鎖定狀態，其他檢查實際按下狀態
        KeyOn := GetKeyState(Key, (Key = "sc03a" or Key = "ScrollLock" or Key = "Pause") ? "T" : "")
        
        if (!this.Keys.HasKey(Key))
            return

        KeyRow := this.Keys[Key][1]
        KeyColumn := this.Keys[Key][2]
        
        CurrentColour := this.Controls[KeyRow, KeyColumn].Colour
        NewColour := ""
        
        ; Shift 鍵監控實體狀態
        if (Key = "sc02a" or Key = "sc036") {
            ; 對於 Shift 鍵：如果 OSK 處於鎖定狀態 (this.isShifted)，則優先顯示鎖定顏色
            if (this.isShifted) {
                NewColour := this.ToggledButtonColour ; 保持鎖定色
            } else if (KeyOn and CurrentColour != this.ToggledButtonColour) {
                ; 實體按下，但 OSK 未鎖定
                NewColour := this.ToggledButtonColour
            } else if (not KeyOn and CurrentColour = this.ToggledButtonColour) {
                ; 實體鬆開，且 OSK 未鎖定 (即從實體按下的狀態恢復)
                NewColour := this.ButtonColour
            }
        }
        ; 對於其他修飾鍵/鎖定鍵
        else if (KeyOn and CurrentColour != this.ToggledButtonColour)
            NewColour := this.ToggledButtonColour
        else if (not KeyOn and CurrentColour = this.ToggledButtonColour) 
            NewColour := this.ButtonColour
        
        if (NewColour)
            this.UpdateGraphics(this.Controls[KeyRow, KeyColumn], NewColour)

        Return
    }

    ; 傳送普通按鍵輸入
    SendPress(Key) {
        KeyRow := this.Keys[Key][1]
        KeyCol := this.Keys[Key][2]
        
        this.UpdateGraphics(this.Controls[KeyRow, KeyCol], this.ClickFeedbackColour)
        SendInput, % "{Blind}{" Key "}"
        Sleep, 100
        
        ; 點擊普通鍵後，視覺恢復為標準色。
        ; MonitorAllKeys 計時器會即時檢查並將修飾鍵（如實體 Shift/Ctrl）恢復到按下狀態的顏色。
        this.UpdateGraphics(this.Controls[KeyRow, KeyCol], this.ButtonColour) 

        Return
    }

    ; 傳送修飾鍵（切換鎖定或按下狀態）
    SendModifier(Key) {
        if (Key = "sc03a") ; CapsLock
            SetCapsLockState, % not GetKeyState(Key, "T")
        else if (Key = "ScrollLock")
            SetScrollLockState, % not GetKeyState(Key, "T")
        else {
            ; Ctrl, Alt, Win - 按下則釋放，釋放則按下 (點擊時的切換行為)
            if (GetKeyState(Key))
                SendInput, % "{" Key " up}"
            else
                SendInput, % "{" Key " down}"
        }
        return
    }

    ; 更新按鈕的視覺顏色
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

