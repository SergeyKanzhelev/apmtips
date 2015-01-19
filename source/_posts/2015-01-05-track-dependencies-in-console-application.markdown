---
layout: post
title: "track dependencies in console application"
date: 2015-01-05 20:28:50 +0200
comments: true
categories: 
- Application Insights
---
Dependencies tracking in Application Insights is powerful feature that allows to see what SQL and Http calls your application makes. I've [mentioned](/blog/2014/12/28/application-insights-extension-for-azure-websites/) that you need to install Status Monitor or Azure WebSites extension to enable it for your web application. I don't like magic and tools that configures something that I don't quite understand. I think most of developers and especially devops thinks the same way. Hopefully after this post you can better understand how this feature works and will trust it more.   

The main purpose of Status Monitor and Azure WebSites extension is to simplify Application Insights enablement for web applications. When you host your ASP.NET application in IIS or as Azure WebSite it has very predictable structure. So most of enablement steps can be automated. In this post I'll show how to enable dependencies tracking feature for console application manually so you know what Status Monitor and Azure WebSites extensions automation makes under the hood. You can apply similar steps for any other application type - be it Windows Service, Worker Role or anything else.  


Let's assume you just created a simple console application called "TestDependency.exe" in Visual Studio. As it tests dependencies tracking - I make a simple http call in a Main method of this application:

``` 
var request = HttpWebRequest.Create("http://bing.com");
var response = request.GetResponse();
using (var s = new StreamReader(response.GetResponseStream()))
{
    Console.WriteLine(s.ReadToEnd().Length);
}
Console.ReadLine();
```

Now you need to include and configure Application Insights for this application and then enable dependencies tracking feature. 


Install Application Insights
----------------------------

Every big feature in Application Insights is implemented in a separate nuget so you can choose what kind of monitoring you want to enable for your application. Dependencies tracking feature implemented in RuntimeTelemetry nuget package. So let's install it:

```
Install-Package Microsoft.ApplicationInsights.RuntimeTelemetry -Pre
```

Once installed new telemetry module will appear in ApplicationInsights.config. This telemetry module is responsible for dependencies tracking. We call it remote dependencies module:

``` 
<Add Type="Microsoft.ApplicationInsights.Extensibility.RuntimeTelemetry.RemoteDependencyModule, Microsoft.ApplicationInsights.Extensibility.RuntimeTelemetry"/>
```

Lastly, as it is a console application, you need to set instrumentation key [manually](/blog/2014/11/17/programmatically-set-instrumenttion-key/): 

``` 
TelemetryConfiguration.Active.InstrumentationKey = "ec126cb1-9adc-4681-9cd4-0fcad33511c9";
```

When you compile your application plenty of new files will appear in bin/Debug folder. You'll need to carry these files alongside with your application's binary when you'll deploying it. Here are the list of files you'll need for 0.12 version of Application Insights SDK.

Application Insights configuration:

``` 
ApplicationInsights.config
```

Application Insights Core and dependencies:

```
Microsoft.ApplicationInsights.dll
Microsoft.Diagnostics.Tracing.EventSource.dll
Microsoft.Threading.Tasks.dll
Microsoft.Threading.Tasks.Extensions.Desktop.dll
Microsoft.Threading.Tasks.Extensions.dll
```

Files responsible for dependencies tracking:

```
Microsoft.ApplicationInsights.Extensibility.RuntimeTelemetry.dll
Microsoft.ApplicationInsights.Extensions.Intercept_x64.dll
Microsoft.ApplicationInsights.Extensions.Intercept_x86.dll
Microsoft.Diagnostics.Instrumentation.Extensions.Intercept.dll
```

Small note here - you may notice that RuntimeTelemetry nuget has a dependency to another nuget that is hidden in nuget.org: "Microsoft.Diagnostics.Instrumentation.Extensions.Intercept". The only reason why it is hidden is that there is no reason to install it by itself, it only has utility features used by other Application Insights nugets.


Enable dependencies tracking feature
------------------------------------

