#Requires AutoHotkey v2
#SingleInstance Force
#Include <OCR>

#Requires AutoHotkey v2.0
#HotIf WinActive("ahk_exe Dofus.exe")

prices := []

^p::
{
    RecipeTotalPrice()
}

^+p::
{
    RecipeTotalPrice(true)
}

^u::
{
    global prices
    num := FindPriceNew(false)
    if num < 0 {
        total := 0
        for p in prices {
            total += p
        }
        MsgBox "Price found : " FormatThousands(total)
        prices := []
    }
    else
        prices.Push(num)
}

^+u::
{
    FindPriceNew(true)
}

RecipeTotalPrice(debug := false)
{
    ; Move in 45 px steps
    step := 45

    CoordMode "Mouse"
    MouseGetPos(&startX, &y)
    full_price := 0
    Loop
    {
        price := FindPriceNew(debug)
        if price < 0
            break

        full_price += price

        SendMode "Event"
        CoordMode "Mouse"
        x := startX + A_Index * step
        MouseMove x, y, 2

        Sleep 75

    }
    A_Clipboard := full_price
    MsgBox FormatThousands(full_price)
}


ParseMaxPrice(ocr_res, debug := false) {
    res := -1
    if debug {
        MsgBox "OCR Result: " ocr_res.text
    }
    for line in ocr_res.Lines {
        if debug {
            MsgBox "Line text: " line.Text
        }
        if RegExMatch(line.Text, "[0-9]+(?:\s+[0-9O]+)*", &m)
        {
            numberText := StrReplace(m[0], "O", "0")
            number := Integer(StrReplace(numberText, " "))
            res := Max(res, number)
        }
    }
    if debug {
        MsgBox "Max price found: " FormatThousands(res)
    }
    return res
}

FindPriceNew(debug := false)
{
    CoordMode "Mouse"
    MouseGetPos(&startX, &startY)
    ; Look around both ides of mouse position
    ; Locate PRIX MOYEN
    ; Look around PRIX MOYEN
    ; Iterate over all lines for the highest number
    search_area := {x: startX - 400, y: startY + 100, w: 800, h: 150}
    if debug {
        rect := DrawRectangle(search_area.x, search_area.y, search_area.w, search_area.h, "Green", 2)
        Sleep 500
        DestroyRectangle(rect)
    }
    result := OCR.FromRect(
        search_area.x, search_area.y, search_area.w, search_area.h,
        {grayscale: true, scale: 3, lang: "fr"}
    )
    if debug
        result.Highlight(500)
    text := ""
    found := false
    for line in result.Lines {
        if InStr(line.Text, "PRIX MOYEN") {
            found := true
            surrounding := {
                x: line.x - 2, y: line.y - 2,
                w: line.w + 100, h: line.h + 30
            }
        }
    }
    if not found
        return -1

    if debug {
        rect := DrawRectangle(surrounding.x, surrounding.y, surrounding.w, surrounding.h, "Red", 2)
        Sleep 500
        DestroyRectangle(rect)
    }
    price_res := OCR.FromRect(
        surrounding.x, surrounding.y, surrounding.w, surrounding.h,
        {grayscale: true, scale: 3, lang: "fr"}
    )
    text := price_res.text
    if debug
        price_res.Highlight(500)

    return ParseMaxPrice(price_res, debug)
}

FormatThousands(n) {
    return RegExReplace(String(n), "\B(?=(\d{3})+(?!\d))", " ")
}

DrawRectangle(x, y, w, h, color := "Red", thickness := 2)
{
    rect := {}

    rect.top := Gui("-Caption +AlwaysOnTop +ToolWindow")
    rect.bottom := Gui("-Caption +AlwaysOnTop +ToolWindow")
    rect.left := Gui("-Caption +AlwaysOnTop +ToolWindow")
    rect.right := Gui("-Caption +AlwaysOnTop +ToolWindow")

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