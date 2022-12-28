/// <summary>
/// Table PTEBCLocalPrinterSetting (ID 50125).
/// </summary>
table 50125 PTEBCLocalPrinterSetting
{
    Caption = 'Local Printer Setting';
    DataClassification = CustomerContent;
    DataPerCompany = false;

    fields
    {
        field(1; UserID; Text[250])
        {
            Caption = 'PrinterID';
            DataClassification = CustomerContent;
        }
        field(2; PrinterID; Text[250])
        {
            Caption = 'PrinterID';
            DataClassification = CustomerContent;
        }
        field(3; Landscape; Boolean)
        {
            Caption = 'Landscape';
            DataClassification = CustomerContent;
            InitValue = false;
        }
        field(4; PaperSourceKind; Enum "Printer Paper Source Kind")
        {
            Caption = 'Paper Source Kind';
            DataClassification = CustomerContent;
            InitValue = AutomaticFeed;
        }
        field(5; PaperKind; Enum "Printer Paper Kind")
        {
            Caption = 'Paper Kind';
            DataClassification = CustomerContent;
            InitValue = A4;
        }
        field(6; Units; Enum "Printer Unit")
        {
            Caption = 'Units';
            DataClassification = CustomerContent;
        }
        field(7; Height; Decimal)
        {
            Caption = 'Height';
            DataClassification = CustomerContent;
        }
        field(8; Width; Decimal)
        {
            Caption = 'Width';
            DataClassification = CustomerContent;
        }
        field(9; Color; Boolean)
        {
            Caption = 'Color (Not Used)';
            DataClassification = CustomerContent;
        }
        field(10; Duplex; Boolean)
        {
            Caption = 'Duplex (Not Used)';
            DataClassification = CustomerContent;
        }
        field(11; DefaulNoCopies; Integer)
        {
            Caption = 'Default No. Copies (Not Used)';
            DataClassification = CustomerContent;
            InitValue = 1;
        }
    }
    keys
    {
        key(PK; UserId, PrinterID)
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// ToJson.
    /// Get Printer Json Setup. 
    /// </summary>
    /// <returns>Return variable ReturnValue of type JsonObject.</returns>
    internal procedure ToJson() ReturnValue: JsonObject
    var
        JPaperTrays: JsonArray;
        JPaperTray: JsonObject;
        VersionLbl: Label 'version';
        DescriptionLbl: Label 'description';
        PaperTraysLbl: Label 'papertrays';
        PaperSourceKindLbl: Label 'papersourcekind';
        PaperKindLbl: Label 'paperkind';
        LandscapeLbl: Label 'landscape';
        ColorLbl: Label 'color';
        DuplexLbl: Label 'duplex';
        DefaultCopiesLbl: Label 'defaultcopies';
    begin
        ReturnValue.Add(VersionLbl, 1);
        ReturnValue.Add(DescriptionLbl, Rec.PrinterID);
        ReturnValue.Add(ColorLbl, Rec.Color);
        ReturnValue.Add(DuplexLbl, Rec.Duplex);
        ReturnValue.Add(DefaultCopiesLbl, Rec.DefaulNoCopies);
        JPaperTray.Add(PaperSourceKindLbl, Rec.PaperSourceKind.AsInteger());
        JPaperTray.Add(PaperKindLbl, Rec.PaperKind.AsInteger());
        JPaperTray.Add(LandscapeLbl, Rec.Landscape);
        JPaperTrays.Add(JPaperTray);
        ReturnValue.Add(PaperTraysLbl, JPaperTrays);
    end;
}
