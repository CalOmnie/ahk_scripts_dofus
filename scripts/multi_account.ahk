#Requires AutoHotkey v2.0
#SingleInstance Force
#Include utils.ahk

;; CONFIGURATION

switchWindowShortcut := "F5"
switchAndClickShortcut := "F6" ; like switchWindowShortcut, but also clicks at the current mouse position once the next window is active

macroShortcut := "F7"
; Switches to the first active Dofus window whose character name matches one
; of the given names for that shortcut. Does nothing if none of them are open.
characterShortcuts := Map(
    "F1", ["Cal-Vioc", "Cal-Ice"],
    "F2", ["Cal-Ori", "Cal-Siner"]
)

;; IMPLEMENTATION

macroReplayDelay := 250 ; Fixed delay (ms) inserted between replayed clicks, replacing whatever real gaps were recorded

mouseButtons := Map(
    "LButton", "Left",
    "RButton", "Right",
    "MButton", "Middle"
)

recording := false
recordingHwnd := 0
macroActions := []

; All shortcuts are scoped to Dofus windows only via IsDofusActive (in
; utils.ahk), passed to the HotIf() function -- HotIf() must be called
; immediately before every Hotkey() call it's meant to scope, including ones
; made later from inside another function (like SetClickRecordingEnabled,
; called from ToggleMacroRecording), since it's live global state rather
; than something resolved once based on where code sits in the script
HotIf(IsDofusActive)
Hotkey(switchWindowShortcut, SwitchWindow)
Hotkey(switchAndClickShortcut, SwitchWindowAndClick)
Hotkey(macroShortcut, ToggleMacroRecording)

for hotkeyName, buttonName in mouseButtons
    Hotkey("~" hotkeyName, MakeClickRecorder(buttonName))

for shortcut, names in characterShortcuts
    Hotkey(shortcut, MakeCharacterSwitchHandler(names))
HotIf()

SetClickRecordingEnabled(enabled)
{
    global mouseButtons
    HotIf(IsDofusActive)
    for hotkeyName, buttonName in mouseButtons
        Hotkey("~" hotkeyName, enabled ? "On" : "Off")
    HotIf()
}

SetClickRecordingEnabled(false) ; dormant until a recording is actually in progress

SwitchWindow(*)
{
    nextHwnd := NextWindowInCycle()
    if !nextHwnd
        return

    ActivateWindow(nextHwnd)
}

; Like SwitchWindow, but also sends a click at wherever the mouse currently
; is once the next window is active -- e.g. for clicking the same on-screen
; spot (a spell, the map) across every account without moving the cursor
SwitchWindowAndClick(*)
{
    Click()
    Sleep 50
    nextHwnd := NextWindowInCycle()
    if !nextHwnd
        return

    WinActivate(nextHwnd)
    Sleep 50
    if !WinWaitActive(nextHwnd, , 2)
        return
}

; Wrapping the closure in its own function call gives it its own copy of
; `names` -- capturing the for-loop's variable directly would have every
; hotkey end up switching to whichever entry was last in the map
MakeCharacterSwitchHandler(names)
{
    return (*) => SwitchToCharacter(names)
}

; Switches to the first active Dofus window whose character name is in
; `names`, or does nothing if none of them are open
SwitchToCharacter(names)
{
    for hwnd in SortNumArray(WinGetList("ahk_exe Dofus.exe"))
    {
        char := ExtractCharName(WinGetTitle(hwnd))
        for name in names
            if char = name
            {
                WinActivate(hwnd)
                return
            }
    }
}

; Returns the hwnd of the next window (same process as the active one) in
; the cycle after the currently active window, or 0 if there's nothing to
; cycle to
NextWindowInCycle()
{
    SetWinDelay(-1)
    SetControlDelay(-1)
    SetKeyDelay(-1)

    proc := WinGetProcessName("A")
    if (proc = "")
        return 0

    cycleList := SortNumArray(WinGetList("ahk_exe " proc))
    if (cycleList.Length = 0)
        return 0

    active := WinGetID("A")
    cycleIndex := 0
    for i, hwnd in cycleList
        if (hwnd = active)
            cycleIndex := i

    cycleIndex++
    if (cycleIndex > cycleList.Length)
        cycleIndex := 1

    return cycleList[cycleIndex]
}

; Starts listening for mouse clicks on the first press, stops on the second
; press and replays every recorded click on every other Dofus window
ToggleMacroRecording(*)
{
    global recording, recordingHwnd, macroActions

    if !recording
    {
        recordingHwnd := WinGetID("A")
        macroActions := []
        recording := true
        SetClickRecordingEnabled(true)
        SoundBeep(1200, 100)
    }
    else
    {
        recording := false
        SetClickRecordingEnabled(false)
        SoundBeep(600, 100)
        ReplayOnOtherWindows(macroActions, recordingHwnd)
    }
}

; Wrapping each closure in its own function call gives it its own copy of
; the button name -- capturing the for-loop's variable directly would have
; every hotkey end up recording whichever one was registered last
MakeClickRecorder(button)
{
    return (*) => RecordClick(button)
}

RecordClick(button)
{
    global recording, recordingHwnd, macroActions

    if !recording || !WinActive(recordingHwnd)
        return

    CoordMode "Mouse", "Client"
    MouseGetPos(&x, &y)
    macroActions.Push({button: button, x: x, y: y})
}

ReplayOnOtherWindows(actions, sourceHwnd)
{
    if actions.Length = 0
        return

    windows := SortNumArray(WinGetList("ahk_exe Dofus.exe"))
    for hwnd in windows
    {
        if hwnd = sourceHwnd
            continue

        if !ActivateWindow(hwnd)
            continue

        ReplayActions(actions)
    }

}

ReplayActions(actions)
{
    global macroReplayDelay
    CoordMode "Mouse", "Client"
    for action in actions
    {
        Click(action.x " " action.y " " action.button)
        Sleep macroReplayDelay
    }
}

;; UTILITIES

; AHK V2 Sort function only works on String
; so we have to convert our int array to string to sort it
; and then convert it back into an array.
; If it sounds stupid, it's because it is.
SortNumArray(arr)
{
    str := ""
    for hwnd in arr
        str .= hwnd "`n"
    str := Sort(Trim(str, "`n"), "N")

    sorted := []
    for hwnd in StrSplit(str, "`n")
        sorted.Push(Integer(hwnd))
    return sorted
}
