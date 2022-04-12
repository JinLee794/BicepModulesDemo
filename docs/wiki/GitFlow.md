# Git Flow

---

## _Navigation_

- [Overview](#overview)
- [Strategy](#strategy)
  - [Main Branch](#main-branch)
  - [Develop Branch](#develop-branch)
  - [Feature Branches](#feature-branches)
  - [Release Branches](#release-branches)
  - [Hotfix branches](#hotfix-branches)
  - [Support branches](#support-branches)
  - [Further Reading](#further-reading)

---

## Strategy


- When using the git-flow extension library, executing `git flow init`
 on an existing repo will create the `develop`
 branch

### Main Branch

- stores the official release history
- tag all commits to main with a version number

### Develop Branch

- integration branch for features

### Feature Branches

- `feature` branches should never interact directly with `main`
- When a `feature` is complete, it gets merged back into `develop` as their parent branch
- created off of the latest on the `develop`  branch

### Release Branches

- Once `develop` has acquired enough features for a release or a release is approaching a due date, **fork** a `release` branch off of `develop`
  - this starts the release cycle
- Once a release cycle is started
  - **NO** new features can be added after this point
  - **ONLY** bug fixes, documentation generation, and other release-oriented tasks
- When ready to ship your release:
  - Merge the `release` branch into `main`
    - tag it and version it
  - Merge the `release` branch into `develop`
- Benefits of this:
  - multi team collaboration to allow dedicated resources to work on release, while others work on new features for next cycle

### Hotfix branches

- Works directly with `main` branch
- very similar to `release` and `feature` branches
  - based on `main` instead of `develop` (which `release` and `feature` branches rely on)
- Used to quickly patch **production** releases
- also similar to the `release` branch, `hotfix` branch gets merged into both `main` and `develop` once finished
- Benefits of this:
  - `hotfix` or `maintenance` branches allow your teams to address issues without interrupting the rest of the workflow or waiting for the next release cycle

### Support branches

- Usually not used for smaller projects
- Essential if maintaining multiple major versions in parallel
- Can be used to support minor or major releases
  - `support/<major>.x`
    - i.e `support/1.x`
  - `support/<major>.<minor>.x` or `support/<major>.<minor>.0`
    - i.e `support/1.3.x` or `support/1.3.0`

## Further Reading

[Gitflow Workflow | Atlassian Git Tutorial](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)

[Creating a branch to work on an issue - GitHub Docs](https://docs.github.com/en/issues/tracking-your-work-with-issues/creating-a-branch-for-an-issue)

[Linking a pull request to an issue - GitHub Docs](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue)

[About code owners - GitHub Docs](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
