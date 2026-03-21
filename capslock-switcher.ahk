#Requires AutoHotkey v2.0
#SingleInstance Force

SetCapsLockState "AlwaysOff"

; # 配置信息
global APP_VERSION := "__APP_VERSION__" ; 版本号会在编译时自动替换
global SCRIPT_ENABLED := true

; ## 输入法状态淡出动画相关配置
global TOAST_HOLD_MS := 640 ; 动画时间，单位毫秒
global TOAST_FADE_INTERVAL_MS := 20 ; 动画时间间隔，单位毫秒
global TOAST_FADE_STEP := 20 ; 动画每一步减少的透明度，为0-255之间的整数

global TOAST_RADIUS := 24 ; 圆角半径，单位像素
global TOAST_FONT := "Microsoft YaHei UI" ; 字体，推荐使用系统字体以保证支持中文和英文，同时保持美观
global TOAST_START_ALPHA := 225 ; 起始透明度，0-255之间的整数，建议不要设置为255以保持一定的磨砂玻璃效果
global TOAST_WIDTH := 320
global TOAST_HEIGHT := 92
global TOAST_PADDING_X := 24
global TOAST_PADDING_Y := 14
global TOAST_X_RATIO := 0.47
global TOAST_Y_RATIO := 0.46
global TOAST_STATUS_FONT_SIZE := 26
global TOAST_TITLE_FONT_SIZE := 20
global TOAST_SUBTITLE_FONT_SIZE := 11
global IME_BACK_COLOR := Map(
    "中文", "fb0931",
    "English", "0073ff",
    "未知", "fb5607",
    "启动", "2f3239"
)

global ToastAlpha := TOAST_START_ALPHA ; todo 这里要加入前n秒保持在这里不变的逻辑
global ToastGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
ToastGui.BackColor := "2f3239"
ToastGui.MarginX := 0
ToastGui.MarginY := 0
ToastGui.SetFont("s" TOAST_TITLE_FONT_SIZE " cFFFFFF bold", TOAST_FONT)
global ToastTitle := ToastGui.AddText("x" TOAST_PADDING_X " y" TOAST_PADDING_Y " w" (TOAST_WIDTH - TOAST_PADDING_X * 2) " h" (
    TOAST_HEIGHT - TOAST_PADDING_Y * 2) " Center +0x200", "")
ToastGui.SetFont("s" TOAST_SUBTITLE_FONT_SIZE " cFFFFFF", TOAST_FONT)
global ToastSubtitle := ToastGui.AddText("x" TOAST_PADDING_X " y" TOAST_PADDING_Y " w" (TOAST_WIDTH - TOAST_PADDING_X *
    2) " h24 Center +0x200 Hidden", "")

Initialize()

CapsLock:: ToggleIme()
+CapsLock:: ShowImeState()

Initialize() {
    global APP_VERSION

    A_TrayMenu.Delete()
    A_TrayMenu.Add("版本 " APP_VERSION, DoNothing)
    A_TrayMenu.Disable("版本 " APP_VERSION)
    A_TrayMenu.Add("开机启动", ToggleStartup)
    UpdateStartupMenuItem()
    A_TrayMenu.Add(GetToggleMenuLabel(), ToggleScriptEnabled)
    A_TrayMenu.Add()
    A_TrayMenu.Add("关于", About)
    A_TrayMenu.Add()
    A_TrayMenu.Add("退出", (*) => ExitApp())

    ShowToast("CapsLock Switcher 启动", 1600)
}

; # 托盘右键菜单相关
DoNothing(*) {
}

About(*) {
    MsgBox(
        "CapsLock Switcher " APP_VERSION "`n" .
        "基于 AutoHotkey 开发的输入法切换工具`n`n" .
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
    Suspend(SCRIPT_ENABLED ? 0 : 1)
    A_TrayMenu.Rename(previousLabel, GetToggleMenuLabel())
    ToastGui.BackColor := "212527"
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
        ToastGui.BackColor := "292727"
        return "未知"
    }

    conversionMode := GetImeConversionMode(hwnd)
    if (conversionMode == -1) {
        return "中文"
    }

    if (IsChineseConversionMode(conversionMode)) {
        ToastGui.BackColor := "da1e3e"
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

ShowToast(text, holdMs := TOAST_HOLD_MS) {
    global APP_VERSION, ToastGui, ToastTitle, ToastSubtitle, ToastAlpha
    global TOAST_HOLD_MS, TOAST_START_ALPHA, IME_BACK_COLOR
    global TOAST_WIDTH, TOAST_HEIGHT, TOAST_PADDING_X, TOAST_PADDING_Y

    if (text = "") {
        text := "未知"
    }

    SetTimer FadeToast, 0
    SetTimer StartFade, 0

    ToastAlpha := TOAST_START_ALPHA
    if (InStr(text, "启动")) {
        titleHeight := 34
        subtitleHeight := 22
        titleTop := 16
        subtitleTop := titleTop + titleHeight + 6

        ToastTitle.SetFont("s" TOAST_TITLE_FONT_SIZE " cFFFFFF bold", TOAST_FONT)
        ToastTitle.Value := "CapsLock Switcher"
        ToastTitle.Move(TOAST_PADDING_X, titleTop, TOAST_WIDTH - TOAST_PADDING_X * 2, titleHeight)
        ToastTitle.Visible := true

        ToastSubtitle.Value := APP_VERSION " 启动"
        ToastSubtitle.Move(TOAST_PADDING_X, subtitleTop, TOAST_WIDTH - TOAST_PADDING_X * 2, subtitleHeight)
        ToastSubtitle.Visible := true
    } else {
        ToastTitle.SetFont("s" TOAST_STATUS_FONT_SIZE " cFFFFFF bold", TOAST_FONT)
        ToastTitle.Value := text
        ToastTitle.Move(TOAST_PADDING_X, TOAST_PADDING_Y, TOAST_WIDTH - TOAST_PADDING_X * 2, TOAST_HEIGHT -
            TOAST_PADDING_Y * 2)
        ToastTitle.Visible := true

        ToastSubtitle.Value := ""
        ToastSubtitle.Visible := false
    }

    if (InStr(text, "启动")) {
        ToastGui.BackColor := IME_BACK_COLOR.Get("启动")
    } else {
        ToastGui.BackColor := IME_BACK_COLOR.Has(text) ? IME_BACK_COLOR.Get(text) : IME_BACK_COLOR.Get("未知")
    }
    x := GetToastAxisPosition(A_ScreenWidth, TOAST_WIDTH, TOAST_X_RATIO)
    y := GetToastAxisPosition(A_ScreenHeight, TOAST_HEIGHT, TOAST_Y_RATIO)
    ToastGui.Show("x" x " y" y " w" TOAST_WIDTH " h" TOAST_HEIGHT " NoActivate")

    ApplyRoundedRegion(ToastGui.Hwnd)
    SetAlpha()

    SetTimer StartFade, -holdMs
}

GetToastAxisPosition(screenSize, boxSize, ratio) {
    availableSpace := screenSize - boxSize
    if (availableSpace < 0) {
        return 0
    }

    ratio := Max(0, Min(1, ratio))
    return Floor(availableSpace * ratio)
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
