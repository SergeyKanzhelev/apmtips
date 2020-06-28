---
layout: post
title: "javascript snippet explained"
date: 2015-03-18 10:44:11 -0700
comments: true
aliases: [/blog/2015-03-18-javascript-snippet-explained/]
categories:
- Application Insights 
---
Big thanks to [Scott Southwood](https://github.com/scsouthw) who helped to prepare this post.
 
For end user monitoring Application Insights requires to add this JavaScript snippet to the page:

``` javascript
var appInsights=window.appInsights||function(config){
    function s(config){t[config]=function(){var i=arguments;t.queue.push(function(){t[config].apply(t,i)})}}var t={config:config},r=document,f=window,e="script",o=r.createElement(e),i,u;for(o.src=config.url||"//az416426.vo.msecnd.net/scripts/a/ai.0.js",r.getElementsByTagName(e)[0].parentNode.appendChild(o),t.cookie=r.cookie,t.queue=[],i=["Event","Exception","Metric","PageView","Trace"];i.length;)s("track"+i.pop());return config.disableExceptionTracking||(i="onerror",s("_"+i),u=f[i],f[i]=function(config,r,f,e,o){var s=u&&u(config,r,f,e,o);return s!==!0&&t["_"+i](config,r,f,e,o),s}),t
}({
    instrumentationKey:"d2cb4759-8e2c-453a-996c-e65c9d0e946a"
});

window.appInsights=appInsights;
appInsights.trackPageView();
```

This snippet will make initial set up for end user tracking and then download the reset of the monitoring logic from CDN.

There are number of reasons why this script needs to be injected into the page html code. First, placing script into the page will not require additional download at the early stage of the page loading phase. So page loading time will not be affected. Second, it provides you API to track metrics and events so you don't need to check whether the full Application Insights script is already loaded or not. Third, this script is working in application domain so it can subscribe on ```onerror``` callback and get a full error stack. Due to security restrictions browser will not give you the full error stack if you subscribe on ```onerror``` callback from the script downloaded from the different domain. It also takes cookies from application domain so they can be used for user/session tracking. Here is more detailed explanation of what it is doing.

First, we check that Application Insights object haven't been created yet. If so - we will create it:
 
``` javascript
    var appInsights = window.appInsights || function (config) {
```

Next goes a helper function that will define a new callback with the name passed as an argument. Methods like ```appInsights.trackEvent``` will be created using this helper. Initial implementation of this method is to put an object into the queue for further processing. "Real" implementation will come with Application Insights javascript file downloaded from CDN later:

``` javascript
       function s(config) {
             t[config] = function () {
                    var i = arguments;
                    t.queue.push(function () {
                           t[config].apply(t, i)
                    })
             }
       }
```

Now real ```appInsights``` object is defined under the pseudo name ```t```. Initially it only contains ```config``` field. More fields and methods will be created later:
 
``` javascript
       var t = { config: config },
```

Bunch of constants and variables:

``` javascript
                    r = document,
                    f = window,
                    e = "script",
                    o = r.createElement(e),
                    i,
                    u;
```

In the beginning of this for loop snippet will create ```script``` element in DOM model so Application Insights javascript file will be download later from CDN: 

``` javascript
       for (o.src = config.url || "//az416426.vo.msecnd.net/scripts/a/ai.0.js",
                    r.getElementsByTagName(e)[0].parentNode.appendChild(o),
```

Store domain cookies in ```appInsights``` object:

``` javascript
                    t.cookie = r.cookie,
```

Create an events queue:

``` javascript

                    t.queue = [],
```

And now there is an actual loop. Iterating thru the collection methods like ```appInsights.trackEvent``` will be created (remember helper ```s``` in the very beginning of the snippet):

``` javascript
                    i = ["Event", "Exception", "Metric", "PageView", "Trace"];
                    i.length;
                    )
                    s("track" + i.pop());
```

Now, subscribe to ```onerror``` callback to catch javascript errors in page initialization. You can disable thie logic by setting ```disableExceptionTracking``` property to ```false```:

``` javascript
       return config.disableExceptionTracking ||
```

Using the same helper from the beggining of script define ```appInsights._onerror``` method:

``` javascript
                    (i = "onerror",
                    s("_" + i),
```

Now save existing ```window.onerror``` (```f``` is ```window```, see above in constants section) callback from the page and replace it with the new implementation. New implementation will chain the call to ```appInsights._onerror``` and call to initial ```window.onerror``` implementation:

``` javascript
                    u = f[i],
                    f[i] = function (config, r, f, e, o) {
                           var s = u && u(config, r, f, e, o);
                           return s !== !0 && t["_" + i](config, r, f, e, o), s
                    }),
```

Return freshly created ```appInsights``` object from the method:

``` javascript
                    t
    }
```

Constructor function is created. Now call it, providing initial configuration. The only required piece of configuration is instrumentationKey:

``` javascript
({
       instrumentationKey: "@RequestTelelemtry.Context.InstrumentationKey"
});
```

Now we store ```appInsights``` as a global variable and save into the queue ```pageView``` event:

``` javascript
    window.appInsights = appInsights;
    appInsights.trackPageView();
```

Read more on [out-of-the box usage analytics](http://azure.microsoft.com/en-gb/documentation/articles/app-insights-overview-usage/). Inforamtion on tracking custom events and metrics [here](http://azure.microsoft.com/en-gb/documentation/articles/app-insights-web-track-usage-custom-events-metrics/).

 