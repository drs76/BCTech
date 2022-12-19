/// <summary>
/// Page PTEBCFTPClient (ID 50136).
/// </summary>
page 50136 PTEBCFTPClient
{
    Caption = 'FTP Client';
    AdditionalSearchTerms = 'BC FTP';
    UsageCategory = Administration;
    ApplicationArea = All;
    PageType = Document;
    InsertAllowed = false;
    ModifyAllowed = true;
    DeleteAllowed = false;
    PromotedActionCategories = 'New,Ftp';

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
                    ToolTip = 'Specifies the FTP Host to connect with.';
                    ApplicationArea = All;
                    TableRelation = PTEBCFtpHost where(Enabled = const(true));

                    trigger OnValidate()
                    begin
                        OnValidateHost();
                    end;
                }

                field(FtpFolder; FtpFolder)
                {
                    Caption = 'FTP Folder';
                    ToolTip = 'Specifies the FTP Host Folder as the root folder.';
                    ApplicationArea = All;
                }
            }

            part(BCFtpFiles; PTEBCFtpClientFilesPart)
            {
                Editable = false;
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Hosts)
            {
                Caption = 'Hosts';
                action(HostList)
                {
                    Caption = 'Hosts';
                    ToolTip = 'Maintain Ftp Host entries.';
                    ApplicationArea = All;
                    Image = Web;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;

                    RunObject = Page PTEBCFTPHosts;
                }
            }

            group(Ftp)
            {
                Caption = 'Ftp';
                action(Connect)
                {
                    ApplicationArea = All;
                    Caption = 'Connect';
                    ToolTip = 'Connect to the selected FTP Host and list root folder.';
                    Image = Continue;
                    Promoted = true;
                    PromotedOnly = true;
                    PromotedCategory = Process;

                    trigger OnAction()
                    begin
                        if StrLen(FtpHost) = 0 then
                            exit;

                        GetFilesList();
                    end;
                }

                group(Download)
                {
                    Caption = 'Download';
                    action(DownloadFile)
                    {
                        Caption = 'Download File';
                        ToolTip = 'Download selected file(s).';
                        ApplicationArea = All;
                        Image = Download;
                        Promoted = true;
                        PromotedOnly = true;
                        PromotedCategory = Process;

                        trigger OnAction()
                        begin
                            if StrLen(FtpHost) = 0 then
                                exit;

                            CurrPage.BCFtpFiles.Page.DownloadFiles();
                        end;
                    }

                    action(DownloadDirectory)
                    {
                        Caption = 'Download Folder';
                        ToolTip = 'Download selected folder and its contents. The folder contents will be compressed into a single file.';
                        ApplicationArea = All;
                        Image = Download;
                        Promoted = true;
                        PromotedCategory = Process;
                        PromotedOnly = true;

                        trigger OnAction()
                        begin
                            if StrLen(FtpHost) = 0 then
                                exit;

                            CurrPage.BCFtpFiles.Page.DownloadFolder();
                        end;
                    }
                }
            }

            action(Files)
            {
                Caption = 'Downloaded Files';
                ToolTip = 'View files downloaded by the ftp client. View pre-filtered to current Ftp Host.';
                ApplicationArea = All;
                Image = Documents;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    DownloadedFiles: Record PTEBCFTPDownloadedFile;
                begin
                    DownloadedFiles.Reset();
                    DownloadedFiles.SetRange(FtpHost, FtpHost);
                    Page.RunModal(Page::PTEBCFtpDownloadedFiles, DownloadedFiles);
                end;
            }
        }
    }

    var
        BCFtpClientMgt: Codeunit PTEBCFtpClientMgt;
        JSettings: JsonObject;
        FtpHost: Text;
        FtpFolder: Text;


    local procedure UpdateSettings()
    var
        HostCodeLbl: Label 'hostCode';
    begin
        BCFtpClientMgt.UpdateClientPageSettings(JSettings, FtpFolder);
        if JSettings.Contains(HostCodeLbl) then
            JSettings.Replace(HostCodeLbl, FtpHost)
        else
            JSettings.Add(HostCodeLbl, FtpHost);

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