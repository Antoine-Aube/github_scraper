class ReviewImporter
  def initialize(github_api_service = GithubApiService.new)
    @github_api_service = github_api_service
  end

  def import_reviews_for_pull_request(pull_request)
    Rails.logger.info "Importing reviews for pull request ##{pull_request.number} (#{pull_request.repository.name})"
    
    # Extract owner and repo from name
    owner, repo = pull_request.repository.name.split('/')
    
    reviews_data = @github_api_service.get_pull_request_reviews(
      owner,
      repo,
      pull_request.number
    )
    
    Rails.logger.info "Found #{reviews_data.length} reviews for pull request ##{pull_request.number}"
    
    reviews_data.each do |review_data|
      import_review(review_data, pull_request)
    end
    
    Rails.logger.info "Finished importing reviews for pull request ##{pull_request.number}"
  end

  def import_reviews_for_repository(repository)
    Rails.logger.info "Importing reviews for repository #{repository.name}"
    
    repository.pull_requests.find_each do |pull_request|
      import_reviews_for_pull_request(pull_request)
    end
    
    Rails.logger.info "Finished importing reviews for repository #{repository.name}"
  end

  private

  def import_review(review_data, pull_request)
    Rails.logger.debug "Processing review #{review_data['id']} for pull request ##{pull_request.number}"
    
    # Find or create the reviewer user
    reviewer = User.find_or_initialize_by(github_id: review_data['user']['id'])
    Rails.logger.debug "Found reviewer: #{reviewer.persisted? ? 'existing' : 'new'} - #{reviewer.github_login}"
    
    if reviewer.new_record?
      Rails.logger.info "Creating new user for reviewer #{review_data['user']['login']}"
      reviewer.assign_attributes(
        github_login: review_data['user']['login'],
        name: review_data['user']['name'] || review_data['user']['login'] # Use login as fallback if name is nil
      )
      if reviewer.save!
        Rails.logger.debug "Created user #{reviewer.id} for #{reviewer.github_login}"
      else
        Rails.logger.error "Failed to create user: #{reviewer.errors.full_messages.join(', ')}"
        return
      end
    end

    # Find or create the review
    review = Review.find_or_initialize_by(github_id: review_data['id'])
    Rails.logger.debug "Found review: #{review.persisted? ? 'existing' : 'new'} - #{review.github_id}"
    
    review.assign_attributes(
      pull_request: pull_request,
      user: reviewer,
      state: review_data['state'],
      body: review_data['body'],
      submitted_at: review_data['submitted_at'],
      commit_id: review_data['commit_id']
    )
    
    Rails.logger.debug "Review attributes: #{review.attributes.slice('github_id', 'state', 'body', 'submitted_at', 'commit_id')}"
    
    if review.save
      Rails.logger.debug "Saved review #{review.id} for pull request ##{pull_request.number}"
    else
      Rails.logger.error "Failed to save review #{review_data['id']}: #{review.errors.full_messages.join(', ')}"
    end
  rescue => e
    Rails.logger.error "Error importing review #{review_data['id']}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end 