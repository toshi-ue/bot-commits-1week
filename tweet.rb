require 'net/https'
require 'uri'
require 'json'
require 'date'
require 'twitter'
require "active_support/time"
require 'dotenv'
Dotenv.load

t = Time.now
t_1day_ago = t - 1.day
arr_per_commits = [0, 0, 0, 0, 0, 0, 0]
my_github_account = ENV['MY_GITHUB_ACCOUNT']
tweet_texts =[]


def time_ja(time, commit_sum)
  "#{time.strftime("%m")}/#{time.strftime("%d")}" \
  "(#{%w(日 月 火 水 木 金 土)[time.wday]}): #{commit_sum.to_s}commits"
end


github_push_events_datas = "https://api.github.com/users/#{my_github_account}/events"

uri = URI.parse(github_push_events_datas)
json = Net::HTTP.get(uri)
results = JSON.parse(json)

7.times do |num|
  results.select do |r|
    str_time = r["created_at"].in_time_zone("UTC").in_time_zone
    if(r["type"] == "PushEvent")
      if((str_time >= (t_1day_ago - num.day).beginning_of_day) && (str_time <= (t_1day_ago - num.day).end_of_day))
        arr_per_commits[num] += 1
      end
    end
  end
end

# Twitter投稿用のテキストを作成
tweet_texts.push("total #{arr_per_commits.sum}commits in last week.")

(arr_per_commits.reverse).each_with_index do |c, idx|
  tweet_texts.push(time_ja(t - (7 - idx).day, c))
end

# Tweetする(などの処理用, REST)ための接続に使用
@client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV['TWITTER_CONSUMER_API_KEY']
  config.consumer_secret     = ENV['YOUR_CONSUMER_API_SECRET_KEY']
  config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
  config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
end

@client.update(tweet_texts.join("\n"))

# [Rubyで曜日を求める方法を現役エンジニアが解説【初心者向け】 | TechAcademyマガジン](https://techacademy.jp/magazine/21762)

# [指定フォーマットで文字列に変換する - 日付(Date、DateTime)クラス - Ruby入門](https://www.javadrive.jp/ruby/date_class/index5.html)
