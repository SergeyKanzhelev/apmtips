---
layout: post
title: "Programmatically set instrumenttion key"
date: 2014-11-17 14:52:51 -0800
comments: true
categories: 
- Application Insights
---
As telemetry became a part of engineering process I hear one question more and more often - how can I separate events reported during development from data collected from production deployment. There are ways to 

You have couple options here. Most straightforward option is to configure your build script to change Instrumentaiton 

``` xml
<!-- This key is for Application Insights resource 'WebApplication1' in resource group 'Default-ApplicationInsights-CentralUS' -->
<InstrumentationKey>d682075e-c621-4fa0-a55e-f3df017f0e15</InstrumentationKey>
```

Set instrumentation key for default configuration. The best place to do it for web applicaiton is Global.asax:
``` csharp
Microsoft.ApplicationInsights.Extensibility.TelemetryConfiguration.Active.InstrumentationKey = "d682075e-c621-4fa0-a55e-f3df017f0e15";
```

Set for certain telemetry client:
``` csharp
TelemetryClient tc = new TelemetryClient();
tc.Context.InstrumentationKey = "d682075e-c621-4fa0-a55e-f3df017f0e15";
```

Set for specific data item:
``` csharp
Microsoft.ApplicationInsights.DataContracts.EventTelemetry evt = new Microsoft.ApplicationInsights.DataContracts.EventTelemetry();
evt.Context.InstrumentationKey = "d682075e-c621-4fa0-a55e-f3df017f0e15";
```
