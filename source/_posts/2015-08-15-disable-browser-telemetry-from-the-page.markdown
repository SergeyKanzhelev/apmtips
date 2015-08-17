---
layout: post
title: "Disable browser telemetry from the page"
date: 2015-08-15 15:20:38 -0700
comments: true
categories:
- Application Insights
- Javascript 
---
There is a feedback page for the Azure portal. One of the feedback item is "[I want to block certain items it sent to the app insights like the pagename. Can this be done?](http://feedback.azure.com/forums/223579-azure-preview-portal/suggestions/8480947-i-have-installed-the-browser-script-but-i-want-to)". One of my previous posts explains how Application Insights [javascript snippet](/blog/2015/03/18/javascript-snippet-explained/) works. Now I'll try to answer the question and discuss another scenario - how to disable reporting of telemetry under certain conditions. I hope this post will help to understand the snippet even better. 

##Do not send page name to the portal
So - can page name be hidden from the Application Insights. Yes, sure. The standard JavaScript snippet ends with these two lines:

``` javascript
window.appInsights = appInsights;
appInsights.trackPageView();
```

So PageView event is not begin sent automatically. It is sent by this call to ```trackPageView``` you've pasted to your page. Looking at [signature](https://github.com/Microsoft/ApplicationInsights-JS/blob/8cfd9337fb085fac4e1aa7f3c743a2918b1f2786/JavaScript/JavaScriptSDK/appInsights.ts#L159) of this function you can find out that it accept four parameters, two of which are ```name``` and ```url```:

``` javascript
public trackPageView(name?: string, url?: string, properties?: Object, measurements?: Object) 
```

When you call ```trackPageView``` without parameters it will use ```window.document.title``` and ```window.location.href``` correspondingly as you can see on [github](https://github.com/Microsoft/ApplicationInsights-JS/blob/8cfd9337fb085fac4e1aa7f3c743a2918b1f2786/JavaScript/JavaScriptSDK/appInsights.ts#L160-L168).

If for some reasons you don't want to use ```window.document.title``` as a page name you can replace it to ```window.location.pathname``` or any custom string you like:

``` javascript
window.appInsights = appInsights;
appInsights.trackPageView(window.location.pathname, window.location.href);
```

##Disable telemetry from the page

Now, let's imagine that you don't want to report telemetry from certain pages or under certain conditions. 

###Do not inject snippet
Easiest way to disable any telemetry from the page is not to inject the javascript snippet. In many applications all pages are built out of one template. So you will need to have some server-side logic to disable snippet injection for the certain pages. 

Typically for ASP.NET applications you will inject Application Insights javascript snippet to the template file ```Views\Shared\_Layout.cshtml```. If you are using razor you can have condition code like this:

```
@if (needTelemetry) {
	<script language="javascript">
		Application Insights snippet code...
	</script>
}
``` 

###Do not initialize javascript
There are cases when you do not run server-side code to generate snippets or you want to decide whether to send telemetry on client side. For instance, if you have a static HTML page and you want to disable tlemetry when it is opened as a file from file system - you can have client side "big switch" implemented like this:

``` javascript
<script language="javascript">
	if (location.protocol != "file:") {
		Application Insights snippet code...
	}
</script>
``` 

The big downside of this approach is that all custom telemetry calls like the call to ```appInsights.trackEvent``` will now fail. To fix this issue - you can create your own mock object that will replace the real ```appInisghts```. Here is how this mock object may look like: 

``` javascript 
<script language="javascript">
	if (location.protocol != "file:") {
		Application Insights snippet code...
	}
	else {
	    var appInsights = window.appInsights || function (config) {
	        var t = {};
	        function s(config) {
	            t[config] = function () {
	                console.log(config + " was called with the arguments: " +
	                    Array.prototype.slice.call(arguments).toString());
	            }
	        }
	        for (i = ["Event", "Exception", "Metric", "PageView", "Trace"]; i.length;)
	            s("track" + i.pop());
	        return t;
	    }();
	    window.appInsights = appInsights;
	}
``` 

###Disable page view reporting

In some cases you may want to disable page view reporting. For instance, you may not want to have page view statistics from the test environment or development machine. Just wrap the call to ```trackPageView``` into condition like this: 

``` javascript
if (!document.location.href.startsWith("http://localhost")) {
	appInsights.trackPageView();
}
```

###Disable error reporting

It is also easy to disable reporting of javascript errors from the development machine. Set ```disableExceptionTracking``` setting in appInsights configuration: 

```
var appInsights = window.appInsights || function (config) {
		//snippet code...
}({
	instrumentationKey: "595f59fc-f85f-425f-a336-827b13c1a03c",
	disableExceptionTracking: document.location.href.startsWith("http://localhost")
});
```


With Application Insights you are in full control over telemetry your application sends to the portal. We release right from [github](https://github.com/Microsoft/ApplicationInsights-js) so you can always review what data Application Insights SDK collects.