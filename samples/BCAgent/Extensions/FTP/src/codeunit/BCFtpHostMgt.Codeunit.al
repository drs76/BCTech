/// <summary>
/// Codeunit PTEBCFtpHostMgt (ID 50135).
/// </summary>
codeunit 50135 PTEBCFtpHostMgt
{
    var
        HostnameLbl: Label 'hostName';
        UsernameLbl: Label 'userName';
        PasswdLbl: Label 'passwd';
        SSLCertLbl: Label 'sslCert';


    /// <summary>
    /// GetHostDetails.
    /// </summary>
    /// <param name="FtpName">Text.</param>
    /// <param name="Host">Text.</param>
    /// <param name="Usr">Text.</param>
    /// <param name="Pwd">Text.</param>
    /// <param name="SslCert">Text.</param>
    internal procedure UpdateHostDetails(FtpName: Text; Host: Text; Usr: Text; Pwd: Text; SslCert: Text)
    var
        JObject: JsonObject;
    begin
        if StrLen(FtpName) = 0 then
            exit;

        UpdateObject(JObject, HostnameLbl, Host);
        UpdateObject(JObject, UsernameLbl, Usr);
        UpdateObject(JObject, PasswdLbl, Pwd);
        UpdateObject(JObject, SSLCertLbl, SslCert);

        SaveInIsolatedStorage(FtpName, JObject);
    end;

    /// <summary>
    /// GetHostDetails.
    /// </summary>
    /// <param name="FtpName">Text.</param>
    /// <param name="Host">VAR Text.</param>
    /// <param name="Usr">VAR Text.</param>
    /// <param name="Pwd">VAR Text.</param>
    /// <param name="SslCert">VAR Text.</param>
    internal procedure GetHostDetails(FtpName: Text; var Host: Text; var Usr: Text; var Pwd: Text; var SslCert: Text)
    var
        JObject: JsonObject;
        JToken: JsonToken;
        KeyValue: Text;
    begin
        if not IsolatedStorage.Contains(FtpName, DataScope::Company) then
            exit;

        IsolatedStorage.Get(FtpName, DataScope::Company, KeyValue);
        JObject.ReadFrom(KeyValue);

        if JObject.Get(HostnameLbl, JToken) then
            Host := JToken.AsValue().AsText();

        if JObject.Get(UsernameLbl, JToken) then
            Usr := JToken.AsValue().AsText();

        if JObject.Get(PasswdLbl, JToken) then
            Pwd := JToken.AsValue().AsText();

        if JObject.Get(SSLCertLbl, JToken) then
            SslCert := JToken.AsValue().AsText();
    end;

    /// <summary>
    /// GetHostDetails.
    /// </summary>
    /// <param name="FtpName">Text.</param>
    /// <param name="JObject">VAR JsonObject.</param>
    internal procedure GetHostDetails(FtpName: Text; var JObject: JsonObject)
    var
        KeyValue: Text;
    begin
        if not IsolatedStorage.Contains(FtpName, DataScope::Company) then
            exit;

        IsolatedStorage.Get(FtpName, DataScope::Company, KeyValue);
        JObject.ReadFrom(KeyValue);
    end;

    /// <summary>
    /// DeleteHostDetails.
    /// </summary>
    /// <param name="FtpName">Text.</param>
    internal procedure DeleteHostDetails(FtpName: Text)
    begin
        if IsolatedStorage.Contains(FtpName, DataScope::Company) then
            IsolatedStorage.Delete(FtpName, DataScope::Company);
    end;

    /// <summary>
    /// GetHostName.
    /// </summary>
    /// <param name="JSettings">JsonObject.</param>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetHostCode(JSettings: JsonObject): Text
    var
        JToken: JsonToken;
        HostCodeLbl: Label 'hostCode';
    begin
        if JSettings.Contains(HostCodeLbl) then
            JSettings.Get(HostCodeLbl, JToken)
        else
            if JSettings.Contains(HostnameLbl) then
                JSettings.Get(HostnameLbl, JToken)
            else
                exit;

        exit(JToken.AsValue().AsText());
    end;


    local procedure UpdateObject(var JObject: JsonObject; Name: Text; Value: Variant)
    var
        JObjectToStore: JsonObject;
    begin
        if Value.IsText() then
            UpdateObject(JObject, Name, Format(Value));

        if Value.IsJsonObject() then begin
            JObjectToStore := Value;
            UpdateObject(JObject, name, JObjectToStore);
        end;
    end;

    internal procedure UpdateSslCert(FtpName: Text; Host: Text; Usr: Text; Pwd: Text)
    var
        JObject: JsonObject;
    begin
        UpdateObject(JObject, HostnameLbl, Host);
        UpdateObject(JObject, UsernameLbl, Usr);
        UpdateObject(JObject, PasswdLbl, Pwd);

        SaveInIsolatedStorage(FtpName, JObject);
    end;

    local procedure UpdateObject(var JObject: JsonObject; Name: Text; Value: Text)
    var
    begin
        if JObject.Contains(Name) then
            JObject.Replace(Name, Value)
        else
            JObject.Add(Name, Value);
    end;

    local procedure SaveInIsolatedStorage(FtpName: Text; JObject: JsonObject)
    var
        KeyValue: Text;
    begin
        JObject.WriteTo(KeyValue);
        IsolatedStorage.Set(FtpName, KeyValue, DataScope::Company);
    end;
}
