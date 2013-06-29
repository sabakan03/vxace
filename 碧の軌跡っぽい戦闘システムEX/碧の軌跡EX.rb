#==============================================================================
# ■ 碧の軌跡っぽい戦闘システムEX1
#   @version 0.29 12/05/05
#   @author さば缶
#------------------------------------------------------------------------------
# 　表示部分をカスタムしたい場合はここをいじってください
#==============================================================================
module Saba
  module Kiseki2
   FIELD_WIDTH = 20
   FIELD_HEIGHT = 14
  end
end

class Scene_Battle
  #--------------------------------------------------------------------------
  # ● アクターコマンドウィンドウの作成
  #--------------------------------------------------------------------------
  alias saba_kiseki2_create_actor_command_window create_actor_command_window
  def create_actor_command_window
    saba_kiseki2_create_actor_command_window
    @actor_command_window.viewport = nil
  end

  #--------------------------------------------------------------------------
  # ○ 選択状態の更新
  #--------------------------------------------------------------------------
  alias saba_kiseki2_update_selection update_selection
  def update_selection
    saba_kiseki2_update_selection
    @spriteset.clear_selection
    @spriteset.select(@enemy_window.enemy) if @enemy_window.active
    @spriteset.select(@actor_window.actor) if @actor_window.active
  end
  #--------------------------------------------------------------------------
  # ● スキル／アイテムの使用(再定義！)
  #--------------------------------------------------------------------------
  alias saba_kiski2_battle_use_item use_item
  def use_item
    item = @subject.current_action.item
    unless @subject.actor?
      @spriteset.select_action_tiles(@subject) 
      wait(10)
    end
    targets = @subject.current_action.make_targets.compact
    target = targets[0]
    attack_succeeded = @spriteset.move(@subject, target, item)
    while @spriteset.moving?
      wait(2)
    end
    wait(4)
    @spriteset.clear_battlefield
    return unless attack_succeeded
    if item.animation_id < 0 && @subject.actor?
      @spriteset.start_anime(target, @subject.atk_animation_id1)
    else
      @spriteset.start_anime(target, item.animation_id)
    end

    saba_kiski2_battle_use_item
  end
    #--------------------------------------------------------------------------
  # ● アクターコマンド選択の開始
  #--------------------------------------------------------------------------
  alias saba_kiseki2_start_actor_command_selection start_actor_command_selection
  def start_actor_command_selection
    saba_kiseki2_start_actor_command_selection
    character = @spriteset.get_sprite(BattleManager.actor).character
    @spriteset.clear_selection
    @actor_command_window.x = character.x * 32 + 90
    @actor_command_window.y = character.y * 32 - 20
    @actor_command_window.open
  end
  #--------------------------------------------------------------------------
  # ● コマンド［スキル］
  #--------------------------------------------------------------------------
  alias saba_kiseki2_command_skill command_skill
  def command_skill
    saba_kiseki2_command_skill
    @skill_window.open
  end
  #--------------------------------------------------------------------------
  # ● スキル［キャンセル］
  #--------------------------------------------------------------------------
  alias saba_kiseki2_on_skill_cancel on_skill_cancel
  def on_skill_cancel
    saba_kiseki2_on_skill_cancel
    @spriteset.clear_selection
    @spriteset.clear_battlefield
    @actor_command_window.open
  end
  #--------------------------------------------------------------------------
  # ● アイテム［キャンセル］
  #--------------------------------------------------------------------------
  alias saba_kiseki2_on_item_cancel on_item_cancel
  def on_item_cancel
    saba_kiseki2_on_item_cancel
    @spriteset.clear_selection
    @spriteset.clear_battlefield
    @actor_command_window.open
  end
  #--------------------------------------------------------------------------
  # ● 敵キャラ選択の開始
  #--------------------------------------------------------------------------
  alias saba_kiseki2_select_enemy_selection select_enemy_selection
  def select_enemy_selection
    saba_kiseki2_select_enemy_selection
    @enemy_window.refresh
    @enemy_window.show.activate
    @spriteset.select_action_tiles(BattleManager.actor)
    update_selection
    @actor_command_window.close
    @skill_window.close
    @item_window.close
  end
  #--------------------------------------------------------------------------
  # ● 敵キャラ［キャンセル］
  #--------------------------------------------------------------------------
  alias saba_on_enemy_cancel on_enemy_cancel
  def on_enemy_cancel
    case @actor_command_window.current_symbol
    when :attack
      @actor_command_window.activate
      @spriteset.clear_selection
      @spriteset.clear_battlefield
      @actor_command_window.open
    when :skill
      @skill_window.activate
      @skill_window.open
    when :item
      @item_window.activate
      @item_window.open
    end
    saba_on_enemy_cancel
    
  end
