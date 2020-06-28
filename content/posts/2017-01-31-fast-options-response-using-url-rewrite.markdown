---
layout: post
title: "Fast OPTIONS response using Url Rewrite"
date: 2017-01-31 22:48:26 -0800
comments: true
categories: 
- Hacking availability tests 
---
Imagine you run a high load web application. If this application should be accessible from the different domains you need to configure your server to correctly respond to `OPTIONS` requests. With IIS - it is easy to configure UrlRewrite rule that will reply with the preconfigured headers without any extra processing cost.

You need to configure inbound rule that matches `{REQUEST_METHOD}` and reply `200` immidiately. Also you'd need a set of outbound rules which will set a proper response headers like `Access-Control-Allow-Methods`. It will look like this:

``` xml
<rewrite>
    <outboundRules>
        <rule name="Set Access-Control-Allow-Methods for OPTIONS response" preCondition="OPTIONS" patternSyntax="Wildcard">
            <match serverVariable="RESPONSE_Access-Control-Allow-Methods" pattern="*" negate="false" />
            <action type="Rewrite" value="POST" />
        </rule>
        <rule name="Set Access-Control-Allow-Headers for OPTIONS response" preCondition="OPTIONS" patternSyntax="Wildcard">
            <match serverVariable="RESPONSE_Access-Control-Allow-Headers" pattern="*" negate="false" />
            <action type="Rewrite" value="Origin, X-Requested-With, Content-Name, Content-Type, Accept" />
        </rule>
        <rule name="Set Access-Control-Allow-Origin for OPTIONS response" preCondition="OPTIONS" patternSyntax="Wildcard">
            <match serverVariable="RESPONSE_Access-Control-Allow-Origin" pattern="*" negate="false" />
            <action type="Rewrite" value="*" />
        </rule>
        <rule name="Set Access-Control-Max-Age for OPTIONS response" preCondition="OPTIONS" patternSyntax="Wildcard">
            <match serverVariable="RESPONSE_Access-Control-Max-Age" pattern="*" negate="false" />
            <action type="Rewrite" value="3600" />
        </rule>
        <rule name="Set X-Content-Type-Options for OPTIONS response" preCondition="OPTIONS" patternSyntax="Wildcard">
            <match serverVariable="RESPONSE_X-Content-Type-Options" pattern="*" negate="false" />
            <action type="Rewrite" value="nosniff" />
        </rule>
        <preConditions>
            <preCondition name="OPTIONS">
                <add input="{REQUEST_METHOD}" pattern="OPTIONS" />
            </preCondition>
        </preConditions>
    </outboundRules>
    <rules>
    <rule name="OPTIONS" patternSyntax="Wildcard" stopProcessing="true">
        <match url="*" />
        <conditions logicalGrouping="MatchAny">
            <add input="{REQUEST_METHOD}" pattern="OPTIONS" />
        </conditions>
        <action type="CustomResponse" statusCode="200" subStatusCode="0" statusReason="OK" statusDescription="OK" />
    </rule>
    </rules>
</rewrite>
```

I did some measurements locally and found that this simple rule saves a lot of CPU under high load. You can add this rule to your site `web.config` or for Azure Web Apps you can configure these rules using `applicationHost.xdt` [file](https://github.com/projectkudu/kudu/wiki/Xdt-transform-samples#add-a-rewrite-rule).

Now you configured it - how will you make sure it is working in production? Application Insights allows to run a [multi-step availability tests](https://docs.microsoft.com/en-us/azure/application-insights/app-insights-monitor-web-app-availability#multi-step-web-tests). Configuring one for `OPTIONS` required two hacks.

First, Visual Studio didn't allow to pick `OPTIONS` http method. Only `GET` and `POST`. To workaround this issue I simply opened my `.webtest` file in text editor and manually set the method to the value I needed:

``` xml
<Request Method="OPTIONS" Version="1.1" Url="https://dc.services.visualstudio.com/v2/track"..
```

Second, there is no built-in response header value validator. So I configured the web test to run "bad" request if the value of extracted response header doesn't match the expected value.

{% img /images/2017-01-31-fast-options-response-using-url-rewrite/multi-step-availability-test.png 'web test' %}

After I configured my web test I can see the test results in standard UI or simply run a query like in Application Analytics.

```
availabilityResults
| where timestamp > ago(1d)
| where name == "OPTIONS"
| summarize percentile(duration, 99) by location, bin(timespan, 15m)
```