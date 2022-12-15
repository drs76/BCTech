/// <summary>
/// Codeunit BCFtpClientMgt (ID 50136).
/// </summary>

codeunit 50136 PTEBCFtpClientMgt
{

    var
        ProgressWindow: Dialog;
        FailuresMsg: Label 'Failed to download the folowing file(s).\%1', Comment = '%1 = List of files failed to download.';
        ProgressMsg: Label 'Filename: #1############################\Progress: #2############################', Comment = '#1 = Filename, #2=Progress Message.';
        DownloadLbl: Label 'Downloading..';
        ZeroSizeLbl: Label '0';
        UpLevelLbl: Label '..';
        ItemsLbl: Label 'Items';


    /// <summary>
    /// DownloadFiles.
    /// </summary>
    /// <param name="JSettings">JsonObject.</param>
    /// <param name="TempNameValueBuffer">Temporary VAR Record "Name/Value Buffer".</param>
    internal procedure DownloadFiles(JSettings: JsonObject; var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    var
        TempBlob: Codeunit "Temp Blob";
        FailedTB: TextBuilder;
    begin
        if not TempNameValueBuffer.FindSet() then
            exit;

        if GuiAllowed then
            ProgressWindow.Open(ProgressMsg);

        repeat
            if GuiAllowed then begin
                ProgressWindow.Update(1, TempNameValueBuffer.Name);
                ProgressWindow.Update(2, DownloadLbl);
            end;

            if DownloadFtpFile(JSettings, TempNameValueBuffer, TempBlob) then
                StoreDownloadFtpFile(JSettings, TempNameValueBuffer, TempBlob, false)
            else
                FailedTB.AppendLine(TempNameValueBuffer.Name);
        until TempNameValueBuffer.Next() = 0;

        if not GuiAllowed then
            exit;

        ProgressWindow.Close();
        if FailedTB.Length() > 0 then
            Message(StrSubstNo(FailuresMsg, FailedTB.ToText()));
    end;

    /// <summary>
    /// DownloadFolder.
    /// </summary>
    internal procedure DownloadFolder(JSettings: JsonObject; TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    var
        BCFtpMgt: Codeunit PTEBCFTPManagement;
        TempBlob: Codeunit "Temp Blob";
        Base64: Codeunit "Base64 Convert";
        WriteStream: OutStream;
        ReadStream: InStream;
        Response: Text;
        Filename: Text;
        NewZipNameLbl: Label '%1.zip', Comment = '%1 = Base filename';
    begin
        if (TempNameValueBuffer.Value <> ZeroSizeLbl) or (TempNameValueBuffer.Name = UpLevelLbl) then
            exit;

        Response := BCFtpMgt.DownLoadFolder(JSettings, TempNameValueBuffer.Name);

        TempBlob.CreateOutStream(WriteStream);
        Base64.FromBase64(Response, WriteStream);
        TempBlob.CreateInStream(ReadStream);

        Filename := StrSubStno(NewZipNameLbl, TempNameValueBuffer.Name);
        TempNameValueBuffer.Name := CopyStr(Filename, 1, MaxStrLen(TempNameValueBuffer.Name));

        StoreDownloadFtpFile(JSettings, TempNameValueBuffer, TempBlob, true);
    end;

    /// <summary>
    /// UpdateClientPageSettings.
    /// </summary>
    /// <param name="JSettings">VAR JsonObject.</param>
    /// <param name="FtpFolder">Text.</param>
    internal procedure UpdateClientPageSettings(var JSettings: JsonObject; FtpFolder: Text)
    var
        RootFolderLbl: Label 'rootFolder';
    begin
        if JSettings.Contains(RootFolderLbl) then
            JSettings.Replace(rootFolderLbl, FtpFolder)
        else
            JSettings.Add(rootFolderLbl, FtpFolder);
    end;

    /// <summary>
    /// GetFtpFolderFilesList.
    /// </summary>
    /// <param name="JSettings">JsonObject.</param>
    /// <param name="FtpFolder">Text.</param>
    /// <returns>Return variable ReturnValue of type JsonArray.</returns>
    internal procedure GetFtpFolderFilesList(JSettings: JsonObject; FtpFolder: Text) ReturnValue: JsonArray
    var
        BCFtpMgt: Codeunit PTEBCFTPManagement;
        JToken: JsonToken;
    begin
        JToken.ReadFrom(BCFtpMgt.GetFilesList(JSettings, FtpFolder));
        if not JToken.AsObject().Get(ItemsLbl, JToken) then
            exit;

        ReturnValue := JToken.AsArray();
    end;

    /// <summary>
    /// TextFromLastSlash.
    /// Get the text after the last / or \
    /// </summary>
    /// <param name="ReturnValue">VAR Text.</param>
    internal procedure TextFromLastSlash(var ReturnValue: Text)
    var
        TempRegExMatches: Record Matches temporary;
        RegExp: Codeunit Regex;
        RegExpLbl: Label '^(.*[\\\/])';
    begin
        RegExp.Match(ReturnValue, RegExpLbl, TempRegExMatches);
        if TempRegExMatches.IsEmpty() then
            exit;

        TempRegExMatches.FindFirst();
        ReturnValue := TempRegExMatches.ReadValue();
    end;

    local procedure DownloadFtpFile(var JSettings: JsonObject; var TempNameValueBuffer: Record "Name/Value Buffer" temporary; var TempBlob: Codeunit "Temp Blob") ReturnValue: Boolean
    var
        BCFtpMgt: Codeunit PTEBCFTPManagement;
        Base64Convert: Codeunit "Base64 Convert";
        WriteStream: OutStream;
        FileContent: Text;
    begin
        FileContent := BCFtpMgt.DownLoadFile(JSettings, TempNameValueBuffer.Name);
        if StrLen(FileContent) = 0 then
            exit;

        TempBlob.CreateOutStream(WriteStream, TextEncoding::UTF8);
        WriteStream.WriteText(Base64Convert.FromBase64(FileContent));

        ReturnValue := true;
    end;

    /// <summary>
    /// StoreDownloadFtpFile.
    /// </summary>
    /// <param name="JSettings">JsonObject.</param>
    /// <param name="TempNameValueBuffer">Temporary Record "Name/Value Buffer".</param>
    /// <param name="TempBlob">VAR Codeunit "Temp Blob".</param>
    /// <param name="IsCompressed">Boolean.</param>
    local procedure StoreDownloadFtpFile(JSettings: JsonObject; TempNameValueBuffer: Record "Name/Value Buffer" temporary; var TempBlob: Codeunit "Temp Blob"; IsCompressed: Boolean)
    var
        FtpDownloadedFiles: Record PTEBCFTPDownloadedFile;
        StoringLbl: Label 'Storing to Ftp Downloads table..';
    begin
        if GuiAllowed then
            ProgressWindow.Update(2, StoringLbl);

        FtpDownloadedFiles.CreateEntry(JSettings, TempNameValueBuffer, TempBlob, IsCompressed);
    end;
}