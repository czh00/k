; ======================================================================================================================
; Script:           On-Screen Keyboard (螢幕小鍵盤)
; Language:         AutoHotkey v1.1
; Author:           (原始作者未知，由 Gem Gemini AI 整理與註解)
; Description:      一個可自訂主題、可縮放、支援中英切換的螢幕小鍵盤。
; Features:
;   - 深色主題 (可自行修改顏色變數)
;   - QWERTY (英文) 與 Bopomofo (注音) 兩種鍵盤佈局切換
;   - 可透過按鈕或熱鍵縮放鍵盤大小
;   - 可調整鍵盤透明度
;   - 按下實體鍵盤時，螢幕鍵盤會同步顯示按鍵狀態 (例如 Ctrl, Shift 按下時會變色)
;   - 支援視窗拖動、隱藏、關閉
; Hotkeys:
;   - Ctrl + Shift + O : 顯示 / 隱藏螢幕鍵盤
;   - Ctrl + Space      : 在螢幕鍵盤上切換 QWERTY / Bopomofo 佈局 (同時也會送出系統的中英切換指令)
; ======================================================================================================================

; ----------------------------------------------------------------------------------------------------------------------
; §1. 腳本初始化與全域設定 (Script Initialization & Global Settings)
; ----------------------------------------------------------------------------------------------------------------------

; #SingleInstance: 確保此腳本一次只有一個實例在執行。如果再次運行腳本，舊的實例會被新的取代。
#SingleInstance

; SendMode Input: 設定 Send 指令的模式為 "Input"。這是 AHK 中最快、最可靠的模擬按鍵輸入方式，
; 它使用驅動程式層級的事件，能與大多數程式良好地協作，並且不會被使用者的實體鍵盤操作中斷。
SendMode Input

; --- 主要啟動區塊 ---
; 判斷式 `If (A_ScriptFullPath = A_LineFile)` 是一個常用的技巧，
; 用來確保這段程式碼只在腳本直接執行時運行，而不是在被其他腳本 #Include 時運行。
; A_ScriptFullPath 是腳本的完整路徑，A_LineFile 是目前正在讀取的檔案路徑，只有在主腳本中它們才會相等。
If (A_ScriptFullPath = A_LineFile) { 
    ; `Global keyboard := new OSK("dark", "qwerty")`
    ; 建立一個 OSK (On-Screen Keyboard) 類別的實例 (物件)，並將它存放在全域變數 `keyboard` 中。
    ; `new OSK(...)` 會呼叫 OSK 類別中的 `__New()` 方法來進行初始化。
    ; 傳入 "dark" 和 "qwerty" 作為初始主題和鍵盤佈局。
    Global keyboard := new OSK("dark", "qwerty")

    ; --- 系統匣圖示右鍵選單設定 (Tray Menu Configuration) ---
    Menu, Tray, NoStandard        ; 移除所有預設的右鍵選單項目 (例如 Pause, Suspend 等)。
    Menu, Tray, Add, 顯示/隱藏, ToggleTrayHandler ; 新增一個名為 "顯示/隱藏" 的選項，點擊後會執行 ToggleTrayHandler 標籤的程式碼。
    Menu, Tray, Add, 離開, ExitHandler          ; 新增一個名為 "離開" 的選項，點擊後會執行 ExitHandler 標籤的程式碼。
    Menu, Tray, Default, 顯示/隱藏             ; 將 "顯示/隱藏" 設為預設選項 (當使用者左鍵雙擊圖示時觸發)。
    Menu, Tray, Click, 1                      ; 設定為只需要單擊左鍵就能觸發預設選項。
    Menu, Tray, Tip, 螢幕鍵盤 (Ctrl+Shift+O)   ; 設定滑鼠停留在系統匣圖示上時顯示的提示文字。

    ; --- 熱鍵設定 (Hotkey Definitions) ---
    ; `toggle := ObjBindMethod(keyboard, "toggle")`
    ; ObjBindMethod 是一個強大的功能，它可以將一個物件的方法 (這裡是 keyboard 物件的 toggle 方法) 綁定到一個變數上。
    ; 這樣，當呼叫 `toggle` 時，實際上就是在呼叫 `keyboard.toggle()`。這對於將物件方法直接用在 Hotkey 指令上非常方便。
    toggle := ObjBindMethod(keyboard, "toggle")
    Hotkey, ^+O, % toggle ; 設定熱鍵 Ctrl+Shift+O，當按下時，執行上面綁定的 `toggle` 函式 (即 keyboard.toggle())。

    ; 同樣地，綁定 ToggleLayout 方法到 toggleLayout 變數。
    toggleLayout := ObjBindMethod(keyboard, "ToggleLayout")
    ; `~$^Space`: 這是熱鍵的修飾符。
    ;   `~`: "Passthrough" - 當熱鍵觸發時，不會攔截原始按鍵。也就是說，系統仍然會接收到 Ctrl+Space。
    ;   `$`: "Hook" - 使用鍵盤掛鉤來實現熱鍵，通常更可靠。
    ;   `^`: Ctrl 鍵。
    Hotkey, ~$^Space, % toggleLayout

    ; --- 視窗訊息監聽 (Window Message Monitoring) ---
    ; `OnMessage(0x201, "HandleBackgroundClick")`
    ; 註冊一個訊息監聽器。當腳本的 GUI 視窗接收到代碼為 0x201 的訊息時，會自動呼叫 HandleBackgroundClick 函式。
    ; 0x201 是 WM_LBUTTONDOWN 訊息，代表滑鼠左鍵被按下。
    ; 這主要用來實現點擊鍵盤視窗的空白處來拖動視窗的功能。
    OnMessage(0x201, "HandleBackgroundClick")

    ; 呼叫 keyboard 物件的 Show() 方法，在腳本啟動時就顯示鍵盤。
    keyboard.Show()
}
Return ; 結束自動執行區段。腳本會停在這裡，等待熱鍵或事件觸發。

