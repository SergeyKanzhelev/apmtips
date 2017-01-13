---
layout: post
title: "Update to the last post - set the name in MVC Web API"
date: 2017-01-12 23:38:59 -0800
comments: true
categories: 
---
Answering the quesiton in this [comment](http://disq.us/url?impression=c2ac7ce8-d8f1-11e6-b91f-002590f382ca&thread=4930878937&forum=3303858&url=http%3A%2F%2Fapmtips.com%2Fblog%2F2016%2F06%2F21%2Fapplication-insights-for-mvc-and-mvc-web-api%2F%23comment-3096059076%3AlxPIOcDy_D8h8D2nytRz890EJdc&variant=active&experiment=digests&behavior=click&post=3096059076&type=notification.post.moderator&event=email) - how to set the name of the request for attribute-based MVC Web API routing. It can be done as an extension to the previous post. Something like this would work.

``` csharp
public class ApplicationInsightsCorrelationHttpActionFilter : System.Web.Http.Filters.ActionFilterAttribute, ITelemetryInitializer
{
    private static AsyncLocal<RequestTelemetry> currentRequestTelemetry = new AsyncLocal<RequestTelemetry>();

    public override Task OnActionExecutingAsync(HttpActionContext actionContext, CancellationToken cancellationToken)
    {
        var template = actionContext.RequestContext.RouteData.Route.RouteTemplate;
        var controller = actionContext.RequestContext.RouteData.Values["Controller"];

        template = template.Replace("{controller}", controller.ToString());

        var request = System.Web.HttpContext.Current.GetRequestTelemetry();
        request.Name = actionContext.RequestContext.RouteData.Route.RouteTemplate;
        request.Context.Operation.Name = request.Name;

        currentRequestTelemetry.Value = request;


        return base.OnActionExecutingAsync(actionContext, cancellationToken);
    }
}
```

This is an action filter for Web API. In the beggining of action execution the name can be taken from the route data. You can use an actual controller name by taking it from values and substituting it in the template.

Action filter wouldn't work when execution didn't reach the controller. So you may need to duplicate the logic in telemetry initializer `Initialize` method itself. However in this case you'd need to get the currently executing request and it may not always be available. 