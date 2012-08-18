#==============================================================================
# ■ ダンジョン生成7_2
#   @version 0.14 12/05/05 RGSS3
#   @author さば缶
#------------------------------------------------------------------------------
# 　
#==============================================================================
module Saba
  module Dungeon
    PLAYER_COLOR_ID = 9     # ミニマップのプレイヤーの色 ID
    FOLLOWER_COLOR_ID = 1   # ミニマップのフォロワーの色 ID
  end
end

class << DataManager
  #--------------------------------------------------------------------------
  # ● 各種ゲームオブジェクトの作成
  #--------------------------------------------------------------------------
  alias saba_minimap_create_game_objects create_game_objects
  def create_game_objects
    saba_minimap_create_game_objects
    $game_minimap = Game_MiniMap.new
  end
  #--------------------------------------------------------------------------
  # ● セーブ内容の作成
  #--------------------------------------------------------------------------
  alias saba_minimap_make_save_contents make_save_contents
  def make_save_contents
    contents = saba_minimap_make_save_contents
    contents[:minimap] = $game_minimap
    contents
  end
  #--------------------------------------------------------------------------
  # ● セーブ内容の展開
  #--------------------------------------------------------------------------
  alias saba_minimap_extract_save_contents extract_save_contents
  def extract_save_contents(contents)
    saba_minimap_extract_save_contents(contents)
    $game_minimap        = contents[:minimap]
  end
end

class Game_Map
  #--------------------------------------------------------------------------
  # ● セットアップ
  #     map_id : マップ ID
  #--------------------------------------------------------------------------
  alias saba_minmap_setup setup
  def setup(map_id)
    saba_minmap_setup(map_id)
    if dungeon?
      $game_minimap.setup(self) 
    end
  end
  #--------------------------------------------------------------------------
  # ● 指定の座標をマッピング
  #--------------------------------------------------------------------------
  def mapping(x, y)
    return unless floor?(x, y)
    for rect in @rect_list
      if rect.room.contains(x, y)
        $game_player.room = rect.room
        $game_minimap.mapping_room(rect.room)
        return
      end
    end
    $game_player.room = nil
    $game_minimap.mapping(x, y)
  end
end

class Game_MiniMap
  BLANK = 0   # 空きマップ
  FLOOR = 1   # 床
  WALL  = 2   # 壁
  PASSAGE = 3 # 通路
  attr_accessor :changed_area
  attr_accessor :cleared
  attr_reader :events
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    @map_data = {}
    @events = []
  end
  #--------------------------------------------------------------------------
  # ● マップ情報を初期化
  #--------------------------------------------------------------------------
  def setup(map)
    clear
    for x in 0..map.width
      for y in 0..map.height
        @map_data[[x, y]] = BLANK
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● マッピングされているか？
  #--------------------------------------------------------------------------
  def mapping?(x, y)
    return @map_data[[x, y]] != BLANK
  end
  def floor_type(x, y)
    return @map_data[[x, y]]
  end
  #--------------------------------------------------------------------------
  # ● 部屋をマッピング
  #--------------------------------------------------------------------------
  def mapping_room(room)
    return if room.mapping
    room.mapping = true
    for x in room.lx...room.hx
      for y in room.ly...room.hy
        @map_data[[x, y]] = FLOOR
      end
    end
    mapping_edge(room)
    @changed_area = Rect.new(room.lx-1, room.ly-1, room.width+1, room.height+1)
  end
  #--------------------------------------------------------------------------
  # ● 部屋の外側をマッピング
  #--------------------------------------------------------------------------
  def mapping_edge(room)
    for x in (room.lx-1)...(room.hx+1)
      mapping_internal(x, room.ly-1)
      mapping_internal(x, room.hy)
    end
    for y in (room.ly)...(room.hy)
      mapping_internal(room.lx-1, y)
      mapping_internal(room.hx, y)
    end
  end
  #--------------------------------------------------------------------------
  # ● 道をマッピング
  #--------------------------------------------------------------------------
  def mapping(x, y)
    mapping_internal(x, y)
    mapping_internal(x-1, y)
    mapping_internal(x+1, y)
    mapping_internal(x, y-1)
    mapping_internal(x, y+1)
    mapping_internal(x-1, y-1)
    mapping_internal(x+1, y-1)
    mapping_internal(x-1, y+1)
    mapping_internal(x+1, y+1)
    @changed_area = Rect.new(x-1, y-1, 3, 3)
  end
  #--------------------------------------------------------------------------
  # ● 道をマッピング
  #--------------------------------------------------------------------------
  def mapping_internal(x, y)
    return if mapping?(x, y)
    if $game_map.floor?(x, y)
      @map_data[[x, y]] = PASSAGE
    else
      @map_data[[x, y]] = WALL
    end
  end
  def add_event(event)
    @events.push(event)
  end
  #--------------------------------------------------------------------------
  # ● クリア
  #--------------------------------------------------------------------------
  def clear
    @cleared = true
    @map_data = {}
    @events = []
  end
