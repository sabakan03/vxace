#==============================================================================
# ■ 碧の軌跡っぽい戦闘システム18
#   @version 0.28 12/08/16
#   @author さば缶
#------------------------------------------------------------------------------
# 　
# ■使い方
# 　★★★★データベースのスキル 001～010が必要です。★★★★
# 　コピーして使ってください。
#
#   攻撃(001)      … 通常攻撃の駆動時間や硬直時間の設定
#                     そのほか、<硬直>や<駆動>が指定されていないスキルは
#                     このスキルの値が使われる
#   防御(002)      … 防御の硬直時間の設定
#   逃走(003)      … 逃走の硬直時間の設定
# 　戦闘開始(004)  … 戦闘開始時の初期待ち時間の設定
#   復活(005)      … 生き返ったときの初期待ち時間の設定
#   キャンセル(006)… スキルがキャンセルされた後の待ち時間の設定
#   先制(007)      … 先制したキャラの戦闘開始時の初期待ち時間の設定
#                     "戦闘開始(004)"のかわりに使われる
#   行動不能(008)  … スタンなどで行動不能なときと復帰したとき
#
# 　★★★★グラフィックが必要です。★★★★
#   "Graphics/System"をコピーして使ってください。
#   また、敵のターゲットを消したい場合はTarget.pngを透明な画像と差し替えてください
# 　
#
# ■スキルやアイテムのメモ欄に書けるもの一覧（詳細は実際のスキルのサンプルで）
#   <硬直>          … スキル実行後の待ち時間の計算式
#   <駆動>          … スキルが駆動されるまでの待ち時間の計算式
#   <駆動msg>       … スキルが駆動待ちになったときに表示するメッセージ
#                      <駆動>があるスキルのみで使われる
#   <ステート>      … スキルが駆動待ちの間、自動で付与されるステート
#                      スキル駆動またはキャンセルで解除される
#                      <駆動>があるスキルのみで使われる
#   <キャンセル>    … スキルを当てた対象のスキル駆動を中断させる
#   <キャンセル率>  … <キャンセル>が書いてあるときのみ有効、
#                      この確率でキャンセルがかかる。100%の場合は100
#   <キャンセル不可>… このスキルは<キャンセル>されない
#   <ディレイコマ数>… スキルを当てた対象を指定のコマ数後ろに下げる
#                      マイナスならその分進める
#   <ディレイ率>    … <ディレイコマ数>が書いてあるときのみ有効、
#                      この確率でディレイがかかる。100%の場合は100
#
# ■アクターやエネミーのメモ欄に書けるもの一覧
#   <キャンセル不可>… このキャラは<キャンセル>されない
#   <ディレイ不可>  … このキャラはディレイがかからない
#
#==============================================================================
module Saba
  module Kiseki
    # 敵キャラのメモ欄にグラフィック指定がない場合のグラフィック名です。
    DEFAULT_MONSTER_GRAPHIC_NAME = "Monster1"
    
    # 敵キャラのメモ欄にグラフィック指定がない場合のインデックス番号です。
    DEFAULT_MONSTER_GRAPHIC_INDEX = 3
    
    # 敵キャラのメモ欄にこの文字を入れると、空白をはさんで続く文字がグラフィック名、
    # さらに空白をはさんで続く文字がグラフィック内のインデックス番号になります。
    GRAPHIC_MARKER = "GRAPHIC"
    
    # 素早さが待ち時間に与える影響力です。0以上の整数を設定してください。単位は%。
    # 100 でデフォルト、120でデフォルトの1.2倍、50でデフォルトの半分です。
    SPEED_INFLUENCE = 100
    
    # デバッグ表示
    # キャラの素早さ偏差値がみれます
    DEBUG = false
    
    # デフォルトのスキル準備メッセージ
    DEFAULT_PREPARE_MSG = "%sは%sの準備をしている！"
    
    # 駆動SE
    OPERATE_SE_FILE = "Audio/SE/Heal4"
    # 駆動SEの音量
    OPERATE_SE_VOLUME = 80
    # 駆動SEのピッチ
    OPERATE_SE_PITCH = 150
  end
end

