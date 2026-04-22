#SingleInstance Force
SetWorkingDir A_ScriptDir

; ==================== 全局变量 ====================
global GUI_WIDTH := 360
global GUI_HEIGHT := 100
global GUI_CORNER_RADIUS := 15
global GUI_MARGIN_TOP := 30
global GUI_MARGIN_RIGHT := 240
global GUI_SHOW_TRANSPARENCY := 220
global GUI_FADE_START_TRANSPARENCY := 205
global GUI_REFRESH_INTERVAL_MS := 1000
global guiVisible := false
global myGui := 0

; ==================== 热键设置 ====================
; 双击Ctrl显示监控窗口
~Ctrl::
{
    if (A_PriorHotkey = "~Ctrl" and A_TimeSincePriorHotkey < 720) {
        ShowSystemMonitor()
    }
}

; ==================== 显示系统监控窗口 ====================
ShowSystemMonitor() {
    global guiVisible, myGui
    global GUI_WIDTH, GUI_HEIGHT, GUI_CORNER_RADIUS
    global GUI_MARGIN_TOP, GUI_MARGIN_RIGHT
    global GUI_SHOW_TRANSPARENCY, GUI_REFRESH_INTERVAL_MS

    if (guiVisible) {
        FadeOutGUI()
        return
    }

    ; 创建GUI窗口
    myGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +Border", "SystemMonitor")
    myGui.BackColor := "2f3239"
    myGui.SetFont("s11 cFFFFFF q5", "Microsoft YaHei UI")

    ; 标题
    ; myGui.SetFont("s12 c00d4ff bold")
    ; myGui.Add("Text", "x20 y12 w260 h25", "⚡ System Monitor")
    ; myGui.SetFont("s11 cFFFFFF norm")

    ; 分隔线
    ; myGui.Add("Text", "x20 y40 w260 h1 +0x10 c4a4a6a")

    ; CPU 使用率
    myGui.Add("Text", "x20 y15 w160 h22", "🔷 CPU Usage:")
    myGui.SetFont("c00ff88")
    myGui.Add("Text", "vCpuUsageText x180 y15 w160 h22 Right", "--%")
    myGui.SetFont("cFFFFFF")

    ; CPU 温度
    myGui.Add("Text", "x20 y40 w160 h22", "🔷 CPU Temp:")
    myGui.SetFont("cffaa00")
    myGui.Add("Text", "vCpuTempText x180 y40 w160 h22 Right", "N/A")
    myGui.SetFont("cFFFFFF")

    ; Memory 使用率（百分比和数值在一行）
    myGui.Add("Text", "x20 y65 w160 h22", "🔷 Memory:")
    myGui.SetFont("c00ccff")
    myGui.Add("Text", "vMemUsageText x140 y65 w200 h22 Right", "--")
    myGui.SetFont("cFFFFFF")

    ; 显示窗口
    posX := A_ScreenWidth - GUI_WIDTH - GUI_MARGIN_RIGHT
    posY := GUI_MARGIN_TOP
    myGui.Show("x" . posX . " y" . posY . " w" . GUI_WIDTH . " h" . GUI_HEIGHT . " NoActivate")

    ; 设置透明度
    myGuiHwnd := myGui.Hwnd
    WinSetTransparent(GUI_SHOW_TRANSPARENCY, "ahk_id " . myGuiHwnd)

    ; 设置圆角窗口 - 使用DllCall
    SetRoundedWindow(myGuiHwnd, GUI_CORNER_RADIUS, GUI_WIDTH, GUI_HEIGHT)

    guiVisible := true
    UpdateSystemMonitor()
    SetTimer(UpdateSystemMonitor, GUI_REFRESH_INTERVAL_MS)

    ; 2秒后开始淡出
    ; SetTimer(FadeOutGUI, -2000)
}

UpdateSystemMonitor() {
    global guiVisible, myGui

    if (!guiVisible || !myGui) {
        return
    }

    cpuUsage := GetCPUUsage()
    cpuTemp := GetCPUTemperature()
    memUsage := GetMemoryUsage()
    memInfo := GetMemoryInfo()

    memUsedGB := Round(memInfo.Used / 1024, 1)
    memTotalGB := Round(memInfo.Total / 1024, 1)

    myGui["CpuUsageText"].Text := cpuUsage . "%"
    myGui["CpuTempText"].Text := cpuTemp
    myGui["MemUsageText"].Text := memUsage . "% (" . memUsedGB . "/" . memTotalGB . " GB)"
}

; ==================== 设置圆角窗口 ====================
SetRoundedWindow(hwnd, radius, width, height) {
    ; 尝试使用 Windows 11 的 DWM API
    try {
        DWMWA_WINDOW_CORNER_PREFERENCE := 33
        DWMWCP_ROUND := 2
        attr := Buffer(4)
        NumPut("Int", DWMWCP_ROUND, attr, 0)
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "Int", DWMWA_WINDOW_CORNER_PREFERENCE, "Ptr", attr, "UInt",
            4)
        return
    }

    ; 如果上面失败，使用传统方法
    try {
        hRgn := DllCall("CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", width, "Int", height, "Int", radius, "Int",
            radius, "Ptr")
        DllCall("SetWindowRgn", "Ptr", hwnd, "Ptr", hRgn, "Bool", true)
    }
}

