#Requires AutoHotkey v2.0

; Criteria callback for the HotIf() function (not the #HotIf directive --
; that's resolved once at load time, before any runtime code runs, so it
; doesn't match "current" state at the moment a dynamically-created Hotkey()
; call actually executes). HotIf() must be called with this immediately
; before each Hotkey() call it's meant to scope, and reset with a bare
; HotIf() call right after -- including calls made later from inside other
; functions, since it's live global state, not something tied to source position
IsDofusActive(*)
{
    return WinActive("ahk_exe Dofus.exe")
}

; Activates hwnd and waits for it to actually become the foreground window,
; returning whether it did so within timeoutSeconds
ActivateWindow(hwnd, timeoutSeconds := 2)
{
    WinActivate(hwnd)
    return WinWaitActive(hwnd, , timeoutSeconds) ? true : false
}

; Window titles look like "$CHAR_NAME - $CHAR_CLASS - $GAME_VERSION - $GAMETYPE"
ExtractCharName(title)
{
    parts := StrSplit(title, " - ")
    if parts.Length = 0
        return ""
    return Trim(parts[1])
}

; Opens the Dofus chat input, pastes the clipboard, and submits it
SendChatCommand()
{
    Send "{Space}"
    Sleep 100
    Send "^v"
    Sleep 100
    Send "{Enter}"
}

; Parses coordinate input in the form "12 24", "12,24", or "/travel 12 24"
; into {x, y}. Returns false if the input doesn't match.
ParseCoordinates(input)
{
    text := Trim(input)
    text := RegExReplace(text, "i)^/travel\s*", "")
    text := Trim(text)

    if !RegExMatch(text, "^(-?\d+)\s*,?\s*(-?\d+)$", &m)
        return false

    return {x: Integer(m[1]), y: Integer(m[2])}
}

LoadZaaps()
{
    zaaps := []
    path := A_ScriptDir "\..\data\zaaps.yaml"
    if !FileExist(path)
        return zaaps

    content := FileRead(path)
    pos := 1
    while RegExMatch(content, "area:\s*(.*?)\R\s*subarea:\s*(.*?)\R\s*x:\s*(-?\d+)\R\s*y:\s*(-?\d+)", &m, pos)
    {
        zaaps.Push({area: Trim(m[1]), subarea: Trim(m[2]), x: Integer(m[3]), y: Integer(m[4])})
        pos := m.Pos(0) + m.Len(0)
    }
    return zaaps
}

ClosestZaap(x, y, zaaps)
{
    best := zaaps[1]
    bestDist := (best.x - x) ** 2 + (best.y - y) ** 2
    for z in zaaps
    {
        d := (z.x - x) ** 2 + (z.y - y) ** 2
        if d < bestDist
        {
            bestDist := d
            best := z
        }
    }
    return best
}

; Builds the "/zaap X Y; /travel x y" command for the closest zaap to {x, y},
; or "" if no zaap data could be loaded
BuildTravelCommand(coords)
{
    zaaps := LoadZaaps()
    if zaaps.Length = 0
        return ""

    closest := ClosestZaap(coords.x, coords.y, zaaps)
    return "/zaap " closest.x " " closest.y "; /travel " coords.x " " coords.y
}
