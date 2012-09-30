#==============================================================================
# ■ 挑発
#   @version 0.1 12/10/01
#   @author さば缶
#------------------------------------------------------------------------------
# 　挑発ステートをつけられた敵が、挑発ステートをつけた相手に
#   攻撃するようになります。
#
#   ■使い方
#     ステートのメモ欄に <挑発> と書きます。
#
#   ■その他
#     敵から挑発を受けた場合、対象選択時は通常通りで、
#     攻撃する瞬間にターゲットが切り替わります。
#==============================================================================

class Game_Battler
  attr_accessor :provoking_battler       # 挑発した人
  #--------------------------------------------------------------------------
  # ○ 挑発を受けている状態か？
  #--------------------------------------------------------------------------
  def provoked?
    return false unless @provoking_battler
    return false if @provoking_battler.dead? || @provoking_battler.hidden?
    states.each {|s| return true if s.provocation?}
    return false
  end
  #--------------------------------------------------------------------------
  # ● ステートの付加
  #--------------------------------------------------------------------------
  alias saba_provocation_add_state add_state
  def add_state(state_id)
    if state_addable?(state_id)
      state = $data_states[state_id]
      @provocation_flag = true if state.provocation?
    end
    saba_provocation_add_state(state_id)
  end
  #--------------------------------------------------------------------------
  # ● 使用効果［ステート付加］：通常攻撃
  #--------------------------------------------------------------------------
  alias saba_provocation_item_effect_add_state_attack item_effect_add_state_attack
  def item_effect_add_state_attack(user, item, effect)
    @provocation_flag = false
    saba_provocation_item_effect_add_state_attack(user, item, effect)
    @provoking_battler = user if @provocation_flag
  end
  #--------------------------------------------------------------------------
  # ● 使用効果［ステート付加］：通常
  #--------------------------------------------------------------------------
  alias saba_provocation_item_effect_add_state_normal item_effect_add_state_normal
  def item_effect_add_state_normal(user, item, effect)
    @provocation_flag = false
    saba_provocation_item_effect_add_state_normal(user, item, effect)
    @provoking_battler = user if @provocation_flag
  end
  #--------------------------------------------------------------------------
  # ● 戦闘終了処理
  #--------------------------------------------------------------------------
  alias saba_provocation_on_battle_end on_battle_end
  def on_battle_end
    @provoking_battler = nil # 念のためクリア
    saba_provocation_on_battle_end
  end
end

class RPG::State
  #--------------------------------------------------------------------------
  # ○ 挑発ステートか？
  #--------------------------------------------------------------------------
  def provocation?
    @provocation ||= /<挑発>/ =~ note
  end
end

class Game_Action
  #--------------------------------------------------------------------------
  # ● ランダムターゲット
  #--------------------------------------------------------------------------
  alias saba_provocation_decide_random_target decide_random_target
  def decide_random_target
    if @subject.provoked?
      return [@subject.provoking_battler]
    else
      saba_provocation_decide_random_target
    end
  end
  #--------------------------------------------------------------------------
  # ● 敵に対するターゲット
  #--------------------------------------------------------------------------
  alias saba_provocation_targets_for_opponents targets_for_opponents
  def targets_for_opponents
    if (item.for_random? || item.for_one?) && @subject.provoked?
      return [@subject.provoking_battler]
    else
      saba_provocation_targets_for_opponents
    end
  end
end