#==============================================================================
# ■ 3Dダンジョン
#   @version 1.9 12/09/20
#   @author さば缶
#------------------------------------------------------------------------------
# ■ 使い方
#    1. 3Dダンジョンのスクリプトをコピーしてください。
#    2. Graphics以下のファイルをコピーしてください
#       ※Graphics/Pictures だけは必要ないです
#    3. データベースを開き、タイルセットタブの3Dダンジョンタイルセットを
#       コピーしてください
#
# ■ タイル説明
#    ▼ 黒い壁
#       通常の壁です。基本的にこれを使います。
#
#    ▼ 赤い壁
#       サブの壁です。マップ名に <"壁名"> で2つ以上壁を設定した場合のみ使えます
#       MAP003 のサンプルを参考にしてください。
#       ちょっとアクセントが入った壁をまぜるとオシャレに！
#
#
#    ▼ 白い床
#       通常の床です。基本的にこれを使います。
#       この床の上だと、自動で 15 番の変数に 0 が入ります。
#
#    ▼ 青い床
#       サンプルだとダメージ床になっています。
#       マッピングでも青くマッピングされます。
#       この床の上だと、自動で 15 番の変数に 1 が入ります。
#
#    ▼ 黄色い床
#       サンプルだとメニューが開けないエリアになっています。
#       "３Dダンジョン 黄床でメニュー不可"スクリプトを参照してください
#       マッピングでも黄色くマッピングされます。
#       この床の上だと、自動で 15 番の変数に 2 が入ります。
#
#==============================================================================
module Saba
  module Three_D
    # オートマッピングをデフォルトで有効にする場合 true に設定します。
    AUTOMAPPING_ENABLED = true
    
    # メッセージ表示時にステータスウィンドウ(+オートマッピング)を
    # 表示したままにする場合 ON にするスイッチの番号です。
    SHOW_STATUS_AT_MESSAGE_SWITCH = 110

    # キー入力による移動を禁止にするスイッチの番号です。
    DISABLE_KEY_INPUT = 113
    
    # ステータスウィンドウ、オートマップウィンドウ
    # 全てを非表示にするスイッチの番号です。
    HIDE_ALL_SWITCH = 114
    
    # オートマップウィンドを非表示にするスイッチの番号です。
    HIDE_AUTOMAP_SWITCH = 115
    
    # オートマップウィンドを表示にするスイッチの番号です。
    SHOW_AUTOMAP_SWITCH = 116
    
    # 奥の壁を着色するときに使うスイッチの番号です。
    # このスイッチをONにすると、奥の壁に少し色がつきます。
    # 色の設定方法はスクリプトで、
    # $dungeon.wall_color = Color.new(30, 30, 30, 30)
    # というように設定します。
    COLORING_WALL_SWITCH = 117
    
    # このスイッチが ON になっていると、全体マップ表示ボタンを押しても
    # 全体マップが表示されません。
    # イベント中などにどうぞ。
    DISABLE_WHOLE_MAP_SWITCH = 118
    
    # 逃走時に一歩後退する場合、ONにするスイッチです。
    BACK_AT_ESCAPE_SWITCH = 119
    
    # ダークゾーンに入るとミニマップを隠すスイッチ
    HIDE_AUTOMAP_IN_DARK_ZONE_SWITCH = 120
    
    # 現在の床色が入る変数
    TILE_TYPE_VARIABLE = 15
    
    # ダッシュ時の、各移動のウェイトです。
    DASH_WAIT = 11
    # 通常時の、各移動のウェイトです。
    NORMAL_WAIT = 16
    # 平行移動のウェイトです。
    TRANSLATION_WAIT = 24
    # 方向転換時のウェイトです。
    # 0 → ノーマル、ウェイト21
    # 1 → ちょいはや、ウェイト17
    # 2 → はや、ウェイト14
    # 3 → なし、ウェイト0
    ROTATION_WAIT_TYPE = 0
    
    # 移動中、スリップダメージで画面をフラッシュする場合 true に設定します。
    #FLASH_AT_SLIP_DAMAGE = false
    
    # 足音を鳴らす場合、trueに設定します。
    MOVE_SE_ENABLED = true
    
    # 足音1の音声ファイルです。
    MOVE_SE = "Audio/SE/Knock"
    # 足音1のボリュームです。
    MOVE_SE_VOLUME = 75
    # 足音1のピッチです。
    MOVE_SE_PITCH = 145
    
    # 足音2の音声ファイルです。
    MOVE_SE2 = "Audio/SE/Knock"
    # 足音2のボリュームです。
    MOVE_SE2_VOLUME = 80
    # 足音2のピッチです。
    MOVE_SE2_PITCH = 150
    
    # 壁激突時の音声ファイルです。
    CLASH_SE = "Audio/SE/Blow1"
    # 壁激突時のボリュームです。
    CLASH_SE_VOLUME = 100
    # 壁激突時のピッチです。
    CLASH_SE_PITCH = 100
    # 壁激突時の揺れの強さです。
    SHAKE_POWER = 5
    # 壁激突時の揺れのスピードです。
    SHAKE_SPEED = 10
    # 壁激突時の揺れの時間です。
    SHAKE_DURATION = 10
    
    # 扉通過時の音声ファイルです。
    GATE_SE = "Audio/SE/Open2"
    # 扉通過時のボリュームです。
    GATE_SE_VOLUME = 70
    # 扉通過時のピッチです。
    GATE_SE_PITCH = 120
    
    # １マス遠くになるごとに、壁と空間にかかる暗闇のアルファ値です。0～255
    DARK_ALPHA = 50
    
    # デフォルトの一番奥の視野の色です。
    BG_COLOR = Color.new(10, 10, 10)
    
    # 壁に着色する場合の色です。
    # スイッチ COLORING_WALL_SWITCH が ON である必要があります。
    WALL_COLOR = Color.new(255, 255, 255, 30)
    
    # 現在地を表示するテキストの揃え位置です。0で左揃え、1で中央、2で右揃え
    PLACE_TEXT_ALIGNMENT = 1
    

    # 全体マップを表示するときのボタンです。
    AUTOMAP_BUTTON = Input::R
 
    # オートマッピングウィンドウの、内側の空きピクセル数です。
    AUTO_MAPPING_WINDOW_PADDING = 6
    
    # LRボタンでカニ歩きできるようにする場合、trueに設定します。
    ENABLE_TRANSLATION_WITH_LR = false
    # 下ボタンでカニ歩きできるようにする場合、trueに設定します。
    ENABLE_TRANSLATION_WITH_DOWN = false
    
    # カニ歩きボタン。これを押しながら左右移動でカニ歩きします。
    # 無効にする場合　nil
    SIDLE_ALONG_BUTTON = Input::C
    
    # FOE を有効にする場合 true にします。
    # 描画回数が 1 回増えます。
    ENABLE_FOE = true
    
    # 中間モーションを描画しない場合、trueに設定します。
    NOT_DRAW_MIDDLE_MOTION = false
    
    # 扉をくぐった時のエンカウントの上昇度合いです。
    # この歩数歩いたのと同等のエンカウント率になります。
    GATE_ENCOUNTER = 5
    
    #-----------------------以下システム系、変更する必要はありません。
    REGEX_3D_WALL = /<([^<]+)>/
    REGEX_3D_NAME = /([^<]*)\<.+\>/i
    
    DARK_ZONE = 10
    TYPE2_ZONE = 12
    TYPE3_ZONE = 13
    NORMAL_ZONE = 0

    #118.5%
    module ItemExValueGetter
      #--------------------------------------------------------------------------
      # ● 拡張パラメータを取得します。
      #   item : 拡張パラメータを取得するアイテム
      #   name : 拡張パラメータの名前
      #--------------------------------------------------------------------------
      def self.get_ex_name(string, name)
        string.split(/[\r\n]+/).each do |line|
          elements = line.split(/\s+/)
          next unless elements.size == 2
          next unless elements[0] == name
          return elements[1]
        end
        return nil
      end
    end
  end
  
