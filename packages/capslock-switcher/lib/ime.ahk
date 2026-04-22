; IME — detect and toggle input method conversion mode

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
    hwnd := GetImeTargetHwnd()
    if !hwnd {
        return "未知"
    }

    conversionMode := GetImeConversionMode(hwnd)
    if (conversionMode == -1) {
        return "中"
    }

    return IsChineseConversionMode(conversionMode) ? "中" : "En"
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
