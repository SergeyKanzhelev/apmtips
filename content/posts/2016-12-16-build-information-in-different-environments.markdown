---
layout: post
title: "Build information in different environments"
date: 2016-12-16 10:08:23 -0800
comments: true
aliases: [/blog/2016/12/16/build-information-in-different-environments/]
categories: 
- Versioning
---
I wrote [before](http://apmtips.com/blog/2015/06/18/application-versioning-semantic-or-automatic/) about automatic telemetry versioning you can implement for ASP.NET apps. With a single line change in the project file you can generate the `BuildInfo.config` file. This file contains the basic build information including build id.  

Note, that when you build an application locally - `BuildInfo.config` will be generated under `bin/` folder and will have `AutoGen_<GUID>` build id. With the new VSTS build infrastracture, the same `AutoGen_` appears in production builds as well.

The reason is that VSTS build infrastructure defined a new build property names. Specifically, `BuildUri` was renamed to `Build.BuildUri`. [Here](https://www.visualstudio.com/en-us/docs/build/define/variables#predefined-variables) is the list of all predefined variables in VSTS builds. So the fix for `BuildInfo.config` generation is easy:

``` xml
<BuildUri Condition="$(BuildUri) == ''">$(Build_BuildUri)</BuildUri>
<GenerateBuildInfoConfigFile>true</GenerateBuildInfoConfigFile>
```

You can review the file `C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v14.0\BuildInfo\Microsoft.VisualStudio.ReleaseManagement.BuildInfo.targets` for other properties that got broken. For instance, you may want to fix `BuildLabel` as well. Fix above will make `BuildLabel` to use `BuildId`:

``` xml
<BuildLabel kind="label">vstfs:///Build/Build/3497900</BuildLabel>
<BuildId kind="id">vstfs:///Build/Build/3497900</BuildId>
```

instead of

```
build id: 3497900
build name: 20161214.1
```

You can use the same trick for Azure Web Apps. When you set continues integration for Azure Web App from github - Kudu will download sources and build them locally. Every deployment is identified by commit ID. So you can set `buildId` like I did it in this [commit in Glimpse.ApplicationInsights](https://github.com/Glimpse/Glimpse.ApplicationInsights/commit/7e5aeb37764b195a721d193be2b3ab8601276ef4):

```
<BuildId Condition="$(BuildId) == ''">$(SCM_COMMIT_ID)</BuildId>
<GenerateBuildInfoConfigFile>true</GenerateBuildInfoConfigFile>
```

Once implemented I can see the deployment id as an application version in Glimpse:

{% img /images/2016-12-16-build-information-in-different-environments/glimpse-version.png 'Glimpse version' %}

You can also filter by it in azure portal:

{% img /images/2016-12-16-build-information-in-different-environments/portal-version.png 'Portal version' %}

Using this deployment ID you can query deployment information using the link `https://%WEBSITE_HOSTNAME%.scm.azurewebsites.net/api/deployments/<deployment id>` to see something like this:

``` xml
{
  "id": "7e5aeb37764b195a721d193be2b3ab8601276ef4",
  "status": 4,
  "status_text": "",
  "author_email": "SergKanz@microsoft.com",
  "author": "Sergey Kanzhelev",
  "deployer": "GitHub",
  "message": "commit ID\n",
  "progress": "",
  "received_time": "2016-12-14T21:59:50.8705503Z",
  "start_time": "2016-12-14T21:59:51.0919654Z",
  "end_time": "2016-12-14T22:05:29.940095Z",
  "last_success_end_time": "2016-12-14T22:05:29.940095Z",
  "complete": true,
  "active": true,
  "is_temp": false,
  "is_readonly": false,
  "url": "https://ai-glimpse-web-play-develop.scm.azurewebsites.net/api/deployments/7e5aeb37764b195a721d193be2b3ab8601276ef4",
  "log_url": "https://ai-glimpse-web-play-develop.scm.azurewebsites.net/api/deployments/7e5aeb37764b195a721d193be2b3ab8601276ef4/log",
  "site_name": "ai-glimpse-web-play"
}
```

As mentioned in [this](https://github.com/projectkudu/kudu/issues/1897) issue you may also override `BuildId` for other platforms. For AppVeyor it seems that this property will work: `APPVEYOR_BUILD_VERSION`.
