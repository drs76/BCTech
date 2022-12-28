namespace FTPPlugin {

    using FluentFTP;
    using FluentFTP.Client.BaseClient;
    using Microsoft.Dynamics.BusinessCentral.Agent.Common;
    using Newtonsoft.Json;
    using Newtonsoft.Json.Linq;
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.IO.Compression;
    using System.Linq;
    using System.Net.Security;
    using System.Security.Authentication;
    using System.Security.Cryptography.X509Certificates;
    using System.Dynamic;

    [AgentPlugin("ftp/V1.0")]
    public class FTPPlugin : IAgentPlugin {
        protected internal dynamic ftpSetup = new FtpClientSetup();

        [PluginMethod("GET")]
        public string ConnectFtp(string jsonsettings) {
            SetSettings(jsonsettings);
            return SetReturnValue(JsonConvert.SerializeObject(Connect()), string.Empty);
        }

        [PluginMethod("GET")]
        public string GetFilesFtp(string jsonsettings, string foldername) {
            SetSettings(jsonsettings);
            return SetReturnValue(GetListing(foldername).ToString(), string.Empty);
        }

        [PluginMethod("GET")]
        public string DownloadFolderFtp(string jsonsettings, string foldername) {
            SetSettings(jsonsettings);
            return SetReturnValue(Convert.ToString(DownloadDirectory(foldername)), string.Empty);
        }

        [PluginMethod("GET")]
        public string DownloadFileFtp(string jsonsettings, string filename) {
            SetSettings(jsonsettings);
            return DownloadFileBytes(filename);
        }

        protected string Connect() {
            const string ConnectedLbl = "Connected.";
            using (FtpClient conn = new FtpClient(ftpSetup.hostName.ToString(), ftpSetup.userName.ToString(), ftpSetup.passwd.ToString())) {
                conn.Connect();
                return ConnectedLbl;
            }
        }

        protected string DownloadDirectory(string foldername) {
            byte[] zipFile;
            using (FtpClient ftp = new FtpClient(ftpSetup.hostName.ToString(), ftpSetup.userName.ToString(), ftpSetup.passwd.ToString())) {
                ftp.Connect();
                ftp.SetWorkingDirectory(foldername);

                using (MemoryStream zipStream = new MemoryStream()) {
                    using (ZipArchive zipArchive = new ZipArchive(zipStream, ZipArchiveMode.Create, true)) {
                        foreach (var item in ftp.GetListing(foldername, FtpListOption.AllFiles)) {
                            if (item.Type == FtpObjectType.File) {
                                var entry = zipArchive.CreateEntry(item.Name, CompressionLevel.Fastest);
                                using (Stream entryStream = entry.Open())
                                using (BinaryWriter zipFileBinarywriter = new BinaryWriter(entryStream)) {
                                    if (ftp.DownloadBytes(out byte[] ftpFile, item.FullName)) {
                                        zipFileBinarywriter.Write(ftpFile);
                                    }
                                }
                            }
                        }
                    }
                    zipStream.Seek(0, SeekOrigin.Begin);
                    zipFile = zipStream.ToArray();
                }
            }
            return Convert.ToBase64String(zipFile.ToArray());
        }

        protected void ApplyConnectionSecurity(ref FtpClient ftp) {
            const string SSLOSLbl = "None (OS)";
            const string X509Lbl = "X509";
            const string ValidateCertificateLbl = "ValidateCertificate";
            const string ValidateAnyCertificateLbl = "ValidateAnyCertificate";
            const string InvalidCertEtrr = "Invalid certificate : {0}";

            if (ftpSetup.SSL != SSLOSLbl) {
                ftp.Config.SslProtocols = SslProtocols.Tls11 | SslProtocols.Tls12;
            }
            else {
                // OS Defaults
                ftp.Config.SslProtocols = SslProtocols.None;
            }

            switch (ftpSetup.ValidationCertificate) {
                case X509Lbl:
                    ftp.Config.SocketKeepAlive = false;
                    ftp.Config.ClientCertificates.Add(new X509Certificate2(Convert.FromBase64String(Convert.ToBase64String(ftpSetup.sslCert))));
                    ftp.ValidateCertificate += (control, e) => {
                        e.Accept = e.PolicyErrors == SslPolicyErrors.None;
                    };
                    break;
                case ValidateCertificateLbl:
                    ftp.ValidateCertificate += (control, e) => {
                        if (e.PolicyErrors == SslPolicyErrors.None || e.Certificate.GetRawCertDataString() == ftpSetup.sslCert.ToString()) {
                            e.Accept = true;
                        }
                        else {
                            throw new Exception(string.Format(InvalidCertEtrr, e.PolicyErrors));
                        }
                    };
                    break;
                case ValidateAnyCertificateLbl:
                    ftp.Config.ValidateAnyCertificate = true;
                    break;
                default:
                    break;
            }
        }

        protected string DownloadFileBytes(string filename) {
            const string FailedToDownloadErr = "Failed to download {0}";

            using (FtpClient ftp = new FtpClient(ftpSetup.hostName.ToString(), ftpSetup.userName.ToString(), ftpSetup.passwd.ToString())) {
                ftp.Connect();

                // download a file bytes
                bool res = ftp.DownloadBytes(out byte[] ftpFile, filename);
                if (!res) {
                    return SetReturnValue(string.Empty, string.Format(FailedToDownloadErr, filename));
                }
                return SetReturnValue(Convert.ToBase64String(ftpFile), string.Empty);
            }
        }

        protected string GetListing(string foldername) {
            using (FtpClient ftp = new FtpClient(ftpSetup.hostName.ToString(), ftpSetup.userName.ToString(), ftpSetup.passwd.ToString())) {
                ftp.Connect();

                // get a recursive listing of the files & folders in a specific folder 
                RootObject root = new RootObject() {
                    Items = new List<FtpListItem>()
                };

                foreach (var item in ftp.GetListing(foldername, FtpListOption.AllFiles)) {
                    if (item.Type == FtpObjectType.Link) {
                        continue;
                    }
                    root.Items.Add(item);
                }
                return JsonConvert.SerializeObject(root);
            }
        }

        protected void SetSettings(string JsonString) {
            ftpSetup = JObject.Parse(JsonString);
        }

        protected string SetReturnValue(string ReturnValue, string ErrorMessage) {
            JObject jreturn = new JObject() { { "returnValue", ReturnValue }, { "errorMessage", ErrorMessage } };
            return JsonConvert.SerializeObject(jreturn);
        }

        protected internal class RootObject {
            public List<FtpListItem> Items { get; set; }
        }

        protected internal class FtpClientSetup : DynamicObject { }
    }
}