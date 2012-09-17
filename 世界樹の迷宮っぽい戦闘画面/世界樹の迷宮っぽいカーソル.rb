#==============================================================================
# ■ 世界樹の迷宮っぽい敵選択カーソル
#   @version 0.2 2012/09/17
#   @author さば缶
#------------------------------------------------------------------------------
#   ※ Graphics/System フォルダの画像が必要です。
#==============================================================================

module Saba
  module Sekaiju3
    
    # 敵選択カーソルの座標。敵の座標からの相対値
    CURSOR_X = -65
    CURSOR_Y = 90
    
    # 敵選択カーソル内でのHPバーの座標と長さ
    GAUGE_X = 30
    GAUGE_Y = -8
    GAUGE_WIDTH = 73
    
    # カーソルのY座標も敵の座標にあわせる場合 true
    ADJUST_Y = false
    # カーソルの最小Y座標
    CURSOR_MIN_Y = 50
    #CURSOR_Y = -70     # ADJUST_Yを trueのときはこのあたりの数値で
    
    # 敵のHPを表示しない場合 true に設定します
    HIDE_ENEMY_HP = false
  end
end


class Scene_Battle
  #--------------------------------------------------------------------------
  # ● 敵キャラ選択の開始
  #--------------------------------------------------------------------------
  alias saba_sekaiju3_select_enemy_selection select_enemy_selection
  def select_enemy_selection
    @item_window.hide
    @skill_window.hide
    saba_sekaiju3_select_enemy_selection
  end
  #--------------------------------------------------------------------------
  # ● 敵キャラ［キャンセル］
  #--------------------------------------------------------------------------
  alias saba_sekaiju3_on_enemy_cancel on_enemy_cancel
  def on_enemy_cancel
    case @actor_command_window.current_symbol
    when :attack
      @actor_command_window.show
    when :skill
      @skill_window.show
    when :item
      @item_window.show
    end
    saba_sekaiju3_on_enemy_cancel
  end
end

class Window_BattleEnemy < Window_Selectable
  include Saba::Sekaiju3
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     info_viewport : 情報表示用ビューポート
  #--------------------------------------------------------------------------
  def initialize(info_viewport)
    super(0, 0, window_width, window_height)
    refresh
    self.visible = false
    self.opacity = 0
    @help_window = Window_Help.new(1)
    @help_window.hide
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  def dispose
    super
    @help_window.dispose
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ幅の取得
  #--------------------------------------------------------------------------
  def window_width
    Graphics.width
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ高さの取得
  #--------------------------------------------------------------------------
  def window_height
    Graphics.height
  end
  def row_max
    return  $game_troop.alive_members.size
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウのアクティブ化
  #--------------------------------------------------------------------------
  def activate
    super
    select(0)
    cursor_rect.empty
    call_update_help
    return self
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    cursor_rect.empty
    enemy = selected_enemy
    self.contents.clear
    if ADJUST_Y
      y = enemy.screen_y + CURSOR_Y - Cache.battler(enemy.battler_name, enemy.battler_hue).height
      y = [y, CURSOR_MIN_Y].max
    else
      y = CURSOR_Y
    end
    if HIDE_ENEMY_HP
      img = Cache.system("enemy_cursor2")
      self.contents.blt(enemy.screen_x + CURSOR_X, y, img, img.rect)
    else
      img = Cache.system("enemy_cursor")
      self.contents.blt(enemy.screen_x + CURSOR_X, y, img, img.rect)
      draw_gauge(enemy.screen_x + CURSOR_X + GAUGE_X, y + GAUGE_Y, GAUGE_WIDTH, enemy.hp_rate, hp_gauge_color1, hp_gauge_color2)
    end
  end
  #--------------------------------------------------------------------------
  # ● 項目の選択
  #--------------------------------------------------------------------------
  def select(index)
    self.index = index
    refresh
    call_update_help
  end
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #--------------------------------------------------------------------------
  def draw_item(index)
    # 何もしない
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウの非表示
  #--------------------------------------------------------------------------
  def hide
    super
    @help_window.hide
  end
  #--------------------------------------------------------------------------
  # ○ 選択されている敵の取得
  #--------------------------------------------------------------------------
  def selected_enemy
    e = $game_troop.alive_members[self.index]
    return e if e
    self.index = 0
    $game_troop.alive_members[self.index]
  end
  #--------------------------------------------------------------------------
  # ● ヘルプウィンドウの更新
  #--------------------------------------------------------------------------
  def update_help
    @help_window.clear
    @help_window.set_text(selected_enemy.name)
    @help_window.show
  end
end
