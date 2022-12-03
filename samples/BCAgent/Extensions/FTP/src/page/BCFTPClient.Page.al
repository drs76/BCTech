/// <summary>
/// Page PTEBCFTPClient (ID 50124).
/// </summary>
page 50124 PTEBCFTPClient
{
    Caption = 'FTP Client';
    AdditionalSearchTerms = 'BC FTP';
    UsageCategory = Administration;
    ApplicationArea = All;
    PageType = Document;
    InsertAllowed = false;
    ModifyAllowed = true;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Server)
            {
                Caption = 'Server';

                field(FtpHost; FtpHost)
                {
                    Caption = 'FTP Host';
                    ToolTip = 'Specifies the FTP Host to use.';
                    ApplicationArea = All;
                    TableRelation = PTEBCFtpHost;

                    trigger OnValidate()
                    begin
                        SetHost();
                    end;
                }


                field(FtpFolder; FtpFolder)
                {
                    Caption = 'FTP Folder';
                    ToolTip = 'Specifies the FTP Host Folder to use.';
                    ApplicationArea = All;
                }

                field(LocalFolder; LocalFolder)
                {
                    Caption = 'Local Folder';
                    ToolTip = 'Specifies the Local Folder to use.';
                    ApplicationArea = All;
                }
            }

            group(Response)
            {
                Caption = 'Response';

                field(FtpResponse; FtpResponse)
                {
                    ApplicationArea = All;
                    Caption = 'FTP Response';
                    ToolTip = 'Specifies the response from last Ftp command.';
                    MultiLine = true;
                }
            }

            part(BCFtpFiles; PTEFtpFiles)
            {
                Editable = false;
                ApplicationArea = All;
                Caption = 'Ftp File List';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Connect)
            {
                ApplicationArea = All;
                Caption = 'Connect';
                ToolTip = 'Connect to the selected FTP Host.';
                Image = Continue;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    FtpResponse := BCFtp.Connect(JSettings);
                    CurrPage.Update(false);
                end;
            }

            action(GetFileList)
            {
                ApplicationArea = All;
                Caption = 'File List';
                ToolTip = 'Get list of files on FTP server';
                Image = Continue;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    JToken: JsonToken;
                    Source: JsonArray;
                begin
                    FtpResponse := BCFtp.GetFilesList(JSettings, FtpFolder);
                    JToken.ReadFrom(FtpResponse);
                    if not JToken.AsObject().Get('items', JToken) then
                        exit;

                    Source := JToken.AsArray();
                    CurrPage.BCFtpFiles.Page.SetSource(Source);
                    CurrPage.Update(false);
                end;
            }
            action(DownloadFile)
            {
                Caption = 'Download';
                ToolTip = 'Download selected file(s)';
                ApplicationArea = All;
                Image = Download;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    CurrPage.BCFtpFiles.Page.DownloadFiles();
                end;
            }
        }
    }

    var
        BCFtp: Codeunit PTEBCFTP;
        JSettings: JsonObject;
        FtpHost: Text;
        FtpResponse: Text;
        FtpFolder: Text;
        LocalFolder: Text;
        RootFolderLbl: Label 'rootFolder';
        LocalFolderLbl: Label 'localFolder';


    local procedure UpdateSettings()
    begin
        if JSettings.Contains(RootFolderLbl) then
            JSettings.Replace(rootFolderLbl, FtpFolder)
        else
            JSettings.Add(rootFolderLbl, FtpFolder);

        if JSettings.Contains(LocalFolderLbl) then
            JSettings.Replace(LocalFolderLbl, LocalFolder)
        else
            JSettings.Add(LocalFolderLbl, LocalFolder);

        BCFTP.SettingsToVars(JSettings);
        CurrPage.BCFtpFiles.Page.SetSettings(JSettings);
    end;

    local procedure SetHost()
    var
        BCFtpHost: Record PTEBCFtpHost;
        FtpHostMgt: Codeunit PTEBCFtpHostMgt;
    begin
        Clear(JSettings);
        Clear(FtpFolder);
        Clear(LocalFolder);
        if BCFtpHost.Get(FtpHost) then begin
            FtpHostMgt.GetHostDetails(FtpHost, JSettings);
            FtpFolder := BCFtpHost.RootFolder;
            LocalFolder := BCFtpHost.LocalFolder;
            UpdateSettings();
        end;
        CurrPage.Update(false);
    end;
}