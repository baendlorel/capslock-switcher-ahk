#Requires AutoHotkey v2.0
#SingleInstance Force

SetCapsLockState "AlwaysOff"

global TOAST_HOLD_MS := 640
global TOAST_FADE_INTERVAL_MS := 20
global TOAST_FADE_STEP := 20
global TOAST_RADIUS := 24
global APP_VERSION := "__APP_VERSION__"
global SCRIPT_ENABLED := true

global ToastAlpha := 200
global ToastGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
ToastGui.BackColor := "2f3239"
ToastGui.MarginX := 28
ToastGui.MarginY := 14
ToastGui.SetFont("s20 cFFFFFF bold", "Microsoft YaHei UI")
global ToastText := ToastGui.AddText("Center w130", "")

InitializeTrayMenu()

CapsLock:: ToggleIme()
+CapsLock:: SyncImeState()

; # 托盘右键菜单
InitializeTrayMenu() {
    global APP_VERSION

    A_TrayMenu.Delete()
    A_TrayMenu.Add(APP_VERSION, DoNothing)
    A_TrayMenu.Disable(APP_VERSION)
    A_TrayMenu.Add("开机启动", ToggleStartup)
    UpdateStartupMenuItem()
    A_TrayMenu.Add(GetToggleMenuLabel(), ToggleScriptEnabled)
    A_TrayMenu.Add()
    A_TrayMenu.Add("退出", (*) => ExitApp())
}

DoNothing(*) {
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
    Suspend(SCRIPT_ENABLED ? 0 : 1)
    A_TrayMenu.Rename(previousLabel, GetToggleMenuLabel())
    ShowToast(SCRIPT_ENABLED ? "已开启" : "已关闭")
}

GetToggleMenuLabel() {
    global SCRIPT_ENABLED
    return SCRIPT_ENABLED ? "暂时关闭" : "开启"
}

IsStartupEnabled() {
    return FileExist(GetStartupShortcutPath()) != ""
}

CreateStartupShortcut() {
    startupShortcutPath := GetStartupShortcutPath()
    if FileExist(startupShortcutPath) {
        FileDelete(startupShortcutPath)
    }

    if (A_IsCompiled) {
        FileCreateShortcut(A_ScriptFullPath, startupShortcutPath, A_ScriptDir, , "CapsLock Switcher")
        return
    }

    FileCreateShortcut(
        A_AhkPath,
        startupShortcutPath,
        A_ScriptDir,
        '"' A_ScriptFullPath '"',
        "CapsLock Switcher",
        A_AhkPath
    )
}

RemoveStartupShortcut() {
    startupShortcutPath := GetStartupShortcutPath()
    if FileExist(startupShortcutPath) {
        FileDelete(startupShortcutPath)
    }
}

GetStartupShortcutPath() {
    scriptBaseName := RegExReplace(A_ScriptName, "\.[^.]+$", "")
    return A_Startup "\\" scriptBaseName ".lnk"
}

; # 真正的检测中英文和切换模式的逻辑
ToggleIme(*) {
    if (IsChineseLayout()) {
        SendInput "^{Space}"
        ShowToast(ReadImeModeAfterDelay())
    }
}

SyncImeState(*) {
    if (IsChineseLayout()) {
        ShowToast(ReadImeModeAfterDelay(0))
    }
}

ReadImeModeAfterDelay(delayMs := 120) {
    if (delayMs > 0) {
        Sleep delayMs
    }

    loop 3 {
        mode := GetImeMode()
        if (mode != "未知") {
            return mode
        }
        Sleep 40
    }

    return "未知"
}

GetImeMode() {
    hwnd := GetImeTargetHwnd()
    if !hwnd {
        ToastGui.BackColor := "292727"
        return "未知"
    }

    conversionMode := GetImeConversionMode(hwnd)
    if (conversionMode == -1) {
        return "中文"
    }

    if (IsChineseConversionMode(conversionMode)) {
        ToastGui.BackColor := "a30923"
        return "中文"
    } else {
        ToastGui.BackColor := "303030"
        return "English"
    }

}

