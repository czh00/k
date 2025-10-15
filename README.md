就是有注音標籤的OSK，執行後隱藏與顯示的熱鍵是Ctrl+Shift+O。
AHK 繁體中文螢幕小鍵盤 (AHK Traditional Chinese On-Screen Keyboard)
這是一個使用 AutoHotkey v1.1 編寫的功能齊全、可高度自訂的螢幕小鍵盤。它特別為需要繁體中文（注音）輸入法的使用者設計，同時也提供標準的 QWERTY 英文佈局。

This is a full-featured, highly customizable on-screen keyboard written in AutoHotkey v1.1. It is especially designed for users who need Traditional Chinese (Bopomofo/Zhuyin) input, while also providing a standard QWERTY English layout.

✨ 功能特色 (Features)
雙語言佈局 (Dual Layouts):

QWERTY: 標準英文鍵盤佈局。

注音 (Bopomofo): 台灣使用者慣用的繁體中文注音輸入法佈局。

可透過 Ctrl + Space 或專用按鍵快速切換。

深色主題 (Dark Theme): 預設採用時尚的深色主題，減少視覺疲勞 (顏色可於腳本內自訂)。

動態縮放 (Scalable): 可透過鍵盤上的 ⊕ (放大) 和 ⊖ (縮小) 按鈕即時調整鍵盤大小。

透明度調整 (Transparency Control): 提供多段式透明度切換，讓鍵盤在不使用時能融入背景。

即時狀態同步 (Real-time Key State Sync): 當您按下實體鍵盤的修飾鍵 (如 Shift, Ctrl, CapsLock) 時，螢幕小鍵盤上的對應按鍵會同步變色，清楚顯示當前狀態。

高相容性 (High Compatibility): 使用 SendMode Input 和 Blind 模式發送按鍵，確保在大多數應用程式和遊戲中都能穩定運作。

人性化設計 (User-Friendly):

支援點擊鍵盤空白處拖動視窗。

點擊時不搶佔當前視窗焦點 (WS_EX_NOACTIVATE)。

提供系統匣圖示選單，方便快速操作及退出。

🔧 需求 (Requirements)
AutoHotkey v1.1 或更新版本。 (注意：此腳本與 v2.0 不相容)

🚀 如何使用 (How to Use)
安裝 AutoHotkey: 如果您尚未安裝，請至 AutoHotkey 官方網站 下載並安裝 v1.1 版本。

下載腳本: 下載本專案中的 k_annotated.ahk 檔案。

執行: 直接雙擊 k_annotated.ahk 檔案即可執行。您將會在系統右下角的系統匣中看到一個新的 AutoHotkey 圖示。

⌨️ 快捷鍵 (Hotkeys)
Ctrl + Shift + O : 顯示 / 隱藏螢幕鍵盤。

Ctrl + Space : 切換鍵盤的「英文」與「注音」佈局 (此操作同時也會發送系統的中英文輸入法切換指令)。

🎨 自訂 (Customization)
您可以輕易地修改腳本來自訂鍵盤的外觀。打開 k_annotated.ahk 檔案，在 OSK 類別的 __New 方法中找到以下顏色變數並修改其 16 進位色碼：

; --- 顏色主題設定 (Color Theme Settings) ---
this.Background := "2A2A2A"          ; GUI 背景色
this.ButtonColour := "010101"        ; 按鈕預設顏色
this.ClickFeedbackColour := "0078D7" ; 按鈕點擊時的瞬間回饋顏色
this.ToggledButtonColour := "553b6a" ; 當修飾鍵處於 "開啟" 狀態時的顏色
this.TextColour := "ffffff"          ; 主要文字顏色
this.ShiftSymbolColour := "ADD8E6"   ; 按下 Shift 時，第二層符號的顏色
this.SecondLineColour := "FFA500"    ; 注音模式下，注音符號的顏色

📄 授權 (License)
本專案採用 MIT 授權。
