require 'rails_helper'

RSpec.describe RepositoryImporter do
  let(:github_api_service) { instance_double(GithubApiService) }
  let(:importer) { described_class.new(github_api_service) }

  describe '#import_organization_repos' do
    let(:mock_repos_data) do
      [
        {
          'name' => 'next.js',
          'html_url' => 'https://github.com/vercel/next.js',
          'private' => false,
          'archived' => false
        },
        {
          'name' => 'vercel',
          'html_url' => 'https://github.com/vercel/vercel',
          'private' => false,
          'archived' => false
        }
      ]
    end

    before do
      allow(github_api_service).to receive(:get_organization_repos)
        .with('vercel', page: 1, per_page: 100)
        .and_return(mock_repos_data)
      
      allow(github_api_service).to receive(:get_organization_repos)
        .with('vercel', page: 2, per_page: 100)
        .and_return([])
    end

    it 'imports repositories from GitHub API' do
      expect { importer.import_organization_repos('vercel') }
        .to change(Repository, :count).by(2)
    end

    it 'creates repositories with correct attributes' do
      importer.import_organization_repos('vercel')
      
      next_js_repo = Repository.find_by(name: 'next.js')
      expect(next_js_repo).to be_present
      expect(next_js_repo.url).to eq('https://github.com/vercel/next.js')
      expect(next_js_repo.private).to be false
      expect(next_js_repo.archived).to be false
    end

    it 'does not create duplicate repositories' do
      # Import twice
      importer.import_organization_repos('vercel')
      importer.import_organization_repos('vercel')
      
      expect(Repository.count).to eq(2)
    end

    it 'returns the total number of imported repositories' do
      result = importer.import_organization_repos('vercel')
      expect(result).to eq(2)
    end
  end
end 