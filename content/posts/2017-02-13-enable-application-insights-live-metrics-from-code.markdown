---
layout: post
title: "Enable Application Insights Live Metrics from code"
date: 2017-02-13 21:33:48 -0800
comments: true
aliases: [/blog/2017-02-13-enable-application-insights-live-metrics-from-code/]
categories: 
---
Small tip on how to enable Application Insights Live Metrics from code. 

Application Insights allows to view telemetry like CPU and memory in [real time](https://docs.microsoft.com/en-us/azure/application-insights/app-insights-live-stream). The feature is called Live Metrics. We also call it Quick Pulse. You'd typically use it when something is happenning with your application. Deploying a new version, investigating an ongoing incident or scaling it out. You can use it free of charge as a traffic to Live Stream endpoint is not counted towards the bill. 

The feature is implemented in a NuGet `Microsoft.ApplicationInsights.PerfCounterCollector`. If you are using `ApplicationInsights.config` to configure monitoring you need to add a telemetry module and telemetry processor like you'd normally do:

``` xml
<TelemetryModules>
  <Add Type="Microsoft.ApplicationInsights.Extensibility.PerfCounterCollector.
    QuickPulse.QuickPulseTelemetryModule, Microsoft.AI.PerfCounterCollector"/>
</TelemetryModules>

<TelemetryProcessors>
  <Add Type="Microsoft.ApplicationInsights.Extensibility.PerfCounterCollector.
    QuickPulse.QuickPulseTelemetryProcessor, Microsoft.AI.PerfCounterCollector"/>
<TelemetryProcessors>
```

However simply adding them in code like you'd expect wouldn't work: 

``` csharp
TelemetryConfiguration configuration = new TelemetryConfiguration();
configuration.InstrumentationKey = "9d3ebb4f-7a11-4fb1-91ac-7ca8a17a27eb";

configuration.TelemetryProcessorChainBuilder
    .Use((next) => { return new QuickPulseTelemetryProcessor(next); })
    .Build();

var QuickPulse = new QuickPulseTelemetryModule();
QuickPulse.Initialize(configuration);
```

You need to "connect" module and processor. So you'd need to store the processor when constructing the chain and register it with the telemetry module. The code will look like this:

``` csharp
TelemetryConfiguration configuration = new TelemetryConfiguration();
configuration.InstrumentationKey = "9d3ebb4f-7a11-4fb1-91ac-7ca8a17a27eb";

QuickPulseTelemetryProcessor processor = null;

configuration.TelemetryProcessorChainBuilder
    .Use((next) =>
    {
        processor = new QuickPulseTelemetryProcessor(next);
        return processor;
    })
    .Build();

var QuickPulse = new QuickPulseTelemetryModule();
QuickPulse.Initialize(configuration);
QuickPulse.RegisterTelemetryProcessor(processor);
```

Now with the few lines of code you can start monitoring your application in real time for free. 