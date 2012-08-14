#==============================================================================
# ■ 世界樹の迷宮っぽいバトルステータス 隊列変更
#   @version 0.11  2012/04/06
#   @author さば缶
#------------------------------------------------------------------------------
# 　
#==============================================================================

#==============================================================================
# ■ 隊列を変更するシーンです
#------------------------------------------------------------------------------
#==============================================================================
class Scene_ChangeFormation < Scene_MenuBase
  FORMATION_MEMBERS = 6
  #--------------------------------------------------------------------------
  # ● 開始処理
  #--------------------------------------------------------------------------
  def start
    super
    @change_party = $game_switches[Saba::Sekaiju::NOT_CHANGE_PARTY_SWITCH] != true
    if @change_party
      @actors = $game_party.members
    else
      @actors = $game_party.battle_members
    end

    @label_window = Window_Label.new(260, 60, 215, (FORMATION_MEMBERS + 1) * 24 + 32)
    @remaining = Window_RemainingActors.new(@change_party, 70, 60, 145, [@actors.size, 7].min * 24 + 32, @actors)
    @remaining.active = true
    @formation = Window_Formation.new(@change_party, 330, 60, 145, (FORMATION_MEMBERS + 1) * 24 + 32)
    @formation.active = false
    @status_window = Window_BattleStatus.new
    @status_window.x = 64
    @status_window.y = Graphics.height-120
    @status_window.visible = true
    @status_window.deactivate
    @status_window.update
  end
  #--------------------------------------------------------------------------
  # ● 隊列変更を終了します。
  #--------------------------------------------------------------------------
  def end_change_formation
    return_scene
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    if @remaining.active
      update_remaining_selection
    elsif @formation.active
      update_formation_selection
    end
  end
  #--------------------------------------------------------------------------
  # ● 残りメンバー選択の更新
  #--------------------------------------------------------------------------
  def update_remaining_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel
      if @remaining.restore_confirmed?      # 仮確定メンバーから戻す処理の途中か？
        cancel_restore
      else
        end_change_formation
      end
    elsif Input.trigger?(Input::C)
      if @remaining.remaining_actor? # 有効なメンバーを選択しているか？
        if @formation.actor_size == Saba::Sekaiju::MAX_MEMBERS && @change_party
          Sound.play_buzzer
        else
          Sound.play_ok
          select_remaining_actor
        end
      elsif @remaining.restore_confirmed?      # 仮確定メンバーから戻す処理の途中か？
        Sound.play_ok
        restore
      else
        Sound.play_buzzer
      end
    elsif Input.trigger?(Input::RIGHT)
      unless @remaining.restore_confirmed?
        Sound.play_cursor
        activate_formation_window
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 配置が完了できるどうかを判定します。
  #--------------------------------------------------------------------------
  def finished?
    return false if @formation.actor_size > Saba::Sekaiju::MAX_MEMBERS
    return @formation.actor_size > 0 if @change_party
    return @formation.actor_size == @actors.size
  end
  #--------------------------------------------------------------------------
  # ● 配置先ウィンドウをアクティヴにします。
  #--------------------------------------------------------------------------
  def activate_formation_window
    @remaining.deactivate
    @formation.activate
  end
  #--------------------------------------------------------------------------
  # ● 残りメンバーを選択状態にし、配置先を決める処理に移ります。
  #--------------------------------------------------------------------------
  def select_remaining_actor
    @remaining.deactivate
    @formation.activate
  end
  #--------------------------------------------------------------------------
  # ● 配置が決まっていたメンバーを元に戻します。
  #--------------------------------------------------------------------------
  def restore
    @formation.remove_current
    @remaining.restore(@remaining.restore_confirmed_actor)
    @remaining.confirm_restore(nil)
    @remaining.activate
    @formation.deactivate
    if over? || @formation.actor_size == 0
       @formation.complete = false
    elsif finished?
       @formation.complete = true
    else
      @formation.complete = false
    end
  end
  #--------------------------------------------------------------------------
  # ● 配置が決まっていたメンバーを元に戻す処理をキャンセルします。
  #--------------------------------------------------------------------------
  def cancel_restore
    @remaining.deactivate
    @formation.activate
    @remaining.confirm_restore(nil)
  end
  #--------------------------------------------------------------------------
  # ● 仮確定メンバー選択の更新
  #--------------------------------------------------------------------------
  def update_formation_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel
      if @remaining.remaining_actor?
        cancel_arrange
      else
        end_change_formation
      end
    elsif Input.trigger?(Input::C)
      if @formation.ok_button?
        Sound.play_ok
        decide
      elsif @remaining.remaining_actor?
        Sound.play_ok
        arrange_provisionally
      elsif @formation.actor != nil
        Sound.play_ok
        confirm_restore
      else
        Sound.play_buzzer
      end
    elsif Input.trigger?(Input::LEFT)
      if @remaining.remaining_actor?
        return
      end
      Sound.play_cursor
      activate_remaining_window
    end
  end
  #--------------------------------------------------------------------------
  # ● 既に配置したメンバーを元に戻すかを確認する処理に移ります。
  #--------------------------------------------------------------------------
  def confirm_restore
    actor = @formation.actor
    @remaining.confirm_restore(actor)
    @remaining.activate
    @formation.deactivate
  end
  #--------------------------------------------------------------------------
  # ● 残りメンバー配置をキャンセルします。
  #--------------------------------------------------------------------------
  def cancel_arrange
    @remaining.activate
    @formation.deactivate
  end
  #--------------------------------------------------------------------------
  # ● 残りメンバーウィンドウをアクティヴにします。
  #--------------------------------------------------------------------------
  def activate_remaining_window
    @remaining.activate
    @formation.deactivate
  end
  #--------------------------------------------------------------------------
  # ● 残りメンバーウィンドウで選択されているアクターを選択されている配置先に配置します。
  #--------------------------------------------------------------------------
  def arrange_provisionally
    actor = @remaining.remove_current
    old = @formation.actor
    @formation.put_actor(actor)
    @remaining.restore(old)
    if finished?      # 全員確定したか？
      if over?
        @formation.complete = false
      else
        @formation.complete = true
      end
      
      if @formation.finished_all?
        @remaining.deactivate
      else
        next_cursor
      end
    else
      @formation.complete = false
      next_cursor
    end
  end
  def over?
    @formation.actor_size > Saba::Sekaiju::MAX_MEMBERS
  end
  def next_cursor
    @remaining.activate
    @formation.deactivate
    @remaining.auto_select
  end
  #--------------------------------------------------------------------------
  # ● 配置を確定します。
  #--------------------------------------------------------------------------
  def decide
    fronts = @formation.fronts.compact
    backs = @formation.backs.compact
    $game_party.clear_formation
    for actor in fronts
      $game_party.add_front(actor)
    end
    for actor in backs
      $game_party.add_back(actor)
    end
    $game_party.update_formation
    $game_player.refresh
    $game_map.need_refresh = true
    end_change_formation
  end

