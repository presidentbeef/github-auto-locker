require 'json'
require 'date'
require 'net/http'
require 'base64'

# Automatically locks old issues that have been closed already
class Locker
  def initialize user, repo, token, old_days = 120, noop = false, level = 2
    @user = user
    @repo = repo
    @token = token
    @old_days = old_days.to_i
    @noop = noop
    @level = level || 0
  end

  # Locks old closed issues
  def lock
    notify "Not locking anything due to -n flag" if @noop
    notify "Getting closed issues for %s/%s..." % [@user, @repo]
    issues = get_closed_issues

    if issues.empty?
      notify "No issues to lock"
    else
      notify "Received #{issues.length} issues"
      notify "Locking old closed issues..."

      if @noop then
        total = issues.size

        issues.sort_by { |h| h["number"] }.each_with_index do |issue, i|
          number = issue['number']
          locking number, i, total
          puts issue['title']
        end

        return
      end

      lock_old_closed_issues issues
    end
  end

  # Fetches all closed, unlocked issues closed before cutoff date
  def get_closed_issues
    issues = []
    path = "/repos/#@user/#@repo/issues?state=closed&per_page=100&access_token=#@token&sort=updated&direction=asc"
    page = 1
    http = Net::HTTP.start("api.github.com", 443, nil, nil, nil, nil, use_ssl: true)

    loop do
      notify "Retrieving page #{page}..."

      resp = http.get(path)
      new_issues = JSON.parse(resp.body)

      unless Array === new_issues then
        abort "bad response: %p" % new_issues
      end

      issues += new_issues

      # Pagination
      if resp['Link'] and resp['Link'].match(/<https:\/\/api\.github\.com(\/[^>]+)>; rel="next",/)
        path = $1
        page = path.match(/&page=(\d+)/)[1]
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
               'Authorization' => "Basic #{Base64.strict_encode64("#@user:#@token")}",
               'Content-Type' => "application/x-www-form-urlencoded",
              }

    Net::HTTP.start("api.github.com", 443, nil, nil, nil, nil, use_ssl: true) do |http|
      total = issues.length

      issues.each_with_index do |issue, i|
        number = issue['number']
        locking number, i, total

        _, _, _, _, _, path, * = URI.split issue["url"]
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
    return unless @level >= 1
    print "[INFO] Locking #{number} (#{item + 1}/#{total})..."
  end

  # Print locked message
  def locked
    puts 'locked!'
  end

  # Print INFO message
  def notify message
    return unless @level >= 2
    puts "[INFO] #{message}"
  end

  # Print ERROR message
  def error message
    warn "[ERROR] #{message}"
  end
end
