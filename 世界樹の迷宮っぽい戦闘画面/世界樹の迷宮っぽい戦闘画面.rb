#==============================================================================
# ■ 世界樹の迷宮っぽい戦闘画面
#   @version 0.3 2012/09/09
#   @author さば缶
#------------------------------------------------------------------------------
#   ※ Graphics/Pictures フォルダにアクター画像があれば、戦闘中に表示します。
#==============================================================================

module Saba
  module Sekaiju2
    
    # 顔グラが移動する速度(毎フレームのピクセル数)
    FACE_SPEED = 128
    
    # 顔グラの表示位置
    FACE_X     = 240
    FACE_Y     = 360
    
    # アクターごとの顔グラの座標修正値。アクターIDがキー
    # y座標は下揃え
    FACE_OFFSET_X = {1=>20, 2=>-95, 3=>160}
    FACE_OFFSET_Y = {2=>120}
    
    # パーティーコマンドを有効にする場合true
    ENABLE_PARTY_COMMAND = false

    # パーティーコマンド＆アクターコマンドの座標
    PARTY_COMMAND_Y = 160
    ACTOR_COMMAND_Y = 160
    
    # スキルウィンドウ＆アイテムウィンドウの座標
    SKILL_WINDOW_X = 127
    SKILL_WINDOW_Y = 130
    
    # 敵選択カーソルの座標。敵の座標からの相対値
    CURSOR_X = -63
    CURSOR_Y = 90
    
    # 敵選択カーソル内でのHPバーの座標と長さ
    GAUGE_X = 30
    GAUGE_Y = -8
    GAUGE_WIDTH = 73
  end
end

class Scene_Battle
  include Saba::Sekaiju2
  #--------------------------------------------------------------------------
  # ● 全ウィンドウの作成
  #--------------------------------------------------------------------------
  alias saba_sekaiju2_create_all_windows create_all_windows
  def create_all_windows
    saba_sekaiju2_create_all_windows
    create_face_sprite
  end
  #--------------------------------------------------------------------------
  # ○ 顔グラを表示するスプライトの作成
  #--------------------------------------------------------------------------
  def create_face_sprite
    @face_sprite = Sprite_SekaijuFace.new
    @actor_command_window.face_sprite = @face_sprite
  end
  #--------------------------------------------------------------------------
  # ● 情報表示ビューポートの作成
  #--------------------------------------------------------------------------
  alias saba_sekaiju2_create_actor_window create_actor_window
  def create_actor_window
    saba_sekaiju2_create_actor_window
    @actor_window.viewport = nil
    @actor_window.x = (Graphics.width - @actor_window.width) / 2
    @status_window.viewport = nil
    @status_window.x = @actor_window.x
    @status_window.y = 360
  end
  #--------------------------------------------------------------------------
  # ● パーティコマンドウィンドウの作成
  #--------------------------------------------------------------------------
  alias saba_sekaiju2_create_party_command_window create_party_command_window
  def create_party_command_window
    saba_sekaiju2_create_party_command_window
    @party_command_window.viewport = nil
    @party_command_window.y = PARTY_COMMAND_Y
  end
  #--------------------------------------------------------------------------
  # ● アクターコマンドウィンドウの作成
  #--------------------------------------------------------------------------
  alias saba_sekaiju2_create_actor_command_window create_actor_command_window
  def create_actor_command_window
    saba_sekaiju2_create_actor_command_window
    @actor_command_window.viewport = nil
    @actor_command_window.x = 0
  end
  #--------------------------------------------------------------------------
  # ● 敵キャラウィンドウの作成
  #--------------------------------------------------------------------------
  alias saba_sekaiju2_create_enemy_window create_enemy_window
  def create_enemy_window
    saba_sekaiju2_create_enemy_window
    @enemy_window.help_window = @help_window
  end
  #--------------------------------------------------------------------------
  # ● パーティコマンド選択の開始
  #--------------------------------------------------------------------------
  def start_party_command_selection
    unless scene_changing?
      refresh_status
      @status_window.unselect
      @status_window.open
      if BattleManager.input_start
        if ENABLE_PARTY_COMMAND
          @actor_command_window.hide
          @party_command_window.setup
          @face_sprite.actor = nil
        else
          next_command
        end
      else
        @party_command_window.deactivate
        turn_start
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● アクター選択の開始
  #--------------------------------------------------------------------------
  alias saba_sekaiju2_select_actor_selection select_actor_selection
  def select_actor_selection
    saba_sekaiju2_select_actor_selection
    @status_window.hide
  end
  #--------------------------------------------------------------------------
  # ● アクター［決定］
  #--------------------------------------------------------------------------
  alias saba_sekaiju2_on_actor_ok on_actor_ok
  def on_actor_ok
    saba_sekaiju2_on_actor_ok
    @status_window.show
  end
  #--------------------------------------------------------------------------
  # ● アクター［キャンセル］
  #--------------------------------------------------------------------------
  alias saba_sekaiju2_on_actor_cancel on_actor_cancel
  def on_actor_cancel
    @status_window.show
    saba_sekaiju2_on_actor_cancel
  end
  #--------------------------------------------------------------------------
  # ● 前のコマンド入力へ
  #--------------------------------------------------------------------------
  def prior_command
    if BattleManager.prior_command
      start_actor_command_selection
    else
      if ENABLE_PARTY_COMMAND
        start_party_command_selection
        @actor_command_window.clear
      else
        next_command
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 敵キャラ選択の開始
  #--------------------------------------------------------------------------
  alias saba_sekaiju2_select_enemy_selection select_enemy_selection
  def select_enemy_selection
    @actor_command_window.hide
    @item_window.hide
    @skill_window.hide
    saba_sekaiju2_select_enemy_selection
  end
  #--------------------------------------------------------------------------
  # ● 敵キャラ［キャンセル］
  #--------------------------------------------------------------------------
  alias saba_sekaiju2_on_enemy_cancel on_enemy_cancel
  def on_enemy_cancel
    saba_sekaiju2_on_enemy_cancel
    @actor_command_window.show
  end
