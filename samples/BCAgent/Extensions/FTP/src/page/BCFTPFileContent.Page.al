/// <summary>
/// Page PTEBCFTPFileContent (ID 50139).
/// </summary>
page 50139 PTEBCFTPFileContent
{
    Caption = 'FTP File Content';
    PageType = NavigatePage;
    SourceTable = Integer;
    SourceTableView = sorting(Number) where(Number = const(1));
    UsageCategory = None;
    Editable = false;
    ShowFilter = false;
    LinksAllowed = false;

    layout
    {
        area(content)
        {
            usercontrol(fileContent; PTEBCFTPFileContent)
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    CurrPage.fileContent.Init();
                    CurrPage.fileContent.Load(FileContent);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        FileContent: Text;
        Filename: Text;


    /// <summary>
    /// SetFileContent.
    /// </summary>
    /// <param name="NewFileContent">Text.</param>
    /// <param name="NewFilename">Text.</param>
    internal procedure SetFileContent(NewFileContent: Text; NewFilename: Text)
    begin
        FileContent := NewFileContent;
        Filename := NewFilename;
    end;
}
