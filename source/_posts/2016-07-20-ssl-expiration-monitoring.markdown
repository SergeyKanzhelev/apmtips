---
layout: post
title: "SSL expiration monitoring"
date: 2016-07-20 00:53:01 -0700
comments: true
categories: 
---
Now this blog is available via [https](https://apmtips.com). Thanks for the courtesy of *Let's Encrypt* and great step by step [instruction](https://gooroo.io/GoorooTHINK/Article/16420/Lets-Encrypt-Azure-Web-Apps-the-Free-and-Easy-Way/) how to install it on Azure Web App.

SSL certificate from *Let's Encrypt* expires in 3 month. Instruction above configures a web job to update certificate before it expire. However, you may want to set up an extra reminder for the certificate expiration.

Application Insights web test will fail when certificate is invalid. It will be a little bit late as certificate is already expired. 

So I created a little [tool](https://github.com/SergeyKanzhelev/WebTestsTools/blob/master/WebTestsTools/Controllers/CertificateController.cs) that will return certificate information for a given domain name.

When you call http://webteststools.azurewebsites.net/certificate/apmtips.com/ - it will return a JSON with certificate information like this:

``` json
{
    "ExpirationDate":"10/18/2016 6:30:00 AM",
    "ExpiresIn10Days":false,
    "IssuerName":"CN=Let's Encrypt Authority X3, O=Let's Encrypt, C=US",
    "Subject":"CN=apmtips.com",
    "Error":false
}
```

So you can set up an Application Insights web test that will call that url and validate response:

{% img /images/2016-07-20-ssl-expiration-monitoring/webtestconfig.png 'web test configuration' %}

Now when `"ExpiresIn10Days":false` will turn into `"ExpiresIn10Days":true` - alert will fire and there will be 10 more days to fix a certificate.

There is now a new point of failure - this new tool. If it is down - you will get a false alarm. Considering Azure Web Apps SLA and the fact that certificates do not expire too often - it may be a good compromise. 