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
* Set deployment credentials. Open WebSite blade, click on settings tile. Now you can set deployment credentials. I set "FTP/deployment user name" to javamavenuser. 
* Now you can access your web site content by FTP. You can find FTP host name under "Properties" on the same "Settings" blade. In my case it was ftp://waws-prod-dm1-003.ftp.azurewebsites.windows.net. Note, that actual user name you should use is "dotm2\javamavenuser" - it is specific to your website.
* One last piece of website configuration is to enable directory browsing. Just create a web.config under "site/wwwroot" with this content:
 
``` xml
<configuration>
   <system.webServer>
      <directoryBrowse enabled="true" showFlags="Date,Time,Extension,Size" />
   </system.webServer>
</configuration>
```

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
                authentication(userName: "dotm2\\javamavenuser", password:javamavenuserpassword)
            }
         }
    }
}
```

Note, I've used variable "javamavenuserpassword" that you'll need to supply to gradle to upload artifacts. 

* Build and upload artifacts:
```
gradlew uploadArchives -Pjavamavenuserpassword=<your password goes here>
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