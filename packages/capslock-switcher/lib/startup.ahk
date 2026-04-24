; Startup — standard startup-folder launch and shared helpers

IsStandardStartupEnabled() {
    return FileExist(GetStartupShortcutPath()) != ""
}

EnableStandardStartup() {
    if !ShowStandardStartupWarning() {
        return false
    }

    if (IsAdminStartupEnabled() && !RemoveStartupTask()) {
        MsgBox(
            "无法切换到普通权限开机启动。`n`n" .
            "请允许本程序删除已有的管理员计划任务后再重试。",
            "CapsLock Switcher",
            "0x10"
        )
        return false
    }

    RemoveLegacyStartupShortcut()
    if CreateStandardStartupShortcut() {
        return true
    }

    MsgBox(
        "无法启用普通权限开机启动。`n`n" .
        "请确认启动文件夹可写，或重新运行本程序后再试一次。",
        "CapsLock Switcher",
        "0x10"
    )
    return false
}

DisableStandardStartup() {
    return RemoveLegacyStartupShortcut()
}

CreateStandardStartupShortcut() {
    try {
        FileCreateShortcut(
            GetStartupShortcutTarget(),
            GetStartupShortcutPath(),
            A_ScriptDir,
            GetStartupShortcutArgs(),
            "CapsLock Switcher"
        )
        return true
    } catch {
        return false
    }
}

GetStartupShortcutTarget() {
    return A_IsCompiled ? A_ScriptFullPath : A_AhkPath
}

GetStartupShortcutArgs() {
    return A_IsCompiled ? "" : '"' A_ScriptFullPath '"'
}

RemoveLegacyStartupShortcut() {
    startupShortcutPath := GetStartupShortcutPath()
    if !FileExist(startupShortcutPath) {
        return true
    }

    try {
        FileDelete(startupShortcutPath)
        return true
    } catch {
        return false
    }
}

GetStartupShortcutPath() {
    scriptBaseName := RegExReplace(A_ScriptName, "\.[^.]+$", "")
    return A_Startup "\\" scriptBaseName ".lnk"
}

ShowStandardStartupWarning() {
    result := false
    warningGui := Gui("+AlwaysOnTop -MinimizeBox", "普通权限开机启动")
    warningGui.BackColor := "2f3239"
    warningGui.MarginX := 28
    warningGui.MarginY := 20

    warningGui.SetFont("s20 cFFFFFF bold", "Microsoft YaHei UI")
    warningGui.AddText("w430 Center", "普通权限开机启动")

    warningGui.SetFont("s10 c8899aa norm", "Microsoft YaHei UI")
    warningGui.AddText("w430 Center", "启动文件夹模式")

    warningGui.MarginY := 16
    warningGui.SetFont("s11 cDDDDDD norm", "Microsoft YaHei UI")
    warningGui.AddText(
        "w430",
        "普通权限启动本程序时，将无法在其他以管理员权限打开的应用中生效。`n" .
        "也就是说，权限不够时，CapsLock 切换不会被这些窗口接收。"
    )

    warningGui.MarginY := 12
    warningGui.SetFont("s11 cFFB86C bold", "Microsoft YaHei UI")
    warningGui.AddText("w430", "继续开启后，会从“开机启动（管理员）”切换为“开机启动（普通）”。")

    warningGui.MarginY := 22
    warningGui.SetFont("s10 c8899aa norm", "Microsoft YaHei UI")
    warningGui.AddText("w430 Center", "如果你需要在管理员窗口里也生效，请使用“开机启动（管理员）”。")

    warningGui.MarginY := 28
    warningGui.SetFont("s11 cFFFFFF norm", "Microsoft YaHei UI")
    btnEnable := warningGui.AddButton("xm+86 w128 h34 Default", "继续开启")
    btnCancel := warningGui.AddButton("x+12 w128 h34", "取消")

    closeGui(*) {
        warningGui.Destroy()
    }

    confirm(*) {
        result := true
        closeGui()
    }

    cancel(*) {
        result := false
        closeGui()
    }

    btnEnable.OnEvent("Click", confirm)
    btnCancel.OnEvent("Click", cancel)
    warningGui.OnEvent("Close", cancel)
    warningGui.OnEvent("Escape", cancel)
    warningGui.Show("AutoSize Center")
    WinWaitClose("ahk_id " warningGui.Hwnd)
    return result
}
