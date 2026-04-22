#Requires AutoHotkey v2.0
#SingleInstance Force

#Include ./lib/config.ahk
#Include ./lib/toast.ahk
#Include ./lib/ime.ahk
#Include ./lib/startup.ahk
#Include ./lib/first-run.ahk
#Include ./lib/tray.ahk

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
+CapsLock:: ShowImeState()

; Always active — used to re-enable the script when it is disabled.
!CapsLock:: ToggleScriptEnabled()