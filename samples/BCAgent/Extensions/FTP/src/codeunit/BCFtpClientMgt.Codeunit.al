/// <summary>
/// Codeunit BCFtpClientMgt (ID 50136).
/// </summary>

codeunit 50136 PTEBCFtpClientMgt
{

    var
        ProgressWindow: Dialog;
        ProgressOpened: Boolean;
        FailuresMsg: Label 'Failed to download the folowing file(s).\%1', Comment = '%1 = List of files failed to download.';
        ProgressFilesMsg: Label 'Filename: #1############################\Progress: #2############################', Comment = '#1 = Filename, #2=Progress Message.';
        ProgressFolderMsg: Label 'Foldername #1############################\Progress: #2############################', Comment = '#1 = Filename, #2=Progress Message.';
        DownloadLbl: Label 'Downloading..';
        ZeroSizeLbl: Label '0';
        UpLevelLbl: Label '..';
        ItemsLbl: Label 'Items';
        NameLbl: Label 'FullName';
        SizeLbl: Label 'Size';


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

        OpenProgress(ProgressFilesMsg);

        repeat
            UpdateProgress(1, TempNameValueBuffer.Name);
            UpdateProgress(2, DownloadLbl);

            if DownloadFtpFile(JSettings, TempNameValueBuffer, TempBlob) then
                StoreDownloadFtpFile(JSettings, TempNameValueBuffer, TempBlob, false)
            else
                FailedTB.AppendLine(TempNameValueBuffer.Name);
        until TempNameValueBuffer.Next() = 0;

        if not GuiAllowed then
            exit;

        CloseProgress();
        if GuiAllowed then
            if FailedTB.Length() > 0 then
                Message(StrSubstNo(FailuresMsg, FailedTB.ToText()));
    end;

    /// <summary>
    /// DownloadFolder.
    /// </summary>
    internal procedure DownloadFolder(JSettings: JsonObject; TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    var
        BCFtpMgt: Codeunit PTEBCFTPMgt;
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

        OpenProgress(ProgressFolderMsg);
        UpdateProgress(1, TempNameValueBuffer.Name);
        UpdateProgress(2, DownloadLbl);

        Response := BCFtpMgt.DownLoadFolder(JSettings, TempNameValueBuffer.Name);

        TempBlob.CreateOutStream(WriteStream, TextEncoding::UTF8);
        Base64.FromBase64(Response, WriteStream);
        TempBlob.CreateInStream(ReadStream, TextEncoding::UTF8);

        Filename := StrSubStno(NewZipNameLbl, TempNameValueBuffer.Name);
        TempNameValueBuffer.Name := CopyStr(Filename, 1, MaxStrLen(TempNameValueBuffer.Name));

        StoreDownloadFtpFile(JSettings, TempNameValueBuffer, TempBlob, true);

        CloseProgress();
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
        BCFtpMgt: Codeunit PTEBCFTPMgt;
        JToken: JsonToken;
    begin
        JToken.ReadFrom(BCFtpMgt.GetFilesList(JSettings, FtpFolder));
        if not JToken.AsObject().Get(ItemsLbl, JToken) then
            exit;

        ReturnValue := JToken.AsArray();
    end;

    /// <summary>
    /// TextFromLastSlash.
    /// Get the text before (To) or after (From) the last / or \
    /// </summary>
    /// <param name="ReturnValue">VAR Text.</param>
    internal procedure TextToFromLastSlash(var ReturnValue: Text; From: Boolean)
    var
        TempRegExMatches: Record Matches temporary;
        RegExp: Codeunit Regex;
        RegExpToLbl: Label '^(.*[\\\/])';
        RegExpFromLbl: Label '([^\\\/]+$)';
    begin
        if From then
            RegExp.Match(ReturnValue, RegExpFromLbl, TempRegExMatches)
        else
            RegExp.Match(ReturnValue, RegExpToLbl, TempRegExMatches);
        if TempRegExMatches.IsEmpty() then
            exit;

        TempRegExMatches.FindFirst();
        ReturnValue := TempRegExMatches.ReadValue();
    end;

    /// <summary>
    /// SetFtpFilesSource.
    /// </summary>
    /// <param name="NewSource">JsonArray.</param>
    /// <param name="NewTempNameValue">Temporary VAR Record "Name/Value Buffer".</param>
    internal procedure SetFtpFilesSource(NewSource: JsonArray; var NewTempNameValue: Record "Name/Value Buffer" temporary)
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        JToken: JsonToken;
        SourceNotTempErr: Label 'Source must be temporary Name/Value Buffer';
    begin
        if not NewTempNameValue.IsTemporary() then
            Error(SourceNotTempErr);

        InsertNameValueForFtpFilesPage(TempNameValueBuffer, UpLevelLbl, 0);
        foreach JToken in NewSource do
            InsertNameValueForFtpFilesPage(TempNameValueBuffer, JToken, NewSource.IndexOf(JToken) + 1);

        NewTempNameValue.DeleteAll(true);
        NewTempNameValue.Copy(TempNameValueBuffer, true);
    end;

    /// <summary>
    /// FtpFilesNavigateUp.
    /// </summary>
    /// <param name="JSettings">JsonObject.</param>
    /// <param name="NewTempNameValue">Temporary VAR Record "Name/Value Buffer".</param>
    /// <param name="CurrentFolder">VAR Text.</param>
    /// <param name="RootFolder">Text.</param>
    internal procedure FtpFilesNavigateUp(JSettings: JsonObject; var NewTempNameValue: Record "Name/Value Buffer" temporary; var CurrentFolder: Text; RootFolder: Text)
    var
        BCFtp: Codeunit PTEBCFTPMgt;
        BCFtpClientMgt: Codeunit PTEBCFtpClientMgt;
        JToken: JsonToken;
        FwdSlashLbl: Label '/';
        BackSlashLbl: Label '\';
    begin
        if CurrentFolder <> RootFolder then
            BCFtpClientMgt.TextToFromLastSlash(CurrentFolder, false);

        if CurrentFolder.EndsWith(FwdSlashLbl) or CurrentFolder.EndsWith(BackSlashLbl) then
            CurrentFolder := CopyStr(CurrentFolder, 1, StrLen(CurrentFolder) - 1);

        JToken.ReadFrom(BCFtp.GetFilesList(JSettings, CurrentFolder));
        if not JToken.AsObject().Get(ItemsLbl, JToken) then
            exit;

        SetFtpFilesSource(JToken.AsArray(), NewTempNameValue);
        CheckForRootFolder(JSettings, NewTempNameValue, CurrentFolder, RootFolder);
    end;

    /// <summary>
    /// FtpFilesNavigateDown.
    /// </summary>
    /// <param name="JSettings">JsonObject.</param>
    /// <param name="NewTempNameValue">Temporary VAR Record "Name/Value Buffer".</param>
    /// <param name="CurrentFolder">VAR Text.</param>
    internal procedure FtpFilesNavigateDown(JSettings: JsonObject; var NewTempNameValue: Record "Name/Value Buffer" temporary; var CurrentFolder: Text)
    var
        BCFtp: Codeunit PTEBCFTPMgt;
        JToken: JsonToken;
        EmptyTxt: Label '';
    begin
        JToken.ReadFrom(BCFtp.GetFilesList(JSettings, NewTempNameValue.Name));
        if not JToken.AsObject().Get(ItemsLbl, JToken) then
            exit;

        CurrentFolder := NewTempNameValue.Name;
        SetFtpFilesSource(JToken.AsArray(), NewTempNameValue);
        CheckForRootFolder(JSettings, NewTempNameValue, CurrentFolder, EmptyTxt);
    end;

    /// <summary>
    /// CheckForRootFolder.
    /// </summary>
    /// <param name="JSettings">VAR JsonObject.</param>
    /// <param name="NewTempNameValue">Temporary VAR Record "Name/Value Buffer".</param>
    /// <param name="CurrentFolder">Text.</param>
    /// <param name="RootFolder">Text.</param>
    internal procedure CheckForRootFolder(var JSettings: JsonObject; var NewTempNameValue: Record "Name/Value Buffer" temporary; CurrentFolder: Text; RootFolder: Text)
    var
        JToken: JsonToken;
    begin
        if StrLen(RootFolder) = 0 then
            if JSettings.Contains('rootFolder') then
                if JSettings.Get('rootFolder', JToken) then
                    RootFolder := JToken.AsValue().AsText();

        if CurrentFolder <> RootFolder then
            exit;

        if NewTempNameValue.FindFirst() then
            NewTempNameValue.Delete(true);
    end;

    /// <summary>
    /// InsertNameValueForFtpFilesPage.
    /// /// /// </summary>
    /// <param name="JToken">JsonToken.</param>
    /// <param name="Id">Integer.</param>
    local procedure InsertNameValueForFtpFilesPage(var NewTempNameValue: Record "Name/Value Buffer" temporary; JToken: JsonToken; Id: Integer)
    var
        TempNameValue: Record "Name/Value Buffer" temporary;
        JObject: JsonObject;
        Size: BigInteger;
    begin
        TempNameValue.Copy(NewTempNameValue, true);

        TempNameValue.Init();
        TempNameValue.ID := Id;

        JObject := JToken.AsObject();

        if JObject.Get(NameLbl, JToken) then
            TempNameValue.Name := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TempNameValue.Name));

        TempNameValue.Value := ZeroSizeLbl;
        if JObject.Get(SizeLbl, JToken) then
            if Evaluate(Size, JToken.AsValue().AsText()) then
                if Size <> -1 then
                    TempNameValue.Value := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TempNameValue.Value));

        TempNameValue.Insert(false);
        NewTempNameValue.Copy(TempNameValue, true);
    end;

    /// <summary>
    /// InsertNameValueForFtpFilesPage.
    /// </summary>
    /// <param name="NewTempNameValue">Temporary VAR Record "Name/Value Buffer".</param>
    /// <param name="Name">Text.</param>
    /// <param name="Id">Integer.</param>
    local procedure InsertNameValueForFtpFilesPage(var NewTempNameValue: Record "Name/Value Buffer" temporary; Name: Text; Id: Integer)
    begin
        NewTempNameValue.Init();
        NewTempNameValue.ID := Id;
        NewTempNameValue.Name := CopyStr(Name, 1, MaxStrLen(NewTempNameValue.Name));
        NewTempNameValue.Insert(false);
    end;

    /// <summary>
    /// DownloadFtpFile.
    /// </summary>
    /// <param name="JSettings">VAR JsonObject.</param>
    /// <param name="TempNameValueBuffer">Temporary VAR Record "Name/Value Buffer".</param>
    /// <param name="TempBlob">VAR Codeunit "Temp Blob".</param>
    /// <returns>Return variable ReturnValue of type Boolean.</returns>
    local procedure DownloadFtpFile(var JSettings: JsonObject; var TempNameValueBuffer: Record "Name/Value Buffer" temporary; var TempBlob: Codeunit "Temp Blob") ReturnValue: Boolean
    var
        BCFtpMgt: Codeunit PTEBCFTPMgt;
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

    local procedure OpenProgress(Msg: Text)
    begin
        if not GuiAllowed then
            exit;

        if ProgressOpened then
            ProgressWindow.Close();

        ProgressWindow.Open(Msg);
        ProgressOpened := true;
    end;

    local procedure UpdateProgress(Item: Integer; Value: Variant)
    begin
        if not ProgressOpened then
            exit;

        ProgressWindow.Update(Item, Value);
    end;

    local procedure CloseProgress()
    begin
        if ProgressOpened then
            ProgressWindow.Close();

        Clear(ProgressOpened);
    end;

}