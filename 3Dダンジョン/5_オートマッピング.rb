#==============================================================================
# ■ 3Dダンジョン オートマッピング
#   @version 1.91 12/10/14
#   @author さば缶
#------------------------------------------------------------------------------
# ■ 機能
#    イベントのスクリプトで、以下のように記述すると指定のリージョンを
#    マッピング済みにできます。
#    $auto_mapping.mapping_region(リージョンID)
#
#    例： $auto_mapping.mapping_region(1)
#==============================================================================
class Game_AutoMappingSet
  attr_accessor :listener
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    @data = {}
    @maps = {}
    @enabled = Saba::Three_D::AUTOMAPPING_ENABLED
  end
  
  def enabled=(b)
    return if @enabled == b
    @enabled = b
    if @enabled
      mapping($game_map.map_id, $game_player.x, $game_player.y)
    end
  end
  #--------------------------------------------------------------------------
  # ● 指定のマップIDのマップを、オートマッピング可能かどうかを設定します。
  #--------------------------------------------------------------------------
  def enable_map(map_id, b)
    @maps[map_id] = b
  end
  #--------------------------------------------------------------------------
  # ● 指定のマップIDのマップがオートマッピング可能かどうかを返します。
  #--------------------------------------------------------------------------
  def enabled?(map_id)
    return false unless @enabled
    if @maps[map_id] == false
      return false
    else
      return true
    end
  end
  #--------------------------------------------------------------------------
  # ● プレイヤーの方向を変えたことを通知します。
  #--------------------------------------------------------------------------
  def update_direction
    @listener.direction_updated unless @listener == nil
  end
  def refresh
    @listener.updated unless @listener == nil
  end
  #--------------------------------------------------------------------------
  # ● 指定のマップIDの指定のマップ座標をマッピングします。
  #--------------------------------------------------------------------------
  def mapping(map_id, x, y)
    return if $game_map.events == nil
    unless $auto_mapping.enabled?($game_map.map_id)
      @listener.updated unless @listener == nil
      return
    end
    success = mapping_internal(map_id, x, y)
    if success
      @listener.mapped(x, y) unless @listener == nil
    end
    @listener.updated unless @listener == nil
  end
  #--------------------------------------------------------------------------
  # ● 指定のマップIDの指定のマップ座標をマッピングします。内部でのみ使われます。
  #--------------------------------------------------------------------------
  def mapping_internal(map_id, x, y, force = false)
    auto_map = map(map_id)
    auto_map.clear_tile(x, y) if force
    success = auto_map.add_tile(x, y, tile_type(x, y))
    unless success
      return success
    end
    if $game_map.gate?(x, y, 4)
      auto_map.add_gate(x, y, 4)
    elsif $game_map.wall?(x, y, 4)
      auto_map.add_wall(x, y, 4)
    end
    if $game_map.gate?(x, y, 6)
      auto_map.add_gate(x, y, 6)
    elsif $game_map.wall?(x, y, 6)
      auto_map.add_wall(x, y, 6)
    end
    if $game_map.gate?(x, y, 8)
      auto_map.add_gate(x, y, 8)
    elsif $game_map.wall?(x, y, 8)
      auto_map.add_wall(x, y, 8)
    end
    if $game_map.gate?(x, y, 2)
      auto_map.add_gate(x, y, 2)
    elsif $game_map.wall?(x, y, 2)
      auto_map.add_wall(x, y, 2)
    end
    
    return success
  end
  def tile_type(x, y)
    $game_map.tile_type(x, y)
  end
  #--------------------------------------------------------------------------
  # ● 指定のマップIDの指定のマップ座標がダークゾーンかを返します。
  #--------------------------------------------------------------------------
  def dark_zone?(map_id, x, y)
    auto_map = map(map_id)
    return false if auto_map == nil
    return auto_map.dark_zone?(x, y)
  end
  #--------------------------------------------------------------------------
  # ● 指定のマップIDの指定のマップ座標が通行可能かを返します。
  #--------------------------------------------------------------------------
  def tile?(map_id, x, y)
    auto_map = map(map_id)
    return false if auto_map == nil
    return auto_map.tile?(x, y)
  end
  #--------------------------------------------------------------------------
  # ● 指定のマップIDの指定のマップ座標が壁かを返します。
  #--------------------------------------------------------------------------
  def wall?(map_id, x, y, direction)
    auto_map = map(map_id)
    return false if auto_map == nil
    return auto_map.wall?(x, y, direction)
  end
  #--------------------------------------------------------------------------
  # ● 指定のマップIDの指定のマップ座標が扉かを返します。
  #--------------------------------------------------------------------------
  def gate?(map_id, x, y, direction)
    auto_map = map(map_id)
    return false if auto_map == nil
    return auto_map.gate?(x, y, direction)
  end
  #--------------------------------------------------------------------------
  # ● 指定のマップIDのマップオブジェクトを返します。
  #--------------------------------------------------------------------------
  def map(map_id)
    @data[map_id] = Game_AutoMapping.new if @data[map_id] == nil
    return @data[map_id]
  end
  #--------------------------------------------------------------------------
  # ● マーカーを更新することをマッピングスプライトに通知します。
  #--------------------------------------------------------------------------
  def update_markers
    @listener.marker_updated unless @listener == nil
  end
