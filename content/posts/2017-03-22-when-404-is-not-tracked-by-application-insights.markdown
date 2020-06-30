---
layout: post
title: "When 404 is not tracked by Application Insights"
date: 2017-03-22 14:47:01 -0700
comments: true
aliases: [/blog/2017/03/22/when-404-is-not-tracked-by-application-insights/]
categories: 
---

Sometimes Application Insights wouldn't track web requests made with the bad routes resulting in the response code `404`. The reason may not be clear initially. However once you opened the application from localhost and see the standard IIS error page - it become clearer. Without the default route set up in your applicaiton - `404` will be returned by `StaticFile` handler, not by the managed handler. This is what the error page says:

![404 error page](/images/2017-03-22-when-404-is-not-tracked-by-application-insights/404-error-page.png)

Easiest and most straightforward workaround is to change a `web.config` according to [this blog post](http://apmtips.com/blog/2014/12/02/tracking-static-content-with-application-insights-httpmodule/) - add `runAllManagedModulesForAllRequests="true"` and remove `preCondition="managedHandler"`:

``` xml
<modules runAllManagedModulesForAllRequests="true">
  <remove name="ApplicationInsightsWebTracking" />
  <add name="ApplicationInsightsWebTracking" 
   type="Microsoft.ApplicationInsights.Web.ApplicationInsightsHttpModule, Microsoft.AI.Web"/>
</modules>
```

This way Application Insights http module will be working on every request and you'll capture all requests made to the bad routes. 