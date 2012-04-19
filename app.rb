#! ruby -EUTF-8:UTF-8
# coding: UTF-8

# 参考 : http://codezine.jp/article/detail/2180

$LOAD_PATH.unshift File.join( File.dirname(__FILE__), 'lib' )
$LOAD_PATH.unshift File.join( File.dirname(__FILE__), 'modules', 'OAuthSimple', 'lib' )

require 'json'
require 'curses'
require 'oauth_simple'

require 'twivi/worker'
#require "editwind"
#require "commandwind"
# [追加]
#require "handler"

# OAuth の credentials の設定を書いたファイル
oauth_credentials_file_name = 'config/oauth_credentials.json'

# preparing OAuth credentials
json_str = File.read( File.join( File.dirname(__FILE__), oauth_credentials_file_name ) )
credentials_json = JSON.parse( json_str )

class Status
  def initialize( text )
    @text = text
  end
  def text; @text end
end
class Model
  def initialize( data_manager )
    @data_manager = data_manager
  end

  class LatestStatuses < Model
    def initialize( data_manager, num_statuses )
      super( data_manager )
      @listeners = []
      @num_statuses = num_statuses
    end
    def on_change_data
      @data = nil
      @listeners.each{ |e| e.notify( self ) }
    end
    def get_data
      @data ||= @data_manager.get_latest_statuses( @num_statuses )
    end
    def add_change_listener( listener )
      @listeners << listener
    end
  end
end

class DataManager
  def initialize
    @statuses = []
  end
  def add_status( status )
    @statuses << status
    @model_latest_statuses.on_change_data if @model_latest_statuses
  end
  def get_latest_statuses( num_statuses )
    e = @statuses.length
    s = e - num_statuses
    if s < 0 then s = 0 end
    @statuses[s,e]
  end
  def get_model_latest_statuses
    @model_latest_statuses ||= Model::LatestStatuses.new( self, 20 )
  end
end

class View
  def initialize( data_manager )
    model = data_manager.get_model_latest_statuses
    model.add_change_listener( self )
    Curses.init_screen
    #コンソール画面を初期化し初期設定を行う
    Curses.cbreak
    Curses.noecho
    # デフォルトウィンドウを取得
    win = Curses.stdscr
    # 編集エリアウィンドウを作成
    #edit_wind = EditWind.new(defo_wind)
    # デフォルトウィンドウの高さを少し小さくしたサブウィンドウを作成
    sub_wind = win.subwin( #win.maxy - 3, win.maxx - 4, 0, 0 )
                          win.maxy - 4, win.maxx - 4, 1, 1 )
    win.box( '|', '-' )
    # スクロール機能をONにする
    sub_wind.scrollok(true)
    #sub_wind.box( '|', '-' )

    30.times do |i|
      sub_wind.setpos(1, 0)
      sub_wind.addstr('test 日本語 : ' + i.to_s)
      sub_wind.scroll
    end
    sub_wind.setpos(5, 0)
    sub_wind.addstr( sub_wind.class.inspect )
    #ch = sub_wind.getch #１文字入力。
    win.refresh
    @sub_win = sub_wind
  end
  def notify( model )
    @sub_win.clear
    statuses = model.get_data
    # 画面更新処理
    line_num = 0
    statuses.each do |status|
      @sub_win.setpos( line_num, 0 )
      @sub_win.addstr( status.text )
      line_num = @sub_win.cury
      line_num += 1
    end
    @sub_win.refresh
  end
  def finalize
    #コンソール画面を終了
    Curses.close_screen
  end
end

class App

  # 状態定数
  ST_RUNNING    = 3
  ST_FINALIZING = 4
  ST_FINALIZED  = 5

  def initialize( credentials_json )
    @status = ST_RUNNING

    @data_manager = DataManager.new
    @worker = Twivi::Worker.new( @data_manager, credentials_json )
    @view   = View.new( @data_manager )

  end

  def finalize
    if ST_FINALIZING <= @status
      return
    end
    @status = ST_FINALIZING
    @worker.finalize
    @view.finalize
    @status = ST_FINALIZED
  end

end

stopper = Thread.new do
  sleep
end
# TODO stopper が止まるまで待つ

app = App.new( credentials_json )
Signal.trap( :INT ) { app.finalize; stopper.wakeup }

stopper.join

__END__

# 情報表示エリアウィンドウを作成
#cmmd_wind = CommandWind.new(defo_wind,file_name)
# [追加]イベント処理クラスを生成
#handler = Handler.new

# ファイルをオープンし内容を編集エリアに表示する
#edit_wind.display(file_name)
# [追加]イベントループ
#  while true
    #ch = sub_wind.getch #１文字入力。
    # イベント処理クラスで処理分岐を行う
#    handler = handler.execute(edit_wind,ch)
#  end
