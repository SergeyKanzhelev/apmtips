---
layout: post
title: "Developer mode"
date: 2014-11-25 21:50:47 -0800
comments: true
published: false
categories: 
- Application Insights
- trubleshooting
---
I love application insights in a new [azure portal](http://portal.azure.com)! It is really easy to start sending telemetry data to the portal, it is  useful for developers and truly integrate into Visual Studio development expirience. But most important - you can see telemetyr data immidiately. Ths post shed more light how immidiate it really is and how dveloper mode works.  iT will describe some internal details of SDK inmplemetation that is subject to change. All code snippets are wokring for currently available version of SKD (0.11). I'll keep in mind to post an update to this post when any breaking change will be released. Please comment if anything was not working for you.



Application SDK is using the following order of finding ApplicaitonInsights.config file:
	* bin folder of application (from [Application Insigths Core](http://www.nuget.org/packages/Microsoft.ApplicationInsights/0.11.1-build00694) assembly it's Assembly.GetExecutingAssembly().CodeBase)
	* current directory - side by side with web.config for ASP.NET applications (AppDomain.CurrentDomain.BaseDirectory)

``` xml
  <TelemetryChannel>
    <DeveloperMode>true</DeveloperMode>
  </TelemetryChannel>
  ``` 