# GH Candle 🕯️

If you had to create one or more separate GitHub accounts that reflect most of
your activity, and now your personal GH contribution graph looks quite sad...
Say no more! There is a way to "synchronize" those activities with *GH candle*
🕯️.

<!-- Turns out you can use gists for these blobs ;) -->
![GH Contribution Graph transformation](https://gist.githubusercontent.com/jossemarGT/04f6590ad9771de163a50c79214cd544/raw/f576ad287375b1826cfa73c6b76040a616f72857/contrib-graph-transform.gif)
<!-- You say mistake in the gif, I call it easter egg! -->

**Note**: There is no *official* way to fully synchronize GH contribution
graphs, and this tool is no exception to that fact. Instead *GH candle* 🕯️
projects other GH profiles' activity into yours, you guessed it, like shadow
puppets cast by your hands in front of a candle.

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

GH candle should work as long you have the following setup in your machine:

- `git` installed - <https://git-scm.com/book/en/v2/Getting-Started-Installing-Git>
- `gh` installed - <https://cli.github.com/manual/installation>
- `GH_TOKEN` environment variable with a [GitHub personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) that has read-only access.

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

## Colophon

- The `light-on.sh` script was inspired by @[kefimochi](https://github.com/kefimochi)'s
  template repository [sync-contribution-graph](https://github.com/kefimochi/sync-contribution-graph)
- The gift on this document was generated with `transitions` utility from
  [Fred's ImageMagick Scripts](http://www.fmwconcepts.com/imagemagick/index.php)
- <!-- 👾 All your base are belong to us 👾 -->
