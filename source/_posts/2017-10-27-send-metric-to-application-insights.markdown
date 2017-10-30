---
layout: post
title: "Send metric to Application Insights"
date: 2017-10-27 13:39:25 -0700
comments: true
categories: 
- DIY
---
I already [posted](http://apmtips.com/blog/2017/03/27/oneliner-to-send-event-to-application-insights/) how to send telemetry to Application Insights REST endpoint using PowerShell one-liner. This post shows how to send metric using `curl`.

Here is a minimal JSON represents the metric. You need to define `iKey` where this metric will be stored into, `time` this metric reported for and `metrics` collection. Note, that `baseType` should be set to `MetricData`. The field `name` in envelope is redundant in the context of this API.

Here is an example of JSON:

``` json
{
    "iKey": "f4731d25-188b-4ec1-ac44-9fcf35c05812",
    "time": "2017-10-27T00:01:52.9586379Z",
    "name": "MetricData", 
    "data": {
        "baseType": "MetricData",
        "baseData": {
            "metrics": [ 
                {
                    "name": "Custom metric",
                    "value": 1,
                    "count": 1
                }
            ]
        }
    }
}
```

Microsoft bond definition for the MetricData document is located in [ApplicationInsights-Home](https://github.com/Microsoft/ApplicationInsights-Home/blob/master/EndpointSpecs/Schemas/Bond/MetricData.bond) repository.

Now you can send this to Application Insights endpoint:

``` bash
curl -d '{"name": "MetricData", "time":"2017-10-27T00:01:52.9586379Z",
    "iKey":"f4731d25-188b-4ec1-ac44-9fcf35c05812",
    "data":{"baseType":"MetricData","baseData":
    {"metrics":[{"name":"Custom metric","value":1,"count":1}]}}}' 
    https://dc.services.visualstudio.com/v2/track

StdOut:
{"itemsReceived":1,"itemsAccepted":1,"errors":[]}
```

You can send multiple new-line delimited metrics in one http POST.

``` bash
curl -d $'{"name": "MetricData", "time":"2017-10-27T00:01:52.9586379Z",
    "iKey":"f4731d25-188b-4ec1-ac44-9fcf35c05812",
    "data":{"baseType":"MetricData","baseData":
    {"metrics":[{"name":"Custom metric on line 1","value":1,"count":1}]}}}\n

    {"name": "MetricData", "time":"2017-10-27T00:01:52.9586379Z",
    "iKey":"f4731d25-188b-4ec1-ac44-9fcf35c05812",
    "data":{"baseType":"MetricData","baseData":
    {"metrics":[{"name":"Custom metric on line 2","value":1,"count":1}]}}}' 
    https://dc.services.visualstudio.com/v2/track

StdOut:
{"itemsReceived":2,"itemsAccepted":2,"errors":[]}
```

If you want to add a few dimensions to your metric - you can use `properties` collection.

``` json
{
    "iKey": "f4731d25-188b-4ec1-ac44-9fcf35c05812",
    "time": "2017-10-27T00:01:52.9586379Z",
    "name": "MetricData", 
    "data": {
        "baseType": "MetricData",
        "baseData": {
            "metrics": [ 
                {
                    "name": "Custom metric",
                    "value": 1,
                    "count": 1
                }
            ],
            "properties": {
                "dimension1": "value1",
                "dimension2": "value2"
            }
        }
    }
}
```

Now you can create stacked area chart using analytics query:

```
customMetrics 
    | summarize avg(value) by tostring(customDimensions.dimension1), bin(timestamp, 1m) 
    | render areachart kind=stacked 
```

There are no limits on number of dimensions or it's cardinality. You can even summarize by derived field. For example - you can aggregate a metric by substring of a dimension value.

```
customMetrics 
    | extend firstChar = substring(tostring(customDimensions.dimension1), 0, 2)
    | summarize avg(value) by firstChar, bin(timestamp, 1m) 
    | render areachart kind=stacked 
```

You can also specify standard dimensions using `tags`. This way you associate your metric with the specific application role or role instance. Or mark it with the user and account. Using standard dimensions will enable better integration with the rest of telemetry. This example lists a few standard dimensions you can specify:

``` json
{
    "iKey": "f4731d25-188b-4ec1-ac44-9fcf35c05812",
    "time": "2017-10-27T00:01:52.9586379Z",
    "name": "MetricData", 
    "tags": {
        "ai.application.ver": "v1.2",
        "ai.operation.name": "CheckOut",
        "ai.operation.syntheticSource": "TestInProduction: Validate CheckOut",
        "ai.user.accountId": "Example.com",
        "ai.user.authUserId": "sergey@example.com",
        "ai.user.id": "qwoijcas",
        "ai.cloud.role": "Cart",
        "ai.cloud.roleInstance": "instance_0"
    },
    "data": {
        "baseType": "MetricData",
        "baseData": {
            "metrics": [ 
                {
                    "name": "Custom metric",
                    "value": 1,
                    "count": 1
                }
            ]
        }
    }
}
```

You can also set more aggregates for the metric. Besides `value` (which is treated as `sum`) and `count` you can specify `min`, `max` and standard deviation `stdDev`.

``` json
{
    "iKey": "f4731d25-188b-4ec1-ac44-9fcf35c05812",
    "time": "2017-10-27T00:01:52.9586379Z",
    "name": "MetricData", 
    "data": {
        "baseType": "MetricData",
        "baseData": {
            "metrics": [ 
                {
                    "name": "Custom metric",
                    "value": 5,
                    "min": 0,
                    "max": 3,
                    "stdDev": 1.52753,
                    "count": 3
                }
            ]
        }
    }
}
```

##Price of a single metric

Application Insights charges $2.3 per Gb of telemetry. Let's say the metric document you send is 500 bytes. Metric with just name and value is 200 bytes. So 500 bytes includes few dimensions. If you send 1 metric per minute you will be paying for `24 * 60 * 500 * 30 bytes` per month or `0.02 Gb` per month. If you send this metric from 5 different instances of your application - it is `0.1 Gb` or 23 cents. I'm not taking into account the first free Gb you are getting every month.

With Application Insights today you cannot pay flat rate for a metric. On other hand you get very rich analytics language on every metric document you sent, not just access to metric aggregates.

##Metrics REST API shortcomings

### Multiple metrics in a single document
Metrics document schema defines an array of metrics. However Application Insights only supports one element in this array. 

When this limitation will be removed - every metric in collection will support it's own set of dimensions. Today, dimensions are set on document level to align with all other telemetry types that Application Insights supports.

### Aggregation Interval

Application Insights assumes 1 minute aggregation for all reported metrics. You can easily work around this assumption using Analytics queries.

In standard metrics aggregator custom property `MS.AggregationIntervalMs` [used to indicate](https://github.com/Microsoft/ApplicationInsights-dotnet/blob/e544ffae4f3188bde01a367364ea3e36f2bf03a9/src/Microsoft.ApplicationInsights/Managed/Shared/Extensibility/MetricManager.cs#L248-L253) the aggregation interval. This property used primarily to smooth out metrics after `Flush` was called before the aggregation period ended.

##APIs of other metrics solutions:

***AWS CloudWatch***

http://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html
http://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_PutMetricData.html
http://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html

***SignalFX***

https://developers.signalfx.com/docs/metric-data-overview
https://docs.signalfx.com/en/latest/concepts/metric-types.html
https://developers.signalfx.com/reference#datapoint

***Google StackDriver***

https://cloud.google.com/monitoring/custom-metrics/creating-metrics
https://cloud.google.com/monitoring/api/ref_v3/rest/v3/projects.timeSeries/create
https://cloud.google.com/monitoring/api/v3/metrics

