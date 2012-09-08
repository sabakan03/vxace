#==============================================================================
# ■ 世界樹の迷宮っぽいバトルステータス
#   @version 0.16 2012/09/08
#   @author さば缶
#------------------------------------------------------------------------------
# 　武器防具のメモ欄に <長射程> と記述すると、
#   後列でもステート33 がつかなくなります
#==============================================================================
module Saba
  module Sekaiju
    # 最大戦闘人数
    MAX_MEMBERS = 5
    
    # 前列のキャラに自動的につくステートID
    FRONT_STATE_ID = 31
    # 後列のキャラに自動的につくステートID
    BACK_STATE_ID = 32
    #長射程の装備をしていないキャラに自動的につくステートID
    BACK_STATE_ID2 = 33
    
    # パーティーの入れ替え不可で、並び替えだけできるようになるスイッチ
    # ダンジョン内などでどうぞ
    NOT_CHANGE_PARTY_SWITCH = 133
    
    # 戦闘中、味方へのスキルにもアニメーションを表示する場合 true
    ENABLE_ACTOR_ANIME = true
    
    MAX_CHAR_NAME = 6
    
  end
end

class Game_Interpreter
  def set_front_member_size(n)
    battle_members = $game_party.battle_members
    $game_party.clear_formation
    i = 0
    for m in battle_members
      if i < n
        $game_party.add_front(m)
      else
        $game_party.add_back(m)
      end
      i += 1
    end
  end
end

class Game_Troop
  def front_members
    return alive_members
  end
  def back_members
    return alive_members
  end
  def alive_fronts
    return alive_members
  end
  def alive_backs
    return alive_members
  end
end

class Game_Party
  include Saba::Sekaiju
  attr_accessor :front_members
  attr_accessor :back_members
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  alias saba_sekaiju_initialize initialize
  def initialize
    saba_sekaiju_initialize
    clear_formation
  end
  def battle_members
    return @front_members + @back_members
  end
  #--------------------------------------------------------------------------
  # ● バトルメンバーの最大数を取得
  #--------------------------------------------------------------------------
  def max_battle_members
    return Saba::Sekaiju::MAX_MEMBERS
  end
  def clear_formation
    @front_members = []
    @back_members = []
  end
    #--------------------------------------------------------------------------
  # ● アクターを加える
  #--------------------------------------------------------------------------
  alias saba_sekaiju_add_actor add_actor
  def add_actor(actor_id)
    saba_sekaiju_add_actor(actor_id)
 
    actor = $game_actors[actor_id]
    return if battle_members.size == Saba::Sekaiju::MAX_MEMBERS
    if @front_members.size < 3
      @front_members.push(actor) unless @front_members.include?(actor)
    elsif @back_members.size < 3
      @back_members.push(actor) unless @back_members.include?(actor)
    end
    
  end
  #--------------------------------------------------------------------------
  # ● アクターを外す
  #--------------------------------------------------------------------------
  alias saba_sekaiju_remove_actor remove_actor
  def remove_actor(actor_id)
    actor = $game_actors[actor_id]
    @front_members.delete(actor)
    @back_members.delete(actor)
    saba_sekaiju_remove_actor(actor_id)
  end
  #--------------------------------------------------------------------------
  # ● 初期パーティのセットアップ
  #--------------------------------------------------------------------------
  alias saba_sekaiju_setup_starting_members setup_starting_members
  def setup_starting_members
    saba_sekaiju_setup_starting_members
    auto_arrange
  end
  def add_front(actor)
    @front_members.push(actor) unless @front_members.include?(actor)
    update_formation
  end
  def add_back(actor)
    @back_members.push(actor) unless @back_members.include?(actor)
    update_formation
  end
  def update_formation
    actors = @actors.clone
    @actors = []
    @actors += @front_members.collect {|a| a.id }
    @actors += @back_members.collect {|a| a.id }
    actors.each do |a|
      @actors.push(a) unless @actors.include?(a)
    end
  end
  def auto_arrange
    clear_formation
    
    size = [members.size, MAX_MEMBERS].min
    if size > 0
      add_front(members[0])
    end
    if size > 1
      add_front(members[1])
    end
    case size
      when 0
      when 1
      when 2
      when 3
        add_back(members[2])
      when 4
        add_back(members[2])
        add_back(members[3])
      when 5
        add_front(members[2])
        add_back(members[3])
        add_back(members[4])
      else
        add_front(members[2])
        add_back(members[3])
        add_back(members[4])
        add_back(members[5])
    end
  end
  #--------------------------------------------------------------------------
  # ● 生存している前衛の配列取得
  #--------------------------------------------------------------------------
  def alive_fronts
    front_members.select {|member| member.alive? }
  end
  #--------------------------------------------------------------------------
  # ● 生存している後衛の配列取得
  #--------------------------------------------------------------------------
  def alive_backs
    back_members.select {|member| member.alive? }
  end