class Scene_Battle
  include Saba::Kiseki
  #--------------------------------------------------------------------------
  # ● 開始処理
  #--------------------------------------------------------------------------
  alias saba_kiseki_start start
  def start
    $game_party.clear_results
    calculate_battlers_speed
    OrderManager.init_unit
    saba_kiseki_start
  end
  #--------------------------------------------------------------------------
  # ○ バトラーの速度偏差値を求めます。
  #--------------------------------------------------------------------------
  def calculate_battlers_speed
    battlers = $game_party.battle_members + $game_troop.members
    
    total = 0.0
    for battler in battlers
      total += battler.agi
    end
    
    mean = total / battlers.size
    standard_deviation = 0.0

    for battler in battlers
      standard_deviation += (battler.agi - mean) * (battler.agi - mean)
    end
    
    standard_deviation /= battlers.size
    standard_deviation = Math.sqrt(standard_deviation)
    for battler in battlers
      if standard_deviation != 0
        battler.spd = ((battler.agi - mean) / standard_deviation) * 10
      else
        battler.spd = 0
      end
      battler.spd *= (SPEED_INFLUENCE / 100.0)
      battler.spd += 50
      p  battler.name + " 速度:" + battler.agi.to_s + " 偏差値:" + battler.spd.to_i.to_s if DEBUG
    end
  end
  #--------------------------------------------------------------------------
  # ● パーティコマンド選択の開始
  #--------------------------------------------------------------------------
  def start_party_command_selection
    unless scene_changing?
      refresh_status
      @status_window.unselect
      @status_window.open
      BattleManager.input_start
      top_unit = OrderManager.top_unit
      top_unit.battler.on_turn_start 
      refresh_status
      
      @log_window.display_auto_affected_status(top_unit.battler)
      @log_window.wait_and_clear
      next_command
    end
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  alias saba_kiseki_battle_update_basic update_basic
  def update_basic
    saba_kiseki_battle_update_basic
    OrderManager.update
  end
  #--------------------------------------------------------------------------
  # ● スキルウィンドウの作成
  #--------------------------------------------------------------------------
  alias saba_kiseki_battle_create_skill_window create_skill_window
  def create_skill_window
    saba_kiseki_battle_create_skill_window
    @skill_window.set_handler(:change, method(:update_forecast))
  end
  #--------------------------------------------------------------------------
  # ● アイテムウィンドウの作成
  #--------------------------------------------------------------------------
  alias saba_kiseki_battle_create_item_window create_item_window
  def create_item_window
    saba_kiseki_battle_create_item_window
    @item_window.set_handler(:change, method(:update_forecast))
  end
  #--------------------------------------------------------------------------
  # ● アクターコマンドウィンドウの作成
  #--------------------------------------------------------------------------
  alias saba_kiseki_battle_create_actor_command_window create_actor_command_window
  def create_actor_command_window
    saba_kiseki_battle_create_actor_command_window
    @actor_command_window.set_handler(:change, method(:update_forecast))
  end
  #--------------------------------------------------------------------------
  # ● アクターウィンドウの作成
  #--------------------------------------------------------------------------
  alias saba_kiseki_battle_create_actor_window create_actor_window
  def create_actor_window
    saba_kiseki_battle_create_actor_window
    @actor_window.set_handler(:change, method(:update_selection))
  end
  #--------------------------------------------------------------------------
  # ● 敵キャラウィンドウの作成
  #--------------------------------------------------------------------------
  alias saba_kiseki_battle_create_enemy_window create_enemy_window
  def create_enemy_window
    saba_kiseki_battle_create_enemy_window
    @enemy_window.set_handler(:change, method(:update_selection))
  end
  #--------------------------------------------------------------------------
  # ○ 選択状態の更新
  #--------------------------------------------------------------------------
  def update_selection
    OrderManager.clear_selection
    OrderManager.select(@enemy_window.enemy) if @enemy_window.active
    OrderManager.select(@actor_window.actor) if @actor_window.active
  end
  #--------------------------------------------------------------------------
  # ○ 順番予測更新
  #--------------------------------------------------------------------------
  def update_forecast
    OrderManager.clear_selection
    actor = BattleManager.actor
    case @actor_command_window.current_symbol
      when :attack
        item = $data_skills[actor.attack_skill_id]
      when :guard
        item = $data_skills[actor.guard_skill_id]
      when :skill
        item = @skill_window.item if @skill_window.visible
      when :item
        item = @item_window.item if @item_window.visible
      when :escape
        item = $data_skills[3]
    end
    return OrderManager.remove_forecast_unit if item == nil
    update_forecast_item(item)
  end
  #--------------------------------------------------------------------------
  # ○ 指定のアイテムの順番予測更新
  #--------------------------------------------------------------------------
  def update_forecast_item(item)
    battler = OrderManager.top_unit.battler
    item = $data_skills[battler.attack_skill_id] if item == nil
    operate_time = item.operate_time(battler)
    unit = OrderManager.forecast_unit
    return if unit && unit.battler == battler && unit.usable_item == item
    
    OrderManager.remove_forecast_unit
    
    if operate_time > 0 && ! OrderManager.top_unit.operate
      if battler.state_operate_time == nil
        OrderManager.insert(battler, operate_time, true, item, true)
      else
        OrderManager.insert(battler, battler.state_operate_time, true, item, true)
      end
      OrderManager.show_targeted(battler) if battler.enemy?
    else
      if battler.state_stiff_time == nil
        stiff_time = item.stiff_time(battler)
        OrderManager.insert(battler, stiff_time, true, item)
      else
        OrderManager.insert(battler, battler.state_stiff_time, true, item)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● ターン開始
  #--------------------------------------------------------------------------
  alias saba_kiski_battle_turn_start turn_start
  def turn_start
    OrderManager.clear_selection
    battler = OrderManager.top_unit.battler
    
    $game_troop.clear_results
    $game_party.clear_results
    
    if battler.current_action != nil
      item = battler.current_action.item
      update_forecast_item(item)
    else
      update_forecast_item($data_skills[8])
    end
    saba_kiski_battle_turn_start
    if item != nil && item.operate_time(battler) > 0 &&
       OrderManager.top_unit.operate != true
       play_operate_se
       refresh_status
      @log_window.display_prepare_item(battler, item)
    end
  end
  #--------------------------------------------------------------------------
  # ○ 駆動SE再生
  #--------------------------------------------------------------------------
  def play_operate_se
    Audio.se_play(OPERATE_SE_FILE, OPERATE_SE_VOLUME, OPERATE_SE_PITCH)
  end
  #--------------------------------------------------------------------------
  # ● ターン終了
  #--------------------------------------------------------------------------
  def turn_end
    all_battle_members.each do |battler|
      battler.on_turn_end
      if battler.result.status_affected?
        refresh_status
        @log_window.display_auto_affected_status(battler)
        @log_window.wait_and_clear
      end
    end
    BattleManager.turn_end
    process_event
    start_party_command_selection
    calculate_battlers_speed
  end
  #--------------------------------------------------------------------------
  # ● スキル／アイテムの使用(再定義！)
  #--------------------------------------------------------------------------
  alias saba_kiski_battle_use_item use_item
  def use_item
    item = @subject.current_action.item
    @log_window.display_use_item(@subject, item)
    @subject.use_item(item)
    refresh_status
    targets = @subject.current_action.make_targets.compact
    show_animation(targets, item.animation_id)
    targets.each {|target| item.repeats.times { invoke_item(target, item) } }
  
    targets.each do |target|
      delay = target.result.delay_count
      if delay != 0
        OrderManager.delay_order(target, delay) 
        #@log_window.display_delay(target, delay) 
      end
      unit = OrderManager.find_unit(target)
      if unit && unit.cancel?
        unit.battler.turn_count += 1
        OrderManager.cancel(unit)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 戦闘行動終了時の処理
  #--------------------------------------------------------------------------
  alias saba_kiski_battle_process_action_end process_action_end
  def process_action_end
    OrderManager.update_delay_time
    if BattleManager.battle_end?
      OrderManager.remove_forecast_unit
    end
    saba_kiski_battle_process_action_end
  end