end

class RPG::UsableItem
  def cant_move?
    if @cant_move != nil
      return @cant_move
    end
    @cant_move = self.note.include?("<移動不可>")
    return @cant_move
  end
  #--------------------------------------------------------------------------
  # ○ 攻撃範囲の取得
  #--------------------------------------------------------------------------
  def attack_range(battler)
    attack_range_formula
    return 1 if @attack_range_formula == nil
    a = battler
    c = $game_variables
    p attack_range_formula
    return eval(@attack_range_formula)
  end
  #--------------------------------------------------------------------------
  # ○ 攻撃範囲計算式の取得
  #--------------------------------------------------------------------------
  def attack_range_formula
    return @attack_range_formula if @get_attack_range_formula
    @get_attack_range_formula = true
    self.note.split(/[\r\n]+/).each do |line|
      if line.index("<攻撃範囲>") == 0
        @attack_range_formula = line["<攻撃範囲>".length..-1]
        return @attack_range_formula
      end
    end
    return @attack_range_formula
  end
end



class Game_Battler
  def attack_range
    return current_action.item.attack_range(self)
  end
  def motivity
    if $game_party.in_battle
      if current_action.item.cant_move?
        return 0
      else
        return 4
      end
    else
      return 4
    end
  end
end

#==============================================================================
# ■ Spriteset_BattleField
#------------------------------------------------------------------------------
# 　戦場のスプライトセット
#==============================================================================
class Spriteset_Battle
  
  alias saba_kiseki2_initialize initialize
  def initialize
    saba_kiseki2_initialize
    create_field
  end
  def create_field
    @field_sprite = Sprite_BattleField.new(nil, @actor_sprites, @enemy_sprites)
  end
  #--------------------------------------------------------------------------
  # ● アクタースプライトの作成
  #    デフォルトではアクター側の画像は表示しないが、便宜上、敵と味方を同じ
  #  ように扱うためにダミーのスプライトを作成する。
  #--------------------------------------------------------------------------
  def create_actors
    @actor_sprites = $game_party.battle_members.reverse.collect do |actor|
      Sprite_BattlerPiece.new(@viewport2, actor)
    end
  end
  #--------------------------------------------------------------------------
  # ● 敵キャラスプライトの作成
  #--------------------------------------------------------------------------
  def create_enemies
    @enemy_sprites = $game_troop.members.reverse.collect do |enemy|
      Sprite_BattlerPiece.new(@viewport2, enemy)
    end
  end
  #--------------------------------------------------------------------------
  # ● アクタースプライトの更新
  #--------------------------------------------------------------------------
  def update_actors
    @actor_sprites.each {|sprite| sprite.update }
  end
  #--------------------------------------------------------------------------
  # ● 戦闘背景（床）スプライトの作成
  #--------------------------------------------------------------------------
  def create_battleback1
    @back1_sprite = Sprite.new(@viewport1)
    @back1_sprite.bitmap = battleback1_bitmap
    @back1_sprite.z = 0
    center_sprite(@back1_sprite)
    @back1_sprite.y -= 100
  end
  #--------------------------------------------------------------------------
  # ● 戦闘背景（壁）スプライトの作成
  #--------------------------------------------------------------------------
  def create_battleback2
    @back2_sprite = Sprite.new(@viewport1)
    @back2_sprite.bitmap = battleback2_bitmap
    @back2_sprite.z = 1
    center_sprite(@back2_sprite)
    @back2_sprite.y -= 100
  end
  def select_action_tiles(battler)
    clear_selection
    character = get_sprite(battler).character
    @field_sprite.select_action_tiles(character)
    
    
  end
  def select_enemy
    field_sprite.select_enemy(@enemy_sprites)
  end
  #--------------------------------------------------------------------------
  # ● スプライトの取得
  #--------------------------------------------------------------------------
  def get_sprite(battler)
    if battler.actor?
      for sprite in @actor_sprites
        return sprite if sprite.battler == battler
      end
    else
      for sprite in @enemy_sprites
        return sprite if sprite.battler == battler
      end
    end
    p "ERROR! #{battler.name} のspriteが見つかりません"
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  alias saba_kiseki2_update update
  def update
    saba_kiseki2_update
    @field_sprite.update if @field_sprite
  end
  def clear_selection
    @actor_sprites.each {|sprite| sprite.selected = false }
    @enemy_sprites.each {|sprite| sprite.selected = false }
  end 
  def select(battler)
    get_sprite(battler).selected = true
  end
  def move(subject, target, item)
    s = get_sprite(subject).character
    t = get_sprite(target).character
    attack_succeeded = (s.x - t.x) ** 2 + (s.y - t.y) ** 2 < (subject.motivity + subject.attack_range) ** 2
    tile = @field_sprite.select_attack_tile(s, t, item.attack_range(subject))
    s.x = tile.x
    s.y = tile.y
    return attack_succeeded
  end
  def moving?
    @actor_sprites.each {|sprite| return true if sprite.character.moving? }
    @enemy_sprites.each {|sprite| return true if sprite.character.moving? }
    return false
  end
  def start_anime(battler, animation_id)
    get_sprite(battler).character.animation_id = animation_id
  end
  def clear_battlefield
    @field_sprite.clear
  end
