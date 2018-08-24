# Richard Hsu's Blog

This repository is for my Jekyll Blog that I hope to update with anything and
everything! Come join me on my adventures!

## Previewing

To preview it you can run the following to build after changes are made and then serve to view locally:

```
bundle exec jekyll build
bundle exec jekyll serve
```

## Publishing

```
rake publish
```

This will `build`, `commit`, and `deploy` which can each be run separately as
tasks for each step.

### Algolia Indexing

```
bundle exec jekyll algolia
```

You'll need to make sure you have `ALGOLIA_API_KEY` in  your environment otherwise you'll have to execute:

```
ALGOLIA_API_KEY='{your_admin_api_key}' bundle exec jekyll algolia
```

The key can be found on the Algolia dashboard.

## Structure

Jekyll is built from the `source` branch and upon building stores in `_site`
folder. The `deploy` command will commit it to the `master` branch for serving.