end

module Rotation
  def src_x(start_ox)
    t = Saba::Three_D::ROTATION_WAIT_TYPE
    if $game_player.rotation_right? || $game_player.rotation_left?
      if $game_player.rotation_right?
        sign = -1
      else
        sign = 1
      end
      if t == 0
        if $game_player.rotation.abs <= 6
          return $game_player.rotation * 3 * sign + start_ox
        else
          return ($game_player.rotation * $game_player.rotation.abs) / 20.0 * 6.8 * sign + start_ox
        end
      elsif t == 1
        if $game_player.rotation.abs <= 5
          return $game_player.rotation * 2.3 * sign + start_ox
        else
          return ($game_player.rotation * $game_player.rotation.abs) / 20 * 6.8 * sign + start_ox
        end
      elsif t == 2
        if $game_player.rotation.abs <= 4
          return $game_player.rotation * 2 * sign + start_ox
        else
          return ($game_player.rotation * $game_player.rotation.abs) / 20 * 6.8 * sign + start_ox
        end
      elsif t == 3
        return start_ox
      end
    else
      return start_ox
    end
  end
end

#==============================================================================
# ■ Scene_Map
#------------------------------------------------------------------------------
# 　3Dダンジョンと2Dマップの変化を検知して処理します。
#==============================================================================
class Scene_Map
  #--------------------------------------------------------------------------
  # ● 開始処理
  #--------------------------------------------------------------------------
  alias saba_3d_start start
  def start
    @is_3d = $game_map.is_3d?
    saba_3d_start
    update
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  alias saba_3d_update update
  def update
    back_at_escape if $game_map.is_3d?
    saba_3d_update
    
    update_change_3d_dungeon
  end
  def back_at_escape
    return if $game_temp.escape_at_battle != true
    $game_temp.escape_at_battle = false
    $game_player.back_at_escape
  end
  def update_basic
    super 
    update_change_3d_dungeon
  end
  #--------------------------------------------------------------------------
  # ○ 3Dダンジョン<->2Dマップの変化更新
  #--------------------------------------------------------------------------
  def update_change_3d_dungeon
    if @is_3d != $game_map.is_3d?
      @is_3d = $game_map.is_3d?
      if @is_3d
        to_3d
      else
        to_2d
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ 2Dマップに変化
  #--------------------------------------------------------------------------
  def to_2d
    @spriteset.change_map_type
  end
  #--------------------------------------------------------------------------
  # ○ 3Dダンジョンに変化
  #--------------------------------------------------------------------------
  def to_3d
    @spriteset.change_map_type
  end
  #--------------------------------------------------------------------------
  # ● キャンセルボタンによるメニュー呼び出し判定
  #--------------------------------------------------------------------------
  alias saba_3d_update_call_menu update_call_menu
  def update_call_menu
    if $game_player.collide_with_foe?($game_player.x, $game_player.y)
      @menu_calling = false
    else
      saba_3d_update_call_menu
    end
  end
  #--------------------------------------------------------------------------
  # ● シーン遷移の可能判定
  #--------------------------------------------------------------------------
  alias saba_3d_scene_change_ok? scene_change_ok?
  def scene_change_ok?
    return false if $game_switches[Saba::Three_D::DISABLE_KEY_INPUT]
    return saba_3d_scene_change_ok?
  end
