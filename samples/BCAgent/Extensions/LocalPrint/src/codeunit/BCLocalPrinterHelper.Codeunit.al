/// <summary>
/// Codeunit PTEBCLocalPrinterHelper (ID 50127).
/// </summary>
codeunit 50127 PTEBCLocalPrinterHelper
{
    Permissions = tabledata Printer = RIM;

    /// <summary>
    /// SelectPrinter.
    /// </summary>
    internal procedure SelectPrinter()
    var
        PrinterList: Page PTEBCLocalPrinters;
        SelectLbl: Label 'Select printer';
    begin
        PrinterList.Caption(SelectLbl);
        PrinterList.RunModal();
    end;

    /// <summary>
    /// AddLocalPrinters.
    /// </summary>
    /// <param name="Printers">VAR Dictionary of [Text[250], JsonObject].</param>
    internal procedure AddLocalPrinters(var Printers: Dictionary of [Text[250], JsonObject])
    var
        LocalPrinterMgt: Codeunit PTEBCLocalPrinterMgt;
        LocalPrinterSetupMgt: Codeunit PTEBCLocalPrinterSetupMgt;
        TypeHelper: Codeunit "Type Helper";
        Printername: Text;
    begin
        foreach Printername in LocalPrinterMgt.GetLocalPrinters().Split(TypeHelper.NewLine()) do
            if StrLen(Printername) > 0 then
                Printers.Add(CopyStr(Printername, 1, 250), LocalPrinterSetupMgt.GetPrinterSettingsJson(Printername));
    end;

    /// <summary>
    /// TryRunLocalPrinterSetup.
    /// </summary>
    /// <param name="PrinterID">Text.</param>
    /// <returns>False if an runtime error occurred. Otherwise true.</returns>
    [TryFunction]
    internal procedure TryRunLocalPrinterSetup(PrinterID: Text)
    var
        LocalPrinterSetting: Record PTEBCLocalPrinterSetting;
        LocalPrinterSetupMgt: Codeunit PTEBCLocalPrinterSetupMgt;
    begin
        if not LocalPrinterSetting.Get(CopyStr(UserId(), 1, MaxStrLen(LocalPrinterSetting.UserID)), CopyStr(PrinterID, 1, MaxStrLen(LocalPrinterSetting.PrinterID))) then
            LocalPrinterSetupMgt.AddLocalPrinterSetting(PrinterID, LocalPrinterSetting);

        LocalPrinterSetting.SetRecFilter();
        Page.RunModal(Page::PTEBCLocalPrinterSettings, LocalPrinterSetting);
    end;

    /// <summary>
    /// TrySendToLocalPrinter.
    /// </summary>
    /// <param name="PayLoad">JsonObject.</param>
    /// <param name="DocumentStream">InStream.</param>
    /// <returns>False if an runtime error occurred. Otherwise true.</returns>
    internal procedure TrySendToLocalPrinter(PayLoad: JsonObject; DocumentStream: InStream) ReturnValue: Boolean
    var
        LocalPrinterMgt: Codeunit PTEBCLocalPrinterMgt;
        JToken: JsonToken;
        Printername: Text;
        GuilAllowedErr: Label 'GuiAllowed must be true.';
        PrinternameLbl: Label 'printername';
        DocumentTypeTok: Label 'documenttype';
    begin
        if not GuiAllowed then
            Error(GuilAllowedErr);

        if PayLoad.Contains(DocumentTypeTok) then
            if PayLoad.Get(DocumentTypeTok, JTOken) then
                Message(JToken.AsValue().AsText());

        if not PayLoad.Contains(PrinternameLbl) then
            exit;

        PayLoad.Get(PrinternameLbl, JToken);
        Printername := JToken.AsValue().AsText();

        Message(LocalPrinterMgt.PrintFileToLocalPrinter(Printername, DocumentStream));
        ReturnValue := true;
    end;
}