end

class Game_Actor
  attr_accessor :screen_x
  attr_accessor :screen_y
  attr_accessor :screen_z
  def screen_x
    @screen_x = 0 if @screen_x == nil
    return @screen_x
  end
  def screen_y
    @screen_y = 0 if @screen_y == nil
    return @screen_y
  end
  def screen_z
    @screen_z = 10 if @screen_z == nil
    return @screen_z
  end
  #--------------------------------------------------------------------------
  # ● ステートのターンカウント更新
  #--------------------------------------------------------------------------
  alias saba_sekaiju_update_state_turns update_state_turns
  def update_state_turns
    states.each do |state|
      @state_turns[state.id] = -1 unless @state_turns[state.id]
    end
    saba_sekaiju_update_state_turns
  end
  #--------------------------------------------------------------------------
  # ● ステート情報をクリア
  #--------------------------------------------------------------------------
  alias saba_sekaiju_clear_states clear_states
  def clear_states
    saba_sekaiju_clear_states
    @state_turns[Saba::Sekaiju::FRONT_STATE_ID] = -1
    @state_turns[Saba::Sekaiju::BACK_STATE_ID] = -1
    @state_turns[Saba::Sekaiju::BACK_STATE_ID2] = -1
  end
  #--------------------------------------------------------------------------
  # ○ 前列か？
  #--------------------------------------------------------------------------
  def front?
    return $game_party.front_members.include?(self)
  end
  #--------------------------------------------------------------------------
  # ○ 後列か？
  #--------------------------------------------------------------------------
  def back?
    return ! front?
  end
  #--------------------------------------------------------------------------
  # ● 現在のステートをオブジェクトの配列で取得
  #--------------------------------------------------------------------------
  def states
    ret = @states.collect {|id| $data_states[id] }
    return ret unless $game_party.in_battle
    if front?
      ret.push($data_states[Saba::Sekaiju::FRONT_STATE_ID]) 
    else
      ret.push($data_states[Saba::Sekaiju::BACK_STATE_ID]) 
      unless equip_back_attack?
        ret.push($data_states[Saba::Sekaiju::BACK_STATE_ID2]) 
      end
    end
    return ret
  end
  def use_sprite?
    return Saba::Sekaiju::ENABLE_ACTOR_ANIME
  end
  #--------------------------------------------------------------------------
  # ○ 長射程の武器防具を装備しているか？
  #--------------------------------------------------------------------------
  def equip_back_attack?
    @equips.each do |item|
      next unless item.object
      return true if item.object.can_back_attack?
    end
    return false
  end
end

class Game_Enemy
  #--------------------------------------------------------------------------
  # ○ 前列か？
  #--------------------------------------------------------------------------
  def front?
    return true
  end
  #--------------------------------------------------------------------------
  # ○ 後列か？
  #--------------------------------------------------------------------------
  def back?
    return false
  end
end

class Scene_Menu
  def create_status_window
    @status_window = Window_BattleStatus.new
    @status_window.visible = true
    @status_window.x = (Graphics.width - @status_window.width) / 2
    @status_window.y = Graphics.height - 120
  end
  #--------------------------------------------------------------------------
  # ● 並び替え［決定］
  #--------------------------------------------------------------------------
  def command_formation
    SceneManager.call(Scene_ChangeFormation)
  end
  #--------------------------------------------------------------------------
  # ● ゴールドウィンドウの作成
  #--------------------------------------------------------------------------
  alias saba_sekaiju_create_gold_window create_gold_window
  def create_gold_window
    saba_sekaiju_create_gold_window
    @gold_window.x = Graphics.width - @gold_window.width
    @gold_window.y = 0
  end
end

