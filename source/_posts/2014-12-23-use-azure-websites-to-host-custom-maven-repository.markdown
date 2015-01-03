---
layout: post
title: "Use Azure WebSites to host custom maven repository"
date: 2014-12-23 09:37:28 -0800
comments: true
categories: 
- Java
- Azure WebSites
---
I was trying to set up a temporary maven repository to share java libraries. It turns out you can easily do it for free using azure WebSites. Here are step-by-step instructions:

* Create Azure WebSite. Name "m2" was already taken so I took dotm2 - here it is: [http://dotm2.azurewebsites.net/](http://dotm2.azurewebsites.net/).
* Obtain ftp location and deployment credentials. I'd recommend to use site-specific credentials, not user ones. The difference is [explained here](https://github.com/projectkudu/kudu/wiki/Deployment-credentials). In ibiza portal you need to open web site blade and find "Get publish profile" button in blade's title. It is not visible by default so you'll need to click on "..." in the blade's title. I got file like this:
``` xml
<publishData>
	<...>
	<publishProfile 
		profileName="dotm2 - FTP" 
		publishMethod="FTP" 
		publishUrl="ftp://waws-prod-dm1-003.ftp.azurewebsites.windows.net/site/wwwroot" 
		ftpPassiveMode="True" 
		userName="dotm2\$dotm2" 
		userPWD="password goes here" 
	</publishProfile>
</publishData>
```
Now you can access web site content by FTP. 

* Since I've already opened FTP window to try out deployment credentials - I'll make one last piece of website configuration. Enable directory browsing. Just create a web.config under "site/wwwroot" with this content:
 
``` xml
<configuration>
	<system.webServer>
		<directoryBrowse enabled="true" showFlags="Date,Time,Extension,Size" />
	</system.webServer>
	<staticContent>
		<mimeMap fileExtension=".pom" mimeType="application/xml" />
		<mimeMap fileExtension=".md5" mimeType="text/plain" />
		<mimeMap fileExtension=".sha1" mimeType="text/plain" />
	</staticContent>
</configuration>
```

***update(1/3/2015):** At the moment of publication I forgot to configure mime types so pom files wasn't accessible and gradle wasn't able to resolve dependencies*

* Now FTP deployer can be used to upload jars to my repository. If you are using gradle [maven plugin](http://www.gradle.org/docs/current/userguide/maven_plugin.html) can be configured like shown below (build.gradle file):

``` groovy
apply plugin: 'maven'

configurations {
    deployerJars
}

repositories {
    mavenCentral()
}

dependencies { 
    deployerJars "org.apache.maven.wagon:wagon-ftp:2.8"
} 

version = "1.0.0-SNAPSHOT"
group = "com.microsoft.applicationinsights"

uploadArchives {
    repositories {
        mavenDeployer {
            configuration = configurations.deployerJars

            repository(url: "ftp://waws-prod-dm1-003.ftp.azurewebsites.windows.net/site/wwwroot/repository/") { 
                authentication(userName: "dotm2\\\$dotm2", password:javamavenuserpassword)
            }
         }
    }
}
```

Note, I've used variable "javamavenuserpassword" that you'll need to supply to gradle to upload artifacts. 

* Build and upload artifacts:
```
gradlew uploadArchives -Pjavamavenuserpassword=<password goes here>
```

That's it. Now you can use artifacts from your repository like this:

``` groovy
repositories {
    mavenCentral()

    maven {
        url 'http://dotm2.azurewebsites.net/repository/'
    }
}
```