end

class Window_Label < Window_Selectable
  def initialize(x, y, width, height)
    super(x, y, width, height)
    @item_max = 6
    @column_max = 1
    self.index = -1
    refresh
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    @item_max.times do |i|
      draw_item(i)
    end
  end
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #--------------------------------------------------------------------------
  def draw_item(index)
    case index
    when 0
      rect = item_rect(index)
      self.contents.clear_rect(rect)
      self.contents.draw_text(rect.x, rect.y, 50, 24, "FRONT", 1)
    when 3
      rect = item_rect(index)
      self.contents.clear_rect(rect)
      self.contents.draw_text(rect.x, rect.y, 50, 24, "BACK", 1)
    end
  end
end

#==============================================================================
# ■ Window_Actors
#------------------------------------------------------------------------------
#   アクターを保持するウィンドウです
#==============================================================================
class Window_Actors < Window_Selectable
  def item_max
    return 0 unless @actors
    return @actors.size
  end
  #--------------------------------------------------------------------------
  # ● アクター名の描画
  #--------------------------------------------------------------------------
  def draw_actor(actor, x, y, enabled = true, align = 0)
    name = actor.name

    self.contents.font.color = normal_color
    
    self.contents.font.color.alpha = enabled ? 255 : 128
    self.contents.draw_text(x, y, self.width - 32, 24, name, align)
  end
  def draw_text(text, x, y, enabled = true, align = 0)
    self.contents.font.color = normal_color
    self.contents.font.color.alpha = enabled ? 255 : 128
    self.contents.draw_text(x, y, self.width - 32, 24, text, align)
  end
  #--------------------------------------------------------------------------
  # ● アクターの取得
  #--------------------------------------------------------------------------
  def actor
    return @actors[self.index]
  end

