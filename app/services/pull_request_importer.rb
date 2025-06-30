class PullRequestImporter
  def initialize(github_api_service = GithubApiService.new)
    @github_api_service = github_api_service
  end

  def import_repository_pull_requests(repository)
    Rails.logger.info "Starting import of pull requests for repository: #{repository.name}"
    
    page = 1
    total_imported = 0
    
    loop do
      Rails.logger.info "Fetching pull requests page #{page} for #{repository.name}"
      
      # Parse owner and repo name from repository name
      owner, repo_name = parse_repository_name(repository.name)
      Rails.logger.info "Parsed owner: #{owner}, repo: #{repo_name}"
      
      pull_requests = @github_api_service.get_repository_pull_requests(
        owner,
        repo_name,
        page: page, 
        per_page: 100
      )
      Rails.logger.info "API returned #{pull_requests.length} pull requests"
      break if pull_requests.empty?
      
      Rails.logger.info "Received #{pull_requests.length} pull requests from API"
      
      imported_count = import_pull_requests(pull_requests, repository)
      total_imported += imported_count
      
      Rails.logger.info "Imported #{imported_count} pull requests from page #{page}"
      
      # If we got less than 100 PRs, we've reached the end
      break if pull_requests.length < 100
      
      page += 1
    end
    
    Rails.logger.info "Completed import of #{total_imported} pull requests for #{repository.name}"
    total_imported
  end

  private

  def parse_repository_name(repo_name)
    # Handle both "owner/repo" and "repo" formats
    if repo_name.include?('/')
      parts = repo_name.split('/')
      [parts.first, parts.last]
    else
      # Default to 'vercel' as owner if no owner specified
      ['vercel', repo_name]
    end
  end

  def import_pull_requests(pull_requests_data, repository)
    Rails.logger.info "Starting import_pull_requests with #{pull_requests_data.length} PRs"
    imported_count = 0
    
    pull_requests_data.each do |pr_data|
      begin
        Rails.logger.info "Processing PR ##{pr_data['number']}: #{pr_data['title']}"
        pull_request = find_or_create_pull_request(pr_data, repository)
        Rails.logger.info "find_or_create_pull_request returned: #{pull_request.inspect}"
        imported_count += 1 if pull_request&.persisted?
        Rails.logger.info "Successfully processed PR ##{pr_data['number']}"
      rescue => e
        Rails.logger.error "Failed to import pull request #{pr_data['number']}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
    
    Rails.logger.info "import_pull_requests finished, imported: #{imported_count}"
    imported_count
  end

  def find_or_create_pull_request(pr_data, repository)
    author = find_or_create_user(pr_data['user'])
    return nil unless author

    pr = PullRequest.find_or_initialize_by(number: pr_data['number'], repository: repository)
    pr.title = pr_data['title']
    pr.updated_at = pr_data['updated_at']
    pr.closed_at = pr_data['closed_at']
    pr.merged_at = pr_data['merged_at']
    pr.additions = pr_data['additions']
    pr.deletions = pr_data['deletions']
    pr.changed_files = pr_data['changed_files']
    pr.commits_count = pr_data['commits']
    pr.author = author
    pr.save!
    pr
  end

  def find_or_create_user(user_data)
    return nil unless user_data
    
    User.find_or_create_by(github_login: user_data['login']) do |user|
      user.github_id = user_data['id']
      user.name = user_data['name'] || user_data['login']
      user.created_at = user_data['created_at']
    end
  end
end 