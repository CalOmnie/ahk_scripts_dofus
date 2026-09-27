#Requires AutoHotkey v2.0
#SingleInstance Force
#Include utils.ahk

;; CONFIGURATION

travelShortcut := "^y"
broadcastTravelShortcut := "^+y" ; same as travelShortcut, but sends the command to every active Dofus window
broadcastClipboardShortcut := "^+c" ; no prompt: just sends whatever's currently in the clipboard to every active Dofus window
clipboardShortcut := "^+v" ; same as broadcastClipboardShortcut, but only sends it to the active window

; Named locations that bypass coordinate parsing entirely.
; "shortcut" is optional: leave it "" to skip creating a dedicated hotkey
; that travels straight there, e.g. "bank" -> travel to 10,22 via Ctrl+Shift+B
namedLocations := Map(
    "bank", {coords: [-31, -57], shortcut: "^F1"},
    "kano", {coords: [0, 0], shortcut: "^F2"},
    "enclo", {coords: [-18, 0], shortcut: "^F3"},
    "dim", {coords: [-22, -24], shortcut: "^F4"},
)

;; IMPLEMENTATION

HotIf(IsDofusActive)
Hotkey(travelShortcut, TravelPrompt)
Hotkey(broadcastTravelShortcut, BroadcastTravelPrompt)
Hotkey(broadcastClipboardShortcut, BroadcastClipboard)
Hotkey(clipboardShortcut, SendClipboard)

for name, entry in namedLocations
    if entry.shortcut != ""
        Hotkey(entry.shortcut, MakeLocationHandler(entry))
HotIf()

TravelPrompt(*)
{
    coords := PromptForCoordinates("Travel")
    if !IsObject(coords)
        return

    TravelTo(coords)
}

; Same coordinate prompt as TravelPrompt, but sends the resulting command to
; every active Dofus window instead of just the one it was triggered from
BroadcastTravelPrompt(*)
{
    coords := PromptForCoordinates("Travel (all windows)")
    if !IsObject(coords)
        return

    if !PrepareTravelCommand(coords)
        return

    BroadcastToAllWindows()
}

; Prompts for coordinates or a saved location name, showing an error and
; returning false if the user cancelled or the input couldn't be resolved
PromptForCoordinates(title)
{
    ib := InputBox("Enter coordinates (e.g. 12 24, 12,24, /travel 12 24) or a saved location name", title)
    if ib.Result = "Cancel"
        return false

    coords := ResolveCoordinates(ib.Value)
    if !IsObject(coords)
    {
        MsgBox "Could not parse coordinates from: " ib.Value
        return false
    }

    return coords
}

; No prompt, no coordinate resolution -- just fans out whatever's currently
; in the clipboard, e.g. a command already built by TravelPrompt or
; BroadcastTravelPrompt on another window
BroadcastClipboard(*)
{
    BroadcastToAllWindows()
}

; Same idea, but only sends the clipboard to the currently active window
SendClipboard(*)
{
    SendChatCommand()
}

BroadcastToAllWindows()
{
    sourceHwnd := WinGetID("A")
    for hwnd in WinGetList("ahk_exe Dofus.exe")
    {
        if !ActivateWindow(hwnd)
            continue

        SendChatCommand()
    }
    WinActivate(sourceHwnd)
}

; Returns a hotkey handler bound to this specific location. Wrapping the
; closure in its own function call gives each one its own copy of `entry`
; -- capturing the for-loop's variable directly would have every handler
; end up pointing at whichever location was last in the map.
MakeLocationHandler(entry)
{
    return (*) => TravelTo({x: entry.coords[1], y: entry.coords[2]})
}

TravelTo(coords)
{
    if !PrepareTravelCommand(coords)
        return

    SendChatCommand()
}

; Builds the travel command for {x, y} and copies it to the clipboard,
; showing an error and returning false if no zaap data could be loaded
PrepareTravelCommand(coords)
{
    result := BuildTravelCommand(coords)
    if result = ""
    {
        MsgBox "No zaaps found in data\zaaps.yaml"
        return false
    }

    A_Clipboard := result
    return true
}

;; UTILITIES

ResolveCoordinates(input)
{
    global namedLocations

    key := StrLower(Trim(input))
    if namedLocations.Has(key)
    {
        loc := namedLocations[key].coords
        return {x: loc[1], y: loc[2]}
    }

    return ParseCoordinates(input)
}
