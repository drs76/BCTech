/// <summary>
/// Table PTEFtpHost (ID 50135).
/// </summary>
table 50135 PTEBCFtpHost
{
    Caption = 'BC Ftp Host';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Name; Code[250])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
        }

        field(2; RootFolder; Text[2048])
        {
            Caption = 'Ftp Folder';
            DataClassification = CustomerContent;
        }

        field(3; LocalFolder; Text[2048])
        {
            Caption = 'Local Folder';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; Name)
        {
            Clustered = true;
        }
    }
}