GetImeConversionMode(hwnd) {
    imeWnd := DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hwnd, "Ptr")
    if imeWnd {
        try {
            mode := SendMessage(0x0283, 0x0001, 0, , imeWnd)
            return mode
        } catch Error as e {
            MsgBox("错误信息: " e.Message)
        }
    }

    hIMC := DllCall("imm32\ImmGetContext", "Ptr", hwnd, "Ptr")
    if hIMC {
        conversionMode := 0
        sentenceMode := 0
        success := DllCall(
            "imm32\ImmGetConversionStatus",
            "Ptr", hIMC,
            "UInt*", conversionMode,
            "UInt*", sentenceMode,
            "Int"
        )
        DllCall("imm32\ImmReleaseContext", "Ptr", hwnd, "Ptr", hIMC)
        if success {
            return conversionMode
        }
    }

    return -1
}

GetImeTargetHwnd() {
    activeHwnd := WinExist("A")
    if !activeHwnd {
        return 0
    }

    focusedCtrl := ""
    try focusedCtrl := ControlGetFocus("ahk_id " activeHwnd)
    if (focusedCtrl != "") {
        try {
            ctrlHwnd := ControlGetHwnd(focusedCtrl, "ahk_id " activeHwnd)
            if ctrlHwnd {
                return ctrlHwnd
            }
        }
    }
    return activeHwnd
}

IsChineseLayout(*) {
    static zhLangIds := Map(
        0x0404, true, ; zh-TW
        0x0804, true, ; zh-CN
        0x0C04, true, ; zh-HK
        0x1004, true, ; zh-SG
        0x1404, true  ; zh-MO
    )
    hkl := DllCall("GetKeyboardLayout", "UInt", 0, "Ptr")
    langId := hkl & 0xFFFF
    return zhLangIds.Has(langId)
}

IsChineseConversionMode(conversionMode) {
    static IME_CMODE_NATIVE := 0x0001
    return (conversionMode & IME_CMODE_NATIVE) != 0
}

ShowToast(text) {
    global ToastGui, ToastText, ToastAlpha, TOAST_HOLD_MS

    if (text = "") {
        text := "未知"
    }

    SetTimer FadeToast, 0
    SetTimer StartFade, 0

    ToastAlpha := 200
    ToastText.Value := text

    ToastGui.Show("AutoSize Hide")
    ToastGui.GetPos(, , &w, &h)
    x := Floor((A_ScreenWidth - w) / 2)
    y := Floor((A_ScreenHeight - h) / 2)
    ToastGui.Show("x" x " y" y " NoActivate")

    ApplyRoundedRegion(ToastGui.Hwnd)
    if (ToastAlpha > 0) {
        WinSetTransparent ToastAlpha, "ahk_id " ToastGui.Hwnd
    } else {
        WinSetTransparent 0, "ahk_id " ToastGui.Hwnd

    }

    SetTimer StartFade, -TOAST_HOLD_MS
}

StartFade(*) {
    global TOAST_FADE_INTERVAL_MS
    SetTimer FadeToast, TOAST_FADE_INTERVAL_MS
}

FadeToast(*) {
    global ToastAlpha, ToastGui, TOAST_FADE_STEP
    ToastAlpha -= TOAST_FADE_STEP
    if (ToastAlpha <= 0) {
        SetTimer FadeToast, 0
        ToastGui.Hide()
        return
    }
    WinSetTransparent ToastAlpha, "ahk_id " ToastGui.Hwnd
}

ApplyRoundedRegion(hwnd) {
    global TOAST_RADIUS
    WinGetPos(, , &w, &h, "ahk_id " hwnd)
    rgn := DllCall(
        "gdi32\CreateRoundRectRgn",
        "Int", 0,
        "Int", 0,
        "Int", w + 1,
        "Int", h + 1,
        "Int", TOAST_RADIUS,
        "Int", TOAST_RADIUS,
        "Ptr"
    )
    DllCall("user32\SetWindowRgn", "Ptr", hwnd, "Ptr", rgn, "Int", true)
}
