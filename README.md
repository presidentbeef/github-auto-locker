## GitHub AutoLocker

Automatically locks old GitHub issues that have already been closed.

By default it locks closed issues that are over 120 days old.

### Usage

This requires Ruby.

From source:

* Clone or download repo
* Run `./bin/github-auto-locker USER REPO TOKEN [age in days]`

As a gem:

* Run `gem install github-auto-locker`
* Run `github-auto-locker USER REPO TOKEN [age in days]`

The age is optional.

`TOKEN` is a personal access token from [here](https://github.com/settings/tokens). It will require the 'repo' scope.

### License

MIT
