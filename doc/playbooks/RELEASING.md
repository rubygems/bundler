# Releasing

Bundler uses [Semantic Versioning](https://semver.org/).

_Note: In the documentation listed below, the *current* minor version number is
1.11 and the *next* minor version number is 1.12_

Regardless of the version, *all releases* must update the `CHANGELOG.md` and `lib/bundler/version.rb`
files. The changelog for the first stable minor release (`1.12.0`) is a sum of all
the preceding pre-release versions (`1.12.pre.1`, `1.12.pre.2`, etc) for that
minor version. The changelog for the first stable minor release is left blank
unless there are fixes included since the last pre/rc release.

## Workflow

In general, `master` will accept PRs for:

* feature merges for the next minor version (1.12)
* regression fix merges for a patch release on the current minor version (1.11)
* feature-flagged development for the next major version (2.0)

### Breaking releases

Bundler cares a lot about preserving compatibility. As a result, changes that
break backwards compatibility should (whenever this is possible) include a feature
release that is backwards compatible, and issue warnings for all options and
behaviors that will change.

We try very hard to only release breaking changes when incrementing the _major_
version of Bundler.

### Cherry picking

Patch releases are made by cherry-picking bug fixes from `master`.

When we cherry-pick, we cherry-pick the merge commits using the following command:

```bash
$ git cherry-pick -m 1 MERGE_COMMIT_SHAS
```

For example, for PR [#5029](https://github.com/bundler/bundler/pull/5029), we
cherry picked commit [dd6aef9](https://github.com/bundler/bundler/commit/dd6aef97a5f2e7173f406267256a8c319d6134ab),
not [4fe9291](https://github.com/bundler/bundler/commit/4fe92919f51e3463f0aad6fa833ab68044311f03)
using:

```bash
$ git cherry-pick -m 1 dd6aef9
```

The `rake release:patch` command will automatically handle cherry-picking, and is further detailed below.

## Changelog

Bundler maintains a list of changes present in each version in the `CHANGELOG.md` file.
Entries should not be added in pull requests, but are rather written by the Bundler
maintainers in the [bundler-changelog repo](https://github.com/bundler/bundler-changelog).
That repository tracks changes by pull requests, with each entry having an associated version,
PR, section, author(s), issue(s) closed, and message.

Ensure that repo has been updated with all new PRs before releasing a new version,
and copy over the new sections to the `CHANGELOG.md` in the Bundler repo.

## Releases

### Minor releases

While pushing a gem version to RubyGems.org is as simple as `rake release`,
releasing a new version of Bundler includes a lot of communication: team consensus,
git branching, changelog writing, documentation site updates, and a blog post.

Dizzy yet? Us too.

Here's the checklist for releasing new minor versions:

* [ ] Check with the core team to ensure that there is consensus around shipping a
  feature release. As a general rule, this should always be okay, since features
  should _never break backwards compatibility_
* [ ] Create a new stable branch from master (see **Branching** below)
* [ ] Update `version.rb` to a prerelease number, e.g. `1.12.pre.1`
* [ ] Update `CHANGELOG.md` to include all of the features, bugfixes, etc for that
  version, from the [bundler-changelog](https://github.com/bundler/bundler-changelog)
  repo.
* [ ] Run `rake release`, tweet, blog, let people know about the prerelease!
* [ ] Wait a **minimum of 7 days**
* [ ] If significant problems are found, increment the prerelease (i.e. 1.12.pre.2)
  and repeat, but treating `.pre.2` as a _patch release_. In general, once a stable
  branch has been cut from master, it should _not_ have master merged back into it.

Wait! You're not done yet! After your prelease looks good:

* [ ] Update `version.rb` to a final version (i.e. 1.12.0)
* [ ] In the [bundler/bundler-site](https://github.com/bundler/bundler-site) repo,
  copy the previous version's docs to create a new version (e.g. `cp -r v1.11 v1.12`)
* [ ] Update the new docs as needed, paying special attention to the "What's new"
  page for this version
* [ ] Write a blog post announcing the new version, highlighting new features and
  notable bugfixes
* [ ] Run `rake release` in the bundler repo, tweet, link to the blog post, etc.

At this point, you're a release manager! Pour yourself several tasty drinks and
think about taking a vacation in the tropics.

Beware, the first couple of days after the first non-prerelease version in a minor version
series can often yield a lot of bug reports. This is normal, and doesn't mean you've done
_anything_ wrong as the release manager.

#### Branching

Minor releases of the next version start with a new release branch from the
current state of master: `1-12-stable`, and are immediately followed by a `.pre.0` release.

Once that `-stable` branch has been cut from `master`, changes for that minor
release series (1.12) will only be made _intentionally_, via patch releases.
That is to say, changes to `master` by default _won't_ make their way into any
`1.12` version, and development on `master` will be targeting the next minor
or major release.

### Patch releases (bug fixes!)

Releasing new bugfix versions is really straightforward. Increment the tiny version
number in `lib/bundler/version.rb`, and in `CHANGELOG.md` add one bullet point
per bug fixed. Then run `rake release` from the `-stable` branch,
and pour yourself a tasty drink!

PRs containing regression fixes for a patch release of the current minor version
are merged to master. These commits are then cherry-picked from master onto the
minor branch (`1-12-stable`).

There is a `rake release:patch` rake task that automates creating a patch release.
It takes a single argument, the _exact_ patch release being made (e.g. `1.12.3`),
and checks out the appropriate stable branch (`1-12-stable`), grabs the `1.12.3`
milestone from GitHub, ensures all PRs are closed, and then cherry-picks those changes
(and only those changes) to the stable branch. The task then bumps the version in the
version file, prompts you to update the `CHANGELOG.md`, then will commit those changes
and run `rake release`!

## Beta testing

Early releases require heavy testing, especially across various system setups.
We :heart: testers, and are big fans of anyone who can run `gem install bundler --pre`
and try out upcoming releases in their development and staging environments.

There may not always be prereleases or beta versions of Bundler.
The Bundler team will tweet from the [@bundlerio account](https://twitter.com/bundlerio)
when a prerelease or beta version becomes available. You are also always welcome to try
checking out master and building a gem yourself if you want to try out the latest changes.
