# webteam-devops

This repository contains a collection of utilities for DevOps which are used at Canonical's 
Web Engineering department deploying and managing web applications.

The main contents of the repository are:
- The GitHub scripts/actions, which are to be called from
each repository in order to set up the builds and deployments for the project.
- The Terraform configuration files used for deploying projects to environments on PS7+.

For more information see the `docs` folder.
You should start with [/docs/ps7_setup.md](https://github.com/canonical/webteam-devops/blob/main/docs/setup.md)
in order to learn how to set up CI/CD for your project.

If you want a quick introduction to Terraform then you can check `/docs/terraform.md`.

Inside `/docs/workflows/` there's information about workflows details.
