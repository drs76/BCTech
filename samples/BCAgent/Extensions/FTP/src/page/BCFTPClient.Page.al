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
    PromotedActionCategories = 'New,,,Hosts,Ftp';

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
                        OnValidateHost();
                    end;
                }

                field(FtpFolder; FtpFolder)
                {
                    Caption = 'FTP Folder';
                    ToolTip = 'Specifies the FTP Host Folder to use.';
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

            part(BCFtpFiles; PTEBCFtpFiles)
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
            group(Ftp)
            {
                Caption = 'Ftp';
                action(Connect)
                {
                    ApplicationArea = All;
                    Caption = 'Connect';
                    ToolTip = 'Connect to the selected FTP Host.';
                    Image = Continue;
                    Promoted = true;
                    PromotedOnly = true;
                    PromotedCategory = Category5;

                    trigger OnAction()
                    var
                        BCFtpMgt: Codeunit PTEBCFTPManagement;
                    begin
                        FtpResponse := BCFtpMgt.Connect(JSettings);
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
                    PromotedCategory = Category5;

                    trigger OnAction()
                    begin
                        GetFilesList();
                    end;
                }

                action(DownloadFile)
                {
                    Caption = 'Download File';
                    ToolTip = 'Download selected file(s)';
                    ApplicationArea = All;
                    Image = Download;
                    Promoted = true;
                    PromotedOnly = true;
                    PromotedCategory = Category5;

                    trigger OnAction()
                    begin
                        CurrPage.BCFtpFiles.Page.DownloadFiles();
                    end;
                }

                action(DownloadDirectory)
                {
                    Caption = 'Download Folder';
                    ToolTip = 'Download selected folder and its contents.';
                    ApplicationArea = All;
                    Image = Download;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;

                    trigger OnAction()
                    begin
                        CurrPage.BCFtpFiles.Page.DownloadFolder();
                    end;
                }
            }
            group(Hosts)
            {
                Caption = 'Hosts';
                action(HostList)
                {
                    Caption = 'Hosts';
                    ToolTip = 'Maintain Ftp Hosts.';
                    ApplicationArea = All;
                    Image = Web;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;

                    RunObject = Page PTEBCFTPHosts;
                }
            }

            action(Files)
            {
                Caption = 'Downloaded Files';
                ToolTip = 'View files downloaded by the ftp client.';
                ApplicationArea = All;
                Image = Documents;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                RunObject = Page PTEBCFtpDownloadedFiles;
            }
        }
    }

    var
        BCFtpClientMgt: Codeunit PTEBCFtpClientMgt;
        JSettings: JsonObject;
        FtpHost: Text;
        FtpResponse: Text;
        FtpFolder: Text;


    local procedure UpdateSettings()
    begin
        BCFtpClientMgt.UpdateClientPageSettings(JSettings, FtpFolder);
        CurrPage.BCFtpFiles.Page.SetSettings(JSettings);
    end;

    local procedure OnValidateHost()
    var
        BCFtpHost: Record PTEBCFtpHost;
        FtpHostMgt: Codeunit PTEBCFtpHostMgt;
    begin
        Clear(JSettings);
        Clear(FtpFolder);
        if BCFtpHost.Get(FtpHost) then begin
            FtpHostMgt.GetHostDetails(FtpHost, JSettings);
            FtpFolder := BCFtpHost.RootFolder;
            UpdateSettings();
        end;
        CurrPage.Update(false);
    end;

    local procedure GetFilesList()
    var
        Source: JsonArray;
    begin
        Source := BCFtpClientMgt.GetFtpFolderFilesList(JSettings, FtpFolder);
        CurrPage.BCFtpFiles.Page.SetSource(Source);
        CurrPage.Update(false);
    end;

}