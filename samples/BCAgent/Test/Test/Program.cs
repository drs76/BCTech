using System.Threading.Tasks;
using System.Threading;
using System;
using Microsoft.Dynamics.BusinessCentral.Agent.RequestDispatcher;
using Microsoft.Dynamics.BusinessCentral.Agent.Common;

namespace Test {
    internal class Program {
        static void Main(string[] args) {
            Console.WriteLine("Business Central Agent");
           
            // TODO: argument validating and exit on invalid.

            Console.WriteLine("Press 'q' to quit.");
            var cts = new CancellationTokenSource();
            Task.Run(() => RequestDispatcher.Start(
                "bcagentrelayns.servicebus.windows.net",
                "bcagentc",
                "listen",
                "53MNnWHQ7Of2Tul7AMljtz9JOGw6Ofp+JAjPrLPCp4c=",
                AppContext.BaseDirectory,
                new ConsoleLogger(), // TODO: LogLevel support 
                cts.Token
            ), cts.Token);

            while (Console.ReadKey().KeyChar != 'q') {

            }

            cts.Cancel();

        }
        /// <summary>
        /// ILogger implementation that writes to console.
        /// </summary>
        class ConsoleLogger : ILogger {
            public ConsoleLogger() {
            }

            public void LogException(Exception e) {
                Console.WriteLine(e.ToString());
            }

            public void LogMessage(LogLevel level, string message) {
                Console.WriteLine(message);
            }
        }
    }
}