class PullRequestImporter
  def initialize(github_api_service = GithubApiService.new)
    @github_api_service = github_api_service
  end

  def import_repository_pull_requests(repository)
    page = 1
    total_imported = 0
    
    loop do
      # Parse owner and repo name from repository name
      owner, repo_name = parse_repository_name(repository.name)
      
      pull_requests = @github_api_service.get_repository_pull_requests(
        owner,
        repo_name,
        page: page, 
        per_page: 100
      )

      break if pull_requests.empty?
      
      imported_count = import_pull_requests(pull_requests, repository)
      total_imported += imported_count
      
      # If we got less than 100 PRs, we've reached the end
      break if pull_requests.length < 100
      
      page += 1
    end
    
    total_imported
  end

  private

  def parse_repository_name(repo_name)
    # Handle both "owner/repo" and "repo" formats
    if repo_name.include?('/')
      parts = repo_name.split('/')
      [parts.first, parts.last]
    else
      # Default to 'vercel' as owner if no owner specified just for the purpose of this project
      ['vercel', repo_name]
    end
  end

  def import_pull_requests(pull_requests_data, repository)
    imported_count = 0
    
    pull_requests_data.each do |pr_data|
      begin
        pull_request = find_or_create_pull_request(pr_data, repository)
        imported_count += 1 if pull_request&.persisted?
      rescue => e
        puts "Error importing pull request #{pr_data['number']}: #{e.message}"
      end
    end
    
    ##Just for testing purposes
    imported_count
  end

  def find_or_create_pull_request(pr_data, repository)
    author = find_or_create_user(pr_data['user'])
    #For data integrity, we don't want to import PRs without an author
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