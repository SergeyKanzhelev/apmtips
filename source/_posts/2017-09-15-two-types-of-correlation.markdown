---
layout: post
title: "Two types of correlation"
date: 2017-09-15 10:56:32 -0700
comments: true
published: false
categories: 
---
Application Map in Application Insights supports two types of correlation. One shows nodes as instrumentation keys and another - as roles inside a single instrumentation key. In future those will be combined. In this post I'll explain why those wasn't combined from the beginning and how Application Map is built from telemetry events.

What needed to build an Application Map? There should be a query that returns the list of nodes and a query to connect those nodes. It rarely will be a single query as a map will typically follow the path. Once you know that component `A` calls component `B` - there may be a separate query to get all connections of component `B`.


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

``` csharp
string SINGLE_INSTRUMENTATION_KEY = "3b162b68-47d7-4a8c-b031-c246206696e3";

var TRACE_ID = Guid.NewGuid().ToString();


//Devices initiates a logical operation
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
r.Context.Cloud.RoleName = "Frontend"; // this is the name of the node on app map

new TelemetryClient() { InstrumentationKey = SINGLE_INSTRUMENTATION_KEY }.TrackRequest(r);

// Devices calls into myapi. 
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

// The following headers got propagated with the http request
//  Request-Id: |<r.Id>
//  Request-Context: appId=cid-v1:{DEVICES_APP_ID}
//


//Request got received by MAS_SHAKE:

r = new RequestTelemetry(
    name: "POST /feedback", //this is the name of the operation that initiated the entire distributed trace
    startTime: DateTimeOffset.Now,
    duration: TimeSpan.FromSeconds(1),
    responseCode: "200",
    success: true)
{
    Source = "", // not used
    Url = new Uri("https://myapi.com/feedback/text='feedback text'"), // you can omit it if you do not use it
};
r.Context.Operation.Id = TRACE_ID; // initiate the logical operation ID (trace id)
r.Context.Operation.ParentId = d.Id; // this is the first span in a trace
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

In order to [turn on single Ikey correlation](https://docs.microsoft.com/en-us/azure/application-insights/app-insights-app-map#end-to-end-system-app-maps) - open Preview blade for your app and toggle the switch for multi-role Application Map:

{% img /images/2017-09-15-two-types-of-correlation/enable-role-based-map.png  'Enable Multi-Role Application Map' %}

Using Program2.cs you’ll get a similar result:

{% img /images/2017-09-15-two-types-of-correlation/role-based-app-map.png  'Multi-Role Application Map' %}


