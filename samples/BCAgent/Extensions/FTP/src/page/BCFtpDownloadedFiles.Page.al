/// <summary>
/// Page PTEBCFtpDownloadedFiles (ID 50137).
/// </summary>
page 50137 PTEBCFtpDownloadedFiles
{
    ApplicationArea = All;
    Caption = 'BC Ftp Downloaded Files';
    PageType = List;
    SourceTable = PTEBCFTPDownloadedFile;
    UsageCategory = Administration;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {

                field(Compressed; Rec.Compressed)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Compressed field.';
                }

                field(EntryNo; Rec.EntryNo)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Entry No. field.';
                }

                field(FileContent; Rec.FileContent)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the File Content field.';
                }

                field(Filename; Rec.Filename)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Filename field.';
                }

                field(FtpHost; Rec.FtpHost)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Ftp Host field.';
                }

                field(Size; Rec.Size)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Size field.';
                }

                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the SystemCreatedAt field.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Download)
            {
                Caption = 'Download File';
                ToolTip = 'Download selected fileo(s).';
                ApplicationArea = All;
                Image = Download;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    Rec.DownloadFile();
                end;
            }
        }
    }
}
