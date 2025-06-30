class GithubApiService
  include HTTParty
  
  base_uri 'https://api.github.com'
  headers 'Authorization' => "Bearer #{ENV['GITHUB_ACCESS_TOKEN']}",
          'Accept' => 'application/vnd.github.v3+json',
          'User-Agent' => 'DX-Scraper-Challenge'

  def initialize
    @rate_limit_remaining = 5000
    @rate_limit_reset = Time.now
  end

  # Organization endpoints
  def get_organization_repos(org_name, page: 1, per_page: 100)
    begin
      response = self.class.get("/orgs/#{org_name}/repos", query: { page: page, per_page: per_page })
      handle_response(response)
    rescue GithubApiError => e
      if e.message.include?('Rate limit exceeded')
        handle_rate_limit_and_retry(org_name, page, per_page)
      else
        raise e
      end
    end
  end

  # Repository endpoints
  def get_repository_pull_requests(owner, repo, state: 'all', page: 1, per_page: 100)
    begin
      response = self.class.get("/repos/#{owner}/#{repo}/pulls", 
                               query: { state: state, page: page, per_page: per_page })
      handle_response(response)
    rescue GithubApiError => e
      if e.message.include?('Rate limit exceeded')
        handle_rate_limit_and_retry_pulls(owner, repo, state, page, per_page)
      else
        raise e
      end
    end
  end

  # Pull Request endpoints
  def get_pull_request_reviews(owner, repo, pull_number, page: 1, per_page: 100)
    begin
      response = self.class.get("/repos/#{owner}/#{repo}/pulls/#{pull_number}/reviews",
                               query: { page: page, per_page: per_page })
      handle_response(response)
    rescue GithubApiError => e
      if e.message.include?('Rate limit exceeded')
        handle_rate_limit_and_retry_reviews(owner, repo, pull_number, page, per_page)
      else
        raise e
      end
    end
  end

  # User endpoints
  def get_user(username)
    begin
      response = self.class.get("/users/#{username}")
      handle_response(response)
    rescue GithubApiError => e
      if e.message.include?('Rate limit exceeded')
        handle_rate_limit_and_retry_user(username)
      else
        raise e
      end
    end
  end

  # Rate limiting info
  def rate_limit_remaining
    @rate_limit_remaining
  end

  def rate_limit_reset
    @rate_limit_reset
  end

  private

  def handle_response(response)
    case response.code
    when 200
      update_rate_limit_info(response)
      response.parsed_response
    when 403
      if response.headers['x-ratelimit-remaining'] == '0'
        raise GithubApiError, "Rate limit exceeded"
      else
        raise GithubApiError, "API Error: #{response.code} - #{response.body}"
      end
    when 404
      raise GithubApiError, "Resource not found: #{response.code} - #{response.body}"
    when 401
      raise GithubApiError, "Authentication failed. Check your GitHub token."
    else
      raise GithubApiError, "API Error: #{response.code} - #{response.body}"
    end
  end

  def update_rate_limit_info(response)
    @rate_limit_remaining = response.headers['x-ratelimit-remaining'].to_i
    @rate_limit_reset = Time.at(response.headers['x-ratelimit-reset'].to_i)
  end

  def handle_rate_limit_and_retry(org_name, page, per_page)
    reset_time = @rate_limit_reset
    wait_time = (reset_time - Time.now).ceil
    
    if wait_time > 0
      Rails.logger.warn "Rate limit exceeded. Waiting #{wait_time} seconds..."
      sleep(wait_time)
      # Retry the request
      get_organization_repos(org_name, page: page, per_page: per_page)
    else
      raise GithubApiError, "Rate limit exceeded and reset time has passed"
    end
  end

  def handle_rate_limit_and_retry_pulls(owner, repo, state, page, per_page)
    reset_time = @rate_limit_reset
    wait_time = (reset_time - Time.now).ceil
    
    if wait_time > 0
      Rails.logger.warn "Rate limit exceeded. Waiting #{wait_time} seconds..."
      sleep(wait_time)
      # Retry the request
      get_repository_pull_requests(owner, repo, state: state, page: page, per_page: per_page)
    else
      raise GithubApiError, "Rate limit exceeded and reset time has passed"
    end
  end

  def handle_rate_limit_and_retry_reviews(owner, repo, pull_number, page, per_page)
    reset_time = @rate_limit_reset
    wait_time = (reset_time - Time.now).ceil
    
    if wait_time > 0
      Rails.logger.warn "Rate limit exceeded. Waiting #{wait_time} seconds..."
      sleep(wait_time)
      # Retry the request
      get_pull_request_reviews(owner, repo, pull_number, page: page, per_page: per_page)
    else
      raise GithubApiError, "Rate limit exceeded and reset time has passed"
    end
  end

  def handle_rate_limit_and_retry_user(username)
    reset_time = @rate_limit_reset
    wait_time = (reset_time - Time.now).ceil
    
    if wait_time > 0
      Rails.logger.warn "Rate limit exceeded. Waiting #{wait_time} seconds..."
      sleep(wait_time)
      # Retry the request
      get_user(username)
    else
      raise GithubApiError, "Rate limit exceeded and reset time has passed"
    end
  end
end 