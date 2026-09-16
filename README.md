# webteam-devops

This repository contains a collection of utilities for DevOps which are used at Canonical's 
Web Engineering department deploying and managing web applications. The main contents of the
repository are the GitHub scripts/actions, which are to be called fro each repository in
order to set up the builds and deployments for the project.

For more information see the `docs` folder.
You should start with [/docs/ps7_setup.md](https://github.com/canonical/webteam-devops/blob/main/docs/ps7_setup.md)
in order to learn how to set up CI/CD for your project.

Inside `/docs/workflows/` there's information about workflows details.

## Terraform plans

You can find the Terraform plans that can be deployed with this actions in the internal
repository of [webteam-terraform-plan](https://github.com/canonical/webteam-terraform-plans),
along with a brief Terraform introduction.