end

class Sprite_BattleField < Sprite_Base
  MOVE_COLOR = Color.new(100, 100, 200, 140)
  
  include Saba::Kiseki2
  def initialize(viewport, actor_sprites, enemy_sprites)
    super(viewport)
    @actor_sprites = actor_sprites
    @enemy_sprites = enemy_sprites
    self.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    self.z = 1
    @offset_x = 32
    @offset_y = 32
    w = FIELD_WIDTH
    h = FIELD_HEIGHT
    @tiles = {}
    w.times do |x|
      h.times do |y|
        @tiles[[x, y]] = Game_BattleFieldTile.new(x, y)
      end
    end
  end
  def tile(x, y)
    return @tiles[[x, y]]
  end
  def clear_tiles
    w = FIELD_WIDTH
    h = FIELD_HEIGHT
    w.times do |x|
      h.times do |y|
        @tiles[[x, y]].clear
      end
    end
  end
  def select_action_tiles(character)
    clear_tiles
    self.bitmap.clear

    battler = character.battler
    cx = character.x * 32 + 16
    cy = character.y * 32 + 16
    rr = ((battler.motivity) * 32) ** 2
    draw_circle(cx, cy, (battler.motivity + battler.attack_range) * 32)
    for tile in @tiles.values
      if tile.in_range?(cx, cy, rr)
        tile.selected = true
        draw_selection(tile.x, tile.y, MOVE_COLOR)
      end
    end

  end
  def clear_selection
    for tile in @tiles.values
      tile.selected = false
    end
  end
  def clear
    #clear_selection
    self.bitmap.clear
  end
  def draw_selection(x, y, color)
    self.bitmap.fill_rect(x * 32 + @offset_x, y * 32 + @offset_y, 32, 32, Color.new(255, 255, 255, 100))
    self.bitmap.fill_rect(x * 32 + 1 + @offset_x, y * 32 + 1 + @offset_y, 30, 30, color)
  end
  def draw_circle(cx, cy, r)
    img = Cache.system("circle1")
    dest = Rect.new((cx - r * 1.1) + @offset_x, (cy - r * 1.1) + @offset_y, r * 2.2, r * 2.2)
    self.bitmap.stretch_blt(dest, img, img.rect)
  end
  def select_attack_tile(subject, target, distance)
    scx = subject.x * 32 + 16
    scy = subject.y * 32 + 16
    tcx = target.x * 32 + 16
    tcy = target.y * 32 + 16
    rr = (distance * 32) ** 2
    subject_tile = tile(subject.x, subject.y)
    if subject_tile.in_range?(tcx, tcy, rr)
      # 今いる場所から攻撃可能
      p "移動なし"
      return subject_tile
    end
    
    if tcx != scx && tcy != scy
      a = (tcy - scy) * 1.0 / (tcx - scx)
      b = Math::sqrt(a ** 2 + 1)
    end

    candidates = []
    for tile in @tiles.values

      if tile.selected 
        next if battler_exists?(tile.x, tile.y)
        # 遠くに移動しすぎ
        next if subject_tile.distance(tile.cx, tile.cy) > subject_tile.distance(tcx, tcy)
        if a
          d = (a * tile.cx - tile.cy + (- a * scx + scy)).abs / b
        else
          d = 0
        end
        candidates.push([(tile.distance(tcx, tcy) - rr), d**2*4.to_i, tile])
      end
    end
    candidates.sort! { |a1, b1|
      # 攻撃範囲内とそうでない場合
      if a1[0] <= 0 && b1[0] > 0
        -1
      elsif a1[0] > 0 && b1[0] <= 0
        1
      else
        (a1[0].abs + a1[1]) <=> (b1[0].abs + b1[1])
      end
    }
    return subject_tile if candidates.empty? # 移動なし
    return candidates[0][2]
  end
  def battler_exists?(x, y)
    for m in @actor_sprites
      next if m.battler.dead?
      return true if m.character.x == x && m.character.y == y
    end
    for m in @enemy_sprites
      next if m.battler.dead?
      return true if m.character.x == x && m.character.y == y
    end
    return false
  end
