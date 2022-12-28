
namespace LocalPrintersPlugin {
    using Microsoft.Dynamics.BusinessCentral.Agent.Common;
    using Newtonsoft.Json.Linq;
    using Newtonsoft.Json;
    using System.Drawing.Printing;
    using System.Text;
    using System.Runtime.InteropServices;
    using Ghostscript.NET.Processor;
    using System.IO;
    using System.Collections.Generic;
    using System;
    using Ghostscript.NET;
    using System.Linq;
    using System.Drawing;
    using System.Text.RegularExpressions;
    using System.Diagnostics;
    using System.Runtime.InteropServices.ComTypes;
    using System.Security.Policy;
    using System.Threading;

    [AgentPlugin("localPrinters/V1.0")]
    public class LocalPrintersPlugin : IAgentPlugin {
        protected string fileNameToPrint;
        protected string printerName;
        protected int noOfPages;
        protected byte[] fileContent;
        protected string returnValue;
        protected string returnError;

        const string printerLbl = "printername";
        const string filecontentLbl = "filecontent";
        const string bodyLbl = "body";


        [PluginMethod("GET")]
        public string CheckForGhostScript() {
            List<GhostscriptVersionInfo> gsVersions = GhostscriptVersionInfo.GetInstalledVersions(GhostscriptLicense.GPL | GhostscriptLicense.AFPL | GhostscriptLicense.Artifex);
            if (gsVersions.Count > 0) return SetReturnValue(gsVersions.AsEnumerable().First<GhostscriptVersionInfo>().Version.ToString(), string.Empty);
            return SetReturnValue(string.Empty, "Ghostscript is not installed on client!");
        }

