---
layout: post
title: "Performance Counters Today"
date: 2016-08-02 21:56:12 -0700
comments: true
aliases: [/blog/2016/08/02/performance-counters-today/]
categories: 
published: false
---

How do you use performance counters today? 

Application Insights collects application centric telemetry to help monitor and troubleshoot issues in production.

Key health characteristics like machine CPU and RAM, process CPU, memory and IO, CLR total exceptions count and web application characteristics - requests rate and execution time as well as a incoming requests queue size. All these characteristics are tight to the current application as described in one of my [previous blogs](/blog/2015/10/07/performance-counters-in-non-web-applications/). 



          "name": "Process(APP_WIN_PROC) - Processor Time",

``` java
private static final String REQUEST_COUNT_PC_CATEGORY_NAME = "ASP.NET Applications";
```

https://github.com/Microsoft/ApplicationInsights-Java/blob/66c798e8fe2d4d36058ead2468b46a31428a9854/web/src/main/java/com/microsoft/applicationinsights/web/internal/perfcounter/DefaultWebPerformanceCountersFactory.java#L14







Let's take an example of Service Fabric. 
https://azure.microsoft.com/en-us/documentation/articles/service-fabric-reliable-actors-diagnostics/#performance-counters

```
ivoicemailboxactor.leavemessageasync_2_89383d32-e57e-4a9b-a6ad-57c6792aa521_635650083804480486
```

https://www.simple-talk.com/dotnet/net-performance/building-performance-metrics-into-asp-net-mvc-applications/


https://github.com/SignalR/SignalR/blob/799d9bc32524066344cb3656e5f28f2fd03ba9b3/src/Microsoft.AspNet.SignalR.Core/Owin/OwinExtensions.cs#L193


https://msdn.microsoft.com/en-us/library/ms804008.aspx

```
performanceCounters/processorPercentage
performanceCounters/availableMemory

performanceCounters/processCpuPercentage
performanceCounters/processPrivateBytes
performanceCounters/processIORate

performanceCounters/exceptionRate

performanceCounters/requestExecutionTime
performanceCounters/requestRate
performanceCounters/requestQueueDepth
```


``` xml
<Counters>
    <Add PerformanceCounter="\Processor(_Total)\% Processor Time" />
    <Add PerformanceCounter="\Memory\Available Bytes" />

    <Add PerformanceCounter="\Process(??APP_WIN32_PROC??)\% Processor Time"/>
    <Add PerformanceCounter="\Process(??APP_WIN32_PROC??)\Private Bytes" />
    <Add PerformanceCounter="\Process(??APP_WIN32_PROC??)\IO Data Bytes/sec" />

    <Add PerformanceCounter="\.NET CLR Exceptions(??APP_CLR_PROC??)\# of Exceps Thrown / sec" />

    <Add PerformanceCounter="\ASP.NET Applications(??APP_W3SVC_PROC??)\Requests/Sec" />
    <Add PerformanceCounter="\ASP.NET Applications(??APP_W3SVC_PROC??)\Request Execution Time" />
    <Add PerformanceCounter="\ASP.NET Applications(??APP_W3SVC_PROC??)\Requests In Application Queue" />
</Counters>
```

https://msdn.microsoft.com/en-us/library/ms972959.aspx