end

#==============================================================================
# ■ Game_AutoMapping
#------------------------------------------------------------------------------
# 　Auto_Mappingクラスの内部で使われ、各マップにつきひとつ作成されます。
#  マップ内のオートマッピング情報を保持しています。
#==============================================================================
class Game_AutoMapping
  include Saba::Three_D
  attr_accessor :tiles
  attr_accessor :walls
  attr_accessor :gates
  def initialize
    @tiles = []
    @walls = []
    @gates = []
    @tile_map = {}
    @wall_map = {}
    @gate_map = {}
  end
  def clear_tile(x, y)
    key = [x, y]
    @tile_map[key] = false
    for direction in [2, 4, 6, 8]
      key = [x, y, direction]
      @wall_map[key] = false
      @gate_map[key] = false
    end
  end
  def add_tile(x, y, type)
    key = [x, y]
    return false if @tile_map[key] == true
    @tile_map[key] = type
    @tiles.push(key)
    return true
  end
  def dark_zone?(x, y)
    key = [x, y]
    return key == DARK_ZONE
  end
  def add_wall(x, y, direction)
    key = [x, y, direction]
    @wall_map[key] = true
    @walls.push(key)
  end
  def add_gate(x, y, direction)
    key = [x, y, direction]
    @gate_map[key] = true
    @gates.push(key)
  end
  def tile_id(x, y)
    key = [x, y]
    return @tile_map[key]
  end
  def wall?(x, y, direction)
    key = [x, y, direction]
    return @wall_map[key] == true
  end
  def gate?(x, y, direction)
    key = [x, y, direction]
    return @gate_map[key] == true
  end
  def mapped?(x, y)
    key = [x, y]
    return @tile_map[key] != nil
  end
end

