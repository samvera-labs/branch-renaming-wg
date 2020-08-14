#!/usr/bin/env ruby
# frozen_string_literal: true

# Github sandbox repo creation script
username = ARGV[0]
github_token = ARGV[1]

unless username && github_token
  puts 'Argument Error: GitHub username and GitHub access token required'
  puts ''
  puts 'USAGE'
  puts '  ruby generate-sandbox-repo.rb <github_username> <github_access_token>'
  puts ''
  puts 'DESCRIPTION'
  puts '  Creates repo in GitHub at username/branch-renaming-test'
  puts ''
  puts '    <github_username> - identifies your personal repository location in GitHub'
  puts '    <github_access_token> - the access token that allows the test repo to be created under your Repositories'
  puts ''
  return
end

require 'octokit'

org_name = username
repo_name = "branch-renaming-test"

client = Octokit::Client.new({ access_token: github_token });

# Create the repo
client.create_repository(repo_name, private: false, has_issues: true, has_wiki: true, auto_init: true)

# Create file which references master
client.create_contents("#{org_name}/#{repo_name}", "CONTRIBUTING.md", "Add CONTRIBUTING.md", file: 'CONTRIBUTING.md')

# Create a branch and PR
master_sha = client.refs("#{org_name}/#{repo_name}", "heads/master")[:object][:sha]
client.create_ref("#{org_name}/#{repo_name}", "heads/add-new-file", master_sha)
client.create_contents("#{org_name}/#{repo_name}", "new-file", "Add new-file", "Proposed New File", branch: 'add-new-file')
client.create_pull_request("#{org_name}/#{repo_name}", "master", "add-new-file", "Add new file to repo", "A PR to master")

# Create an issue which references a commit in master
client.create_issue("#{org_name}/#{repo_name}", "An issue that references a commit in master", "This issue is solved in #{master_sha}")

# Create issue that is converted into a PR
issue = client.create_issue("#{org_name}/#{repo_name}", "An issue that will be converted into a PR", "This issue will be converted into a PR")
client.create_ref("#{org_name}/#{repo_name}", "heads/issue-solution", master_sha)
client.create_contents("#{org_name}/#{repo_name}", "issue-solution", "Solution to issue", "Issue solution", branch: 'issue-solution')
client.create_pull_request_for_issue("#{org_name}/#{repo_name}", "master", "issue-solution", issue[:number])

# Create issue that fixes a PR
issue = client.create_issue("#{org_name}/#{repo_name}", "An issue that will be fixed in PR", "This issue will be solved in a PR")
client.create_ref("#{org_name}/#{repo_name}", "heads/issue-solution2", master_sha)
client.create_contents("#{org_name}/#{repo_name}", "issue-solution2", "Solution to issue", "Issue solution", branch: 'issue-solution2')
client.create_pull_request("#{org_name}/#{repo_name}", "master", "issue-solution2", "Fix issue ##{issue[:number]}", "Fixes ##{issue[:number]}")


# When all done delete the repo:
# client.delete_repository("#{org_name}/#{repo_name}")

