---
layout: post
title: "Developer Mode"
date: 2015-02-02 08:54:58 -0800
comments: true
aliases: [/blog/2015/02/02/developer-mode/]
categories: 
- Application Insights
- troubleshooting
---
Application Insights is truly integrated into Visual Studio development experience. It is easy to add telemetry to your project and see how it works on very early stages of development. There should be no surprises in production. 

To enable the best development experience in Visual Studio, Application Insights SDK has a special mode called "Developer Mode". When in Developer Mode Application Insights SDK behavior changes comparing to production environment:

- you'll see application insights data items in Debug Output window
- data items will be sent immediately without buffering (default buffering interval on production is 1 minute)
- "Track" method of SDK will throw exception if Instrumentation Key is not set (Application Insights SDK wouldn't throw exceptions in production)

There are also nice integration in Visual Studio - popup window showing that data is flowing to Application Insights and with the direct link to application blade on the portal. 

Developer Mode will be turned on automatically in Visual Studio. When you import Application Insights NuGet to your project the following targets file will be added:

```
<Import Project="..\packages\Microsoft.ApplicationInsights.0.12.0-build17386\tools\net40\Microsoft.ApplicationInsights.targets" Condition="Exists('..\packages\Microsoft.ApplicationInsights.0.12.0-build17386\tools\net40\Microsoft.ApplicationInsights.targets')" />
```

This target will enable Developer Mode by creating the following setting in ApplicationInsights.config file:

``` xml
<TelemetryChannel>
  <DeveloperMode>true</DeveloperMode>
</TelemetryChannel>
```

However it will not modify the file you have in source control - it will copy modified file to output directory of the application. And because of configuration file [search order](/blog/2014/12/23/applicationinsights-dot-config-file-search-order/) SDK will be using this modified configuration file when running in Visual Studio.

You'll typically deploy Release version of your application to production. So Developer Mode will not be turned on. However if for some reason you want to deploy Debug version - don't forget to remove this file or just set DeveloperMode to false in ApplicationInsights.config yourself.
