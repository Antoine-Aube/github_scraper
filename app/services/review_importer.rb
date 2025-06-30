class ReviewImporter
  def initialize(github_api_service = GithubApiService.new)
    @github_api_service = github_api_service
  end

  def import_reviews_for_pull_request(pull_request)
    # Extract owner and repo from name
    owner, repo = pull_request.repository.name.split('/')
    
    reviews_data = @github_api_service.get_pull_request_reviews(
      owner,
      repo,
      pull_request.number
    )
    
    reviews_data.each do |review_data|
      import_review(review_data, pull_request)
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
        name: review_data['user']['name'] || review_data['user']['login'] # Use login as fallback if name is nil
      )
      if reviewer.save!
        puts "User created successfully #{reviewer.github_login}"
      else
        puts "Failed to create user #{reviewer.github_login}: #{reviewer.errors.full_messages.join(', ')}"
        return
      end
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