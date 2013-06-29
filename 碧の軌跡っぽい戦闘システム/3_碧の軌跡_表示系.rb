#==============================================================================
# ■ 碧の軌跡っぽい戦闘システム18　表示系
#   @version 0.29 12/05/05
#   @author さば缶
#------------------------------------------------------------------------------
# 　表示部分をカスタムしたい場合はここをいじってください
#==============================================================================
module Saba
  module Kiseki
    # 左の隙間
    MARGIN_LEFT = 10
    
    # 上の隙間
    MARGIN_TOP = 10
    
    # 先頭ユニットと２番目のユニットの隙間
    MARGIN_CURRENT_BOTTOM = 10
    
    # ユニット同士の y 方向の間隔
    UNIT_INTERVAL = 32
    
    # 新規ユニットが入るときの x 方向の移動距離
    INSERT_DISTANCE = 32
    
    # 行動するときのディレイ表示タイプ
    # 0 文字で DELAY
    # 1 時計アイコン
    DELAY_DISPLAY_TYPE = 0
    
    # 左の順番バーの高さ
    ORDER_BAR_HEIGHT = 460
    
    # キャンセルメッセージ
    CANCEL_MSG         = "%sの%sはキャンセルされた！"
    FAIL_CANCEL_MSG    = "%sの%sをキャンセルできなかった！"
    ANTI_CANCEL_MSG    = "%sの%sはキャンセルできない！"
    
    # ディレイメッセージ
    DELAY_ENEMY_MSG    =  "%sの行動を %s コマ遅らせた！"
    DELAY_ACTOR_MSG    =  "%sの行動が %s コマ遅れた！"
    HASTE_ENEMY_MSG    =  "%sの行動が %s コマ早まった！"
    HASTE_ACTOR_MSG    =  "%sの行動を %s コマ早めた！"
    ANTI_DELAY_MSG     =  "%sの行動を遅らせられない！"
    FAIL_DELAY_MSG     =  "%sの行動を遅らせられなかった！"
    
    # 敵番号の表示設定
    SHOW_ENEMY_LABEL = true
    ENEMY_LABEL_X = 20
    ENEMY_LABEL_Y = 14
    
    
    # 0→敵全体の中での順番
    # 1→敵グループ内での順番
    ENEMY_LABEL_TYPE = 1
    
    # ENEMY_LABEL_TYPE が1のときに使われます
    ENEMY_LABEL = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    
    # グループでない敵にもラベルをつける場合 true
    # ENEMY_LABEL_TYPE が0のときに使われます
    SET_LABEL_AT_SINGLE_ENEMY = false
    
    ENEMY_LABEL_FONT_SIZE = 17
    ENEMY_LABEL_FONT_BOLD = true
  end
end


#==============================================================================
# ■ Spriteset_BattleUnit
#------------------------------------------------------------------------------
# 　画面左の待ち時間バー上に表示するユニットです
#==============================================================================

