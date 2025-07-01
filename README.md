# GitHub Scraper Challenge

## Project Description

This is a Ruby on Rails application that scrapes GitHub data for organizations, specifically designed to import repositories, pull requests, reviews, and users from GitHub's API. The project was built as a challenge to demonstrate full-stack development skills with a focus on data import and processing.

### What it does:
- **Repository Import**: Fetches all repositories for a specified GitHub organization(Vercel Organization if unspecified.)
- **Pull Request Import**: Imports all pull requests for each repository, including metadata like additions, deletions, and commit counts
- **Review Import**: Imports all reviews for each pull request
- **User Import**: Automatically creates user records for PR authors and reviewers
- **Data Relationships**: Maintains proper relationships between repositories, pull requests, reviews, and users

### Key Features:
- Rate limiting handling for GitHub API
- Comprehensive error handling
- Background job processing
- RSpec test coverage
- Simple command-line interface via rake tasks

## Local Setup

### Prerequisites
- Ruby 3.2.2 or higher
- PostgreSQL (must be set up on your local environment)
- GitHub Personal Access Token

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd dx_scraper_challenge
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Set up the database**
   ```bash
   rails db:create
   rails db:migrate
   ```

4. **Set your GitHub token**
   ```bash
   export GITHUB_ACCESS_TOKEN=your_github_token_here
   ```
   
   To get a GitHub token:
   - Go to https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Copy the token and set it as an environment variable in the .env file

5. **Run the import**
   ```bash
   # Import Vercel data (default)
   rails github:import
   
   # Import data for a different organization
   rails github:import[rails]
   ```

### Available Commands

```bash
# Import GitHub data
rails github:import[organization_name]

# View import statistics
rails github:stats

# Clear all imported data
rails github:clear
```

### Example Output

```
🚀 Starting GitHub import for organization: vercel
==================================================
✅ Import completed successfully!
⏱️  Duration: 45.23 seconds

📊 Import Summary:
  Repositories: 0 → 15 (+15)
  Pull Requests: 0 → 234 (+234)
  Reviews: 0 → 567 (+567)
  Users: 0 → 89 (+89)

🎉 All done! Check your database for the imported data.
```

## Testing
### To run the test

```
bundle exec rspec
```
## Potential Improvements

### 1. Better Error Handling and Logging
### 2. Automated Daily Imports with Cron
### 3. Asynchronous Import Processing

**Benefits of Asynchronous Processing**:
- Faster overall import times
- Better resource utilization
- More scalable for large organizations