end

class Spriteset_Map
  #--------------------------------------------------------------------------
  # ○ 3Dダンジョン<->2Dマップの変化
  #--------------------------------------------------------------------------
  def change_map_type
    dispose_tilemap
    create_tilemap
  end
  #--------------------------------------------------------------------------
  # ● 3Dダンジョン作成
  #--------------------------------------------------------------------------
  def create_3d
    if $dungeon.dungeon_sprite
      @main_3d = $dungeon.dungeon_sprite
    else
      @main_3d = Dungeon_Sprite.new
    end
    @main_3d.init_sprite(@viewport1)
    @main_3d.character_sprites = @character_sprites
    $dungeon.dungeon_sprite = @main_3d
  end
  #--------------------------------------------------------------------------
  # ● キャラクタースプライトの作成
  #--------------------------------------------------------------------------
  alias saba_3d_create_characters create_characters
  def create_characters
    saba_3d_create_characters
    return if $game_map.is_2d?
    @main_3d.character_sprites = @character_sprites
    @main_3d.refresh
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  alias saba_3d_update update
  def update
    saba_3d_update
    return if $game_map.is_2d?
    return if $dungeon.dungeon_sprite == nil
    @main_3d.update
  end
  #--------------------------------------------------------------------------
  # ● タイルマップの作成
  #--------------------------------------------------------------------------
  alias saba_3d_create_tilemap create_tilemap
  def create_tilemap
    if $game_map.is_3d?
      create_3d
    else 
      saba_3d_create_tilemap
    end
  end
  #--------------------------------------------------------------------------
  # ● タイルセットの更新
  #--------------------------------------------------------------------------
  alias saba_3d_update_tileset update_tileset
  def update_tileset
    return saba_3d_update_tileset if $game_map.is_2d?
    return create_3d if $dungeon.dungeon_sprite == nil
  end
  #--------------------------------------------------------------------------
  # ● タイルマップの更新
  #--------------------------------------------------------------------------
  alias saba_3d_update_tilemap update_tilemap
  def update_tilemap
    saba_3d_update_tilemap if $game_map.is_2d?
  end
  #--------------------------------------------------------------------------
  # ● タイルマップの解放
  #--------------------------------------------------------------------------
  alias saba_3d_dispose_tilemap dispose_tilemap
  def dispose_tilemap
    @tilemap.dispose if @tilemap
    if @main_3d
      @main_3d.visible = false 
      @main_3d.dispose_sprites
    end
  end
end

