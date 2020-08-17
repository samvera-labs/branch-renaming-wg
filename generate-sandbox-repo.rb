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

# Delete the repo if it currently exists
client.delete_repository("#{org_name}/#{repo_name}") rescue nil

# Create the repo
client.create_repository(repo_name, private: false, has_issues: true, has_wiki: true, auto_init: true)

# Create a file in master
hello_world = <<-HELLO_WORLD.chomp
puts "Hello World!"
HELLO_WORLD
client.create_contents("#{org_name}/#{repo_name}", "hello_world.rb", "Add hello_world.rb", hello_world)

# Create branch protections
client.protect_branch("#{org_name}/#{repo_name}", "master", required_status_checks: { strict: true, contexts: [] }, enforce_admins: true, required_pull_request_reviews: nil, restrictions: nil )

# Create file which references master
client.create_contents("#{org_name}/#{repo_name}", "CONTRIBUTING.md", "Add CONTRIBUTING.md", file: 'CONTRIBUTING.md')

# Create a branch and PR
pull_request_text = <<-PULL_REQUEST.chomp
A PR to master to add CONTRIBUTING.md
Consider applying i18n to https://github.com/#{org_name}/#{repo_name}/blob/master/hello_world.rb?
PULL_REQUEST
master_sha = client.refs("#{org_name}/#{repo_name}", "heads/master")[:object][:sha]
client.create_ref("#{org_name}/#{repo_name}", "heads/add-new-file", master_sha)
client.create_contents("#{org_name}/#{repo_name}", "new-file", "Add new-file", "Proposed New File", branch: 'add-new-file')
client.create_pull_request("#{org_name}/#{repo_name}", "master", "add-new-file", "Add new file to repo", pull_request_text)

# Create an issue which references a commit in master
issue_text = <<-ISSUE.chomp
This issue is solved in #{master_sha}.
The github link: https://github.com/#{org_name}/#{repo_name}/blob/master/hello_world.rb
And also the section that starts at line 1: https://github.com/#{org_name}/#{repo_name}/blob/master/hello_world.rb#L1
Also look at the raw hello_world.rb: https://raw.githubusercontent.com/#{org_name}/#{repo_name}/master/hello_world.rb
ISSUE
client.create_issue("#{org_name}/#{repo_name}", "An issue that references a commit in master", issue_text)

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

# TODO: Create a fork and a PR to master from the fork

# TODO: Update the repo's wiki

# TODO: Setup local git repo?

# All done
puts client.say('All done setting up the sandbox repo')
