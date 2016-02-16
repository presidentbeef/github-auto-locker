require 'json'
require 'date'
require 'net/http'
require 'base64'

# Automatically locks old issues that have been closed already
class Locker
  def initialize user, repo, token, old_days = 120
    @user = user
    @repo = repo
    @token = token
    @old_days = old_days
  end

  # Locks old closed issues
  def lock
    notify "Getting closed issues..."
    issues = get_closed_issues

    if issues.empty?
      notify "No issues to lock"
    else
      notify "Received #{issues.length} issues"
      notify "Locking old closed issues..."
      lock_old_closed_issues issues
    end
  end

  # Fetches all closed, unlocked issues closed before cutoff date
  def get_closed_issues
    issues = []
    path = "/repos/#@user/#@repo/issues?state=closed&access_token=#@token&sort=updated&direction=asc"
    page = 1
    http = Net::HTTP.start("api.github.com", 443, nil, nil, nil, nil, use_ssl: true)

    loop do
      notify "Retrieving page #{page}..."

      resp = http.get(path)
      new_issues = JSON.parse(resp.body)
      issues += new_issues

      # Pagination
      if resp['Link'].match /<https:\/\/api\.github\.com(\/[^>]+)>; rel="next",/
        path = $1
        page = path.match(/page=(\d+)/)[1]
      else
        http.finish
        break
      end
    end

    cutoff_date = (Date.today - @old_days).iso8601

    issues.reject do |issue|
      issue["locked"] or
        issue["closed_at"] > cutoff_date
    end
  end

  # Expects array of issues from API call
  def lock_old_closed_issues issues
    headers = {'Accept' => 'application/vnd.github.the-key-preview+json', # required for new lock API
               'Content-Length' => '0', # required for PUT with no body
               'Authorization' => "Basic #{Base64.strict_encode64("#@user:#@token")}"}

    Net::HTTP.start("api.github.com", 443, nil, nil, nil, nil, use_ssl: true) do |http|
      total = issues.length

      issues.each_with_index do |issue, i|
        number = issue['number']
        locking number, i, total

        path = issue["url"][22..-1] # pull path from full URL
        response = http.put("#{path}/lock", '', headers)

        if response.code == "204" # 204 means it worked, apparently
          locked
        else
          error response.inspect
        end
      end
    end
  end

  # Print locking message
  def locking number, item, total
    print "[INFO] Locking #{number} (#{item + 1}/#{total})..."
  end

  # Print locked message
  def locked
    puts 'locked!'
  end

  # Print INFO message
  def notify message
    puts "[INFO] #{message}"
  end

  # Print ERROR message
  def error message
    warn "[ERROR] #{message}"
  end
end