end

class Window_ActorCommand
  def cancel_enabled?
    return false
  end
end

class Spriteset_Battle
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  alias saba_kiseki_battle_initialize initialize
  def initialize
    @battle_units = {}
    saba_kiseki_battle_initialize
    @viewport3.rect.height = Saba::Kiseki::ORDER_BAR_HEIGHT
    @kiseki_sprite = Spriteset_Kiseki.new(@viewport3)
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  alias saba_kiseki_battle_update update
  def update
    saba_kiseki_battle_update
    update_battle_unit
    @kiseki_sprite.update if @kiseki_sprite
  end
  #--------------------------------------------------------------------------
  # ○ ユニット更新
  #--------------------------------------------------------------------------
  def update_battle_unit
    remove_list = @battle_units.keys
    OrderManager.units.each do |unit|
      if @battle_units[unit] == nil
        @battle_units[unit] = Spriteset_BattleUnit.new(@viewport3, unit)
      else
        remove_list.delete(unit)
      end
      @battle_units[unit].update
    end
    remove_list.each { |unit|
      sprite = @battle_units[unit]
      sprite.dispose
      @battle_units.delete(unit)
    }
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  alias saba_kiseki_battle_dispose dispose
  def dispose
    @battle_units.values.each { |sprite| sprite.dispose }
    @kiseki_sprite.dispose
    saba_kiseki_battle_dispose
  end
