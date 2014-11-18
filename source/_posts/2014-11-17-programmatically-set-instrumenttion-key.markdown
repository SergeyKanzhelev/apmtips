---
layout: post
title: "Programmatically set instrumenttion key"
date: 2014-11-17 14:52:51 -0800
comments: true
categories: 
- Application Insights
---
As telemetry became a part of engineering process I hear one question more and more often - how can I separate events reported during development from data collected from production deployment? How can I limit access to data and integrate telemetry into my continues integration infrastracture? How can I separate events from staging and production, from different versions of applciaiton, from different components inside the applicaiton? 

Well, nobody knows the answer better then you. Applicaiton Telemetry SDK is flexible and gives you full controls over data and configure data collection the way you need it. There are couple ways to slice your data. In this article I'll explain how to separate telemetry data by sending it to different components. 

Every component in Applicaiton Insights is represented by a single Instrumentation Key. You can get it in "properties" section of your component:
{% img /images/2014-11-17-programmatically-set-instrumenttion-key/getinstrumentationkey.png 'Get instrumentation key in the portal' %}

Easiest way to configure instrumentation key is to set it in ApplicaitonInsights.config. Whenever Applicaiton Insights will need to send data for the first time it will attempt to read instrumentation key from this config file. You can use TransformXml msbuild task to [automate the release pipeline](http://msdn.microsoft.com/en-us/library/dn449951.aspx). Here is config snippet you need to modify: 
``` xml
<InstrumentationKey>ec126cb1-9adc-4681-9cd4-0fcad33511c9</InstrumentationKey>
```
However this approach is not working well with some deployments. You may already have distributed configuration management system in place. One example may be Azure Cloud Services where you may prefer to store instrumentation key in [cscfg file](http://azure.microsoft.com/en-us/documentation/articles/cloud-services-how-to-configure/). In this case you can leave InstrumentationKey section of ApplicaitonInsights.config file blank and set it programmatically:
``` csharp
TelemetryConfiguration.Active.InstrumentationKey = "ec126cb1-9adc-4681-9cd4-0fcad33511c9";
TelemetryClient tc = new TelemetryClient();
tc.TrackTrace("This trace goes to the default source");
```
The best place to do it for web applicaiton is Global.asax before any telemetry data items were tracked. ***Note***, that if you'll attempt to send telemetry data item before instrumentation key was set TelemetryClient.Track[Foo] method will throw an exception.

In both cases - using config or setting key programmatically you'll see data reported into the same component. This key will be used as default for all telemetry clients you'll instantiate.
{% img /images/2014-11-17-programmatically-set-instrumenttion-key/defaultsourceevents.png 'Default events' %}

There are situations when one default key is not enough. Scenarios I can imagine are:

	* reporting data from payment processing library separately from other telemetry
	* split telemetry information by tenants of your applicaiton and grant them access to their data only
	* library developer wants to collect telemetry from his library, not send it to applicaiton that uses this library

For all this scenarios you'll need to configure your own custom telemetry client and set it's instrumentation key:
``` csharp
TelemetryClient tcCustom = new TelemetryClient();
tcCustom.Context.InstrumentationKey = "67989f95-d6a2-46a9-918b-028a6a2070c1";
tcCustom.TrackTrace("This trace goes to custom telemetry client");
```
Sometimes you might want even more fine grained control over data. You may want to decide where to send telemetry data item based on it's properties. For instance, you can have a library that decides where to send telemetry item based on current thread identity. In this case you'll create and populate telemetry item and then pass it to this library so it will set the correct Instrumentation Key on this item:
``` csharp
TelemetryClient tcDefault = new TelemetryClient();
TraceTelemetry trace = new TraceTelemetry("This trace goes to the custom source");
trace.Context.InstrumentationKey = "67989f95-d6a2-46a9-918b-028a6a2070c1";
tcDefault.TrackTrace(trace);

```
Both code examples will send trace message to your custom applicaiton even though configuration file defines another instrumentation key.
{% img /images/2014-11-17-programmatically-set-instrumenttion-key/customsourceevents.png 'CustomSource events' %}

Summary
-------
Application Insights SDK gives you a flexible way to configure data collection. You have full programmatic control over where data will be reported to and it is very easy to integrate Application Insights into any continues deployment process with the minimal coding.