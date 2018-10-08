# Publisher

A GitHub App to publish your non-Jekyll content in `master` directly to `gh-pages`.

## Setup

First, deploy this code to Heroku (or some other server you own). It will need to have redis installed

Next, you'll need to set an environment variable:

| Option | Description
| :----- | :----------
| `SECRET_TOKEN` | **Required**. This establishes a private token to secure your payloads. This token is used to [verify that the payload came from GitHub](https://developer.github.com/webhooks/securing/).
| `REDIS_URL` | **Required**.  A URL to a running redis service.
| `GITHUB_APP_ID` | **Required**. The ID of your GitHub App.
| `GITHUB_APP_PEM` | **Required**. The path to your App's PEM file.

On your GitHub Pages repository, set a webhook up to hit the `/build` endpoint.

On each push to `master`, this webhook will call `rake publish` on your repository, which is assumed to build your site and push it to `gh-pages`.
