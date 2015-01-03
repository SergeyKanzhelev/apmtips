---
layout: post
title: "Application Insights requests tracking - more than just a begin and end"
date: 2015-01-02 21:27:42 -0800
comments: true
categories: 
- Application Insights
---
I've already mentioned that Application Insights using [http modules to track requests data](/blog/2014/12/02/tracking-static-content-with-application-insights-httpmodule/). Tracking requests is actually quite straightforward task and can be easily implemented in couple lines of code on begin of request:

```
private static void BeginRequest(HttpContext ctx)
{
    var sw = new Stopwatch();
    sw.Start();
    ctx.Items["request-tracking-watch"] = sw;
}
```

and simple code on end of request:

```
private static void EndRequest(HttpContext ctx)
{
    var sw = (Stopwatch)ctx.Items["request-tracking-watch"];
    sw.Stop();
            
    RequestTelemetry rt = new RequestTelemetry(
        name: ctx.Request.Path,
        timestamp: DateTimeOffset.Now,
        duration: sw.Elapsed,
        responseCode: ctx.Response.StatusCode.ToString(),
        success: 200 == ctx.Response.StatusCode
    );
    rt.Url = ctx.Request.Url;
    rt.HttpMethod = ctx.Request.HttpMethod;

    TelemetryClient rtClient = new TelemetryClient();
    rtClient.TrackRequest(rt);
}
```

***Note:** we actually send request start time as a timestamp. In the code example above I simplified code a little bit and send end time as a timestamp.*

You can track requests from console application, worker role or OWIN middleware. It is easy and straightforward. However [Application Insights Web nuget](http://www.nuget.org/packages/Microsoft.ApplicationInsights.Web/) has more logic. Here is the list of ApplicationInsights.config settings controlling additional data collection (on the moment of this writing - version 0.12 of Application Insights SDK):
``` xml
<TelemetryModules>
  <Add Type="Microsoft.ApplicationInsights.Extensibility.Web.RequestTracking.TelemetryModules.WebRequestTrackingTelemetryModule, Microsoft.ApplicationInsights.Extensibility.Web" />
  <Add Type="Microsoft.ApplicationInsights.Extensibility.Web.RequestTracking.TelemetryModules.WebExceptionTrackingTelemetryModule, Microsoft.ApplicationInsights.Extensibility.Web" />
  <Add Type="Microsoft.ApplicationInsights.Extensibility.Web.RequestTracking.TelemetryModules.WebSessionTrackingTelemetryModule, Microsoft.ApplicationInsights.Extensibility.Web" />
  <Add Type="Microsoft.ApplicationInsights.Extensibility.Web.RequestTracking.TelemetryModules.WebUserTrackingTelemetryModule, Microsoft.ApplicationInsights.Extensibility.Web" />
  <Add Type="Microsoft.ApplicationInsights.Extensibility.Web.WebApplicationLifecycleModule, Microsoft.ApplicationInsights.Extensibility.Web" />
</TelemetryModules>
<TelemetryInitializers>
  <Add Type="Microsoft.ApplicationInsights.Extensibility.Web.TelemetryInitializers.WebOperationNameTelemetryInitializer, Microsoft.ApplicationInsights.Extensibility.Web" />
  <Add Type="Microsoft.ApplicationInsights.Extensibility.Web.TelemetryInitializers.WebOperationIdTelemetryInitializer, Microsoft.ApplicationInsights.Extensibility.Web" />
</TelemetryInitializers>

<ContextInitializers>
  <Add Type="Microsoft.ApplicationInsights.Extensibility.Web.AzureRoleEnvironmentContextInitializer, Microsoft.ApplicationInsights.Extensibility.Web" />
</ContextInitializers>
```

Here is a short overview of what else http module is doing under the hood and what kind of data is collected by these telemetry modules, context and telemetry initializers.

1. **Smart request name calculation** (WebRequestTrackingTelemetryModule). Request name is used to group and correlate requests in UI. For instance, you can see average duration grouped by request name. Or search traces and exceptions for "similar" requests where similar means the same name. That's why request name for MVC application is reported as "VERB Controller/Action" (for example "GET Home/Index"). It should not contain any unique identifiers, otherwise there will be too many groups in UI and it will be less usable.
2. **Track Operation ID for traces inside request**(WebOperationNameTelemetryInitializer & WebOperationIdTelemetryInitializer). I've already mentioned [default telemetry initializers that Web nuget installs](/blog/2014/12/01/telemetry-initializers/). These telemetry initializers ensures that all traces, events and dependencies will be associated with request they called from.
3. **Exceptions collection** (WebExceptionTrackingTelemetryModule). Application Insights http module attempts to collect exceptions happening in your application. I'm saying attempts as there are many cases when exceptions object will be cleared out by the moment http module's code executes. This [article](http://blogs.msdn.com/b/visualstudioalm/archive/2014/12/12/application-insights-exception-telemetry.aspx) shed some light on how to enhance exception collection logic for different technologies. 
4. **Track users of your application** (WebSessionTrackingTelemetryModule, WebUserTrackingTelemetryModule). Whenever Application Insights SDK get a request that doesn't have application insights user tracking cookie (set by Application Insights JS snippet) it will set this cookie and start a new session. Application Insights SDK sets cookies carefully so cacheability of ASP.NET pages wouldn't be broken. With user and session information you'll see usage charts even if your application is a REST service called via AJAX by another web application.
5. **Get azure role name for cloud services** (AzureRoleEnvironmentContextInitializer). When application initializes it attempts to get azure role name in case it is running on azure.
6. **Something else** (WebRequestTrackingTelemetryModule, WebApplicationLifecycleModule et al). There are some logic, specific to http modules and IIS implementation that helps us ensure the best data collection. For instance, when routing happening we making sure that you will get one request data item even if multiple handlers were executed and http module received multiple notifications. We also collect some diagnostics information in case something goes wrong and send it to the portal so you can take an action.

I plan to cover some of these data collection aspects in more details going forward. Please leave a comment if you have questions or want more information on a particular aspect of data collection. 

BTW, Application Insights will definitely support asp.net vNext so OWIN-based implementation of web requests tracking is on the way.
