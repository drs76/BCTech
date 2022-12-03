namespace FTPPlugin {

    using FluentFTP;
    using FluentFTP.Helpers;
    using Microsoft.Dynamics.BusinessCentral.Agent.Common;
    using Microsoft.Extensions.Logging;
    using Newtonsoft.Json;
    using Newtonsoft.Json.Linq;
    using System;
    using System.Collections.Generic;
    using System.IO;

    [AgentPlugin("ftp/V1.0")]
    public class FTPPlugin : IAgentPlugin {
        protected string HostName { get; set; }
        protected string UserName { get; set; }
        protected string Passwd { get; set; }
        protected string RootFolder { get; set; }
        protected string LocalFolder { get; set; }


        [PluginMethod("GET")]
        public string ConnectFtp(string jsonsettings) {
            string returnval = string.Empty;
            SetSettings(jsonsettings);

            try {
                Connect(this.HostName, this.UserName, this.Passwd);
                return SetReturnValue(true.ToString(), string.Empty);
            }
            catch (Exception ex) {
                return SetReturnValue(string.Empty, string.Format("Error connecting:,{0}", ex.Message));
            }
        }

        [PluginMethod("GET")]
        public string GetFilesFtp(string jsonsettings, string foldername) {
            string returnval = string.Empty;
            SetSettings(jsonsettings);

            try {
                return SetReturnValue(GetListing(this.HostName, this.UserName, this.Passwd, foldername).ToString(), string.Empty);
            }
            catch (Exception ex) {

                return SetReturnValue(string.Empty, JsonConvert.SerializeObject(string.Format("Error getting files:\n,{0}", ex.Message)));
            }
        }

        [PluginMethod("GET")]
        public string DownloadFolderFtp(string jsonsettings, string foldername) {
            string returnval = string.Empty;
            SetSettings(jsonsettings);

            try {
                return SetReturnValue(Convert.ToString(DownloadDirectory(this.HostName, this.UserName, this.Passwd, foldername)), string.Empty);
            }
            catch (Exception ex) {
                return SetReturnValue(string.Empty, string.Format("Error downloading folders:\n,{0}", ex.Message));
            }
        }

        [PluginMethod("GET")]
        public string SetWorkingDirectoryFtp(string jsonsettings, string foldername) {
            string returnval = string.Empty;
            SetSettings(jsonsettings);

            try {
                SetWorkingDirectory(this.HostName, this.UserName, this.Passwd, foldername);
                return (SetReturnValue(string.Empty, string.Empty));
            }
            catch (Exception ex) {
                return SetReturnValue(string.Empty, string.Format("Error downloading folders:\n,{0}", ex.Message));
            }
        }

        [PluginMethod("GET")]
        public string DownloadDirectoryFtp(string jsonsettings, string foldername) {
            string returnval = string.Empty;
            SetSettings(jsonsettings);

            try {
                return SetReturnValue(JsonConvert.SerializeObject(DownloadDirectory(this.HostName, this.UserName, this.Passwd, foldername)), string.Empty);
            }
            catch (Exception ex) {
                return SetReturnValue(string.Empty, string.Format("Error downloading folders:\n,{0}", ex.Message)); 
            }
        }

        [PluginMethod("GET")]
        public string DownloadFileFtp(string jsonsettings, string filename) {
            string returnval = string.Empty;
            SetSettings(jsonsettings);
            
            try {
                if (!DownloadFile(this.HostName, this.UserName, this.Passwd, filename)) {
                    return SetReturnValue(string.Empty, "Download failed.");
                }
                else {
                    Byte[] bytes = File.ReadAllBytes(Path.Combine(this.LocalFolder, filename));
                    return SetReturnValue(Convert.ToBase64String(bytes), string.Empty);
                }
            }
            catch (Exception ex) {
                return SetReturnValue(string.Empty,ex.Message); 
            }
        }

        [PluginMethod("GET")]
        public void SetWorkingDirectory(string hostname, string username, string passwd, string foldername) {
            using (var conn = new FtpClient(hostname, username, passwd)) {
                conn.Connect();
                conn.SetWorkingDirectory(foldername);
            }
        }

        [PluginMethod("GET")]
        public string GetWorkingDirectory(string hostname, string username, string passwd, string foldername) {
            using (var conn = new FtpClient(hostname, username, passwd)) {
                conn.Connect();
                return SetReturnValue(conn.GetWorkingDirectory(), string.Empty);
            }
        }

        internal static void Connect(string hostname, string username, string passwd) {
            using (var conn = new FtpClient(hostname, username, passwd)) {
                conn.Connect();
            }
        }

        internal bool DownloadDirectory(string hostname, string username, string passwd, string foldername) {
            using (var ftp = new FtpClient(hostname, username, passwd)) {
                ftp.Connect();

                // download a folder and all its files
                ftp.DownloadDirectory(this.LocalFolder, foldername, FtpFolderSyncMode.Update);

                // download a folder and all its files, and delete extra files on disk
                //List<FtpResult> result = ftp.DownloadDirectory(@"C:\temp\", foldername, FtpFolderSyncMode.Mirror);
                return false;
            }
        }

        internal Boolean DownloadFile(string hostname, string username, string passwd, string filename) {
            using (var ftp = new FtpClient(hostname, username, passwd)) {
                ftp.Connect();

                // download a file
                FtpStatus res = ftp.DownloadFile(Path.Combine(this.LocalFolder, filename), filename, FtpLocalExists.Overwrite);

                return res.IsSuccess();
            }
        }

        internal string GetListing(string hostname, string username, string passwd, string foldername) {
            using (var conn = new FtpClient(hostname, username, passwd)) {
                conn.Connect();

                // get a recursive listing of the files & folders in a specific folder 
                RootObject root = new RootObject {
                    items = new List<FtpListItem>()
                };

                foreach (var item in conn.GetListing(foldername, FtpListOption.AllFiles))
                {
                    if (item.Type == FtpObjectType.Link)
                    {
                        continue;
                    }
                    root.items.Add(item);
                }
                return JsonConvert.SerializeObject(root);
            }
        }

        internal void SetSettings(string JsonString) {
            const string HostNameLbl = "hostName";
            const string UserNameLbl = "userName";
            const string PasswdLbl = "passwd";
            const string RootFolderLbl = "rootFolder";
            const string LocalFolderLbl = "localFolder";

            JObject Json = JObject.Parse(JsonString);
            this.HostName = Json.GetValue(HostNameLbl).ToString();
            this.UserName = Json.GetValue(UserNameLbl).ToString();
            this.Passwd = Json.GetValue(PasswdLbl).ToString();
            this.RootFolder = Json.GetValue(RootFolderLbl).ToString();
            this.LocalFolder = Json.GetValue(LocalFolderLbl).ToString();
        }

        internal string SetReturnValue(string ReturnValue, string ErrorMessage)
        {
            JObject jreturn = new JObject
            {
                { "returnValue", ReturnValue },
                { "errorMessage", ErrorMessage }
            };
            return JsonConvert.SerializeObject(jreturn);
        }
    }


    internal class RootObject {
        public List<FtpListItem> items { get; set; }
    }
}