class Scene_Map
  include Saba::Three_D
  #--------------------------------------------------------------------------
  # ● 開始処理
  #--------------------------------------------------------------------------
  alias saba_3d_automap_start start
  def start
    @automap_calling = false
    saba_3d_automap_start
    
    $auto_mapping.refresh
  end
  #--------------------------------------------------------------------------
  # ● 全ウィンドウの作成
  #--------------------------------------------------------------------------
  alias saba_3d_automap_create_all_windows create_all_windows
  def create_all_windows
    saba_3d_automap_create_all_windows
    create_automap_window
  end
  #--------------------------------------------------------------------------
  # ○ 2Dマップに変化
  #--------------------------------------------------------------------------
  alias saba_3d_automap_to_2d to_2d
  def to_2d
    saba_3d_automap_to_2d
    dispose_automap_window
  end
  #--------------------------------------------------------------------------
  # ○ 3Dダンジョンに変化
  #--------------------------------------------------------------------------
  alias saba_3d_automap_to_3d to_3d
  def to_3d
    saba_3d_automap_to_3d
    create_automap_window
  end
  def create_automap_window
    return if $game_map.is_2d?
    w = 128
    h = 120
    @automapping_window = Window_AutoMapping.new(Graphics.width-w, Graphics.height-h, w, h)
  end
  def dispose_automap_window
    @automapping_window.dispose
    @automapping_window = nil
  end
  #--------------------------------------------------------------------------
  # ● シーン遷移に関連する更新
  #--------------------------------------------------------------------------
  alias saba_3d_automap_update_scene update_scene
  def update_scene
    saba_3d_automap_update_scene
    update_call_automap unless scene_changing?
  end
  #--------------------------------------------------------------------------
  # ● マップ画面呼び出し判定
  #--------------------------------------------------------------------------
  def update_call_automap
    if  $game_map.interpreter.running?
      @automap_calling = false
    elsif $game_switches[DISABLE_WHOLE_MAP_SWITCH]
    else
      if $game_switches[HIDE_AUTOMAP_IN_DARK_ZONE_SWITCH] && $game_player.in_dark_zone?
        Sound.play_buzzer if Input.trigger?(AUTOMAP_BUTTON)
        return
      end
      @automap_calling ||= Input.trigger?(AUTOMAP_BUTTON)
      call_automap if @automap_calling && !$game_player.moving?
    end
  end
  #--------------------------------------------------------------------------
  # ● マップ画面の呼び出し
  #--------------------------------------------------------------------------
  def call_automap
    Sound.play_ok
    SceneManager.call(Scene_AutoMapping)
  end
end

#==============================================================================
# ■ Window_AutoMapping
#------------------------------------------------------------------------------
# オートマッピング用のウィンドウです。
#==============================================================================
class Window_AutoMapping < Window_Base
  include Saba::Three_D
  def initialize(x, y, width, height, type = "", whole = false)
    super(x, y, width, height)
    self.z = 1
    @margin = Saba::Three_D::AUTO_MAPPING_WINDOW_PADDING
    h = height-@margin*2
    h -= 32 if whole
    y += 32 if whole
    @sprite = Sprite_AutoMapping.new(x+@margin, y+@margin, width-@margin*2, h, type, whole)
    draw_mapname if whole
    update
  end
  def update
    super
    if @last_map_id != $game_map.map_id
      @sprite.refresh
      @last_map_id = $game_map.map_id
    end
    if $game_switches[HIDE_ALL_SWITCH] || $game_switches[HIDE_AUTOMAP_SWITCH]
      self.visible = false
      return
    end
    self.visible = ! ($game_message.busy? && $game_message.position == 2)
    @sprite.update
  end
  def draw_mapname
    draw_text(0, 6, Graphics.width, 24, $game_map.display_name, 1)
  end
  def visible=(b)
    super
    if $game_player.in_dark_zone? && b
      # 何もしない
    else
      @sprite.visible = b
    end
  end
  def dispose
    super
    @sprite.dispose
  end
  def up
    @sprite.up
  end
  def down
    @sprite.down
  end
  def right
    @sprite.right
  end
  def left
    @sprite.left
  end
end

