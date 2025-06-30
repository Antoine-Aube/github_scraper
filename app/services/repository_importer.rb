class RepositoryImporter
  def initialize(github_api_service = GithubApiService.new)
    @github_api_service = github_api_service
  end

  def import_organization_repos(org_name)
    page = 1
    total_imported = 0
    
    loop do
      repos = @github_api_service.get_organization_repos(org_name, page: page, per_page: 100)
      break if repos.empty?
      
      imported_count = import_repositories(repos)
      total_imported += imported_count
      
      # If we got less than 100 repos, we've reached the end
      break if repos.length < 100
      
      page += 1
    end
    
    total_imported
  end

  private

  def import_repositories(repos_data)
    imported_count = 0
    
    repos_data.each do |repo_data|
      begin
        repository = find_or_create_repository(repo_data)
        imported_count += 1 if repository.persisted?
      rescue => e
        puts "Error importing repository #{repo_data['name']}: #{e.message}"
      end
    end
    
    imported_count
  end

  def find_or_create_repository(repo_data)
    Repository.find_or_create_by(url: repo_data['html_url']) do |repo|
      repo.name = repo_data['name']
      repo.private = repo_data['private']
      repo.archived = repo_data['archived']
    end
  end
end 