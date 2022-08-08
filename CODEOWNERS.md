# CODEOWNERS guidelines

This repo is multi-tenanted
To enable teams to be self service they are allowed to merge changes related to their own applications

The rules are simple:
1. only staging and prod are protected
1. Prod requires a review from the [@hmcts/production-apps-approvals](https://github.com/orgs/hmcts/teams/production-apps-approvals/members) team
1. Staging requires a review from [@hmcts/platform-operations](https://github.com/orgs/hmcts/teams/platform-operations/members)
1. only file name entries may be added to CODEOWNERS, no directories as that bypasses the review for new applications
1. be sensible, every change is tracked through git, don't repurpose files, create a new one for new applications

To add a new application, create an application namespace under apps and create application specific folders or create application specific folders in an existing namespace.

Ensure `apps/<namespace>` is added to CODEOWNERS

Raise a pull request adding the application to the kustomization for the cluster by appending to the kustomization file e.g. ```clusters/dev/base/kustomization.yaml```

```
  - ../../../apps/mailrelay2/base/kustomize.yaml
```


If you're adding the application to staging or prod then then add a line referring to it in CODEOWNERS, i.e. 

```
apps/mi/ @hmcts/mi
```