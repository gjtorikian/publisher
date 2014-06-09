Publisher
===============

Publishes your non-Jekyll content in `master` directly to `gh-pages`.

## Setup

1. Deploy this code to Heroku (or some other server you own).
2. Set an environment variable on that server called `SECRET_TOKEN`, which establishes a private token. This token is used to verify that the payload came from GitHub.
3. Set another environment variable on that server called `MACHINE_USER_TOKEN`. This is the access token the server will act as when performing the Git operations.

On your GitHub pages repository, set a webhook up to hit the `/build` endpoint.

On each push to `master`, this webhook will call `rake publish` on your repository, which is assumed to build your site and push it to `gh-pages`.
