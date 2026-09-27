#Requires AutoHotkey v2.0

#SingleInstance force
#Requires AutoHotkey v2.0
#SingleInstance Force

; Press Ctrl + Win + Left Mouse Button to drag a rectangle without clicking underneath
^#LButton:: {
    Area := SelectScreenRegion("LButton", "Lime", 80)
    if (Area.W > 5 && Area.H > 5) { ; Ignores accidental tiny clicks
        MsgBox("X: " Area.X "`nY: " Area.Y "`nWidth: " Area.W "`nHeight: " Area.H)
    }
}

SelectScreenRegion(Key, Color := "Lime", Transparent := 80) {
    CoordMode("Mouse", "Screen")
    MouseGetPos(&sX, &sY)
    
    ; Create a full-screen, invisible overlay to absorb all mouse actions
    overlay := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound -DPIScale +E0x200") ; E0x200 adds WS_EX_CLIENTEDGE
    overlay.BackColor := "Black"
    WinSetTransparent(1, overlay) ; Near-invisible to the user, but blocks clicks
    overlay.Show("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight)
    
    ; Create the visible selection rectangle
    ssrGui := Gui("+AlwaysOnTop -Caption +Border +ToolWindow +LastFound -DPIScale")
    ssrGui.BackColor := Color
    WinSetTransparent(Transparent, ssrGui)
    
    Loop {
        Sleep(10)
        MouseGetPos(&eX, &eY)
        W := Abs(sX - eX)
        H := Abs(sY - eY)
        X := Min(sX, eX)
        Y := Min(sY, eY)
        
        if (W > 0 && H > 0) {
            ssrGui.Show("x" X " y" Y " w" W " h" H " NoActivate")
        }
    } Until !GetKeyState(Key, "P")
    
    ; Clean up both GUIs
    ssrGui.Destroy()
    overlay.Destroy()
    
    return { X: X, Y: Y, W: W, H: H, X2: X + W, Y2: Y + H }
}
