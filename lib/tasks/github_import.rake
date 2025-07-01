namespace :github do
  desc "Import GitHub data for an organization (default: vercel)"
  task :import, [:org_name] => :environment do |task, args|
    org_name = args[:org_name] || 'vercel'
    
    puts "🚀 Starting GitHub import for organization: #{org_name}"
    puts "=" * 50
    
    # Store initial counts
    initial_repos = Repository.count
    initial_prs = PullRequest.count
    initial_reviews = Review.count
    initial_users = User.count
    
    # Run the import
    start_time = Time.current
    
    begin
      GithubImportJob.perform_now(org_name)
    rescue => e
      puts "⚠️  Import encountered errors: #{e.message}"
      puts "Continuing to show results..."
    end
    
    end_time = Time.current
    
    # Calculate final counts
    final_repos = Repository.count
    final_prs = PullRequest.count
    final_reviews = Review.count
    final_users = User.count
    
    puts "✅ Import completed!"
    puts "⏱️  Duration: #{(end_time - start_time).round(2)} seconds"
    puts ""
    puts "📊 Import Summary:"
    puts "  Repositories: #{initial_repos} → #{final_repos} (+#{final_repos - initial_repos})"
    puts "  Pull Requests: #{initial_prs} → #{final_prs} (+#{final_prs - initial_prs})"
    puts "  Reviews: #{initial_reviews} → #{final_reviews} (+#{final_reviews - initial_reviews})"
    puts "  Users: #{initial_users} → #{final_users} (+#{final_users - initial_users})"
    puts ""
    puts "🎉 All done! Check your database for the imported data."
  end

  desc "Show current import statistics"
  task :stats => :environment do
    puts "📈 Current Import Statistics"
    puts "=" * 30
    puts "Repositories: #{Repository.count}"
    puts "Pull Requests: #{PullRequest.count}"
    puts "Reviews: #{Review.count}"
    puts "Users: #{User.count}"
    
    if Repository.count > 0
      puts ""
      puts "📋 Recent Repositories:"
      Repository.limit(5).each do |repo|
        puts "  • #{repo.name} (#{repo.pull_requests.count} PRs)"
      end
    end
    
    if User.count > 0
      puts ""
      puts "👥 Top Users (by PR count):"
      User.joins(:pull_requests)
          .group('users.id')
          .order('COUNT(pull_requests.id) DESC')
          .limit(5)
          .each do |user|
        puts "  • #{user.github_login} (#{user.pull_requests.count} PRs)"
      end
    end
  end

  desc "Clear all imported data"
  task :clear => :environment do
    puts "🗑️  Clearing all imported data..."
    
    Review.delete_all
    PullRequest.delete_all
    Repository.delete_all
    User.delete_all
    
    puts "✅ All data cleared!"
  end
end 