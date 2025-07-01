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
      
      # Since our limit is 100 repos, get outta here if we have less than the limit
      break if repos.length < 100
      
      page += 1
    end
    
    ##Just for testing purposes
    total_imported
  end

  #should be private but making public for testing purposes
  def find_or_create_repository(repo_data)
    Repository.find_or_create_by(url: repo_data['html_url']) do |repo|
      repo.name = repo_data['name']
      repo.private = repo_data['private']
      repo.archived = repo_data['archived']
    end
  end

  private

  def import_repositories(repos_data)
    imported_count = 0
    
    repos_data.each do |repo_data|
      begin
        repository = find_or_create_repository(repo_data)
        if repository.persisted?
          imported_count += 1
          puts "Imported repository: #{repository.name}"
        else
          puts "Failed to save repository #{repo_data['name']}: #{repository.errors.full_messages.join(', ')}"
        end
      rescue => e
        puts "Error importing repository #{repo_data['name']}: #{e.message}"
      end
    end
    
    #Just for testing purposes
    imported_count
  end
end 