class Spriteset_BattleUnit
  include Saba::Kiseki
  
  TARGET_ENEMY_COLOR = Color.new(255, 0, 0, 255)
  TARGET_ACTOR_COLOR = Color.new(0, 0, 255, 255)
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(viewport, unit)
    super
    @viewport = viewport 
    @unit = unit
    @battler = unit.battler
    @forecast = false
    
    @layers = []
    
    create_bg_layer
    create_char_layer
    create_char_select_layer
    create_enemy_label_layer
    create_marker_layer
    create_targeted_layer
    create_arrow_layer
  end
  #--------------------------------------------------------------------------
  # ○ 背景レイヤの作成
  #--------------------------------------------------------------------------
  def create_bg_layer
    @bg_layer = Sprite_Base.new(@viewport)
    @bg_layer.bitmap = Bitmap.new(64, 64)
    if @battler.actor?
      border = Cache.system("UnitBorder")
    else
      border = Cache.system("UnitBorder2")
    end
    @bg_layer.bitmap.blt(0, 0, border, border.rect)
    @bg_layer.z = 1
    
    @layers.push(@bg_layer)
  end
  #--------------------------------------------------------------------------
  # ○ キャラレイヤの作成
  #--------------------------------------------------------------------------
  def create_char_layer
    @char_layer = Sprite_Base.new(@viewport)
    @char_layer.bitmap = Bitmap.new(32, 32)
    @char_layer.z = 2
    init_graphic
    draw_character(@char_layer, @graphic_name, @graphic_index)
    @layers.push(@char_layer)
  end
  #--------------------------------------------------------------------------
  # ○ キャラ選択レイヤの作成
  #--------------------------------------------------------------------------
  def create_char_select_layer
    @char_select_layer = Sprite_Base.new(@viewport)
    @char_select_layer.bitmap = Bitmap.new(32, 32)
    @char_select_layer.z = 3
    draw_character(@char_select_layer, @graphic_name, @graphic_index)
    @char_select_layer.blend_type = 1
    if @battler.actor?
      @char_select_layer.color = TARGET_ACTOR_COLOR
    else
      @char_select_layer.color = TARGET_ENEMY_COLOR
    end
    @layers.push(@char_select_layer)
  end
  #--------------------------------------------------------------------------
  # ○ マーカーレイヤの作成
  #--------------------------------------------------------------------------
  def create_marker_layer
    @marker_layer = Sprite_Base.new(@viewport)
    @marker_layer.bitmap = Bitmap.new(32, 32)
    @marker_layer.z = 4
    marker = Cache.system("ActionMarker")
    @marker_layer.bitmap.blt(0, 0, marker, marker.rect)
    @marker_layer.visible = false
    @layers.push(@marker_layer)
  end
  #--------------------------------------------------------------------------
  # ○ 駆動の対象レイヤの作成
  #--------------------------------------------------------------------------
  def create_targeted_layer
    @targeted_layer = Sprite_Base.new(@viewport)
    @targeted_layer.bitmap = Bitmap.new(32, 32)
    @targeted_layer.z = 5
    marker = Cache.system("Targeted")
    @targeted_layer.bitmap.blt(0, 0, marker, marker.rect)
    @targeted_layer.visible = false
    @layers.push(@targeted_layer)
  end
  #--------------------------------------------------------------------------
  # ○ 敵番号レイヤの作成
  #--------------------------------------------------------------------------
  def create_enemy_label_layer
    return unless SHOW_ENEMY_LABEL
    return if @battler.actor?
    @enemy_label_layer = Sprite_Base.new(@viewport)
    @enemy_label_layer.bitmap = Bitmap.new(50, 32)
    @enemy_label_layer.z = 6
    
    @enemy_label_layer.bitmap.font.size = ENEMY_LABEL_FONT_SIZE
    @enemy_label_layer.bitmap.font.bold = ENEMY_LABEL_FONT_BOLD
    if ENEMY_LABEL_TYPE == 0
      index = $game_troop.members.index(@battler)
      @enemy_label_layer.bitmap.draw_text(ENEMY_LABEL_X, ENEMY_LABEL_Y, 32, 24, ENEMY_LABEL[index])
    else
      return if ! SET_LABEL_AT_SINGLE_ENEMY && ! @battler.plural
      @enemy_label_layer.bitmap.draw_text(ENEMY_LABEL_X, ENEMY_LABEL_Y, 32, 24, @battler.letter)
    end
    

    @layers.push(@enemy_label_layer)
  end
  #--------------------------------------------------------------------------
  # ○ 矢印レイヤの作成
  #--------------------------------------------------------------------------
  def create_arrow_layer
    @arrow_layer = Sprite_Base.new(@viewport)
    @arrow_layer.bitmap = Bitmap.new(64, 32)
    @arrow_layer.z = 7
    arrow = Cache.system("ForecastArrow")
    @arrow_layer.bitmap.blt(0, 0, arrow, arrow.rect)
    @layers.push(@arrow_layer)
    
    @arrow_index = 12
  end
  #--------------------------------------------------------------------------
  # ○ 解放
  #--------------------------------------------------------------------------
  def dispose
    @layers.each do |layer|
      layer.bitmap.dispose
      layer.dispose
    end

    @forecast_sprite.dispose if @forecast_sprite
  end
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  def update
    x = @unit.x + MARGIN_LEFT
    y = @unit.y + MARGIN_TOP
    
    @layers.each do |layer|
      layer.x = x
      layer.y = y
      layer.update
    end

    @arrow_layer.x += @arrow_index
    @arrow_layer.visible = @unit.forecast
    @arrow_index -= 0.25
    @arrow_index = 12 if @arrow_index == 0

    @char_select_layer.visible = @unit.selected
    @marker_layer.visible = @unit.operate
    @targeted_layer.visible = @unit.targeted

    update_forecast
    update_opacity
  end
  #--------------------------------------------------------------------------
  # ○ 使用するグラフィックを決定します。
  #--------------------------------------------------------------------------
  def init_graphic
    if @battler.actor?
      @graphic_name = @battler.character_name
      @graphic_index = @battler.character_index
    else
      @graphic_name = enemy_graphic_name
      @graphic_index = enemy_graphic_index
    end
  end
  #--------------------------------------------------------------------------
  # ○ 行動予測を更新
  #--------------------------------------------------------------------------
  def update_forecast
    if @forecast_sprite
      @forecast_sprite.update 
      @forecast_sprite.visible = BattleManager.phase == :input
    end
    return if @forecast == @unit.forecast
    
    if @unit.forecast
      @forecast_sprite = Sprite_Forecast.new(@viewport, @unit)
    else
      @forecast_sprite.dispose
      @forecast_sprite = nil
    end
    @forecast = @unit.forecast
  end
  #--------------------------------------------------------------------------
  # ○ キャラクターグラフィックを描画します。
  #--------------------------------------------------------------------------
  def draw_character(layer, character_name, character_index)
    bitmap = Cache.character(character_name)
    sign = character_name[/^[\!\$]./]
    if sign && sign.include?('$')
      cw = bitmap.width / 3
      ch = bitmap.height / 4
    else
      cw = bitmap.width / 12
      ch = bitmap.height / 8
    end
    n = character_index
    src_rect = Rect.new((n%4*3+1)*cw, (n/4*4)*ch, cw, ch)
    layer.bitmap.blt(0, 0, bitmap, src_rect)
  end
  #--------------------------------------------------------------------------
  # ○ 行動待ちマーカーを描画します。
  #--------------------------------------------------------------------------
  def draw_action_marker
    bitmap = Cache.system("ActionMarker")
    @char_layer.bitmap.blt(0, 0, bitmap, bitmap.rect)
  end
  #--------------------------------------------------------------------------
  # ○ 透明度を更新します。
  #--------------------------------------------------------------------------
  def update_opacity
    opacity  = 255 - @unit.x * 8
    @arrow_layer.opacity = opacity
    @bg_layer.opacity    = opacity
    @char_layer.opacity  = opacity
    @forecast_sprite.opacity    = opacity if @forecast_sprite
  end
  #--------------------------------------------------------------------------
  # ○ バトラーが敵エネミーの場合、使用するグラフィック名を初期化します。
  #--------------------------------------------------------------------------
  def enemy_graphic_name
    marker = Saba::Kiseki::GRAPHIC_MARKER
    graphic = get_ex_value_with_index(@battler.enemy, marker, 0)
    if graphic == nil
      return Saba::Kiseki::DEFAULT_MONSTER_GRAPHIC_NAME
    else
      return graphic
    end
  end
  #--------------------------------------------------------------------------
  # ○ バトラーが敵エネミーの場合、使用するグラフィック内のインデックスを初期化します。
  #--------------------------------------------------------------------------
  def enemy_graphic_index
    marker = Saba::Kiseki::GRAPHIC_MARKER
    index = get_ex_value_with_index(@battler.enemy, marker, 1)
    if index == nil
      return Saba::Kiseki::DEFAULT_MONSTER_GRAPHIC_INDEX
    else
      return index.to_i
    end
  end
  def get_ex_value_with_index(item, name, index)
    item.note.split(/[\r\n]+/).each do |line|
    elements = line.split(/\s+/)
      next if elements.size <= index + 1
      next unless elements[0] == name
      return elements[index + 1]
    end
    return nil
  end
