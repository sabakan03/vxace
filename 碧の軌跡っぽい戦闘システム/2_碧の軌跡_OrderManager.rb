#==============================================================================
# ■ 碧の軌跡っぽい戦闘システム13_3　OrderManager
#   @version 0.23 12/01/28
#   @author さば缶
#------------------------------------------------------------------------------
# 　順番を管理するモジュールが入っています
#==============================================================================
module OrderManager
  
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    init_unit
  end
  #--------------------------------------------------------------------------
  # ○ 先頭のユニット取得
  #--------------------------------------------------------------------------
  def self.top_unit
    return @top_unit
  end
  #--------------------------------------------------------------------------
  # ○ ユニット初期化
  #--------------------------------------------------------------------------
  def self.init_unit
    @units = []
    for actor in $game_party.battle_members
      next if actor.dead?
      if BattleManager.preemptive
        delay_time = $data_skills[7].operate_time(actor)
      else
        delay_time = $data_skills[4].operate_time(actor)
      end
      @units.push(Game_BattleUnit.new(actor, delay_time))
    end
    for enemy in $game_troop.members
      if BattleManager.surprise
        delay_time = $data_skills[7].operate_time(enemy)
      else
        delay_time = $data_skills[4].operate_time(enemy)
      end
      @units.push(Game_BattleUnit.new(enemy, delay_time)) if enemy.alive?
    end
    sort
    update_top
    init_position
  end
  #--------------------------------------------------------------------------
  # ○ 座標を初期化
  #--------------------------------------------------------------------------
  def self.init_position
    @top_unit.init_position
    @units.each { |unit| unit.init_position }
  end
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  def self.update
    check_alive
    check_dead
    self.units.each { |unit| unit.update }
  end
  #--------------------------------------------------------------------------
  # ○ バトラーの配列を返します。
  #--------------------------------------------------------------------------
  def self.battlers
    @units.collect {|unit| unit.battler }.uniq
  end
  #--------------------------------------------------------------------------
  # ○ ユニットの点滅を停止します。
  #--------------------------------------------------------------------------
  def self.clear_blink
    for unit in @units
      unit.blink = false
      unit.targeted = false
    end
  end
  #--------------------------------------------------------------------------
  # ○ 指定のキャラの最小さいディレイコマ数を取得
  #--------------------------------------------------------------------------
  def self.min_delay_count(battler)
    unit = find_unit(battler)
    return -@units.index(unit)
  end
  #--------------------------------------------------------------------------
  # ○ 指定のキャラの最大ディレイコマ数を取得
  #--------------------------------------------------------------------------
  def self.max_delay_count(battler)
    unit = find_unit(battler)
    return @units.size - @units.index(unit) - 1
  end
  #--------------------------------------------------------------------------
  # ○ 指定のキャラの待ち時間に指定の値を加えます。
  #--------------------------------------------------------------------------
  def self.add_delay(battler, delay)
    unit = find_unit(battler)
    return unless unit
    unit.delay_time += delay if unit
    sort
    update_delay_time
  end
  #--------------------------------------------------------------------------
  # ○ 指定のキャラのスキル発動待ちをキャンセルします。
  #--------------------------------------------------------------------------
  def self.cancel(unit)
    return false if unit == nil
    unit.cancel
    unit.delay_time = $data_skills[6].operate_time(unit.battler)
    sort
    update_delay_time
    return true
  end
  #--------------------------------------------------------------------------
  # ○ 先頭ユニットを削除し、次のユニットに入れ替えます。
  #--------------------------------------------------------------------------
  def self.update_top
    check_remove
    
    old = @top_unit
    @top_unit = @units[0]
    
    @units.delete(@top_unit)
    @top_unit.forecast = false
    @top_unit.delay_time_decimal = 99
    @units.each_with_index do |unit, i|
      unit.delay_time -= @top_unit.delay_time
      unit.forecast = false
    end
    @top_unit.delay_time = 0
    update_delay_time
  end
  #--------------------------------------------------------------------------
  # ○ 指定のバトラーのユニットが存在するかを返します。
  #--------------------------------------------------------------------------
  def self.contains?(battler)
    return find_unit(battler) != nil
  end
  #--------------------------------------------------------------------------
  # ○ ユニット内のキャラの死亡を判定します。
  #--------------------------------------------------------------------------
  def self.check_dead
    for unit in @units.clone
      if  (unit.battler.dead? || unit.battler.hidden?)
        remove(unit.battler)
        next
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ ユニット内の死亡したキャラの復活を判定します。
  #--------------------------------------------------------------------------
  def self.check_alive
    for actor in $game_party.battle_members
      next if actor.dead?
      if find_unit(actor) == nil
        insert(actor, $data_skills[5].operate_time(actor))
      end
    end
    for actor in $game_troop.members
      next if actor.dead? || actor.hidden?
      if find_unit(actor) == nil
        insert(actor, $data_skills[5].operate_time(actor))
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ ユニット内のパーティー抜けを判定します。
  #--------------------------------------------------------------------------
  def self.check_remove
    for unit in @units.clone
     if unit.battler.actor?
        unless $game_party.battle_members.include?(unit.battler)
          remove(unit.battler)
          next
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ 指定のバトラーをユニットとして追加します。
  #  battler 追加するバトラー
  #  delay_time 待ち時間
  #  forecast 行動順の予想ユニットかどうかのフラグ
  #  item 待ち時間が必要なアイテム
  #--------------------------------------------------------------------------
  def self.insert(battler, delay_time, forecast = false, item = nil, operate = false)
    delay_time = delay_time.round
    unit = find_not_top_unit(battler)
    if unit
      update_unit(unit, delay_time, forecast, item, operate)
    else
      insert_new_unit(battler, delay_time, forecast, item, operate)
    end
    sort
    update_delay_time
  end
  #--------------------------------------------------------------------------
  # ○ ユニットの状態を更新
  #--------------------------------------------------------------------------
  def self.update_unit(unit, delay_time, forecast, item, operate)
    index = @units.index(unit)
    if forecast
      unit.delay_time = delay_time
    end
    unit.forecast = forecast
    unit.usable_item = item
    unit.operate = operate
  end
  #--------------------------------------------------------------------------
  # ○ 新しいユニットを追加
  #--------------------------------------------------------------------------
  def self.insert_new_unit(battler, delay_time, forecast, item, operate)
    new_unit = Game_BattleUnit.new(battler, delay_time, forecast, item, operate)
    new_unit.x = Saba::Kiseki::INSERT_DISTANCE
    @units.push(new_unit)
  end
  #--------------------------------------------------------------------------
  # ○ 待ち時間を更新
  #--------------------------------------------------------------------------
  def self.update_delay_time
    @top_unit.index = 0 if @top_unit != nil
    @units.each_with_index do |unit, i|
      unit.index = i + 1
      unit.delay_time_decimal = i * 500 # 間にディレイキャラを差し込むため
    end
  end
  #--------------------------------------------------------------------------
  # ○ 先頭以外で指定のバトラーを内部に持つユニットを検索します。
  #--------------------------------------------------------------------------
  def self.find_not_top_unit(battler)
    return @units.reverse.select { |unit| unit.battler == battler}[0]
  end
  #--------------------------------------------------------------------------
  # ○ 指定のバトラーを内部に持つユニットを検索します。
  #--------------------------------------------------------------------------
  def self.find_unit(battler)
    return self.units.reverse.select { |unit| unit.battler == battler}[0]
  end
  #--------------------------------------------------------------------------
  # ○ 指定のバトラーを内部に持つユニットを削除します。
  #--------------------------------------------------------------------------
  def self.remove(battler)
    unit = find_unit(battler)
    return if unit == nil
    @units.delete(unit)
  end
  #--------------------------------------------------------------------------
  # ○ 全てのユニットを返します。
  #--------------------------------------------------------------------------
  def self.units
    return ([@top_unit] + @units).compact
  end
  #--------------------------------------------------------------------------
  # ○ 全てのユニットを行動順に並び替えます。
  #--------------------------------------------------------------------------
  def self.sort
    @units.sort! { |a, b| a.delay_time_compare <=> b.delay_time_compare }
  end
  #--------------------------------------------------------------------------
  # ○ 指定のバトラーを含むユニットを点滅
  #--------------------------------------------------------------------------
  def self.blink(battler, show_targeted = true)
    unit = find_unit(battler)
    return if unit == nil
    unit.blink = true
    show_target(battler) if show_targeted
  end
  #--------------------------------------------------------------------------
  # ○ 指定のバトラーの攻撃目標を表示
  #--------------------------------------------------------------------------
  def self.show_target(battler)
    for unit in @units.reverse
      unit.targeted = battler.target?(unit.battler)
    end
  end
  #--------------------------------------------------------------------------
  # ○ 指定のバトラーの順番を遅らせる。
  #--------------------------------------------------------------------------
  def self.delay_order(battler, value)
    unit = find_unit(battler)

    return unless unit
    
    if value > 0
      target = find_next_unit(unit, value)
      unit.delay_time_decimal = target.delay_time_decimal + 1 + unit.delay_time_decimal / 500
      unit.delay_time = target.delay_time 
    else
      target = find_prev_unit(unit, value)
      return if target == nil
      unit.delay_time = target.delay_time 
      unit.delay_time_decimal = target.delay_time_decimal - 1
    end
    sort
  end
  #--------------------------------------------------------------------------
  # ○ 指定のユニットのvalue後ろのユニットを返す
  #    返されるユニットは delay_count が 0 のものに限る
  #--------------------------------------------------------------------------
  def self.find_next_unit(unit, value)
    index = @units.index(unit) + value
    begin
      target = @units[index]
      index += 1
      return last_unit if target == nil
    end while target.battler.result.delay_count != 0
    return target
  end
  #--------------------------------------------------------------------------
  # ○ 指定のユニットのvalue前のユニットを返す
  #    返されるユニットは delay_count が 0 のものに限る
  #--------------------------------------------------------------------------
  def self.find_prev_unit(unit, value)
    index = @units.index(unit) + value
    begin
      return top_unit if index < 0
      target = @units[index]
      index -= 1
      return top_unit if target == nil
    end while target.battler.result.delay_count != 0
    return target
  end
  #--------------------------------------------------------------------------
  # ○ 行動予想のマークを削除
  #--------------------------------------------------------------------------
  def self.clear_forecast
    @units.each {|unit| unit.forecast = false }
  end
  #--------------------------------------------------------------------------
  # ○ 行動予想のユニットを返す
  #--------------------------------------------------------------------------
  def self.forecast_unit
    @units.each {|unit| return unit if unit.forecast }
    return nil
  end
  #--------------------------------------------------------------------------
  # ○ 行動予想のユニットを削除
  #--------------------------------------------------------------------------
  def self.remove_forecast_unit
    @units.delete_if {|unit| unit.forecast }
    update_delay_time
  end
  #--------------------------------------------------------------------------
  # ○ 指定のユニットを選択
  #--------------------------------------------------------------------------
  def self.select(battler)
    clear_selection
    return unless find_unit(battler)
    find_unit(battler).selected = true
    show_targeted(battler)
  end
  #--------------------------------------------------------------------------
  # ○ 攻撃対象のユニットを表示
  #--------------------------------------------------------------------------
  def self.show_targeted(battler)
    return if battler.actor?
    unit = find_unit(battler)
    return unless unit
    unit.targets.each do |b|
      next unless find_unit(b)
      find_unit(b).targeted = true
    end
  end
  #--------------------------------------------------------------------------
  # ○ 選択状態をクリア
  #--------------------------------------------------------------------------
  def self.clear_selection
    @top_unit.selected = false
    @top_unit.targeted = false
    @units.each {|unit| unit.selected = false; unit.targeted = false }
  end
  #--------------------------------------------------------------------------
  # ○ 一番最後のユニットを返します。
  #--------------------------------------------------------------------------
  def self.last_unit
    return @units[-1]
  end
end
