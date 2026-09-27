#Requires AutoHotkey v2.0
#Include utils.ahk

;; CONFIGURATION

travelShortcut := "^y"

;; IMPLEMENTATION

#HotIf WinActive("ahk_exe Dofus.exe")
Hotkey(travelShortcut, TravelPrompt)
#HotIf

TravelPrompt(*)
{
    ib := InputBox("Enter coordinates (e.g. 12 24, 12,24, /travel 12 24)", "Travel")
    if ib.Result = "Cancel"
        return

    coords := ParseCoordinates(ib.Value)
    if !IsObject(coords)
    {
        MsgBox "Could not parse coordinates from: " ib.Value
        return
    }

    zaaps := LoadZaaps()
    if zaaps.Length = 0
    {
        MsgBox "No zaaps found in data\zaaps.yaml"
        return
    }

    closest := ClosestZaap(coords.x, coords.y, zaaps)

    result := "/zaap " closest.x " " closest.y "; /travel " coords.x " " coords.y
    A_Clipboard := result
    SendChatCommand()
}

;; UTILITIES

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
