; Tray — tray menu setup, script enable/disable toggle

Initialize() {
    global APP_VERSION

    ApplyScriptEnabledState()

    A_TrayMenu.Delete()
    A_TrayMenu.Add("版本 " APP_VERSION, DoNothing)
    A_TrayMenu.Disable("版本 " APP_VERSION)
    A_TrayMenu.Add("开机启动", ToggleStartup)
    UpdateStartupMenuItem()
    A_TrayMenu.Add(GetToggleMenuLabel(), ToggleScriptEnabled)
    A_TrayMenu.Add()
    A_TrayMenu.Add("为什么开了没效果？", About)
    A_TrayMenu.Add()
    A_TrayMenu.Add("退出", (*) => ExitApp())

    ShowToast("开")
    CheckFirstRun()
}

DoNothing(*) {
}

About(*) {
    MsgBox(
        "本程序原理是将CapsLock映射为Ctrl + Space，需要在输入法快捷键设置`n" .
        "中把切换中英文的按键改为Ctrl + Space方可生效`n`n" .
        "`n" .
        "CapsLock：映射为Ctrl + Space，配合输入法快捷键设置实现切换`n" .
        "Shift + CapsLock：显示当前语言状态`n" .
        "Alt + CapsLock：切换本程序开关，关闭后CapsLock恢复原功能`n" .
        "`n" .
        "`n" .
        "CapsLock Switcher " APP_VERSION "`n" .
        "基于 AutoHotkey v2 开发的输入法切换程序`n`n" .
        "作者：Kasukabe Tsumugi`n" .
        "项目地址: https://github.com/baendlorel/capslock-switcher-ahk")
}

ToggleStartup(*) {
    if (IsStartupEnabled()) {
        RemoveStartupShortcut()
    } else {
        CreateStartupShortcut()
    }
    UpdateStartupMenuItem()
}

UpdateStartupMenuItem() {
    if (IsStartupEnabled()) {
        A_TrayMenu.Check("开机启动")
    } else {
        A_TrayMenu.Uncheck("开机启动")
    }
}

ToggleScriptEnabled(*) {
    global SCRIPT_ENABLED

    previousLabel := GetToggleMenuLabel()
    SCRIPT_ENABLED := !SCRIPT_ENABLED
    ApplyScriptEnabledState()
    A_TrayMenu.Rename(previousLabel, GetToggleMenuLabel())
    ShowToast(SCRIPT_ENABLED ? "开" : "关")
}

ApplyScriptEnabledState() {
    global SCRIPT_ENABLED
    ; Do NOT use Suspend — it would also disable !CapsLock, preventing re-enabling.
    ; CapsLock/+CapsLock handlers check SCRIPT_ENABLED themselves.
    SetCapsLockState(SCRIPT_ENABLED ? "AlwaysOff" : "Off")
}

GetToggleMenuLabel() {
    global SCRIPT_ENABLED
    return SCRIPT_ENABLED ? "暂时关闭" : "开启"
}
