# Bundler Policies

This document is an attempt to record the policies and processes that are used to govern the Bundler project--it's not fixed or permanent, and will likely evolve as events warrant.

### Our Goals

0. Treat everyone like a valuable human being, worthy of respect and empathy. No exceptions.
1. Strive to empower users, the Ruby developers who use Bundler. For example, there is no such thing as user error, only insufficient UX design.
2. Strive to empower Bundler contributors, as long as it does not harm users. For example, potential contributors should be able to set up a complete development and testing environment with a single command.
3. Strive to empower maintainers, as long as it does not harm contributors or users. For example, automating issue triage to reduce repetitive work for maintainers, as long as users with problems are not worse off.

These policies are intended to be examples of how to apply these goals, and we realize that we can't possibly cover every edge case or loophole. In any case where policies turn out to conflict with these goals, the goals should win.

### Compatibility guidelines

Bundler tries for perfect backwards compatibility. That means that if something worked in version 1.x, it should continue to work in 1.y and 1.z. That thing may or may not continue to work in 2.x. We may not always get it right, and there may be extenuating circumstances that force us into choosing between different kinds of breakage, but compatibility is very important to us. Infrastructure should be as unsurprising as possible.

Bundler will provide features and bugfixes to older versions on a schedule similar to Ruby itself. For example, when Bundler 4.x is the current version, Bundler 4 will be eligible for new features and bugfixes. Bundler 3 will be eligible for bugfixes only. Bundler 2 will be eligible for security bugfixes only. Bundler 1 will be unsupported.

Bundler 2 and above will support Ruby and RubyGems versions for the same amount of time as the Ruby core team supports them. As of February 2018, that means no support for Bundler running on Ruby 2.2, security fixes only for Bundler running on Ruby 2.3, and full support (including new features and bugfixes) for Bundler running on Ruby 2.4 and 2.5. Unsupported Ruby versions will be dropped in the first Bundler minor release after support ends.

These policies are not a guarantee that any particular fix will be backported. Instead, this is a way for us to set an upper limit on the versions of Ruby, RubyGems, and Bundler that we have to consider while making changes. Without the limit, the number of versions grows exponentially over time and quickly becomes overwhelming, which leads to maintainer burnout. We want to avoid that.

### User experience guidelines

The experience of using Bundler should not include surprises. If users are surprised, we did something wrong, and we should fix it. There are no user errors, only UX design failures. Warnings should always include actionable instructions to resolve them. Errors should include instructions, helpful references, or other information to help users attempt to debug.

Changing existing behavior is also surprising. If reducing user surprise will result in a backwards-incompatible change, that change should include at least one major version of deprecation warning before the breaking change is made.

### Issue guidelines

Anyone is welcome to open an issue, or comment on an issue. Issue comments without useful content (like “me too”) may be removed.

Opening an issue to ask for help may eventually get you help, but chances are help will arrive faster if you post on [Stack Overflow](https://stackoverflow.com) or ask in [the Bundler Slack](https://slack.bundler.io).

Issues will be handled as soon as possible, which may take some time. Including a script that can be used to reproduce your issue is a great way to help maintainers help you. If you can, writing a failing test for your issue is even more helpful.

### Contribution and pull request guidelines

Anyone is welcome to [contribute to Bundler](README.md). Contributed code will be released under the same license as the existing codebase.

Pull requests must have passing tests to be merged. Code changes must also include tests for the new behavior. Squashing commits is not required.

Every pull request should explain:

1. The problem being solved
2. Why that problem is happening
3. What changes to fix that problem are included in the PR, and
4. Why that implementation was chosen out of the possible options.

### RFC guidelines

Large changes often benefit from being written out more completely, read by others, and discussed. The [Bundler RFC repo](https://github.com/bundler/rfcs) is the preferred place for that to happen.

### Maintainer team guidelines

Always create pull requests rather than pushing directly to the primary branch. Try to get code review and merge approval from someone other than yourself whenever possible. Always merge using `@bundlerbot` to guarantee the primary branch stays green.

Contributors who have contributed regularly for more than six months (or implemented a completely new feature for a minor release) are eligible to join the maintainer team. Unless vetoed by an existing maintainer, these contributors will be asked to join the maintainer team. If they accept, new maintainers will be given permissions to view maintainer playbooks, accept pull requests, and release new versions.

### Release guidelines

Bugfix releases should generally be cut as soon as possible. Multiple bugfix releases are preferable to waiting for a specific fix to land.

Minor/feature releases can be cut anytime at least one new feature is ready, but don't have to be. Minor version releases should include an update to the documentation website, allowing users to view the documentation for whatever minor version they happen to be using.

Major version releases should be cut no more than once per year, ideally between Ruby's release on December 25 and February 15 of the next year. Releasing soon after Ruby helps us stay in sync with deprecated Ruby versions. Breaking changes other than dropping support for old Ruby versions should be avoided whenever possible, but may be included in major releases. In general, breaking changes should include at least one major version with a deprecation warning before the breaking change takes effect.

### Enforcement guidelines

First off, Bundler's policies and enforcement of those policies are subsidiary to [Bundler's code of conduct](https://github.com/rubygems/bundler/blob/master/CODE_OF_CONDUCT.md) in any case where they conflict. The first priority is treating human beings with respect and empathy, and figuring out project guidelines and sticking to them will always come after that.

When it comes to carrying out our own policies, we're all regular humans trying to do the best we can. There will probably be times when we don't stick to our policies or goals. If you notice a discrepancy between real-life actions and these policies and goals, please bring it up! We want to make sure that our actions and our policies line up, and that our policies exemplify our goals.

Policies are not set in stone, and may be revised if policy violations are found to be in the spirit of the project goals. Likewise, actions that violate the spirit of the project goals will be considered policy violations, and enforcement action will be taken. We're not interested in rules-lawyering, and we will take action when needed to ensure that everyone feels safe and included.

If you are comfortable reporting issues to the entire Bundler team, please send an email to team@bundler.io. If you are not comfortable reporting to the entire team, for any reason, please check the [maintainers team list](https://bundler.io/team) and use email, Twitter, or Slack to report to a single maintainer of your choice. Anyone violating a policy or goal is expected to cooperate with the team (and the reporter, if they request it) to resolve the issue in a way that follows the project goals.