class Game_Map
  include Saba::Three_D

  NORMAL = 0
  ROTATE_RIGHT = 1
  ROTATE_LEFT = 2
  MIDDLE = 3
  attr_accessor :wall_index
  attr_accessor :wall_names
  attr_accessor :animation_type
  alias saba_3d_game_map_initialize initialize
  def initialize
    @wall_index = -1
    @no_cache = false
    @animation_type = NORMAL
    @gate_map = {}
    @event_map = {}
    saba_3d_game_map_initialize
  end
  #--------------------------------------------------------------------------
  # ● セットアップ
  #--------------------------------------------------------------------------
  alias saba_3d_setup setup
  def setup(map_id)
    saba_3d_setup(map_id)
    init_wall_index
    @gate_map = {}
    @event_map = {}
    if $dungeon.dungeon_sprite && $dungeon.dungeon_sprite.map_id != map_id
      $dungeon.dungeon_sprite.dispose
    end
    setup_foe
  end
  #--------------------------------------------------------------------------
  # ○ FOE初期化
  #--------------------------------------------------------------------------
  def setup_foe
    @foe_list = []
    for event in @events.values
      @foe_list.push(event) if event.foe?
    end
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  alias saba_3d_refresh refresh
  def refresh
    saba_3d_refresh
    $auto_mapping.refresh
  end
  #--------------------------------------------------------------------------
  # ● 通常キャラの通行可能判定
  #     d : 方向（2,4,6,8）
  #    指定された座標のタイルが指定方向に通行可能かを判定する。
  #--------------------------------------------------------------------------
  alias saba_3d_passable? passable?
  def passable?(x, y, d)
    return saba_3d_passable?(x, y, d) if $game_map.is_2d?
    return true if gate?(x, y, d)
    return false if clash_one_way?(x, y, d)
    return true if one_way?(x, y, d)
    return saba_3d_passable?(x, y, d)
  end
  #--------------------------------------------------------------------------
  # ○ 指定の座標が扉かどうか
  #--------------------------------------------------------------------------
  def gate?(x, y, direction)
    return true if one_way?(x, y, direction)
    key = [@map_id, x, y, direction]
    @gate_map = {} if @gate_map == nil
    unless @gate_map[key] == nil
      return @gate_map[key] >= 0
    end
    gate = gate_internal(x, y, direction)
    @gate_map[key] = gate
    return gate >= 0
  end
  def gate_index(x, y, direction)
    return 0 if one_way?(x, y, direction)
    key = [@map_id, x, y, direction]
    @gate_map = {} if @gate_map == nil
    unless @gate_map[key] == nil
      return @gate_map[key]
    end
    gate = gate_internal(x, y, direction)
    @gate_map[key] = gate
    return gate
  end
  def clear_cache
    @event_map = {}
  end
  def silent?(x, y)
    for event in events_xy(x, y)
      return true if event.silent?
    end
    return false
  end
  def unpassable_event?(x, y)
    for event in events_xy(x, y)
      return true if (! event.through) && event.unpassable?
    end
    return false
  end
  def foe?(x, y, direction)
    case direction
    when 8
      y -= 1
    when 2
      y += 1
    when 4
      x -= 1
    when 6
      x += 1
    end
    for event in events_xy(x, y)
      return true if event.foe?
    end
    return false
  end
  alias saba_3d_events_xy events_xy
  def events_xy(x, y)
    if $game_map.is_2d?
      return saba_3d_events_xy(x, y)
    end
    key = [x, y]
    @event_map = {} if @event_map == nil
    unless @event_map[key] == nil
      return @event_map[key]
    end
    events = saba_3d_events_xy(x, y)
    @event_map[key] = events unless @no_cache
    return events
  end
  def one_way?(x, y, direction)
    return one_way_internal(x, y, direction)
  end
  #--------------------------------------------------------------------------
  # ● 壁と衝突するかどうかを判定します。
  #--------------------------------------------------------------------------
  def clash_wall?(x, y, direction)
    return true if ! passable?(x, y, $game_player.reverse_dir(direction))
    return true if clash_one_way?(x, y, direction)
    return false
  end
  def clash_one_way?(x, y, direction)
    case direction
    when 2
      return true if one_way?(x, y + 1, 8)
    when 4
      return true if one_way?(x - 1, y, 6)
    when 6
      return true if one_way?(x + 1, y, 4)
    when 8
      return true if one_way?(x, y - 1, 2)
    end
    return false
  end

  def wall_index(x, y, direction)
    case direction
    when 2
      return 0 if one_way?(x, y, 8)
      return -1 if clash_one_way?(x, y, 8)
      index = wall(x, y, 8)
      return index if index >= 0
    when 4
      return 0 if one_way?(x, y, 6)
      return -1 if clash_one_way?(x, y, 6)
      index = wall(x, y, 6)
      return index if index >= 0
    when 6
      return 0 if one_way?(x, y, 4)
      return -1 if clash_one_way?(x, y, 4)
      index = wall(x, y, 4)
      return index if index >= 0
    when 8
      return 0 if one_way?(x, y, 2)
      return -1 if clash_one_way?(x, y, 2)
      index = wall(x, y, 2)
      return index if index >= 0
    end
    if passable?(x, y, $game_player.reverse_dir(direction))
      return -1
    else
      return 0
    end
  end
  def wall?(x, y, direction)
    return false if gate?(x, y, direction)
    return true if wall(x, y, direction) >= 0
    case direction
    when 2
      return wall(x, y + 1, 8) >= 0
    when 4
      return wall(x - 1, y, 6) >= 0
    when 6
      return wall(x + 1, y, 4) >= 0
    when 8
      return wall(x, y - 1, 2) >= 0
    end
  end
  def wall(x, y, direction)
    return -1 if gate?(x, y, direction)
    return 0 if clash_one_way?(x, y, direction)
    tile_id = @map.data[x, y, 0]          # タイル ID を取得
    case direction
    when 8
      return 0 if Saba::Three_D::WALL_TOP.include?(tile_id)
      return 1 if Saba::Three_D::WALL_TOP_2.include?(tile_id)
      return 0 if Saba::Three_D::WALL_TOP_3.include?(tile_id)
      return 1 if Saba::Three_D::WALL_TOP_4.include?(tile_id)
      return 0 if Saba::Three_D::WALL_TOP_5.include?(tile_id)
      return 1 if Saba::Three_D::WALL_TOP_6.include?(tile_id)
      tile_id = @map.data[x, y - 1, 0]          # タイル ID を取得
      return 0 if Saba::Three_D::WALL_BOTTOM.include?(tile_id)
      return 1 if Saba::Three_D::WALL_BOTTOM_2.include?(tile_id)
      return 0 if Saba::Three_D::WALL_BOTTOM_3.include?(tile_id)
      return 1 if Saba::Three_D::WALL_BOTTOM_4.include?(tile_id)
      return 0 if Saba::Three_D::WALL_BOTTOM_5.include?(tile_id)
      return 1 if Saba::Three_D::WALL_BOTTOM_6.include?(tile_id)
    when 2
      return 0 if Saba::Three_D::WALL_BOTTOM.include?(tile_id)
      return 1 if Saba::Three_D::WALL_BOTTOM_2.include?(tile_id)
      return 0 if Saba::Three_D::WALL_BOTTOM_3.include?(tile_id)
      return 1 if Saba::Three_D::WALL_BOTTOM_4.include?(tile_id)
      return 0 if Saba::Three_D::WALL_BOTTOM_5.include?(tile_id)
      return 1 if Saba::Three_D::WALL_BOTTOM_6.include?(tile_id)
      tile_id = @map.data[x, y + 1, 0]          # タイル ID を取得
      return 0 if Saba::Three_D::WALL_TOP.include?(tile_id)
      return 1 if Saba::Three_D::WALL_TOP_2.include?(tile_id)
      return 0 if Saba::Three_D::WALL_TOP_3.include?(tile_id)
      return 1 if Saba::Three_D::WALL_TOP_4.include?(tile_id)
      return 0 if Saba::Three_D::WALL_TOP_5.include?(tile_id)
      return 1 if Saba::Three_D::WALL_TOP_6.include?(tile_id)
    when 4
      return 0 if Saba::Three_D::WALL_LEFT.include?(tile_id)
      return 1 if Saba::Three_D::WALL_LEFT_2.include?(tile_id)
      return 0 if Saba::Three_D::WALL_LEFT_3.include?(tile_id)
      return 1 if Saba::Three_D::WALL_LEFT_4.include?(tile_id)
      return 0 if Saba::Three_D::WALL_LEFT_5.include?(tile_id)
      return 1 if Saba::Three_D::WALL_LEFT_6.include?(tile_id)
      tile_id = @map.data[x - 1, y, 0]          # タイル ID を取得
      return 0 if Saba::Three_D::WALL_RIGHT.include?(tile_id)
      return 1 if Saba::Three_D::WALL_RIGHT_2.include?(tile_id)
      return 0 if Saba::Three_D::WALL_RIGHT_3.include?(tile_id)
      return 1 if Saba::Three_D::WALL_RIGHT_4.include?(tile_id)
      return 0 if Saba::Three_D::WALL_RIGHT_5.include?(tile_id)
      return 1 if Saba::Three_D::WALL_RIGHT_6.include?(tile_id)
    when 6
      return 0 if Saba::Three_D::WALL_RIGHT.include?(tile_id)
      return 1 if Saba::Three_D::WALL_RIGHT_2.include?(tile_id)
      return 0 if Saba::Three_D::WALL_RIGHT_3.include?(tile_id)
      return 1 if Saba::Three_D::WALL_RIGHT_4.include?(tile_id)
      return 0 if Saba::Three_D::WALL_RIGHT_5.include?(tile_id)
      return 1 if Saba::Three_D::WALL_RIGHT_6.include?(tile_id)
      tile_id = @map.data[x + 1, y, 0]          # タイル ID を取得
      return 0 if Saba::Three_D::WALL_LEFT.include?(tile_id)
      return 1 if Saba::Three_D::WALL_LEFT_2.include?(tile_id)
      return 0 if Saba::Three_D::WALL_LEFT_3.include?(tile_id)
      return 1 if Saba::Three_D::WALL_LEFT_4.include?(tile_id)
      return 0 if Saba::Three_D::WALL_LEFT_5.include?(tile_id)
      return 1 if Saba::Three_D::WALL_LEFT_6.include?(tile_id)
    end
    return -1
  end
  #--------------------------------------------------------------------------
  # ● ダークゾーンの中にいるかどうかを判定します。
  #--------------------------------------------------------------------------
  def dark_zone?(x, y)
    tile_id = @map.data[x, y, 2]
    return DARK_ZONE == tile_id
  end
  #--------------------------------------------------------------------------
  # ● 指定の座標から指定の向きを向いた場合、正面が扉かどうかを判定します。
  #--------------------------------------------------------------------------
  def gate_internal(x, y, direction)
    
    tile_id = @map.data[x, y, 2]          # タイル ID を取得
    case direction
    when 8
      return 0 if Saba::Three_D::GATE_TOP.include?(tile_id)
      return 1 if Saba::Three_D::GATE_TOP_2.include?(tile_id)
      return 0 if Saba::Three_D::GATE_TOP_3.include?(tile_id)
      tile_id = @map.data[x, y - 1, 2]          # タイル ID を取得
      return 0 if Saba::Three_D::GATE_BOTTOM.include?(tile_id)
      return 1 if Saba::Three_D::GATE_BOTTOM_2.include?(tile_id)
      return 0 if Saba::Three_D::GATE_BOTTOM_3.include?(tile_id)
    when 2
      return 0 if Saba::Three_D::GATE_BOTTOM.include?(tile_id)
      return 1 if Saba::Three_D::GATE_BOTTOM_2.include?(tile_id)
      return 0 if Saba::Three_D::GATE_BOTTOM_3.include?(tile_id)
      tile_id = @map.data[x, y + 1, 2]          # タイル ID を取得
      return 0 if Saba::Three_D::GATE_TOP.include?(tile_id)
      return 1 if Saba::Three_D::GATE_TOP_2.include?(tile_id)
      return 0 if Saba::Three_D::GATE_TOP_3.include?(tile_id)
    when 4
      return 0 if Saba::Three_D::GATE_LEFT.include?(tile_id)
      return 1 if Saba::Three_D::GATE_LEFT_2.include?(tile_id)
      return 0 if Saba::Three_D::GATE_LEFT_3.include?(tile_id)
      tile_id = @map.data[x - 1, y, 2]          # タイル ID を取得
      return 0 if Saba::Three_D::GATE_RIGHT.include?(tile_id)
      return 1 if Saba::Three_D::GATE_RIGHT_2.include?(tile_id)
      return 0 if Saba::Three_D::GATE_RIGHT_3.include?(tile_id)
    when 6
      return 0 if Saba::Three_D::GATE_RIGHT.include?(tile_id)
      return 1 if Saba::Three_D::GATE_RIGHT_2.include?(tile_id)
      return 0 if Saba::Three_D::GATE_RIGHT_3.include?(tile_id)
      tile_id = @map.data[x + 1, y, 2]          # タイル ID を取得
      return 0 if Saba::Three_D::GATE_LEFT.include?(tile_id)
      return 1 if Saba::Three_D::GATE_LEFT_2.include?(tile_id)
      return 0 if Saba::Three_D::GATE_LEFT_3.include?(tile_id)
    end
    return -1
  end
  #--------------------------------------------------------------------------
  # ● 指定の座標から指定の向きを向いた場合、正面が一方通行かどうかを判定します。
  #--------------------------------------------------------------------------
  def one_way_internal(x, y, direction)
    tile_id = @map.data[x, y, 2]          # タイル ID を取得
    case direction
    when 8
      return true if Saba::Three_D::ONE_WAY_TOP.include?(tile_id)
    when 2
      return true if Saba::Three_D::ONE_WAY_BOTTOM.include?(tile_id)
    when 4
      return true if Saba::Three_D::ONE_WAY_LEFT.include?(tile_id)
    when 6
      return true if Saba::Three_D::ONE_WAY_RIGHT.include?(tile_id)
    end

    return false
  end
  #--------------------------------------------------------------------------
  # ● 指定の座標のマーカーIDを返します。
  #--------------------------------------------------------------------------
  def marker(x, y, mapped)
    p x
    for event in events_xy(x, y)            # 座標が一致するイベントを調べる
      marker = event.marker(mapped)
      return marker if marker != nil && marker > 0
    end
    return 0
  end
  def name
    return @map.name
  end
  #--------------------------------------------------------------------------
  # ● 現在の状態を右回転に設定します。
  #--------------------------------------------------------------------------
  def rotate_right
    @animation_type = ROTATE_RIGHT
  end
  #--------------------------------------------------------------------------
  # ● 現在の状態を左回転に設定します。
  #--------------------------------------------------------------------------
  def rotate_left
    @animation_type = ROTATE_LEFT
  end
  #--------------------------------------------------------------------------
  # ● 現在の状態を前方移動中に設定します。
  #--------------------------------------------------------------------------
  def middle
    @animation_type = MIDDLE
  end
  #--------------------------------------------------------------------------
  # ● 現在の状態を通常状態に設定します。
  #--------------------------------------------------------------------------
  def normal
    @animation_type = NORMAL
  end

  #--------------------------------------------------------------------------
  # ● 横方向にループするか？
  #--------------------------------------------------------------------------
  alias saba_3d_setup_parallax setup_parallax
  def setup_parallax
    saba_3d_setup_parallax
    return if is_2d?
    @parallax_loop_x = false
    @parallax_loop_y = false
  end
  #--------------------------------------------------------------------------
  # ● 3D画面の場合 true を返します。
  #--------------------------------------------------------------------------
  def is_3d?
    return @wall_index != -1
  end
  #--------------------------------------------------------------------------
  # ● 2D画面の場合 true を返します。
  #--------------------------------------------------------------------------
  def is_2d?
    return @wall_index == -1
  end
  #--------------------------------------------------------------------------
  # ● 壁のタイプを配列で返します。
  #--------------------------------------------------------------------------
  def wall_types
    return @wall_types
  end
  #--------------------------------------------------------------------------
  # ○ 壁のタイプを初期化します。
  #--------------------------------------------------------------------------
  def init_wall_index
    $game_map.wall_names = $data_mapinfos[$game_map.map_id].name.scan(Saba::Three_D::REGEX_3D_WALL)
    if $game_map.wall_names.empty?
      $game_map.wall_index = -1 
    else
      $game_map.wall_index = $game_map.wall_names[0][0]
    end
  end
  #--------------------------------------------------------------------------
  # ○ FOEの行動を更新します。
  #--------------------------------------------------------------------------
  def update_foe
    @no_cache = true
    for foe in @foe_list
      foe.move
    end
    @no_cache = false
  end
