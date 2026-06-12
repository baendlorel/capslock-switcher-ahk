; StartupAdmin — elevated startup via Task Scheduler

IsAdminStartupEnabled() {
    return IsStartupTaskEnabled()
}

EnsureAdminStartupTaskConfiguration() {
    if (A_IsAdmin && IsStartupTaskEnabled()) {
        CreateStartupTask()
    }
}

EnableAdminStartup() {
    RemoveLegacyStartupShortcut()

    if CreateStartupTask() {
        return true
    }

    MsgBox(
        "无法启用开机启动。`n`n" .
        "程序现在会优先通过任务计划程序以管理员权限静默启动。`n" .
        "如果看到了 UAC 提示，请允许本程序创建计划任务后再重试。",
        "CapsLock Switcher",
        "0x10"
    )
    return false
}

DisableAdminStartup() {
    return RemoveStartupTask()
}

IsStartupTaskEnabled() {
    return RunSchtasks('/Query /TN "' GetStartupTaskName() '"') = 0
}

CreateStartupTask() {
    ; Delay logon startup slightly so Explorer can create the notification area first.
    args := '/Create /TN "' GetStartupTaskName() '" /SC ONLOGON /RL HIGHEST /DELAY ' . GetStartupTaskDelay() .
    ' /IT /TR ' .
    QuoteForSchtasks(GetStartupTaskRunCommand()) . ' /F'
    exitCode := RunSchtasks(args)
    if (exitCode = 0) {
        return true
    }

    if (!A_IsAdmin) {
        exitCode := RunSchtasks(args, true)
    }

    return exitCode = 0
}

RemoveStartupTask(tryElevate := true) {
    if !IsStartupTaskEnabled() {
        return true
    }

    args := '/Delete /TN "' GetStartupTaskName() '" /F'
    exitCode := RunSchtasks(args)
    if (exitCode = 0) {
        return true
    }

    if (tryElevate && !A_IsAdmin) {
        exitCode := RunSchtasks(args, true)
    }

    return exitCode = 0
}

RunSchtasks(args, elevate := false) {
    target := '"' GetSchtasksPath() '" ' args
    if (elevate) {
        target := '*RunAs ' target
    }

    try {
        return RunWait(target, , "Hide")
    } catch {
        return -1
    }
}

QuoteForSchtasks(command) {
    return '"' StrReplace(command, '"', '\"') '"'
}

GetStartupTaskRunCommand() {
    if (A_IsCompiled) {
        return '"' A_ScriptFullPath '"'
    }

    return '"' A_AhkPath '" "' A_ScriptFullPath '"'
}

GetStartupTaskName() {
    scriptBaseName := RegExReplace(A_ScriptName, "\.[^.]+$", "")
    return "CapsLock Switcher - " scriptBaseName
}

GetStartupTaskDelay() {
    return "0000:08"
}

GetSchtasksPath() {
    return A_WinDir "\\System32\\schtasks.exe"
}
