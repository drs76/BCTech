/// <summary>
/// Page PTEBCFTPHosts (ID 50134).
/// </summary>
page 50134 PTEBCFTPHosts
{
    ApplicationArea = All;
    Caption = 'FTP Hosts';
    PageType = List;
    SourceTable = PTEBCFtpHost;
    UsageCategory = Administration;
    CardPageId = PTEBCFtpHostCard;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                Editable = false;

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Name field.';
                }
            }
        }
    }
}