end



# 3Dダンジョン内のテキスト位置をちょっと上に
class Window_Message
  #--------------------------------------------------------------------------
  # ● ウィンドウ位置の更新
  #--------------------------------------------------------------------------
  alias saba_3d_update_placement update_placement
  def update_placement
    saba_3d_update_placement
    return unless $game_map.is_3d?
    self.y = @position * (Graphics.height - height) / 2 - 50 if @position == 1
  end
end

class << DataManager
  #--------------------------------------------------------------------------
  # ● 各種ゲームオブジェクトの作成
  #--------------------------------------------------------------------------
  alias saba_3d_create_game_objects create_game_objects
  def create_game_objects
    saba_3d_create_game_objects
    $auto_mapping = Game_AutoMappingSet.new
    $dungeon = Dungeon_Setting.new
  end
  #--------------------------------------------------------------------------
  # ● セーブの実行
  #--------------------------------------------------------------------------
  alias saba_3d_save_game save_game
  def save_game(index)
    listener = $auto_mapping.listener
    sprite = $dungeon.dungeon_sprite
    $auto_mapping.listener = nil
    $dungeon.dungeon_sprite = nil
    result = saba_3d_save_game(index)
    $auto_mapping.listener = listener
    $dungeon.dungeon_sprite = sprite
    return result
  end
  #--------------------------------------------------------------------------
  # ● セーブ内容の作成
  #--------------------------------------------------------------------------
  alias saba_3d_make_save_contents make_save_contents
  def make_save_contents
    contents = saba_3d_make_save_contents

    contents[:auto_mapping]        = $auto_mapping
    contents[:dungeon_setting]     = $dungeon
    
    contents
  end
  #--------------------------------------------------------------------------
  # ● セーブ内容の展開
  #--------------------------------------------------------------------------
  alias saba_3d_extract_save_contents extract_save_contents
  def extract_save_contents(contents)
    saba_3d_extract_save_contents(contents)
    $auto_mapping        = contents[:auto_mapping]
    $dungeon             = contents[:dungeon_setting]
  end
