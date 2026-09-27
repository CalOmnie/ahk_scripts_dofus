#Requires AutoHotkey v2.0
#Include utils.ahk

; This is a support file for recipe_price.ahk, not a standalone script --
; FindPrixMoyenLine here depends on ocrOptions, debugHighlightDelayMs and
; FlashRectangle, all defined there. Run recipe_price.ahk (which #Include's
; this file); running this file directly will fail with something like
; "ocrOptions ... never assigned a value".

;; CONFIGURATION

calibrateShortcut := "^+r"

;; IMPLEMENTATION

HotIf(IsDofusActive)
Hotkey(calibrateShortcut, CalibrateRecipeSetup)
HotIf()

; TEMPORARY: isolated tests, not scoped to Dofus so they can be tried from
; anywhere -- remove once confirmed working
Hotkey("F9", DebugDragSelectRectangle)
Hotkey("F10", DebugDrawRectangleOnly)

; Walks through the 3 measurements RecipeTotalPrice needs and updates them
; live for this session. Each step drags a rectangle over a full-screen
; overlay (see DragSelectRectangle) so the click never reaches Dofus itself.
CalibrateRecipeSetup(*)
{
    global ingredientStepPx, searchAreaOffset, priceAreaPadding

    stepRect := DragSelectRectangle(
        "Étape 1/4 - Espacement entre ingrédients`n`n"
        "Dessinez un rectangle englobant les 2 premiers ingrédients de la recette (voir l'image).",
        A_ScriptDir "\..\data\calibration_step1.png"
    )
    if !IsObject(stepRect)
        return
    ; Half the rectangle's width, not its full width -- the rectangle spans 2
    ; ingredients plus the spacing between them, so half of it is the
    ; per-ingredient step
    newStepPx := Round(stepRect.w / 2)

    anchor := CaptureMousePositionByClick(
        "Étape 2/4 - Zone de recherche`n`n"
        "Positionnez votre souris comme vous le feriez normalement pour vérifier le prix d'un ingrédient (infobulle ouverte, Alt pour la verrouiller), puis cliquez pour enregistrer cette position.",
        A_ScriptDir "\..\data\calibration_step2.png"
    )
    if !IsObject(anchor)
        return

    searchRect := DragSelectRectangle(
        "Étape 3/4 - Zone de l'infobulle`n`n"
        "Dessinez un rectangle qui couvre toute la zone où l'infobulle de prix apparaît (assez large pour englober 'PRIX MOYEN' et le prix). "
        "Prévoyez large : l'infobulle n'apparaît pas toujours exactement au même endroit par rapport à la souris (voir les 2 exemples ci-dessous).",
        [A_ScriptDir "\..\data\calibration_step3_1.png", A_ScriptDir "\..\data\calibration_step3_2.png"]
    )
    if !IsObject(searchRect)
        return
    newSearchAreaOffset := {
        x: searchRect.x - anchor.x,
        y: searchRect.y - anchor.y,
        w: searchRect.w,
        h: searchRect.h
    }

    ; Searches the exact rectangle just dragged (not reconstructed from
    ; the anchor + offset -- the mouse isn't back at the anchor anymore at
    ; this point, it's wherever the drag ended). debug: true flashes it
    ; (green) right before the search and prints/highlights what OCR sees.
    line := FindPrixMoyenLineInRect(searchRect, true)
    if !IsObject(line)
    {
        MsgBox "Impossible de détecter 'PRIX MOYEN' avec cette zone de recherche. Gardez l'infobulle ouverte au même endroit et relancez la calibration."
        return
    }

    priceRect := DragSelectRectangle(
        "Étape 4/4 - Zone du prix`n`n"
        "Dessinez un rectangle autour de l'endroit où le prix moyen doit être lu. "
        "Prévoyez large : un prix élevé prend plus de place qu'un petit prix.",
        A_ScriptDir "\..\data\calibration_step4_1.png"
    )
    if !IsObject(priceRect)
        return
    newPriceAreaPadding := {
        x: priceRect.x - line.x,
        y: priceRect.y - line.y,
        w: priceRect.w - line.w,
        h: priceRect.h - line.h
    }

    ingredientStepPx := newStepPx
    searchAreaOffset := newSearchAreaOffset
    priceAreaPadding := newPriceAreaPadding

    ShowSelectableText(
        "ingredientStepPx := " newStepPx "`n"
        "searchAreaOffset := {x: " newSearchAreaOffset.x ", y: " newSearchAreaOffset.y ", w: " newSearchAreaOffset.w ", h: " newSearchAreaOffset.h "}`n"
        "priceAreaPadding := {x: " newPriceAreaPadding.x ", y: " newPriceAreaPadding.y ", w: " newPriceAreaPadding.w ", h: " newPriceAreaPadding.h "}",
        "Calibration terminée -- copiez ces lignes dans CONFIGURATION"
    )
}

; TEMPORARY: see the Hotkey("F9", ...) registration above
DebugDragSelectRectangle(*)
{
    rect := DragSelectRectangle("Test : glissez pour dessiner un rectangle -- il doit suivre la souris pendant le glissement.")
    if !IsObject(rect)
    {
        MsgBox "Annulé (Échap)"
        return
    }
    MsgBox "x=" rect.x " y=" rect.y " w=" rect.w " h=" rect.h
}

; TEMPORARY: see the Hotkey("F10", ...) registration above. Drags a
; rectangle over the same click-absorbing overlay as DragSelectRectangle
; (so it works fine over a live Dofus tooltip without clicking into the
; game), then hands that exact rectangle straight to OCR.FromRect -- no
; offsets, no anchors, no calibration math -- flashing it first, then
; highlighting and printing whatever OCR detects. Tests OCR positioning in
; isolation from the rest of the calibration flow.
DebugDrawRectangleOnly(*)
{
    global ocrOptions, debugHighlightDelayMs

    overlay := CreateClickAbsorbingOverlay()

    Loop
    {
        if GetKeyState("Escape", "P")
        {
            overlay.Destroy()
            return
        }
        if GetKeyState("LButton", "P")
            break
        Sleep 10
    }

    CoordMode "Mouse"
    MouseGetPos(&startX, &startY)
    cancelled := false

    selectionGui := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale")
    selectionGui.BackColor := "Yellow"
    WinSetTransparent(120, selectionGui)

    Loop
    {
        if GetKeyState("Escape", "P")
        {
            cancelled := true
            break
        }
        if !GetKeyState("LButton", "P")
            break

        MouseGetPos(&curX, &curY)
        x := Min(startX, curX)
        y := Min(startY, curY)
        w := Abs(curX - startX)
        h := Abs(curY - startY)

        if w > 0 && h > 0
            selectionGui.Show("x" x " y" y " w" w " h" h " NoActivate")

        Sleep 10
    }

    MouseGetPos(&endX, &endY)
    selectionGui.Destroy()
    overlay.Destroy()

    if cancelled
        return

    finalRect := {
        x: Min(startX, endX),
        y: Min(startY, endY),
        w: Max(Abs(endX - startX), 1),
        h: Max(Abs(endY - startY), 1)
    }

    FlashRectangle(finalRect, "Green")

    result := OCR.FromRect(finalRect.x, finalRect.y, finalRect.w, finalRect.h, ocrOptions)
    result.Highlight(debugHighlightDelayMs)
    MsgBox "x=" finalRect.x " y=" finalRect.y " w=" finalRect.w " h=" finalRect.h "`n`nOCR Result: " result.text
}

;; UTILITIES

; Runs the OCR search pass at the current mouse position with the given
; offset, returning the detected "PRIX MOYEN" line, or false if not found
FindPrixMoyenLine(offset, debug := false)
{
    CoordMode "Mouse"
    MouseGetPos(&startX, &startY)

    searchArea := {
        x: startX + offset.x,
        y: startY + offset.y,
        w: offset.w,
        h: offset.h
    }
    return FindPrixMoyenLineInRect(searchArea, debug)
}

; Same as FindPrixMoyenLine, but takes an absolute screen rectangle instead
; of an offset from the current mouse position -- use this when you already
; have the exact rectangle to search (e.g. one just dragged out), since
; reconstructing it from an offset would need the mouse to still be at
; whatever position the offset was measured from
FindPrixMoyenLineInRect(rect, debug := false)
{
    global ocrOptions, debugHighlightDelayMs

    if debug
        FlashRectangle(rect, "Green")

    searchResult := OCR.FromRect(rect.x, rect.y, rect.w, rect.h, ocrOptions)
    if debug
    {
        searchResult.Highlight(debugHighlightDelayMs)
        MsgBox "OCR Result: " searchResult.text
    }

    for line in searchResult.Lines
        if InStr(line.Text, "PRIX MOYEN")
            return line

    return false
}

; Creates and shows a full-screen, always-on-top, near-invisible overlay
; that blocks clicks from reaching whatever's underneath (e.g. Dofus).
; Based on a working reference (test_drag.ahk) -- two things turned out to
; matter that our first attempt got wrong: this uses alpha transparency
; (WinSetTransparent) rather than color-key transparency (WinSetTransColor,
; which apparently lets Windows pass clicks straight through the
; transparent pixels), and it's activated (not shown with "NoActivate") so
; it takes focus away from whatever's underneath -- games that read mouse
; drag via raw input tied to being the focused window (e.g. camera-pan)
; otherwise keep receiving it regardless of window z-order or capture.
; Caller must Destroy() it when done.
CreateClickAbsorbingOverlay()
{
    vLeft := SysGet(76)
    vTop := SysGet(77)
    vWidth := SysGet(78)
    vHeight := SysGet(79)

    overlay := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound -DPIScale +E0x200")
    overlay.BackColor := "Black"
    WinSetTransparent(1, overlay)
    overlay.Show("x" vLeft " y" vTop " w" vWidth " h" vHeight)

    return overlay
}

; Shows instructions (optionally with an image, see ShowInstructions), then
; lets the user click once to record a position, returning it as {x, y}, or
; false if cancelled with Escape. No overlay here (unlike DragSelectRectangle)
; -- this click needs to reach Dofus normally so hovering the mouse still
; shows the tooltip
CaptureMousePositionByClick(instructions, imagePath := "")
{
    ShowInstructions(instructions "`n`nCliquez pour enregistrer la position, ou Échap pour annuler.", imagePath)

    Loop
    {
        if GetKeyState("Escape", "P")
            return false
        if GetKeyState("LButton", "P")
            break
        Sleep 10
    }

    CoordMode "Mouse"
    MouseGetPos(&x, &y)

    while GetKeyState("LButton", "P")
        Sleep 10

    return {x: x, y: y}
}

; Shows instructions (optionally with an image, see ShowInstructions), then
; lets the user drag a rectangle anywhere on screen, drawing it live as it's
; dragged, and returns it as {x, y, w, h}, or false if cancelled with Escape.
; The drag happens over a full-screen, always-on-top overlay so it lands on
; it instead of on whatever's underneath (e.g. Dofus). The visible selection
; box is a single translucent fill (like the working reference), not the
; hollow border DrawRectangle draws.
DragSelectRectangle(instructions, imagePath := "")
{
    ShowInstructions(instructions "`n`nCliquez-glissez pour dessiner le rectangle, relâchez pour valider, ou Échap pour annuler.", imagePath)

    overlay := CreateClickAbsorbingOverlay()

    Loop
    {
        if GetKeyState("Escape", "P")
        {
            overlay.Destroy()
            return false
        }
        if GetKeyState("LButton", "P")
            break
        Sleep 10
    }

    CoordMode "Mouse"
    MouseGetPos(&startX, &startY)
    result := false

    selectionGui := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale")
    selectionGui.BackColor := "Yellow"
    WinSetTransparent(120, selectionGui)

    Loop
    {
        if GetKeyState("Escape", "P")
            break

        if !GetKeyState("LButton", "P")
        {
            MouseGetPos(&endX, &endY)
            result := {
                x: Min(startX, endX),
                y: Min(startY, endY),
                w: Max(Abs(endX - startX), 1),
                h: Max(Abs(endY - startY), 1)
            }
            break
        }

        MouseGetPos(&curX, &curY)
        x := Min(startX, curX)
        y := Min(startY, curY)
        w := Abs(curX - startX)
        h := Abs(curY - startY)

        if w > 0 && h > 0
            selectionGui.Show("x" x " y" y " w" w " h" h " NoActivate")

        Sleep 10
    }

    selectionGui.Destroy()
    overlay.Destroy()

    return result
}
