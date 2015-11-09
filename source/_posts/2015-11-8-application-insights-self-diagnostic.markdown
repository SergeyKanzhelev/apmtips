---
layout: post
title: "Application Insights self-diagnostics"
date: 2015-11-08 00:00:00 -0700
comments: true
categories:
- Application Insights
---
Each application insights component writes diagnostic information using [EventSource](http://blogs.msdn.com/b/vancem/archive/2012/07/09/logging-your-own-etw-events-in-c-system-diagnostics-tracing-eventsource.aspx).

If you see no data and you already checked that correct instrumentation key is specified you can try to use PerfView to see if there are problems with sending telemetry out (More about collecting Application Insights traces [here](http://sergeysharp.com/blog/2015/04/16/diagnostic-of-applicationinsights-sdk/).

But it may be so that Application Insights is partially functional: channel is working and sending telemetry out but not all events are delivered. For example, you configured custom counter but you do not see it. If counter is configured incorrectly ETW event will be logged and you will actually be able to find Application Insights trace telemetry it in your Search explorer:

{% img /images/2015-11-8-application-insights-self-diagnostic/SearchExplorer.PNG 'Application Insights diagnostic traces' %}

Why did you get this even as trace telemetry?

Application Insights Web nuget package adds [Diagnostics module](https://github.com/Microsoft/ApplicationInsights-dotnet/blob/master/src/Core/Managed/Shared/Extensibility/Implementation/Tracing/DiagnosticsTelemetryModule.cs) in the configuration file by default. This module subscribes to Application Insights diagnostic error events and sends them out to the same Application Insights resource that is used by your application. Diagnostics messages will be sent as trace telemetry and will have “AI:” or “AI Internal:” prefixes.

You can send Application Insights diagnostic messages to a different resource if you provide different instrumentation key for Diagnostics Module in your application insights configuration file:

``` xml
<Add Type="Microsoft.ApplicationInsights.Extensibility.Implementation.Tracing.DiagnosticsTelemetryModule, Microsoft.ApplicationInsights" >
	<DiagnosticsInstrumentationKey>YOUR_KEY_2</DiagnosticsInstrumentationKey>
</Add>
```
