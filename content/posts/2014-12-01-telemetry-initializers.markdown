---
layout: post
title: "Telemetry Initializers"
date: 2014-12-01 21:07:47 -0800
comments: true
aliases: [/blog/2014/12/01/telemetry-initializers/]
published: true
categories: 
---
Application Insights .NET SDK has number of extensibility points. One of them is called telemetry initializer. Telemetry initializer is a class implementing ITelemetryInitializer interface. The only method of this interface "Initialize" is called whenever a TraceFoo method is called for one of telemetry data items (Event, Metric, Request, Exception, etc.).

The Application Insights web SDK comes with two default telemetry initializers - web operation name and Id initializers:
``` xml
<TelemetryInitializers>
  <Add Type="Microsoft.ApplicationInsights.Extensibility.Web.TelemetryInitializers.WebOperationNameTelemetryInitializer, Microsoft.ApplicationInsights.Extensibility.Web" />
  <Add Type="Microsoft.ApplicationInsights.Extensibility.Web.TelemetryInitializers.WebOperationIdTelemetryInitializer, Microsoft.ApplicationInsights.Extensibility.Web" />
</TelemetryInitializers>
```
These initializers are used to mark every collected telemetry item with the current web request identity so that traces and exception can be correlated to corresponding requests:

{% img /images/2014-12-01-telemetry-initializers/trace-for-request.png 'trace for request' %}

