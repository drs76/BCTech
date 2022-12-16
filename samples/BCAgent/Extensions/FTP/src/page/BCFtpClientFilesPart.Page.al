/// <summary>
/// Page PTEBCFtpClientFilesPart (ID 50125).
/// </summary>
page 50125 PTEBCFtpClientFilesPart
{
    Caption = 'Ftp Files';
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
                Scope = Repeater;

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
        BCFtpClientMgt: Codeunit PTEBCFtpClientMgt;
        JSettings: JsonObject;
        [InDataSet]
        CurrentFolder: Text;
        RootFolder: Text;
        StyleTxt: Text;
        ZeroSizeLbl: Label '0';
        UpLevelLbl: Label '..';


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
            RootFolder := JToken.AsValue().AsText();

        CurrentFolder := RootFolder;
    end;

    /// <summary>
    /// SetSource.
    /// </summary>
    /// <param name="NewSource">JsonArray.</param>
    internal procedure SetSource(NewSource: JsonArray)
    begin
        Rec.Reset();
        BCFtpClientMgt.SetFtpFilesSource(NewSource, Rec);
        CurrPage.Update(false);
    end;

    /// <summary>
    /// DownloadFolder.
    /// </summary>
    internal procedure DownloadFolder()
    begin
        BCFtpClientMgt.DownloadFolder(JSettings, Rec);
    end;

    /// <summary>
    /// DownloadFiles.
    /// </summary>
    internal procedure DownloadFiles()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
    begin
        if (Rec.Value = ZeroSizeLbl) or (Rec.Name = UpLevelLbl) then
            exit;

        TempNameValueBuffer.Copy(Rec, true);

        CurrPage.SetSelectionFilter(TempNameValueBuffer);
        BCFtpClientMgt.DownloadFiles(JSettings, TempNameValueBuffer);
    end;

    /// <summary>
    /// NavigateUp.
    /// Move up folder on ftp server.
    /// </summary>
    local procedure NavigateUp()
    begin
        Rec.Reset();
        BCFtpClientMgt.FtpFilesNavigateUp(JSettings, Rec, CurrentFolder, RootFolder);
        CurrPage.Update(false);
    end;

    /// <summary>
    /// NavigateDown.
    /// Move down folder on ftp server.
    /// </summary>
    local procedure NavigateDown()
    begin
        Rec.Reset();
        BCFtpClientMgt.FtpFilesNavigateDown(JSettings, Rec, CurrentFolder);
        CurrPage.Update(false);
    end;

    local procedure SetStyle()
    var
        StrongLbl: Label 'Strong';
    begin
        if Rec.Value = ZeroSizeLbl then
            StyleTxt := StrongLbl;
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