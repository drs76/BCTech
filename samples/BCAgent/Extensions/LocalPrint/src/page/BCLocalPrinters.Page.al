/// <summary>
/// Page PTEBCLocalPrinters (ID 50125).
/// </summary>
page 50125 PTEBCLocalPrinters
{
    ApplicationArea = All;
    Caption = 'Local Printers';
    PageType = List;
    UsageCategory = Administration;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    Editable = false;
    ShowFilter = false;
    LinksAllowed = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(printerName; Rec.Name)
                {
                    Caption = 'Printer Name';
                    ToolTip = 'Specifies the local printer name';
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        PopulateSource();
    end;

    local procedure PopulateSource()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        LocalPrinterMgt: Codeunit PTEBCLocalPrinterMgt;
        TypeHelper: Codeunit "Type Helper";
        Printer: Text;
    begin
        LocalPrinterMgt.GetLocalPrinters();
        foreach Printer in LocalPrinterMgt.GetLocalPrinters().Split(TypeHelper.NewLine()) do
            if StrLen(Printer) > 0 then
                TempNameValueBuffer.AddNewEntry(CopyStr(Printer, 1, MaxStrLen(TempNameValueBuffer.Name)), Printer);

        Rec.Copy(TempNameValueBuffer, true);
    end;

}
