---
layout: post
title: "This blog is running on k8s now"
date: 2020-06-30 17:07:00 -0700
comments: true
categories: 
---

This blog is now running on kubernetes on Google Kubernetes Engine. This is clearly an overkill for such a simple static web site, but I have many plans on trying things in GKE.

With the switch to GKE, I also made a few changes:

- Switched from Octopress to [hugo](https://gohugo.io/).
- Set up Google [Cloud Build](https://cloud.google.com/cloud-build) as a CI/CD.
- Switched the domain from GoDaddy to [domains.google](https://domains.google).

I was surprised how easy the switch was. Domain migrated in a few minutes, it was quite straightforward to follow the guides on configuring custom domain with certificate on GKE Ingress. Posts in markdown were (almost) compatible with Hugo.

There are still so much polishing left. But it's working and with hugo and new CD pipeline - easier for me to post. So worth switching now. Please comment if there are any issues.