        [PluginMethod("GET")]
        public string GetLocalPrintersList() {
            const string InvalidOSErr = "Invalid OS ({0}). Supported only on Windows.";
            if (!RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
                return SetReturnValue(string.Format(InvalidOSErr, RuntimeInformation.OSDescription), string.Empty);

            StringBuilder sb = new StringBuilder();
            foreach (var item in PrinterSettings.InstalledPrinters)
                sb.AppendLine(item.ToString());

            return SetReturnValue(sb.ToString(), string.Empty);
        }

        [PluginMethod("PUT")]
        public string PrintFileToLocalPrinterLP(string body) {
            returnError = string.Empty;
            returnValue = string.Empty;
            GetPrintDetails(body);
            fileNameToPrint = CreateTempFile();
            Stream strm = new MemoryStream(fileContent);
            try {
                LocalPrinting lp = new LocalPrinting(printerName, strm, noOfPages);
            }
            catch (Exception ex) {
                returnError = ex.Message;
            }
            return SetReturnValue(string.Empty, returnError);
        }


        [PluginMethod("PUT")]
        public string PrintFileToLocalPrinterProcess(string body) {
            returnError = string.Empty;
            returnValue = string.Empty;
            GetPrintDetails(body);
            fileNameToPrint = CreateTempFile();
            try {
                using (Process p = new Process()) {
                    using (FileStream fs = new FileStream(fileNameToPrint, FileMode.OpenOrCreate))
                    using (StreamWriter sw = new StreamWriter(fs))
                        sw.Write(Convert.ToBase64String(fileContent));

                    p.StartInfo = new ProcessStartInfo() {
                        CreateNoWindow = true,
                        Verb = "PrintTo",
                        Arguments = printerName,
                        FileName = @fileNameToPrint
                    };

                    p.Start();

                    long ticks = -1;
                    while (ticks != p.TotalProcessorTime.Ticks) {
                        ticks = p.TotalProcessorTime.Ticks;
                        Thread.Sleep(1000);
                    }

                    if (false == p.CloseMainWindow())
                        p.Kill();

                    if (File.Exists(fileNameToPrint))
                        File.Delete(fileNameToPrint);
                }
            }
            catch (Exception ex) { returnError = ex.Message; }
            return SetReturnValue(string.Empty, returnError);
        }

        [PluginMethod("PUT")]

        public string PrintFileToLocalPrinterGS(string body) {
            returnError = string.Empty;
            returnValue = string.Empty;
            GetPrintDetails(body);
            fileNameToPrint = CreateTempFile();

            using (FileStream fs = new FileStream(fileNameToPrint, FileMode.OpenOrCreate))
            using (StreamWriter sw = new StreamWriter(fs, Encoding.UTF8))
                sw.Write(fileContent);

            using (GhostscriptProcessor processor = new GhostscriptProcessor()) {

                List<string> switches = new List<string>();
                switches.Add("-empty");
                switches.Add("-dPrinted");
                switches.Add("-dBATCH");
                switches.Add("-dNOPAUSE");
                switches.Add("-dNOSAFER");
                switches.Add("-dNumCopies=1");
                switches.Add("-sDEVICE=mswinpr2");
                switches.Add("-sOutputFile=%printer%" + printerName);
                switches.Add("-f");

                processor.Completed += OnProcessExited;
                processor.Error += OnProcessError;

                processor.StartProcessing(switches.ToArray(), null);
                while (processor.IsRunning) {
                }

            }
            return SetReturnValue(returnValue, returnError);
        }

        [PluginMethod("GET")]
        public string GetPrinterSettings(string printername) {
            using (PrintDocument pd = new PrintDocument()) {
                // Specify the printer to use.
                pd.PrinterSettings.PrinterName = printername;
                if (pd.PrinterSettings.IsValid) return SetReturnValue(pd.PrinterSettings.ToString(), string.Empty);
            }
            return SetReturnValue(string.Empty, "Invalid printer settings");
        }

        internal protected void OnProcessError(object sender, GhostscriptProcessorErrorEventArgs e) {
            returnError = e.Message;
        }

        internal protected void OnProcessExited(object sender, GhostscriptProcessorEventArgs e) {
            if (File.Exists(fileNameToPrint)) {
                File.Delete(fileNameToPrint);
            }
            returnValue = e.ToString();
        }

        internal protected string SetReturnValue(string ReturnValue, string ErrorMessage) {
            JObject jreturn = new JObject() { { "returnValue", ReturnValue }, { "errorMessage", ErrorMessage } };
            return JsonConvert.SerializeObject(jreturn);
        }

        internal protected static string CreateTempFile() {
            string fileName;
            try {
                fileName = Path.GetTempFileName();
                FileInfo fileInfo = new FileInfo(fileName);
                fileInfo.Attributes = FileAttributes.Temporary;
                fileName = Path.ChangeExtension(fileName, "pdf");
            }
            catch (Exception ex) {
                throw new ArgumentException(string.Format("Unable to create TEMP file or set its attributes: {0}", ex.Message));
            }

            return fileName;
        }

        private void GetPrintDetails(string bodycontent) {
            JObject settings = JObject.Parse(bodycontent);
            GetBodyProperty(settings, printerLbl);
            GetBodyProperty(settings, filecontentLbl);

            if (returnError.Length == 0)
                return;

            throw new Exception(returnError);
        }

        internal protected bool GetBodyProperty(JObject body, string property) {
            if (body.TryGetValue(property, out var prop)) {
                switch (property) {
                    case printerLbl:
                        printerName = prop.ToString();
                        return true;
                    case filecontentLbl:
                        fileContent = Convert.FromBase64String(prop.ToString());
                        return true;
                    default:
                        break;
                }
            }
            if (returnError.Length != 0)
                returnError += Environment.NewLine;

            returnError += $"Invalid Json: {property} not found in Request Body Content.";
            return false;
        }

        internal protected int GetNoPagesInPdf(string pdf) {
            Regex rx = new Regex(@"/Type\s/Page[^s]");
            MatchCollection match = rx.Matches(pdf.ToString());
            return match.Count;
        }
    }
}