end

class Game_Player
  attr_accessor :room
  #--------------------------------------------------------------------------
  # ● 指定位置に移動
  #--------------------------------------------------------------------------
  alias saba_minimap_moveto moveto
  def moveto(x, y)
    saba_minimap_moveto(x, y)
    $game_map.mapping(x, y)
  end
  #--------------------------------------------------------------------------
  # ● 歩数増加
  #--------------------------------------------------------------------------
  alias saba_minimap_increase_steps increase_steps
  def increase_steps
    saba_minimap_increase_steps
    $game_map.mapping(self.x, self.y)
  end
end


class Sprite_MiniMap < Sprite_Base
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  SQUARE_SIZE = 5 
  FLOOR_COLOR   = Color.new(70, 70, 180, 170)
  PASSAGE_COLOR = Color.new(160, 80, 160, 170)
  WALL_COLOR    = Color.new(200, 200, 200, 0)
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     viewport  : ビューポート
  #--------------------------------------------------------------------------
  def initialize(viewport)
    super(viewport)
    @windowskin = Cache.system("Window")
    @event_sprites = {}
    create_bitmap
    update_position
    redraw_all
    @follower_sprites = {}
    if $game_player.followers.visible
      for follower in $game_player.followers
        @follower_sprites[follower] = create_character_sprite(Saba::Dungeon::FOLLOWER_COLOR_ID)
      end
    end
    @player_sprite = create_character_sprite(Saba::Dungeon::PLAYER_COLOR_ID)
    
    update
  end
  #--------------------------------------------------------------------------
  # ● 文字色取得
  #     n : 文字色番号（0..31）
  #--------------------------------------------------------------------------
  def text_color(n)
    @windowskin.get_pixel(64 + (n % 8) * 8, 96 + (n / 8) * 8)
  end
  #--------------------------------------------------------------------------
  # ● キャラクター用ビットマップの作成
  #--------------------------------------------------------------------------
  def create_character_sprite(color)
    if color >= 1000
      hole = true
      color -= 1000
    end
    if color >= 100
      static = true
      color -= 100
    end
    
    sprite_color = text_color(color) if color != 0
    return Sprite_MiniMap_Character.new(viewport, sprite_color, static, hole)
  end
  #--------------------------------------------------------------------------
  # ● ビットマップの作成
  #--------------------------------------------------------------------------
  def create_bitmap
    self.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    self.bitmap.font.size = 32
    self.bitmap.font.color.set(255, 255, 255)
  end
  #--------------------------------------------------------------------------
  # ● 座標の更新
  #--------------------------------------------------------------------------
  def update_position
    self.x = (Graphics.width - SQUARE_SIZE * $game_map.width) / 2
    self.y = (Graphics.height - SQUARE_SIZE * $game_map.height) / 2
  end
  #--------------------------------------------------------------------------
  # ● 転送元ビットマップの更新
  #--------------------------------------------------------------------------
  def update_bitmap
    rect = $game_minimap.changed_area
    return unless rect
    $game_minimap.changed_area = nil
    for x in rect.x..(rect.width + rect.x)
      for y in rect.y..(rect.height + rect.y)
        case $game_minimap.floor_type(x, y)
        when Game_MiniMap::FLOOR then
          color = FLOOR_COLOR
        when Game_MiniMap::WALL then
          color = WALL_COLOR
        when Game_MiniMap::PASSAGE then
          color = PASSAGE_COLOR
        else
          next
        end
        self.bitmap.fill_rect(x*SQUARE_SIZE, y*SQUARE_SIZE, SQUARE_SIZE, SQUARE_SIZE, color)
      end
    end
  end

  def redraw_all
    self.bitmap.clear
    for x in 0..$game_map.width
      for y in 0..$game_map.height
        case $game_minimap.floor_type(x, y)
        when Game_MiniMap::FLOOR then
          color = FLOOR_COLOR
        when Game_MiniMap::PASSAGE then
          color = PASSAGE_COLOR
        when Game_MiniMap::WALL then
          color = WALL_COLOR
        else
          next
        end
        self.bitmap.fill_rect(x*SQUARE_SIZE, y*SQUARE_SIZE, SQUARE_SIZE, SQUARE_SIZE, color)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    clear if $game_minimap.cleared
    update_bitmap if $game_minimap.changed_area
    update_visibility
    update_player
    update_events
  end
  #--------------------------------------------------------------------------
  # ● 可視状態の更新
  #--------------------------------------------------------------------------
  def update_visibility
    #self.visible = $game_timer.working?
  end
  #--------------------------------------------------------------------------
  # ● プレイヤーの更新
  #--------------------------------------------------------------------------
  def update_player
    @player_sprite.x = self.x + $game_player.x * SQUARE_SIZE
    @player_sprite.y = self.y + $game_player.y * SQUARE_SIZE
    
    return unless $game_player.followers.visible
    for follower in $game_player.followers
      sprite = @follower_sprites[follower] 
      next unless sprite
      sprite.x = self.x + follower.x * SQUARE_SIZE
      sprite.y = self.y + follower.y * SQUARE_SIZE
    end
  end
  #--------------------------------------------------------------------------
  # ● 全イベントの更新
  #--------------------------------------------------------------------------
  def update_events
    for event in $game_map.events.values
      if event.erased
        sprite = @event_sprites[event.event_id]
        if sprite
          sprite.dispose
          @event_sprites.delete(event.event_id)
        end
        $game_map.events.delete(event.event_id)
        next
      end
      update_event(event)
    end
  end
  #--------------------------------------------------------------------------
  # ● イベントの更新
  #--------------------------------------------------------------------------
  def update_event(event)
    if @event_sprites[event.event_id]
      sprite = @event_sprites[event.event_id]
    else
      sprite = create_character_sprite(event.name.to_i)
      @event_sprites[event.event_id] = sprite
    end
    if sprite.static
      sprite.visible = $game_minimap.mapping?(event.x, event.y)
    else
      sprite.visible = false
      if $game_player.room
        sprite.visible = $game_player.room.contains(event.x, event.y)
      end
      sprite.visible |= $game_player.distance(event) == 1
      sprite.visible = true if Saba::Dungeon::DEBUG_MODE
    end
    sprite.x = self.x + event.x * SQUARE_SIZE
    sprite.y = self.y + event.y * SQUARE_SIZE
  end
  def next_enemy_sprite
    unless @spare_enemy_sprites.empty?
      return @spare_enemy_sprites.pop
    else
      return create_character_sprite(true)
    end
  end
  #--------------------------------------------------------------------------
  # ● クリア
  #--------------------------------------------------------------------------
  def clear
    self.bitmap.clear
    update_position
    @event_sprites.values.each {|s| s.dispose }
    @event_sprites = {}
    $game_minimap.cleared = false
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    @player_sprite.bitmap.dispose
    @player_sprite.dispose
    for sprite in @event_sprites.values
      sprite.dispose
    end
    for sprite in @follower_sprites.values
      sprite.dispose
    end
    super
  end
  def visible=(value)
    return if visible == value
    super
    @player_sprite.visible = value
    for sprite in @follower_sprites.values
      sprite.visible = value
    end
    for sprite in @event_sprites.values
      sprite.visible = value
    end
  end
