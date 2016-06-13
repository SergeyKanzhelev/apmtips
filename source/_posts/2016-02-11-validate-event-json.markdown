---
layout: post
title: "Validate event json"
date: 2016-02-11 23:45:35 -0800
comments: true
categories:
- Application Insights
- Troubleshooting 
---
Application Insights endpoint now supports events validation. It's very easy to use - just post your telemetry item json to this endpoint and if response code is not `200` response text will contain the error message.

In C# code will look like this:

``` csharp
static async Task<bool> IsEventCorrect(string json)
{
    json = json.Replace("duration", "durationMs");

    HttpClient client = new HttpClient();
    var result = await client.PostAsync(
        "https://dc.services.visualstudio.com/v2/validate", 
        new ByteArrayContent(Encoding.UTF8.GetBytes(json)));

    Console.WriteLine(result.StatusCode);

    if (result.StatusCode != HttpStatusCode.OK)
    {
        var response = await result.Content.ReadAsStringAsync();
        Console.WriteLine(response);
        return await Task.FromResult(false);
    }
    return await Task.FromResult(true);
}
```

Result of execution will be something like this:

``` json
BadRequest
{
  "itemsReceived": 1,
  "itemsAccepted": 0,
  "errors": [
    {
      "index": 0,
      "statusCode": 400,
      "message": "106: Field 'duration' on type 'RequestData' is of 
                    incorrect type. Expected: string, Actual: undefined"
    }
  ]
}
```

Validation that this endpoint provides is not 100% strict. It guarantees that event is well-formed and has all the required fields. So it will be accepted by the `/track` endpoint. However, today it will allow sending some extra fields in json payload that will never be saved in backend.


With the [.NET SDK](https://www.nuget.org/packages/Microsoft.ApplicationInsights/) it's easy to generate test JSON. You'll need to construct telemetry type of interest. In this example - `RequestTelemetry`. Then use `JsonSerializer` class to get byte array: 

``` csharp
RequestTelemetry rt = new RequestTelemetry();

rt.Context.InstrumentationKey = "c92059c3-9428-43e7-9b85-a96fb7c9488f";

rt.Name = "RequestName";
rt.StartTime = DateTimeOffset.Now;
rt.Duration = TimeSpan.FromSeconds(10);

string json = Encoding.Default.GetString(
    JsonSerializer.Serialize(new List<ITelemetry>() { rt }, false));

json = json.Replace("duration", "durationMs");

var t = IsEventCorrect(json);
```



You can also fill out all the properties:

``` csharp
// Host context
rt.Context.Cloud.RoleName = "Role Name";
rt.Context.Cloud.RoleInstance = "Role Instance";

// Application context
rt.Context.Component.Version = "Application Version";

// Custom properties - limit 200 per application
rt.Context.Properties["DeploymentUnit"] = "SouthUS";

// Application user context
rt.Context.Location.Ip = "127.0.0.1";
rt.Context.Operation.SyntheticSource = "Test in production";

// Session context
rt.Context.User.Id = "Anonymous User Id";
rt.Context.Session.Id = "Anonymous Session Id";

rt.Context.User.AccountId = "Account Id";
rt.Context.User.AuthenticatedUserId = "Authenticated user id";

// Operation context
rt.Context.Operation.Id = "Root operatioin id";
rt.Context.Operation.ParentId = "Parent Operation Id";
rt.Context.Operation.Name = "Operation name";
```

Using C# JSON serialization and validation endpoint it is easier to understand why json formed by any other SDK is not being accepted by Application Insights endpoint.   