end

class Scene_Map
  #--------------------------------------------------------------------------
  # ● 終了処理
  #--------------------------------------------------------------------------
  alias saba_3d_terminate terminate
  def terminate
    saba_3d_terminate
    $game_player.clear_input
    $game_map.normal
  end
end


class Dungeon_Setting
  attr_accessor :dungeon_sprite
  attr_accessor :darkness
  attr_accessor :move_se_enabled
  attr_accessor :move_se1
  attr_accessor :move_se1_volume
  attr_accessor :move_se1_pitch
  attr_accessor :move_se2
  attr_accessor :move_se2_volume
  attr_accessor :move_se2_pitch
  attr_accessor :clash_se
  attr_accessor :clash_se_volume
  attr_accessor :clash_se_pitch
  attr_accessor :gate_se
  attr_accessor :gate_se_volume
  attr_accessor :gate_se_pitch
  attr_accessor :bg_color
  attr_accessor :wall_color
  attr_accessor :automap_visible
  def initialize
    clear_darkness
    @move_se_enabled = Saba::Three_D::MOVE_SE_ENABLED
    @bg_color = Saba::Three_D::BG_COLOR
    @wall_color = Saba::Three_D::WALL_COLOR
    @automap_visible = true
    clear_move_se1
    clear_move_se2
    clear_clash_se
    clear_gate_se
  end
  
  def clear_darkness
    @darkness = Color.new(0, 0, 0, Saba::Three_D::DARK_ALPHA)
    @dungeon_sprite.refresh_darkness if @dungeon_sprite != nil
  end
  
  def clear_move_se1
    @move_se1 = Saba::Three_D::MOVE_SE
    @move_se1_volume = Saba::Three_D::MOVE_SE_VOLUME
    @move_se1_pitch = Saba::Three_D::MOVE_SE_PITCH
  end
  
  def clear_move_se2
    @move_se2 = Saba::Three_D::MOVE_SE2
    @move_se2_volume = Saba::Three_D::MOVE_SE2_VOLUME
    @move_se2_pitch = Saba::Three_D::MOVE_SE2_PITCH
  end
  
  def clear_clash_se
    @clash_se = Saba::Three_D::CLASH_SE
    @clash_se_volume = Saba::Three_D::CLASH_SE_VOLUME
    @clash_se_pitch = Saba::Three_D::CLASH_SE_PITCH
  end
  
  def clear_gate_se
    @gate_se = Saba::Three_D::GATE_SE
    @gate_se_volume = Saba::Three_D::GATE_SE_VOLUME
    @gate_se_pitch = Saba::Three_D::GATE_SE_PITCH
  end
  
  def darkness=(value)
    @darkness = value
    @dungeon_sprite.refresh_darkness if @dungeon_sprite != nil
  end
  
  def bg_color=(value)
    @bg_color = value
    @dungeon_sprite.refresh_darkness if @dungeon_sprite != nil
  end
  