end

class Window_Selectable
  #--------------------------------------------------------------------------
  # ● 項目の選択
  #--------------------------------------------------------------------------
  alias saba_kiseki_battle_select select
  def select(index)
    saba_kiseki_battle_select(index)
    call_handler(:change)
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウのアクティブ化
  #--------------------------------------------------------------------------
  def activate
    super
    call_handler(:change)
    self
  end
end

class Game_ActionResult
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :delay_count
  attr_accessor :cancel
  attr_accessor :fail_cancel
  attr_accessor :anti_cancel
  attr_accessor :fail_delay
  attr_accessor :anti_delay
  #--------------------------------------------------------------------------
  # ● クリア
  #--------------------------------------------------------------------------
  alias saba_kiseki_battle_clear clear
  def clear
    saba_kiseki_battle_clear
    @delay_count = 0
    @cancel = false
    @fail_cancel = false
    @anti_cancel = false
    @fail_delay = false
    @anti_delay = false
  end
end

class Game_Battler
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :spd
  attr_accessor :turn_count
  alias saba_kiseki_initialize initialize
  def initialize
    saba_kiseki_initialize
    @spd = 50
    @turn_count = 0
  end
  #--------------------------------------------------------------------------
  # ● スキル／アイテムの効果適用
  #--------------------------------------------------------------------------
  alias saba_kiseki_battle_item_apply item_apply
  def item_apply(user, item)
    saba_kiseki_battle_item_apply(user, item)
    return unless $game_party.in_battle
    if @result.hit?
      
      if user.actor? && item.is_a?(RPG::Skill) && item.id == 1
        # 通常攻撃
        total = 0
        cancel = false
        cancel_attack = false
        delay_attack = false
        
        user.weapons.each do |weapon|
          total += weapon.delay_count(user)
          delay_attack |= weapon.delay_attack?
          cancel |= weapon.cancel?
          cancel_attack |= weapon.cancel_attack?
        end
        @result.delay_count = total
        @result.cancel = cancel
      else
        @result.delay_count = item.delay_count(user)
        delay_attack = item.delay_attack?
        @result.cancel = item.cancel?
        cancel_attack = item.cancel_attack?
      end
      char = actor? ? actor : enemy
      @result.delay_count = 0 if char.anti_delay?
      if @result.delay_count > 0
        @result.delay_count = [@result.delay_count, OrderManager.max_delay_count(self)].min
      elsif @result.delay_count < 0
        @result.delay_count = [@result.delay_count, OrderManager.min_delay_count(self)].max
      elsif delay_attack
        if char.anti_delay?
          @result.anti_delay = true
        else
          @result.fail_delay = true
        end
      end
      
      unit = OrderManager.find_unit(self)

      if unit && unit.operate
        # 行動不能によるキャンセルチェック
        if ! self.movable? || self.confusion?
          @result.cancel = true
        elsif char.anti_cancel? || unit.usable_item.anti_cancel?
          # キャンセルが無効化された
          @result.anti_cancel = true if cancel_attack
          @result.cancel = false 
        elsif cancel_attack && ! @result.cancel
          # キャンセル失敗
          @result.fail_cancel = true
          @result.cancel = false 
        end
        
      else
        # もともと準備中でない
        @result.cancel = false 
      end
      
      
      if self.dead?
        @result.anti_delay = false
        @result.fail_delay = false
        @result.delay_count = 0
        @result.cancel = false
        @result.anti_cancel = false
        @result.fail_cancel = false
      end
      @result.success = true if @result.delay_count != 0 || @result.cancel
    end
  end
  #--------------------------------------------------------------------------
  # ○ ターン開始処理
  #--------------------------------------------------------------------------
  def on_turn_start
    regenerate_all
    update_state_turns
    update_buff_turns
    remove_states_auto(2)
    remove_buffs_auto
    make_actions
  end
  #--------------------------------------------------------------------------
  # ● ターン終了処理
  #--------------------------------------------------------------------------
  def on_turn_end
    @result.clear
  end
  #--------------------------------------------------------------------------
  # ● 戦闘行動終了時の処理
  #--------------------------------------------------------------------------
  def on_action_end
    @result.clear
    remove_states_auto(1)
    @turn_count += 1
  end
  #--------------------------------------------------------------------------
  # ○ ステートによる駆動時間を取得
  #--------------------------------------------------------------------------
  def state_operate_time
    n = nil
    states.reverse.each do |state|
      if state.operate_formula
        n = state.operate_time(self)
      end
    end
    return n
  end
  #--------------------------------------------------------------------------
  # ○ ステートによる硬直時間を取得
  #--------------------------------------------------------------------------
  def state_stiff_time
    n = nil
    states.reverse.each do |state|
      if state.stiff_formula
        n = state.stiff_time(self)
      end
    end
    return n
  end