; ==================== 开始淡出效果 ====================
FadeOutGUI() {
    global guiVisible, myGui
    global GUI_FADE_START_TRANSPARENCY

    if (!guiVisible) {
        return
    }

    SetTimer(UpdateSystemMonitor, 0)

    myGuiHwnd := myGui.Hwnd

    ; 渐变淡出效果
    transparency := GUI_FADE_START_TRANSPARENCY
    loop 24 {
        transparency -= 20
        if (transparency < 0) {
            transparency := 0
        }
        WinSetTransparent(transparency, "ahk_id " . myGuiHwnd)
        Sleep(20)
    }

    ; 销毁窗口
    try {
        myGui.Destroy()
    }
    myGui := 0
    guiVisible := false
}

; ==================== 获取CPU使用率 ====================
GetCPUUsage() {
    static oldIdleTime := 0, oldKrnlTime := 0, oldUserTime := 0

    ; 获取系统时间
    idleTime := Buffer(8)
    krnlTime := Buffer(8)
    userTime := Buffer(8)
    DllCall("GetSystemTimes", "Ptr", idleTime, "Ptr", krnlTime, "Ptr", userTime)

    idleTimeVal := NumGet(idleTime, 0, "Int64")
    krnlTimeVal := NumGet(krnlTime, 0, "Int64")
    userTimeVal := NumGet(userTime, 0, "Int64")

    if (oldIdleTime = 0) {
        oldIdleTime := idleTimeVal
        oldKrnlTime := krnlTimeVal
        oldUserTime := userTimeVal
        return GetCPUUsageWMI()
    }

    ; 计算CPU使用率
    sysIdle := idleTimeVal - oldIdleTime
    sysKrnl := krnlTimeVal - oldKrnlTime
    sysUser := userTimeVal - oldUserTime

    total := sysKrnl + sysUser

    if (total > 0) {
        cpuUsage := Round((total - sysIdle) * 100 / total)
    } else {
        cpuUsage := GetCPUUsageWMI()
    }

    ; 更新旧值
    oldIdleTime := idleTimeVal
    oldKrnlTime := krnlTimeVal
    oldUserTime := userTimeVal

    return cpuUsage
}

; WMI备用方法获取CPU使用率
GetCPUUsageWMI() {
    try {
        wmi := ComObjGet("winmgmts:\\.\root\cimv2")
        for proc in wmi.ExecQuery("Select * From Win32_Processor") {
            return proc.LoadPercentage
        }
    }
    return 0
}

; ==================== 获取CPU温度 ====================
GetCPUTemperature() {
    static lastTemp := "N/A"

    try {
        wmi := ComObjGet("winmgmts:\\.\root\wmi")

        ; 尝试MSAcpi_ThermalZoneTemperature
        for temp in wmi.ExecQuery("Select * From MSAcpi_ThermalZoneTemperature") {
            if (temp.CurrentTemperature > 0) {
                ; 温度单位是开尔文 * 10，需要转换为摄氏度
                tempC := Round((temp.CurrentTemperature - 2732) / 10, 1)
                lastTemp := tempC . "°C"
                return lastTemp
            }
        }
    }

    try {
        wmi := ComObjGet("winmgmts:\\.\root\cimv2")

        ; 尝试Win32_PerfFormattedData_Counters_ThermalZoneInformation
        for temp in wmi.ExecQuery("Select * From Win32_PerfFormattedData_Counters_ThermalZoneInformation") {
            if (temp.Temperature > 0) {
                tempC := Round(temp.Temperature - 273.15, 1)
                lastTemp := tempC . "°C"
                return lastTemp
            }
        }
    }

    ; 如果无法获取温度，尝试读取OpenHardwareMonitor的数据（如果已安装）
    try {
        wmi := ComObjGet("winmgmts:\\.\root\OpenHardwareMonitor")
        for hardware in wmi.ExecQuery("Select * From Sensor Where SensorType='Temperature' And Name Like '%CPU%'") {
            if (hardware.Value > 0) {
                tempC := Round(hardware.Value, 1)
                lastTemp := tempC . "°C"
                return lastTemp
            }
        }
    }

    return lastTemp
}

; ==================== 获取内存使用率 ====================
GetMemoryUsage() {
    memStatus := Buffer(64)
    NumPut("UInt", 64, memStatus, 0)

    DllCall("kernel32.dll\GlobalMemoryStatusEx", "Ptr", memStatus)

    memLoad := NumGet(memStatus, 4, "UInt")

    return memLoad
}

GetMemoryInfo() {
    memStatus := Buffer(64)
    NumPut("UInt", 64, memStatus, 0)

    DllCall("kernel32.dll\GlobalMemoryStatusEx", "Ptr", memStatus)

    memLoad := NumGet(memStatus, 4, "UInt")
    totalPhys := NumGet(memStatus, 8, "UInt64")
    availPhys := NumGet(memStatus, 16, "UInt64")

    usedPhys := (totalPhys - availPhys) / 1024 / 1024
    totalPhysMB := totalPhys / 1024 / 1024

    return { Used: usedPhys, Total: totalPhysMB }
}

; ==================== 清理和退出 ====================
OnExit(ExitHandler)

ExitHandler(*) {
    global myGui, guiVisible
    SetTimer(UpdateSystemMonitor, 0)
    try {
        myGui.Destroy()
    }
    myGui := 0
    guiVisible := false
}
