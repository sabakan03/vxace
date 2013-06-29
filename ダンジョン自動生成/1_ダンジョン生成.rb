#==============================================================================
# ■ ダンジョン生成12
#   @version 0.19 12/10/09 RGSS3
#   @author さば缶
#------------------------------------------------------------------------------
# 　
#==============================================================================
module Saba
  module Dungeon
    # 区画の最小サイズ
    MINIMUM_RECT_SIZE = 7
    
    # 部屋の最小サイズ
    MINIMUM_ROOM_SIZE = 3
    
    # 区画と部屋の最小マージン
    MARGIN_BETWEEN_RECT_ROOM = 2
    
    # 追加の道が作られる割合。この数字分の1
    # 小さいほどよく作られる
    MORE_COUPLE_RATE = 35
    
    # 敵の数が含まれる変数
    ENEMY_COUNT_VARIABLE = 141
    
    # デバッグモード
    # ・敵が常にミニマップに表示されます
    DEBUG_MODE = false
  end
end

#==============================================================================
# ■ Dungeon_Rect
#------------------------------------------------------------------------------
# 　ダンジョンを区切った領域を表します。
#　各 Dungeon_Rect に一つづつ Room が存在します。
#==============================================================================
class Dungeon_Rect
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :lx
  attr_accessor :ly
  attr_accessor :hx
  attr_accessor :hy
  attr_accessor :room
  attr_accessor :done_split_v
  attr_accessor :done_split_h
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(lx, ly, hx, hy)
    self.lx = lx
    self.ly = ly
    self.hx = hx
    self.hy = hy
    self.done_split_v = false
    self.done_split_h = false
  end
end

#==============================================================================
# ■ Room
#------------------------------------------------------------------------------
# 　部屋です。
#==============================================================================
class Room
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :lx
  attr_accessor :ly
  attr_accessor :hx
  attr_accessor :hy
  attr_accessor :mapping
  attr_reader :width
  attr_reader :height
  attr_reader :couple_areas  # 通路に面している[x, y]のリスト
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(lx, ly, hx, hy)
    self.lx = lx
    self.ly = ly
    self.hx = hx
    self.hy = hy
    @width = hx - lx
    @height = hy - ly
    @events = {}
    @couple_areas = []
    @mapping = false
  end
  #--------------------------------------------------------------------------
  # ● イベント配置可能数残りを取得
  #--------------------------------------------------------------------------
  def remain
    return (hx - lx) * (hy - ly) -  @events.size - @couple_areas.size
  end
  #--------------------------------------------------------------------------
  # ● 指定のイベントをこの部屋のランダムな場所に配置
  #--------------------------------------------------------------------------
  def put_to_random_place(event)
    begin
      key = [rand(hx - lx) + lx, rand(hy - ly) + ly]
    end while @events[key] != nil || @couple_areas.include?(key)
    @events[key] = event
    event.moveto(key[0], key[1])
  end
  #--------------------------------------------------------------------------
  # ● 指定の座標を含んでいるかを取得
  #--------------------------------------------------------------------------
  def contains(x, y)
    return lx <= x && x < hx && ly <= y && y < hy
  end
  #--------------------------------------------------------------------------
  # ● 指定の座標を明るくするかを取得
  #--------------------------------------------------------------------------
  def right_area?(x, y)
    return lx-1 <= x && x < hx+1 && ly-1 <= y && y < hy+1
  end
end




#==============================================================================
# ■ Couple
#------------------------------------------------------------------------------
# 　通路です。
#==============================================================================
class Couple
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :rect0
  attr_accessor :rect1
  attr_accessor :direction
end

