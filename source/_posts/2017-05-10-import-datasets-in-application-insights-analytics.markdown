---
layout: post
title: "import datasets in Application Insights Analytics"
date: 2017-05-10 22:47:26 -0700
comments: true
categories: 
---

I was thinking how to improve querying experience in Application Insights Analytics. In the previous post, I demonstrated how to use datasets in your query. Particularly I needed timezones for countries and I used `datatable` operator to create a dictionary of country timezones. In this post, I show how to use Application Insights [data import feature](https://docs.microsoft.com/azure/application-insights/app-insights-analytics-import) to work around the user voice request ["Return ISO 2/3 letter country code in the REST API"](https://visualstudio.uservoice.com/forums/357324-application-insights/suggestions/18964777-return-iso-2-3-letter-country-code-in-the-rest-api).

I downloaded the country codes from UN [website](https://unstats.un.org/unsd/methodology/m49/) and saved it as a blob in Azure. Then defined the Application Insights Analytics open schema by uploading this file as an example. I named columns and asked to use ingestion time as a required time column.

{% img /images/2017-05-10-import-datasets-in-application-insights-analytics/define-schema.png 'define the schema' %}

Then I used code example from the documentation for [data import feature](https://docs.microsoft.com/azure/application-insights/app-insights-analytics-import). Get the reference to the blob, created a security token and notified Application Insights about this blob storage.

``` csharp
var storageAccount 
= CloudStorageAccount.Parse(ConfigurationManager.AppSettings.Get("StorageConnectionString"));
var blobClient = storageAccount.CreateCloudBlobClient();
var container = blobClient.GetContainerReference("testopenschema");
var blob = container.GetBlobReferenceFromServer("countrycodes.csv");

var sasConstraints = new SharedAccessBlobPolicy();
sasConstraints.SharedAccessExpiryTime = DateTimeOffset.MaxValue;
sasConstraints.Permissions = SharedAccessBlobPermissions.Read;
string uri = blob.Uri + blob.GetSharedAccessSignature(sasConstraints);

AnalyticsDataSourceClient client = new AnalyticsDataSourceClient();
var ingestionRequest = new AnalyticsDataSourceIngestionRequest(
    ikey: "074608ec-29c0-41f1-a7c6-54f30d520629", 
    schemaId: "440f9d45-9b1f-4760-9aa5-3d1bc828cedc", 
    blobSasUri: uri);

await client.RequestBlobIngestion(ingestionRequest);
```

Originally I made a bug in an application and received the error. It means that the security token is verified right away. However the actual data upload happens after some delay. So set the expiration time for some time in future.

```
Ingestion request failed with status code: Forbidden. 
    Error: Blob does not exist or not accessible.
```

Here is how successful requests and response look like:

``` json
POST https://dc.services.visualstudio.com/v2/track HTTP/1.1
Content-Type: application/json; charset=UTF-8
Accept: application/json
Host: dc.services.visualstudio.com
Content-Length: 472

{
    "data": {
        "baseType":"OpenSchemaData",
        "baseData": {
            "ver":"2",
            "blobSasUri":"https://apmtips.blob.core.windows.net/testopenschema/countrycodes.csv?sv=2016-05-31&sr=b&sig=y3oWWTWvAefer7N%2FN%2B49sy4j%2BpR2NA%2F7797EvXQAQEk%3D&se=2017-05-12T00%3A09%3A12Z&sp=rl",
            "sourceName":"440f9d45-9b1f-4760-9aa5-3d1bc828cedc",
            "sourceVersion":"1"
        }
    },
    "ver":1,
    "name":"Microsoft.ApplicationInsights.OpenSchema",
    "time":"2017-05-11T00:09:14.6255207Z",
    "iKey":"074608ec-29c0-41f1-a7c6-54f30d520629"
}
```



``` json
HTTP/1.1 200 OK
Content-Length: 49
Content-Type: application/json; charset=utf-8
Server: Microsoft-IIS/8.5
x-ms-session-id: 0C2E28FE-6085-4DD7-BFB9-8A6195C73A2A
Strict-Transport-Security: max-age=31536000
Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Name, Content-Type, Accept
Access-Control-Allow-Origin: *
Access-Control-Max-Age: 3600
X-Content-Type-Options: nosniff
X-Powered-By: ASP.NET
Date: Thu, 11 May 2017 00:09:15 GMT

{"itemsReceived":1,"itemsAccepted":1,"errors":[]}
```

Once data uploaded you can query it by joining standard tables with the imported data:

```
pageViews 
  | join kind= innerunique (CountryCodes_CL) 
      on $left.client_CountryOrRegion == $right.CountryOrRegion
  | project name, ISOalpha3code  
```

{% img /images/2017-05-10-import-datasets-in-application-insights-analytics/pageview-and-country.png 'pageview and countries' %}

Refresh data in this table periodically as Application Insights keeps data only for [90 days](https://docs.microsoft.com/en-us/azure/application-insights/app-insights-data-retention-privacy#how-long-is-the-data-kept). You can set up an Azure Function to run every 90 days.

By the way, imported logs are also billed by size. You see it as a separate table in the bill blade. You can see how many times I run the application trying things =)...

{% img /images/2017-05-10-import-datasets-in-application-insights-analytics/bill.png 'bill' %}
