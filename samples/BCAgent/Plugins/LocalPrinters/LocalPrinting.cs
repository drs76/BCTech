using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Printing;
using System.IO;
using System.Text.RegularExpressions;
using Ghostscript.NET;
using Ghostscript.NET.Rasterizer;

namespace LocalPrintersPlugin {
    internal class LocalPrinting {
        protected Font printFont;
        protected StreamReader streamToPrint;
        protected string printerName;
        protected int noOfPages;
        protected List<byte[]> imagePages;

        public LocalPrinting(string printername, Stream filecontent, int noofpages) {
            this.printerName = printername;
            this.streamToPrint = new StreamReader(filecontent);
            this.noOfPages = noofpages;
            Printing();
        }

        // The PrintPage event is raised for each page to be printed.
        private void pd_PrintPage(object sender, PrintPageEventArgs ev) {
            float linesPerPage = 0;
            float yPos = 0;
            int count = 0;
            float leftMargin = ev.MarginBounds.Left;
            float topMargin = ev.MarginBounds.Top;
            String line = null;

            // Calculate the number of lines per page.
            linesPerPage = ev.MarginBounds.Height /
               printFont.GetHeight(ev.Graphics);

            // Iterate over the file, printing each line.
            while (count < linesPerPage && ((line = streamToPrint.ReadLine()) != null)) {
                yPos = topMargin + (count * printFont.GetHeight(ev.Graphics));
                ev.Graphics.DrawString(line, printFont, Brushes.Black, leftMargin, yPos, new StringFormat());
                count++;
            }

            // If more lines exist, print another page.
            if (line != null)
                ev.HasMorePages = true;
            else
                ev.HasMorePages = false;
        }

        // Print the file.
        public void Printing() {
            try {
                try {
                    for (int i = 1; i < noOfPages; i++) {
                        imagePages.Add(Freeware.Pdf2Png.Convert(streamToPrint.BaseStream, 1));
                    }
   
                    printFont = new Font("Segoe UI", 8);
                    PrintDocument pd = new PrintDocument();
                    pd.PrintPage += new PrintPageEventHandler(pd_PrintPage);
                    // Print the document.
                    pd.PrinterSettings.PrinterName = printerName;
                    pd.Print();
                }
                finally {
                    streamToPrint.Close();
                }
            }
            catch (Exception ex) {
                throw new Exception("Printing" + ex.Message);
            }
        }
    }
}