#==============================================================================
# ■ Sprite_AutoMapping
#------------------------------------------------------------------------------
# オートマッピング用のスプライトです。
#==============================================================================
class Sprite_AutoMapping < Sprite_Base
  include Saba::Three_D
  #--------------------------------------------------------------------------
  # ● オートマッピングの初期化
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height, type = "", whole = false)
    super(nil)
    @whole = whole
    @width = width
    @height = height
    init_resources(type)
    $auto_mapping.listener = self
    init_bitmap(width, height)
    init_location(x, y)
    init_marker_sprite(viewport, width, height)
    init_player_sprite(viewport, width, height)
    
    @last_map_id = $game_map.map_id
    init_max_scroll
    update_player
    update_src_rect
    self.z = 1
    refresh
    update
  end
  #--------------------------------------------------------------------------
  # ○ 使う画像を取得し、その画像サイズからオートマッピングの1マスの大きさを決定します。
  #--------------------------------------------------------------------------
  def init_resources(type)
    @tile = Cache.system("AutoMapTile" + type)
    @marker = Cache.system("AutoMapMarker" + type)
    @player = Cache.system("AutoMapPlayer" + type)
    @foe = Cache.system("AutoMapFoe" + type)
    @cw = @tile.width / 2
    @ch = @cw
  end
  #--------------------------------------------------------------------------
  # ● メインで使うビットマップを作成します。。
  #--------------------------------------------------------------------------
  def init_bitmap(width, height)
    self.bitmap = Bitmap.new([@cw * $game_map.width + 1, width].max, [@ch * ($game_map.height + 1), height].max)
    self.src_rect = Rect.new(0, 0, width, height)
  end
  
  def init_location(x, y)
    @start_ox = -x
    self.ox = @start_ox
    @start_oy = -y
    self.oy = @start_oy
    @scroll_x = 0
    @scroll_y = 0
    @center_x = (@width) / 2 - @cw / 2
    @center_y = (@height) / 2 - @ch / 2
  end
  #--------------------------------------------------------------------------
  # ○ プレイヤースプライトを作成
  #--------------------------------------------------------------------------
  def init_player_sprite(viewport, width, height)
    return if @whole
    @player_sprite = Sprite.new(viewport)
    @player_sprite.bitmap = Bitmap.new(@player.width / 2, @player.height / 2)
    @player_sprite.ox = @start_ox - (width) / 2 + @player.width / 4
    @player_sprite.oy = @start_oy - (height) / 2 + @player.height / 4
    @player_sprite.z = 10
  end
  #--------------------------------------------------------------------------
  # ○ マーカースプライトを作成
  #--------------------------------------------------------------------------
  def init_marker_sprite(viewport, width, height)
    return if @whole
    @marker_sprite = Sprite.new(viewport)
    @marker_sprite.bitmap = Bitmap.new(width, height)
    @marker_sprite.ox = @start_ox
    @marker_sprite.oy = @start_oy
    @marker_sprite.z = 8
  end
  #--------------------------------------------------------------------------
  # ● 現在のマップの指定の座標がマッピングされたときに呼ばれます。
  #--------------------------------------------------------------------------
  def mapped(x, y)
    real_x = x * @cw
    real_y = y * @ch
    draw_mapping_elements(real_x, real_y, x, y)
  end
  #--------------------------------------------------------------------------
  # ● リソースを全て解放します。
  #--------------------------------------------------------------------------
  def dispose
    super
    self.bitmap.dispose
    if @player_sprite
      @player_sprite.bitmap.dispose
      @player_sprite.dispose
    end
    if @marker_sprite
      @marker_sprite.bitmap.dispose
      @marker_sprite.dispose
    end
    $auto_mapping.listener = nil
  end
  #--------------------------------------------------------------------------
  # ● オートマッピングが更新されたときに呼ばれます。
  #--------------------------------------------------------------------------
  def updated
    update_player
    draw_markers
    update_src_rect
  end
  #--------------------------------------------------------------------------
  # ● プレイヤーの向きが変わったときに呼ばれます。
  #--------------------------------------------------------------------------
  def direction_updated
    update_player
  end
  #--------------------------------------------------------------------------
  # ● 表示領域を更新します。
  #--------------------------------------------------------------------------
  def update_src_rect
    return if @whole
    self.src_rect.x = @cw * $game_player.x + @cw / 2 - (@width) / 2
    self.src_rect.y = @ch * $game_player.y + @ch / 2 - (@height) / 2
  end
  #--------------------------------------------------------------------------
  # ● プレイヤーの画像を更新します。
  #--------------------------------------------------------------------------
  def update_player
    return if @whole
    @player_sprite.bitmap.clear_rect(0, 0, @player_sprite.bitmap.width, @player_sprite.bitmap.height)
    draw_player(0, 0, @player_sprite.bitmap)
  end
  #--------------------------------------------------------------------------
  # ● 全ての描画要素を最新の状態に更新します。
  #--------------------------------------------------------------------------
  def refresh
    draw_whole
    draw_markers
  end
  #--------------------------------------------------------------------------
  # ● スクロールできる最大値を計算します。これは全体マップの時に使われます。
  #--------------------------------------------------------------------------
  def init_max_scroll
    width = @width / @cw
    height = @height / @ch
    @max_scroll_x = ($game_map.width - width + 1) * @cw
    @max_scroll_y = ($game_map.height - height + 1) * @ch
    if @max_scroll_x < 0
      @max_scroll_x = 0
    end
    if @max_scroll_y < 0
      @max_scroll_y = 0
    end
  end
  #--------------------------------------------------------------------------
  # ● オートマッピングで必要な要素を全て描画します。
  #--------------------------------------------------------------------------
  def draw_whole
    self.bitmap.clear_rect(0, 0, self.bitmap.width, self.bitmap.height)
  
    width = (@width) / @cw
    height = (@height) / @ch
    
    if @whole
      start_x = [(width - $game_map.width) / 2, 1].max
      start_y = [(height - $game_map.height) / 2, 1].max
    else
      start_x = 0
      start_y = 0
    end
    draw_background(start_x, start_y)
    draw_all_tiles(start_x, start_y)
    
    focus_player(start_x, start_y, width, height)
  end
  #--------------------------------------------------------------------------
  # ● 背景ウィンドウから指定の座標分離れたところから、マッピング要素を全て描画します。
  #--------------------------------------------------------------------------
  def draw_all_tiles(start_x, start_y)
    map = $auto_mapping.map($game_map.map_id)
    for tile in map.tiles
      x = start_x + tile[0]
      y = start_y + tile[1]
      real_x = x * @cw
      real_y = y * @ch
      draw_mapping_elements(real_x, real_y, tile[0], tile[1])
    end
  end
  #--------------------------------------------------------------------------
  # ● 全体図の場合、プレイヤーアイコンが中心にくるように初期スクロールを設定します。
  #--------------------------------------------------------------------------
  def focus_player(start_x, start_y, width, height)
    return unless @whole
    player_x = @cw * ($game_player.x + start_x) + (@cw - @player.width / 2) / 2
    player_y = @ch * ($game_player.y + start_y) + (@ch - @player.height / 2) / 2
  
   
    draw_player(player_x, player_y, self.bitmap)

    
    if $game_player.x > width / 2
      @scroll_x = ($game_player.x - width / 2) * @cw
      if @scroll_x >= @max_scroll_x
        @scroll_x = @max_scroll_x
      end
      self.src_rect.x = @scroll_x
    end
    if $game_player.y > height / 2
      @scroll_y = ($game_player.y - height / 2) * @ch
      if @scroll_y >= @max_scroll_y
        @scroll_y = @max_scroll_y
      end
      self.src_rect.y = @scroll_y
    end
  end
  #--------------------------------------------------------------------------
  # ● 背景ウィンドウから指定の座標分離れたところから、背景のタイルを全て描画します。
  #--------------------------------------------------------------------------
  def draw_background(start_x, start_y)
    $game_map.width.times do |x_index|
      x = start_x + x_index
      $game_map.height.times do |y_index|
        y = start_y + y_index
        real_x = x * @cw
        real_y = y * @ch
        self.bitmap.blt(real_x, real_y, @tile, Rect.new(0, 0, @cw, @ch))
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 表示位置を4ピクセル右にすらします。全体マップの時に使われます。
  #--------------------------------------------------------------------------
  def right
    if @scroll_x >= @max_scroll_x
      return
    end
    @scroll_x += 4
    self.src_rect.x = @scroll_x
  end
  #--------------------------------------------------------------------------
  # ● 表示位置を4ピクセル左にすらします。全体マップの時に使われます。
  #--------------------------------------------------------------------------
  def left
    if @scroll_x <= 0
      return
    end
    @scroll_x -= 4
    self.src_rect.x = @scroll_x
  end
  #--------------------------------------------------------------------------
  # ● 表示位置を4ピクセル下にすらします。全体マップの時に使われます。
  #--------------------------------------------------------------------------
  def down
    if @scroll_y >= @max_scroll_y
      return
    end
    @scroll_y += 4
    self.src_rect.y = @scroll_y
  end
  #--------------------------------------------------------------------------
  # ● 表示位置を4ピクセル上にすらします。全体マップの時に使われます。
  #--------------------------------------------------------------------------
  def up
    if @scroll_y <= 0
      return
    end
    @scroll_y -= 4
    self.src_rect.y = @scroll_y
  end
  #--------------------------------------------------------------------------
  # ● マーカーの状態に変更があったときに呼ばれます。
  #--------------------------------------------------------------------------
  def marker_updated
    draw_markers
  end
  #--------------------------------------------------------------------------
  # ● 全てのマーカーを再描画します。
  #--------------------------------------------------------------------------
  def draw_markers
    if @whole
      draw_whole_markers
    else
      draw_part_of_markers
    end
  end
  #--------------------------------------------------------------------------
  # ● オートマッピングで見えている範囲のマーカーを再描画します。
  #--------------------------------------------------------------------------
  def draw_part_of_markers
    @marker_sprite.bitmap.clear_rect(0, 0, @marker_sprite.bitmap.width, @marker_sprite.bitmap.height)
    
    x = $game_player.x
    y = $game_player.y
    
    x_count = @marker_sprite.bitmap.width / @cw + 2
    y_count = @marker_sprite.bitmap.width / @ch + 2
    
    start_x = -(x_count / 2).round
    start_y = -(y_count / 2).round
    if $auto_mapping.enabled?($game_map.map_id)
      
      x_count.times do |x_index|
        offset_x = start_x + x_index
        y_count.times do |y_index|
          offset_y = start_y + y_index
          real_x = @center_x + offset_x * @cw
          real_y = @center_y + offset_y * @ch
          draw_marker(real_x, real_y, x + offset_x, y + offset_y)
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 全体図用に、全ての領域のマーカーを描画します。
  #--------------------------------------------------------------------------
  def draw_whole_markers
    width = (@width) / @cw
    height = (@height) / @ch
    
    if @whole
      start_x = (width - $game_map.width) / 2
      start_y = (height - $game_map.height) / 2
      if start_x < 1
        start_x = 1
      end
      if start_y < 1
        start_y = 1
      end
    end