; ----------------------------------------------------------------------------------------------------------------------
; §2. 事件處理函式與標籤 (Event Handlers & Labels)
; ----------------------------------------------------------------------------------------------------------------------

; --- 系統匣選單處理函式 (Tray Menu Handlers) ---
ToggleTrayHandler:
    keyboard.toggle() ; 呼叫 keyboard 物件的 toggle 方法來顯示或隱藏 GUI。
    return

ExitHandler:
    ExitApp ; 結束整個腳本。
    return

; --- GUI 背景點擊處理 (Background Click Handler) ---
; 這個函式由 `OnMessage(0x201, ...)` 觸發。
; 參數 wParam, lParam, msg, hwnd 是由系統傳遞的訊息資訊。
HandleBackgroundClick(wParam, lParam, msg, hwnd) {
    ; `Gui, OSK: +LastFound`: 將腳本的預設視窗目標設為名為 "OSK" 的 GUI 視窗，
    ; 這樣後續的 WinExist() 等指令就會作用在這個視窗上。
    Gui, OSK: +LastFound
    ; `if (hwnd = WinExist())`: 檢查收到訊息的視窗 (hwnd) 是否就是我們的 OSK 視窗。
    if (hwnd = WinExist()) {
        ; `MouseGetPos, , , , clicked_control`: 獲取滑鼠當前位置下的控制項 (按鈕、文字等) 的 HWND (控制代碼)。
        MouseGetPos, , , , clicked_control
        ; `if (clicked_control = "")`: 如果滑鼠下方沒有任何控制項 (即點擊在空白背景上)。
        if (clicked_control = "") {
            ; `PostMessage, 0xA1, 2`: 向 OSK 視窗發送一個訊息。
            ;   `0xA1`: WM_NCLBUTTONDOWN 訊息，代表在非客戶區 (如標題列) 按下左鍵。
            ;   `2`:  HTCAPTION 參數，告訴系統「假裝」使用者點擊的是標題列。
            ; 這樣做的效果就是，使用者可以點擊視窗的任何空白處來拖動它，就像拖動標題列一樣。
            PostMessage, 0xA1, 2
        }
    }
}

; --- 語境敏感熱鍵區段 (Context-sensitive Hotkeys) ---
; `#If (keyboard.Enabled)`: 只有當 `keyboard.Enabled` 這個變數為 True 時，
; 這個 `#If` 和下一個 `#If` 之間的熱鍵才會生效。
; 在這個腳本中，雖然 `#If` 區段是空的，但它是一個保留的結構，
; 如果未來需要新增「只在鍵盤顯示時才有效的熱鍵」，就可以加在這裡。
#If (keyboard.Enabled) 
#If ; 結束語境敏感區段

; --- OSK 按鈕點擊處理 (OSK Button Click Handler) ---
; 這個函式被 GUI 中所有按鈕的 `gHandleOSKClick` 標籤所觸發。
HandleOSKClick() {
    ; `A_GuiControl` 是一個內建變數，它儲存了觸發 g-label 的控制項的關聯變數或文字。
    ; 在這個腳本中，它就是我們在 `Make()` 函式中設定的掃描碼 (例如 "sc029")。
    ; 然後呼叫 keyboard 物件的 HandleOSKClick 方法，並將按下的鍵的掃描碼傳遞給它處理。
    keyboard.HandleOSKClick(A_GuiControl)
    return
}