end

class << BattleManager
  #--------------------------------------------------------------------------
  # ● 次のコマンド入力へ
  #--------------------------------------------------------------------------
  def next_command
    begin
      if !actor || !actor.next_command
        battler = OrderManager.top_unit.battler
        unless battler.actor?
          unless battler.current_action
            OrderManager.top_unit.usable_item = $data_skills[1]
            return false
          end
          OrderManager.top_unit.usable_item = battler.current_action.item
          return false 
        end
        return false if @actor_index == battler.index
        @actor_index = battler.index
        if OrderManager.top_unit.operate  # 発動
          OrderManager.top_unit.remove_operate_state
          battler.current_action.set_usable_item(OrderManager.top_unit.usable_item)
          return false 
        end
        return false if @actor_index >= $game_party.members.size
      end
    end until actor.inputable?
    return true
  end
  #--------------------------------------------------------------------------
  # ● 行動順序の作成
  #--------------------------------------------------------------------------
  def make_action_orders
    battler = OrderManager.top_unit.battler
    if battler.current_action == nil || battler.current_action.item == nil
      @action_battlers = [battler]
    elsif battler.current_action.item.operate_time(battler) > 0 &&
       OrderManager.top_unit.operate != true
      # 発動待ち
      OrderManager.top_unit.usable_item = battler.current_action.item
      OrderManager.top_unit.add_operate_state
      @action_battlers = []
    else
      @action_battlers = [battler]
    end
  end
  #--------------------------------------------------------------------------
  # ● ターン終了
  #--------------------------------------------------------------------------
  alias saba_kiseki_battle_turn_end turn_end
  def turn_end
    saba_kiseki_battle_turn_end
    unit = OrderManager.top_unit
    OrderManager.clear_forecast
    OrderManager.update_top
  end
end


class Game_Enemy
  #--------------------------------------------------------------------------
  # ● 戦闘行動の作成
  #--------------------------------------------------------------------------
  alias saba_kiseki_battke_make_actions make_actions
  def make_actions
    # 発動待ちを上書きしないように
    unit = OrderManager.find_unit(self)
    if unit && unit.operate
      return 
    end
    saba_kiseki_battke_make_actions
  end
  #--------------------------------------------------------------------------
  # ● 行動条件合致判定［ターン数］
  #--------------------------------------------------------------------------
  def conditions_met_turns?(param1, param2)
    n = @turn_count
    #p name + " " + @turn_count.to_s
    if param2 == 0
      n == param1
    else
      n > 0 && n >= param1 && n % param2 == param1 % param2
    end
  end
end

class Game_Actor
  #--------------------------------------------------------------------------
  # ● 戦闘行動の作成
  #--------------------------------------------------------------------------
  alias saba_kiseki_battke_make_actions make_actions
  def make_actions
    # 発動待ちを上書きしないように
    unit = OrderManager.find_unit(self)
    if unit && unit.operate
      return 
    end
    saba_kiseki_battke_make_actions
  end
end


class Window_BattleActor
  #--------------------------------------------------------------------------
  # ○ 味方キャラオブジェクト取得
  #--------------------------------------------------------------------------
  def actor
    $game_party.battle_members[@index]
  end
end

