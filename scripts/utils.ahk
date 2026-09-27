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

; -DPIScale disables AHK's own automatic scaling of Gui coordinates on
; high-DPI displays, so they line up directly with the plain (unscaled)
; screen coordinates MouseGetPos and SysGet return
DrawRectangle(x, y, w, h, color := "Red", thickness := 2)
{
    ; If the box is smaller than its own border thickness, y + h - thickness
    ; (and the x equivalent) go negative relative to the corner, pushing the
    ; bottom/right borders above/left of (x, y) instead of around the box
    w := Max(w, thickness)
    h := Max(h, thickness)

    rect := {}

    rect.top := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale")
    rect.bottom := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale")
    rect.left := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale")
    rect.right := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale")

    for g in [rect.top, rect.bottom, rect.left, rect.right]
    {
        g.BackColor := color
        g.Show("NA")
    }

    rect.top.Move(x, y, w, thickness)
    rect.bottom.Move(x, y + h - thickness, w, thickness)
    rect.left.Move(x, y, thickness, h)
    rect.right.Move(x + w - thickness, y, thickness, h)

    return rect
}

DestroyRectangle(rect)
{
    rect.top.Destroy()
    rect.bottom.Destroy()
    rect.left.Destroy()
    rect.right.Destroy()
}

; Shows instructions like MsgBox, but with one or more images stacked above
; the OK button (MsgBox itself only supports built-in system icons, not
; arbitrary image files). imagePaths can be omitted/"", a single path, or an
; array of paths. Missing files are skipped. Falls back to a plain MsgBox if
; no image ends up available. Blocks until the user closes it, same as MsgBox.
ShowInstructions(text, imagePaths := "")
{
    paths := (imagePaths = "") ? [] : (imagePaths is Array) ? imagePaths : [imagePaths]

    existingPaths := []
    for path in paths
        if FileExist(path)
            existingPaths.Push(path)

    if existingPaths.Length = 0
    {
        MsgBox text
        return
    }

    ; Sized relative to the screen (capped) instead of a fixed pixel width, so
    ; the dialog and image stay a sensible size on both small and large/high-
    ; DPI displays
    width := Min(700, Round(A_ScreenWidth * 0.4))

    g := Gui("+AlwaysOnTop", "Instructions")
    g.SetFont("s10")
    g.AddText("w" width, text)
    for path in existingPaths
        g.AddPicture("w" width, path)
    g.AddButton("w100 Default", "OK").OnEvent("Click", (*) => g.Destroy())
    g.OnEvent("Close", (*) => g.Destroy())
    g.Show()
    WinWaitClose("ahk_id " g.Hwnd)
}

; Shows text in a read-only, selectable/copyable Edit box instead of a MsgBox
; (MsgBox text can't be selected). Text arrives pre-selected so Ctrl+C alone
; copies everything.
ShowSelectableText(text, title := "Résultat")
{
    resultGui := Gui("+AlwaysOnTop", title)
    resultGui.SetFont("s10", "Consolas")
    edit := resultGui.AddEdit("w500 r10 ReadOnly -Wrap +HScroll", text)
    resultGui.AddButton("w100 Default", "OK").OnEvent("Click", (*) => resultGui.Destroy())
    resultGui.OnEvent("Close", (*) => resultGui.Destroy())
    resultGui.Show()
    edit.Focus()
    SendMessage(0xB1, 0, -1, edit.Hwnd) ; EM_SETSEL, select all
}
