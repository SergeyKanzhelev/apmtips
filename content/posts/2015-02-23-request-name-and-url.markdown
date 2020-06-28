---
layout: post
title: "Request name and url"
date: 2015-02-23 09:08:55 -0800
comments: true
aliases: [/blog/2015/02/23/request-name-and-url/]
categories:
- Application Insights
---
In my previous post on [web requests tracking http module](/blog/2015/01/02/application-insights-requests-tracking-more-than-just-a-begin-and-end/) I mentioned that Application Insights http module has some smart logic to collect request name. This logic is needed to make meaningful aggregation on UI side. In the screenshot below you see that requests are grouped by request name.  Aggregations like number of requests and average execution time for requests were calculated for some pages. And those aggregations completely unusable for requests to "__browserLink":

{%img /images/2015-02-23-requesdt-name-and-url/grouping-by-request-name.png 'Grouping by request name' %}

Here is how request name calculation logic works today:

1. ASP.NET MVC support. Request name is calculated as "VERB controller/action".
2. ASP.NET MVC Web API support. Following the logic above both requests "/api/movies/" and "/api/movies/5" will be resulted in "GET movies". So to support Web API request name includes the list of all names of routing parameters in case if "action" parameter wasn't found. In example above you'll see requests "GET movies" and "GET movies[id]".  
3. If routing table is empty or doesn't have "controller" - [HttpRequest.Path](https://msdn.microsoft.com/en-us/library/system.web.httprequest.path.aspx) will be used as a request name. This property doesn't include domain name and query string.

Application Insights web SDK will send request name "as is" with regards to letter case. Grouping on UI will be case sensitive so "GET Home/Index" will be counted separately from "GET home/INDEX" even though in many cases they will result in the same controller and action execution. The reason for that is that urls in general are case sensitive (http://www.w3.org/TR/WD-html40-970708/htmlweb.html) and you may want to see if all 404 happened when customer were requesting the page in certain case.

Known issues:

1. There is no smart request name calculation for [attributes-based routing](http://blogs.msdn.com/b/webdev/archive/2013/10/17/attribute-routing-in-asp-net-mvc-5.aspx) today
2. Custom implementation of routing is not supported out of the box. You'll need to implement your own WebOperationNameTelemetryInitializer implementation to override standard behavior.
