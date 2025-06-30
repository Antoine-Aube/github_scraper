require 'rails_helper'

RSpec.describe ReviewImporter do
  let(:github_api_service) { instance_double(GithubApiService) }
  let(:review_importer) { described_class.new(github_api_service) }

  before(:each) do
    Review.delete_all
    PullRequest.delete_all
    Repository.delete_all
    User.delete_all
  end

  let(:repository) { Repository.create!(name: 'vercel/next.js', url: 'https://github.com/vercel/next.js', private: false, archived: false) }
  let!(:author) { User.create!(github_id: 123, github_login: 'author', name: 'John Author') }
  let(:pull_request) { PullRequest.create!(repository: repository, number: 123, title: 'Test PR', author: author) }
  let!(:reviewer) { User.create!(github_id: 456, github_login: 'reviewer', name: 'John Reviewer') }

  describe '#import_reviews_for_pull_request' do
    let(:reviews_data) do
      [
        {
          'id' => 789,
          'user' => {
            'id' => 456,
            'login' => 'reviewer',
            'name' => 'John Reviewer',
            'email' => 'reviewer@example.com',
            'avatar_url' => 'https://example.com/avatar.jpg'
          },
          'state' => 'APPROVED',
          'body' => 'Looks good!',
          'submitted_at' => '2024-01-15T10:30:00Z',
          'commit_id' => 'abc123'
        },
        {
          'id' => 790,
          'user' => {
            'id' => 457,
            'login' => 'another_reviewer',
            'name' => 'Jane Another',
            'email' => 'jane@example.com',
            'avatar_url' => 'https://example.com/jane.jpg'
          },
          'state' => 'CHANGES_REQUESTED',
          'body' => 'Please fix this issue',
          'submitted_at' => '2024-01-16T14:20:00Z',
          'commit_id' => 'def456'
        }
      ]
    end

    before do
      allow(github_api_service).to receive(:get_pull_request_reviews)
        .with('vercel', 'next.js', 123)
        .and_return(reviews_data)
    end

    it 'imports reviews for a pull request' do   
      expect { review_importer.import_reviews_for_pull_request(pull_request) }
        .to change { Review.count }.by(2)
        .and change { User.count }.by(1)

      # Check first review
      review1 = Review.find_by(github_id: 789)
      expect(review1).to be_present
      expect(review1.pull_request).to eq(pull_request)
      expect(review1.user.github_login).to eq('reviewer')
      expect(review1.state).to eq('APPROVED')
      expect(review1.body).to eq('Looks good!')

      # Check second review
      review2 = Review.find_by(github_id: 790)
      expect(review2).to be_present
      expect(review2.pull_request).to eq(pull_request)
      expect(review2.user.github_login).to eq('another_reviewer')
      expect(review2.state).to eq('CHANGES_REQUESTED')
      expect(review2.body).to eq('Please fix this issue')
    end

    it 'reuses existing users for reviewers' do
      existing_user = reviewer

      expect { review_importer.import_reviews_for_pull_request(pull_request) }
        .to change { Review.count }.by(2)
        .and change { User.count }.by(1)

      review = Review.find_by(github_id: 789)
      expect(review.user).to eq(existing_user)
    end

    it 'updates existing reviews' do
      existing_review = Review.create!(
        github_id: 789, 
        pull_request: pull_request, 
        user: reviewer,
        state: 'COMMENTED',
        submitted_at: '2024-01-14T10:30:00Z'
      )

      expect { review_importer.import_reviews_for_pull_request(pull_request) }
        .to change { Review.count }.by(1)

      existing_review.reload
      expect(existing_review.state).to eq('APPROVED')
      expect(existing_review.body).to eq('Looks good!')
    end
  end

  describe '#import_reviews_for_repository' do
    let!(:pull_request1) { PullRequest.create!(repository: repository, number: 123, title: 'Test PR 1', author: author) }
    let!(:pull_request2) { PullRequest.create!(repository: repository, number: 124, title: 'Test PR 2', author: author) }

    before do
      allow(github_api_service).to receive(:get_pull_request_reviews)
        .with('vercel', 'next.js', 123)
        .and_return([])
      allow(github_api_service).to receive(:get_pull_request_reviews)
        .with('vercel', 'next.js', 124)
        .and_return([])
    end

    it 'imports reviews for all pull requests in a repository' do
      review_importer.import_reviews_for_repository(repository)

      expect(github_api_service).to have_received(:get_pull_request_reviews)
        .with('vercel', 'next.js', 123)
      expect(github_api_service).to have_received(:get_pull_request_reviews)
        .with('vercel', 'next.js', 124)
    end
  end
end 