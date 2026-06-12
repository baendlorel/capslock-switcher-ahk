; Tray — tray menu setup and CapsLock mode toggle

Initialize() {
    global APP_VERSION

    EnsureAdminStartupTaskConfiguration()
    ApplyScriptEnabledState()

    A_TrayMenu.Delete()
    A_TrayMenu.Add("版本 " APP_VERSION, DoNothing)
    A_TrayMenu.Disable("版本 " APP_VERSION)
    A_TrayMenu.Add(GetAdminStartupMenuLabel(), ToggleAdminStartup)
    A_TrayMenu.Add(GetStandardStartupMenuLabel(), ToggleStandardStartup)
    UpdateStartupMenuItems()
    A_TrayMenu.Add(GetToggleMenuLabel(), ToggleCapsLockMode)
    A_TrayMenu.Add()
    A_TrayMenu.Add("重新启动", RestartApp)
    A_TrayMenu.Add()
    A_TrayMenu.Add("为什么开了没效果？", About)
    A_TrayMenu.Add("关于", AboutProgram)
    A_TrayMenu.Add()
    A_TrayMenu.Add("退出", (*) => ExitApp())

    ShowToast("小写")
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

ToggleAdminStartup(*) {
    if (IsAdminStartupEnabled()) {
        DisableAdminStartup()
    } else {
        EnableAdminStartup()
    }
    UpdateStartupMenuItems()
}

ToggleStandardStartup(*) {
    if (IsStandardStartupEnabled()) {
        DisableStandardStartup()
    } else {
        EnableStandardStartup()
    }
    UpdateStartupMenuItems()
}

UpdateStartupMenuItems() {
    adminLabel := GetAdminStartupMenuLabel()
    standardLabel := GetStandardStartupMenuLabel()

    if (IsAdminStartupEnabled()) {
        A_TrayMenu.Check(adminLabel)
    } else {
        A_TrayMenu.Uncheck(adminLabel)
    }

    if (IsStandardStartupEnabled()) {
        A_TrayMenu.Check(standardLabel)
    } else {
        A_TrayMenu.Uncheck(standardLabel)
    }
}

GetAdminStartupMenuLabel() {
    return "开机启动（管理员）"
}

GetStandardStartupMenuLabel() {
    return "开机启动（普通）"
}

ToggleCapsLockMode(*) {
    global SCRIPT_ENABLED

    previousLabel := GetToggleMenuLabel()
    if (SCRIPT_ENABLED) {
        SCRIPT_ENABLED := false
        ApplyScriptEnabledState()
        SetCapsLockState("On")
    } else {
        SCRIPT_ENABLED := true
        ApplyScriptEnabledState()
    }

    A_TrayMenu.Rename(previousLabel, GetToggleMenuLabel())
    ShowToast(GetCapsLockToastLabel())
}

RestartApp(*) {
    RestartAsAdmin()
}

ApplyScriptEnabledState() {
    global SCRIPT_ENABLED
    ; Do NOT use Suspend — it would also disable !CapsLock, preventing mode switching.
    ; CapsLock/+CapsLock handlers check SCRIPT_ENABLED themselves.
    SetCapsLockState(SCRIPT_ENABLED ? "AlwaysOff" : "Off")
}

GetToggleMenuLabel() {
    global SCRIPT_ENABLED
    return SCRIPT_ENABLED ? "切换到大写" : "切换到小写"
}

GetCapsLockToastLabel() {
    return GetKeyState("CapsLock", "T") ? "大写" : "小写"
}
