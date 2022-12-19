/// <summary>
/// Codeunit PTEBCLocalPrinterMgt (ID 50125).
/// </summary>
codeunit 50125 PTEBCLocalPrinterMgt
{
    var
        ServiceBusRelay: codeunit AzureServiceBusRelay;
        FtpPluginNameTok: Label '/localPrinters/V1.0', Locked = true;
        GetLocalPrintersTok: Label '/GetLocalPrintersList', Locked = true;
        CombineTxt: Label '%1%2', Comment = '%1 - String1, %2 - String2';


    /// <summary>
    /// GetLocalPrinters.
    /// </summary>
    /// <returns>Return variable Result of type Text.</returns>
    internal procedure GetLocalPrinters() Result: Text
    var
        SettingsString: Text;
    begin
        ServiceBusRelay.Get(BuildRequest(GetLocalPrintersTok, SettingsString), Result);
        Result := GetResult(Result);
    end;

    local procedure BuildRequest(Method: Text; SettingsString: Text): Text
    begin
        exit(StrSubStno(CombineTxt, FtpPluginNameTok, StrSubstNo(Method, SettingsString)));
    end;

    local procedure GetResult(JsonResult: Text) Result: Text
    var
        JObject: JsonObject;
        JToken: JsonToken;
        ResultValueLbl: Label 'returnValue';
        ErrorMessageLbl: Label 'errorMessage';
    begin
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
