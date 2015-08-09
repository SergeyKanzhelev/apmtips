---
layout: post
title: "Application Insights for desktop applications"
date: 2015-08-08 09:21:47 -0700
comments: true
categories:
- Application Insights 
---

1.	Install [Application Insights API NuGet](https://www.nuget.org/packages/Microsoft.ApplicationInsights/).
2.	Track usage:
https://azure.microsoft.com/documentation/articles/app-insights-windows-usage/
Track Failures: https://azure.microsoft.com/documentation/articles/app-insights-api-custom-events-metrics/
Or even diagnostics logs: https://azure.microsoft.com/documentation/articles/app-insights-diagnostic-search/

3.	By default – in-memory channel will be used to communicate with the Application Insights backend. This channel has no persistence of events and will lose data if internet connection is not reliable. You may use this channel if it is important for you to guarantee delivery of telemetry events: https://www.nuget.org/packages/Microsoft.ApplicationInsights.PersistenceChannel/ 


``` csharp
private async void buttonClick_requestCurrentTemperature(object sender, RoutedEventArgs e)
{
    var zip = zipTextBox.Text;
    var apiUrl = string.Format("http://api.openweathermap.org/data/2.5/weather?units=metric&zip={0},us", zip);

    HttpClient client = new HttpClient();
    var result = await client.GetStringAsync(apiUrl);

    JObject o = JObject.Load(new JsonTextReader(new StringReader(result)));
    var temperature = o.SelectToken("main.temp").Value<float>();
    label.Content = temperature.ToString();
}
```

``` csharp
private readonly TelemetryClient telemetryClient;

public MainWindow()
{
    TelemetryConfiguration config = TelemetryConfiguration.CreateDefault();
    config.InstrumentationKey = "Foo";
    config.TelemetryChannel = new PersistenceChannel();
    config.TelemetryChannel.DeveloperMode = Debugger.IsAttached;
    telemetryClient = new TelemetryClient(config);
    
    InitializeComponent();
}

```

``` csharp
telemetryClient.TrackEvent("TemperatureRequested", new Dictionary<string, string>() { { "zip", zip } });
```

``` csharp
private async void buttonClick_requestCurrentTemperature(object sender, RoutedEventArgs e)
{
    var timer = Stopwatch.StartNew();
    var zip = this.zipTextBox.Text;
    var apiUrl = string.Format("http://api.openweathermap.org/data/2.5/weather?units=metric&zip={0},us", zip);

    try
    {
        HttpClient client = new HttpClient();
        var result = await client.GetStringAsync(apiUrl);

        JObject o = JObject.Load(new JsonTextReader(new StringReader(result)));
        var temperature = o.SelectToken("main.temp").Value<float>();
        this.label.Content = temperature.ToString();
    }
    finally
    {
        telemetryClient.TrackEvent("TemperatureRequested", 
            new Dictionary<string, string>() { { "zip", zip } },
            new Dictionary<string, double>() { { "duration", timer.ElapsedMilliseconds } });
    }
}
```


Application Insights Telemetry: {"name":"Microsoft.ApplicationInsights.Dev.foo.Event","time":"2015-08-08T10:55:35.0275391-07:00","iKey":"Foo","tags":{"ai.internal.sdkVersion":"1.2.0.5639"},"data":{"baseType":"EventData","baseData":{"ver":2,"name":"TemperatureRequested","measurements":{"duration":773},"properties":{"zip":"98052","DeveloperMode":"true"}}}}