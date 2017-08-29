#!/usr/bin/env ruby

require 'bundler'
Bundler.require

require 'active_support'
require 'active_support/core_ext/numeric/time'

POWERS = %w{
  インク効率アップ[(（]メイン[）)]
  インク効率アップ[(（]サブ[）)]
  インク回復力アップ
  ヒト移動速度アップ
  イカダッシュ速度アップ
  スペシャル増加量アップ
  スペシャル減少量ダウン
  スペシャル性能アップ
  復活時間短縮
  スーパージャンプ時間短縮
  サブ性能アップ
  相手インク影響軽減
  爆風ダメージ軽減
  マーキング時間短縮

  スタートダッシュ
  ラストスパート
  逆境強化
  カムバック

  イカニンジャ
  リベンジ
  サーマルインク
  復活ペナルティーアップ
  追加ギアパワー倍化

  ステルスジャンプ
  対物攻撃力アップ
  受け身術
}

WANTED = {
  'イカニンジャ' => 'イカダッシュ速度アップ',
}

class TextParseFailed < RuntimeError
end

def tweets_in_12hours(client)
  limit = Time.now - 12.hours
  client.user_timeline(891009577252077569).select{|tw| tw.created_at > limit }
end

def parse_text(text)
  gears = "(#{POWERS.join '|'})"

  main = text.match /特別ギアパワー：#{gears}/
  sub = text.match /ブランド：[^(]+\(#{gears}\)/

  unless main && sub
    raise TextParseFailed.new "Failed to parse '#{text}': main: #{main}, sub: #{sub}"
  end

  # Normalize parens
  main = main[1].gsub(/[（）]/, '（' => '(', '）' => ')')
  sub = sub[1].gsub(/[（）]/, '（' => '(', '）' => ')')

  { special_main: main, brand_sub: sub }
end

def i_want_this?(text)
  begin
    p = parse_text text
    puts "Parsed: #{p}"
    main_sub_matched = p[:special_main] == p[:brand_sub]
    is_vip_pair = WANTED[p[:special_main]] && (WANTED[p[:special_main]] == WANTED[p[:brand_sub]])
    main_sub_matched || is_vip_pair
  rescue TextParseFailed => e
    STDERR.puts e
    false
  end
end

def notify_me(client, tweets)
  previous = client.direct_messages.map &:text
  tweets.each do |t|
    id = t.id.to_s
    url = t.url.to_s
    if previous.any?{|m| m.include? id }
      puts "This gear was already notified. Skipped: #{url}"
      next
    end
    puts "Notify: text is '#{t.text}', URL is '#{url}'"
    msg = "Target gear was found in Geso-Town (id: #{id}): #{url}"
    client.create_direct_message('Linda_pp', msg)
  end
end

# Heroku scheduler only privides daily/hourly/per-10min scheduling.
# Choose hourly sched and run per 3 hours by checking the time in this script.
def run?
  Time.now.hour % 3 == 0
end

def run
  # Run this script once per 3 hours
  return unless run?

  client = Twitter::REST::Client.new do |config|
    config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
    config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
    config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
    config.access_token_secret = ENV['TWITTER_ACCESS_SECRET']
  end

  tweets = tweets_in_12hours(client)
  puts "#{tweets.size} tweets retrieved"
  tweets = tweets.select{|t| i_want_this? t.text }
  puts "I want #{tweets.size} gear(s)"
  notify_me(client, tweets)
end
