# GH Candle 🕯️

Generate contribution graphs "shadows" from other GitHub accounts *that belong to you*.

Let's say by whims of fate, you had to create one or more separate GitHub
accounts that reflect most of your activity, and now your personal one looks so
sad. Then you wonder if only there was a way to synchronize GH contribution
graphs... Well, say no more! Although there is no official way to do so, there
are ways to mimic it with *GH candle* 🕯️.

## Prerequisites

GH candle should work as long you have the following tools installed on your
machine:

- `git` - <https://git-scm.com/book/en/v2/Getting-Started-Installing-Git>
- `gh` - <https://cli.github.com/manual/installation>

Also the tool assumes you already have a
[GitHub personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
exposed as the `GH_TOKEN` environment variable.

## Make it run 🔥

```
./light.sh my-second-github-account
```

## FAQ

- **How come this repository is named "GH candle"?** Well, the reality is that
  there is no *simple* way of fully synchronizing GH contribution graphs, so
  this tool only "casts shadows" of them. And yeah, shadows, since those aren't
  the real thing but look alike from a distance.
