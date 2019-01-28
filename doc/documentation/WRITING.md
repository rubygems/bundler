# Writing docs for man pages

A primary source of help for Bundler users are the man pages: the output printed when you run `bundle help` (or `bundler help`). These pages can be a little tricky to format and preview, but are pretty straightforward once you get the hang of it.

_Note: `bundler` and `bundle` may be used interchangeably in the CLI. This guide uses `bundle` because it's cuter._

## What goes in man pages?

We use man pages for Bundler commands used in the CLI (command line interface). They can vary in length from large (see `bundle install`) to very short (see `bundle clean`).

To see a list of commands available in the Bundler CLI, type:

      $ bundle help

Our goal is to have a man page for every command.

Don't see a man page for a command? Make a new page and send us a PR! We also welcome edits to existing pages.

## Creating a new man page

To create a new man page, simply create a new `.ronn` file in the `man/` directory.

For example: to create a man page for the command `bundle cookies` (not a real command, sadly), I would create a file `man/bundle-cookies.ronn` and add my documentation there.

## Formatting

Our man pages use ronn formatting, a combination of Markdown and standard man page conventions. It can be a little weird getting used to it at first, especially if you've used Markdown a lot.

[The ronn guide formatting guide](https://rtomayko.github.io/ronn/ronn.7.html) provides a good overview of the common types of formatting.

In general, make your page look like the other pages: utilize sections like `##OPTIONS` and formatting like code blocks and definition lists where appropriate.

If you're not sure if the formatting looks right, that's ok! Make a pull request with what you've got and we'll take a peek.

## Previewing

To preview your changes as they will print out for Bundler users, you'll need to run a series of commands:

```
$ rake spec:deps
$ rake man:build
$ man man/bundle-cookies.1
```

If you make more changes to `bundle-cookies.ronn`, you'll need to run the `rake man:build` again before previewing.

## Testing

We have tests for our documentation! The most important test file to run before you make your pull request is the one for the `help` command and another for documentation quality.

```
$ bin/rspec ./spec/commands/help_spec.rb
$ bin/rspec ./spec/quality_spec.rb
```

# Writing docs for [the Bundler documentation site](https://bundler.io)

If you'd like to submit a pull request for any of the primary commands or utilities on [the Bundler documentation site](https://bundler.io), please follow the instructions above for writing documentation for man pages from the `bundler/bundler` repository. They are the same in each case.

Note: Editing `.ronn` files from the `bundler/bundler` repository for the primary commands and utilities documentation is all you need 🎉. There is no need to manually change anything in the `bundler/bundler-site` repository, because the man pages and the docs for primary commands and utilities on [the Bundler documentation site](https://bundler.io) are one in the same. They are generated automatically from the `bundler/bundler` repository's `.ronn` files from the `rake man/build` command. In other words, after updating `.ronn` file and running `rake man/build` in `bundler`, `.ronn` files map to the auto-generated files in the `source/man` directory of `bundler-site`.

Additionally, if you'd like to add a guide or tutorial: in the `bundler/bundler-site` repository, go to `/bundler-site/source/current_version_of_bundler/guides` and add [a new Markdown file](https://guides.github.com/features/mastering-markdown/) (with an extension ending in `.md`). Be sure to correctly format the title of your new guide, like so:
```
---
title: RubyGems.org SSL/TLS Troubleshooting Guide
---
```
