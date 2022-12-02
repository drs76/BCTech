/// <summary>
/// Page BCFtpHostCard (ID 50135).
/// </summary>
page 50135 PTEBCFtpHostCard
{
    Caption = 'BC Ftp Host Card';
    PageType = Card;
    SourceTable = PTEBCFtpHost;
    UsageCategory = None;

    layout
    {
        area(content)
        {
            group(General)
            {
                field(Name; Rec.Name)
                {
                    Caption = 'Name';
                    ApplicationArea = All;
                    NotBlank = true;
                }

                field(FtpHost; FtpHost)
                {
                    Caption = 'FTP Host';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        FtpHostMgt.UpdateHostDetails(Rec.Name, FtpHost, FtpUser, FtpPasswd);
                    end;
                }

                field(FtpUser; FtpUser)
                {
                    Caption = 'FTP User';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        FtpHostMgt.UpdateHostDetails(Rec.Name, FtpHost, FtpUser, FtpPasswd);
                    end;
                }

                field(FtpPasswd; FtpPasswd)
                {
                    Caption = 'FTP Passwd';
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;

                    trigger OnValidate()
                    begin
                        FtpHostMgt.UpdateHostDetails(Rec.Name, FtpHost, FtpUser, FtpPasswd);
                    end;
                }

                field(RootFolder; Rec.RootFolder)
                {
                    Caption = 'FTP Root Folder';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        FtpHostMgt.UpdateHostDetails(Rec.Name, FtpHost, FtpUser, FtpPasswd);
                    end;
                }

                field(LocalFolder; Rec.LocalFolder)
                {
                    Caption = 'FTP Local Folder';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        FtpHostMgt.UpdateHostDetails(Rec.Name, FtpHost, FtpUser, FtpPasswd);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin

        FtpHostMgt.GetHostDetails(Rec.Name, FtpHost, FtpUser, FtpPasswd);
    end;

    var
        FtpHostMgt: Codeunit PTEBCFtpHostMgt;
        FtpHost: Text;
        FtpUser: Text;
        FtpPasswd: Text;
}
