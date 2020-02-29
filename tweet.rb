require 'net/https'
require 'uri'
require 'json'
require 'date'
require "active_support/time"
require 'dotenv'
Dotenv.load

# total aa commits in this week
# xx / yy (日): zz commits

t = Time.now
arr_per_commits = [0, 0, 0, 0, 0, 0, 0]
my_github_account = ENV['MY_GITHUB_ACCOUNT']
tweet_texts =[]

# puts t
# puts my_github_account
# github_push_events_datas = "https://api.github.com/users/toshi-ue/events"

github_push_events_datas = "https://api.github.com/users/#{my_github_account}/events"

uri = URI.parse(github_push_events_datas)
json = Net::HTTP.get(uri)
results = JSON.parse(json)

7.times do |num|
  results.select do |r|
    str_time = r["created_at"].in_time_zone("UTC").in_time_zone
    if(r["type"] == "PushEvent")
      if(str_time >= (t - num.day).beginning_of_day && str_time <= (t - num.day).end_of_day)
        arr_per_commits[num] += 1
      end
    end
  end
end

puts arr_per_commits
