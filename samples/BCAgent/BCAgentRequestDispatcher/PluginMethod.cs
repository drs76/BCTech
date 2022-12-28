// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved. 
// Licensed under the MIT License. See License.txt in the project root for license information. 
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Dynamics.BusinessCentral.Agent.RequestDispatcher {
    using System;
    using System.Collections.Generic;
    using System.Collections.Specialized;
    using System.Globalization;
    using System.IO;
    using System.Reflection;
    using System.Text;
    using System.Web;
    using Azure.Relay;
    using Common;
    using Newtonsoft.Json.Linq;

    internal class PluginMethod {
        internal string HttpMethod { get; }

        internal IAgentPlugin Plugin { get; }

        internal MethodInfo MethodInfo { get; }

        internal string Name => MethodInfo.Name;

        private readonly ParameterInfo[] parameters;
        private readonly Func<string, object>[] parameterConverters;

        private ParameterInfo returnParameter;

        internal static PluginMethod Create(IAgentPlugin plugin, MethodInfo methodInfo) {
            PluginMethodAttribute methodAttribute = methodInfo.GetCustomAttribute<PluginMethodAttribute>();
            if (!IsValidMethodAttribute(methodAttribute)) {
                return null;
            }

            if (!IsValidSignature(methodInfo)) {
                return null;
            }

            return new PluginMethod(plugin, methodAttribute.HttpMethod, methodInfo);
        }

        private PluginMethod(IAgentPlugin plugin, string httpMethod, MethodInfo methodInfo) {
            HttpMethod = httpMethod;
            MethodInfo = methodInfo;
            parameters = MethodInfo.GetParameters();
            parameterConverters = CreateParameterConverters();

            returnParameter = MethodInfo.ReturnParameter;
            Plugin = plugin;
        }

        private Func<string, object>[] CreateParameterConverters() {
            var parameterConverters = new Func<string, object>[parameters.Length];
            for (int i = 0; i < parameters.Length; i++) {
                Type parameterType = parameters[i].ParameterType;
                if (parameterType == typeof(string)) {
                    parameterConverters[i] = ToString;
                }
                else if (parameterType == typeof(decimal)) {
                    parameterConverters[i] = ToDecimal;
                }
                else if (parameterType == typeof(int)) {
                    parameterConverters[i] = ToInt;
                }
                else if (parameterType == typeof(long)) {
                    parameterConverters[i] = ToInt64;
                }
            }

            return parameterConverters;
        }

        /// <summary>
        /// Invoke the method using reflection.
        /// </summary>
        /// <param name="context">The listener context</param>
        internal void Invoke(RelayedHttpListenerContext context) {
            var result = MethodInfo.Invoke(Plugin, PrepareArguments(context));
            if (result != null) {
                using (var sw = new StreamWriter(context.Response.OutputStream)) {
                    sw.WriteLine(result.ToString());
                }
            }
        }

        private static readonly object[] EmptyParameters = new object[0];

        /// <summary>
        /// Create an object array with converted parameters.
        /// </summary>
        /// <param name="query">The request QueryString</param>
        /// <param name="inputstream">Stream containing the file to print.</param>
        /// <returns>Object array with converted parameters</returns>
        private object[] PrepareArguments(RelayedHttpListenerContext context) {
            NameValueCollection nameValueCollection = HttpUtility.ParseQueryString(context.Request.Url.Query);
            if ((parameters.Length == 0) && (context.Request.HttpMethod == "GET")) {
                if (context.Request.Url.Query.Length > 0) {
                    // TODO: Warn for excess parameters
                }
                return EmptyParameters;
            }

            if ((!context.Request.HasEntityBody) && (context.Request.HttpMethod == "PUT")) {
                return EmptyParameters;
            }

            List<Object> arguments = new List<object>();
            JObject body = GetBodyContentAsJson(context.Request.InputStream);
            
            ProcessParameters(context, nameValueCollection, arguments, body);
            
            if (arguments.Count == 0)
                return EmptyParameters;

            return arguments.ToArray();
        }

        internal protected void ProcessParameters(RelayedHttpListenerContext context, NameValueCollection nameValueCollection, List<object> arguments, JObject body) {
            for (int i = 0; i < parameters.Length; i++) {
                ParameterInfo parameter = parameters[i];
                string value = nameValueCollection.Get(parameter.Name);
                if (context.Request.HttpMethod == "PUT") {
                    arguments.Add(parameterConverters[i](body.ToString()));
                    continue;
                }
                else {
                    if (value != null) {
                        arguments.Add(parameterConverters[i](value));
                        continue;
                    }
                }
                // Error missing parameter.
                throw new ArgumentException($"Parameter '{parameter.Name}' not found in Request Query or Body.");
            }
        }

        internal protected static JObject GetBodyContentAsJson(Stream inputstream) {
            using (StreamReader reader = new StreamReader(inputstream, Encoding.UTF8)) {
                JObject x = JObject.Parse(reader.ReadToEnd());
                if (x.TryGetValue("body", out var jtoken)) {
                    JObject body = jtoken.ToObject<JObject>();
                    return body;
                }
            }
            return new JObject();
        }

        /// <summary>
        /// Validate the method attribute for supported Http Method
        /// </summary>
        /// <param name="methodAttribute">The plugin method attribute</param>
        /// <returns>true if the attribute is valid and supported,</returns>
        internal protected static bool IsValidMethodAttribute(PluginMethodAttribute methodAttribute) {
            if (methodAttribute == null) {
                return false;
            }

            switch (methodAttribute.HttpMethod) {
                case "GET":
                case "PUT":
                    break;
                default:
                    return false;
            }

            return true;
        }

        /// <summary>
        /// Checks if the method signature is valid and supported by the runtime.
        /// </summary>
        /// <param name="methodInfo">Method Info</param>
        /// <returns>true - if the method is supported by the runtime.</returns>
        private static bool IsValidSignature(MethodInfo methodInfo) {
            if (methodInfo.IsGenericMethod) {
                return false;
            }

            ParameterInfo[] parameterInfos = methodInfo.GetParameters();
            foreach (var parameterInfo in parameterInfos) {
                if (parameterInfo.IsOut) {
                    return false;
                }

                if (parameterInfo.ParameterType != typeof(string) &&
                    parameterInfo.ParameterType != typeof(decimal) &&
                    parameterInfo.ParameterType != typeof(long) &&
                    parameterInfo.ParameterType != typeof(int)) {
                    return false;
                }
            }

            return true;
        }

        #region Parameter value converters

        private static object ToInt(string value) {
            if (!int.TryParse(value, out int i)) {
                return null;
            }

            return i;
        }

        private static object ToInt64(string value) {
            if (!long.TryParse(value, out long l)) {
                return null;
            }

            return l;
        }

        private static object ToDecimal(string value) {
            if (!decimal.TryParse(value, NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out decimal d)) {
                return null;
            }

            return d;
        }

        private static object ToString(string value) {
            return value;
        }

        #endregion

        public override string ToString() {
            return this.MethodInfo.ToString();
        }
    }
}
