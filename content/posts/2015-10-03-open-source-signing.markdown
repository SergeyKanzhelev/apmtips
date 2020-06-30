---
layout: post
title: "Open source signing"
date: 2015-10-03 18:55:21 -0700
comments: true
aliases: [/blog/2015/10/03/open-source-signing/]
categories: 
- Application Insights
- Development
---
We enabled open source signing for Application Insights SDK on [github](https://github.com/microsoft/applicationInsights-dotnet). Open source signing allows you to build assembly that matches identity of those officially built by Microsoft.

When you import Application Insights [NuGet package](https://www.nuget.org/packages/Microsoft.ApplicationInsights/1.2.0) reference like this will be added to your project. Note that this reference is added to the assembly with the specific public key token: 

``` xml
<Reference Include="Microsoft.ApplicationInsights, PublicKeyToken=31bf3856ad364e35, Version=2.0.0.0, Culture=neutral, processorArchitecture=MSIL">
	<HintPath>..\packages\Microsoft.ApplicationInsights.2.0.0.0\lib\net45\Microsoft.ApplicationInsights.dll</HintPath>
	<Private>True</Private>
</Reference>
```

You may also have some already compiled assemblies that has a reference to Application Insights SDK. Those references would also be on strongly named assembly.

Open source signing allows you to change the code of Application Insights SDK, compile it and replace original assembly for testing. Applicaiton Insights assembly you'll compile locally will have the same public key token as one compiled by Microsoft. Here is what [sn tool](https://msdn.microsoft.com/en-us/library/k5b5tt23.aspx) will output: 

```
>sn -Tp Microsoft.ApplicationInsights.dll

Microsoft (R) .NET Framework Strong Name Utility  Version 4.0.30319.18020
Copyright (c) Microsoft Corporation.  All rights reserved.

Public key (hash algorithm: sha1):
0024000004800000940000000602000000240000525341310004000001000100b5fc90e7027f6
7871e773a8fde8938c81dd402ba65b9201d60593e96c492651e889cc13f1415ebb53fac1131ae
0bd333c5ee6021672d9718ea31a8aebd0da0072f25d87dba6fc90ffd598ed4da35e44c398c454
307e8e33b8426143daec9f596836f97c8f74750e5975c64e2189f45def46b2a2b1247adc3652b
f5c308055da9

Public key token is 31bf3856ad364e35
```

So you don't need to change public key token in project file and you don't need to recompile other assemblies referring Application Insights SDK. You can just replace a file and test your changes.

There are some limitations with open source signing. First, strong name verification will obviously fail:

```
>sn -vf Microsoft.ApplicationInsights.dll

Microsoft (R) .NET Framework Strong Name Utility  Version 4.0.30319.18020
Copyright (c) Microsoft Corporation.  All rights reserved.

Failed to verify assembly -- Strong name validation failed.
```

So you may need to disable verification for this public key token (don't forget to run this command for the correct bittness - x86 or x64):

```
>sn -Vr Microsoft.ApplicationInsights.dll
``` 

Next limitation is related to the behavior of ASP.NET infrastracture. Even if you turned strong name verification off on computer, your ASP.NET applicaitons will likely fail with the message like this:

```
A first chance exception of type 'System.IO.FileLoadException' occurred in mscorlib.dll

Additional information: Could not load file or assembly 'Microsoft.ApplicationInsights.dll, 
Version=2.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35' or one of its 
dependencies. Strong name signature could not be verified.  The assembly may have 
been tampered with, or it was delay signed but not fully signed with the correct 
private key. (Exception from HRESULT: 0x80131045)
```

The issue explained in details at [IIS forum](http://forums.iis.net/t/1220602.aspx?Skipping+Strong+Name+Assembly+for+Windows+7+IIS+7+5+still+give+an+error+Couldn+t+be+Verified+).

{% blockquote %}
When using .NET 4, shadow copying assemblies in an application for which assemblies rarely ever change has improved. In previous versions of ASP.NET, there was often a noticeable delay in application startup time while assemblies were being shadow copied. Now, the framework checks the file date/time of an application’s assemblies and compares that with the file date/time of any shadow copied assemblies. If they are the same, the shadow copying process does not occur. This causes the shadow copying process to kick off only if an assembly has been physically modified.

The process would look something like this for each assembly:
1. Copy assembly from application location to temporary location 
2. Open assembly 
3. Verify assembly name 
4. Validate strong name 
5. Compare update to current cached assembly 
6. Copy to shadow copy location (if newer) 
7. Remove assembly from temporary location 

Shadow copying is important if you are modifying assemblies directly in a live application.

But if  you want to skip strong name assembly, you must disable  shadow copying.
{% endblockquote %}

So you need to disable shadow copying for your ASP.NET application in ```web.config```:

``` xml
<system.web>
	<hostingEnvironment shadowCopyBinAssemblies="false" />
</system.web>
```

More information on open source signing can be found at [corefx documentaiton page](https://github.com/dotnet/corefx/blob/master/Documentation/project-docs/oss-signing.md).

With open source signing it is much easier to validate changes you may need in Application Insights SDK. We always happy to hear your feedback and accept your contribution! 