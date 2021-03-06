---
layout: post
title: "Application Insights for MVC and Web API"
date: 2016-06-21 22:59:20 -0700
comments: true
aliases: [/blog/2016/06/21/application-insights-for-mvc-and-mvc-web-api/]
categories: 
---
Application Insights Web SDK today has a very basic support for MVC and Web API applications. In this post I collected some links on how to make monitoring of your applications better. This is not a definitive guide on how to monitor those types of applications correctly. This is just a dump of accumulated knowledge of some problems and their solutions.

##Telemetry correlation
This is how NuGet server implemented [OWIN middleware](https://github.com/NuGet/NuGet.Services.Metadata/pull/68/files) to track telemetry. It uses custom CallContext and time tracking. 

This [blog post](http://blog.marcinbudny.com/2016/04/application-insights-for-owin-based.html) suggests much better approach for telemetry correlation using the newest features of Application Insights SDK. Author also suggests the workaround for this [issue](https://katanaproject.codeplex.com/workitem/440?FocusElement=CommentTextBox) that looks very promising.  

##Use Action filters
Action filters can also be used for telemetry correlation. CallContext will not be lost when using action filters. However, timing of request will not be as accurate as when middleware being used.

##Exceptions
Exceptions are handled by MVC infrastracture and sometimes will not reach http module. Here is a documentation on how to configure exception handling in [different versions of MVC](https://azure.microsoft.com/en-us/documentation/articles/app-insights-asp-net-exceptions/#web-api-1x).

There is also an [ApplicationInsights.Helpers NuGet package](https://github.com/advancedrei/ApplicationInsights.Helpers/) that implements exception handling for MVC.

Exceptions thrown by middlewares should also be collected. Typically, you'd need a separate middleware to catch exceptions. You can find an explanation why there should be two middlewares at [Step 3 in this blog post](https://blogs.msdn.microsoft.com/webdev/2015/05/19/application-insights-for-asp-net-5-youre-in-control/). 

##Request names
I [mentioned before](http://apmtips.com/blog/2015/02/23/request-name-and-url/) that for [attribute-based routing](https://blogs.msdn.microsoft.com/webdev/2013/10/17/attribute-routing-in-asp-net-mvc-5/) operation names will have identifier in them and will not be groupable. I advice to set Route template as a request name:   

``` csharp
this.RequestContext.RouteData.Route.RouteTemplate
```

##Configuration file
In order to collect performance counters and dependencies as well as some other good features - you'd want to install [Windows Server nuget](https://www.nuget.org/packages/Microsoft.ApplicationInsights.WindowsServer/). This nuget will create and populate `ApplicationInsights.config` file. So most of monitoring configuration will be defined in that configuration file. However  if you'd like to use code-based configuration approach and dependency injection - you'll need to remove this file after every nuget update.


##Singleton and DI
When using dependency injection to inject `TelemetryConfiguration` and `TelemetryClient` classes - singleton `TelemetryConfiguration.Active` will not be initialized. Or even worse - will be initialized with some unexpected values. Thus the code from documentation will not send event:

``` csharp
var client = new TelemetryClient();
client.TrackEvent("purchase completed");
```

[This](https://github.com/Microsoft/ApplicationInsights-aspnetcore/blob/master/src/Microsoft.ApplicationInsights.AspNetCore/Extensions/ApplicationInsightsExtensions.cs#L72) is how we solved it in ASP.NET core. We take configuration from Application Insights's singleton and use it as DI singleton. 

Another [issue](http://apmtips.com/blog/2015/06/09/do-not-use-context-initializers/#comment-2740137715) with the dependency injection is that identity provider can only be obtained using DI. It is not that easy to create a `TelemetryInitializer` that will be instantiated on every request by DI. Application Insights has it's own mechanism of initializing and do not have a native mechanism to create a list of telemetry initializers per request.

#Bugs
There are some bugs I cannot explain today. There are reports that sometimes request name has a mystery \[id\] in it. For instance, request to this controller will be reported as *POST MyController \[id\]*: 

``` csharp
    public class MyController : ApiController
    {
        public async Task<HttpResponseMessage> Post(HttpRequestMessage request)
```

Looking at how [request name generated](https://github.com/Microsoft/ApplicationInsights-dotnet-server/blob/master/Src/Web/Web.Shared.Net/Implementation/RequestTrackingExtensions.cs#L75) I cannot explain it.