class Scene_ItemBase < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● アクターウィンドウの作成
  #--------------------------------------------------------------------------
  def create_actor_window
    @actor_window = Window_BattleStatus.new
    @actor_window.visible = true
    @actor_window.x = (Graphics.width - @actor_window.width) / 2
    @actor_window.y = Graphics.height - 120
    @actor_window.set_handler(:ok,     method(:on_actor_ok))
    @actor_window.set_handler(:cancel, method(:on_actor_cancel))
  end
  #--------------------------------------------------------------------------
  # ● サブウィンドウの表示
  #--------------------------------------------------------------------------
  def show_sub_window(window)
    window.activate
  end
  #--------------------------------------------------------------------------
  # ● サブウィンドウの非表示
  #--------------------------------------------------------------------------
  def hide_sub_window(window)
    window.deactivate
    activate_item_window
  end
end


class Scene_Item
  #--------------------------------------------------------------------------
  # ● アイテムウィンドウの作成
  #--------------------------------------------------------------------------
  def create_item_window
    wy = @category_window.y + @category_window.height
    wh = Graphics.height - wy - 120
    @item_window = Window_ItemList.new(0, wy, Graphics.width, wh)
    @item_window.viewport = @viewport
    @item_window.help_window = @help_window
    @item_window.set_handler(:ok,     method(:on_item_ok))
    @item_window.set_handler(:cancel, method(:on_item_cancel))
    @category_window.item_window = @item_window
  end
end

class Scene_Skill < Scene_ItemBase
  #--------------------------------------------------------------------------
  # ● アイテムウィンドウの作成
  #--------------------------------------------------------------------------
  def create_item_window
    wx = 0
    wy = @status_window.y + @status_window.height
    ww = Graphics.width
    wh = Graphics.height - wy - 120
    @item_window = Window_SkillList.new(wx, wy, ww, wh)
    @item_window.actor = @actor
    @item_window.viewport = @viewport
    @item_window.help_window = @help_window
    @item_window.set_handler(:ok,     method(:on_item_ok))
    @item_window.set_handler(:cancel, method(:on_item_cancel))
    @command_window.skill_window = @item_window
  end
end

class Window_BattleActor < Window_BattleStatus
  #--------------------------------------------------------------------------
  # ● ウィンドウの表示
  #--------------------------------------------------------------------------
  def show
    if @info_viewport
      @ox = @info_viewport.ox
      @info_viewport.ox = self.width + @ox
      @info_viewport.rect.x = self.width
      select(0)
    end
    super
  end
    #--------------------------------------------------------------------------
  # ● ウィンドウの非表示
  #--------------------------------------------------------------------------
  def hide
    @info_viewport.rect.x = 0 if @info_viewport
    @info_viewport.ox = @ox if @info_viewport
    deactivate
    super
  end
end