end

class Sprite_MiniMap_Character < Sprite_Base
  attr_reader :static
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     viewport  : ビューポート
  #--------------------------------------------------------------------------
  def initialize(viewport, color, static, hole)
    super(viewport)
    @alive = true
    @color = color
    @static = static
    @hole = hole
    if @color
    
      create_bitmap
      update
    else   
      self.visible = false
   
    end
  end
  #--------------------------------------------------------------------------
  # ● ビットマップの作成
  #--------------------------------------------------------------------------
  def create_bitmap
    size = Sprite_MiniMap::SQUARE_SIZE
    self.bitmap = Bitmap.new(size, size)
    if @hole
      self.bitmap.fill_rect(0, 0, size, 1, @color)
      self.bitmap.fill_rect(0, size-1, size, 1, @color)
      self.bitmap.fill_rect(0, 1, 1, size-2, @color)
      self.bitmap.fill_rect(size-1, 1, 1, size-2, @color)
    else
      self.bitmap.fill_rect(0, 0, size, size, @color)
    end
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose if self.bitmap
    super
  end
end

class Spriteset_Map
  attr_reader :character_sprites
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  alias saba_minimap_initialize initialize
  def initialize
    saba_minimap_initialize
    
    @mini_map = Sprite_MiniMap.new(@viewport2)
    if $game_map.dungeon?
      update
    else
      @mini_map.visible = false
    end
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  alias saba_minimap_dispose dispose
  def dispose
    saba_minimap_dispose
    @mini_map.dispose if @mini_map
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  alias saba_minimap_update update
  def update
    saba_minimap_update
    return unless @mini_map
    if $game_map.dungeon?
      @mini_map.visible = true
      @mini_map.update
    else
      @mini_map.visible = false
    end
  end
  #--------------------------------------------------------------------------
  # ● クリア
  #--------------------------------------------------------------------------
  def clear_minimap
    @mini_map.clear
  end
end