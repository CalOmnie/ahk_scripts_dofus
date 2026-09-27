#Requires AutoHotkey v2.0
#SingleInstance Force
#Include utils.ahk

;; CONFIGURATION

groupInviteShortcut := "^g"

;; IMPLEMENTATION

HotIf(IsDofusActive)
Hotkey(groupInviteShortcut, GroupInviteAll)
HotIf()

GroupInviteAll(*)
{
    activeChar := ExtractCharName(WinGetTitle("A"))

    characters := []
    for hwnd in WinGetList("ahk_exe Dofus.exe")
    {
        char := ExtractCharName(WinGetTitle(hwnd))
        if char = "" || char = activeChar
            continue
        characters.Push(char)
    }

    if characters.Length = 0
        return

    result := ""
    for i, char in characters
        result .= (i = 1 ? "" : "; ") "/invite " char

    A_Clipboard := result
    SendChatCommand()
}
