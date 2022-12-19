/// <summary>
/// Codeunit PTEBCFTPMgt (ID 50134).
/// </summary>
codeunit 50134 PTEBCFTPMgt
{
    var
        ServiceBusRelay: codeunit AzureServiceBusRelay;
        FtpPluginNameTok: Label '/ftp/V1.0', Locked = true;
        ConnectFtpTok: Label '/ConnectFtp?jsonsettings=%1', Locked = true, Comment = '%1 - JSettings';
        GetFileListFtpTok: Label '/GetFilesFtp?jsonsettings=%1&foldername=%2', Locked = true, Comment = '%1 - JSettings, %2 - Foldername';
        DownloadFileFtpTok: Label '/DownloadFileFtp?jsonsettings=%1&filename=%2', Locked = true, Comment = '%1 - JSettings, %2 - Filename';
        DownloadFolderFtpTok: Label '/DownloadFolderFtp?jsonsettings=%1&foldername=%2', Locked = true, Comment = '%1 - JSettings, %2 - Foldername';
        CombineTxt: Label '%1%2', Comment = '%1 - String1, %2 - String2';


    /// <summary>
    /// Connect.
    /// </summary>
    /// <param name="JSettings">JsonObject.</param>
    /// <returns>Return variable Result of type Text.</returns>
    internal procedure Connect(JSettings: JsonObject) Result: Text
    var
        SettingsString: Text;
    begin
        JSettings.WriteTo(SettingsString);
        ServiceBusRelay.Get(BuildRequest(ConnectFtpTok, SettingsString), Result);
        Result := GetResult(Result);
    end;

    /// <summary>
    /// GetFilesList.
    /// </summary>
    /// <param name="JSettings">JsonObject.</param>
    /// <param name="FolderName">Text.</param>
    /// <returns>Return variable Result of type Text.</returns>
    internal procedure GetFilesList(JSettings: JsonObject; FolderName: Text) Result: Text
    var
        SettingsString: Text;
    begin
        JSettings.WriteTo(SettingsString);
        ServiceBusRelay.Get(BuildRequest(GetFileListFtpTok, SettingsString, Foldername), Result);
        Result := GetResult(Result);
    end;

    /// <summary>
    /// DownLoadFile.
    /// </summary>
    /// <param name="JSettings">JsonObject.</param>
    /// <param name="FileName">Text.</param>
    /// <returns>Return variable Result of type Text.</returns>
    internal procedure DownLoadFile(JSettings: JsonObject; FileName: Text) Result: Text
    var
        SettingsString: Text;
    begin
        JSettings.WriteTo(SettingsString);
        ServiceBusRelay.Get(BuildRequest(DownloadFileFtpTok, SettingsString, FileName), Result);
        Result := GetResult(Result);
    end;

    /// <summary>
    /// DownLoadFolder.
    /// </summary>
    /// <param name="JSettings">JsonObject.</param>
    /// <param name="FolderName">Text.</param>
    /// <returns>Return variable Result of type Text.</returns>
    internal procedure DownLoadFolder(JSettings: JsonObject; FolderName: Text) Result: Text
    var
        SettingsString: Text;
    begin
        JSettings.WriteTo(SettingsString);
        ServiceBusRelay.Get(BuildRequest(DownloadFolderFtpTok, SettingsString, FolderName), Result);
        Result := GetResult(Result);
    end;

    local procedure BuildRequest(Method: Text; SettingsString: Text): Text
    begin
        exit(StrSubStno(CombineTxt, FtpPluginNameTok, StrSubstNo(Method, SettingsString)));
    end;

    local procedure BuildRequest(Method: Text; SettingsString: Text; Foldername: Text): Text
    begin
        exit(StrSubStno(CombineTxt, FtpPluginNameTok, StrSubstNo(Method, SettingsString, Foldername)));
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
