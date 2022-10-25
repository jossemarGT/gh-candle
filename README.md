# GH Candle 🕯️

If you had to create one or more separate GitHub accounts that reflect most of
your activity, and now your personal GH contribution graph looks quite sad...
Say no more! There is a way to "synchronize" those activities with *GH candle*
🕯️.

<!-- TODO: Before and after image here -->

Before we continue, I must confess that there is no *simple* way of fully
synchronizing GH contribution graphs, and this tool does not do that exactly. In
reality, *GH candle* 🕯️ simply casts other GH profile activity into yours, you
guessed it, like shadow puppets done by your hand in front of a candle.

## Make it run 🔥

You could clone this repository then run the script locally like this

```sh
GH_TOKEN=XXXXXX ./light-on.sh my-second-github-account
```

Or you could inmediately execute it right after you fetch it from internet, like
this

```sh
export GH_TOKEN=XXXXXX
curl -sfL https://raw.githubusercontent.com/jossemarGT/gh-candle/master/light-on.sh | sh -s my-second-github-account
```

## Prerequisites 🔔

GH candle should work as long you have the following tools installed on your
machine:

- `git` - <https://git-scm.com/book/en/v2/Getting-Started-Installing-Git>
- `gh` - <https://cli.github.com/manual/installation>

Also the tool assumes you already have a
[GitHub personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
exposed as the `GH_TOKEN` environment variable.

## When in doubt use -h

```sh
$ ./light-on.sh -h
usage: ./light-on.sh [-b <git branch>] [-g <git path>] [-d] [-h] <GitHub handle>
  -g    set local git repository for activity shadowing. Default: '.'
  -b    set local git branch for activity shadowing. Default: 'shadow/<GitHub handle>'
  -d    dry-run
  -h    show help

environment variables overrides:
  GH_TOKEN   - GH Personal access token, used for GH API lookups. Default: <empty>
  DATE_START - GH graph to be synced start date. Default: 2021-10-18T00:00:00.000+00:00
  DATE_END   - GH graph to be synced end date, uses "today" when empty. Default: <empty>
  DEBUG      - When set, prints out debug messages

examples:
  GH_TOKEN='xxxxxx' ./light-on.sh octocat
```