class Game_Map
  attr_reader :map
  attr_accessor :new_events
  attr_accessor :map_infos
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  COUPLE_VERTICAL = 0
  COUPLE_HORIZONAL = 1
  #--------------------------------------------------------------------------
  # ● セットアップ
  #     map_id : マップ ID
  #--------------------------------------------------------------------------
  alias saba_setup setup
  def setup(map_id)
    saba_setup(map_id)
    @random_dungeon = nil
    make_random_dungeon if dungeon?
  end
  #--------------------------------------------------------------------------
  # ● ランダムダンジョンを作成
  #--------------------------------------------------------------------------
  def make_random_dungeon
    @rect_list = []
    @room_list = []
    @couple_list = []
    @map = load_data(sprintf("Data/Map%03d.rvdata2", @map_id))
    @floor_chip_id = @map.data[0, 0, 0]
    @floor_chip_id1 = @map.data[1, 0, 0]
    @edge_chip_id = @map.data[0, 1, 0]
    @wall_chip_id = @map.data[0, 2, 0]
    @blank_chip_id = @map.data[0, 4, 0]
    @object_chip_id0 = @map.data[0, 3, 0]
    @object_chip_id1 = @map.data[0, 3, 1]
    @object_chip_id2 = @map.data[0, 3, 2]
    make_rect
    make_room
    make_couple_more
    
    @init_phase = true
    
    put_blank_tiles
    put_couple_tiles
    put_room_tiles
    put_shadow
    put_wall_tiles
    put_edge_tiles
    
    setup_dungeon_events
    @random_data = @map.data
    @last_moving = false
    
  end
  #--------------------------------------------------------------------------
  # ● 区切りを作成
  #--------------------------------------------------------------------------
  def make_rect
    split_rect(add_rect(0, 1, @map.width, @map.height))
  end
  #--------------------------------------------------------------------------
  # ● 指定の DungeonRect を区切る
  #--------------------------------------------------------------------------
  def split_rect(parent)
    if (parent.hy - parent.ly <= Saba::Dungeon::MINIMUM_RECT_SIZE * 2) 
      parent.done_split_v = true
    end
    if (parent.hx - parent.lx <= Saba::Dungeon::MINIMUM_RECT_SIZE * 2) 
      parent.done_split_h = true;
    end
    if ((parent.done_split_v) &&  (parent.done_split_h))
      return
    end
    child = add_rect(parent.lx, parent.ly, parent.hx, parent.hy)
    unless parent.done_split_v
      split_coord_y = random_range(parent.ly + Saba::Dungeon::MINIMUM_RECT_SIZE, parent.hy - Saba::Dungeon::MINIMUM_RECT_SIZE)
      parent.hy = split_coord_y
      child.ly = split_coord_y
      parent.done_split_v = true
      child.done_split_v = true
      add_couple(COUPLE_VERTICAL, parent, child)
      split_rect(parent)
      split_rect(child)
    else
      split_coord_x = random_range(parent.lx + Saba::Dungeon::MINIMUM_RECT_SIZE, parent.hx - Saba::Dungeon::MINIMUM_RECT_SIZE)
      parent.hx = split_coord_x
      child.lx = split_coord_x
      parent.done_split_h = true
      child.done_split_h = true
      add_couple(COUPLE_HORIZONAL, parent, child)
      split_rect(parent)
      split_rect(child)
    end
  end
  #--------------------------------------------------------------------------
  # ● さらに道を作成
  #--------------------------------------------------------------------------
  def make_couple_more
    rectmap = {}
    for rect in @rect_list
      for i in rect.lx...rect.hx
        for j in rect.ly...rect.hy
          rectmap[[i, j]] = rect
        end
      end
    end
  
    for i in 0..(@map.width-2)
      for j in 1..(@map.height-2)
        if rectmap[[i, j]] != rectmap[[i, j + 1]]
          if rand(Saba::Dungeon::MORE_COUPLE_RATE) == 0
            add_couple(COUPLE_VERTICAL, rectmap[[i,j]], rectmap[[i, j + 1]])
          end
        end
        if rectmap[[i, j]] != rectmap[[i + 1, j]]
          if rand(Saba::Dungeon::MORE_COUPLE_RATE) == 0
            add_couple(COUPLE_HORIZONAL, rectmap[[i, j]], rectmap[[i + 1, j]])
          end
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● ランダムダンジョンか？
  #--------------------------------------------------------------------------
  def dungeon?
    if @random_dungeon != nil
      return @random_dungeon
    end
    @random_dungeon = @map_infos[@map_id].name.include?("@")
    return @random_dungeon
  end
  #--------------------------------------------------------------------------
  # ● 指定の区間の中でランダムな値を取得
  #--------------------------------------------------------------------------
  def random_range(b, e)
    return (rand(e - b) + b).to_i
  end
  #--------------------------------------------------------------------------
  # ● DungeonRect を作成して追加
  #--------------------------------------------------------------------------
  def add_rect(lx, ly, hx, hy)
    rect = Dungeon_Rect.new(lx, ly, hx, hy)
    @rect_list.push(rect)
    return rect
  end
  #--------------------------------------------------------------------------
  # ● Room を作成して追加
  #--------------------------------------------------------------------------
  def add_room(lx, ly, hx, hy)
    room = Room.new(lx, ly, hx, hy)
    @room_list.push(room)
    return room
  end
  #--------------------------------------------------------------------------
  # ● 部屋を作成
  #--------------------------------------------------------------------------
  def make_room
    for rect in @rect_list
      w = random_range(Saba::Dungeon::MINIMUM_ROOM_SIZE, rect.hx - rect.lx - (Saba::Dungeon::MARGIN_BETWEEN_RECT_ROOM * 2) + 1);
      h = random_range(Saba::Dungeon::MINIMUM_ROOM_SIZE, rect.hy - rect.ly - (Saba::Dungeon::MARGIN_BETWEEN_RECT_ROOM * 2) + 1);
      x = random_range(rect.lx + Saba::Dungeon::MARGIN_BETWEEN_RECT_ROOM, rect.hx - Saba::Dungeon::MARGIN_BETWEEN_RECT_ROOM - w + 1);
      y = random_range(rect.ly + Saba::Dungeon::MARGIN_BETWEEN_RECT_ROOM, rect.hy - Saba::Dungeon::MARGIN_BETWEEN_RECT_ROOM - h + 1);
      rect.room = add_room(x, y, x + w, y + h);
    end
  end
  #--------------------------------------------------------------------------
  # ● 通路 を作成して追加
  #--------------------------------------------------------------------------
  def add_couple(direction, rect0, rect1)
    @couple_list.each {|c|
      if (c.rect0 == rect0 && c.rect1 == rect1) ||
         (c.rect0 == rect1 && c.rect1 == rect0)
        # 重複はつくらない
        return
      end
    }
    couple = Couple.new
    couple.direction = direction
    couple.rect0 = rect0
    couple.rect1 = rect1
    @couple_list.push(couple)
    return couple
  end
  #--------------------------------------------------------------------------
  # ● 空きチップを配置
  #--------------------------------------------------------------------------
  def put_blank_tiles
    for x in 0..@map.width
      for y in 0..@map.height
        @map.data[x, y, 0] = @blank_chip_id
        @map.data[x, y, 1] = 0
        @map.data[x, y, 2] = 0
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 床チップを配置
  #--------------------------------------------------------------------------
  def put_room_tiles
    for rect in @rect_list
      room = rect.room
      (room.hx - room.lx).times do |x|
        (room.hy - room.ly).times do |y|
          put_floor_tile(x + room.lx, y + room.ly)
        end
      end
    end
  end
  def put_floor_tile(x, y)
    if @floor_chip_id1 > 0 && rand(10) == 0
      @map.data[x, y, 0] = @floor_chip_id1
    else
      @map.data[x, y, 0] = @floor_chip_id
    end
  end
  #--------------------------------------------------------------------------
  # ● 通路チップを配置
  #--------------------------------------------------------------------------
  def put_couple_tiles
    for couple in @couple_list
      case couple.direction
      when COUPLE_HORIZONAL then
        unless couple.rect0.hx == couple.rect1.lx 
          p "Errorx:" + couple.rect0.hx.to_s + couple.rect1.lx .to_s
          next
        end
        c0x = couple.rect0.hx
        c0y = random_range(couple.rect0.room.ly + 1, couple.rect0.room.hy)
        c1x = couple.rect1.lx
        c1y = random_range(couple.rect1.room.ly + 1, couple.rect1.room.hy)
        line(c0x, c0y, c1x, c1y);
        line(couple.rect0.room.hx, c0y, c0x, c0y)
        line(couple.rect1.room.lx, c1y, c1x, c1y)
        couple.rect0.room.couple_areas.push([couple.rect0.room.hx-1, c0y])
        couple.rect1.room.couple_areas.push([couple.rect1.room.lx, c1y])
      when COUPLE_VERTICAL then
        unless couple.rect0.hy == couple.rect1.ly
          p "Errory:" + couple.rect0.hy.to_s + " " + couple.rect1.ly .to_s
          next
        end
        c0x = random_range(couple.rect0.room.lx + 1, couple.rect0.room.hx)
        c0y = couple.rect0.hy
        c1x = random_range(couple.rect1.room.lx + 1, couple.rect1.room.hx)
        c1y = couple.rect1.ly
        line(c0x, c0y, c1x, c1y)
        line(c0x, couple.rect0.room.hy, c0x, c0y)
        line(c1x, couple.rect1.room.ly, c1x, c1y)
        couple.rect0.room.couple_areas.push([c0x, couple.rect0.room.hy-1])
        couple.rect1.room.couple_areas.push([c1x, couple.rect1.room.ly])
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 指定の座標間で床を配置
  #--------------------------------------------------------------------------
  def line(x0, y0, x1, y1)
    min_x = [x0, x1].min
    max_x = [x0, x1].max
    min_y = [y0, y1].min
    max_y = [y0, y1].max
    if ((x0 <= x1) && (y0 >= y1))
      for i in min_x..max_x
        put_floor_tile(i, max_y)
      end
      for j in min_y..max_y
        put_floor_tile(max_x, j)
      end
    elsif ((x0 > x1) && (y0 > y1))
      for i in min_x..max_x
        put_floor_tile(i, min_y)
      end
      for j in min_y..max_y
        put_floor_tile(max_x, j)
      end
    elsif ((x0 > x1) && (y0 <= y1))
      for i in min_x..max_x
        put_floor_tile(i, min_y)
      end
      for j in min_y..max_y
        put_floor_tile(max_x, j)
      end
    elsif ((x0 <= x1) && (y0 < y1))
      for i in min_x..max_x
        put_floor_tile(i, max_y)
      end
      for j in min_y..max_y
        put_floor_tile(min_x, j)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 壁チップを配置
  #--------------------------------------------------------------------------
  def put_wall_tiles
    for y in (1..@map.height).to_a.reverse
      for x in 0..@map.width
        next unless  floor?(x, y)
        next if floor?(x, y-1)
        @map.data[x, y-1, 0] = @wall_chip_id + 15
      end
    end
    
    for y in (1..@map.height).to_a.reverse
      for x in 0..@map.width
        tile = @map.data[x, y, 0]
        next unless tile ==  @wall_chip_id + 15
        if floor?(x, y-1)
          put_object_tile(x, y)
          next
        end
        if floor?(x-1, y) || blank?(x-1, y)
          if floor?(x+1, y) || blank?(x+1, y)
            @map.data[x, y, 0] = @wall_chip_id + 15
          else
            @map.data[x, y, 0] = @wall_chip_id + 11
          end
        else
          if floor?(x+1, y) || blank?(x+1, y)
            @map.data[x, y, 0] = @wall_chip_id + 14
          else
            @map.data[x, y, 0] = @wall_chip_id + 10
          end
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 障害物チップを配置
  #--------------------------------------------------------------------------
  def put_object_tile(x, y)
    @map.data[x, y, 0] = @object_chip_id0
    @map.data[x, y, 1] = @object_chip_id1
    @map.data[x, y, 2] = @object_chip_id2
  end
  #--------------------------------------------------------------------------
  # ● 境界チップを配置
  #--------------------------------------------------------------------------
  def put_edge_tiles
    for y in (1..@map.height).to_a.reverse
      for x in 0..@map.width
        tile = @map.data[x, y, 0]
        next if inner?(x, y)
        if inner?(x, y-1)
          if inner?(x, y+1)
            if inner?(x-1, y)
              if inner?(x+1, y)
                @map.data[x, y, 0] = @edge_chip_id + 46
              else
                @map.data[x, y, 0] = @edge_chip_id + 43
              end
            else
              if inner?(x+1, y)
                @map.data[x, y, 0] = @edge_chip_id + 45
              else
                @map.data[x, y, 0] = @edge_chip_id + 33
              end
            end
          else
            if inner?(x-1, y)
              if inner?(x+1, y)
                @map.data[x, y, 0] = @edge_chip_id + 42
              else
                @map.data[x, y, 0] = @edge_chip_id + 34
              end
            else
              if inner?(x+1, y)
                @map.data[x, y, 0] = @edge_chip_id + 36
              else
                @map.data[x, y, 0] = @edge_chip_id + 20
              end
            end
          end
        else
          if inner?(x, y+1)
            if inner?(x-1, y)
              if inner?(x+1, y)
                @map.data[x, y, 0] = @edge_chip_id + 44
              else
                @map.data[x, y, 0] = @edge_chip_id + 40
              end
            else
              if inner?(x+1, y)
                @map.data[x, y, 0] = @edge_chip_id + 38
              else
                @map.data[x, y, 0] = @edge_chip_id + 28
              end
            end
          else
            if inner?(x-1, y)
              if inner?(x+1, y)
                @map.data[x, y, 0] = @edge_chip_id + 32
              else
                @map.data[x, y, 0] = @edge_chip_id + 16
              end
            else
              if inner?(x+1, y)
                @map.data[x, y, 0] = @edge_chip_id + 24
              else
                if inner?(x+1, y+1) || inner?(x+1, y-1) ||
                   inner?(x-1, y-1) || inner?(x-1, y+1)
                  @map.data[x, y, 0] = @edge_chip_id
                else
                  @map.data[x, y, 0] = @blank_chip_id
                end
              end
            end
          end
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 影タイルを置きます
  #--------------------------------------------------------------------------
  def put_shadow
    for y in 0..@map.height
      for x in 0..@map.width
        next unless floor?(x, y)
        next if floor?(x-1, y-1)
        next unless blank?(x-1, y)
        @map.data[x, y, 3] = 5
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 指定の座標が境界の内側かどうか
  #--------------------------------------------------------------------------
  def inner?(x, y)
    return floor?(x, y) || wall?(x, y) || object?(x, y)
  end
  #--------------------------------------------------------------------------
  # ● 指定の座標が床かどうか
  #--------------------------------------------------------------------------
  def floor?(x, y)
    return false if @map.data[x, y, 2] == @object_chip_id2
    return true if @floor_chip_id1 && @map.data[x, y, 0] == @floor_chip_id1
    return @map.data[x, y, 0] == @floor_chip_id
  end
  #--------------------------------------------------------------------------
  # ● 指定の座標がカラかどうか
  #--------------------------------------------------------------------------
  def blank?(x, y)
    return @map.data[x, y, 0] == @blank_chip_id
  end
  #--------------------------------------------------------------------------
  # ● 指定の座標が障害物かどうか
  #--------------------------------------------------------------------------
  def object?(x, y)
    return @map.data[x, y, 0] == @object_chip_id0
  end
  #--------------------------------------------------------------------------
  # ● 指定の座標が壁かどうか
  #--------------------------------------------------------------------------
  def wall?(x, y)
    tile = @map.data[x, y, 0]
    return false if tile == nil || tile == 0
    return tile >= @wall_chip_id && tile <= @wall_chip_id + 15
  end
  #--------------------------------------------------------------------------
  # ● プレイヤーをランダムな位置に配置
  #--------------------------------------------------------------------------
  def setup_player_initial_position
    put_to_random_place($game_player) unless floor?($game_player.x, $game_player.y)
  end
  #--------------------------------------------------------------------------
  # ● ダンジョンの特殊なイベントをランダムな場所に配置する
  #--------------------------------------------------------------------------
  def setup_dungeon_events
    @next_enemy_event_id = 10000
    @enemy_events = []
    
    for event in @events.values
      if event.event.name.include?("*")
        @enemy_events.push(event.event)
        self.events[event.id].erase
      else
        put_to_random_place(event)
      end
    end
    setup_enemy
  end
  #--------------------------------------------------------------------------
  # ● 敵イベントの初期設定
  #--------------------------------------------------------------------------
  def setup_enemy
    $game_variables[Saba::Dungeon::ENEMY_COUNT_VARIABLE] = 0
    return if @enemy_events.count == 0
    @map.encounter_step.times do |i|
      add_random_enemy
    end
  end
  #--------------------------------------------------------------------------
  # ● ランダムな敵イベントをランダムな場所に配置する
  #--------------------------------------------------------------------------
  def add_random_enemy
    add_enemy(rand(@enemy_events.count))
  end
  #--------------------------------------------------------------------------
  # ● 指定の敵イベントを複製してランダムな場所に配置する
  #--------------------------------------------------------------------------
  def add_enemy(event_id)
    enemy_event = @enemy_events[event_id]
    event = Game_Event.new(@map_id, enemy_event)
    
    # イベントのループ内では新しいイベントを追加できないので、
    # 一旦別の場所に格納
    @new_events = {} unless @new_events
    @new_events[@next_enemy_event_id] = event
    
    event.event_id = @next_enemy_event_id
    @next_enemy_event_id += 1
    $game_variables[Saba::Dungeon::ENEMY_COUNT_VARIABLE] += 1
  end
  alias saba_randomdungeon_update_events update_events
  def update_events
    saba_randomdungeon_update_events
    if @new_events
      for key in @new_events.keys
        @events[key] = @new_events[key]
        put_to_random_place(@events[key])
        $game_minimap.add_event(@events[key]) if $game_minimap
      end
    end
    @init_phase = false
  end
  #--------------------------------------------------------------------------
  # ● 指定のイベントをランダムな場所に配置する
  #--------------------------------------------------------------------------
  def put_to_random_place(event)
    if @init_phase
      room_list = @room_list.select {|room| room.remain != 0 }
    else 
      room_list = @room_list.select {|room| room.remain != 0 && room != $game_player.room }
    end
    room = room_list[rand(room_list.size)]
    room.put_to_random_place(event)
  end

  #--------------------------------------------------------------------------
  # ● 起動中のマップイベントを検出／セットアップ
  #--------------------------------------------------------------------------
  def setup_starting_map_event
    event = @events.values.find {|event| event.starting }
    event.clear_starting_flag if event
    @interpreter.setup(event.list, event.event_id) if event
    event
  end
  def room(x, y)
    for rect in @rect_list
      if rect.room.contains(x, y)
        return rect.room
      end
    end
    return nil
  end
  
