; FirstRun — show a startup notice on every launch (5-second mandatory read)

global FIRST_RUN_MARKER := A_ScriptDir "\\capslock-switcher-v" APP_VERSION "-opened.txt"
CheckFirstRun() {
    global FIRST_RUN_MARKER
    if FileExist(FIRST_RUN_MARKER) {
        return
    }
    ShowInstruction(5)
}

; waitSecs: seconds before the close button is enabled (0 = immediately available)
ShowInstruction(waitSecs := 5) {
    global APP_VERSION

    frGui := Gui("+AlwaysOnTop", "CapsLock Switcher")
    frGui.BackColor := "2f3239"
    frGui.MarginX := 28
    frGui.MarginY := 20

    ; Title
    frGui.SetFont("s20 cFFFFFF bold", "Microsoft YaHei UI")
    frGui.AddText("w420 Center", "CapsLock Switcher")

    ; Version
    frGui.SetFont("s10 c8899aa norm", "Microsoft YaHei UI")
    frGui.AddText("w420 Center", APP_VERSION)

    ; Usage instructions
    frGui.MarginY := 14
    frGui.SetFont("s11 cDDDDDD norm", "Microsoft YaHei UI")
    frGui.AddText("w420",
        "本程序原理是将 CapsLock 映射为 Ctrl+Space，需要在输入法快捷键设置`n" .
        "中把切换中英文的按键改为 Ctrl+Space 方可生效")

    ; Hotkeys header
    frGui.MarginY := 12
    frGui.SetFont("s11 cFFFFFF bold", "Microsoft YaHei UI")
    frGui.AddText("w420", "按键说明")

    ; Hotkey rows — two-column layout: key (w160) + description (w260)
    hotkeyRows := [
        ["CapsLock", "映射为 Ctrl+Space，配合输入法快捷键切换中英文"],
        ["Shift + CapsLock", "显示当前语言状态"],
        ["Alt + CapsLock", "切换到原生 CapsLock 大小写，再按一次切回输入法模式"],
    ]
    for row in hotkeyRows {
        frGui.MarginY := 9
        frGui.SetFont("s11 c00d4ff norm", "Microsoft YaHei UI")
        frGui.AddText("xm w160", row[1])
        frGui.SetFont("s11 cCCCCCC norm", "Microsoft YaHei UI")
        frGui.AddText("x+0 w260 yp", row[2])
    }

    ; Countdown / spacer
    frGui.MarginY := 32 ; 增加底部空间
    frGui.SetFont("s9 c8899aa norm", "Microsoft YaHei UI")
    countdownCtrl := frGui.AddText("xm w420 Center", waitSecs > 0 ? "请阅读，剩余 " waitSecs " 秒..." : "")

    ; Close button
    frGui.MarginY := 28 ; 增加按钮下方空间
    frGui.SetFont("s11 cFFFFFF norm", "Microsoft YaHei UI")
    btnClose := frGui.AddButton("xm+150 w120", "关闭")
    btnClose.Enabled := (waitSecs <= 0)

    frGui.Show("AutoSize Center")
    global FIRST_RUN_MARKER
    btnClose.OnEvent("Click", (*) => (
        (!FileExist(FIRST_RUN_MARKER) ? FileAppend("", FIRST_RUN_MARKER) : 0),
        frGui.Destroy()
    ))

    if (waitSecs > 0) {
        remaining := waitSecs
        Tick(*) {
            remaining -= 1
            if (remaining > 0) {
                countdownCtrl.Value := "请阅读，剩余 " remaining " 秒..."
                SetTimer Tick, -1000
            } else {
                countdownCtrl.Value := ""
                btnClose.Enabled := true
            }
        }
        SetTimer Tick, -1000
    }
}
