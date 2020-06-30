---
layout: post
title: "WebApi tracing powered by ApplicationInsights in Visual Studio 2015 Update 1"
date: 2016-01-06 00:00:00 -0700
comments: true
aliases: [/blog/2016/01/06/webapi-tracing-powered-by-ai-in-vs2015-update1/]
categories:
- Application Insights
- WebApi
- Tracing
- VisualStudio 2015
---

*This blog post was written by Anastasia Baranchenkova*

In **Visual Studio 2015 Update 1** Application Insights telemetry is available right from the Visual Studio. And you can even get it without providing a valid instrumentation  key.

I created a sample application that I describe in details later on. In this application I forward WebApi framework traces to Application Insights (it is a similar thing that SergeyK described in one of his previous posts but it is done differently: by implementing `ITraceWriter` interface).

Full sample is [here]( https://github.com/Microsoft/ApplicationInsights-Home/tree/master/Samples/WebApiTracingSample).

So if you start debugging web hosted WebApi application even if you do not provide instrumentation key you can see all the traces rights in your Diagnostics Tools window. You can search there, filter and see actual json file that would have been sent if you provided a valid instrumentation key:
![Application Insights exception in the Diagnostics Tools hub](/images/2016-01-06-webapi-tracing-powered-by-ai-in-vs2015-update1/DiagnosticToolsView_1.PNG)

![Application Insights trace in the Diagnostics Tools window](/images/2016-01-06-webapi-tracing-powered-by-ai-in-vs2015-update1/DiagnosticToolsView_2.PNG)

For self-hosted WebApi applications you would need to configure ApplicationInsights providing a valid instrumentation key because Diagnostics Tools hub does not currently support this type of application. But you still can see all the telemetry from the VS itself. For that you need to open: **View ->Other Windows->Application Insights Search**. From there you connect to your Azure Subscription and get back all the telemetry. You can select different time intervals, filter by type or property values and see each telemetry item details:

![Application Insights Search windows](/images/2016-01-06-webapi-tracing-powered-by-ai-in-vs2015-update1/VSSearch.PNG)

And now I want to describe in details how you can forward WebApi traces to ApplicationInsigts to get all this beauty. 


##WebApi web-hosted application##
1.	Create WebApi web hosted application. If you have Azure subscription check “Add ApplicationInsights to project”.
2.	If you did not add ApplicationInsights on application creation then add the latest [Application Insights for Web](http://www.nuget.org/packages/Microsoft.ApplicationInsights.Web/) nuget through nugget package manager. (In this case you do not have instrumentation key in the ApplicationInsights configuration file and no data will be sent to the portal but you can add it that later and for debugging purposes you have all you need)
3.	Add [Microsoft.AspNet.WebApi.Tracing]( http://www.nuget.org/packages/Microsoft.AspNet.WebApi.Tracing/) nuget package.
4.	Add [ApplicationInsightsTraceWriter.cs]( https://github.com/Microsoft/ApplicationInsights-Home/blob/master/Samples/WebApiTracingSample/WebHostedWebApiApplication/_TRACING_/ApplicationInsightsTraceWriter.cs)

`ApplicationInsightsTraceWriter` implements `System.Web.Http.Tracing.ITraceWriter`.
Method `Trace` gets trace message parameters and converts it to ApplicationInsights trace or exception.

```
internal sealed class ApplicationInsightsTraceWriter : ITraceWriter
{
	public void Trace(HttpRequestMessage request, string category, TraceLevel level, Action<TraceRecord> traceAction)
    {
		…
		message = this.systemDiagnosticsTraceWriter.Format(traceRecord);
		this.client.TrackTrace(message, GetSeverityLevel(level));
	}
}
```

5.	Add [CompositTraceWriter.cs]( https://github.com/Microsoft/ApplicationInsights-Home/blob/master/Samples/WebApiTracingSample/WebHostedWebApiApplication/_TRACING_/CompositTraceWriter.cs)

`CompositTraceWriter` also implements `ITraceWriter` and is used in case if some other `ITraceWriter` is already registered by the application so that `ApplicationInsightsTraceWriter` does not replace existing but rather is added to the list of trace writers.

6.	Add [Extensions.cs]( https://github.com/Microsoft/ApplicationInsights-Home/blob/master/Samples/WebApiTracingSample/WebHostedWebApiApplication/_TRACING_/Extensions.cs)	  

This class adds `HttpConfiguration.EnableApplicationInsights` extension method that registers `ApplicationInsightsTraceWriter`.

```
	writer = new ApplicationInsightsTraceWriter();
	configuration.Services.Replace(typeof(ITraceWriter), writer);   
```

7.	In [Global.asax]( https://github.com/Microsoft/ApplicationInsights-Home/blob/master/Samples/WebApiTracingSample/WebHostedWebApiApplication/Global.asax.cs) add
`GlobalConfiguration.Configuration.EnableApplicationInsights();`

##WebApi self-hosted application##
For a self-hosted application you will do almost the same but

1.	Instead of Web nuget package add [ApplicationInsights API]( http://www.nuget.org/packages/Microsoft.ApplicationInsights/) nuget
2.	Create application insights resource manually through the portal and set instrumentation key programmatically
```
TelemetryConfiguration.Active.InstrumentationKey = “MyKey”;
```
3.	Call `config.EnableApplicationInsights()` from [Startup.Configuration]( https://github.com/Microsoft/ApplicationInsights-Home/blob/master/Samples/WebApiTracingSample/SelfHostedWebApiApplication/Startup.cs) where config would be an instance of HttpConfiguration that you create in this method for other registration purposes.


I would highly encourage to also read this [blog post]( http://blogs.msdn.com/b/roncain/archive/2012/04/12/tracing-in-asp-net-web-api.aspx) that explains how and when to use WebApi tracing. The example above demonstrates basic integration points while in the article above you can find detailed information on the best practices of how to use WebApi tracing. 