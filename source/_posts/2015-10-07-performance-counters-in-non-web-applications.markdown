---
layout: post
title: "Performance Counters in non-web applications"
date: 2015-10-07 08:43:49 -0700
comments: true
categories: 
---
This post shows how to collect Performance Counters for the desktop application and features the answer to the questions:

{% blockquote %}
There is no more ``TelemetryModules`` collection in ``TelemetryConfiguration`` class. where should I store my telemetry modules?
{% endblockquote %}

##Step 1
Install [NuGet package](https://www.nuget.org/packages/Microsoft.ApplicationInsights.PerfCounterCollector/1.2.1).

```
Install-Package Microsoft.ApplicationInsights.PerfCounterCollector
```

##Step 2
NuGet will create an ```ApplicationInsights.config``` file. If you don't use it (and you probably don't use it for desktop applications) - remove this file.

##Step 3
Define global variable that will live for a lifetime of an applicaiton, instantiate it, populate the list of counters and call ```Initialize``` method:

``` csharp
class Program
{
    private PerformanceCollectorModule perfCollectorModule;

    static void Main(string[] args)
    {
        TelemetryConfiguration.Active.InstrumentationKey = "Foo";

        var perfCounterCollectorModule = new PerformanceCollectorModule();
        perfCounterCollectorModule.Counters.Add(
			new PerformanceCounterCollectionRequest(
				@"\.NET CLR Memory(??APP_CLR_PROC??)\# GC Handles", "GC Handles"));
        perfCounterCollectorModule.Initialize(TelemetryConfiguration.Active);
```

##Step 4
In order to collect counters for the current process - you should use ```??APP_CLR_PROC??``` for CLR counters and ```??APP_WIN32_PROC??``` for windows counters. Typically counter instances will be named after process name. However in case of multiple instances of the process running you will have names like ```w3wp#3``` representing third instance of the ```w3wp.exe``` process.

This indeces in instance names will change over time. For example, when process ```w3wp#2``` will finish, ```w3wp#3``` will become ```w3wp#2```. Moreover, instance name for CLR counters is different than for windows counter as CLR counters only count processes that runs .NET code inside.

So ```PerfCounterCollector``` will regularly check the mapping between the instance name and process ID using counters: ```\.NET CLR Memory(*)\Process ID``` for managed counters and ```Process(*)\ID Process``` for windows counters is you are using keywords ```??APP_CLR_PROC??``` and ```??APP_WIN32_PROC??``` as instance names. 
 
 
##Step 5
You are all set. Counter will be sent to the portal every minute.

Custom counters will be sent as metrics:

``` json
{
  "name": "Microsoft.ApplicationInsights.foo.Metric",
  "time": "2015-10-07T08:22:20.6783162-07:00",
  "iKey": "Foo",
  "tags": { "ai.internal.sdkVersion": "1.2.0.5639" },
  "data": {
    "baseType": "MetricData",
    "baseData": {
      "ver": 2,
      "metrics": [
        {
          "name": "GC Handles",
          "kind": "Measurement",
          "value": 123
        }
      ],
      "properties": {
        "CounterInstanceName": "TestPerfCounters.vshost",
        "CustomPerfCounter": "true"
      }
    }
  }
}
```

Standard perofrmance counters will be sent as performance counters:

``` json
{
  "name": "Microsoft.ApplicationInsights.foo.PerformanceCounter",
  "time": "2015-10-07T08:22:20.6464765-07:00",
  "iKey": "Foo",
  "tags": { "ai.internal.sdkVersion": "1.2.0.5639" },
  "data": {
    "baseType": "PerformanceCounterData",
    "baseData": {
      "ver": 2,
      "categoryName": "Process",
      "counterName": "% Processor Time",
      "instanceName": "TestPerfCounters.vshost",
      "value": 20.0318031311035
    }
  }
}
``` 

For web applications you can configure the list of performance counters to monitor using [configuration file](https://azure.microsoft.com/documentation/articles/app-insights-configuration-with-applicationinsights-config/).

Note, that for SDK to collect counters identity application is running under should be part of the group ```Performance Monitor Users```.