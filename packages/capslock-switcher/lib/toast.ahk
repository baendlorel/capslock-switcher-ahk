; Toast — GUI setup (auto-execute) and display/animation functions

; --- GUI setup (runs at include time as part of the auto-execute section) ---
global ToastAlpha := TOAST_START_ALPHA
global ToastGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
ToastGui.MarginX := 12
ToastGui.MarginY := 6
ToastGui.SetFont("s24 cFFFFFF bold", TOAST_FONT)
global ToastText := ToastGui.AddText("Center w40", "")

; --- Functions ---

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
    w := w + 120 ; slightly wider than AutoSize for breathing room
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
