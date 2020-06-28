---
layout: post
title: "send correlation identifiers"
date: 2017-11-21 21:25:05 -0800
comments: true
aliases: [/blog/2017-11-21-send-correlation-identifiers/]
categories: 
---
Small post on how to send correlation identifiers to the application monitored by Application Insights. It is a reflection on investigation what Application Insights Availability tests need to send to the application to natively correlate test execution identifier with the telemetry produced by that application.

Here is a small asp.net core test application I used. It writes in response request telemetry properties so can be easily used with `curl`.

``` csharp
var r = context.Features.Get<RequestTelemetry>();
await context.Response.WriteAsync(
    "RequestTelemetry: " + 
        " operation_id=" + r?.Context.Operation.Id + 
        " parentId=" + r?.Context.Operation.ParentId + 
        " id=" + r?.Id + 
        " source=" + (r?.Source ?? "") + "\n");
```

# Basic correlation

Http correlation protocol used by Application Insights is posted on [GitHub](https://github.com/dotnet/corefx/blob/master/src/System.Diagnostics.DiagnosticSource/src/HttpCorrelationProtocol.md). The good thing about this protocol is that it's flexible and works with the most identity schemes you may have. If you want to correlate entire distributed transaction by the given identifier - the only thing you need to do is to send it as a `Request-ID` header.

``` bash
curl -H "Request-ID:{78505740-5180-4809-968e-39284bde1a4e}" http://localhost:5000

RequestTelemetry: 
    operation_id={78505740-5180-4809-968e-39284bde1a4e} 
    parentId={78505740-5180-4809-968e-39284bde1a4e} 
    id=|{78505740-5180-4809-968e-39284bde1a4e}.989973aa_
```

In the example above I formatted identifier as a GUID. For the real life implementation, I'd suggest formatting this GUID as a 16-bytes array in hex. Like `4bf92f3577b34da6a3ce929d0e0e4736`. It will be consistent with the future direction on correlation protocol.

# Sequencing

If one test sends multiple requests to one or many applications - you'd want to send a different id-s with every request. It's easy to do. Just append to the test execution identity any random seed and sequence number of the request. In the example below seed is `sd` and sequencing starts with `1`.

``` bash
curl -H "Request-ID:|{78505740-5180-4809-968e-39284bde1a4e}.sd_1" http://localhost:5000
RequestTelemetry: 
    operation_id= {78505740-5180-4809-968e-39284bde1a4e} 
    parentId=|{78505740-5180-4809-968e-39284bde1a4e}.sd_1 
    id=|{78505740-5180-4809-968e-39284bde1a4e}.sd_1.989973ad_

curl -H "Request-ID:|{78505740-5180-4809-968e-39284bde1a4e}.sd_2" http://localhost:5000
RequestTelemetry: 
    operation_id= {78505740-5180-4809-968e-39284bde1a4e} 
    parentId=|{78505740-5180-4809-968e-39284bde1a4e}.sd_2 
    id=|{78505740-5180-4809-968e-39284bde1a4e}.sd_2.989973ae_

curl -H "Request-ID:|{78505740-5180-4809-968e-39284bde1a4e}.sd_3" http://localhost:5000
RequestTelemetry: 
    operation_id= {78505740-5180-4809-968e-39284bde1a4e} 
    parentId=|{78505740-5180-4809-968e-39284bde1a4e}.sd_3 
    id=|{78505740-5180-4809-968e-39284bde1a4e}.sd_3.989973af_
```

# Application identifier

As I mentioned before for the better application map, you'd need to propagate an app-id of the calling component. First, having instrumentation key you can get app-id:

``` bash
curl  https://dc.services.visualstudio.com/api/profiles/074608ec-29c0-41f1-a7c6-54f30d520629/appId
cbf775c7-b52e-4533-8673-bd6fbd7ab04a
```

Then you can send app-id as a `Request-Context` header:

``` bash
curl 
    -H "Request-ID:|{78505740-5180-4809-968e-39284bde1a4e}.sd_3" 
    -H "Request-Context: appId=cid-v1:cbf775c7-b52e-4533-8673-bd6fbd7ab04a" 
    http://localhost:5000

RequestTelemetry: 
    operation_id={78505740-5180-4809-968e-39284bde1a4e} 
    parentId=|{78505740-5180-4809-968e-39284bde1a4e}.sd_3 
    id=|{78505740-5180-4809-968e-39284bde1a4e}.sd_3.ca349ca3_ 
    source=cid-v1:cbf775c7-b52e-4533-8673-bd6fbd7ab04a
```

This way you can identify two components to correlate telemetry. `RequestTelemetry`'s source field points to the component that sent original request.

## Summary

You can use this correlation technique when you run some synthetic traffic on your application or call it from some mobile application.