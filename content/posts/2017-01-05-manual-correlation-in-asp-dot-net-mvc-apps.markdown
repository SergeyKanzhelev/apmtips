---
layout: post
title: "manual correlation in ASP.NET MVC apps"
date: 2017-01-05 14:49:35 -0800
comments: true
aliases: [/blog/2017-01-05-manual-correlation-in-asp-dot-net-mvc-apps/]
categories: 
---
I already wrote that correlation is not working well in ASP.NET MVC applications. Here is how you can fix it manually. 

Assuming you are using `Microsoft.ApplicationInsights.Web` nuget package - you will have access to the `RequestTelemetry` stored in `HttpContext.Current`. You can store it in `AsyncLocal` (for FW 4.5 you can use `CallContext`) so it will ba available for all telemetry - sync and async run inside the action. 

This is an example implementation that uses the same class as Action Filter and Telemetry Initializer.

``` csharp
namespace ApmTips
{
    public class ApplicationInsightsCorrelationActionFilter : ActionFilterAttribute, ITelemetryInitializer
    {
        private static AsyncLocal<RequestTelemetry> currentRequestTelemetry = new AsyncLocal<RequestTelemetry>();

        public override void OnActionExecuting(ActionExecutingContext filterContext)
        {
            var request = HttpContext.Current.GetRequestTelemetry();
            currentRequestTelemetry.Value = request;

            base.OnActionExecuting(filterContext);
        }

        public override void OnActionExecuted(ActionExecutedContext filterContext)
        {
            currentRequestTelemetry.Value = null;

            base.OnActionExecuted(filterContext);
        }

        public override void OnResultExecuting(ResultExecutingContext filterContext)
        {
            var request = HttpContext.Current.GetRequestTelemetry();
            currentRequestTelemetry.Value = request;

            base.OnResultExecuting(filterContext);
        }

        public override void OnResultExecuted(ResultExecutedContext filterContext)
        {
            currentRequestTelemetry.Value = null;

            base.OnResultExecuted(filterContext);
        }

        public void Initialize(ITelemetry telemetry)
        {
            var request = currentRequestTelemetry.Value;

            if (request == null)
                return;

            if (string.IsNullOrEmpty(telemetry.Context.Operation.Id) && !string.IsNullOrEmpty(request.Context.Operation.Id))
            {
                telemetry.Context.Operation.Id = request.Context.Operation.Id;
            }

            if (string.IsNullOrEmpty(telemetry.Context.Operation.ParentId) && !string.IsNullOrEmpty(request.Id))
            {
                telemetry.Context.Operation.ParentId = request.Id;
            }

            if (string.IsNullOrEmpty(telemetry.Context.Operation.Name) && !string.IsNullOrEmpty(request.Name))
            {
                telemetry.Context.Operation.Name = request.Name;
            }

            if (string.IsNullOrEmpty(telemetry.Context.User.Id) && !string.IsNullOrEmpty(request.Context.User.Id))
            {
                telemetry.Context.User.Id = request.Context.User.Id;
            }

            if (string.IsNullOrEmpty(telemetry.Context.Session.Id) && !string.IsNullOrEmpty(request.Context.Session.Id))
            {
                telemetry.Context.Session.Id = request.Context.Session.Id;
            }
        }
    }
}
```

Here is how you'd register it in `Global.asax.cs`:

``` csharp
var filter = new ApplicationInsightsCorrelationActionFilter();
GlobalFilters.Filters.Add(filter);
TelemetryConfiguration.Active.TelemetryInitializers.Add(filter);
```

You can always use one of community-supported MVC monitoring NuGets which will be doing a similar things to enable this correlation.