class Window_BattleStatus
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  alias saba_sekaiju_initialize initialize
  def initialize
    @windows = []
    saba_sekaiju_initialize
    self.opacity = 0
    self.openness = 255
    self.visible = false
    self.arrows_visible = false
  end
  #--------------------------------------------------------------------------
  # ● 表示行数の取得
  #--------------------------------------------------------------------------
  def visible_line_number
    return 4
  end
  #--------------------------------------------------------------------------
  # ● 項目数の取得
  #--------------------------------------------------------------------------
  def item_max
    @windows.size
  end
  #--------------------------------------------------------------------------
  # ● カーソルを 1 ページ後ろに移動
  #--------------------------------------------------------------------------
  def cursor_pagedown
    return cursor_up if @index >= 10
    select(item_max - 1)
  end
  #--------------------------------------------------------------------------
  # ● カーソルを 1 ページ前に移動
  #--------------------------------------------------------------------------
  def cursor_pageup
    return cursor_up if @index >= 10
    select(0)
  end
  #--------------------------------------------------------------------------
  # ● カーソルを下に移動
  #--------------------------------------------------------------------------
  def cursor_down(wrap = false)
    cursor_up(wrap)
  end
  #--------------------------------------------------------------------------
  # ● カーソルを上に移動
  #--------------------------------------------------------------------------
  def cursor_up(wrap = false)
    return if @index == 20 || @index == 21
    return select(11) if @index == 10
    return select(10) if @index == 11
    if $game_party.front_members.size > @index
        @index += $game_party.front_members.size
        @index = $game_party.battle_members.size - 1 if @index >= $game_party.battle_members.size
        @index = 2 if $game_party.back_members.size == 3 && $game_party.front_members.size == 1
      else
        @index -= $game_party.front_members.size
        @index = 0 if @index < 0
        @index = $game_party.front_members.size - 1 if @index >= $game_party.front_members.size
        @index = 1 if $game_party.back_members.size == 1 && $game_party.front_members.size == 3
     end
     select(@index)
  end
  #--------------------------------------------------------------------------
  # ● カーソルを右に移動
  #--------------------------------------------------------------------------
  def cursor_right(wrap = false)
    return if @index >= 10
    if $game_party.battle_members.size <= index + 1
      select(0)
    else
      select(index + 1)
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルを左に移動
  #--------------------------------------------------------------------------
  def cursor_left(wrap = false)
    return if @index >= 10
    if index == 0
      select($game_party.battle_members.size - 1)
    else
      select(index - 1)
    end
  end
  #--------------------------------------------------------------------------
  # ● 項目の選択
  #--------------------------------------------------------------------------
  def select(index)
    @index = index
    if @index == 10 || @index == 20
      @windows.each { |w| w.select(w.actor.front?) }
      return
    elsif @index == 11 || @index == 21
      @windows.each { |w| w.select(w.actor.back?) }
      return
    end
    if @cursor_all
      @windows.each { |w| w.select(true) }
      return
    end
    unselect
    
    @index = 0 if item_max <= @index

    @windows[@index].select(true)
    call_handler(:change)
  end
  #--------------------------------------------------------------------------
  # ● カーソルの更新
  #--------------------------------------------------------------------------
  def update_cursor
    # 何もしない
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    @windows.each { |w| w.update }
  end
  #--------------------------------------------------------------------------
  # ● 項目の選択解除
  #--------------------------------------------------------------------------
  def unselect
    @windows.each { |w| w.select(false) }
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    if @last_fronts != $game_party.front_members.size || @last_backs != $game_party.back_members.size
       create_windows
       self.visible = true
       update
    else
       @windows.each { |w| w.refresh}
    end
  end
  #--------------------------------------------------------------------------
  # ○ サブウィンドウの作成
  #--------------------------------------------------------------------------
  def create_windows
    @last_fronts = $game_party.front_members.size
    @last_backs = $game_party.back_members.size
    
    @windows.each { |w| w.dispose }

    @windows.clear

    $game_party.front_members.each_with_index do |actor, i|

      start = start_x($game_party.front_members.size)
      window = Window_BattleActorStatus.new(self.viewport, actor, i, start + i * subwindow_width, 0, subwindow_width)
      @windows.push(window)
    end
    
    $game_party.back_members.each_with_index do |actor, i|
      start = start_x($game_party.back_members.size)
      window = Window_BattleActorStatus.new(self.viewport, actor, i, start + i * subwindow_width, 60, subwindow_width)
      @windows.push(window)
    end
    
    @windows.each { |w| 
      w.parent_x = self.x
      w.parent_y = self.y
      w.visible = self.visible && open?
    }
  end
  #--------------------------------------------------------------------------
  # ○ サブウィンドウの幅取得
  #--------------------------------------------------------------------------
  def subwindow_width
    return self.width / 3 + 1
  end
  #--------------------------------------------------------------------------
  # ○ サブウィンドウの左端の座標取得
  #--------------------------------------------------------------------------
  def start_x(member_count)
    case member_count
      when 1
        return subwindow_width
      when 2
        return subwindow_width / 2
      else
        return 0
    end
  end
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #--------------------------------------------------------------------------
  def draw_item(index)
    # 何もしない
  end
  def viewport=(arg)
    super
    @windows.each { |w| w.viewport = arg }
  end
  def y=(arg)
    @windows.each { |w| w.parent_y = arg}
    super
  end
  def x=(arg)
    @windows.each { |w| w.parent_x = arg}
    super
  end
  def visible=(arg)
    @windows.each { |w| w.visible = arg; w.update}
    super
  end
  def close
    @windows.each { |w| w.visible = false}
    super
  end
  def open
    @windows.each { |w| w.visible = true}
    super
  end
  def dispose
    @windows.each { |w| w.dispose }
    super
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウの表示
  #--------------------------------------------------------------------------
  def show
    @windows.each { |w| w.visible = true}
    return super
  end
  #--------------------------------------------------------------------------
  # ● 決定ボタンが押されたときの処理
  #--------------------------------------------------------------------------
  def process_ok
    unless $game_party.in_battle
      if index < 10
        $game_party.menu_actor = $game_party.members[index]
        $game_party.target_actor = $game_party.members[index] unless @cursor_all
      end
    end
    Input.update
    Sound.play_ok
    call_ok_handler
  end
  #--------------------------------------------------------------------------
  # ● 前回の選択位置を復帰
  #--------------------------------------------------------------------------
  def select_last
    select($game_party.target_actor.index || 0)
  end
  #--------------------------------------------------------------------------
  # ● アイテムのためのカーソル位置設定
  #--------------------------------------------------------------------------
  def select_for_item(item)
    
    if item.for_friend?
      if item.target_front?
        select(20)
        return
      elsif item.target_back?
        select(21)
        return
      elsif item.target_line?
        select(10)
        return
      end
    end
    
    @cursor_fix = item.for_user? && $game_party.in_battle
    @cursor_all = item.for_all?
    if @cursor_fix
      select($game_party.menu_actor.index)
    elsif @cursor_all
      select(0)
    else
      select_last
    end
  end
  def deactivate
    super
    unselect
  end
