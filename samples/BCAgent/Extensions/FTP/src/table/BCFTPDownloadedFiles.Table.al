/// <summary>
/// Table PTEBCFTPDownloadedFile (ID 50136).
/// </summary>
table 50136 PTEBCFTPDownloadedFile
{
    Caption = 'BC FTP Downloaded Files';
    DataClassification = CustomerContent;

    fields
    {
        field(1; EntryNo; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }

        field(2; Filename; Text[1024])
        {
            Caption = 'Filename';
            DataClassification = CustomerContent;
        }

        field(3; Compressed; Boolean)
        {
            Caption = 'Compressed';
            DataClassification = CustomerContent;
        }

        field(4; Size; Integer)
        {
            Caption = 'Size';
            DataClassification = CustomerContent;
        }

        field(5; FtpHost; Code[250])
        {
            Caption = 'Ftp Host';
            DataClassification = CustomerContent;
        }

        field(6; FileContent; Media)
        {
            Caption = 'File Content';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; EntryNo)
        {
            Clustered = true;
        }

        key(Host; FtpHost)
        {

        }
    }

    /// <summary>
    /// CreateEntry.
    /// </summary>
    /// <param name="JSettings">JsonObject.</param>
    /// <param name="TempNameValueBuffer">Temporary Record "Name/Value Buffer".</param>
    /// <param name="TempBlob">VAR Codeunit "Temp Blob".</param>
    /// <param name="IsCompressed">Boolean.</param>
    internal procedure CreateEntry(JSettings: JsonObject; TempNameValueBuffer: Record "Name/Value Buffer" temporary; var TempBlob: Codeunit "Temp Blob"; IsCompressed: Boolean)
    var
        FtpDownloadedFiles: Record PTEBCFTPDownloadedFile;
        FtpClientMgt: Codeunit PTEBCFtpClientMgt;
        FtpHostMgt: Codeunit PTEBCFtpHostMgt;
        ReadStream: InStream;
        NewFileName: Text;
        StoringLbl: Label 'Storing to Ftp Downloads table..';
    begin
        NewFileName := TempNameValueBuffer.Name;
        FtpClientMgt.TextFromLastSlash(NewFileName);
        TempBlob.CreateInStream(ReadStream);

        FtpDownloadedFiles.Init();
        FtpDownloadedFiles.Filename := CopyStr(NewFileName, 1, MaxStrLen(FtpDownloadedFiles.Filename));
        Evaluate(FtpDownloadedFiles.Size, TempNameValueBuffer.Value);
        FtpDownloadedFiles.FileContent.ImportStream(ReadStream, NewFileName);
        FtpDownloadedFiles.Compressed := IsCompressed;
        FtpDownloadedFiles.FtpHost := CopyStr(FtpHostMgt.GetHostName(JSettings), 1, MaxStrLen(FtpDownloadedFiles.FtpHost));
        FtpDownloadedFiles.Insert(true);

        Rec := FtpDownloadedFiles;
    end;

    /// <summary>
    /// DownloadFile.
    /// </summary>
    internal procedure DownloadFile()
    var
        TenantMedia: Record "Tenant Media";
        ReadStream: InStream;
        ToFileName: Text;
        EmptyTxt: Label '';
    begin
        if not TenantMedia.Get(Rec.FileContent.MediaId) then
            exit;

        ToFileName := Rec.Filename;
        TenantMedia.Content.CreateInStream(ReadStream);
        DownloadFromStream(ReadStream, EmptyTxt, EmptyTxt, EmptyTxt, ToFileName);
    end;
}