class << BattleManager
  attr_reader :preemptive
  attr_reader :surprise
  attr_reader :phase
  def battle_end?
    return true if $game_party.members.empty?
    return true if $game_party.all_dead?
    return true if $game_troop.all_dead?
    return true if aborting?
    return false
  end
end

class Game_Action
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :targets
  attr_accessor :save_targets
  #--------------------------------------------------------------------------
  # ● クリア
  #--------------------------------------------------------------------------
  alias saba_kiseki_battle_clear clear
  def clear
    saba_kiseki_battle_clear
    @targets = nil
    save_targets = false
  end
  #--------------------------------------------------------------------------
  # ● ターゲットの配列作成
  #--------------------------------------------------------------------------
  alias saba_kiseki_battle_make_targets make_targets
  def make_targets
    return @targets if @targets && @save_targets
    @targets = saba_kiseki_battle_make_targets
    return @targets
  end
  #--------------------------------------------------------------------------
  # ● アイテムを設定
  #--------------------------------------------------------------------------
  def set_usable_item(item)
    @item.object = item
    self
  end
end

#==============================================================================
# ■ Game_BattleUnit
#------------------------------------------------------------------------------
# 　画面上に表示されるコマです。
#==============================================================================
class Game_BattleUnit
  attr_accessor :battler
  attr_accessor :forecast
  attr_accessor :usable_item
  attr_accessor :operate
  attr_accessor :delay_time           # 待ち時間
  attr_accessor :delay_time_decimal   # 待ち時間の小数
  attr_accessor :x
  attr_accessor :dest_y
  attr_accessor :selected
  attr_accessor :targeted
  attr_reader :y
  #--------------------------------------------------------------------------
  # ○ オブジェクトを初期化します。
  #  init_battler このユニットが表すバトラーオブジェクト
  #  delay_time 行動までの待ち時間
  #  forecast 行動の予想ユニットかどうかのフラグ
  #  skill スキルの発動待ちかどうかのフラグ
  #--------------------------------------------------------------------------
  def initialize(battler, delay_time, forecast = false, usable_item = nil, operate = false)
    @battler = battler
    @delay_time = delay_time
    @usable_item = usable_item
    @forecast = forecast
    @operate = operate
    @dest_x = 0
    @dest_y = 0
    @speed_y = 1
    @delay_time_decimal = 0
    @x = @dest_x
    @y = 0
    @targeted = false
    @selected = false
  end
  #--------------------------------------------------------------------------
  # ○ 座標を更新
  #--------------------------------------------------------------------------
  def update
    update_x
    update_y
  end
  #--------------------------------------------------------------------------
  # ○ x 座標を更新
  #--------------------------------------------------------------------------
  def update_x
    @x = @dest_x if (@dest_x - @x).abs < 4
    @x += 4 if @dest_x > @x
    @x -= 4 if @dest_x < @x
  end
  #--------------------------------------------------------------------------
  # ○ y 座標を更新
  #--------------------------------------------------------------------------
  def update_y
    if (@dest_y - @y).abs < 3
      @y = @dest_y
      @speed_y = 1
    else
      @speed_y = 3
    end
    @y += @speed_y if @dest_y > @y
    @y -= @speed_y if @dest_y < @y
  end
  #--------------------------------------------------------------------------
  # ○ キャンセル
  #--------------------------------------------------------------------------
  def cancel
    if @operate && @usable_item
      @operate = false
      remove_operate_state
      return true
    else
      return false
    end
  end
  #--------------------------------------------------------------------------
  # ○ キャンセルチェック
  #--------------------------------------------------------------------------
  def cancel?
    return @battler.result.cancel
  end
  #--------------------------------------------------------------------------
  # ○ 他のユニットと待ち時間を比較するための値を返します。
  #    他のユニット同一の値だと、ソート時に順番が入れ替わるおそれがあるので、
  #    バトラー別に補正を掛けます。
  #--------------------------------------------------------------------------
  def delay_time_compare
    return -1 if @delay_time == 0 && @forecast #即時効果
    return @delay_time * 10000 + delay_time_decimal
  end
  def delay_time_decimal
    return 4999 if @forecast
    return @delay_time_decimal
  end
  #--------------------------------------------------------------------------
  # ○ 待ち時間を設定
  #--------------------------------------------------------------------------
  def delay_time=(value)
    @delay_time = value.round
  end
  #--------------------------------------------------------------------------
  # ○ 順番を設定
  #--------------------------------------------------------------------------
  def index=(arg)
    @index = arg
    @dest_y = arg * Saba::Kiseki::UNIT_INTERVAL
    @dest_y += Saba::Kiseki::MARGIN_CURRENT_BOTTOM if @index > 0
    init_position if @x != 0
  end
  #--------------------------------------------------------------------------
  # ○ 座標を初期化
  #--------------------------------------------------------------------------
  def init_position
    @y = @dest_y
  end
  #--------------------------------------------------------------------------
  # ○ 待ち時間に自動でかかるステートを設定
  #--------------------------------------------------------------------------
  def add_operate_state
    @usable_item.operate_states.each {|s|
      operate_state_targets.each { |b|
        b.add_state(s)
      }
    }
  end
  #--------------------------------------------------------------------------
  # ○ 待ち時間に自動でかかるステートを削除
  #--------------------------------------------------------------------------
  def remove_operate_state
    @usable_item.operate_states.each {|s| 
      operate_state_targets.each { |b|
        b.remove_state(s)
      }
    }
  end
  #--------------------------------------------------------------------------
  # ○ 待ち時間に自動でかかるステート対象を取得
  #--------------------------------------------------------------------------
  def operate_state_targets
    targets = []
    if @usable_item.operate_states_for_friends_all?
      targets += @battler.friends_unit.alive_members
    end 
    if @usable_item.operate_states_for_opponents_all?
      targets += @battler.opponents_unit.alive_members
    end
    targets = [@battler] if targets.empty?
    return targets
  end
  #--------------------------------------------------------------------------
  # ○ 攻撃対象を取得
  #--------------------------------------------------------------------------
  def targets
    return [] unless @operate
    battler.current_action.save_targets = true
    battler.current_action.make_targets
  end