end

class Window_BattleActorStatus < Window_Base
  def initialize(viewport, actor, index, x, y, width)
    width += 1 if index == 2
    super(x, y, width, 60)
    @start_x = x
    @start_y = y
   
    @actor = actor
    if @actor
      @actor.screen_x = @start_x + 140
      @actor.screen_y = @start_y + 410
    end
   
    self.viewport = viewport
    refresh
  end
  def actor
    return @actor
  end
  def parent_x=(arg)
    self.x = arg + @start_x
  end
  def parent_y=(arg)
    self.y = arg + @start_y
  end
  def select(b)
    if b
      self.windowskin = Cache.system("ActiveWindow2")
    else
      self.windowskin = Cache.system("Window")
    end
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    contents.clear
    return unless @actor

    draw_actor_hp(actor, 6 ,22, 69)
    draw_actor_mp(actor, 83, 22, 69)
    draw_actor_tp(actor, 6, 2, 69) if $data_system.opt_display_tp
    
    draw_actor_name(@actor, 6, 0, 78)
    draw_actor_icons(@actor, 86, 0, 80)
  end
  #--------------------------------------------------------------------------
  # ● TP の描画
  #--------------------------------------------------------------------------
  def draw_actor_tp(actor, x, y, width = 124)
    draw_gauge(x, y, width, actor.tp_rate, tp_gauge_color1, tp_gauge_color2)
  end
  #--------------------------------------------------------------------------
  # ● 標準パディングサイズの取得
  #--------------------------------------------------------------------------
  def standard_padding
    return 6
  end
end


class Spriteset_Battle
  #--------------------------------------------------------------------------
  # ● ビューポートの作成
  #--------------------------------------------------------------------------
  alias saba_sekaiju_create_viewports create_viewports
  def create_viewports
    saba_sekaiju_create_viewports
    @viewport_sekaiju = Viewport.new
    @viewport_sekaiju.z = 200
  end
  #--------------------------------------------------------------------------
  # ● ビューポートの解放
  #--------------------------------------------------------------------------
  alias saba_sekaiju_dispose_viewports dispose_viewports
  def dispose_viewports
    saba_sekaiju_dispose_viewports
    @viewport_sekaiju.dispose
  end
  #--------------------------------------------------------------------------
  # ● ビューポートの更新
  #--------------------------------------------------------------------------
  alias saba_sekaiju_update_viewports update_viewports
  def update_viewports
    saba_sekaiju_update_viewports
    @viewport_sekaiju.ox = $game_troop.screen.shake
    @viewport_sekaiju.update
  end
  def create_actors
    @actor_sprites = Array.new($game_party.battle_members.size) { Sprite_Battler.new(@viewport_sekaiju) }
  end
end

class Scene_Battle
  #--------------------------------------------------------------------------
  # ● アクター選択の開始
  #--------------------------------------------------------------------------
  alias saba_sekaiju_select_actor_selection select_actor_selection
  def select_actor_selection
    saba_sekaiju_select_actor_selection
    item = @item ? @item : @skill
    if item.for_friend?
      if item.target_front?
        @actor_window.select(20)

      elsif item.target_back?
        @actor_window.select(21)
      elsif item.target_line?
        @actor_window.select(10)
      end
    end
  end
end

