' Visual Basic for Application tools for help automating MS Office; stolen from
' http://www.extendoffice.com/documents/excel/1139-excel-unmerge-cells-and-fill.html
' Please follow instructions there for running the functions.

Sub UnMergeSameCell()
Dim Rng As Range, xCell As Range
xTitleId = "UnMergeSameCell"
Set WorkRng = Application.Selection
Set WorkRng = Application.InputBox("Range", xTitleId, WorkRng.Address, Type:=8)
Application.ScreenUpdating = False
Application.DisplayAlerts = False
For Each Rng In WorkRng
    If Rng.MergeCells Then
        With Rng.MergeArea
            .UnMerge
            .Formula = Rng.Formula
        End With
    End If
Next
Application.DisplayAlerts = True
Application.ScreenUpdating = True
End Sub

Sub SelectCellsByRange()
Dim Rng As Range, xCell As Range
xTitleId = "SelectCellsByRange"
Set WorkRng = Application.Selection
Set WorkRng = Application.InputBox("Range", xTitleId, WorkRng.Address, Type:=8)
Application.ScreenUpdating = False
Application.DisplayAlerts = False
WorkRng.Select
Application.DisplayAlerts = True
Application.ScreenUpdating = True
End Sub

