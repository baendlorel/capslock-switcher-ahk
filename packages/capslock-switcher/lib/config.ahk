; Config — global variables and constants

global APP_VERSION := "__APP_VERSION__" ; replaced at build time
global SCRIPT_ENABLED := true

; Toast animation
global TOAST_HOLD_MS := 640          ; how long to show before fading, ms
global TOAST_FADE_INTERVAL_MS := 20  ; timer interval for fade step, ms
global TOAST_FADE_STEP := 20         ; alpha decrease per step (0-255)

; Toast appearance
global TOAST_RADIUS := 24            ; corner radius, px
global TOAST_FONT := "Microsoft YaHei UI"
global TOAST_START_ALPHA := 215      ; initial alpha (0-255); <255 gives frosted glass feel
global IME_BACK_COLOR := Map(
    "中", "ff1f45",
    "En", "0073ff",
    "开", "2fbb1c",
    "关", "941212",
    "未知", "fb5607",
    "启动", "2f3239"
)