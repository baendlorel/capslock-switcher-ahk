#Requires AutoHotkey v2.0
#SingleInstance Force

; # 配置信息
global APP_VERSION := "__APP_VERSION__" ; 版本号会在编译时自动替换
global SCRIPT_ENABLED := true

; ## 输入法状态淡出动画相关配置
global TOAST_HOLD_MS := 640 ; 动画时间，单位毫秒
global TOAST_FADE_INTERVAL_MS := 20 ; 动画时间间隔，单位毫秒
global TOAST_FADE_STEP := 20 ; 动画每一步减少的透明度，为0-255之间的整数

global TOAST_RADIUS := 24 ; 圆角半径，单位像素
global TOAST_FONT := "Microsoft YaHei UI" ; 字体
global TOAST_START_ALPHA := 215 ; 起始透明度，0-255之间的整数，建议不要设置为255以保持一定的磨砂玻璃效果
global IME_BACK_COLOR := Map(
    "中", "ff1f45",
    "En", "0073ff",
    "开", "2fbb1c",
    "关", "941212",
    "未知", "fb5607",
    "启动", "2f3239"
)

global ToastAlpha := TOAST_START_ALPHA
global ToastGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
ToastGui.MarginX := 12
ToastGui.MarginY := 6
ToastGui.SetFont("s24 cFFFFFF bold", TOAST_FONT)
global ToastText := ToastGui.AddText("Center w40", "")

Initialize()

; When enabled: toggle IME. When disabled: restore native CapsLock behavior.
CapsLock:: {
    global SCRIPT_ENABLED
    if (SCRIPT_ENABLED) {
        ToggleIme()
    } else {
        ; Manually toggle caps lock state since the key is intercepted
        SetCapsLockState(GetKeyState("CapsLock", "T") ? "Off" : "On")
    }
}

; When enabled: show IME state. When disabled: pass through.
+CapsLock:: {
    global SCRIPT_ENABLED
    ShowImeState()
}

; Always active — used to re-enable the script when it is suspended.
!CapsLock:: ToggleScriptEnabled()

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

}

; # 托盘右键菜单相关
DoNothing(*) {
}

About(*) {
    MsgBox(
        "本程序原理是将CapsLock映射为Ctrl + Space，需要在输入法快捷键设置中把切换中英文的按键改为Ctrl + Space方可生效" .
        "Shift + CapsLock可显示当前语言状态" .
        "" .
        "" .
        "CapsLock Switcher " APP_VERSION "`n" .
        "基于 AutoHotkey v2 开发的输入法切换工具`n`n" .
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
    global ToastGui, SCRIPT_ENABLED

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
    if (!IsChineseLayout()) {
        return
    }

    SendInput "^{Space}"
    imeMode := ReadImeModeAfterDelay(60)
    ShowToast(imeMode)
}

ShowImeState(*) {
    if (!IsChineseLayout()) {
        return
    }

    imeMode := ReadImeModeAfterDelay(0)
    ShowToast(imeMode)
}

ReadImeModeAfterDelay(delayMs) {
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
    global ToastGui

    hwnd := GetImeTargetHwnd()
    if !hwnd {
        return "未知"
    }

    conversionMode := GetImeConversionMode(hwnd)
    if (conversionMode == -1) {
        return "中"
    }

    if (IsChineseConversionMode(conversionMode)) {
        return "中"
    } else {
        return "En"
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

ShowToast(text, holdMs := TOAST_HOLD_MS) {
    global ToastGui, ToastText, ToastAlpha, TOAST_HOLD_MS, TOAST_START_ALPHA, IME_BACK_COLOR

    if (text = "") {
        text := "未知"
    }

    SetTimer FadeToast, 0
    SetTimer StartFade, 0

    ToastAlpha := TOAST_START_ALPHA
    ToastText.Value := text

    ToastGui.BackColor := IME_BACK_COLOR.Has(text) ? IME_BACK_COLOR.Get(text) : IME_BACK_COLOR.Get("未知")
    ToastGui.Show("AutoSize Hide")
    ToastGui.GetPos(, , &w, &h)
    x := Floor((A_ScreenWidth - w) / 2)
    y := Floor((A_ScreenHeight - h) / 2)
    ToastGui.Show("x" x " y" y " NoActivate Center")

    ApplyRoundedRegion(ToastGui.Hwnd)
    SetAlpha()

    SetTimer StartFade, -holdMs
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

    SetAlpha()
}

SetAlpha() {
    global ToastAlpha, ToastGui, TOAST_START_ALPHA
    if (ToastAlpha >= TOAST_START_ALPHA) {
        WinSetTransparent TOAST_START_ALPHA, "ahk_id " ToastGui.Hwnd
    } else if (ToastAlpha > 0) {
        WinSetTransparent ToastAlpha, "ahk_id " ToastGui.Hwnd
    } else {
        WinSetTransparent 0, "ahk_id " ToastGui.Hwnd
    }
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
