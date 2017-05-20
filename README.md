## GitHub AutoLocker

Automatically locks old GitHub issues that have already been closed.

By default it locks closed issues that are over 120 days old.

### Usage

This requires Ruby.

From source:

* Clone or download repo
* Run `./bin/github-auto-locker USER REPO TOKEN [age in days] [-n]`

As a gem:

* Run `gem install github-auto-locker`
* Run `github-auto-locker USER REPO TOKEN [age in days]`[-n]

The age is optional.

`TOKEN` is a personal access token from [here](https://github.com/settings/tokens). It will require the 'repo' scope. Alternatively, credentials will be loaded from `~/.config/hub` if it exists.

`-n` can be used to perform a dry run and show which issues *would* be locked, but does not make any changes.

### License

MIT
