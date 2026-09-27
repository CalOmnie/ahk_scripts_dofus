#Requires AutoHotkey v2.0

; Opens the Dofus chat input, pastes the clipboard, and submits it
SendChatCommand()
{
    Send "{Space}"
    Sleep 100
    Send "^v"
    Sleep 100
    Send "{Enter}"
}