end

class Game_BattleFieldTile
  MOVE_COLOR = Color.new(100, 100, 100, 100)
  ATTACK_COLOR = Color.new(255, 100, 100, 100)
  attr_accessor :x
  attr_accessor :y
  attr_accessor :cx
  attr_accessor :cy
  attr_accessor :selected
  def initialize(x, y)
    @x = x
    @y = y
    @cx = @x * 32 + 16
    @cy = @y * 32 + 16
    @selected = false
  end
  def in_range?(x, y, rr)
    return distance(x, y) <= rr
  end
  def distance(x, y)
    return (x - @cx) ** 2 + (y - @cy) ** 2
  end
  def clear
    @selected = false
  end
end


class Game_Actor
  def use_sprite
    return true
  end

end

class Game_Piece < Game_Character
  attr_accessor :battler
  attr_accessor :x
  attr_accessor :y
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(battler)
    
    @battler = battler
    super()
    @tile_id  = 0
    if battler.actor?
      @character_name = battler.character_name
      @character_index = battler.character_index
    else
      @character_name = enemy_graphic_name
      @character_index = enemy_graphic_index
    end

    @x = rand(10)+5
    @y = rand(8)
    @real_x = @x
    @real_y = @y

    @speed_x = 0
    @speed_y = 0
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
  #--------------------------------------------------------------------------
  # ● 画面 X 座標の取得
  #--------------------------------------------------------------------------
  def screen_x
    (@real_x) * 32 + 16 + 32
  end
  #--------------------------------------------------------------------------
  # ● 画面 Y 座標の取得

  #--------------------------------------------------------------------------
  def screen_y
    (@real_y) * 32 + 32 + 32
  end
  #--------------------------------------------------------------------------
  # ● 移動時の更新
  #--------------------------------------------------------------------------
  def update_move
    if @real_x == @x && @real_y == @y
      @speed_x = 0
      @speed_y = 0
    end
    if @speed_x == 0
      calc_speed
      calc_direction
    end
    @real_x = [@real_x - @speed_x, @x].max if @x < @real_x
    @real_x = [@real_x + @speed_x, @x].min if @x > @real_x
    @real_y = [@real_y - @speed_y, @y].max if @y < @real_y
    @real_y = [@real_y + @speed_y, @y].min if @y > @real_y
    update_bush_depth unless moving?
  end
  def calc_speed
    dist_x = (@x - @real_x).abs
    dist_y = (@y - @real_y).abs
    if dist_x == 0
      @speed_x = 0
      @speed_y = distance_per_frame
      return 
    elsif dist_y == 0
      @speed_x = distance_per_frame
      @speed_y = 0
      return 
    end
    if dist_x > dist_y
      @speed_x = distance_per_frame
      @speed_y = distance_per_frame * dist_y / dist_x
    else
      @speed_x = distance_per_frame * dist_x / dist_y
      @speed_y = distance_per_frame
    end
  end
  def calc_direction
    dist_x = (@x - @real_x).abs
    dist_y = (@y - @real_y).abs
    if dist_x == 0 || dist_y > dist_x
      if @y < @real_y 
        set_direction(8)
      else
        set_direction(2)
      end
    else
      if @x < @real_x
        set_direction(4)
      else
        set_direction(6)
      end

    end
    
  end
end

#==============================================================================
# ■ Sprite_BattlerPiece
#------------------------------------------------------------------------------
# 　駒をあらわすクラスです
#==============================================================================

class Sprite_BattlerPiece < Sprite_Character
  include Saba::Kiseki
  ARGET_ENEMY_COLOR = Color.new(255, 0, 0, 155)
  TARGET_ACTOR_COLOR = Color.new(0, 0, 255, 155)
  attr_accessor :selected
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(viewport, battler)
    @battler = battler
    @character = Game_Piece.new(battler)
    super(viewport, character)
    
    self.z = 3
  end
  def battler
    return @character.battler
  end
  def update
    if @battler.dead?
      self.visible = false
      return
    end
    @character.update
    @character.update
    super
  end
  def effect?
    return false
  end
  def selected=(b)
    if b
      self.color = ARGET_ENEMY_COLOR
    else
      self.color = Color.new(0, 0, 0, 0)
    end
  end
end