; ======================================================================================================================
; §3. OSK 類別定義 (The OSK Class Definition)
; ======================================================================================================================
Class OSK
{
    ; --- 類別屬性 (Class Properties / Member Variables) ---
    LayoutMode := "" ; 目前的鍵盤佈局 ("qwerty" 或 "bopomofo")
    
    ; `__New()`: 這是類別的建構函式 (Constructor)。當使用 `new OSK()` 建立物件時，這個方法會被自動呼叫。
    __New(theme:="dark", layout:="qwerty") {
        ; `this.Enabled := False`: `this` 關鍵字代表這個類別的實例本身。
        ; 這個變數用來追蹤鍵盤 GUI 是否可見。初始為 False。
        this.Enabled := False
        this.current_trans := 1 ; 目前的透明度等級 (1-4)
        this.ScaleFactor := 1.5 ; 初始縮放比例
        this.CurrentX := "" ; 用來儲存 GUI 的 X 座標
        this.CurrentY := "" ; 用來儲存 GUI 的 Y 座標
        
        ; 修飾鍵 (Modifier Keys) 列表，用於判斷哪些鍵是像 Ctrl, Alt, Shift, CapsLock 一樣的狀態鍵。
        ; 掃描碼 (Scan Codes): e.g., sc01d 是左 Ctrl, sc03a 是 CapsLock。
        this.Modifiers := ["sc01d", "sc05b", "sc038", "sc03a", "ScrollLock"]
        
        ; --- 顏色主題設定 (Color Theme Settings) ---
        this.Background := "2A2A2A"          ; GUI 背景色 (深灰色)
        this.ButtonColour := "010101"        ; 按鈕預設顏色 (接近黑色)
        this.ClickFeedbackColour := "0078D7" ; 按鈕點擊時的瞬間回饋顏色 (藍色)
        this.ToggledButtonColour := "553b6a" ; 當修飾鍵 (如 Shift, CapsLock) 處於 "開啟" 狀態時的顏色 (紫色)
        this.TextColour := "ffffff"          ; 主要文字顏色 (白色)
        this.ShiftSymbolColour := "ADD8E6"   ; 按下 Shift 時，第二層符號的顏色 (淡藍色)
        this.SecondLineColour := "FFA500"    ; 注音模式下，注音符號的顏色 (橘色)

        ; 一個特殊的鍵列表，在注音模式下，這些鍵上的主要符號 (非注音) 應該顯示為白色。
        this.WhiteSymbolKeysList := "|sc029|sc00d|sc01a|sc01b|sc02b|sc028|"

        ; 使用 ObjBindMethod 將 MonitorAllKeys 方法綁定到 this.MonitorKeyPresses 屬性上，方便之後給 SetTimer 使用。
        this.MonitorKeyPresses := ObjBindMethod(this, "MonitorAllKeys") 
        
        ; 每一行鍵盤的起始 X 軸偏移量 (未使用，保留結構)
        this.RowStartOffsets := {}
        this.RowStartOffsets[2] := 0
        this.RowStartOffsets[3] := 0
        this.RowStartOffsets[4] := 0
        this.RowStartOffsets[5] := 0
        this.RowStartOffsets[6] := 0

        ; --- 鍵盤佈局定義 (Keyboard Layout Definition) ---
        this.Layout := []           ; 主要的佈局陣列，儲存每一行的按鍵資訊。
        this.BopomofoNames := {}    ; 儲存注音佈局下每個按鍵的顯示文字。
        this.QwertyNames := {}      ; 儲存 QWERTY 佈局下每個按鍵的顯示文字。
        this.LayoutMode := layout   ; 從建構函式接收初始佈局模式。
        
        StdKey := 45 ; 標準按鍵的寬度單位

        ; `this.Layout.Push([...])`: 向 Layout 陣列中添加一行。
        ; 每一行是一個陣列，其中每個元素又是一個小陣列，代表一個按鍵。
        ; 按鍵格式: `[ "掃描碼/功能名稱", 寬度 ]`
        ; e.g., ["sc001", StdKey] 代表一個掃描碼為 sc001 (Esc), 寬度為 45 的按鍵。
        ; "placeholder" 是特殊用途的佔位符。
        this.Layout.Push([ ["sc001", StdKey], ["placeholder", 306], ["ToggleLayout", StdKey], ["ZoomOut", StdKey], ["ZoomIn", StdKey], ["Reset", StdKey], ["Transparent"], ["Close", StdKey], ["Hide", StdKey] ]) 
        this.Layout.Push([ ["sc029", StdKey],["sc002", StdKey],["sc003", StdKey],["sc004", StdKey],["sc005", StdKey],["sc006", StdKey],["sc007", StdKey],["sc008", StdKey],["sc009", StdKey],["sc00a", StdKey],["sc00b", StdKey],["sc00c", StdKey],["sc00d", StdKey],["sc00e", 63] ])
        this.Layout.Push([ ["sc00f", 67.5],["sc010", StdKey],["sc011", StdKey],["sc012", StdKey],["sc013", StdKey],["sc014", StdKey],["sc015", StdKey],["sc016", StdKey],["sc017", StdKey],["sc018", StdKey],["sc019", StdKey],["sc01a", StdKey],["sc01b", StdKey],["sc02b", 41] ])
        this.Layout.Push([ ["sc03a", 90],["sc01e", StdKey],["sc01f", StdKey],["sc020", StdKey],["sc021", StdKey],["sc022", StdKey],["sc023", StdKey],["sc024", StdKey],["sc025", StdKey],["sc026", StdKey],["sc027", StdKey],["sc028", StdKey],["sc01c", 67] ])
        this.Layout.Push([ ["sc02a", 112.5],["sc02c", StdKey],["sc02d", StdKey],["sc02e", StdKey],["sc02f", StdKey],["sc030", StdKey],["sc031", StdKey],["sc032", StdKey],["sc033", StdKey],["sc034", StdKey],["sc035", StdKey], ["sc048", 45], ["sc053", 44.5] ]) 
        this.Layout.Push([ ["sc01d", 60], ["sc05b", 60], ["sc038", 60], ["sc039", 360], ["sc04b", 45], ["sc050", 45], ["sc04d", 45] ]) 
        
        ; --- 按鍵顯示名稱定義 (Key Display Names) ---
        SharedNames := {} ; 建立一個物件，儲存兩種佈局共通的按鍵名稱。
        SharedNames["Transparent"] := "◌"     ; 透明度按鈕
        SharedNames["Close"]       := "✕"     ; 關閉按鈕
        SharedNames["Hide"]        := "⇲"     ; 隱藏/顯示按鈕
        SharedNames["ZoomOut"]     := "⊖"     ; 縮小按鈕
        SharedNames["ZoomIn"]      := "⊕"     ; 放大按鈕
        SharedNames["Reset"]       := "↺"     ; 重設大小按鈕
        SharedNames["placeholder"] := ""      ; 佔位符 (無文字)
        SharedNames["sc001"]       := "Esc"   ; Esc 鍵 (掃描碼 sc001)
        SharedNames["sc00e"]       := "←"     ; Backspace 鍵 (掃描碼 sc00e)
        SharedNames["sc00f"]       := "Tab"   ; Tab 鍵 (掃描碼 sc00f)
        SharedNames["sc03a"]       := "⇭"     ; CapsLock 鍵 (掃描碼 sc03a)

        SharedNames["sc01c"]       := "↩"     ; Enter 鍵 (掃描碼 sc01c)
        SharedNames["sc02a"]       := "Shift" ; 左 Shift 鍵 (掃描碼 sc02a)
        SharedNames["sc036"]       := "Shift" ; 右 Shift 鍵 (掃描碼 sc036)
        SharedNames["sc01d"]       := "Ctrl"  ; 左 Ctrl 鍵 (掃描碼 sc01d)
        SharedNames["sc05b"]       := "Win"   ; 左 Win 鍵 (掃描碼 sc05b)
        SharedNames["sc038"]       := "Alt"   ; 左 Alt 鍵 (掃描碼 sc038)
        SharedNames["sc039"]       := "Space" ; 空白鍵 (掃描碼 sc039)
        SharedNames["sc048"]       := "↑"     ; 向上方向鍵 (掃描碼 sc048)
        SharedNames["sc050"]       := "↓"     ; 向下方向鍵 (掃描碼 sc050)
        SharedNames["sc04b"]       := "←"     ; 向左方向鍵 (掃描碼 sc04b)
        SharedNames["sc04d"]       := "→"     ; 向右方向鍵 (掃描碼 sc04d)
        SharedNames["sc053"]       := "Del"   ; Delete 鍵 (掃描碼 sc053)
        
        ; `BopomofoSpecificNames := SharedNames.Clone()`: 複製共通名稱物件，然後在其上添加注音特有的定義。
        BopomofoSpecificNames := SharedNames.Clone()
        ; 格式: `掃描碼 := "預設字元 Shift字元 注音字元"` (用空格分隔)
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
        
        ; 複製共通名稱物件，並添加 QWERTY (英文) 特有的定義。
        QwertySpecificNames := SharedNames.Clone()
        ; 格式: `掃描碼 := "預設字元 Shift字元"` (用空格分隔)
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
        
        ; 將兩種佈局的名稱物件儲存在一個主物件中，方便切換。
        this.AllPrettyNames := {bopomofo: BopomofoSpecificNames, qwerty: QwertySpecificNames}
        
        ; 根據初始設定的 LayoutMode，選擇當前要使用的名稱物件。
        this.PrettyName := this.AllPrettyNames[this.LayoutMode]
        this.UpdateLayoutButtonText() ; 更新中英切換按鈕上的文字
        
        this.Keys := []     ; 儲存每個按鍵的座標 (row, col)，方便快速查找。
        this.Controls := [] ; 儲存每個按鍵的 GUI 控制項控制代碼 (hwnd)，方便更新外觀。
        
        ; `this.Make()`: 呼叫 Make 方法來實際建立 GUI 視窗和所有控制項。
        this.Make()
    }

    ; `SetTimer(TimerID, Period)`: 一個方便設定計時器的包裝方法。
    SetTimer(TimerID, Period) {
        Timer := this[TimerID] ; 取得綁定的方法 (例如 this.MonitorKeyPresses)
        SetTimer % Timer, % Period ; 設定或關閉計時器
        return
    }

    ; `Make()`: 建立 GUI 介面的核心方法。
    Make() {
        ; --- 尺寸計算 (Dimension Calculations) ---
        ScaleFactor := this.ScaleFactor ; 獲取當前的縮放比例
        ButtonHeight := Round(35 * ScaleFactor) ; 計算按鈕高度
        KeySpacing := Round(2 * ScaleFactor)   ; 計算按鍵間距
        StandardWidth := Round(45 * ScaleFactor) ; 計算標準按鈕寬度
        CurrentY := Round(10 * ScaleFactor)      ; 初始 Y 座標
        MarginLeft := Round(10 * ScaleFactor)    ; 左邊距
        MaxRightEdge := 0
        LastButtonY := 0
        FontSize := "s" Round(10 * ScaleFactor) ; 計算字體大小

        ; --- GUI 設定 (GUI Configuration) ---
        ; `Gui, OSK: ...`: 所有對 GUI 的操作都指定作用於名為 "OSK" 的 GUI。
        ; `+AlwaysOnTop`: 視窗總在最上層。
        ; `-DPIScale`: 禁用 AHK 的自動 DPI 縮放，我們自己手動控制縮放。
        ; `+Owner`: 使其成為一個 owned window，可以避免在任務欄顯示圖示。
        ; `-Caption`: 移除標題列。
        ; `+E0x08000000`: 擴充樣式 WS_EX_NOACTIVATE，使鍵盤視窗在點擊時不會搶走前一個視窗的焦點。
        Gui, OSK: +AlwaysOnTop -DPIScale +Owner -Caption +E0x08000000 
        Gui, OSK: Font, %FontSize%, Microsoft JhengHei UI ; 設定字體和大小
        Gui, OSK: Margin, 0, 0 ; 設定 GUI 的邊距為 0
        Gui, OSK: Color, % this.Background ; 設定 GUI 的背景顏色

        ; --- 迴圈建立按鈕 (Button Creation Loop) ---
        ; `For Index, Row in this.Layout`: 遍歷 `this.Layout` 陣列中的每一行。
        ; `Index` 是行號 (從 1 開始)，`Row` 是該行的按鍵陣列。
        For Index, Row in this.Layout {
            X_Offset_Units := this.RowStartOffsets.HasKey(Index) ? this.RowStartOffsets[Index] : 0
            CurrentX := MarginLeft + Round(X_Offset_Units * StandardWidth) 
            
            if (Index > 1) {
                CurrentY += ButtonHeight + KeySpacing ; 計算下一行的 Y 座標
            }
            
            ; `For i, Button in Row`: 遍歷該行中的每一個按鍵。
            ; `i` 是按鍵在該行的索引 (從 1 開始)，`Button` 是按鍵的資訊陣列 (["掃描碼", 寬度])。
            For i, Button in Row {
                Width := Round((Button.2 ? Button.2 : 45) * ScaleFactor) ; 計算按鈕寬度
                HorizontalSpacing := Round((Button.3 ? Button.3 : KeySpacing) * ScaleFactor)
                KeyText := Button.1 ; 按鍵的掃描碼或功能名稱
                isPlaceholder := (KeyText = "placeholder")
                
                if (!isPlaceholder) {
                    AbsolutePosition := "x" CurrentX " y" CurrentY ; 計算按鈕的絕對座標
                    
                    ; --- 建立按鈕的三層結構 ---
                    ; 這是這個腳本的一個技巧，用三層控制項來疊加出一個按鈕，以達到更好的視覺效果。
                    ; 1. 底層 (bottomt): 一個 Text 控制項，作為按鈕的背景板，可以被 g-label 觸發點擊事件。
                    ; 2. 中層 (border): 一個 Progress 控制項，用來做為按鈕的邊框和主要顏色填充。
                    ; 3. 上層 (Label): 一個 Text 控制項，用來顯示按鈕上的文字，設置為透明背景。
                    Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " Background" this.ButtonColour " hwndbottomt gHandleOSKClick", % KeyText
                    Gui, OSK:Add, Progress, % "xp yp w" Width " h" ButtonHeight " Background" this.ButtonColour " hwndborder", 100
                    GuiControl, % "OSK: +C" this.ButtonColour, % border ; 設定 Progress 控制項的填充顏色

                    ; `DisplayText := ...`: 從 PrettyName 物件中獲取該按鍵對應的顯示文字。
                    DisplayText := this.PrettyName.HasKey(KeyText) ? this.PrettyName[KeyText] : KeyText
                    ; `parts := StrSplit(DisplayText, A_Space)`: 將顯示文字用空格分割成陣列 (例如 "q Q" -> ["q", "Q"])。
                    parts := StrSplit(DisplayText, A_Space)
                    
                    ; 判斷是否為特殊功能鍵
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

                    ; --- 根據按鍵類型和佈局模式，決定如何顯示文字 ---
                    if (IsControlKey) {
                        ; 如果是功能鍵，直接顯示文字。
                        ; `0x200`: SS_CENTER 樣式，使文字水平居中。
                        ; `BackgroundTrans`: 透明背景。
                        ; `c...`: 設定文字顏色。
                        ; `hwndh`: 將這個 Text 控制項的控制代碼存到變數 h 中。
                        Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " 0x200 Center BackgroundTrans c" this.TextColour " hwndh", % DisplayText
                        LabelHandles.Text := h
                    } else if (this.LayoutMode = "bopomofo") {
                        ; 如果是注音模式
                        BopomofoChars := "ㄅㄆㄇㄈㄉㄊㄋㄌㄍㄎㄏㄐㄑㄒㄓㄔㄕㄖㄗㄘㄙㄧㄨㄩㄚㄛㄜㄝㄞㄟㄠㄡㄢㄣㄤㄥㄦˊˇˋ˙"
                        if (InStr(this.WhiteSymbolKeysList, "|" KeyText "|")) {
                            ; 如果這個鍵在 WhiteSymbolKeysList 中，顯示第一個部分 (英文/符號)。
                            BopoText := parts[1]
                            Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " 0x200 Center BackgroundTrans c" this.TextColour " hwndh", % BopoText
                            LabelHandles.Text := h
                        } else {
                            ; 否則，優先顯示注音符號。
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
                        ; 如果是 QWERTY 模式且有兩個部分 (如 "q Q")
                        CurrentShiftState := GetKeyState("sc02a") OR GetKeyState("sc036") ; 檢查 Shift 是否按下
                        CurrentText := CurrentShiftState ? parts[2] : parts[1] ; 根據 Shift 狀態選擇顯示大寫或小寫
                        CurrentColour := CurrentShiftState ? this.ShiftSymbolColour : this.TextColour ; 選擇對應的顏色
                        Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " 0x200 Center BackgroundTrans c" CurrentColour " hwndh", % CurrentText
                        LabelHandles.Text := h
                    } else if (parts.Length() = 1 and parts[1] != "") {
                        ; 如果只有一部分文字
                        Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " 0x200 Center BackgroundTrans c" this.TextColour " hwndh", % parts[1]
                        LabelHandles.Text := h
                    } 
                    
                    ; --- 儲存按鍵資訊 ---
                    ; 將按鍵的 行/列 索引存起來，方便之後快速查找。
                    this.Keys[KeyText] := [Index, i]
                    
                    currentShiftState := GetKeyState("sc02a") OR GetKeyState("sc036")
                    
                    ; 根據 Shift 狀態，設定 Shift 鍵的初始顏色。
                    if ((KeyText = "sc02a" OR KeyText = "sc036") and currentShiftState) {
                        currentButtonColour := this.ToggledButtonColour
                    } else {
                        currentButtonColour := this.ButtonColour
                    }

                    ; 將這個按鈕的三層控制項控制代碼和當前顏色儲存到 `this.Controls` 中。
                    this.Controls[Index, i] := {Progress: border, Labels: LabelHandles, Bottom: bottomt, Colour: currentButtonColour}
                    GuiControl, % "OSK: +C" currentButtonColour, % border
                    GuiControl, % "OSK: +Background" currentButtonColour, % bottomt
                    
                    ; 更新鍵盤的最大寬度和高度
                    RightEdge := CurrentX + Width
                    if (RightEdge > MaxRightEdge)
                        MaxRightEdge := RightEdge
                    LastButtonY := CurrentY
                }
                CurrentX += Width + HorizontalSpacing ; 計算下一個按鈕的 X 座標
            }
        }
        
        ; --- 顯示 GUI ---
        TotalWidth := MaxRightEdge + MarginLeft
        TotalHeight := LastButtonY + ButtonHeight + MarginLeft
        ; `Gui, OSK:Show, ... Hide`: 以隱藏的方式先顯示 GUI，這樣可以先計算出它的尺寸，但使用者還看不到。
        Gui, OSK:Show, % "w" TotalWidth " h" TotalHeight " Hide"
        Return
    }

    ; `Resize(percent_change)`: 處理鍵盤縮放的方法。
    Resize(percent_change) {
        resize_delta := (percent_change > 0) ? 0.1 : -0.1 ; 計算縮放增量
        new_scale := this.ScaleFactor * (1 + resize_delta)
        ; 限制縮放範圍在 0.5 到 2.5 之間。
        if (new_scale < 0.5)
            new_scale := 0.5
        else if (new_scale > 2.5)
            new_scale := 2.5

        ; 只有在縮放比例實際改變時才重建 GUI，避免不必要的刷新。
        if (Round(new_scale, 2) != Round(this.ScaleFactor, 2)) {
            this.ScaleFactor := new_scale
            this.RebuildGUI()
        }
    }
    
    ; `ResetScale()`: 重設縮放比例到預設值。
    ResetScale() {
        DefaultScale := 1.5 
        if (this.ScaleFactor != DefaultScale) {
            this.ScaleFactor := DefaultScale
            this.RebuildGUI()
        }
    }

    ; `RebuildGUI()`: 重新建立整個 GUI 介面。用於縮放或切換佈局後。
    RebuildGUI() {
        DetectHiddenWindows On ; 允許指令作用於隱藏的視窗
        IfWinExist, 螢幕鍵盤
        {
            ; 獲取當前視窗的位置，以便在重建後恢復到相同位置。
            WinGetPos, currentX, currentY, , , 螢幕鍵盤
            this.CurrentX := currentX
            this.CurrentY := currentY
        }
        DetectHiddenWindows Off

        Gui, OSK: Hide     ; 隱藏舊視窗
        Gui, OSK: Destroy  ; 銷毀舊視窗和所有控制項
        this.Make()        ; 呼叫 Make() 根據新的 ScaleFactor 或 LayoutMode 重新建立所有東西
        Sleep, 50          ; 短暫延遲確保銷毀和重建過程順利
        
        GUI_X := this.CurrentX
        GUI_Y := this.CurrentY
        
        ; 顯示新建立的 GUI，並恢復到之前的位置。
        Gui, OSK:Show, % "x" GUI_X " y" GUI_Y " NA", 螢幕鍵盤
        ; 根據 current_trans 恢復透明度設定。
        trans_levels := [255, 220, 180, 100] ; 255=不透明
        WinSet, Transparent, % trans_levels[this.current_trans], 螢幕鍵盤
    }
    
    ; `Show()`: 顯示鍵盤視窗。
    Show() {
        this.Enabled := True ; 將啟用狀態設為 True
        CurrentMonitorIndex := this.GetCurrentMonitorIndex() ; 獲取滑鼠所在螢幕的索引
        DetectHiddenWindows On
        Gui, OSK: +LastFound
        Gui, OSK:Show, Hide ; 先隱藏顯示以獲取尺寸
        GUI_Hwnd := WinExist()
        this.GetClientSize(GUI_Hwnd,GUI_Width,GUI_Height) ; 獲取 GUI 的實際客戶區寬高
        DetectHiddenWindows Off
        
        if (this.CurrentX != "" and this.CurrentY != "") {
            ; 如果已經有儲存的位置，就使用它。
            GUI_X := this.CurrentX
            GUI_Y := this.CurrentY
        } else {
            ; 否則，計算螢幕底部中央的位置。
            SysGet, MonWA, MonitorWorkArea, %CurrentMonitorIndex%
            GUI_X := ((MonWARight - MonWALeft - GUI_Width) / 2) + MonWALeft
            GUI_Y := MonWABottom - GUI_Height
            this.CurrentX := GUI_X
            this.CurrentY := GUI_Y
        }
        
        ; 以計算好的位置顯示視窗，"NA" 選項表示不要啟動視窗 (不搶焦點)。
        Gui, OSK:Show, % "x" GUI_X " y" GUI_Y " NA", 螢幕鍵盤
        ; 啟動一個計時器，每 30 毫秒執行一次 MonitorKeyPresses 方法，來監控實體鍵盤的狀態。
        this.SetTimer("MonitorKeyPresses", 30)
        Return
    }
    
    ; `Hide()`: 隱藏鍵盤視窗。
    Hide() {
        DetectHiddenWindows On
        IfWinExist, 螢幕鍵盤
        {
            ; 隱藏前先儲存當前位置。
            WinGetPos, currentX, currentY, , , 螢幕鍵盤
            this.CurrentX := currentX
            this.CurrentY := currentY
        }
        DetectHiddenWindows Off

        this.Enabled := False ; 將啟用狀態設為 False
        Gui, OSK: Hide
        ; 關閉監控鍵盤的計時器，節省效能。
        this.SetTimer("MonitorKeyPresses", "off")
        return
    }

    ; `Toggle()`: 在顯示和隱藏之間切換。
    Toggle() {
        If this.Enabled
            this.Hide()
        Else
            this.Show()
        Return
    }
    
    ; `UpdateLayoutButtonText()`: 更新中英切換按鈕上的文字。
    UpdateLayoutButtonText() {
        if (this.LayoutMode = "bopomofo") {
            this.PrettyName["ToggleLayout"] := "En" ; 目前是注音，按鈕顯示 "En"
        } else {
            this.PrettyName["ToggleLayout"] := "ㄅ" ; 目前是英文，按鈕顯示 "ㄅ"
        }
    }
    
    ; `ToggleLayout()`: 切換鍵盤佈局。
    ToggleLayout() {
        if (this.LayoutMode = "bopomofo") {
            this.LayoutMode := "qwerty"
        } else {
            this.LayoutMode := "bopomofo"
        }
        
        this.PrettyName := this.AllPrettyNames[this.LayoutMode] ; 根據新模式選擇對應的名稱物件
        this.UpdateLayoutButtonText() ; 更新切換按鈕的文字
        this.RebuildGUI() ; 重建 GUI 以應用新的佈局
    }

    ; `ToggleTransparent()`: 切換透明度。
    ToggleTransparent() {
        trans_levels := [255, 220, 180, 100] ; 定義四個透明度等級
        this.current_trans := Mod(this.current_trans, trans_levels.Length()) + 1 ; 在 1-4 之間循環
        WinSet, Transparent, % trans_levels[this.current_trans], 螢幕鍵盤 ; 設定視窗透明度
    }

    ; `ConfirmClose()`: 顯示確認關閉的對話框。
    ConfirmClose() {
        MsgBox, 4, 關閉確認, 是否確定要關閉螢幕鍵盤程式？ ; 4 = Yes/No 按鈕
        IfMsgBox, Yes
            ExitApp ; 如果使用者點擊 Yes，則退出程式
        Return
    }

    ; `GetCurrentMonitorIndex()`: 獲取滑鼠當前所在螢幕的索引值。
    GetCurrentMonitorIndex() {
        CoordMode, Mouse, Screen ; 將滑鼠座標模式設為相對於整個螢幕
        MouseGetPos, mx, my
        SysGet, monitorsCount, 80 ; 獲取螢幕總數
        Loop %monitorsCount%{
            SysGet, monitor, Monitor, %A_Index% ; 獲取每個螢幕的邊界
            if (monitorLeft <= mx && mx <= monitorRight && monitorTop <= my && monitorBottom)
                Return A_Index ; 如果滑鼠在該螢幕內，返回其索引
        }
        Return 1 ; 如果找不到，預設返回 1
    }

    ; `GetClientSize()`: 透過 DllCall 獲取視窗的內部客戶區大小 (不包含邊框和標題列)。
    GetClientSize(hwnd, ByRef w, ByRef h) {
        VarSetCapacity(rc, 16) ; 準備一個 16 字節的記憶體空間來儲存 RECT 結構
        DllCall("GetClientRect", "uint", hwnd, "uint", &rc)
        w := NumGet(rc, 8, "int") ; 從記憶體中讀取寬度
        h := NumGet(rc, 12, "int") ; 從記憶體中讀取高度
        Return
    }
    
    ; `HandleOSKClick()`: 處理所有來自 GUI 的按鈕點擊事件的核心方法。
    HandleOSKClick(Key:="") {
        
        if not Key
            Key := A_GuiControl ; 如果沒有傳入 Key，就從內建變數 A_GuiControl 獲取

        if (Key = "placeholder") {
            Return
        }

        ; 特殊處理: 如果點擊空白鍵時 Ctrl 鍵是按下的，則視為切換佈局。
        if (Key = "sc039") {
            CtrlSC := "sc01d"
            if (this.Keys.HasKey(CtrlSC)) {
                ctrl_coords := this.Keys[CtrlSC]
                ctrl_row := ctrl_coords[1]
                ctrl_col := ctrl_coords[2]
                
                ; 檢查螢幕鍵盤上的 Ctrl 按鈕是否處於 "按下" 的顏色狀態。
                if (this.Controls[ctrl_row, ctrl_col].Colour = this.ToggledButtonColour) {
                    this.SendModifier(CtrlSC) ; 模擬釋放 Ctrl 鍵
                    this.HandleOSKClick("ToggleLayout") ; 觸發切換佈局
                    Return
                }
            }
        }
        
        ; 根據傳入的 Key (功能名稱) 執行對應的操作。
        if (Key = "ToggleLayout") {
			KeyRow := this.Keys[Key][1]
			KeyCol := this.Keys[Key][2]
			
            ; 顯示點擊回饋，然後切換佈局，並模擬發送 Ctrl+Space 給系統。
			this.UpdateGraphics(this.Controls[KeyRow, KeyCol], this.ClickFeedbackColour)
			this.ToggleLayout()
			SendInput, ^{Space}
			
			Sleep, 100
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
        
        ; 如果不是上面的特殊功能鍵，就判斷它是一般按鍵還是修飾鍵。
        if (this.IsModifier(Key))
            this.SendModifier(Key) ; 如果是修飾鍵 (Ctrl, Alt, Shift...)，呼叫 SendModifier
        else
            this.SendPress(Key) ; 如果是一般按鍵，呼叫 SendPress
        return
    }

    ; `IsModifier(Key)`: 判斷一個鍵是否為修飾鍵。
    IsModifier(Key) {
        ; 返回一個布林值 (True/False)。
        return (Key = "sc02a"    ; 左 Shift
             or Key = "sc036"    ; 右 Shift
             or Key = "sc01d"    ; 左 Ctrl
             or Key = "sc05b"    ; 左 Win
             or Key = "sc038"    ; 左 Alt
             or Key = "sc03a"    ; CapsLock
             or Key = "ScrollLock")
    }

    ; `MonitorAllKeys()`: 由計時器定期執行的函式，用來監控實體鍵盤的狀態並更新 GUI。
    MonitorAllKeys() {
        ; 遍歷佈局中的所有按鍵
        For _, Row in this.Layout {
            For i, Button in Row {
                if (Button.1 = "placeholder" or Button.1 = "ToggleLayout")
                    continue
                if (this.Keys.HasKey(Button.1))
                    this.MonitorKey(Button.1) ; 對每個按鍵呼叫 MonitorKey
            }
        }
        
        ; 檢查當前實體 Shift 鍵的狀態
        CurrentShiftState := GetKeyState("sc02a") OR GetKeyState("sc036")
        
        if (this.LayoutMode = "qwerty") {
             ; 如果 Shift 狀態改變了 (從沒按到按下，或反之)，就刷新整個鍵盤的顯示。
             if (CurrentShiftState != this.LastDisplayedShiftState) {
                this.RefreshAllKeyDisplays()
                this.LastDisplayedShiftState := CurrentShiftState
             }
        }
        
        Return
    }

    ; `RefreshAllKeyDisplays()`: 刷新所有按鍵上的文字 (主要用於 QWERTY 模式下的大小寫切換)。
    RefreshAllKeyDisplays() {
        isShiftOn := GetKeyState("sc02a") OR GetKeyState("sc036")
        
        if (this.LayoutMode != "qwerty") {
            return
        }

        ; 遍歷所有按鍵
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
                
                ; 如果按鍵有兩個部分 (例如 "q Q")
                if (parts.Length() >= 2) {
                    if (isShiftOn) {
                        ; 如果 Shift 按下，顯示第二部分，並使用 Shift 顏色。
                        newText := parts[2]
                        newColour := this.ShiftSymbolColour
                    } else {
                        ; 否則，顯示第一部分，並使用預設文字顏色。
                        newText := parts[1]
                        newColour := this.TextColour
                    }
                    
                    ; 使用 GuiControl 更新文字標籤的顏色和內容。
                    GuiControl, OSK: +c%newColour%, % TextLabel
                    GuiControl, OSK:, % TextLabel, % newText
                }
            }
        }
        
        ; `WinSet, Redraw`: 強制重繪視窗，確保所有更改都立即顯示。
        Gui, OSK: +LastFound
        WinSet, Redraw, , 螢幕鍵盤
    }

    ; `MonitorKey(Key)`: 監控單一按鍵的狀態並更新其顏色。
    MonitorKey(Key) {
        ; `GetKeyState(...)`: 獲取指定按鍵的狀態。
        ; 對於 CapsLock 等切換鍵，使用 "T" 模式來獲取其 On/Off 狀態，而不是物理上的按下狀態。
        KeyOn := GetKeyState(Key, (Key = "sc03a" or Key = "ScrollLock" or Key = "Pause") ? "T" : "")
        
        if (!this.Keys.HasKey(Key))
            return

        KeyRow := this.Keys[Key][1]
        KeyColumn := this.Keys[Key][2]
        
        CurrentColour := this.Controls[KeyRow, KeyColumn].Colour
        NewColour := ""
        
        ; 如果系統回報按鍵是按下的，但我們的 GUI 顯示的不是 "按下" 顏色，
        ; 就把 NewColour 設為 "按下" 顏色。
        if (KeyOn and CurrentColour != this.ToggledButtonColour)
            NewColour := this.ToggledButtonColour
        ; 反之，如果系統回報按鍵是放開的，但我們的 GUI 顯示的是 "按下" 顏色，
        ; 就把 NewColour 設為預設顏色。
        else if (not KeyOn and CurrentColour = this.ToggledButtonColour) 
            NewColour := this.ButtonColour
        
        ; 如果顏色需要改變，就呼叫 UpdateGraphics 來更新。
        if (NewColour)
            this.UpdateGraphics(this.Controls[KeyRow, KeyColumn], NewColour)

        Return
    }

    ; `SendPress(Key)`: 模擬一次完整的按鍵點擊 (按下後立即放開)。
    SendPress(Key) {
        KeyRow := this.Keys[Key][1]
        KeyCol := this.Keys[Key][2]
        
        ; 1. 將按鈕顏色變為點擊回饋色，讓使用者看到視覺回饋。
        this.UpdateGraphics(this.Controls[KeyRow, KeyCol], this.ClickFeedbackColour)
        ; 2. 使用 SendInput 發送按鍵。`{Blind}` 選項可以避免觸發 AHK 自身的熱鍵。
        SendInput, % "{Blind}{" Key "}"
        ; 3. 短暫延遲，讓回饋色可見。
        Sleep, 100
        ; 4. 將按鈕顏色恢復為預設顏色。
        this.UpdateGraphics(this.Controls[KeyRow, KeyCol], this.ButtonColour) 

        Return
    }

    ; `SendModifier(Key)`: 處理修飾鍵的點擊。
    SendModifier(Key) {
        KeyControls := this.Controls[this.Keys[Key][1], this.Keys[Key][2]]
        ; 1. 顯示點擊回饋色。
        this.UpdateGraphics(KeyControls, this.ClickFeedbackColour)
        Sleep, 100 ; 短暫延遲
        
        if (Key = "sc03a") ; 如果是 CapsLock
            SetCapsLockState, % not GetKeyState(Key, "T") ; 將其狀態反轉
        else if (Key = "ScrollLock") ; 如果是 ScrollLock
            SetScrollLockState, % not GetKeyState(Key, "T") ; 將其狀態反轉
        else {
            ; 對於 Ctrl, Alt, Shift, Win 這些鍵
            if (GetKeyState(Key))
                SendInput, % "{" Key " up}" ; 如果它目前是按下的，就發送 "放開" 指令。
            else
                SendInput, % "{" Key " down}" ; 如果它目前是放開的，就發送 "按下" 指令。
        }
        ; 注意：這裡不需要手動將顏色改回來。
        ; 因為我們已經模擬了系統按鍵事件，下一次 MonitorKey 計時器執行時，
        ; 它會偵測到系統狀態的改變，並自動將螢幕鍵盤上的按鈕顏色更新為正確的狀態 (ToggledButtonColour 或 ButtonColour)。
        return
    }

    ; `UpdateGraphics(Obj, Colour)`: 更新單一按鈕視覺外觀的通用函式。
    UpdateGraphics(Obj, Colour){
        ; `GuiControl, % "OSK: +C" Colour, % Obj.Progress`: 更新 Progress Bar 的顏色。
        GuiControl, % "OSK: +C" Colour, % Obj.Progress
        ; `GuiControl, % "OSK: +Background" Colour, % Obj.Bottom`: 更新底層 Text 的背景色。
        GuiControl, % "OSK: +Background" Colour, % Obj.Bottom 
        ; `GuiControl, OSK: +Redraw, ...`: 強制重繪控制項以立即顯示變更。
        GuiControl, OSK: +Redraw, % Obj.Progress
        GuiControl, OSK: +Redraw, % Obj.Bottom
        
        TextLabel := Obj.Labels.Text
        if (TextLabel != "") {
            GuiControl, OSK: +Redraw, % TextLabel
        }

        ; 最後，更新儲存在物件中的顏色狀態。
        Obj.Colour := Colour
        Return
    }
}
