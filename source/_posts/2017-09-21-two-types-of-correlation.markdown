---
layout: post
title: "Two types of correlation"
date: 2017-09-21 10:56:32 -0700
comments: true
categories: 
---
Application Map in Application Insights supports two types of correlation. One shows nodes in the map as instrumentation keys and another - as roles inside a single instrumentation key. In future those will be combined. In this post I'll explain why those wasn't combined from the beginning and how Application Map is built from telemetry events.

Application Insights data model defines incoming [requests](https://docs.microsoft.com/azure/application-insights/application-insights-data-model-request-telemetry) and outgoing [dependency calls](https://docs.microsoft.com/azure/application-insights/application-insights-data-model-dependency-telemetry). When SDK collects these events - it will populate request's `source` field and dependency's `target`. Now it's quite easy to draw an Application Map in a form of a star. Application is in the center of the star and every node describes the `source` of incoming request or `target` or outgoing. These two queries shows how to do it:

```
dependencies | summarize sum(itemCount) by target
requests | summarize sum(itemCount) by source
```

When you have an Application Map in a form of a star - you may notice that some `http` dependency calls are actually the calls to another component of your application. If both components sends data to the same instrumentation key you can easily follow this call by joining dependency call of component `A` to the incoming request of component `B`. Also - typically those components will de deployed separately and would have a different `cloud_roleName` field. So by running this query you will get the list of all components talking to each other:

```
dependencies 
  | join requests on $left.id == $right.operation_ParentId 
  | summarize sum(itemCount) by from = cloud_RoleName1, to = cloud_RoleName
```

Now you can see a map where every node is a separate `cloud_RoleName`. Note, that some of dependency calls are made to external components. To draw those you'd still need to use a target field from before. With the slight modification - you need to group it by `cloud_roleName`:

```
dependencies | summarize sum(itemCount) by from = cloud_RoleName, to = target
```

This example shows how to build an application map. First - define some constants:

``` csharp
string SINGLE_INSTRUMENTATION_KEY = "3b162b68-47d7-4a8c-b031-c246206696e3";
var TRACE_ID = Guid.NewGuid().ToString();
```

First component - let's call it `Frontend` reports `RequestTelemetry` and related `DependencyTelemetry`. Note that both defines the `.Cloud.RoleName` context property to identify the component.

``` csharp
var r = new RequestTelemetry(
    name: "PostFeedback", 
    startTime: DateTimeOffset.Now,
    duration: TimeSpan.FromSeconds(1),
    responseCode: "200",
    success: true)
{
    Source = "" //no source specified
};
r.Context.Operation.Id = TRACE_ID; // initiate the logical operation ID (trace id)
r.Context.Operation.ParentId = null; // this is the first span in a trace
r.Context.Cloud.RoleName = "Frontend"; // this is the name of the node on app map

new TelemetryClient() { InstrumentationKey = SINGLE_INSTRUMENTATION_KEY }.TrackRequest(r);

var d = new DependencyTelemetry(
    dependencyTypeName: "Http",
    target: $"myapi.com", //host name
    dependencyName: "POST /feedback",
    data: "https://myapi.com/feedback/text='feedback text'",
    startTime: DateTimeOffset.Now,
    duration: TimeSpan.FromSeconds(1),
    resultCode: "200",
    success: true);
d.Context.Operation.ParentId = r.Id;
d.Context.Operation.Id = TRACE_ID;
d.Context.Cloud.RoleName = "Frontend"; // this is the name of the node on app map

new TelemetryClient() { InstrumentationKey = SINGLE_INSTRUMENTATION_KEY }.TrackDependency(d);
```

`Frontend` component need to pass global trace id `Context.Operation.Id` and dependency call id `d.Id` to the next component. Typically those will be send via http header.

Component called `API Service` tracks incoming request and instantiates context properties `.Context.Operation.ParentId` and `.Context.Operation.Id` from the incoming request headers. These context properties allows to join dependency call from `Frontend` to request in `API Service`.

In this example `API Service` in turn calls the external API.

``` csharp
r = new RequestTelemetry(
    name: "POST /feedback", 
    startTime: DateTimeOffset.Now,
    duration: TimeSpan.FromSeconds(1),
    responseCode: "200",
    success: true)
{
    Url = new Uri("https://myapi.com/feedback/text='feedback text'")
};
r.Context.Operation.Id = TRACE_ID; // received from http header
r.Context.Operation.ParentId = d.Id; // received from http header 
r.Context.Cloud.RoleName = "API Service"; // this is the name of the node on app map

new TelemetryClient() { InstrumentationKey = SINGLE_INSTRUMENTATION_KEY }.TrackRequest(r);

d = new DependencyTelemetry(
    dependencyTypeName: "http",
    target: $"api.twitter.com", 
    dependencyName: "POST /twit",
    data: "https://api.twitter.com/twit",
    startTime: DateTimeOffset.Now,
    duration: TimeSpan.FromSeconds(1),
    resultCode: "200",
    success: true);
d.Context.Operation.ParentId = r.Id;
d.Context.Operation.Id = TRACE_ID;
d.Context.Cloud.RoleName = "API Service"; // this is the name of the node on app map

new TelemetryClient() { InstrumentationKey = SINGLE_INSTRUMENTATION_KEY }.Track(d);
```

Multi-role Application Map is in preview now. So in order to see it you'd need to enable it as shown on the picture:

{% img /images/2017-09-15-two-types-of-correlation/enable-role-based-map.png  'Enable Multi-Role Application Map' %}

Result of the code execution will be something like this:

{% img /images/2017-09-15-two-types-of-correlation/role-based-app-map.png  'Multi-Role Application Map' %}

You can see that every component of your application is represented as a separate node on Application Map. However an important limitation of this approach is that it only works when every component use the same instrumentation key to report telemetry. The main reason for this limitation is that Application Insights [does not support](https://feedback.azure.com/forums/357324-application-insights/suggestions/15165558-support-for-cross-ikey-cross-application-queries) cross applications joins.

Now imagine you can join across instrumentation keys. Join-based approach may still fall apart. First, you never know in advance which instrumentation keys you need to join across. Second, for the very rare calls you may 

First, let’s look at cross ikey. See Program.cs in attachment. I record request and dependency for DEVICES and request and twitter dependency for MAS-SHAKE. It should be easy to extend to include MAS-SHAKE-FUNC.
 
 ``` csharp
string FRONTEND_INSTRUMENTATION_KEY = "fe782703-16ea-46a8-933d-1769817c038a";
string API_SERVICE_INSTRUMENTATION_KEY = "2a42641e-2019-423a-a2b5-ecab34d5477d";

// Obtaining APP ID for these instrumentation key.
// We are using app id for correlation as propagating it via HTTP boundaries do not expose the instrumentation key, but still 
// uniquely identifies the Application Insights resource
var task = new HttpClient().GetStringAsync($"https://dc.services.visualstudio.com/api/profiles/{FRONTEND_INSTRUMENTATION_KEY}/appId");
task.Wait();
var FRONTEND_APP_ID = task.Result;

task = new HttpClient().GetStringAsync($"https://dc.services.visualstudio.com/api/profiles/{API_SERVICE_INSTRUMENTATION_KEY}/appId");
task.Wait();
var API_SERVICE_APP_ID = task.Result;


var TRACE_ID = Guid.NewGuid().ToString();


//Frontend initiates a logical operation
var r = new RequestTelemetry(
    name: "PostFeedback", //this is the name of the operation that initiated the entire distributed trace
    startTime: DateTimeOffset.Now,
    duration: TimeSpan.FromSeconds(1),
    responseCode: "200",
    success: true)
{
    Source = "", //no source specified
    Url = null, // you can omit it if you do not use it
};
r.Context.Operation.Id = TRACE_ID; // initiate the logical operation ID (trace id)
r.Context.Operation.ParentId = null; // this is the first span in a trace

new TelemetryClient() { InstrumentationKey = FRONTEND_INSTRUMENTATION_KEY }.TrackRequest(r);

// Frontend calls into API service. For http communication we expect that response will have a header:
// Request-Context: appId={MAS_SHAKE_APP_ID}
var d = new DependencyTelemetry(
    dependencyTypeName: "Http (tracked component)", //(tracked component) indicates that we recieved response header Request-Context
    target: $"myapi.com | cid-v1:{API_SERVICE_APP_ID}", //host name, | char and app ID from the response headers if available
    dependencyName: "POST /feedback",
    data: "https://myapi.com/feedback/text='feedback text'",
    startTime: DateTimeOffset.Now,
    duration: TimeSpan.FromSeconds(1),
    resultCode: "200",
    success: true);
d.Context.Operation.ParentId = r.Id;
d.Context.Operation.Id = TRACE_ID;


new TelemetryClient() { InstrumentationKey = FRONTEND_INSTRUMENTATION_KEY }.TrackDependency(d);

// The following headers got propagated with the http request
//  Request-Id: |<r.Id>
//  Request-Context: appId=cid-v1:{DEVICES_APP_ID}
//

//Request got received by API service:

r = new RequestTelemetry(
    name: "POST /feedback", //this is the name of the operation that initiated the entire distributed trace
    startTime: DateTimeOffset.Now,
    duration: TimeSpan.FromSeconds(1),
    responseCode: "200",
    success: true)
{
    Source = $" | cid-v1:{FRONTEND_APP_ID}", // this is the value from the request headers
    Url = new Uri("https://myapi.com/feedback/text='feedback text'"), // you can omit it if you do not use it
};
r.Context.Operation.Id = TRACE_ID; // initiate the logical operation ID (trace id)
r.Context.Operation.ParentId = d.Id; // this is the first span in a trace

new TelemetryClient() { InstrumentationKey = API_SERVICE_INSTRUMENTATION_KEY }.TrackRequest(r);

d = new DependencyTelemetry(
    dependencyTypeName: "http",
    target: $"api.twitter.com", 
    dependencyName: "POST /twit",
    data: "https://api.twitter.com/twit",
    startTime: DateTimeOffset.Now,
    duration: TimeSpan.FromSeconds(1),
    resultCode: "200",
    success: true);
d.Context.Operation.ParentId = r.Id;
d.Context.Operation.Id = TRACE_ID;

new TelemetryClient() { InstrumentationKey = API_SERVICE_INSTRUMENTATION_KEY }.Track(d);
```

In order to see actual JSON objects – use fiddler. I’m attaching attaching JSONs for your convenience.

{% img /images/2017-09-15-two-types-of-correlation/multi-ikey-app-map.png  'Multi-ikey Application Map' %}

Some complications you’ll notice in code:
You need to pass thru the appID via HTTP headers alongside the trace ID and request ID. This allows Application Insights to understand which Application Insights ikeys are related to each other
There is a separate type of dependency (“HTTP (tracked component)”) for Application Insights dependencies. This is a magic type that allowed to make UI faster.


In order to [turn on single Ikey correlation](https://docs.microsoft.com/en-us/azure/application-insights/app-insights-app-map#end-to-end-system-app-maps) - open Preview blade for your app and toggle the switch for multi-role Application Map:





