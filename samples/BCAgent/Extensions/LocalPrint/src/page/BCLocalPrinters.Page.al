/// <summary>
/// Page PTEBCLocalPrinters (ID 50101).
/// </summary>
page 50101 PTEBCLocalPrinters
{
    ApplicationArea = All;
    Caption = '50120';
    PageType = List;
    UsageCategory = Administration;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;

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
        SourceList: List of [Text];
        Printer: Text;
    begin
        LocalPrinterMgt.GetLocalPrinters();
        SourceList := LocalPrinterMgt.GetLocalPrinters().Split(TypeHelper.NewLine());
        foreach Printer in SourceList do
            TempNameValueBuffer.AddNewEntry(CopyStr(Printer, 1, MaxStrLen(TempNameValueBuffer.Name)), Printer);

        Rec.Copy(TempNameValueBuffer, true);
    end;

}