end


class Spriteset_Map
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  alias saba_dungeon_update update
  def update
    if $game_map.new_events
      $game_map.new_events.values.each do |event|
        @character_sprites.push(Sprite_Character.new(@viewport1, event))
      end
      $game_map.new_events = nil
    end
    saba_dungeon_update
    update_dark_sprite_visible
  end
  #--------------------------------------------------------------------------
  # ● 暗闇スプライトの表示更新
  #--------------------------------------------------------------------------
  def update_dark_sprite_visible
    if $game_map.dungeon?
      unless @dark_sprite
        @viewport_dark = Viewport.new
        @dark_sprite = Sprite_Dark.new(@viewport_dark)
      end
      @dark_sprite.visible = true
      @dark_sprite.update
    else
      @dark_sprite.visible = false if @dark_sprite
    end
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  alias saba_dungeon_dispose dispose
  def dispose
    @dark_sprite.dispose if @dark_sprite
    saba_dungeon_dispose
  end
  #--------------------------------------------------------------------------
  # ● ビューポートの解放
  #--------------------------------------------------------------------------
  alias saba_dungeon_dispose_viewports dispose_viewports
  def dispose_viewports
    saba_dungeon_dispose_viewports
    @viewport_dark.dispose if @viewport_dark
  end
  #--------------------------------------------------------------------------
  # ● キャラクタースプライトの作成
  #--------------------------------------------------------------------------
  alias saba_dungeon_create_characters create_characters
  def create_characters
    saba_dungeon_create_characters
    $game_map.new_events = nil
  end