end


class Window_BattleEnemy < Window_Selectable
  include Saba::Sekaiju2
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     info_viewport : 情報表示用ビューポート
  #--------------------------------------------------------------------------
  def initialize(info_viewport)
    super(0, 0, window_width, window_height)
    refresh
    self.visible = false
    self.opacity = 0
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
    self.contents.clear
    img = Cache.system("enemy_cursor")
    enemy = selected_enemy
    self.contents.blt(enemy.screen_x + CURSOR_X, CURSOR_Y, img, img.rect)
    draw_gauge(enemy.screen_x + CURSOR_X + GAUGE_X, CURSOR_Y + GAUGE_Y, GAUGE_WIDTH, enemy.hp_rate, hp_gauge_color1, hp_gauge_color2)
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
    @help_window.hide if @help_window
  end
  #--------------------------------------------------------------------------
  # ○ 選択されている敵の取得
  #--------------------------------------------------------------------------
  def selected_enemy
    return $game_troop.alive_members[self.index]
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

class Sprite_SekaijuFace < Sprite_Base
  include Saba::Sekaiju2
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  alias saba_sekaiju2_initialize initialize
  def initialize()
    saba_sekaiju2_initialize(Viewport.new)
    self.bitmap = Bitmap.new(440, 480)
    self.viewport.ox = -740
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  alias saba_sekaiju2_dispose dispose
  def dispose
    self.bitmap.dispose
    self.viewport.dispose
    saba_sekaiju2_dispose
  end
  #--------------------------------------------------------------------------
  # ○ 表示するアクター設定
  #--------------------------------------------------------------------------
  def actor=(actor)
    if @actor == actor
      return
    end
    @actor = actor
    @to_appear = false
    show
  end
  #--------------------------------------------------------------------------
  # ● スプライトの非表示
  #--------------------------------------------------------------------------
  def hide
    @show_flag = false
    @to_appear = false
  end
  #--------------------------------------------------------------------------
  # ● スプライトの表示
  #--------------------------------------------------------------------------
  def show
    @show_flag = true
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    return unless @actor
    self.bitmap.clear
    begin
      image = Cache.picture("Actor" + @actor.id.to_s)
    rescue SystemCallError
      p "Graphics/Pictures/Actor#{@actor.id} が見つかりません。"
      return
    end
    x = 100
    y = FACE_Y - image.rect.height
    
    x += FACE_OFFSET_X[@actor.id] if FACE_OFFSET_X[@actor.id]
    y += FACE_OFFSET_Y[@actor.id] if FACE_OFFSET_Y[@actor.id]
    self.bitmap.blt(x, y, image, image.rect)
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    return unless self.viewport
    if @to_appear
      move_viewport(-FACE_X)
    else
      move_viewport(-740)
      if self.viewport.ox == -740
        refresh
        @to_appear = true if @actor && @show_flag
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 情報表示ビューポートの移動
  #--------------------------------------------------------------------------
  def move_viewport(ox)
    current_ox = self.viewport.ox
    self.viewport.ox = [ox, current_ox + FACE_SPEED].min if current_ox < ox
    self.viewport.ox = [ox, current_ox - FACE_SPEED].max if current_ox > ox
  end
end


#==============================================================================
# ■ Window_PartyCommand
#==============================================================================
class Window_PartyCommand < Window_Command
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0)
    self.openness = 0
    deactivate
  end
end


