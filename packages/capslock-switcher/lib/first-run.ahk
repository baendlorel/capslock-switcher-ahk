; FirstRun — show a notice on the very first launch of this version

CheckFirstRun() {
    global APP_VERSION
    markerFile := A_ScriptDir "\capslock-switcher-" APP_VERSION "-opened.txt"
    if FileExist(markerFile) {
        return
    }
    ShowFirstRunNotice(markerFile)
}

ShowFirstRunNotice(markerFile) {
    frGui := Gui("+AlwaysOnTop", "CapsLock Switcher")
    frGui.SetFont("s12", "Microsoft YaHei UI")
    frGui.AddText("w320 Center", "没效果的话右下角托盘点击帮助")
    countdownCtrl := frGui.AddText("w320 Center", "请阅读，剩余 4 秒...")
    frGui.AddText("w320", "")
    btnNoMore := frGui.AddButton("w130", "不再显示")
    btnClose := frGui.AddButton("x+20 w130 yp", "关闭")

    btnNoMore.Enabled := false
    btnClose.Enabled := false

    frGui.Show("AutoSize Center")

    btnNoMore.OnEvent("Click", (*) => (FileAppend("", markerFile), frGui.Destroy()))
    btnClose.OnEvent("Click", (*) => frGui.Destroy())

    remaining := 4
    Tick(*) {
        remaining -= 1
        if (remaining > 0) {
            countdownCtrl.Value := "请阅读，剩余 " remaining " 秒..."
            SetTimer Tick, -1000
        } else {
            countdownCtrl.Value := ""
            btnNoMore.Enabled := true
            btnClose.Enabled := true
        }
    }
    SetTimer Tick, -1000
}
