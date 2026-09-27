#Requires AutoHotkey v2.0
#Include utils.ahk

;; CONFIGURATION

groupInviteShortcut := "^g"

;; IMPLEMENTATION

#HotIf WinActive("ahk_exe Dofus.exe")
Hotkey(groupInviteShortcut, GroupInviteAll)
#HotIf

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

;; UTILITIES

; Window titles look like "$CHAR_NAME - $CHAR_CLASS - $GAME_VERSION - $GAMETYPE"
ExtractCharName(title)
{
    parts := StrSplit(title, " - ")
    if parts.Length = 0
        return ""
    return Trim(parts[1])
}