#~      map = $auto_mapping.map($game_map.map_id)
#~     for tile in map.tiles
#~       x = start_x + tile[0]
#~       y = start_y + tile[1]
#~       real_x = x * @cw
#~       real_y = y * @ch
#~       draw_marker(real_x, real_y, tile[0], tile[1])
#~     end
#~     return
    auto_map = $auto_mapping.map($game_map.map_id)
    for event in $game_map.events.values
      mapped = auto_map.tile_id(event.x, event.y) != nil
      marker = event.marker(mapped)
      next if marker == 0 || marker == nil
      x = start_x + event.x
      y = start_y + event.y
      if marker > Saba::Three_D::FOE_MARKER
        marker -= Saba::Three_D::FOE_MARKER
        self.bitmap.blt(x * @cw, y * @ch, @foe, Rect.new((marker - 1) % 2 * @cw, (marker - 1) / 2 * @ch, @cw, @ch))
      else
        self.bitmap.blt(x * @cw, y * @ch, @marker, Rect.new((marker - 1) % 2 * @cw, (marker - 1) / 2 * @ch, @cw, @ch))
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 指定の画面座標に、指定のマップ座標のマーカーを描画します。
  #--------------------------------------------------------------------------
  def draw_marker(x, y, map_x, map_y)
    auto_map = $auto_mapping.map($game_map.map_id)
    mapped = auto_map.tile_id(map_x, map_y) != nil
    marker = $game_map.marker(map_x, map_y, mapped)
    if marker > Saba::Three_D::FOE_MARKER
      marker -= Saba::Three_D::FOE_MARKER
      @marker_sprite.bitmap.blt(x, y, @foe, Rect.new((marker - 1) % 2 * @cw, (marker - 1) / 2 * @ch, @cw, @ch))
    elsif marker > 0
      @marker_sprite.bitmap.blt(x, y, @marker, Rect.new((marker - 1) % 2 * @cw, (marker - 1) / 2 * @ch, @cw, @ch))
    end
  end
  #--------------------------------------------------------------------------
  # ● オートマッピングで見えている範囲のマップを再描画します。
  #--------------------------------------------------------------------------
  def draw_part_of_map
    self.bitmap.clear_rect(0, 0, self.bitmap.width, self.bitmap.height)
    return unless $auto_mapping.enabled?($game_map.map_id)
    
    x = $game_player.x
    y = $game_player.y
    
    x_count = self.bitmap.width / @cw + 2
    y_count = self.bitmap.width / @ch + 2
    
    start_x = -(x_count / 2).round
    start_y = -(y_count / 2).round
    
    x_count.times do |x_index|
      offset_x = start_x + x_index
      y_count.times do |y_index|
        offset_y = start_y + y_index
        real_x = @center_x + offset_x * @cw
        real_y = @center_y + offset_y * @ch
        draw_mapping_elements(real_x, real_y, x + offset_x, y + offset_y)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 指定の座標にプレイヤーの画像を描画します。
  #--------------------------------------------------------------------------
  def draw_player(x, y, bitmap = self.bitmap)
    case $game_player.direction
    when 2
      bitmap.blt(x, y, @player, Rect.new(@player.width / 2, 0, @player.width / 2, @player.height / 2))
    when 4
      bitmap.blt(x, y, @player, Rect.new(0, @player.height / 2, @player.width / 2, @player.height / 2))
    when 6
      bitmap.blt(x, y, @player, Rect.new(@player.width / 2, @player.height / 2, @player.width / 2, @player.height / 2))
    when 8
      bitmap.blt(x, y, @player, Rect.new(0, 0, @player.width / 2, @player.height / 2))
    end
  end
  #--------------------------------------------------------------------------
  # ● 指定の画面座標に、指定のマップ座標のタイル及び隣接する壁を描画します。
  #--------------------------------------------------------------------------
  def draw_mapping_elements(x, y, map_x, map_y)
    if @last_map_id != $game_map.map_id
      self.bitmap.dispose
      init_bitmap(self.width, self.height)
      @last_map_id = $game_map.map_id
    end
    draw_tile(x, y, map_x, map_y)
    return if $game_map.dark_zone?(map_x, map_y)
    draw_wall(x, y, map_x, map_y)
    draw_gate(x, y, map_x, map_y)
  end
  #--------------------------------------------------------------------------
  # ● 指定の画面座標に、指定のマップ座標のタイルを描画します。
  #--------------------------------------------------------------------------
  def draw_tile(x, y, map_x, map_y)
    position = tile_position(map_x, map_y)
    self.bitmap.blt(x, y, @tile, Rect.new(@cw * position[0], @ch * position[1], @cw, @ch))
  end
  def tile_position(map_x, map_y)
    type = $auto_mapping.tile_type(map_x, map_y)
    case type
    when 0
      return [1, 0]
    when DARK_ZONE
      return [0, 5]
    when TYPE2_ZONE
      return [0, 6]
    when TYPE3_ZONE
      return [1, 6]
    else
      return [0, 0]
    end
  end
  #--------------------------------------------------------------------------
  # ● 指定の画面座標に、指定のマップ座標の壁を描画します。
  #--------------------------------------------------------------------------
  def draw_wall(x, y, map_x, map_y)
    return if $auto_mapping.dark_zone?($game_map.map_id, map_x, map_y)
    if $auto_mapping.wall?($game_map.map_id, map_x, map_y, 8)
      self.bitmap.blt(x, y, @tile, Rect.new(0, @ch, @cw, @ch))
    end
    if $auto_mapping.wall?($game_map.map_id, map_x, map_y, 2)
      self.bitmap.blt(x, y, @tile, Rect.new(@cw, @ch, @cw, @ch))
    end
    if $auto_mapping.wall?($game_map.map_id, map_x, map_y, 4)
      self.bitmap.blt(x, y, @tile, Rect.new(0, @ch * 2, @cw, @ch))
    end
    if $auto_mapping.wall?($game_map.map_id, map_x, map_y, 6)
      self.bitmap.blt(x, y, @tile, Rect.new(@cw, @ch * 2, @cw, @ch))
    end
  end
  #--------------------------------------------------------------------------
  # ● 指定の画面座標に、指定のマップ座標の扉を描画します。
  #--------------------------------------------------------------------------
  def draw_gate(x, y, map_x, map_y)
    return if $auto_mapping.dark_zone?($game_map.map_id, map_x, map_y)
    if $auto_mapping.gate?($game_map.map_id, map_x, map_y, 8)
      self.bitmap.blt(x, y, @tile, Rect.new(0, @ch * 3, @cw, @ch))
    end
    if $auto_mapping.gate?($game_map.map_id, map_x, map_y, 2)
      self.bitmap.blt(x, y, @tile, Rect.new(@cw, @ch * 3, @cw, @ch))
    end
    if $auto_mapping.gate?($game_map.map_id, map_x, map_y, 4)
      self.bitmap.blt(x, y, @tile, Rect.new(0, @ch * 4, @cw, @ch))
    end
    if $auto_mapping.gate?($game_map.map_id, map_x, map_y, 6)
      self.bitmap.blt(x, y, @tile, Rect.new(@cw, @ch * 4, @cw, @ch))
    end
  end
  #--------------------------------------------------------------------------
  # ● オートマッピングの可視性を設定します。
  #--------------------------------------------------------------------------
  def visible=(value)
    super
    @player_sprite.visible = value if @player_sprite
    @marker_sprite.visible = value if @marker_sprite
  end
  def update
    super
    if ($game_message.busy? && $game_message.position == 2)
      self.visible = false
    elsif $game_switches[HIDE_AUTOMAP_IN_DARK_ZONE_SWITCH] && $game_player.in_dark_zone?
      self.visible = false
      @player_sprite.visible = true
    else
      self.visible = true
    end
  end