end


#==============================================================================
# ■ Sprite_Forecast
#------------------------------------------------------------------------------
# 　待ち時間表示です。Delay XX というあれ
#==============================================================================

class Sprite_Forecast < Sprite_Base
  include Saba::Kiseki
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(viewport, unit)
    super(viewport)
    @unit = unit
    self.bitmap = Bitmap.new(120, 50)
    @anime_index = 0
    @wait_count = 0
    refresh
    update
    self.z = 5
  end
  def refresh
    self.bitmap.clear
    
    if DELAY_DISPLAY_TYPE == 0
      delay = Cache.system("Delay")
      self.bitmap.font.size = 20
      self.bitmap.blt(0, 0, delay, delay.rect)
      self.bitmap.draw_text(41, 6, 58, 24, @unit.delay_time.to_s, 1)
    else
      delay = Cache.system("Delay2")
      self.bitmap.font.size = 20
      self.bitmap.blt(0, 0, delay, delay.rect)
      clock = Cache.system("icon_clock")
      x = @anime_index % 4 * clock.width / 4
      y = @anime_index / 4 * clock.height / 2
      
      rect = Rect.new(x, y, clock.width / 4, clock.height / 2)
      self.bitmap.blt(3, 3, clock, rect)
      self.bitmap.draw_text(14, 5, 58, 22, @unit.delay_time.to_s, 1)
    end
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    self.x = @unit.x + Saba::Kiseki::MARGIN_LEFT + 45
    self.y = @unit.y + Saba::Kiseki::MARGIN_TOP
    next_anime
  end
  def next_anime
    @wait_count += 1
    if @wait_count > 6
      @anime_index += 1
      @anime_index = 0 if @anime_index == 8
      @wait_count = 0
      refresh
    end
  end
