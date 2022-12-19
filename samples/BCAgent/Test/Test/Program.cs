using System;
using System.Collections.ObjectModel;
using System.Collections.Specialized;
using System.Text;
using System.Drawing.Printing;

namespace Test {
    internal class Program {
        static void Main(string[] args) {
            Console.WriteLine(GetLocalPrintersList());
        }

        internal protected static string GetLocalPrintersList() {
            foreach (var item in PrinterSettings.InstalledPrinters) {
                Console.WriteLine(item);
                return PrinterSettings.InstalledPrinters.ToString();
            }
            return string.Empty;

                //using (PowerShell ps = PowerShell.Create()) {
                //    try {
                //        string script = @"Get-WmiObject win32_printer | Select-Object name";
                //        ps.AddScript(script, true);
                //        Collection<PSObject> res = ps.Invoke();
                //        StringBuilder sb = new StringBuilder();
                //        foreach (PSObject obj in res) {
                //            sb.AppendLine(obj.ToString());
                //        }
                //        return sb.ToString();
                //    }
                //    catch (Exception ex) {
                //        return string.Empty;
                //    }
                //}          
        }
    }
}