end

class Scene_AutoMapping < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● 開始処理
  #--------------------------------------------------------------------------
  def start
    super
    w = Graphics.width
    h = Graphics.height
    @automapping_window = Window_AutoMapping.new(Graphics.width-w, Graphics.height-h, w, h, "Whole", true)
  end
  def update
    super
    @automapping_window.up if Input.press?(Input::UP)
    @automapping_window.down if Input.press?(Input::DOWN)
    @automapping_window.right if Input.press?(Input::RIGHT)
    @automapping_window.left if Input.press?(Input::LEFT)
    if Input.trigger?(:B)
      Sound.play_cancel
      SceneManager.return 
    end
  end
end



class Game_Map
  def tile_type(x, y)
    return DARK_ZONE if dark_zone?(x, y)
    id = @map.data[x, y, 0]
    return nil unless id
    if id >= 1584 && id <= 1631
      return TYPE2_ZONE
    end
    if id >= 1632 
      return TYPE3_ZONE
    end
    return NORMAL_ZONE
  end
  #--------------------------------------------------------------------------
  # ● 指定の座標のマーカーIDを返します。
  #--------------------------------------------------------------------------
  def marker(x, y, mapped)
    for event in events_xy(x, y)            # 座標が一致するイベントを調べる
      marker = event.marker(mapped)
      return marker if marker != nil && marker > 0
    end
    return 0
  end
  #--------------------------------------------------------------------------
  # ○ 指定のリージョンをぬりつぶし
  #--------------------------------------------------------------------------
  def mapping_region(region_id)
    width.times do |x|
      height.times do |y|
        id = region_id(x, y)
        if id == region_id
          $auto_mapping.mapping(@map_id, x, y)
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ 踏破率取得
  #--------------------------------------------------------------------------
  def mapping_score
    all = 0
    mapped = 0
    auto_mapping = $auto_mapping.map(@map_id)
    width.times do |x|
      height.times do |y|
        if region_id(x, y) > 0
          all += 1
          mapped += 1 if auto_mapping.mapped?(x, y)
        end
      end
    end
    return [all, mapped]
  end
  def name
    return @map.name
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ○ 踏破率取得
  #    何かしらリージョンで塗られているタイルだけを見て判定します。
  #    map_id_list  踏破率を取得したいマップIDの配列(マップIDだけでもいけます)
  #--------------------------------------------------------------------------
  def mapping_rate(map_id_list)
    all = 0
    mapped = 0
    unless map_id_list.is_a?(Array)
      map_id_list = [map_id_list]
    end
    for id in map_id_list
      map = Game_Map.new
      map.setup(id)
      score = map.mapping_score
      all += score[0]
      mapped += score[1]
    end
    return mapped * 100.0 / all
  end
end