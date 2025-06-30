class GithubApiService
  include HTTParty
  
  ##Headers, access token is stored in ENV file for security
  base_uri 'https://api.github.com'
  headers 'Authorization' => "Bearer #{ENV['GITHUB_ACCESS_TOKEN']}",
          'Accept' => 'application/vnd.github.v3+json',
          'User-Agent' => 'DX-Scraper-Challenge'

  def initialize
    @rate_limit_remaining = 5000
    @rate_limit_reset = Time.now
  end

  # Repos call
  def get_organization_repos(org_name, page: 1, per_page: 100)
    begin
      response = self.class.get("/orgs/#{org_name}/repos", query: { page: page, per_page: per_page })
      handle_response(response)
    rescue GithubApiError => e
      if e.message.include?('Rate limit exceeded')
        handle_rate_limit_and_retry(:get_organization_repos, org_name, page, per_page)
      else
        raise e
      end
    end
  end

  # Repository call
  def get_repository_pull_requests(owner, repo, state: 'all', page: 1, per_page: 100)
    begin
      response = self.class.get("/repos/#{owner}/#{repo}/pulls", 
                               query: { state: state, page: page, per_page: per_page })
      handle_response(response)
    rescue GithubApiError => e
      if e.message.include?('Rate limit exceeded')
        handle_rate_limit_and_retry(:get_repository_pull_requests, owner, repo, state, page, per_page)
      else
        raise e
      end
    end
  end

  # Pull Request call
  def get_pull_request_reviews(owner, repo, pull_number, page: 1, per_page: 100)
    begin
      response = self.class.get("/repos/#{owner}/#{repo}/pulls/#{pull_number}/reviews",
                               query: { page: page, per_page: per_page })
      handle_response(response)
    rescue GithubApiError => e
      if e.message.include?('Rate limit exceeded')
        handle_rate_limit_and_retry(:get_pull_request_reviews, owner, repo, pull_number, page, per_page)
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
  

  #Error handling for different status codes
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

  #handle retry base on the endpoint we're calling
  def handle_rate_limit_and_retry(method_name, *args)
    reset_time = @rate_limit_reset
    wait_time = (reset_time - Time.now).ceil
    
    if wait_time > 0
      sleep(wait_time)
      case method_name
      when :get_organization_repos
        get_organization_repos(*args)
      when :get_repository_pull_requests
        get_repository_pull_requests(*args)
      when :get_pull_request_reviews
        get_pull_request_reviews(*args)
      else
        raise GithubApiError, "Unknown method: #{method_name}"
      end
    else
      raise GithubApiError, "Rate limit exceeded and reset time has passed"
    end
  end
end 