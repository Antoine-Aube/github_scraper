namespace :test do
  desc "End-to-end test: Import 5 repositories with PRs, users, and reviews"
  task e2e: :environment do
    puts "=== End-to-End Test: Import 5 Repositories ==="
    
    puts "Clearing existing data..."
    Review.delete_all
    PullRequest.delete_all
    Repository.delete_all
    User.delete_all
    
    initial_repos = Repository.count
    initial_prs = PullRequest.count
    initial_reviews = Review.count
    initial_users = User.count
    
    puts "Initial counts - Repos: #{initial_repos}, PRs: #{initial_prs}, Reviews: #{initial_reviews}, Users: #{initial_users}"
    puts
    
    github_api_service = GithubApiService.new
    repository_importer = RepositoryImporter.new(github_api_service)
    pull_request_importer = PullRequestImporter.new(github_api_service)
    review_importer = ReviewImporter.new(github_api_service)
    
    begin
      puts "Step 1: Importing repositories..."
      repositories_data = github_api_service.get_organization_repos('vercel')
      limited_repos = repositories_data.first(1)
      
      puts "Found #{repositories_data.length} total repos, importing first 5..."
      
      limited_repos.each_with_index do |repo_data, index|
        puts "  #{index + 1}/5: #{repo_data['name']}"
        repository = repository_importer.find_or_create_repository(repo_data)
        puts "    ✅ Created repository: #{repository.name}"
      end
      
      puts "\nStep 2: Importing pull requests..."
      Repository.find_each do |repository|
        puts "  Processing PRs for: #{repository.name}"
        pr_count = pull_request_importer.import_repository_pull_requests(repository)
        puts "    ✅ Imported #{pr_count} pull requests"
      end
      
      puts "\nStep 3: Importing reviews..."
      Repository.find_each do |repository|
        puts "  Processing reviews for: #{repository.name}"
        review_importer.import_reviews_for_repository(repository)
        puts "    ✅ Processed reviews"
      end
      
      final_repos = Repository.count
      final_prs = PullRequest.count
      final_reviews = Review.count
      final_users = User.count
      
      puts "\n=== Test Results ==="
      puts "Repositories: #{initial_repos} → #{final_repos} (+#{final_repos - initial_repos})"
      puts "Pull Requests: #{initial_prs} → #{final_prs} (+#{final_prs - initial_prs})"
      puts "Reviews: #{initial_reviews} → #{final_reviews} (+#{final_reviews - initial_reviews})"
      puts "Users: #{initial_users} → #{final_users} (+#{final_users - initial_users})"
      
      puts "\n=== Sample Data ==="
      Repository.limit(3).each do |repo|
        puts "Repository: #{repo.name}"
        puts "  PRs: #{repo.pull_requests.count}"
        puts "  Reviews: #{repo.pull_requests.joins(:reviews).count}"
        puts "  Users: #{repo.pull_requests.joins(:author).distinct.count}"
        puts
      end
      
      puts "✅ End-to-end test completed successfully!"
      
    rescue => e
      puts "❌ Test failed: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end
  end
end 