/// <summary>
/// Codeunit PTEBCLocalPrinterSetupMgt (ID 50128).
/// </summary>
codeunit 50128 PTEBCLocalPrinterSetupMgt
{

    /// <summary>
    /// GetPrinterSettings.
    /// </summary>
    /// <param name="Printername">Text.</param>
    /// <returns>Return variable ReturnValue of type JsonObject.</returns>
    internal procedure GetPrinterSettingsJson(Printername: Text) ReturnValue: JsonObject
    var
        LocalPrinterSetting: Record PTEBCLocalPrinterSetting;
    begin
        if not LocalPrinterSetting.Get(CopyStr(UserId(), 1, MaxStrLen(LocalPrinterSetting.UserID)), CopyStr(Printername, 1, MaxStrLen(LocalPrinterSetting.PrinterID))) then
            AddLocalPrinterSetting(Printername, LocalPrinterSetting);

        exit(LocalPrinterSetting.ToJson());
    end;

    /// <summary>
    /// AddLocalPrinterSetting.
    /// </summary>
    /// <param name="PrinterID">Text.</param>
    /// <param name="LocalPrinterSettings">VAR Record PTEBCLocalPrinterSetting.</param>
    internal procedure AddLocalPrinterSetting(PrinterID: Text; var LocalPrinterSettings: Record PTEBCLocalPrinterSetting)
    begin
        LocalPrinterSettings.Init();
        LocalPrinterSettings.UserID := CopyStr(UserId, 1, MaxStrLen(LocalPrinterSettings.UserID));
        LocalPrinterSettings.PrinterID := CopyStr(PrinterID, 1, MaxStrLen(LocalPrinterSettings.PrinterID));
        LocalPrinterSettings.Insert(true);
    end;
}