end

class Sprite_Character
  alias saba_dangeon_update update
  def update
    saba_dangeon_update
    return unless $game_map.dungeon?
    if @character.is_a?(Game_Event)
#~       if @static == nil
#~         @static = @character.name.to_i > 1000
#~       end
#~       if @static
#~         self.visible = true
        self.visible = false
      if $game_player.room
        self.visible = $game_player.room.contains(@character.x, @character.y)
      end
      
      case $game_player.distance(@character) 
        when 1;
          self.visible = true
          @last_visible = self.visible
        when 2;
          self.visible |= @last_visible
          @last_visible = false
      end
      
    end
  end
end

class Sprite_Dark < Sprite_Base
  def initialize(viewport)
    super(viewport)
    self.bitmap = Bitmap.new(Graphics.width+32*32, Graphics.height+32*32)
    refresh
    update
  end
  def update
    super
    
    if @last_room != $game_player.room
      refresh
      @last_room = $game_player.room
    end
    if @last_room
      self.viewport.ox = -@start_x + $game_map.display_x*32
      self.viewport.oy = -@start_y + $game_map.display_y*32
      if (self.viewport.ox - self.bitmap.width / 2 + Graphics.width / 2).abs > Graphics.width / 2 ||
         (self.viewport.oy - self.bitmap.height / 2 + Graphics.height / 2).abs > Graphics.height / 2 
        refresh
      end
      self.viewport.ox = -@start_x + $game_map.display_x*32
      self.viewport.oy = -@start_y + $game_map.display_y*32
      
    else
      self.viewport.ox = -$game_player.screen_x + self.bitmap.width / 2 
      self.viewport.oy = -$game_player.screen_y + self.bitmap.height / 2 + 16
    end
  end
  def refresh
    self.bitmap.clear
    self.bitmap.fill_rect(0, 0, self.bitmap.width, self.bitmap.height, Color.new(0, 0, 0, 100))
    room = $game_player.room
    if room == nil
      rect = Rect.new
      rect.x = self.bitmap.width / 2 - 48
      rect.y = self.bitmap.height / 2 - 45
      rect.width = 96
      rect.height = 96
      self.bitmap.clear_rect(rect)
      
      edge = Cache.system("dark_edge2")
      self.bitmap.blt(rect.x, rect.y, edge, edge.rect)
    else
      rect = Rect.new
      rect.x = self.bitmap.width / 2 - ($game_player.x - room.lx) * 32
      rect.y = self.bitmap.height / 2 - ($game_player.y - room.ly) * 32
      rect.width = (room.hx - room.lx+2) * 32
      rect.height = (room.hy - room.ly+2) * 32
      self.bitmap.clear_rect(rect)
      @start_x = $game_map.display_x*32 - self.bitmap.width / 2 + ($game_player.x - $game_map.display_x - 1)*32
      @start_y = $game_map.display_y*32 - self.bitmap.height / 2 + ($game_player.y - $game_map.display_y - 1)*32
      
      edge = Cache.system("dark_edge")
      self.bitmap.blt(rect.x, rect.y, edge, Rect.new(0, 0, 32, 32))
      self.bitmap.blt(rect.x+rect.width-32, rect.y, edge, Rect.new(32, 0, 32, 32))
      self.bitmap.blt(rect.x, rect.y+rect.height-32, edge, Rect.new(0, 32, 32, 32))
      self.bitmap.blt(rect.x+rect.width-32, rect.y+rect.height-32, edge, Rect.new(32, 32, 32, 32))
    end
  end
