require 'rails_helper'

RSpec.describe PullRequestImporter do
  let(:github_api_service) { instance_double(GithubApiService) }
  let(:importer) { described_class.new(github_api_service) }
  let(:repository) { Repository.create!(name: 'vercel/next.js', url: 'https://github.com/vercel/next.js', private: false, archived: false) }

  describe '#import_repository_pull_requests' do
    let(:mock_pull_requests_data) do
      [
        {
          'number' => 123,
          'title' => 'Add new feature',
          'updated_at' => '2023-01-01T00:00:00Z',
          'closed_at' => nil,
          'merged_at' => nil,
          'additions' => 10,
          'deletions' => 5,
          'changed_files' => 3,
          'commits' => 2,
          'user' => {
            'login' => 'testuser',
            'id' => 12345,
            'name' => 'Test User',
            'created_at' => '2020-01-01T00:00:00Z'
          }
        }
      ]
    end

    before do
      allow(github_api_service).to receive(:get_repository_pull_requests)
        .with('vercel', 'next.js', page: 1, per_page: 100)
        .and_return(mock_pull_requests_data)
      
      allow(github_api_service).to receive(:get_repository_pull_requests)
        .with('vercel', 'next.js', page: 2, per_page: 100)
        .and_return([])
    end

    it 'debug: shows what the importer actually returns' do
      result = importer.import_repository_pull_requests(repository)
      puts "Importer returned: #{result}"
      puts "PullRequest count: #{PullRequest.count}"
      puts "User count: #{User.count}"
      puts "Repository count: #{Repository.count}"
    end

    it 'imports pull requests from GitHub API' do
      expect { importer.import_repository_pull_requests(repository) }
        .to change(PullRequest, :count).by(1)
    end

    it 'creates pull requests with correct attributes' do
      importer.import_repository_pull_requests(repository)
      
      pull_request = PullRequest.find_by(number: 123)
      expect(pull_request).to be_present
      expect(pull_request.title).to eq('Add new feature')
      expect(pull_request.additions).to eq(10)
      expect(pull_request.deletions).to eq(5)
      expect(pull_request.changed_files).to eq(3)
      expect(pull_request.commits_count).to eq(2)
    end

    it 'associates pull request with repository' do
      importer.import_repository_pull_requests(repository)
      
      pull_request = PullRequest.find_by(number: 123)
      expect(pull_request.repository).to eq(repository)
    end

    it 'creates user for pull request author' do
      expect { importer.import_repository_pull_requests(repository) }
        .to change(User, :count).by(1)
      
      user = User.find_by(github_login: 'testuser')
      expect(user).to be_present
      expect(user.name).to eq('Test User')
      expect(user.github_id).to eq(12345)
    end

    it 'associates pull request with author' do
      importer.import_repository_pull_requests(repository)
      
      pull_request = PullRequest.find_by(number: 123)
      user = User.find_by(github_login: 'testuser')
      expect(pull_request.author).to eq(user)
    end

    it 'does not create duplicate pull requests' do
      importer.import_repository_pull_requests(repository)
      importer.import_repository_pull_requests(repository)
      
      expect(PullRequest.count).to eq(1)
    end

    it 'returns the total number of imported pull requests' do
      result = importer.import_repository_pull_requests(repository)
      expect(result).to eq(1)
    end
  end
end 