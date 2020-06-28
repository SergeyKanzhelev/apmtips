---
layout: post
title: "Page view and telemetry correlation"
date: 2017-05-11 14:44:41 -0700
comments: true
categories: 
---
For any monitoring and diagnostics solution, it is important to provide visibility into the transaction execution across multiple components. Application Insights [data model](https://docs.microsoft.com/en-us/azure/application-insights/application-insights-correlation) supports telemetry correlation. So you can express interconnections of every telemetry item. A significant subset of interconnections is collected by default by Application Insights SDK. Let's talk about page view correlations and its auto-collection.

Today you can enable telemetry correlation in JavaScript SDK setting the flag `disableCorrelationHeaders` to `false`.

``` js
// Default true. If false, the SDK will add correlation headers 
// to all dependency requests (within the same domain) 
// to correlate them with corresponding requests on the server side. 
disableCorrelationHeaders: boolean;
```
    
You get page view correlated to ajax calls and corresponding server requests. Something like shown on the picture:

{% img /images/2017-05-11-page-view-and-telemetry-correlation/correlated-today.png 'what is correlated today' %}

As you may see, correlation assumes that page view initiated the correlation. Which is not always true. I explain scenarios later in the post.

Application Insights JavaScript SDK hijacks ajax calls and insert correlation headers to it. However, there is no easy way to correlate page views to other resources (scripts or images) without specialized browser extension or "hacky heuristics." You can use referrer value or setting short-living cookies. But neither gives you a generic and reliable solution.

{% img /images/2017-05-11-page-view-and-telemetry-correlation/other-page-resources.png 'other page resources' %}

SPA or single page application may introduce multiple page views correlated to each other. [React components](https://github.com/anastasiia-zolochevska/react-appinsights) may call/contain each other:

{% img /images/2017-05-11-page-view-and-telemetry-correlation/spa-sub-pages.png 'SPA sub pages' %}

SPA is one of the reasons telemetry correlations is not enabled by default. SPA has only one page that initiates all communication to the server. Suddenly all application telemetry may become correlated to a single page view, which is not useful information.

BTW, ability to correlating page views is a primary reason for the github issue [PageView should have own ID for proper correlation](https://github.com/Microsoft/ApplicationInsights-JS/issues/361). As you see, PageViews may create their own execution hierarchy in SPA and Application Insights data model should support it.

You may also want to correlate page view with the originating server request:

{% img /images/2017-05-11-page-view-and-telemetry-correlation/originating-server-request.png 'originating server request' %}

It is easy to implement with the few lines of code. If you are using Application Insights Web SDK is 2.4-beta1 or higher, you can write something like this:

``` js
varappInsights=window.appInsights||function(config){
functioni(config){t[config]=function(){vari=arguments;t.queue.push(function(){t[config]......
    instrumentationKey:"a8cdcad4-2bcb-4ed4-820f-9b2296821ef8",
    disableCorrelationHeaders: false
});

window.appInsights = appInsights;
window.appInsights.queue.push(function () {
    var serverId ="@this.Context.GetRequestTelemetry().Context.Operation.Id";
    appInsights.context.operation.id = serverId;
});

appInsights.trackPageView();
```

If you are using lower version of Application Insights SDK (like 2.3) – the snippet is a bit more complicated as `RequestTelemetry` object needs to be initialized. But still easy:

``` js
var serverId ="@{
    var r = HttpContext.Current.GetRequestTelemetry();
    new Microsoft.ApplicationInsights.TelemetryClient().Initialize(r);
    @Html.Raw(r.Context.Operation.Id);
}";
```

This snippet renders server request ID as a JavaScript variable `serverId` and sets it as a context's operation ID. So all telemetry from this page shares it with the originating server request.

This approach, however, may cause some troubles for the cached pages. Page can be cached on different layers and even shared between users. Often correlating telemetry from different users is not a desired behavior.

Also - make sure you are not making it to extreme. You may want to correlate the server request with the page view that initiated the request:

{% img /images/2017-05-11-page-view-and-telemetry-correlation/referrer.png 'referrer page' %}

As a result, all the pages user visited are correlated. Operation ID is playing the role of session id here. I'd suggest for this kind of analysis employ some other mechanisms and not use telemetry correlation fields.