The trace telemetry in this example, has the following context populated by telemetry initializers mentioned above: 
``` json
"operation":{"id":"1940098063557174680","name":"GET Home/Index"}
```
It is easy to implement your own telemetry initializer. Say, you want to mark every telemetry data item with [ETW ActivityID](http://msdn.microsoft.com/en-us/library/system.diagnostics.tracing.eventsource.currentthreadactivityid.aspx) and [System.Diagnostics ActivityID](http://msdn.microsoft.com/en-us/library/system.diagnostics.correlationmanager.activityid.aspx). To do this, first, you create a class that implements the ITelemetryInitializer interface. In the interface's Initialize method you can fill out telemetry data item properties:
```
namespace ApmTips.Tools
{
    using Microsoft.ApplicationInsights.Extensibility;
    using Microsoft.Diagnostics.Tracing;
    using System.Diagnostics;

    public class ExtendedIDTelemetryInitializer : ITelemetryInitializer
    {
        public void Initialize(Microsoft.ApplicationInsights.Channel.ITelemetry telemetry)
        {
            telemetry.Context.Properties["ETW.ActivityID"] = EventSource.CurrentThreadActivityId.ToString();
            telemetry.Context.Properties["E2ETrace.ActivityID"] = Trace.CorrelationManager.ActivityId.ToString();
        }
    }
}
```
You then need to register your telemetry initializer using one of the following two options:
Adding it to ApplicationInsights.config file:
``` xml
<TelemetryInitializers>
  <Add Type="ApmTips.Tools.ExtendedIDTelemetryInitializer, ApmTips.Tools" />
</TelemetryInitializers>
```
or programmatically:

``` csharp
Microsoft.ApplicationInsights.Extensibility.TelemetryConfiguration.Active.TelemetryInitializers.Add(new ExtendedIDTelemetryInitializer());
```
This is what every data item will be marked with after you start your application with the new telemetry initializer configured:
``` json
"properties":{"ETW.ActivityID":"00000000-0000-0000-0000-000000000000","E2ETrace.ActivityID":"00000000-0000-0000-0700-0080000000f9"}
```

And here is how it looks like in UI:

{% img /images/2014-12-01-telemetry-initializers/new-properties.png 'new properties' %}

Telemetry initializers are a powerful, but dangerous tool. They are called synchronously and block program execution flow; if written poorly they can harm application performance.

The following example demonstrates synchronous execution of telemetry initializers. It traces every telemetry initializer into the file with the stack trace where telemetry data item was created from:
```csharp
namespace ApmTips.Tools
{
    using Microsoft.ApplicationInsights.Extensibility;
    using System;
    using System.Diagnostics;
    using System.IO;

    public class DiagnosticsTraceTelemetryInitializer : ITelemetryInitializer
    {
        public void Initialize(Microsoft.ApplicationInsights.Channel.ITelemetry telemetry)
        {
            var stack = new StackTrace();

            using (StreamWriter sw = new StreamWriter(Environment.ExpandEnvironmentVariables("%tmp%\\ai-log.txt"), true))
            {
                sw.WriteLine(telemetry.GetType().Name + " was traced");
                sw.WriteLine(" from " + stack.ToString());
            }
        }
    }
}
```

Here is the output this telemetry initializer generates for a single request with Trace statement in controller. You can see that the Trace.Write method was called from the home controller (WebApplication3.Controllers.HomeController.Index). This in turn called the Application Insights trace listener which finally called Track method and our telemetry initializer:
```
TraceTelemetry was traced from
   at ApmTips.Tools.DiagnosticsTraceTelemetryInitializer.Initialize(ITelemetry telemetry)
   at Microsoft.ApplicationInsights.TelemetryClient.Track(ITelemetry telemetry)
   at Microsoft.ApplicationInsights.TraceListener.ApplicationInsightsTraceListener.Write(String message)
   at System.Diagnostics.TraceInternal.Write(String message)
   at System.Diagnostics.Trace.Write(String message)
   at WebApplication3.Controllers.HomeController.Index()
   at lambda_method(Closure , ControllerBase , Object[] )
   at System.Web.Mvc.ActionMethodDispatcher.Execute(ControllerBase controller, Object[] parameters)
   at System.Web.Mvc.ReflectedActionDescriptor.Execute(ControllerContext controllerContext, IDictionary`2 parameters)
   at System.Web.Mvc.ControllerActionInvoker.InvokeActionMethod(ControllerContext controllerContext, ActionDescriptor actionDescriptor, IDictionary`2 parameters)
   at System.Web.Mvc.Async.AsyncControllerActionInvoker.ActionInvocation.InvokeSynchronousActionMethod()
   at System.Web.Mvc.Async.AsyncControllerActionInvoker.<BeginInvokeSynchronousActionMethod>b__39(IAsyncResult asyncResult, ActionInvocation innerInvokeState)
   at System.Web.Mvc.Async.AsyncResultWrapper.WrappedAsyncResult`2.CallEndDelegate(IAsyncResult asyncResult)
   at System.Web.Mvc.Async.AsyncResultWrapper.WrappedAsyncResultBase`1.End()
   at System.Web.Mvc.Async.AsyncResultWrapper.End[TResult](IAsyncResult asyncResult, Object tag)
   at System.Web.Mvc.Async.AsyncControllerActionInvoker.EndInvokeActionMethod(IAsyncResult asyncResult)
   at System.Web.Mvc.Async.AsyncControllerActionInvoker.AsyncInvocationWithFilters.<InvokeActionMethodFilterAsynchronouslyRecursive>b__3d()
   at System.Web.Mvc.Async.AsyncControllerActionInvoker.AsyncInvocationWithFilters.<>c__DisplayClass46.<InvokeActionMethodFilterAsynchronouslyRecursive>b__3f()
   at System.Web.Mvc.Async.AsyncControllerActionInvoker.<>c__DisplayClass33.<BeginInvokeActionMethodWithFilters>b__32(IAsyncResult asyncResult)
   at System.Web.Mvc.Async.AsyncResultWrapper.WrappedAsyncResult`1.CallEndDelegate(IAsyncResult asyncResult)
   at System.Web.Mvc.Async.AsyncResultWrapper.WrappedAsyncResultBase`1.End()
   at System.Web.Mvc.Async.AsyncResultWrapper.End[TResult](IAsyncResult asyncResult, Object tag)
   at System.Web.Mvc.Async.AsyncControllerActionInvoker.EndInvokeActionMethodWithFilters(IAsyncResult asyncResult)
   at System.Web.Mvc.Async.AsyncControllerActionInvoker.<>c__DisplayClass21.<>c__DisplayClass2b.<BeginInvokeAction>b__1c()
   at System.Web.Mvc.Async.AsyncControllerActionInvoker.<>c__DisplayClass21.<BeginInvokeAction>b__1e(IAsyncResult asyncResult)
   at System.Web.Mvc.Async.AsyncResultWrapper.WrappedAsyncResult`1.CallEndDelegate(IAsyncResult asyncResult)
   at System.Web.Mvc.Async.AsyncResultWrapper.WrappedAsyncResultBase`1.End()
   at System.Web.Mvc.Async.AsyncResultWrapper.End[TResult](IAsyncResult asyncResult, Object tag)
   at System.Web.Mvc.Async.AsyncControllerActionInvoker.EndInvokeAction(IAsyncResult asyncResult)
   at System.Web.Mvc.Controller.<BeginExecuteCore>b__1d(IAsyncResult asyncResult, ExecuteCoreState innerState)
   at System.Web.Mvc.Async.AsyncResultWrapper.WrappedAsyncVoid`1.CallEndDelegate(IAsyncResult asyncResult)
   at System.Web.Mvc.Async.AsyncResultWrapper.WrappedAsyncResultBase`1.End()
   at System.Web.Mvc.Async.AsyncResultWrapper.End[TResult](IAsyncResult asyncResult, Object tag)
   at System.Web.Mvc.Async.AsyncResultWrapper.End(IAsyncResult asyncResult, Object tag)
   at System.Web.Mvc.Controller.EndExecuteCore(IAsyncResult asyncResult)
   at System.Web.Mvc.Controller.<BeginExecute>b__15(IAsyncResult asyncResult, Controller controller)
   at System.Web.Mvc.Async.AsyncResultWrapper.WrappedAsyncVoid`1.CallEndDelegate(IAsyncResult asyncResult)
   at System.Web.Mvc.Async.AsyncResultWrapper.WrappedAsyncResultBase`1.End()
   at System.Web.Mvc.Async.AsyncResultWrapper.End[TResult](IAsyncResult asyncResult, Object tag)
   at System.Web.Mvc.Async.AsyncResultWrapper.End(IAsyncResult asyncResult, Object tag)
   at System.Web.Mvc.Controller.EndExecute(IAsyncResult asyncResult)
   at System.Web.Mvc.Controller.System.Web.Mvc.Async.IAsyncController.EndExecute(IAsyncResult asyncResult)
   at System.Web.Mvc.MvcHandler.<BeginProcessRequest>b__5(IAsyncResult asyncResult, ProcessRequestState innerState)
   at System.Web.Mvc.Async.AsyncResultWrapper.WrappedAsyncVoid`1.CallEndDelegate(IAsyncResult asyncResult)
   at System.Web.Mvc.Async.AsyncResultWrapper.WrappedAsyncResultBase`1.End()
   at System.Web.Mvc.Async.AsyncResultWrapper.End[TResult](IAsyncResult asyncResult, Object tag)
   at System.Web.Mvc.Async.AsyncResultWrapper.End(IAsyncResult asyncResult, Object tag)
   at System.Web.Mvc.MvcHandler.EndProcessRequest(IAsyncResult asyncResult)
   at System.Web.Mvc.MvcHandler.System.Web.IHttpAsyncHandler.EndProcessRequest(IAsyncResult result)
   at System.Web.HttpApplication.CallHandlerExecutionStep.System.Web.HttpApplication.IExecutionStep.Execute()
   at System.Web.HttpApplication.ExecuteStep(IExecutionStep step, Boolean& completedSynchronously)
   at System.Web.HttpApplication.PipelineStepManager.ResumeSteps(Exception error)
   at System.Web.HttpApplication.BeginProcessRequestNotification(HttpContext context, AsyncCallback cb)
   at System.Web.HttpRuntime.ProcessRequestNotificationPrivate(IIS7WorkerRequest wr, HttpContext context)
   at System.Web.Hosting.PipelineRuntime.ProcessRequestNotificationHelper(IntPtr rootedObjectsPointer, IntPtr nativeRequestContext, IntPtr moduleData, Int32 flags)
   at System.Web.Hosting.PipelineRuntime.ProcessRequestNotification(IntPtr rootedObjectsPointer, IntPtr nativeRequestContext, IntPtr moduleData, Int32 flags)
   at System.Web.Hosting.UnsafeIISMethods.MgdIndicateCompletion(IntPtr pHandler, RequestNotificationStatus& notificationStatus)
   at System.Web.Hosting.PipelineRuntime.ProcessRequestNotificationHelper(IntPtr rootedObjectsPointer, IntPtr nativeRequestContext, IntPtr moduleData, Int32 flags)
   at System.Web.Hosting.PipelineRuntime.ProcessRequestNotification(IntPtr rootedObjectsPointer, IntPtr nativeRequestContext, IntPtr moduleData, Int32 flags)

RequestTelemetry was traced from
   at ApmTips.Tools.DiagnosticsTraceTelemetryInitializer.Initialize(ITelemetry telemetry)
   at Microsoft.ApplicationInsights.TelemetryClient.Track(ITelemetry telemetry)
   at Microsoft.ApplicationInsights.Extensibility.Web.RequestTracking.TelemetryModules.WebRequestTrackingTelemetryModule.OnEndRequest(RequestTelemetryContext state, HttpContext platformContext)
   at Microsoft.ApplicationInsights.Extensibility.Web.RequestTracking.WebPlatformModuleAdapter.ExecuteStepExceptionSafe[TX,TY](String stageName, Action`2 stage, TX state, TY platfromContext)
   at Microsoft.ApplicationInsights.Extensibility.Web.RequestTracking.WebPlatformModuleAdapter.OnEndRequest(HttpContext platformContext)
   at Microsoft.ApplicationInsights.Extensibility.Web.RequestTracking.WebRequestTrackingModule.OnCallbackExceptionSafe(String callbackName, HttpContext platformContext, Action`1 action)
   at Microsoft.ApplicationInsights.Extensibility.Web.RequestTracking.WebRequestTrackingModule.OnEndRequest(Object sender, EventArgs eventArgs)
   at System.Web.HttpApplication.SyncEventExecutionStep.System.Web.HttpApplication.IExecutionStep.Execute()
   at System.Web.HttpApplication.ExecuteStep(IExecutionStep step, Boolean& completedSynchronously)
   at System.Web.HttpApplication.PipelineStepManager.ResumeSteps(Exception error)
   at System.Web.HttpApplication.BeginProcessRequestNotification(HttpContext context, AsyncCallback cb)
   at System.Web.HttpRuntime.ProcessRequestNotificationPrivate(IIS7WorkerRequest wr, HttpContext context)
   at System.Web.Hosting.PipelineRuntime.ProcessRequestNotificationHelper(IntPtr rootedObjectsPointer, IntPtr nativeRequestContext, IntPtr moduleData, Int32 flags)
   at System.Web.Hosting.PipelineRuntime.ProcessRequestNotification(IntPtr rootedObjectsPointer, IntPtr nativeRequestContext, IntPtr moduleData, Int32 flags)
   at System.Web.Hosting.UnsafeIISMethods.MgdIndicateCompletion(IntPtr pHandler, RequestNotificationStatus& notificationStatus)
   at System.Web.Hosting.PipelineRuntime.ProcessRequestNotificationHelper(IntPtr rootedObjectsPointer, IntPtr nativeRequestContext, IntPtr moduleData, Int32 flags)
   at System.Web.Hosting.PipelineRuntime.ProcessRequestNotification(IntPtr rootedObjectsPointer, IntPtr nativeRequestContext, IntPtr moduleData, Int32 flags)

```
Use telemetry initializers wisely for properties that changes from one data item to another. There are other mechanisms to set global properties that will have the same value for all data items in the process.