end



#==============================================================================
# ■ Spriteset_Kiseki
#------------------------------------------------------------------------------
# 　待ち時間バーの背景や、先頭キャラの枠など
#==============================================================================

class Spriteset_Kiseki
  include Saba::Kiseki
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(viewport)
    super
    @bg_layer = Sprite_Base.new(viewport)
    @bg_layer.bitmap = Cache.system("OrderLine")
    @bg_layer.z = 0
    @bg_layer.x = 10
    @bg_layer.src_rect.height = ORDER_BAR_HEIGHT
    
    @window_layer = Sprite_Base.new(viewport)
    @window_layer.bitmap = Cache.system("ActiveWindow")
    @window_layer.z = 7
    @window_layer.x = 2
    @window_layer.y = 3
  end
  #--------------------------------------------------------------------------
  # ○ 解放
  #--------------------------------------------------------------------------
  def dispose
    @bg_layer.dispose
    @window_layer.dispose
  end
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  def update
    @bg_layer.update
    @window_layer.update
  end
end



class Window_BattleLog
  include Saba::Kiseki
    #--------------------------------------------------------------------------
  # ● 失敗の表示
  #--------------------------------------------------------------------------
  alias saba_kiseki_battle_display_failure display_failure
  def display_failure(target, item)
    if target.result.hit? && !target.result.success
      saba_kiseki_battle_display_failure(target, item)
    end
    display_cancel(target, item)
    display_delay(target, item)
  end
  #--------------------------------------------------------------------------
  # ○ アイテム準備の表示
  #--------------------------------------------------------------------------
  def display_prepare_item(target, item)
    text = sprintf(item.prepare_msg, target.name, item.name)
    add_text(text)
    wait
    wait
    wait
  end
  #--------------------------------------------------------------------------
  # ○ キャンセルの表示
  #--------------------------------------------------------------------------
  def display_cancel(target, item)
    unit = OrderManager.find_unit(target)
    return unless unit
    usable_item = unit.usable_item
    return if usable_item == nil
    if target.result.cancel
      return unless CANCEL_MSG
      text = sprintf(CANCEL_MSG, target.name, usable_item.name)
      add_text(text)
      wait
    elsif target.result.fail_cancel
      return unless FAIL_CANCEL_MSG
      text = sprintf(FAIL_CANCEL_MSG, target.name, usable_item.name)
      add_text(text)
      wait
    elsif target.result.anti_cancel
      return unless ANTI_CANCEL_MSG
      text = sprintf(ANTI_CANCEL_MSG, target.name, usable_item.name)
      add_text(text)
      wait
    end
  end
  #--------------------------------------------------------------------------
  # ○ ディレイの表示
  #--------------------------------------------------------------------------
  def display_delay(target, item)
    delay = target.result.delay_count
    if delay > 0
      if target.actor?
        return unless DELAY_ACTOR_MSG
        text = sprintf(DELAY_ACTOR_MSG, target.name, delay.to_s)
      else
        return unless DELAY_ENEMY_MSG
        text = sprintf(DELAY_ENEMY_MSG, target.name, delay.to_s)
      end
      add_text(text)
      wait
    elsif delay < 0
      if target.actor?
        return unless HASTE_ACTOR_MSG
        text = sprintf(HASTE_ACTOR_MSG, target.name, delay.abs.to_s)
      else
        return unless HASTE_ENEMY_MSG
        text = sprintf(HASTE_ENEMY_MSG, target.name, delay.abs.to_s)
      end
      add_text(text)
      wait
    elsif target.result.fail_delay
      return unless FAIL_DELAY_MSG
      text = sprintf(FAIL_DELAY_MSG, target.name)
      add_text(text)
      wait
    elsif target.result.anti_delay
      return unless ANTI_DELAY_MSG
      text = sprintf(ANTI_DELAY_MSG, target.name)
      add_text(text)
      wait
    end
  end
end