---
layout: post
title: "Request success and response code"
date: 2016-12-03 17:11:24 -0800
comments: true
aliases: [/blog/2016-12-03-request-success-and-response-code/]
categories: 
---
Application Inisghts monitors web application requests. This article explains the difference between two fields representing the [request](https://github.com/Microsoft/ApplicationInsights-Home/blob/master/EndpointSpecs/Schemas/Bond/RequestData.bond#L6) - `success` and `responseCode`.

There are many ways you use an application monitoring tool. You can use it for the daily status check, bugs triage or deep diagnostics. For the daily status check you want to know quickly whether anything unusual is going on. The commonly used chart is the number of failed requests. When this number is higher then yesterday - time comes for triage and deep diagnositcs. You want to know how exactly these requests failed.

For the web applications Application Inisghts defines request as sucessful when the response code is less the `400` or equal to `401`. And failed otherwise. Quite straightforward. So why there are two fields being sent - `responseCode` and `success`. Wouldn't it be easier to map the response code to success status on backend? 

Response code `401` is marked as "successful" as it is part of a normal authentication handshake. Marking it as "failed" can cause an alert in the middle of a night when people on the different continent just came to work and login to the application. However this logic is oversimplified. You probably want to get notified when all these people who just came to work cannot login to the applicaiton because of some recent code change. Those `401` responses would be a legitimate "faiures".

So you may want to override the default `success = true` value for `401` response code when the authentication has actually failed. 

There are other cases when response code is not mapped directly to the request success.

Response code `404` may indicate "no records" which can be part of regular flow. It also may indicate a broken link. For the broken links you can even implement a logic that will mark broken links as failures only when those links are located on the same web page (by analyzing urlReferrer) or accessed from the company's mobile application. Similarly `301` and `302` will indicate failure when accessed from the client that doesn't support redirect.

Partially accepted content`206` may indicate a failure of an overall request. For instance, Application Insights endpoint allows to send a batch of telemetry items as a single request. It will return `206` when some items sent in request were not processed successfully. Increasing rate of `206` indicates a problem that needs to be investigated. Similar logic applies to `207 Multi-Status ` where the `success` may be the worst of separate response codes. 

You may want to set `success = false` for `200` responses representing an error page.

And definitely set `success = true` for the `418 I'm a teapot` [(RFC 2324)](https://tools.ietf.org/html/rfc2324) as request for cofffee should never fail.

Here is how you can set the success flag for the request telemetry.

***Implement telemetry initializer***

You can write a simple [telemetry initializer](http://apmtips.com/blog/2014/12/01/telemetry-initializers/) that override the default behavior:

``` csharp
public class SetFailedFor401 : ITelemetryInitializer
{
    public void Initialize(ITelemetry telemetry)
    {
        if (telemetry is RequestTelemetry)
        {
            var r = (RequestTelemetry)telemetry;

            if (r.ResponseCode == "401")
            {
                r.Success = false;
            }
        }
    }
}
```

You can make telemetry initializer configurable. This telemetry initializer will set `success` to `true` for the `404` requests from the external sites.

``` csharp
public class SetSuccesFor404FromExternalSite : ITelemetryInitializer
{
    public string ApplicationHost { get; set; }

    public void Initialize(ITelemetry telemetry)
    {
        if (telemetry is RequestTelemetry)
        {
            var r = (RequestTelemetry)telemetry;

            if (r.ResponseCode == "404" &&
                (HttpContext.Current.Request.UrlReferrer != null &&
                 !HttpContext.Current.Request.UrlReferrer.Host.Contains(this.ApplicationHost)
                )
               )
            {
                r.Success = true;
            }
        }
    }
}
```

You'd need to configure it like this:

``` xml
<Add Type="SetSuccesFor404FromExternalSite, WebApplication1" >
    <ApplicationHost>apmtips.com</ApplicationHost>
</Add>
```

***From Code***

From anywhere in code you can set the succes status of the request. This value will not be overriden by standard request telemetry collection code.

``` csharp
if (returnEmptyCollection)
{
    HttpContext.Current.GetRequestTelemetry().Success = true;
}
```
