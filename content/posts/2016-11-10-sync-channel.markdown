---
layout: post
title: "Sync channel"
date: 2016-11-10 10:15:00 -0800
comments: true
categories: 
---

Application Insights [API library](https://www.nuget.org/packages/Microsoft.ApplicationInsights) provides a basic methods to track telemetry in the application. Like `TrackTrace` and `TrackMetric`. It also implements the basic channel to send this data to the Application Insights.

If you are using Application Insights API in short running tasks you may hit a problem that some telemetry wasn't send. Basic channel do not provide control over data delivery. Method `Flush` makes an effort to flush telemetry left in buffers, but do not guarantee delivery either.    

This is a very simple sync channel you can use to overcome the issues above. It has two features:

1. No need to Flush. When `Track` method complete - event is delivered
2. Sending is synchronous. No new threads/tasks will be started
3. When delivery fails - method `Track` will throw an exception and you can re-try.  

Here is the code with the usage example: 

``` csharp
using System;
using System.Collections.Generic;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.ApplicationInsights.Extensibility.Implementation;

namespace DemoSyncChannel
{
    class Program
    {
        class SyncTelemetryChannel : ITelemetryChannel
        {
            private Uri endpoint = new Uri("https://dc.services.visualstudio.com/v2/track");

            public bool? DeveloperMode { get; set; }

            public string EndpointAddress { get; set; }

            public void Dispose() { }

            public void Flush() { }

            public void Send(ITelemetry item)
            {
                byte[] json = JsonSerializer.Serialize(new List<ITelemetry>() { item }, true);
                Transmission transimission = new Transmission(endpoint, json, "application/x-json-stream", JsonSerializer.CompressionType);
                var t = transimission.SendAsync();
                t.Wait();
            }
        }

        static void Main(string[] args)
        {
            TelemetryConfiguration.Active.TelemetryChannel = new SyncTelemetryChannel();

            TelemetryConfiguration.Active.InstrumentationKey = "c92059c3-9428-43e7-9b85-a96fb7c9488f";
            new TelemetryClient().TrackTrace("Sync trace");

            // this will throw exception
            TelemetryConfiguration.Active.InstrumentationKey = "invalid instrumentation key";
            new TelemetryClient().TrackTrace("Sync trace");
        }
    }
}
```