class Scene_ItemBase
  #--------------------------------------------------------------------------
  # ● アイテムの使用対象となるアクターを配列で取得
  #--------------------------------------------------------------------------
  alias saba_sekaiju_item_target_actors item_target_actors
  def item_target_actors

    saba_sekaiju_item_target_actors
    if !item.for_friend?
      []
    elsif item.for_all?
      $game_party.members
    else
      if @actor_window.index == 10 || @actor_window.index == 20
        $game_party.front_members
      elsif @actor_window.index == 11 || @actor_window.index == 21
        $game_party.back_members
      else
        [$game_party.members[@actor_window.index]]
      end
    end
  end
end

class Game_Action
  #--------------------------------------------------------------------------
  # ● 敵に対するターゲット
  #--------------------------------------------------------------------------
  alias saba_sekaiju_targets_for_opponents targets_for_opponents
  def targets_for_opponents
    if @target_index == 10 or @target_index == 20 or item.target_front?
      members = opponents_unit.alive_fronts
    elsif @target_index == 11 or @target_index == 21 or item.target_back?
      members = opponents_unit.alive_backs
    elsif item.target_line?
      if rand(2) == 0
        members = opponents_unit.alive_fronts
      else
        members = opponents_unit.alive_backs
      end
    end
    
    if members
      if members.size == 0
        members = opponents_unit.alive_members
      end
      if item.for_all?
        return members
      elsif item.for_random?
        return Array.new(item.number_of_targets) { 
          members[rand(members.size)] 
        }
      elsif item.for_one?
        num = 1 + (attack? ? subject.atk_times_add.to_i : 0)
        if @target_index < 0
          return [members[rand(members.size)]] * num
        else
          return [opponents_unit.smooth_target(@target_index)] * num
        end
      end
    end

    saba_sekaiju_targets_for_opponents
  end
  #--------------------------------------------------------------------------
  # ● 味方に対するターゲット
  #--------------------------------------------------------------------------
  alias saba_sekaiju_targets_for_friends targets_for_friends
  def targets_for_friends
    if @target_index == 10 or @target_index == 20 or item.target_front?
      return friends_unit.front_members
    elsif @target_index == 11 or @target_index == 21 or item.target_back?
      return friends_unit.back_members
    end
    
    saba_sekaiju_targets_for_friends
  end
end

class Sprite_Base
    #--------------------------------------------------------------------------
  # ● アニメーションの原点設定
  #--------------------------------------------------------------------------
  def set_animation_origin
    if @animation.position == 3
      if viewport == nil
        @ani_ox = Graphics.width / 2
        @ani_oy = Graphics.height / 2
      else
        @ani_ox = viewport.rect.width / 2
        @ani_oy = viewport.rect.height / 2
      end
      @ani_oy += 200 if @battler && @battler.actor?
    else
      @ani_ox = x - ox + width / 2
      @ani_oy = y - oy + height / 2
      if @animation.position == 0
        @ani_oy -= height / 2
      elsif @animation.position == 2
        @ani_oy += height / 2
      end
    end
  end
end
class RPG::BaseItem
  def target_line?
    if @target_line == nil
      @target_line = false
      if note.include?("<列>")
        @target_line = true
      end
    end
    return @target_line
  end
  
  def target_front?
    if @target_front == nil
      @target_front = false
      if note.include?("<前列>")
        @target_front = true
      end
    end
    return @target_front
  end
  
  def target_back?
    if @target_back == nil
      @target_back = false
      if note.include?("<後列>")
        @target_back = true
      end
    end
    return @target_back
  end
  
  def can_back_attack?
    return note.include?("<長射程>")
  end
end

class << DataManager
  #--------------------------------------------------------------------------
  # ● 通常のデータベースをロード
  #--------------------------------------------------------------------------
  alias saba_sekaiju_load_normal_database load_normal_database
  def load_normal_database
    saba_sekaiju_load_normal_database

    if $data_states[Saba::Sekaiju::FRONT_STATE_ID] == nil || $data_states[Saba::Sekaiju::BACK_STATE_ID2] == nil
      msgbox_p "Error!! 世界樹の迷宮っぽいステータス画面プロジェクトからステート31～33をコピーしてください"
    end
  end
end

class Sprite_Battler
  #--------------------------------------------------------------------------
  # ● 可視状態の初期化
  #--------------------------------------------------------------------------
  alias saba_sekaiju_init_visibility init_visibility
  def init_visibility
    saba_sekaiju_init_visibility
    self.opacity = 255 if @battler.actor?
  end
end