#SingleInstance
SendMode Input

; 程式啟動與熱鍵設定
If (A_ScriptFullPath = A_LineFile) { 
    Global keyboard := new OSK("dark", "bopomofo")

    ; 設定熱鍵 Ctrl+Shift+O 來顯示或隱藏鍵盤
    toggle := ObjBindMethod(keyboard, "toggle")
    Hotkey, ^+O, % toggle 

    keyboard.Show()
}
Return 

; 語境敏感熱鍵
#If, keyboard.Enabled
#If

; 處理 GUI 點擊事件
HandleOSKClick() {
    if (A_GuiControl = "") {
        return
    }
    
    ; 將點擊傳遞給 OSK 類別的處理方法
    keyboard.HandleOSKClick(A_GuiControl)
    return
}

Class OSK
{

    __New(theme:="dark", layout:="qwerty") {
        this.Enabled := False
        this.current_trans := 1 ; 當前透明度等級 (1 = 255/完全不透明)
        this.ScaleFactor := 1.5 ; 鍵盤縮放比例 (預設 1.5)

        this.CurrentX := 0 ; 儲存當前 X 座標
        this.CurrentY := 0 ; 儲存當前 Y 座標

        this.Keys := [] ; 鍵名與座標映射
        this.Controls := [] ; 控件 HWND 儲存
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


        this.MonitorKeyPresses := ObjBindMethod(this, "MonitorAllKeys") 
        
        ; 每行第一個鍵的 X 座標偏移量
        this.RowStartOffsets := {}
        this.RowStartOffsets[2] := 0
        this.RowStartOffsets[3] := 0
        this.RowStartOffsets[4] := 0
        this.RowStartOffsets[5] := 0
        this.RowStartOffsets[6] := 0

        this.Layout := []

        if (layout = "bopomofo") {
            
            StdKey := 45 ; 標準鍵寬
            
            ; Row 1: 功能鍵 (Esc, 移動, 縮放, 重設, 透明度, 關閉, 隱藏)
            this.Layout.Push([ ["sc001", StdKey], ["Move", 355], ["ZoomOut", StdKey], ["ZoomIn", StdKey], ["Reset", StdKey], ["Transparent"], ["Close", StdKey], ["Hide", StdKey] ]) 
            
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
            
            ; 按鍵顯示文字 (使用掃描碼)
            this.PrettyName := {} 
            this.PrettyName["Move"]        := "移動"
            this.PrettyName["Transparent"] := "透明"
            this.PrettyName["Close"]       := "關閉"
            this.PrettyName["Hide"]        := "隱藏"
            this.PrettyName["ZoomOut"]     := "縮小"
            this.PrettyName["ZoomIn"]      := "放大"
            this.PrettyName["Reset"]       := "重設" 
            this.PrettyName["placeholder"] := ""
            
            ; 修飾鍵和特殊功能鍵
            this.PrettyName["sc001"]       := "Esc"       
            this.PrettyName["sc00e"]       := "BS"       ; Backspace
            this.PrettyName["sc00f"]       := "Tab"       
            this.PrettyName["sc03a"]       := "Caps Lock" 
            this.PrettyName["sc01c"]       := "Enter"     
            this.PrettyName["sc02a"]       := "Shift"     ; LShift
            this.PrettyName["sc036"]       := "Shift"     ; RShift
            this.PrettyName["sc01d"]       := "Ctrl"      ; LCtrl
            this.PrettyName["sc05b"]       := "Win"       ; LWin
            this.PrettyName["sc038"]       := "Alt"       ; LAlt
            this.PrettyName["sc039"]       := "Space"     ; Space
            this.PrettyName["sc048"]       := "↑"         ; Up
            this.PrettyName["sc050"]       := "↓"         ; Down
            this.PrettyName["sc04b"]       := "←"         ; Left
            this.PrettyName["sc04d"]       := "→"         ; Right
            this.PrettyName["sc053"]       := "Del"       
            
            ; 數字/符號/注音鍵定義
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
            
            ; QWERTY 列定義
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
            
            ; ASDFG 列定義
            this.PrettyName["sc01e"]       := "A ㄇ"
            this.PrettyName["sc01f"]       := "S ㄋ"
            this.PrettyName["sc020"]       := "K ㄎ"
            this.PrettyName["sc021"]       := "F ㄑ"
            this.PrettyName["sc022"]       := "G ㄕ"
            this.PrettyName["sc023"]       := "H ㄘ"
            this.PrettyName["sc024"]       := "J ㄨ"
            this.PrettyName["sc025"]       := "K ㄜ"
            this.PrettyName["sc026"]       := "L ㄠ"
            this.PrettyName["sc027"]       := "; : ㄤ" 
            this.PrettyName["sc028"]       := "' """ 
            
            ; ZXCVB 列定義
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

    ; 設定計時器 (用於監控按鍵狀態)
    SetTimer(TimerID, Period) {
        Timer := this[TimerID]
        SetTimer % Timer, % Period
        return
    }

    ; 繪製 GUI 介面與按鍵
    Make() {
        ScaleFactor := this.ScaleFactor 
        ButtonHeight := Round(30 * ScaleFactor)
        KeySpacing := Round(2 * ScaleFactor)
        StandardWidth := Round(45 * ScaleFactor)
        
        CurrentY := Round(10 * ScaleFactor) 
        MarginLeft := Round(10 * ScaleFactor)
        
        ; GUI 基本設定
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
                
                ; 檢查是否為佔位符鍵 (不繪製但佔用空間)
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
                                  or KeyText = "sc04d" or KeyText = "Move" or KeyText = "Transparent" 
                                  or KeyText = "Hide" or KeyText = "Close" 
                                  or KeyText = "ZoomOut" or KeyText = "ZoomIn" or KeyText = "Reset")
                                  
                    labels := [] 
                    BopomofoChars := "ㄅㄆㄇㄈㄉㄊㄋㄌㄍㄎㄏㄐㄑㄒㄓㄔㄕㄖㄗㄘㄙㄧㄨㄩㄚㄛㄜㄝㄞㄟㄠㄡㄢㄣㄤㄥㄦˊˇˋ˙"
                    
                    ; 文字區塊尺寸計算
                    TL_X := CurrentX + KeySpacing
                    TL_Y := CurrentY + KeySpacing
                    BR_Y := CurrentY + (ButtonHeight / 2)
                    Full_Text_W := Width - KeySpacing * 2
                    Text_H := (ButtonHeight / 2) - KeySpacing * 2

                    if (IsControlKey) {
                        ; 情況 1: 控制鍵 - 單色居中
                        Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " Center BackgroundTrans c" this.TextColour " hwndh", % DisplayText
                        labels.Push(h)
                    } else if (parts.Length() = 1 and parts[1] != "") {
                        ; 情況 2: 單字元鍵 - 單色居中
                        Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " Center BackgroundTrans c" this.TextColour " hwndh", % parts[1]
                        labels.Push(h)
                    } else if (parts.Length() = 2) {
                        isBopomofo := InStr(BopomofoChars, parts[2])
                        
                        if (isBopomofo) {
                            ; 情況 3a: 字母 + 注音 - 上下分行居中
                            topColour := this.TextColour
                            bottomColour := this.SecondLineColour
                            
                            Gui, OSK:Add, Text, % "x" TL_X " y" TL_Y " w" Full_Text_W " h" Text_H " Center BackgroundTrans c" topColour " hwndh", % parts[1] ; 上方 QWERTY
                            labels.Push(h)
                            Gui, OSK:Add, Text, % "x" TL_X " y" BR_Y " w" Full_Text_W " h" Text_H " Center BackgroundTrans c" bottomColour " hwndh", % parts[2] ; 下方 注音
                            labels.Push(h)
                        } else {
                            ; 情況 3b: 符號 + Shift符號 - 左右分行靠上
                            Gui, OSK:Add, Text, % "x" TL_X " y" TL_Y " w" (Width/2 - KeySpacing) " h" Text_H " Left BackgroundTrans c" this.TextColour " hwndh", % parts[1] ; 左上 (基本字元)
                            labels.Push(h)
                            Gui, OSK:Add, Text, % "x" (CurrentX + Width/2) " y" TL_Y " w" (Width/2 - KeySpacing) " h" Text_H " Right BackgroundTrans c" this.ShiftSymbolColour " hwndh", % parts[2] ; 右上 (Shift符號)
                            labels.Push(h)
                        }
                    } else if (parts.Length() >= 3) {
                        ; 情況 4: 三個文字 (數字/符號/注音)
                        
                        Gui, OSK:Add, Text, % "x" TL_X " y" TL_Y " w" Full_Text_W " h" Text_H " BackgroundTrans c" this.TextColour " Left hwndh", % parts[1] ; 左上 (基本字元)
                        labels.Push(h)
                        
                        Gui, OSK:Add, Text, % "x" TL_X " y" TL_Y " w" Full_Text_W " h" Text_H " BackgroundTrans c" this.ShiftSymbolColour " Right hwndh", % parts[2] ; 右上 (Shift 符號)
                        labels.Push(h)
                        
                        Gui, OSK:Add, Text, % "x" TL_X " y" BR_Y " w" Full_Text_W " h" Text_H " BackgroundTrans c" this.SecondLineColour " Right hwndh", % parts[3] ; 右下 (注音)
                        labels.Push(h)
                    } else {
                        ; 備用
                        Gui, OSK:Add, Text, % AbsolutePosition " w" Width " h" ButtonHeight " hwndh",
                        labels.Push(h)
                    }
                    
                    ; 儲存按鍵資訊與控件句柄
                    this.Keys[KeyText] := [Index, i]
                    this.Controls[Index, i] := {Progress: border, Labels: labels, Bottom: bottomt, Colour: this.ButtonColour}
                }
                
                ; 更新下一按鍵的起始 X 座標
                CurrentX += Width + HorizontalSpacing
            }
        }
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

    ; 銷毀並重新建立 GUI (用於縮放/重設)
    RebuildGUI() {
        ; 1. 讀取 GUI 的當前實際位置
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
        
        ; 3. 重新建立 GUI
        this.Make()
        
        Sleep, 50 
        
        ; 4. 使用上次儲存的位置顯示，並重新設定透明度
        GUI_X := this.CurrentX
        GUI_Y := this.CurrentY
        
        ; 透明度等級列表
        trans_levels := [255, 220, 180, 100]
        WinSet, Transparent, % trans_levels[this.current_trans], 螢幕鍵盤

        Gui, OSK:Show, % "x" GUI_X " y" GUI_Y " NA", 螢幕鍵盤
    }

    ; 顯示鍵盤
    Show() {
        this.Enabled := True
        CurrentMonitorIndex := this.GetCurrentMonitorIndex()
        DetectHiddenWindows On
        Gui, OSK: +LastFound
        Gui, OSK:Show, Hide
        GUI_Hwnd := WinExist()
        this.GetClientSize(GUI_Hwnd,GUI_Width,GUI_Height)
        DetectHiddenWindows Off
        
        ; 計算初始置中位置 (螢幕工作區底部中央)
        SysGet, MonWA, MonitorWorkArea, %CurrentMonitorIndex%
        
        GUI_X := ((MonWARight - MonWALeft - GUI_Width) / 2) + MonWALeft
        GUI_Y := MonWABottom - GUI_Height
        
        ; 首次顯示時，儲存預設位置
        this.CurrentX := GUI_X
        this.CurrentY := GUI_Y
        
        Gui, OSK:Show, % "x" GUI_X " y" GUI_Y " NA", 螢幕鍵盤
        ; 啟用按鍵狀態監控計時器
        this.SetTimer("MonitorKeyPresses", 30)
        Return
    }
    
    ; 隱藏鍵盤
    Hide() {
        this.Enabled := False
        Gui, OSK: Hide
        ; 關閉按鍵狀態監控計時器
        this.SetTimer("MonitorKeyPresses", "off")
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
            if (monitorLeft <= mx && mx <= monitorRight && monitorTop <= my && my <= monitorBottom)
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

        ; 忽略佔位符
        if (Key = "placeholder") {
            Return
        }

        ; 處理內部控制功能鍵
        if (Key = "Move") {
            PostMessage, 0xA1, 2 ; 允許拖曳視窗
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
            this.Hide() ; 隱藏鍵盤
            Return
        }
        
        ; 處理複合鍵 (Shift, Ctrl, Alt, Win, CapsLock)
        if (this.IsModifier(Key))
            this.SendModifier(Key)
        ; 處理普通按鍵
        else
            this.SendPress(Key)
        return
    }

    ; 檢查按鍵是否為修飾鍵/鎖定鍵
    IsModifier(Key) {
        return (Key = "sc02a"    ; LShift
             or Key = "sc036"    ; RShift
             or Key = "sc01d"    ; LCtrl
             or Key = "sc05b"    ; LWin
             or Key = "sc038"    ; LAlt
             or Key = "sc03a"    ; CapsLock
             or Key = "ScrollLock")
    }

    ; 監控所有按鍵的實體狀態
    MonitorAllKeys() {
        For _, Row in this.Layout {
            For i, Button in Row {
                if (Button.1 = "placeholder")
                    continue
                
                if (this.Keys.HasKey(Button.1))
                    this.MonitorKey(Button.1)
            }
        }
        Return
    }

    ; 檢查單一按鍵狀態並更新視覺效果
    MonitorKey(Key) {
        ; 獲取按鍵狀態，鎖定鍵使用 'T' 狀態
        KeyOn := GetKeyState(Key, (Key = "sc03a" or Key = "ScrollLock" or Key = "Pause") ? "T" : "")
        
        if (!this.Keys.HasKey(Key))
            return

        KeyRow := this.Keys[Key][1]
        KeyColumn := this.Keys[Key][2]
        
        CurrentColour := this.Controls[KeyRow, KeyColumn].Colour
        NewColour := ""

        ; 1. 鍵盤已按下/鎖定，且顏色非鎖定色 -> 變更為鎖定色
        if (KeyOn and CurrentColour != this.ToggledButtonColour)
            NewColour := this.ToggledButtonColour
        
        ; 2. 鍵盤未按下/鎖定，但顏色是鎖定色 -> 變更回預設色
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
        
        ; 點擊時短暫變更顏色
        this.UpdateGraphics(this.Controls[KeyRow, KeyCol], this.ClickFeedbackColour)
        
        ; 傳送按鍵
        SendInput, % "{Blind}{" Key "}"

        Sleep, 100
        ; 變回按鈕預設顏色
        this.UpdateGraphics(this.Controls[KeyRow, KeyCol], this.ButtonColour) 
        Return
    }

    ; 傳送修飾鍵（切換鎖定或按下狀態）
    SendModifier(Key) {
        ; CapsLock 和 ScrollLock 使用 Set...State 切換
        if (Key = "sc03a") ; CapsLock
            SetCapsLockState, % not GetKeyState(Key, "T")
        else if (Key = "ScrollLock")
            SetScrollLockState, % not GetKeyState(Key, "T")
        ; 其他修飾鍵（如 Shift, Ctrl, Alt）發送 up/down 模擬鎖定
        else {
            if (GetKeyState(Key))
                SendInput, % "{" Key " up}" ; 如果鍵已按下，則釋放
            else
                SendInput, % "{" Key " down}" ; 如果鍵未按下，則按下（鎖定）
        }
        return
    }

    ; 更新按鈕的視覺顏色
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
