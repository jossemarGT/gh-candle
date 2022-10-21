# Contributing

First, thank you for consider contributing into this tool!

## Pull Request Process

1. State the nature of your Pull Request on its description.
2. Update the README.md with details of changes to the interface, this includes
   new environment variables or flags/options.
3. You may merge the Pull Request in once you have the sign-off from the
   maintainer.

## Styleguides

### Git Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line
* When only changing documentation, include `[ci skip]` in the commit title

### Shell

* Use standard POSIX shell (No bash, zsh, fish magic allowed)
* Always check your changes using `shellcheck`
* When an user value is optional, it should be an option flag parsed by `getops`
* Each option flag should be overridable with an environment variables

### Markdown

* The preferred line lenght is 80 collumns, but exceptions may apply (ie: links
  or code blocks)
* Always check your changes using [markdown-lint](https://github.com/igorshubovych/markdownlint-cli)
