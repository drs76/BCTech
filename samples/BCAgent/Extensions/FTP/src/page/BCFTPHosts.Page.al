/// <summary>
/// Page PTEBCFTPHosts (ID 50134).
/// </summary>
page 50134 PTEBCFTPHosts
{
    Caption = 'FTP Hosts';
    PageType = List;
    SourceTable = PTEBCFtpHost;
    UsageCategory = None;
    CardPageId = PTEBCFtpHostCard;
    ModifyAllowed = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Name field.';
                }
            }
        }
    }
}
