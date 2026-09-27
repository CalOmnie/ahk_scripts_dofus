#Requires AutoHotkey v2.0
#SingleInstance Force
#Include <OCR>
#Include utils.ahk
#Include ocr_utils.ahk

;; CONFIGURATION

recipePriceShortcut := "^p"
recipePriceDebugShortcut := "^+p"
priceAccumulateShortcut := "^u"
priceAccumulateDebugShortcut := "^+u"

ocrOptions := {grayscale: true, scale: 3, lang: "fr"}
ingredientMoveDelayMs := 150
debugHighlightDelayMs := 500

; ==============================================================================
; Valeurs calibrées pour VOTRE résolution d'écran et taille de fenêtre Dofus.
; Ne les modifiez pas à la main : appuyez sur Ctrl+Maj+R (assistant de
; calibration, voir ocr_utils.ahk et le README) et copiez les 3 lignes
; affichées à la fin ici.
ingredientStepPx := 45
searchAreaOffset := {x: -453, y: 57, w: 805, h: 225}
priceAreaPadding := {x: -11, y: -14, w: 153, h: 72}
; ==============================================================================

;; IMPLEMENTATION

HotIf(IsDofusActive)
Hotkey(recipePriceShortcut, RecipePriceHandler)
Hotkey(recipePriceDebugShortcut, RecipePriceDebugHandler)
Hotkey(priceAccumulateShortcut, PriceAccumulateHandler)
Hotkey(priceAccumulateDebugShortcut, PriceAccumulateDebugHandler)
HotIf()

prices := []

RecipePriceHandler(*)
{
    RecipeTotalPrice()
}

RecipePriceDebugHandler(*)
{
    RecipeTotalPrice(true)
}

PriceAccumulateHandler(*)
{
    global prices
    num := FindPrice(false)
    if num < 0
    {
        total := 0
        for p in prices
            total += p
        MsgBox "Price found : " FormatThousands(total)
        prices := []
    }
    else
        prices.Push(num)
}

PriceAccumulateDebugHandler(*)
{
    FindPrice(true)
}

RecipeTotalPrice(debug := false)
{
    global ingredientStepPx, ingredientMoveDelayMs

    CoordMode "Mouse"
    MouseGetPos(&startX, &y)

    totalPrice := 0
    Loop
    {
        price := FindPrice(debug)
        if price < 0
            break

        totalPrice += price

        x := startX + A_Index * ingredientStepPx
        MouseMove x, y, 2
        Sleep ingredientMoveDelayMs
    }

    A_Clipboard := totalPrice
    MsgBox FormatThousands(totalPrice)
}

;; UTILITIES

ParseMaxPrice(ocrResult, debug := false)
{
    best := -1
    if debug
        MsgBox "OCR Result: " ocrResult.text

    for line in ocrResult.Lines
    {
        if debug
            MsgBox "Line text: " line.Text

        if RegExMatch(line.Text, "[0-9]+(?:\s+[0-9O]+)*", &m)
        {
            priceText := StrReplace(StrReplace(m[0], "O", "0"), " ")
            best := Max(best, Integer(priceText))
        }
    }

    if debug
        MsgBox "Max price found: " FormatThousands(best)

    return best
}

FindPrice(debug := false)
{
    global searchAreaOffset, priceAreaPadding, ocrOptions, debugHighlightDelayMs

    line := FindPrixMoyenLine(searchAreaOffset, debug)
    if !IsObject(line)
        return -1

    priceArea := {
        x: line.x + priceAreaPadding.x,
        y: line.y + priceAreaPadding.y,
        w: line.w + priceAreaPadding.w,
        h: line.h + priceAreaPadding.h
    }
    if debug
        FlashRectangle(priceArea, "Red")

    priceResult := OCR.FromRect(priceArea.x, priceArea.y, priceArea.w, priceArea.h, ocrOptions)
    if debug
        priceResult.Highlight(debugHighlightDelayMs)

    return ParseMaxPrice(priceResult, debug)
}

FormatThousands(n)
{
    return RegExReplace(String(n), "\B(?=(\d{3})+(?!\d))", " ")
}

FlashRectangle(area, color)
{
    global debugHighlightDelayMs
    rect := DrawRectangle(area.x, area.y, area.w, area.h, color, 2)
    Sleep debugHighlightDelayMs
    DestroyRectangle(rect)
}
