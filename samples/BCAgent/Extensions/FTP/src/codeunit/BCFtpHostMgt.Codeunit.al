/// <summary>
/// Codeunit PTEBCFtpHostMgt (ID 50133).
/// </summary>
codeunit 50133 PTEBCFtpHostMgt
{
    var
        HostnameLbl: Label 'hostName';
        UsernameLbl: Label 'userName';
        PasswdLbl: Label 'passwd';


    /// <summary>
    /// GetHostDetails.
    /// </summary>
    /// <param name="FtpName">Text.</param>
    /// <param name="Host">VAR Text.</param>
    /// <param name="Usr">VAR Text.</param>
    /// <param name="Pwd">VAR Text.</param>
    procedure UpdateHostDetails(FtpName: Text; Host: Text; Usr: Text; Pwd: Text)
    var
        JObject: JsonObject;
    begin
        UpdateObject(JObject, HostnameLbl, Host);
        UpdateObject(JObject, UsernameLbl, Usr);
        UpdateObject(JObject, PasswdLbl, Pwd);

        SaveInIsolatedStorage(FtpName, JObject);
    end;

    /// <summary>
    /// GetHostDetails.
    /// </summary>
    /// <param name="FtpName">Text.</param>
    /// <param name="Host">VAR Text.</param>
    /// <param name="Usr">VAR Text.</param>
    /// <param name="Pwd">VAR Text.</param>
    procedure GetHostDetails(FtpName: Text; var Host: Text; var Usr: Text; var Pwd: Text)
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
    end;

    /// <summary>
    /// GetHostDetails.
    /// </summary>
    /// <param name="FtpName">Text.</param>
    /// <param name="JObject">VAR JsonObject.</param>
    procedure GetHostDetails(FtpName: Text; var JObject: JsonObject)
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
    procedure DeleteHostDetails(FtpName: Text)
    begin
        if IsolatedStorage.Contains(FtpName, DataScope::Company) then
            IsolatedStorage.Delete(FtpName, DataScope::Company);
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
