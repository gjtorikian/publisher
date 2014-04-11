Publisher
===============

Publishes your non-Jekyll content in `master` directly to `gh-pages`.

## Setup

1. Deploy this code to Heroku (or some other server you own).
2. Set an environment variable there called `BUILD_TOKEN` that establishes a private token. There are two reasons for this:
  * This token will be the acting user for Git changes (so make sure it has access to your repo).
  * This token ensures that no one can trigger some arbitrary changes by randomly sending a `POST`.

On your repository, set a webhook up to hit the `/build` endpoint.
Pass in just a single parameter, `token`, which is a very secret token.

On each push to `master`, this webhook will call `rake publish` on your repository.
