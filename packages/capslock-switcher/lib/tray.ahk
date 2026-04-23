; Tray — tray menu setup, script enable/disable toggle

Initialize() {
    global APP_VERSION

    ApplyScriptEnabledState()

    A_TrayMenu.Delete()
    A_TrayMenu.Add("版本 " APP_VERSION, DoNothing)
    A_TrayMenu.Disable("版本 " APP_VERSION)
    A_TrayMenu.Add(GetStartupMenuLabel(), ToggleStartup)
    UpdateStartupMenuItem()
    A_TrayMenu.Add(GetToggleMenuLabel(), ToggleScriptEnabled)
    A_TrayMenu.Add()
    A_TrayMenu.Add("为什么开了没效果？", About)
    A_TrayMenu.Add("关于", AboutProgram)
    A_TrayMenu.Add()
    A_TrayMenu.Add("退出", (*) => ExitApp())

    ShowToast("开")
    CheckFirstRun()
}

DoNothing(*) {
}

About(*) {
    ShowInstruction(0)
}

AboutProgram(*) {
    global APP_VERSION
    MsgBox(
        "CapsLock Switcher " APP_VERSION "`n`n" .
        "基于 AutoHotkey v2 开发的输入法切换程序`n`n" .
        "作者：Kasukabe Tsumugi`n" .
        "项目地址：https://github.com/baendlorel/capslock-switcher-ahk",
        "关于 CapsLock Switcher",
        "0x40")
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
    menuLabel := GetStartupMenuLabel()
    if (IsStartupEnabled()) {
        A_TrayMenu.Check(menuLabel)
    } else {
        A_TrayMenu.Uncheck(menuLabel)
    }
}

GetStartupMenuLabel() {
    return "开机启动（管理员）"
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
