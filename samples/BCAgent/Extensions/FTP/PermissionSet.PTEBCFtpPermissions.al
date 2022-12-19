/// <summary>
/// permissionset PTEBCFtpPermissions (ID 50134).
/// </summary>
permissionset 50134 PTEBCFtpPermissions
{
    Assignable = true;
    Caption = 'BC Ftp Permissions', MaxLength = 30;
    Permissions =
        table PTEBCFTPDownloadedFile = X,
        tabledata PTEBCFTPDownloadedFile = RMID,
        table PTEBCFtpHost = X,
        tabledata PTEBCFtpHost = RMID,
        codeunit PTEBCFTPMgt = X,
        codeunit PTEBCFtpHostMgt = X,
        codeunit PTEBCFtpClientMgt = X,
        page PTEBCFTPHosts = X,
        page PTEBCFtpHostCard = X,
        page PTEBCFTPFileContent = X,
        page PTEBCFTPDownloadedZipContents = X,
        page PTEBCFtpDownloadedFiles = X,
        page PTEBCFtpClientFilesPart = X,
        page PTEBCFTPClient = X;
}
