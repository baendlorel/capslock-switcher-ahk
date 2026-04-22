; Startup — manage Windows startup shortcut

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
