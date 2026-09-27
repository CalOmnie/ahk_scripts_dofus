#Requires AutoHotkey v2.0

;; CONFIGURATION

switchWindowShortcut := "F1"

;; IMPLEMENTATION

Hotkey(switchWindowShortcut, SwitchWindow)
SwitchWindow(*)
{
    SetWinDelay(-1)
    SetControlDelay(-1)
    SetKeyDelay(-1)

    proc := WinGetProcessName("A")
    if (proc = "")
        return

    cycleList := SortNumArray(WinGetList("ahk_exe " proc))
    if (cycleList.Length = 0)
        return

    active := WinGetID("A")
    cycleIndex := 0
    for i, hwnd in cycleList
        if (hwnd = active)
            cycleIndex := i

    cycleIndex++
    if (cycleIndex > cycleList.Length)
        cycleIndex := 1

    WinActivate(cycleList[cycleIndex])
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