/// <summary>
/// Page BCFtpHostCard (ID 50135).
/// </summary>
page 50135 PTEBCFtpHostCard
{
    Caption = 'Ftp Host Card';
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
                    ToolTip = 'Specifies the Name of the FTP Host';
                    ApplicationArea = All;
                    NotBlank = true;
                }

                field(FtpHost; FtpHost)
                {
                    Caption = 'FTP Host';
                    ToolTip = 'Specifies the address of the FTP Host';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        FtpHostMgt.UpdateHostDetails(Rec.Name, FtpHost, FtpUser, FtpPasswd);
                    end;
                }

                field(FtpUser; FtpUser)
                {
                    Caption = 'FTP User';
                    ToolTip = 'Specifies the FTP Username.';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        FtpHostMgt.UpdateHostDetails(Rec.Name, FtpHost, FtpUser, FtpPasswd);
                    end;
                }

                field(FtpPasswd; FtpPasswd)
                {
                    Caption = 'FTP Passwd';
                    ToolTip = 'Specifies the FTP Password.';
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
                    ToolTip = 'Specifies the default FTP Host Root Folder';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        FtpHostMgt.UpdateHostDetails(Rec.Name, FtpHost, FtpUser, FtpPasswd);
                    end;
                }

                field(LocalFolder; Rec.LocalFolder)
                {
                    Caption = 'FTP Local Folder';
                    ToolTip = 'Specifies the default Local Folder';
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
