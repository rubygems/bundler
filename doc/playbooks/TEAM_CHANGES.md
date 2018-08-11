# Team changes

This file documents how to add and remove team members. For the rules governing adding and removing team members, see [POLICIES](../POLICIES.md).

## Adding a new team member

Interested in adding someone to the team? Here's the process.

1. An existing team member nominates a potential team member to the rest of the team.
1. The existing team reaches consensus about whether to invite the potential member.
1. The nominator reaches out to the potential member and invites them to join the team.
1. The nominator also sends the candidate a link to [POLICIES](https://github.com/bundler/bundler/blob/master/doc/POLICIES.md#bundler-policies) as an orientation for being on the team.
1. If the potential member accepts:
    - Invite them to the maintainers Slack channel
    - Add them to the [maintainers team][org_team] on GitHub
    - Add them to the [Team page][team] on bundler.io, in the [maintainers list][maintainers]
    - Add them to the [list of team members][list] in `contributors.rake`
    - Add them to the authors list in `bundler.gemspec`
    - Add them to the owners list on RubyGems.org by running
      ```
      $ gem owner -a EMAIL bundler
      ```


## Removing a team member

When the conditions in [POLICIES](https://github.com/bundler/bundler/blob/master/doc/POLICIES.md#maintainer-team-guidelines) are met, or when team members choose to retire, here's how to remove someone from the team.

- Remove them from the owners list on RubyGems.org by running
  ```
  $ gem owner -r EMAIL bundler
  ```
- Remove their entry on the [Team page][team] on bundler.io, in the [maintainers list][maintainers]
- Remove them from the [list of team members][list] in `contributors.rake`
- Remove them from the [maintainers team][org_team] on GitHub
- Remove them from the maintainers Slack channel

[org_team]: https://github.com/orgs/bundler/teams/maintainers/members
[team]: https://bundler.io/contributors.html
[maintainers]: https://github.com/bundler/bundler-site/blob/02483d3f79f243774722b3fc18a471ca77b1c424/source/contributors.html.haml#L25
[list]: https://github.com/bundler/bundler-site/blob/02483d3f79f243774722b3fc18a471ca77b1c424/lib/tasks/contributors.rake#L8