end

#==============================================================================
# ■ Window_RemainingActors
#------------------------------------------------------------------------------
#   まだ配置されていないアクターを描画するウィンドウです
#==============================================================================
class Window_RemainingActors < Window_Actors
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     x      : ウィンドウの X 座標
  #     y      : ウィンドウの Y 座標
  #     width  : ウィンドウの幅
  #     height : ウィンドウの高さ
  #     actors : 全アクターの配列
  #--------------------------------------------------------------------------
  def initialize(change_party, x, y, width, height, actors)
    super(x, y, width, height)
    @change_party = change_party
    @actors = actors
    @remaining = @actors.clone
    @item_max = @actors.size
    @column_max = 1
    self.index = 0
    create_contents
    refresh
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    @actors.size.times do |i|
      draw_item(i)
    end
  end
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #--------------------------------------------------------------------------
  def draw_item(index)
    act = @actors[index]
    rect = item_rect(index)
    self.contents.clear_rect(rect)
    if act != nil
      rect.width -= 4
      if @confirmed_actor != nil
        enabled = @confirmed_actor == act
      else
        enabled = @remaining.include?(act)
      end
      draw_actor(act, rect.x, rect.y, enabled)
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルの移動可能判定
  #--------------------------------------------------------------------------
  def cursor_movable?
    return false if restore_confirmed?
    return super
  end
  #--------------------------------------------------------------------------
  # ● 全てのアクターの配置が完了したかどうかを返します。
  #--------------------------------------------------------------------------
  def complete?
    return @remaining.empty?
  end
  #--------------------------------------------------------------------------
  # ● 現在選択されているアクターが未配置状態かどうかを返します。
  #--------------------------------------------------------------------------
  def remaining_actor?
    return false if @hide_cursor
    act = @actors[index]
    return @remaining.include?(act)
  end
  #--------------------------------------------------------------------------
  # ● 現在選択されているアクターを未配置状態にし、返します。
  #--------------------------------------------------------------------------
  def remove_current
    act = @actors[index]
    @remaining.delete(act)
    refresh
    return act
  end
  #--------------------------------------------------------------------------
  # ● 指定のアクターを未配置状態にします。
  #--------------------------------------------------------------------------
  def restore(actor)
    return if actor == nil
    @remaining.push(actor)
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 指定のアクターを未配置状態にするかどうかを確認する状態にします。
  #--------------------------------------------------------------------------
  def confirm_restore(actor)
    @confirmed_actor = actor
    self.index = @actors.index(@confirmed_actor) if @confirmed_actor != nil
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 選択中のアクターを未配置状態にするかどうかを確認する状態かどうかを返します。
  #--------------------------------------------------------------------------
  def restore_confirmed?
    return @confirmed_actor != nil
  end
  #--------------------------------------------------------------------------
  # ● 未配置状態にするかどうかを確認しているアクターを返します。
  #--------------------------------------------------------------------------
  def restore_confirmed_actor
    return @confirmed_actor
  end
  #--------------------------------------------------------------------------
  # ● 自動で未確定のアクターを選択します。
  #--------------------------------------------------------------------------
  def auto_select
    while ! remaining_actor?
      self.index += 1
      if self.index >= @item_max
        self.index = 0
      end
    end
  end
