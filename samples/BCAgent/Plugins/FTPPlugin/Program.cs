namespace FTPPlugin {

    using FluentFTP;
    using FluentFTP.Helpers;
    using FluentFTP.Rules;
    using Microsoft.Dynamics.BusinessCentral.Agent.Common;
    using Microsoft.Extensions.Logging;
    using Newtonsoft.Json;
    using Newtonsoft.Json.Linq;
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.IO.Compression;
    using System.IO.Pipes;
    using System.Linq;

    [AgentPlugin("ftp/V1.0")]
    public class FTPPlugin : IAgentPlugin {
        protected string HostName { get; set; }
        protected string UserName { get; set; }
        protected string Passwd { get; set; }
        protected string RootFolder { get; set; }


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
        public string SetWorkingDirectoryFtp(string jsonsettings, string foldername) {
            SetSettings(jsonsettings);
            SetWorkingDirectory(foldername);
            return (SetReturnValue(string.Empty, string.Empty));
        }

        [PluginMethod("GET")]
        public string DownloadFileFtp(string jsonsettings, string filename) {
            SetSettings(jsonsettings);
            return DownloadFileBytes(filename);
        }

        [PluginMethod("GET")]
        public void SetWorkingDirectory(string foldername) {
            using (var conn = new FtpClient(this.HostName, this.UserName, this.Passwd)) {
                conn.Connect();
                conn.SetWorkingDirectory(foldername);
            }
        }

        [PluginMethod("GET")]
        public string GetWorkingDirectory(string foldername) {
            using (var conn = new FtpClient(this.HostName, this.UserName, this.Passwd)) {
                conn.Connect();
                return SetReturnValue(conn.GetWorkingDirectory(), string.Empty);
            }
        }

        internal string Connect() {
            const string ConnectedLbl = "Connected.";
            using (var conn = new FtpClient(this.HostName, this.UserName, this.Passwd)) {
                conn.Connect();
                return SetReturnValue(ConnectedLbl, string.Empty);
            }
        }

        internal string DownloadDirectory(string foldername) {
            byte[] zipFile;
            using (var ftp = new FtpClient(this.HostName, this.UserName, this.Passwd)) {
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

        internal string DownloadFileBytes(string filename) {
            const string FailedToDownloadErr = "Failed to download {0}";

            using (var ftp = new FtpClient(this.HostName, this.UserName, this.Passwd)) {
                ftp.Connect();

                // download a file bytes
                bool res = ftp.DownloadBytes(out byte[] ftpFile, filename);
                if (!res) {
                    return SetReturnValue(string.Empty, string.Format(FailedToDownloadErr, filename));
                }
                return SetReturnValue(Convert.ToBase64String(ftpFile), string.Empty);
            }
        }

        internal string GetListing(string foldername) {
            using (var ftp = new FtpClient(this.HostName, this.UserName, this.Passwd)) {
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

        internal void SetSettings(string JsonString) {
            const string HostNameLbl = "hostName";
            const string UserNameLbl = "userName";
            const string PasswdLbl = "passwd";
            const string RootFolderLbl = "rootFolder";

            JObject Json = JObject.Parse(JsonString);
            this.HostName = Json.GetValue(HostNameLbl).ToString();
            this.UserName = Json.GetValue(UserNameLbl).ToString();
            this.Passwd = Json.GetValue(PasswdLbl).ToString();
            this.RootFolder = Json.GetValue(RootFolderLbl).ToString();
        }

        internal string SetReturnValue(string ReturnValue, string ErrorMessage) {
            JObject jreturn = new JObject() { { "returnValue", ReturnValue }, { "errorMessage", ErrorMessage } };
            return JsonConvert.SerializeObject(jreturn);
        }
    }


    internal class RootObject {
        public List<FtpListItem> Items { get; set; }
    }
}