#==============================================================================
# ■ Window_ActorCommand
#==============================================================================
class Window_ActorCommand
  include Saba::Sekaiju2
  attr_accessor :face_sprite
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  alias saba_sekaiju2_initialize initialize
  def initialize
    saba_sekaiju2_initialize
    self.viewport = Viewport.new
    self.viewport.z = 2
    self.viewport.ox = self.width
    self.viewport.oy = -ACTOR_COMMAND_Y
  end
  #--------------------------------------------------------------------------
  # ● セットアップ
  #--------------------------------------------------------------------------
  alias saba_sekaiju2_setup setup
  def setup(actor)
    show
    self.openness = 255
    if @actor != actor
      select(0)
      @to_appear = false
    else
      activate
      return
    end
    @actor = actor
    @face_sprite.actor = actor
    activate
    self.viewport.ox = self.width
  end
  def viewport=(v)
    return if self.viewport # 2回目以降は無効に
    super
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  def dispose
    self.viewport.dispose
    @face_sprite.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウの非表示
  #--------------------------------------------------------------------------
  def hide
    @to_appear = false
    self.openness = 255
    deactivate
    @show_flag = false
    @face_sprite.hide if @face_sprite
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウの表示
  #--------------------------------------------------------------------------
  def show
    super
    @show_flag = true
    @face_sprite.show if @face_sprite
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウのアクティブ化
  #--------------------------------------------------------------------------
  def activate
    super
    @face_sprite.show if @face_sprite
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウの非アクティブ化
  #--------------------------------------------------------------------------
  def deactivate
    @show_flag = false
    super
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウを閉じる
  #--------------------------------------------------------------------------
  def close
    super
    @face_sprite.hide if @face_sprite
  end
  #--------------------------------------------------------------------------
  # ● 表示行数の取得
  #--------------------------------------------------------------------------
  def visible_line_number
    return super
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    @face_sprite.update if @face_sprite
    return unless self.viewport
    if @to_appear
      move_viewport(0)
    else
      move_viewport(self.width)
      if self.viewport.ox == self.width
        if @actor && @show_flag
          remake_command
          @to_appear = true
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ コマンド内容を再作成
  #--------------------------------------------------------------------------
  def remake_command
    clear_command_list
    make_command_list
    self.height = contents_height + standard_padding*2
    create_contents
    refresh
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ内容の高さを計算
  #--------------------------------------------------------------------------
  def contents_height
    return visible_line_number * line_height
  end
  #--------------------------------------------------------------------------
  # ● 情報表示ビューポートの移動
  #--------------------------------------------------------------------------
  def move_viewport(ox)
    current_ox = self.viewport.ox
    self.viewport.ox = [ox, current_ox + self.width/3].min if current_ox < ox
    self.viewport.ox = [ox, current_ox - self.width/3].max if current_ox > ox
  end
  def clear
    @actor = nil
    @face_sprite.actor = nil
  end
end


#==============================================================================
# ■ Sekaiju2_Window
#------------------------------------------------------------------------------
# 　スキルウィンドウ、アイテムウィドウの共通モジュール
#==============================================================================
module Sekaiju2_Window
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  def dispose
    self.viewport.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 桁数の取得
  #--------------------------------------------------------------------------
  def col_max
    return 1
  end
  #--------------------------------------------------------------------------
  # ○ 対応するアクター設定
  #--------------------------------------------------------------------------
  def actor=(actor)
    super
    self.opacity = 0
    self.viewport.ox = 180
    self.visible = true
    @appear = true
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    if @appear
      self.opacity += 80 if self.opacity < 255
      self.contents_opacity += 80 if self.contents_opacity < 255
      self.viewport.ox -= 40 if self.viewport.ox > 0
    else
      self.opacity -= 80 if self.opacity > 0
      self.contents_opacity -= 80 if self.contents_opacity > 0
      self.viewport.ox += 40 if self.viewport.ox < 180
      self.visible = false if self.opacity == 0
    end
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウの非表示
  #--------------------------------------------------------------------------
  def hide
    @appear = false
    cursor_rect.empty
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウの非アクティブ化
  #--------------------------------------------------------------------------
  def activate
    super
    return if self.opacity == 255
    self.opacity = 0
    self.viewport.ox = 180
    self.visible = true
    @appear = true
    @help_window.show
  end
end


#==============================================================================
# ■ Window_BattleSkill
#==============================================================================
class Window_BattleSkill < Window_SkillList
  include Saba::Sekaiju2
  include Sekaiju2_Window
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     info_viewport : 情報表示用ビューポート
  #--------------------------------------------------------------------------
  def initialize(help_window, info_viewport)
    super(SKILL_WINDOW_X, SKILL_WINDOW_Y, 250, 200)
    self.visible = false
    @help_window = help_window
    self.viewport = Viewport.new
    self.viewport.z = 1
    self.viewport.ox = 200
  end
end


#==============================================================================
# ■ Window_BattleItem
#==============================================================================
class Window_BattleItem < Window_ItemList
  include Saba::Sekaiju2
  include Sekaiju2_Window
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     info_viewport : 情報表示用ビューポート
  #--------------------------------------------------------------------------
  def initialize(help_window, info_viewport)
    super(SKILL_WINDOW_X, SKILL_WINDOW_Y, 250, 200)
    self.visible = false
    @help_window = help_window
    self.viewport = Viewport.new
    self.viewport.z = 1
    self.viewport.ox = 200
  end
end