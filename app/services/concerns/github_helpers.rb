module GithubHelpers
  extend ActiveSupport::Concern

  private

  def parse_repository_name(repo_name)
    # Handle both "owner/repo" and "repo" formats
    if repo_name.include?('/')
      parts = repo_name.split('/')
      [parts.first, parts.last]
    else
      # Vercel as a default
      ['vercel', repo_name]
    end
  end
end 