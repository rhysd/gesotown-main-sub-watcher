require 'test/unit'
require './app'

class ParseTextTest < Test::Unit::TestCase
  def test_non_target_gear
    text = <<~EOS
      キングタンク マリン(通常ギアパワー：相手インク影響軽減)が入荷しました。
      特別ギアパワー：ヒト移動速度アップ
      ブランド：エンペリー(サブ性能アップ)
      スロット：1
      1回目の組合せです。
    EOS
    p = parse_text text
    assert_equal(p[:special_main], 'ヒト移動速度アップ')
    assert_equal(p[:brand_sub], 'サブ性能アップ')

    text = <<~EOS
      ボーダービーニー(通常ギアパワー：スタートダッシュ)が入荷しました。
      特別ギアパワー：インク効率アップ（サブ）
      ブランド：ジモン(インク効率アップ(メイン))
      スロット：1
      1回目の入荷です。
    EOS
    p = parse_text text
    assert_equal(p[:special_main], 'インク効率アップ(サブ)')
    assert_equal(p[:brand_sub], 'インク効率アップ(メイン)')
  end

  def test_target_gear
    text = <<~EOS
      バンドT SQUIDSQUAD(通常ギアパワー：相手インク影響軽減)が入荷しました。
      特別ギアパワー：ヒト移動速度アップ
      ブランド：ロッケンベルグ(ヒト移動速度アップ)
      スロット：1
      1回目の入荷です。
    EOS
    p = parse_text text
    assert_equal(p[:special_main], 'ヒト移動速度アップ')
    assert_equal(p[:brand_sub], 'ヒト移動速度アップ')
  end

  def test_parse_failure
    assert_raise TextParseFailed do
      parse_text 'this is dummy text'
    end
  end
end

class PopularTweetTest < Test::Unit::TestCase
  class MockTweet
    attr_accessor :retweet_count, :favorite_count
    def initialize
      @retweet_count = 0
      @favorite_count = 0
    end
  end

  def test_popular_tweet
    tw = MockTweet.new
    tw.retweet_count = 142
    assert popular_tweet?(tw)

    tw = MockTweet.new
    tw.favorite_count = 142
    assert popular_tweet?(tw)
  end

  def test_non_popular_tweet
    tw = MockTweet.new
    tw.retweet_count = 42
    tw.favorite_count = 42
    assert !popular_tweet?(tw)
  end
end

class IWantThisTest < Test::Unit::TestCase
  def test_i_dont_want
    text = <<~EOS
      キングタンク マリン(通常ギアパワー：相手インク影響軽減)が入荷しました。
      特別ギアパワー：ヒト移動速度アップ
      ブランド：エンペリー(サブ性能アップ)
      スロット：1
      1回目の組合せです。
    EOS
    assert (not i_want_this?(text))
  end

  def test_i_want
    text = <<~EOS
      バンドT SQUIDSQUAD(通常ギアパワー：相手インク影響軽減)が入荷しました。
      特別ギアパワー：ヒト移動速度アップ
      ブランド：ロッケンベルグ(ヒト移動速度アップ)
      スロット：1
      1回目の入荷です。
    EOS
    assert i_want_this?(text)
  end

  def test_parens_gear_power
    # Edge case
    text = <<~EOS
      ボーダービーニー(通常ギアパワー：スタートダッシュ)が入荷しました。
      特別ギアパワー：インク効率アップ（メイン）
      ブランド：ジモン(インク効率アップ(メイン))
      スロット：1
      1回目の入荷です。
    EOS
    assert i_want_this?(text)
  end

  def test_vip_pair
    text = <<~EOS
      ボーダービーニー(通常ギアパワー：スタートダッシュ)が入荷しました。
      特別ギアパワー：ステルスジャンプ
      ブランド：クラーゲス(スーパージャンプ時間短縮)
      スロット：1
      1回目の入荷です。
    EOS
    assert i_want_this?(text)
  end
end
