---
layout: post
title: "tracking users in API apps"
date: 2016-07-09 23:54:13 -0700
comments: true
aliases: [/blog/2016/07/09/tracking-users-in-api-apps/]
categories: 
---
Triaging and diagnosing issues you need to correlate telemetry with the user. You may want to understand the impact of a failing dependency (like a percent of affected users) or look up all pages visited by the user before the failure occurred.

Application Insights has multiple fields to associate telemetry event with the user - anonymous user id, authenticated user name and account id. When you are using the combination of JavaScript and C# SDK - anonymous user id will be collected automatically. JavaScript SDK sets the cookies that will be sent with every request.

However when the application you are running is REST endpoint it does not have it's own front end. So there is no JavaScript to set a cookie and track the user.

So you need to set user cookie `ai_user` yourself. The code will look like this: 


``` csharp
string userId = null;

var ctx = HttpContext.Current;

if (ctx != null)
{
  if (ctx.Request.Cookies["ai_user"] == null) 
  {
    userId = Guid.NewGuid().ToString(); 
    var c = new HttpCookie("ai_user", userId + "|" + DateTime.Now.ToString("G")); 
    c.Expires = DateTime.MaxValue; 
    c.Path = "/"; 

    ctx.Response.Cookies.Set(c); 
  }
} 
```

Now with every next request, telemetry initializer `Microsoft.ApplicationInsights.Web.UserTelemetryInitializer` will associate the telemetry item with the user id taken from the cookie.

End of story.

Except a little detail. Initial request will not be associated with the user id. There is a good thing in it. Not every request is coming from the browser. So if the cookie will not be saved by caller - this initial request will not generate a new user id. So metrics like user count would not be affected. 

If you are quite sure that the request is coming from an actual browser - it is quite easy to associate newly generated user id with the current request telemetry item.   

Just get request telemetry from the current `HttpContext` using the extension method `GetRequestTelemetry` and set `Context.User.Id`. All other telemetry items like traces, dependencies and exceptions tracked after that will be automatically correlated with this user id. The code will look something like this:

``` csharp
if (string.IsNullOrEmpty(userId))
{
  var ctx = HttpContext.Current;

  if (ctx != null)
  {
      var requestTelemetry = ctx.GetRequestTelemetry();
      if (requestTelemetry != null))
      {
          requestTelemetry.Context.User.Id = userId;        
      }
  }
}
```

There are definitely edge cases. For instance, if the landing page is cached and it initiates many ajax calls on loading - each of them will generate a new random user id. So you may end up with the different user id for the same user. But if it is the case - you probably would know how and when to set cookies for your application the best.