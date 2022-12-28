/// <summary>
/// Codeunit PTEBCLocalPrinterSubscriptions (ID 50126).
/// </summary>
codeunit 50126 PTEBCLocalPrinterSubscriptions
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Printer Setup", 'OnOpenPrinterSettings', '', true, false)]
    local procedure PrinterSetup_OnOpenPrinterSettings(PrinterID: Text; var IsHandled: Boolean)
    begin
        if not IsHandled then   // dont interupt any base app printers, we just want the local ones.
            IsHandled := LocalPrinterHelper.TryRunLocalPrinterSetup(PrinterID);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterDocumentPrintReady', '', true, false)]
    local procedure ReportManagement_OnAfterDocumentPrintReady(ObjectType: Option; ObjectID: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var Success: Boolean)
    begin
        Success := LocalPrinterHelper.TrySendToLocalPrinter(ObjectPayload, DocumentStream);
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterSetupPrinters', '', true, false)]
    local procedure ReportManagement_OnAfterSetupPrinters(var Printers: Dictionary of [Text[250], JsonObject])
    begin
        LocalPrinterHelper.AddLocalPrinters(Printers);
    end;


    var
        LocalPrinterHelper: Codeunit PTEBCLocalPrinterHelper;

}