end


class Dungeon_Sprite
  attr_writer :character_sprites
  attr_reader :map_id
  include Rotation
  def initialize
    @character_sprites = []
    @map_id = $game_map.map_id
    create_bitmaps
  end
  def visible=(b)
    return unless @sprites
    for sprite in @sprites
      sprite.visible = b
    end
  end
  #--------------------------------------------------------------------------
  # ○ スプライト初期化
  #--------------------------------------------------------------------------
  def init_sprite(viewport)
    @start_ox = Graphics.width / 2
    @offset_x = 6
    create_sprite(viewport)
    refresh
  end
  #--------------------------------------------------------------------------
  # ○ スプライト作成
  #--------------------------------------------------------------------------
  def create_sprite(viewport)
    dispose_sprites
    
    @sprites = []
    @bitmaps = []
    color = $dungeon.wall_color
    4.times do |i|
      sprite= Sprite.new(viewport)
      
      sprite.x = 0
      sprite.z = i * 2
      sprite.ox = 0
      sprite.src_rect = Rect.new(0, 0, Graphics.width, Graphics.height)
      if $game_switches[Saba::Three_D::COLORING_WALL_SWITCH]
        sprite.color.set(color.red, color.green, color.blue, color.alpha * (3 - i))
      end
      @sprites.push(sprite)
      bitmap = Bitmap.new(Graphics.width * 2, Graphics.height)
      sprite.bitmap = bitmap
      @bitmaps.push(bitmap)
    end
    @dark_zone_sprite = Sprite.new
    @dark_zone_sprite.bitmap = Cache.system("darkzone")
  end
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  def update
    return if @sprites == nil
    update_rotation
  end
  #--------------------------------------------------------------------------
  # ○ 回転中のフレーム更新
  #--------------------------------------------------------------------------
  def update_rotation
    for sprite in @sprites
        sprite.src_rect.x = src_x(@start_ox)
      
    end
  end
  def refresh
    return if @sprites == nil
    update
    refresh_3d
  end
  #--------------------------------------------------------------------------
  # ○ ３D画面再描画
  #--------------------------------------------------------------------------
  def refresh_3d
    clear_rect
    hide_all_events

    draw_background
    if $game_player.rotation_right?
      draw_rotation_right
    elsif $game_player.rotation_left?
      draw_rotation_left
    elsif $game_player.move_front?
      draw_middle
    else
      draw_normal
    end
    
    @dark_zone_sprite.visible = in_dark_zone?
  end
  #--------------------------------------------------------------------------
  # ○ 暗闇画像更新
  #--------------------------------------------------------------------------
  def refresh_darkness
    @dark.dispose
    @dark = nil
    create_dark
    refresh
  end
  #--------------------------------------------------------------------------
  # ○ ビットマップをクリア
  #--------------------------------------------------------------------------
  def clear_rect
    for bitmap in @bitmaps
      bitmap.clear_rect(0, 0, bitmap.width, bitmap.height)
    end
  end
  #--------------------------------------------------------------------------
  # ○ ダークゾーンの中にいるか？
  #--------------------------------------------------------------------------
  def in_dark_zone?
    return $game_player.in_dark_zone?
  end
  
  def hide_all_events
    for sprite in @character_sprites
      return if sprite.disposed?
      sprite.visible = false
    end
  end
