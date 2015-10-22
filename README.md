Publisher
===============

Publishes your non-Jekyll content in `master` directly to `gh-pages`.

## Setup

First, deploy this code to Heroku (or some other server you own).

Next, you'll need to set a few environment variables:

| Option | Description
| :----- | :----------
| `SECRET_TOKEN` | **Required**. This establishes a private token to secure your payloads. This token is used to [verify that the payload came from GitHub](https://developer.github.com/webhooks/securing/).
| `DOTCOM_MACHINE_USER_TOKEN` | **Required**.  This is [the access token the server will act as](https://help.github.com/articles/creating-an-access-token-for-command-line-use) when syncing between the repositories.
| `MACHINE_USER_EMAIL` | **Required**. The Git email address of your machine user.
| `MACHINE_USER_NAME` | **Required**. The Git author name of your machine user.

On your GitHub pages repository, set a webhook up to hit the `/build` endpoint.

On each push to `master`, this webhook will call `rake publish` on your repository, which is assumed to build your site and push it to `gh-pages`.