Dependencies tracking feature is based on code instrumentation in runtime. Application Insights decorates every call to http or SQL with prefix and postfix callbacks. Timer starts in prefix callback and on postfix - all information regarding dependency call like url and duration being send to Application Insights service. The only way today to notify CLR (common language runtime) to allow code instrumentation is to set certain environment variables before you run your application. 

To enable dependencies tracking feature you should set these environment variables:

```
SET COR_ENABLE_PROFILING=1
SET COR_PROFILER={324F817A-7420-4E6D-B3C1-143FBED6D855}
SET MicrosoftInstrumentationEngine_Host={CA487940-57D2-10BF-11B2-A3AD5A13CBC0}
```

These variables tells CLR to load certain COM object as a "profiler". We call this object Runtime Instrumentation Agent as it's main purpose is to enable code instrumentation in runtime, without application re-compilation. Settings above will only work on machine where Status Monitor installed as GUIDs points to COM objects that should be registered on computer. 

If you are not a big fun of registering COM object (like me) - you can copy content of folder "%ProgramFiles%\Microsoft Application Insights\Runtime Instrumentation Agent" to any other folder, for instance output folder of your application: 

Surely you should tell CLR where to look for COM objects by specifying path to corresponding dlls:

```
SET COR_ENABLE_PROFILING=1
SET COR_PROFILER={324F817A-7420-4E6D-B3C1-143FBED6D855}
SET COR_PROFILER_PATH="folder"\x86\MicrosoftInstrumentationEngine_x86.dll
SET MicrosoftInstrumentationEngine_Host={CA487940-57D2-10BF-11B2-A3AD5A13CBC0}
SET MicrosoftInstrumentationEngine_HostPATH="folder"\x86\Microsoft.ApplicationInsights.ExtensionsHost_x86.dll
```

That's it. Just start console window, set environment variables and run your application. In my case [I see](/blog/2014/12/19/proxy-application-insights-events/) this dependency event being sent to Application Insights:

``` 
"ver":1,
"name":"Microsoft.ApplicationInsights.RemoteDependency",
"time":"2015-01-05T05:03:46.4427348+00:00",
"iKey":"ec126cb1-9adc-4681-9cd4-0fcad33511c9",
"device":{"id":"id is a required field for Microsoft.ApplicationInsights.Extensibility.Implementation.DeviceContext"},
"internal":{"sdkVersion":"0.12.0.17386","agentVersion":"0.12.0"},
"data": {
	"type":"Microsoft.ApplicationInsights.RemoteDependencyData",
 	"item":{
 		"ver":1,
 		"name":"http://bing.com/",
 		"kind":"Aggregation",
 		"value":592,
 		"count":1,
 		"dependencyKind":"HTTP",
 		"success":true,
 		"async":true,
 		"source":2,
 		"properties":{"DeveloperMode":"true"}
 	}
}
```

Looking at this JSON you see that we now send two versions - sdk version (0.12.0.17386) and agent version (0.12.0). Agent version here is a version of Runtime Instrumentation Agent.

Web applications and dependencies tracking
------------------------------------------

So what exactly Status Monitor and Azure WebSites extension are doing. 

Status Monitor:

1. Installs Runtime Instrumentation Agent binaries to %ProgramFiles%\Microsoft Application Insights\Runtime Instrumentation Agent
2. Registers binaries as COM objects. COM registration ensures that CLR will pick dll of the correct bittness as IIS may run in either.
3. Sets environment variables for IIS by setting registry keys HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\W3SVC\Environment and HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\WAS\Environment
4. Suggest to restart IIS to apply those environment variables

Azure WebSites extension:

1. Unpack Runtime Instrumentation Agent binaries to extension folder
2. Detects site bittness to set proper environment variables 
3. Set environment variables for IIS by [modifying applicationhost.config](http://blogs.msdn.com/b/waws/archive/2014/06/17/transform-your-microsoft-azure-web-site.aspx)

Note, in both cases environment variables are set globally for all applications. So Runtime Instrumentation Agent may work with different versions of Application Insight SDK even if they are loaded in a single process. Basically, the only purpose of it is to enable code injection by SDK. You can enable runtime instrumentation agent for any application and if this application is not using Application Insights - Runtime Instrumentation Agent will do nothing.
