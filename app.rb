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

class TextParseFailed < RuntimeError
end

def tweets_in_12hours(client)
  limit = Time.now - 12.hours
  client.user_timeline(891009577252077569).select{|tw| tw.created_at > limit }.tap{|tws| puts "#{tws.size} tweets found" }
end

def parse_text(text)
  gears = "(#{POWERS.join '|'})"

  main = text.match /特別ギアパワー：#{gears}/
  sub = text.match /ブランド：[^(]+\(#{gears}\)/

  unless main && sub
    raise TextParseFailed.new "Failed to parse '#{text}': main: #{main}, sub: #{sub}"
  end

  { special_main: main[1], brand_sub: sub[1] }
end

def i_want_this?(text)
  begin
    p = parse_text text
    puts "Parsed: #{p}"
    p[:special_main] == p[:brand_sub]
  rescue TextParseFailed => e
    STDERR.puts e
    false
  end
end

def notify(client, tweet)
  url = tweet.url.to_s
  puts "Notify: text is '#{tweet.text}', URL is '#{url}'"
  client.create_direct_message('Linda_pp', 'Target gear was found in gesotown: ' + url)
end

def run?
  Time.now.hour % 6 == 0
end

def run
  return unless run?

  client = Twitter::REST::Client.new do |config|
    config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
    config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
    config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
    config.access_token_secret = ENV['TWITTER_ACCESS_SECRET']
  end

  tweets_in_12hours(client).select{|t| i_want_this? t.text }.tap{|ts| puts "I want #{ts.size} gear(s)" }.each{|t| notify(client, t)}
end