end

#==============================================================================
# ■ Window_Formation
#------------------------------------------------------------------------------
#   暫定的に配置を決めたアクターを表示するウィンドウです。
#==============================================================================
class Window_Formation < Window_Actors
  def item_max
    return 0 unless @actors
    return @actors.size + 1 if @complete
    return @actors.size
  end
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     x      : ウィンドウの X 座標
  #     y      : ウィンドウの Y 座標
  #     width  : ウィンドウの幅
  #     height : ウィンドウの高さ
  #--------------------------------------------------------------------------
  def initialize(change_party, x, y, width, height)
    super(x, y, width, height)
    @change_party = change_party
    @actors = [nil, nil, nil, nil, nil, nil]
    @column_max = 1
    @item_max = @actors.size
    @complete = false
    self.index = 0
    refresh
  end
  #--------------------------------------------------------------------------
  # ● アクターの取得
  #--------------------------------------------------------------------------
  def actor
    return @actors[self.index]
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    @actors.size.times do |i|
      draw_item(i)
    end
    draw_ok
  end
  #--------------------------------------------------------------------------
  # ● 決定ボタンを描画します。
  #--------------------------------------------------------------------------
  def draw_ok
    rect = item_rect(6)
    self.contents.clear_rect(rect)
    draw_text("決定", rect.x, rect.y, @complete, 1)
  end
  #--------------------------------------------------------------------------
  # ● 現在選択されているアクターを削除します。
  #--------------------------------------------------------------------------
  def remove_current
    @actors[self.index] = nil
    self.complete =  false unless @change_party
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #--------------------------------------------------------------------------
  def draw_item(index)
    act = @actors[index]
    rect = item_rect(index)
    self.contents.clear_rect(rect)
    rect.width -= 4
    if act
      draw_actor(act, rect.x, rect.y, true)
    else
      text = ""
      Saba::Sekaiju::MAX_CHAR_NAME.times do 
        text += "－"
      end
      draw_text(text, rect.x, rect.y, true)
    end
  end
  #--------------------------------------------------------------------------
  # ● 現在選択されている項目に指定のアクターを配置します。
  #--------------------------------------------------------------------------
  def put_actor(actor)
    @actors[self.index] = actor
    auto_select
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 決定ボタンを押せる状態かを設定します。
  #--------------------------------------------------------------------------
  def complete=(value)
    if value
      @item_max = 7
      self.index = 6 if finished_all?
    else
      @item_max = 6
    end
    return if @complete == value
    @complete = value
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 配置が完了したかどうかを判定します。
  #--------------------------------------------------------------------------
  def finished_all?
    if $game_switches[Saba::Sekaiju::NOT_CHANGE_PARTY_SWITCH] != true
      actors = $game_party.members
    else
      actors = $game_party.battle_members
    end
    return actor_size == Saba::Sekaiju::MAX_MEMBERS || actor_size == actors.size
  end
  #--------------------------------------------------------------------------
  # ● 自動的に開いた項目を選択状態にします。
  #--------------------------------------------------------------------------
  def auto_select
    return if @actors[self.index] == nil
    old = self.index
    @actors.size.times do |index|
      next if self.index > index
      if @actors[index] == nil
        self.index = index
        break
      end
    end
    return if old != self.index
    @actors.size.times do |index|
      if @actors[index] == nil
        self.index = index
        break
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 現在選択されている要素が決定ボタンかを返します。
  #--------------------------------------------------------------------------
  def ok_button?
    return self.index == 6
  end
  #--------------------------------------------------------------------------
  # ● 前衛を返します。
  #--------------------------------------------------------------------------
  def fronts
    return @actors[0, 3]
  end
  #--------------------------------------------------------------------------
  # ● 後衛を返します。
  #--------------------------------------------------------------------------
  def backs
    return @actors[3, 6]
  end
  #--------------------------------------------------------------------------
  # ● 配置されたアクターの数を返します。
  #--------------------------------------------------------------------------
  def actor_size
    return @actors.compact.size
  end
end
