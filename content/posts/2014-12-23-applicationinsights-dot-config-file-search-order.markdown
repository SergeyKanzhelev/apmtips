---
layout: post
title: "ApplicationInsights.config file search order"
date: 2014-12-23 08:10:17 -0800
comments: true
aliases: [/blog/2014/12/23/applicationinsights-dot-config-file-search-order/]
categories: 
- Application Insights
- troubleshooting
---
I've already mentioned how to programmatically [set instrumentation key](/blog/2014/11/17/programmatically-set-instrumenttion-key/) and mentioned how to [configure telemetry initializers](/blog/2014/12/01/telemetry-initializers/). In fact you can completely remove ApplicationInsights.config file and make all configuration programmatically. However it is handy to have a single file containing all the settings so you don't need to recompile an application to change them.

When you add application insights to your .NET application - ApplicationInsights.config file being created and marked as a content. So it will be copied to output directory of your application. In general it will follow the same behavior as app.config file - copied side by side with executable for windows application and next to web.config for web application.

So it will be logical to expect that Application Insights SDK will be searching this file next to app.config. However for certain scenarios this algorithm doesn't work and there is a gotcha here. Application Insights SDK is using the following order of searching ApplicationInsights.config file:

1. bin folder of application - from [Application Insigths Core](http://www.nuget.org/packages/Microsoft.ApplicationInsights/0.12.0-build17386) assembly it's ```Assembly.GetExecutingAssembly().CodeBase```
2. base directory - side by side with web.config for ASP.NET applications (```AppDomain.CurrentDomain.BaseDirectory```)

This behavior caused some problems already. There were cases when some random ApplicationInsights.config file was deployed to the bin folder of web application as well as correct one into content folder. So modifications of configuration file you'd expect to be used will not take an effect:

{% img /images/2014-12-23-applicationinsights-dot-config-file-search-order/ApplicationInsightsConfigSearchOrder.png 'ApplicationInsights.config search order' %}