end

class RPG::BaseItem
  #--------------------------------------------------------------------------
  # ○ 駆動時間の取得
  #--------------------------------------------------------------------------
  def operate_time(battler)
    operate_formula
    return 0 if @operate_formula == nil
    a = battler
    c = $game_variables
    return eval(@operate_formula).to_i
  end
  #--------------------------------------------------------------------------
  # ○ 駆動時間計算式の取得
  #--------------------------------------------------------------------------
  def operate_formula
    return @operate_formula if @get_operate_formula
    @get_operate_formula = true
    self.note.split(/[\r\n]+/).each do |line|
      if line.index("<駆動>") == 0
        @operate_formula = line["<駆動>".length..-1]
        return @operate_formula
      end
    end
    return nil if self.is_a?(RPG::State)
    @operate_formula = $data_skills[1].operate_formula
  end
  #--------------------------------------------------------------------------
  # ○ 硬直時間の取得
  #--------------------------------------------------------------------------
  def stiff_time(battler)
    stiff_formula
    return 0 if @stiff_formula == nil
    a = battler
    c = $game_variables
    return eval(@stiff_formula)
  end
  #--------------------------------------------------------------------------
  # ○ 硬直時間計算式の取得
  #--------------------------------------------------------------------------
  def stiff_formula
    return @stiff_formula if @get_stiff_formula
    @get_stiff_formula = true
    self.note.split(/[\r\n]+/).each do |line|
      if line.index("<硬直>") == 0
        @stiff_formula = line["<硬直>".length..-1]
        return @stiff_formula
      end
    end
    return nil if self.is_a?(RPG::State)
    @stiff_formula = $data_skills[1].stiff_formula
  end
  #--------------------------------------------------------------------------
  # ○ ディレイ攻撃か？
  #--------------------------------------------------------------------------
  def delay_attack?
    return delay_formula != nil
  end
  #--------------------------------------------------------------------------
  # ○ ディレイ値の取得
  #--------------------------------------------------------------------------
  def delay_count(battler)
    delay_formula
    return 0 if @delay_formula == nil
    a = battler
    c = $game_variables
    ret = eval(@delay_formula)
    ret = 0 if rand(100)+1 > delay_percent(battler)
    return ret
  end
  #--------------------------------------------------------------------------
  # ○ ディレイ値計算式の取得
  #--------------------------------------------------------------------------
  def delay_formula
    return @delay_formula if @get_delay_formula
    @get_delay_formula = true
    self.note.split(/[\r\n]+/).each do |line|
      if line.index("<ディレイコマ数>") == 0
        @delay_formula = line["<ディレイコマ数>".length..-1]
        return @delay_formula
      end
      if line.index("<ディレイ>") == 0
        @delay_formula = line["<ディレイ>".length..-1]
        return @delay_formula
      end
    end
    @delay_formula = $data_skills[1].delay_formula
    return @delay_formula
  end
  #--------------------------------------------------------------------------
  # ○ ディレイ率の取得
  #--------------------------------------------------------------------------
  def delay_percent(battler)
    delay_percent_formula
    return 100 if @delay_percent_formula == nil
    a = battler
    c = $game_variables
    return eval(@delay_percent_formula)
  end
  #--------------------------------------------------------------------------
  # ○ ディレイ率計算式の取得
  #--------------------------------------------------------------------------
  def delay_percent_formula
    return @delay_percent_formula if @get_delay_percent_formula
    @get_delay_percent_formula = true
    self.note.split(/[\r\n]+/).each do |line|
      if line.index("<ディレイ率>") == 0
        @delay_percent_formula = line["<ディレイ率>".length..-1]
        return @delay_percent_formula
      end
    end
    return @delay_percent_formula
  end
  #--------------------------------------------------------------------------
  # ○ キャンセル攻撃か？
  #--------------------------------------------------------------------------
  def cancel_attack?
    return note.include?("<キャンセル>")
  end
  #--------------------------------------------------------------------------
  # ○ キャンセル攻撃発動か？
  #--------------------------------------------------------------------------
  def cancel?
    return false if rand(100)+1 >= cancel_percent
    return cancel_attack?
  end
  #--------------------------------------------------------------------------
  # ○ キャンセル率の取得
  #--------------------------------------------------------------------------
  def cancel_percent
    cancel_percent_formula
    return 100 if @cancel_percent_formula == nil
    c = $game_variables
    return eval(@cancel_percent_formula)
  end
  #--------------------------------------------------------------------------
  # ○ キャンセル率計算式の取得
  #--------------------------------------------------------------------------
  def cancel_percent_formula
    return @cancel_percent_formula if @get_cancel_percent_formula
    @get_cancel_percent_formula = true
    self.note.split(/[\r\n]+/).each do |line|
      if line.index("<キャンセル率>") == 0
        @cancel_percent_formula = line["<キャンセル率>".length..-1]
        return @cancel_percent_formula
      end
    end
    return @cancel_percent_formula
  end
  #--------------------------------------------------------------------------
  # ○ ディレイ無効か？
  #--------------------------------------------------------------------------
  def anti_delay?
    return note.include?("<ディレイ不可>")
  end
  #--------------------------------------------------------------------------
  # ○ キャンセル不可か？
  #--------------------------------------------------------------------------
  def anti_cancel?
    return note.include?("<キャンセル不可>")
  end
  #--------------------------------------------------------------------------
  # ○ 駆動待ちに自動でかかるステートリスト取得
  #--------------------------------------------------------------------------
  def operate_states
    return @operate_states if @operate_states
    self.note.split(/[\r\n]+/).each do |line|
      if line.index("<ステート>") == 0
        @operate_states = line["<ステート>".length..-1].split(",").collect { |s| s.to_i }
        return @operate_states
      end
    end
    @operate_states = []
    return @operate_states
  end
  #--------------------------------------------------------------------------
  # ○ 駆動待ちに自動でかかるステート対象が味方全体を含むか？
  #--------------------------------------------------------------------------
  def operate_states_for_opponents_all?
    self.note.split(/[\r\n]+/).each do |line|
      if line.index("<ステート対象>") == 0
        return line.include?("敵全体")
      end
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ○ 駆動待ちに自動でかかるステート対象が敵全体を含むか？
  #--------------------------------------------------------------------------
  def operate_states_for_friends_all?
    self.note.split(/[\r\n]+/).each do |line|
      if line.index("<ステート対象>") == 0
        return line.include?("味方全体")
      end
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ○ スキル準備メッセージ取得
  #--------------------------------------------------------------------------
  def prepare_msg
    return @prepare_msg if @prepare_msg
    self.note.split(/[\r\n]+/).each do |line|
      if line.index("<駆動msg>") == 0
        @prepare_msg = line["<駆動msg>".length..-1]
        return @prepare_msg
      end
    end
    @prepare_msg = Saba::Kiseki::DEFAULT_PREPARE_MSG
    return @prepare_msg
  end
end
