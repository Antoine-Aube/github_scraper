# GitHub Scraper Challenge

## Objective

Build a scaper in Ruby of Github data. Use ActiveRecord for writing data into the database.

## Requirements

For all repositories in the Vercel organization, retrieve the following data:

- All public repositories for Vercel
- All pull requests for each repository
- All reviews for each pull request
- All github users who opened a pull request in a Vercel repo or did a review on one of the PRs

## Bonus

Not a requirement, but bonus if you can make it so your importer can handle rate limiting or any other errors it may encounter.

## Data points to store
- Name of repository
- URL to the repository
- Whether a repo is private or not
- Whether a repo is archived or not
- PR number
- PR title
- PR updated time
- PR closed time
- PR merged time
- PR author
- PR additions
- PR deletions
- PR changed files
- PR number of commits
- Who authored a review
- State of the review
- When the review was submitted
- User's github login
