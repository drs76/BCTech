/// <summary>
/// Codeunit BCFtpClientMgt (ID 50136).
/// </summary>

codeunit 50136 PTEBCFtpClientMgt
{

    /// <summary>
    /// DownloadFiles.
    /// </summary>
    /// <param name="JSettings">JsonObject.</param>
    /// <param name="TempNameValueBuffer">Temporary VAR Record "Name/Value Buffer".</param>
    internal procedure DownloadFiles(JSettings: JsonObject; var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    var
        BCFtpMgt: Codeunit PTEBCFTPManagement;
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        FailedTB: TextBuilder;
        ReadStream: InStream;
        WriteStream: OutStream;
        FileContent: Text;
        ToFileName: Text;
        FailuresMsg: Label 'Failed to donwload the folowing file(s).\%1', Comment = '%1 = List of files failed to download.';
        DownloadCaptionLbl: Label 'Download Ftp File';
    begin
        if TempNameValueBuffer.FindSet() then
            repeat
                FileContent := BCFtpMgt.DownLoadFile(JSettings, TempNameValueBuffer.Name);
                if StrLen(FileContent) > 0 then begin
                    ToFileName := TempNameValueBuffer.Name;
                    TempBlob.CreateOutStream(WriteStream, TextEncoding::UTF8);
                    WriteStream.WriteText(Base64Convert.FromBase64(FileContent));
                    TempBlob.CreateInStream(ReadStream, TextEncoding::UTF8);
                    DownloadFromStream(ReadStream, DownloadCaptionLbl, '', '', ToFileName);
                end else
                    FailedTB.AppendLine(TempNameValueBuffer.Name);
            until TempNameValueBuffer.Next() = 0;

        if FailedTB.Length() > 0 then
            Message(StrSubstNo(FailuresMsg, FailedTB.ToText()));
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
        ItemsLbl: Label 'Items';
    begin
        JToken.ReadFrom(BCFtpMgt.GetFilesList(JSettings, FtpFolder));
        if not JToken.AsObject().Get(ItemsLbl, JToken) then
            exit;

        ReturnValue := JToken.AsArray();
    end;

}