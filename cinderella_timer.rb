require 'discordrb'
require "date"
require 'holiday_japan'

bot = Discordrb::Commands::CommandBot.new(
  token: TOKEN,
  client_id: CLIENT_ID,
  prefix:'/'
)


# 接続しているチャンネルをハッシュで管理
# user_id => channel_id
# デフォルトで保持しているのはCinderella-timerのみ
@connecting_channel = {825048349022748682 => "ofline"}

# ボイスチャンネルへ接続されたときにハッシュを更新
bot.voice_state_update do |event|
  user_id = event.user.id

  if event.channel != nil
    channel_id = event.channel.id
    @connecting_channel[user_id] = channel_id
  else
    @connecting_channel[user_id] = "ofline"
  end  
end


# botを自分が接続しているチャンネルに参加させる
bot.command :join do |event|
  user_id = event.user.id

  # コマンドが、どこかのチャンネルに接続している状態で入力されているかチェック
  if @connecting_channel[user_id] != nil
    channel_id = @connecting_channel[user_id]
    if channel_id != "ofline"
      @voice_bot = bot.voice_connect channel_id
      event.send_message("joined!")
    else
      event.send_message("どこかのチャンネルに接続してからコマンドを入力してください。")
    end
  else
    event.send_message("どこかのチャンネルに接続してからコマンドを入力してください。")
  end
end


# botのチャンネル接続を切断する
# discordrbが未更新のため、エラーが発生する
bot.command :disconnect do |event|
  user_id = 825048349022748682
  channel_id = @connecting_channel[user_id]
  if channel_id != "ofline"
    @voice_bot.destroy
    event.send_message("disconnected!")
  else
    event.send_message("Cinderella-timerはチャンネルに接続されていません。")
  end
end


previous = Date.today -1
# previous = Date.today
bot.heartbeat do |event|
  now = Date.today
  # 日付が変わったときの判定(40秒程度の誤差あり)
  if previous < now
    # 翌日が祝日か土日
    if HolidayJapan.check(now) || now.wday == 0 || now.wday == 6
      voice_bot = bot.voice_connect 825262242555101199
      voice_bot.play_file 'data/kyuujitu.mp3'
      voice_bot.destroy
    else
      voice_bot = bot.voice_connect 825262242555101199
      voice_bot.play_file 'data/heijitu.mp3'
      voice_bot.destroy
    end

    previous = now
  end
end

bot.run