end

class Game_Map
  include Rotation
  #--------------------------------------------------------------------------
  # ● 遠景表示の原点 X 座標の計算
  #--------------------------------------------------------------------------
  alias saba_3d_parallax_ox parallax_ox
  def parallax_ox(bitmap)
    return src_x(0) if is_3d?
    return saba_3d_parallax_ox(bitmap)
  end
  #--------------------------------------------------------------------------
  # ● 遠景表示の原点 Y 座標の計算
  #--------------------------------------------------------------------------
  alias saba_3d_parallax_oy parallax_oy
  def parallax_oy(bitmap)
    return 0 if is_3d?
    return saba_3d_parallax_oy(bitmap)
  end
  #--------------------------------------------------------------------------
  # ● 遠景の名前を返します。
  #    現在の状態によって、返すファイルを変更します。
  #--------------------------------------------------------------------------
  def parallax_name
    if @animation_type == MIDDLE
      return @parallax_name unless @map.parallax_loop_y
      return @parallax_name + "Forward"
    end
    return @parallax_name
  end
end

class Game_Screen
  #--------------------------------------------------------------------------
  # ● シェイクの更新
  #--------------------------------------------------------------------------
  alias saba_3d_update_shake update_shake
  def update_shake
    if $game_map.is_2d? || $game_party.in_battle
      saba_3d_update_shake
      return
    end
    # シェイクは壁が欠けない方向のみ
    if @shake_duration > 0 || @shake != 0
      delta = (@shake_power * @shake_speed * @shake_direction) / 10.0
      if @shake_duration <= 1 && @shake * (@shake + delta) < 0
        @shake = 0
      else
        @shake += delta
        @shake = 0 if @shake < 0
      end
      @shake_direction = -1 if @shake > @shake_power * 2
      @shake_direction = 1 if @shake <= 0
      @shake_duration -= 1
    end
  end
end
