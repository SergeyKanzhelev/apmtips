---
layout: post
title: "Developer mode"
date: 2014-12-04 21:39:47 -0800
comments: true
aliases: [/blog/2014/12/04/developer-mode/]
published: false
categories: 
- Application Insights
- trubleshooting
---
Application Insights is truly integrate into Visual Studio development expirience. You can use default data collection modules or call into SDK. In any case you'll see telemetry data in portal instanteneously... almost instanteneously. Ths post shed some light on how fast it typically is.  It will describe some internal details of SDK inmplemetation that is subject to change. All code snippets are wokring for currently available version of SKD [0.11](http://www.nuget.org/packages/Microsoft.ApplicationInsights/0.11.1-build00694). I'll keep in mind to post an update to this post when any breaking change will be released. Please comment if anything was not working for you.

From the time event happened 

[12/1/2014 9:18 AM] Bret Grinslade: 
I would says something like the service is in preview and there is not a published SLA but data usually shows up in a few seconds.
[12/1/2014 9:18 AM] Bret Grinslade: 
There will be formal SLAs when the services is generally available.


Application SDK is using the following order of finding ApplicationInsights.config file:
	* bin folder of application (from [Application Insigths Core](http://www.nuget.org/packages/Microsoft.ApplicationInsights/0.11.1-build00694) assembly it's Assembly.GetExecutingAssembly().CodeBase)
	* current directory - side by side with web.config for ASP.NET applications (AppDomain.CurrentDomain.BaseDirectory)

``` xml
  <TelemetryChannel>
    <DeveloperMode>true</DeveloperMode>
  </TelemetryChannel>
  ``` 