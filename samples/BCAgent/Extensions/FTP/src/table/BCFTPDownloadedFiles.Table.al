/// <summary>
/// Table PTEBCFTPDownloadedFile (ID 50136).
/// </summary>
table 50136 PTEBCFTPDownloadedFile
{
    Caption = 'FTP Downloaded Files';
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

    var
        EmptyTxt: Label '';


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
    begin
        NewFileName := TempNameValueBuffer.Name;
        FtpClientMgt.TextToFromLastSlash(NewFileName, true);
        TempBlob.CreateInStream(ReadStream, TextEncoding::UTF8);

        FtpDownloadedFiles.Init();
        FtpDownloadedFiles.Filename := CopyStr(NewFileName, 1, MaxStrLen(FtpDownloadedFiles.Filename));
        Evaluate(FtpDownloadedFiles.Size, TempNameValueBuffer.Value);
        FtpDownloadedFiles.FileContent.ImportStream(ReadStream, NewFileName);
        FtpDownloadedFiles.Compressed := IsCompressed;
        FtpDownloadedFiles.FtpHost := CopyStr(FtpHostMgt.GetHostCode(JSettings), 1, MaxStrLen(FtpDownloadedFiles.FtpHost));
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
    begin
        if not GetTenantMedia(TenantMedia) then
            exit;

        TenantMedia.Content.CreateInStream(ReadStream, TextEncoding::UTF8);

        ToFileName := Rec.Filename;
        DownloadFromStream(ReadStream, EmptyTxt, EmptyTxt, EmptyTxt, ToFileName);
    end;

    /// <summary>
    /// GetCompressedEntryList.
    /// Get List of entries in zip archive.
    /// </summary>
    /// <returns>Return variable ReturnValue of type List of [Text].</returns>
    internal procedure GetCompressedEntryList() ReturnValue: List of [Text]
    var
        DataCompression: Codeunit "Data Compression";
    begin
        OpenZipArchive(DataCompression);
        DataCompression.GetEntryList(ReturnValue);
        DataCompression.CloseZipArchive();
    end;

    /// <summary>
    /// ExtractAndDownloadCompressedEntry.
    /// Extract and Download Compressed Entry.
    /// </summary>
    /// <param name="EntryFilename">Text.</param>
    internal procedure ExtractAndDownloadCompressedEntry(EntryFilename: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        ReadStream: InStream;
    begin
        ExtractZipEntry(EntryFilename, TempBlob);

        TempBlob.CreateInStream(ReadStream, TextEncoding::UTF8);
        DownloadFromStream(ReadStream, EmptyTxt, EmptyTxt, EmptyTxt, EntryFilename);
    end;

    /// <summary>
    /// ExtractAndViewCompressedEntry.
    /// </summary>
    /// <param name="EntryFilename">Text.</param>
    internal procedure ExtractAndViewCompressedEntry(EntryFilename: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        ReadStream: InStream;
        FileContentToView: Text;
    begin
        ExtractZipEntry(EntryFilename, TempBlob);

        TempBlob.CreateInStream(ReadStream);
        if ReadStream.Read(FileContentToView) = 0 then
            exit;

        ViewFileContents(FileContentToView, EntryFilename);
    end;

    /// <summary>
    /// ViewFileContents.
    /// </summary>
    internal procedure ViewFileContents()
    var
        TenantMedia: Record "Tenant Media";
        ReadStream: InStream;
        FileContentToView: Text;
    begin
        if not GetTenantMedia(TenantMedia) then
            exit;

        TenantMedia.Content.CreateInStream(ReadStream, TextEncoding::UTF8);
        if ReadStream.Read(FileContentToView) = 0 then
            exit;

        ViewFileContents(FileContentToView, Rec.Filename);
    end;

    local procedure GetTenantMedia(var TenantMedia: Record "Tenant Media") ReturnValue: Boolean
    begin
        if not TenantMedia.Get(Rec.FileContent.MediaId) then
            exit;

        ReturnValue := TenantMedia.CalcFields(Content);
    end;

    local procedure OpenZipArchive(var DataCompression: Codeunit "Data Compression")
    var
        TenantMedia: Record "Tenant Media";
        ReadStream: InStream;
    begin
        if not GetTenantMedia(TenantMedia) then
            exit;

        TenantMedia.Content.CreateInStream(ReadStream, TextEncoding::UTF8);
        DataCompression.OpenZipArchive(ReadStream, false);
    end;

    local procedure ExtractZipEntry(EntryFilename: Text; var TempBlob: Codeunit "Temp Blob")
    var
        DataCompression: Codeunit "Data Compression";
        WriteStream: OutStream;
        Length: Integer;
    begin
        OpenZipArchive(DataCompression);

        TempBlob.CreateOutStream(WriteStream, TextEncoding::UTF8);
        DataCompression.ExtractEntry(EntryFilename, WriteStream, Length);
        DataCompression.CloseZipArchive();
    end;

    local procedure ViewFileContents(PageFileContent: Text; PageFilename: Text);
    var
        FileContents: Page PTEBCFTPFileContent;
        PageCaptionLbl: Label 'Contents of - %1', Comment = '%1 - Filename|Foldername';
    begin
        FileContents.Caption(StrSubstNo(PageCaptionLbl, PageFilename));
        FileContents.SetFileContent(PageFileContent, PageFilename);
        FileContents.RunModal();
    end;

}
