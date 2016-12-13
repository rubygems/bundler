# Releasing

Bundler users [Semantic Versioning](http://semver.org/).

_Note: In the documentation listed below, the *current* minor version number is
1.11 and the *next* minor version number is 1.12_

Regardless of the version, *all releases* must update `CHANGELOG.md` and `version.rb`
files. The changelog for the first stable minor release (`1.12.0`) is a sum of all
the preceding pre-release versions (`1.12.pre.1`, `1.12.pre.2`, etc) for that
minor version. The changelog for the first stable minor release is left blank
unless there are fixes included since the last pre/rc release.

## Workflow

In general, `master` will accept PRs for:

* feature merges for the next minor version (1.12)
* regression fix merges for a patch release on the current minor version (1.11)

### Breaking releases

Bundler cares a lot about preserving compatibility. As a result, changes that
break backwards compatibility should (whenever this is possible) include a feature
release that is backwards compatible, and issue warnings for all options and
behaviors that will change.

### Cherry picking

When we cherry-pick, we cherry-pick the merge commits using the following command:

```
$ git cherry-pick -m 1 MERGE_COMMIT_SHAS
```

For example, for PR [#5029](https://github.com/bundler/bundler/pull/5029), we 
cherry picked commit [dd6aef9](https://github.com/bundler/bundler/commit/dd6aef97a5f2e7173f406267256a8c319d6134ab),
not [4fe9291](https://github.com/bundler/bundler/commit/4fe92919f51e3463f0aad6fa833ab68044311f03)
using:

```
$ git cherry-pick -m 1 dd6aef9
```

## Releases

### Minor releases

While pushing a gem version to RubyGems.org is as simple as `rake release`,
releasing a new version of Bundler includes a lot of communication: team consensus,
git branching, changelog writing, documentation site updates, and a blog post.

Dizzy yet? Us too.

Here's the checklist for releasing new minor versions:

- [ ] Check with the core team to ensure that there is consensus around shipping a
feature release. As a general rule, this should always be okay, since features
should _never break backwards compatibility_
- [ ] Create a new stable branch from master (see **Branching** below)
- [ ] Update `version.rb` to a prerelease number, e.g. `1.12.pre.1`
- [ ] Update `CHANGELOG.md` to include all of the features, bugfixes, etc for that
version
- [ ] Run `rake release`, tweet, blog, let people know about the prerelease!
- [ ] Wait a **minimum of 7 days**
- [ ] If significant problems are found, increment the prerelease (i.e. 1.12.pre.2)
and repeat

Wait! You're not done yet! After your prelease looks good:

- [ ] Update `version.rb` to a final version (i.e. 1.12.0)
- [ ] In the [bundler/bundler-site](https://github.com/bundler/bundler-site) repo,
copy the previous version's docs to create a new version (e.g. `cp -r v1.11 v1.12`)
- [ ] Update the new docs as needed, paying special attention to the "What's new"
page for this version
- [ ] Write a blog post announcing the new version, highlighting new features and
notable bugfixes
- [ ] Run `rake release`, tweet, link to the blog post, etc.

At this point, you're a release manager! Pour yourself several tasty drinks and
think about taking a vacation in the tropics.

#### Branching

Minor releases of the next version start with a new release branch from the
current state of master: `1-12-stable`

From that release branch, we create the first pre-release branch for that minor
version: `1-12-0-pre-1`. Until `1-12-0-pre-1` is ready for release, all active
development is done in that branch.

If `1-12-0-pre-1` is released with bugs and another prerelease version is needed,
**WAIT REALLY HOW DOES THE BRANCHING WORK HERE**????? 

### Patch releases (bug fixes!)

Releasing new bugfix versions is really straightforward. Increment the tiny version
number in `lib/bundler/version.rb`, and in `CHANGELOG.md` add one bullet point
per bug fixed. Then run `rake release` and pour yourself a tasty drink!

PRs containing regression fixes for a patch release of the current minor version
are merged to master. These commits are then cherry-picked from master onto the
minor branch (`1-12-stable`).

Patch releases are created from the diff between the last release (`1-12-0-pre-1`)
and the current minor branch (`1-12-stable`).

