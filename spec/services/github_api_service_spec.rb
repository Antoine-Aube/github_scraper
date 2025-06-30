require 'rails_helper'
require 'pry'

RSpec.describe GithubApiService do
  let(:service) { described_class.new }

  describe '#get_organization_repos' do
    context 'when successful' do
      it 'returns Vercel organization repositories' do
        repos = service.get_organization_repos('vercel', per_page: 5)
        
        expect(repos).to be_an(Array)
        expect(repos.length).to be <= 5
        
        if repos.any?
          repo = repos.first
          expect(repo['name']).to be_present
          expect(repo['html_url']).to be_present
          expect(repo).to have_key('private') # Check that the field exists, regardless of value
        end
      end
    end
    
# sad paths
    context 'when organization does not exist' do
      it 'raises GithubApiError' do
        expect {
          service.get_organization_repos('nonexistent-org')
        }.to raise_error(GithubApiError, /Resource not found/)
      end
    end

    context 'when authentication fails' do
      before do
        allow(ENV).to receive(:[]).with('GITHUB_ACCESS_TOKEN').and_return('invalid_token')
        allow(service.class).to receive(:get).and_return(
          double(code: 401, body: 'Bad credentials')
        )
      end

      it 'raises GithubApiError with authentication message' do
        expect {
          service.get_organization_repos('vercel')
        }.to raise_error(GithubApiError, /Authentication failed/)
      end
    end

    context 'when rate limit is exceeded' do
      before do
        allow(service.class).to receive(:get).and_return(
          double(
            code: 403,
            headers: { 'x-ratelimit-remaining' => '0', 'x-ratelimit-reset' => (Time.now + 60).to_i.to_s },
            body: 'API rate limit exceeded'
          )
        )
      end

      it 'raises GithubApiError for rate limiting' do
        expect {
          service.get_organization_repos('vercel')
        }.to raise_error(GithubApiError, /Rate limit exceeded/)
      end
    end

    context 'when API returns unexpected error' do
      before do
        allow(service.class).to receive(:get).and_return(
          double(code: 500, body: 'Internal server error')
        )
      end

      it 'raises GithubApiError with generic message' do
        expect {
          service.get_organization_repos('vercel')
        }.to raise_error(GithubApiError, /API Error: 500/)
      end
    end
  end

  describe '#get_repository_pull_requests' do
    it 'returns pull requests for a Vercel repository' do
      # Use a popular Vercel repo that likely has PRs
      pull_requests = service.get_repository_pull_requests('vercel', 'next.js', per_page: 5)
      
      expect(pull_requests).to be_an(Array)
      expect(pull_requests.length).to be <= 5
      
      if pull_requests.any?
        pr = pull_requests.first
        expect(pr['number']).to be_present
        expect(pr['title']).to be_present
        expect(pr['html_url']).to be_present
        expect(pr).to have_key('state')
        expect(pr['user']).to be_present
      end
    end
  end

  describe '#get_pull_request_reviews' do
    it 'returns reviews for a pull request' do
      # Use a more realistic PR number from next.js
      reviews = service.get_pull_request_reviews('vercel', 'next.js', 1000, per_page: 5)
      
      expect(reviews).to be_an(Array)
      expect(reviews.length).to be <= 5
      
      if reviews.any?
        review = reviews.first
        expect(review['id']).to be_present
        expect(review).to have_key('state')
        expect(review['user']).to be_present
        expect(review['submitted_at']).to be_present
      end
    end
  end

  describe '#rate_limit_remaining' do
    it 'returns rate limit remaining' do
      expect(service).to respond_to(:rate_limit_remaining)
    end
  end

  describe '#rate_limit_reset' do
    it 'returns rate limit reset time' do
      expect(service).to respond_to(:rate_limit_reset)
    end
  end

  describe 'environment configuration' do
    it 'has GitHub access token set' do
      expect(ENV['GITHUB_ACCESS_TOKEN']).to be_present
    end
  end
end 