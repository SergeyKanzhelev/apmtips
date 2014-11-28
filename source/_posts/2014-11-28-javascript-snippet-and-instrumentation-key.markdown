---
layout: post
title: "JavaScript snippet and instrumentation key"
date: 2014-11-28 10:19:49 -0800
comments: true
categories: 
- Application Insights
---
When you create a new web application in Visual Studio 2013 you can chose to enable Applicaiton Insights for it. Once enabled - JavaScript snippet will be inserted into page template document "\Views\Shared\\_Layout.cshtml":

{% img /images/2014-11-28-javascript-snippet-and-instrumentation-key/javascript-snippet-in-_layout-cshtml.png %}

This JavaScript snippet will collect end user behavior information in portal. You may notice that Instrumentation Key is set to constant in this snippet:

``` csharp
instrumentationKey:"dbdf606c-48ec-4beb-b82d-2a9e7a90e5a4"
```
Constant works fine unless you want to [change the key before deploying to production](/2014/11/17/programmatically-set-instrumenttion-key/). Here is how you can change default snippet in "\Views\Shared\\_Layout.cshtml" to use the same instrumentation key as server monitoring using: 

``` csharp
instrumentationKey:"@Microsoft.ApplicationInsights.Extensibility.TelemetryConfiguration.Active.InstrumentationKey"
```
There are reasons not to use this by default. Performance is one of them. You may also want to separate end user behavior data from server-side telemetry. In any case keep in mind - by default there are two places where you need to change your instrumentation key when you deploying your applicaiton to production.