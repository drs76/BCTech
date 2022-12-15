/// <summary>
/// Page PTEFtpFiles (ID 50125).
/// </summary>
page 50125 PTEFtpFiles
{
    Caption = 'PTEFtpFiles';
    PageType = ListPart;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(FolderName; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the file/folder name';
                    Caption = 'Name';
                    Editable = false;
                    DrillDown = true;
                    StyleExpr = StyleTxt;

                    trigger OnDrillDown()
                    begin
                        OnDrillDownName();
                    end;
                }

                field(Size; Rec.Value)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the file size';
                    Caption = 'Size';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DownloadFile)
            {
                Caption = 'Download';
                ToolTip = 'Download selected file(s)';
                ApplicationArea = All;
                Image = Download;

                trigger OnAction()
                begin
                    DownloadFiles();
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetStyle();
    end;

    trigger OnAfterGetRecord()
    begin
        SetStyle();
    end;


    var
        JSettings: JsonObject;
        [InDataSet]
        CurrentFolder: Text;
        RootFolder: Text;
        StyleTxt: Text;
        NameLbl: Label 'FullName';
        SizeLbl: Label 'Size';
        UpLevelLbl: Label '..';
        ZeroSizeLbl: Label '0';
        ItemsLbl: Label 'Items';


    /// <summary>
    /// SetSettings.
    /// </summary>
    /// <param name="NewJSettings">JsonObject.</param>
    procedure SetSettings(NewJSettings: JsonObject)
    var
        JToken: JsonToken;
        RootFolderLbl: Label 'RootFolder';
    begin
        JSettings := NewJSettings;
        if NewJSettings.Get(RootFolderLbl, JToken) then
            CurrentFolder := JToken.AsValue().AsText();
    end;

    /// <summary>
    /// SetSource.
    /// </summary>
    /// <param name="NewSource">JsonArray.</param>
    internal procedure SetSource(NewSource: JsonArray)
    var
        JToken: JsonToken;
    begin
        Rec.DeleteAll(true);

        InsertNameValue(UpLevelLbl, 0);
        foreach JToken in NewSource do
            InsertNameValue(JToken, NewSource.IndexOf(JToken) + 1);

        CurrPage.Update(false);
    end;

    /// <summary>
    /// DownloadFolder.
    /// </summary>
    internal procedure DownloadFolder()
    var
        BCFtpMgt: Codeunit PTEBCFTPManagement;
        Compress: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        Base64: Codeunit "Base64 Convert";
        WriteStream: OutStream;
        ReadStream: InStream;
        Response: Text;
        Filename: Text;
    begin
        if (Rec.Value <> ZeroSizeLbl) or (Rec.Name = UpLevelLbl) then
            exit;

        Response := BCFtpMgt.DownLoadFolder(JSettings, Rec.Name);
        TempBlob.CreateOutStream(WriteStream);
        Base64.FromBase64(Response, WriteStream);
        TempBlob.CreateInStream(ReadStream);

        Filename := Rec.Name + '.zip';
        DownloadFromStream(ReadStream, 'Zippity Zip', '', '', Filename);
    end;

    /// <summary>
    /// DownloadFiles.
    /// </summary>
    internal procedure DownloadFiles()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        BCFtpClientMgt: Codeunit PTEBCFtpClientMgt;
    begin
        if (Rec.Value = ZeroSizeLbl) or (Rec.Name = UpLevelLbl) then
            exit;

        TempNameValueBuffer.Copy(Rec, true);

        CurrPage.SetSelectionFilter(TempNameValueBuffer);
        BCFtpClientMgt.DownloadFiles(JSettings, TempNameValueBuffer);
    end;

    local procedure InsertNameValue(JToken: JsonToken; Id: Integer)
    var
        JObject: JsonObject;
        ZeroLbl: Label '0';
    begin
        Rec.Init();
        Rec.ID := Id;

        JObject := JToken.AsObject();

        if JObject.Get(NameLbl, JToken) then
            Rec.Name := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(Rec.Name));

        Rec.Value := ZeroLbl;
        if JObject.Get(SizeLbl, JToken) then
            if JToken.AsValue().AsInteger() > 0 then
                Rec.Value := Format(JToken.AsValue().AsInteger());

        Rec.Insert(false);
    end;

    local procedure InsertNameValue(Name: Text; Id: Integer)
    begin
        Rec.Init();
        Rec.ID := Id;
        Rec.Name := CopyStr(Name, 1, MaxStrLen(Rec.Name));
        Rec.Insert(false);
    end;

    local procedure NavigateUp()
    var
        TempRegExMatches: Record Matches temporary;
        BCFtp: Codeunit PTEBCFTPManagement;
        RegExp: Codeunit Regex;
        JToken: JsonToken;
        RegExpLbl: Label '^(.*[\\\/])';
    begin
        if CurrentFolder <> RootFolder then begin
            RegExp.Match(CurrentFolder, RegExpLbl, TempRegExMatches);
            if TempRegExMatches.IsEmpty() then
                exit;

            TempRegExMatches.FindFirst();
            CurrentFolder := TempRegExMatches.ReadValue();
        end;
        if CurrentFolder.EndsWith('/') or CurrentFolder.EndsWith('\') then
            CurrentFolder := CopyStr(CurrentFolder, 1, StrLen(CurrentFolder) - 1);
        JToken.ReadFrom(BCFtp.GetFilesList(JSettings, CurrentFolder));
        if not JToken.AsObject().Get(ItemsLbl, JToken) then
            exit;

        SetSource(JToken.AsArray());
    end;

    local procedure NavigateDown()
    var
        BCFtp: Codeunit PTEBCFTPManagement;
        JToken: JsonToken;
    begin
        JToken.ReadFrom(BCFtp.GetFilesList(JSettings, Rec.Name));
        if not JToken.AsObject().Get(ItemsLbl, JToken) then
            exit;

        CurrentFolder := Rec.Name;
        SetSource(JToken.AsArray());
    end;

    local procedure SetStyle()
    var
        StandardAccentLbl: Label 'StandardAccent';
    begin
        Clear(StyleTxt);
        if Rec.Value = ZeroSizeLbl then
            StyleTxt := StandardAccentLbl;
    end;

    local procedure OnDrillDownName()
    begin
        if (Rec.Value <> ZeroSizeLbl) and (Rec.Name <> UpLevelLbl) then
            exit;

        if Rec.Name = UpLevelLbl then
            NavigateUp()
        else
            NavigateDown();
    end;

}