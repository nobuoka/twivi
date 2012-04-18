# coding: UTF-8

# 参考 : http://codezine.jp/article/detail/2180

require "curses"
#require "editwind"
#require "commandwind"
# [追加]
#require "handler"

class DataManager; end
class Worker; def initialize( a ); end end
class View;   def initialize( a ); end end

class App

  # 状態定数
  ST_RUNNING    = 3
  ST_FINALIZING = 4
  ST_FINALIZED  = 5

  def initialize
    @status = ST_RUNNING

    @data_manager = DataManager.new
    @worker = Worker.new( @data_manager )
    @view   = View.new( @data_manager )

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
                          9, win.maxx - 4, 0, 0 )
    # スクロール機能をONにする
    sub_wind.scrollok(true)

    30.times do |i|
      sub_wind.setpos(1, 0)
      sub_wind.addstr('test 日本語 : ' + i.to_s)
      sub_wind.scroll
    end
    sub_wind.setpos(5, 0)
    sub_wind.addstr('test 日本語ああああああああああああああああああああああああああああああああaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa ')
    #ch = sub_wind.getch #１文字入力。
    win.refresh
  end

  def finalize
    if ST_FINALIZING <= @status
      return
    end
    @status = ST_FINALIZING
    #コンソール画面を終了
    Curses.close_screen
    @status = ST_FINALIZED
  end

end

stopper = Thread.new do
  sleep
end
# TODO stopper が止まるまで待つ

app = App.new
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
