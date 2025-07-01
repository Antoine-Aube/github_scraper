class ReviewImporter
  include GithubHelpers
  
  def initialize(github_api_service = GithubApiService.new)
    @github_api_service = github_api_service
  end

  def import_reviews_for_pull_request(pull_request)
    owner, repo_name = parse_repository_name(pull_request.repository.name)
    
    begin
      reviews_data = @github_api_service.get_pull_request_reviews(
        owner,
        repo_name,
        pull_request.number
      )
      
      reviews_data.each do |review_data|
        import_review(review_data, pull_request)
      end
    rescue GithubApiError => e
      if e.message.include?('404')
        puts "PR #{pull_request.number} in #{pull_request.repository.name} not found (404) - skipping reviews"
      else
        puts "Failed to import reviews for PR #{pull_request.number} in #{pull_request.repository.name}: #{e.message}"
      end
    rescue => e
      puts "Unexpected error importing reviews for PR #{pull_request.number} in #{pull_request.repository.name}: #{e.message}"
    end
  end

  def import_reviews_for_repository(repository)
    repository.pull_requests.find_each do |pull_request|
      import_reviews_for_pull_request(pull_request)
    end
  end

  private

  def import_review(review_data, pull_request)
    reviewer = User.find_or_initialize_by(github_id: review_data['user']['id'])
    
    if reviewer.new_record?
      reviewer.assign_attributes(
        github_login: review_data['user']['login'],
        name: review_data['user']['name'] 
      )
      reviewer.save!
    end

    review = Review.find_or_initialize_by(github_id: review_data['id'])
    
    review.assign_attributes(
      pull_request: pull_request,
      user: reviewer,
      state: review_data['state'],
      body: review_data['body'],
      submitted_at: review_data['submitted_at']
    )
    
    if review.save
    else
      puts "Failed to save review #{review_data['id']}: #{review.errors.full_messages.join(', ')}"
    end
  rescue => e
    puts "Error importing review #{review_data['id']}: #{e.message}"
    return
  end
end 