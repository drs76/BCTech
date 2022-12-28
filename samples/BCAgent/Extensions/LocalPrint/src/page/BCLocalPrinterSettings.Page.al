/// <summary>
/// Page PTEBCLocalPrinterSettings (ID 50126).
/// </summary>
page 50126 PTEBCLocalPrinterSettings
{
    Caption = 'Local Printer Settings';
    PageType = Card;
    SourceTable = PTEBCLocalPrinterSetting;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            group(General)
            {
                field(UserID; Rec.UserID)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the PrinterID field.';
                    Editable = false;
                    Visible = false;
                }
                field(PrinterID; Rec.PrinterID)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the PrinterID field.';
                    Editable = false;
                }
                field(Landscape; Rec.Landscape)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Landscape field.';
                }
                group(PaperTray)
                {
                    Caption = 'Paper Tray';

                    field(PaperSourceKind; Rec.PaperSourceKind)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Paper Source Kind field.';
                    }
                    field(PaperKind; Rec.PaperKind)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Paper Kind field.';

                        trigger OnValidate()
                        begin
                            CurrPage.Update(true);
                        end;
                    }
                    group(PageSize)
                    {
                        Visible = ShowPageSize;

                        field(Height; Rec.Height)
                        {
                            ApplicationArea = All;
                            ToolTip = 'Specifies the value of the Height field.';
                        }
                        field(Width; Rec.Width)
                        {
                            ApplicationArea = All;
                            ToolTip = 'Specifies the value of the Width field.';
                        }
                        field(Units; Rec.Units)
                        {
                            ApplicationArea = All;
                            ToolTip = 'Specifies the value of the Units field.';
                        }
                    }
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetShowPageSize();
    end;

    trigger OnAfterGetRecord()
    begin
        SetShowPageSize();
    end;

    var
        [InDataSet]
        ShowPageSize: Boolean;


    local procedure SetShowPageSize()
    begin
        ShowPageSize := Rec.PaperKind = Rec.PaperKind::Custom;
    end;
}
