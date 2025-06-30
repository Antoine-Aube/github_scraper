class GithubImportJob < ApplicationJob
  queue_as :default


  # Import job to import all repositories, pull requests, and reviews for a given organization. 
  # Gets users by nature of getting saving them from the PR and review calls
  def perform(org_name = 'vercel')
    github_api_service = GithubApiService.new
    
    # Step 1: Import repositories
    repository_importer = RepositoryImporter.new(github_api_service)
    total_repos = repository_importer.import_organization_repos(org_name)
    puts "Imported #{total_repos} repositories"
    puts "Processing imports for PRs, reviews and relevant users"
    
    # Step 2: Import pull requests for each repository
    pull_request_importer = PullRequestImporter.new(github_api_service)
    Repository.find_each do |repository|
      pull_request_importer.import_repository_pull_requests(repository)
    end
    
    # Step 3: Import reviews for each pull request
    review_importer = ReviewImporter.new(github_api_service)
    Repository.find_each do |repository|
      review_importer.import_reviews_for_repository(repository)
    end
  end
end 