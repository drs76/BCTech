/// <summary>
/// Codeunit PTEBCLocalPrinterMgt (ID 50125).
/// </summary>
codeunit 50125 PTEBCLocalPrinterMgt
{
    var
        ServiceBusRelay: codeunit AzureServiceBusRelay;
        FtpPluginNameTok: Label '/localPrinters/V1.0', Locked = true;
        CheckForGhostScriptLbl: Label '/CheckForGhostScript', Locked = true;
        GetLocalPrintersTok: Label '/GetLocalPrintersList', Locked = true;
        PrintFileToLocalPrinterProcessTok: Label '/PrintFileToLocalPrinterProcess?body', Locked = true; // Body query is a placeholder for the reflection in .net
        PrintFileToLocalPrinterGSTok: Label '/PrintFileToLocalPrinterGS?body', Locked = true; // Body query is a placeholder for the reflection in .net
        PrintFileToLocalPrinterLPTok: Label '/PrintFileToLocalPrinterLP?body', Locked = true; // Body query is a placeholder for the reflection in .net
        CombineTxt: Label '%1%2', Comment = '%1 - String1, %2 - String2';

    /// <summary>
    /// CheckForGhostScript.
    /// </summary>
    /// <returns>Return variable Result of type Text.</returns>
    internal procedure CheckForGhostScript() Result: Text
    begin
        ServiceBusRelay.Get(BuildRequest(CheckForGhostScriptLbl), Result);
        Result := GetResult(Result);
    end;

    /// <summary>
    /// GetLocalPrinters.
    /// </summary>
    /// <returns>Return variable Result of type Text.</returns>
    internal procedure GetLocalPrinters() Result: Text
    begin
        ServiceBusRelay.Get(BuildRequest(GetLocalPrintersTok), Result);
        Result := GetResult(Result);
    end;

    /// <summary>
    /// PrintFileToLocalPrinter.
    /// </summary>
    /// <param name="Printername">Text.</param>
    /// <param name="DocumentStream">InStream.</param>
    /// <returns>Return variable Result of type Text.</returns>
    internal procedure PrintFileToLocalPrinter(Printername: Text; DocumentStream: InStream) Result: Text
    var
        Base64: Codeunit "Base64 Convert";
        JsonBody: JsonObject;
        JsonBodyContent: JsonObject;
        TextBody: Text;
        FileContentLbl: Label 'filecontent';
        PrinternameLbl: Label 'printername';
        BodyLbl: Label 'body';
    begin
        JsonBodyContent.Add(PrinternameLbl, Printername);
        JsonBodyContent.Add(FileContentLbl, Base64.ToBase64((DocumentStream)));
        JsonBody.Add(BodyLbl, JsonBodyContent);
        JsonBody.WriteTo(TextBody);

        ServiceBusRelay.Put(BuildRequest(PrintFileToLocalPrinterLPTok), TextBody, Result);
        // ServiceBusRelay.Put(BuildRequest(PrintFileToLocalPrinterGSTok), TextBody, Result);
        //ServiceBusRelay.Put(BuildRequest(PrintFileToLocalPrinterProcessTok), TextBody, Result);
        Result := GetResult(Result);
    end;

    local procedure BuildRequest(Method: Text): Text
    begin
        exit(StrSubStno(CombineTxt, FtpPluginNameTok, Method));
    end;

    local procedure BuildRequest(Method: Text; Parameter: Text): Text
    begin
        exit(StrSubStno(CombineTxt, FtpPluginNameTok, StrSubstNo(Method, Parameter)));
    end;

    local procedure BuildRequest(Method: Text; Parameter: Text; Parameter2: Text): Text
    begin
        exit(StrSubStno(CombineTxt, FtpPluginNameTok, StrSubstNo(Method, Parameter, Parameter2)));
    end;

    local procedure GetResult(JsonResult: Text) Result: Text
    var
        JObject: JsonObject;
        JToken: JsonToken;
        ResultValueLbl: Label 'returnValue';
        ErrorMessageLbl: Label 'errorMessage';
    begin
        if StrLen(JsonResult) = 0 then
            exit;

        JObject.ReadFrom(JsonResult);

        // check for error first
        if JObject.Get(ErrorMessageLbl, JToken) then
            if StrLen(JToken.AsValue().AsText()) > 0 then
                Error(JToken.AsValue().AsText());

        if not JObject.Get(ResultValueLbl, JToken) then
            exit;

        if JToken.IsArray() then
            JToken.WriteTo(Result);

        if JToken.IsObject() then
            JToken.WriteTo(Result);

        if JToken.IsObject() then
            JToken.WriteTo(Result);

        if JToken.IsValue() then
            exit(JToken.AsValue().AsText());
    end;
}