end
class Game_Event
  attr_reader :event
  attr_accessor :event_id
  attr_reader   :erased
  def name
    @event.name
  end
  alias saba_dungeon_erase erase
  def erase
    saba_dungeon_erase
    return unless enemy?
    $game_variables[Saba::Dungeon::ENEMY_COUNT_VARIABLE] -= 1
  end
  def enemy?
    return name.include?("*")
  end
end

class Game_Player
  #--------------------------------------------------------------------------
  # ● 指定位置に移動
  #--------------------------------------------------------------------------
  alias saba_dungeon_moveto moveto
  def moveto(x, y)
    saba_dungeon_moveto(x, y)
    $game_map.setup_player_initial_position if $game_map.dungeon?
  end
  def distance(event)
    min = $game_player.distance_xy_from(event.x, event.y)
    return min unless $game_player.followers.visible
    $game_player.followers.each do |character|
      dist = character.distance_xy_from(event.x, event.y)
      if dist < min
        min = dist
      end
    end
    return min
  end
end


class Game_Character
  #--------------------------------------------------------------------------
  # ● 距離計算
  #--------------------------------------------------------------------------
  def distance_xy_from(x, y)
    sx = distance_x_from(x)
    sy = distance_y_from(y)
    return [sx.abs, sy.abs].max
  end
end

class << DataManager
  alias saba_dungeon_create_game_objects create_game_objects
  def create_game_objects
    saba_dungeon_create_game_objects
    $game_map.map_infos = load_data("Data/MapInfos.rvdata2")
  end
  alias saba_dungeon_load_game_without_rescue load_game_without_rescue
  def load_game_without_rescue(index)
    saba_dungeon_load_game_without_rescue(index)
    $game_map.map_infos = load_data("Data/MapInfos.rvdata2")
  end
  #--------------------------------------------------------------------------
  # ● データが更新されている場合はマップを再読み込み(再定義)
  #--------------------------------------------------------------------------
  alias saba_dungeon_reload_map_if_updated reload_map_if_updated
  def reload_map_if_updated
    return if $game_map.dungeon?
    saba_dungeon_reload_map_if_updated
  end
end