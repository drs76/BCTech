
namespace LocalPrinters {
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

    [AgentPlugin("localPrinters/V1.0")]
    public class LocalPrintersPlugin : IAgentPlugin {
        protected string fileNameToPrint;
        protected string returnValue;
        protected string returnError;

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

        [PluginMethod("GET")]
        public string PrintFileToLocalPrinter(string filecontent, string printerName) {
            returnError = string.Empty;
            returnValue = string.Empty;

            using (GhostscriptProcessor processor = new GhostscriptProcessor()) {
                using (FileStream fs = new FileStream(fileNameToPrint, FileMode.Create)) {
                    using (StreamWriter sw = new StreamWriter(fs, Encoding.UTF8)) {
                        sw.Write(filecontent);
                    }

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
                    switches.Add(fileNameToPrint);

                    processor.Completed += OnProcessExited;
                    processor.Error += OnProcessError;
                    processor.StartProcessing(switches.ToArray(), null);
                    while(processor.IsRunning) {
                    }
                }
            }
            return SetReturnValue(returnValue, returnError);
        }

        private void OnProcessError(object sender, GhostscriptProcessorErrorEventArgs e) {
            returnError = e.Message;
        }

        private void OnProcessExited(object sender, GhostscriptProcessorEventArgs e) {
            File.Delete(fileNameToPrint);
            returnValue = e.ToString();
        }

        protected string SetReturnValue(string ReturnValue, string ErrorMessage) {
            JObject jreturn = new JObject() { { "returnValue", ReturnValue }, { "errorMessage", ErrorMessage } };
            return JsonConvert.SerializeObject(jreturn);
        }
    }
}