---
layout: post
title: "How Application Insights Status Monitor DOES NOT monitor dependencies"
date: 2016-11-18 12:41:11 -0800
comments: true
aliases: [/blog/2016/11/18/how-application-insights-status-monitor-not-monitors-dependencies/]
categories: 
---
In this article I'll address the common misperception that Status Monitor collects telemetry. I'll show how it helps to collect (but not collects itself) application dependencies information.   

Application Insights [collects information about application dependencies](https://docs.microsoft.com/azure/application-insights/app-insights-asp-net-dependencies). Most of the time you don't need to do anything special to collect all outbound HTTP and SQL calls with the basic informaiton like URL and stored procedure name. Application Insights SDK will use the EventSource traces that .NET framework 4.6 emits.

However if you need more information about the dependencies like raw SQL statement we recommend to [install Status Monitor](https://docs.microsoft.com/azure/application-insights/app-insights-monitor-performance-live-website-now).

I created a [small demo application](https://github.com/SergeyKanzhelev/RTIA/) that shows how Status Monitor helps to collect dependencies. In this demo you can learn how to collect `SmtpMail.Send` method as an external dependency call.

The demo application doesn't use Status Monitor. Instead it downloads binaries distributed by Status Monitor as NuGet packages:

``` xml
<package id="Microsoft.ApplicationInsights.Agent_x64" version="2.0.5" />
<package id="Microsoft.ApplicationInsights.Agent_x86" version="2.0.5" />
```

Status Monitor will install the binaries (called Runtime Instrumentation Agent) from those NuGet packages into the folder `%ProgramFiles%\Microsoft Application Insights\Runtime Instrumentation Agent`. 

If you run this demo application from Visual Studio you'll get the message: `Please run this application using Startup.cmd script.`. 

Running the script will instruct .NET Framework to enable Runtime Instrumentation Agent for the current process. When you run the application using `Startup.cmd` script - you'll see the message `Application started with the Runtime Instrumentation Agent enabled. Press any key to continue...`. Looking into the code you may notice that the method `SmtpClient.Send` was already called by that moment. However as Status Monitor do NOT monitor dependencies - Runtime Instrumentation Agent did nothing when this call was made.

We want to report every call of the method `SmtpClient.Send` as a dependency call. We know what information to collect with that dependency call - mail subject, smtp host, etc. 

This is how to configure the monitoring. First - import another NuGet package:

``` xml
<package id="Microsoft.ApplicationInsights.Agent.Intercept" version="2.0.5" />
```

Second - call the method `Decorate` and pass the following method information - assembly name, module name and full method name. 

``` csharp
Decorator.InitializeExtension();
Functions.Decorate("System", "System.dll", "System.Net.Mail.SmtpClient.Send", 
    OnBegin, OnEnd, OnException, false);
```

You also need to pass three callbacks: 

``` csharp
public static object OnBegin(object thisObj, object arg1)
public static object OnEnd(object context, object returnValue, object thisObj, object arg1)
public static void OnException(object context, object exception, object thisObj, object arg1)
```

The call to `Decorate` will do the magic. It finds the method you specified and using the Runtime Instrumentation Agent inserts those callbacks into the beggining, end and in the global `try{}catch` statement of that method. This magic only allowed when Runtime Instrumentation Agent is enabled for the process.

In the callbacks implementation I [start the operation](https://github.com/SergeyKanzhelev/RTIA/blob/master/SimpleConsoleApp/Program.cs#L64) in `OnBegin` callback:

``` csharp
public static object OnBegin(object thisObj, object arg1)
{
    // start the operation
    var operation = new TelemetryClient().StartOperation<DependencyTelemetry>("Send");
    operation.Telemetry.Type = "Smtp";
    operation.Telemetry.Target = ((SmtpClient)thisObj).Host;
    if (arg1 != null)
    {
        operation.Telemetry.Data = ((MailMessage)arg1).Subject;
    }
    // save the operation in the local context
    return operation;    
}
```

And [stop operaiton](https://github.com/SergeyKanzhelev/RTIA/blob/master/SimpleConsoleApp/Program.cs#L97) in `OnEnd` and `OnException` callbacks:

``` csharp
public static void OnException(object context, object exception, object thisObj, object arg1)
{
    // mark operation as failed and stop it. Getting the operation from the context
    var operation = (IOperationHolder<DependencyTelemetry>)context;
    operation.Telemetry.Success = false;
    operation.Telemetry.ResultCode = exception.GetType().Name;
    new TelemetryClient().StopOperation(operation);
}
```

Notice the runtime arguments passed to the original method are used in those callbacks to collect information. Argument called `thisObj` is an instance of `SmtpClient` that made a call and `arg1` is a `MailMessage` that was passed as an argument.

So all the data collection logic is implemented in the application itself. Runtime Instrumentation Agent just provided a way to inject the callbacks into the methods of interest.

This is how Status Monitor helps to collect dependencies. During installation Status Monitor enables Runtime Instrumentation Agent for all IIS-based applications. Agent does nothing if application does not use Application Insights SDK. It has zero impact in the runtime. Only when Application Insights SDK is initialized - it can use Runtime Instrumentation Agent to monitor any methods it chooses. Status Monitor doesn't have information on what needs to be instrumented, what data should be collected and where this information have to be send. It all defined in code by Application Insights SDK.

This approach allows to version Application Insights SDK data collection logic without the need to re-install the agent. It also guarantees that the update of an agent will not change the way telemetry is being collected for your application. 

I'll describe other functions of Status Monitor in the next blog posts.

BTW, the same Runtime Instrumentation Agent is installed by [Microsoft Monitoring Agent](http://apmtips.com/blog/2015/09/11/operational-insights-agent-for-scom/) and Application Insights Azure Web App extension.
