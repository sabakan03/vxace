#==============================================================================
# ■ 倒すとコモンイベント
#    バージョン 2012/10/31
#------------------------------------------------------------------------------
# 　ステートやスキルに以下のメモを書きます
# <敵撃破コモン 20>　→エネミーを倒したらコモンイベント20実行
# <味方撃破コモン 20>　→アクターを倒されたらコモンイベント20実行
# 
# ■ステートの場合
#   このステートがついたバトラーがエネミーを倒すとコモンイベント発動　or
#   このステートがついたバトラーにアクターが倒されるとコモンイベント発動
#
# ■スキル・アイテムの場合
#   このスキル・アイテムでエネミーを倒すとコモンイベント発動　or
#   このスキル・アイテムでアクターが倒されるとコモンイベント発動
#==============================================================================

class Game_Battler
  #--------------------------------------------------------------------------
  # ● スキル／アイテムの効果適用
  #--------------------------------------------------------------------------
  alias saba_finish_item_apply item_apply
  def item_apply(user, item)
    alive = alive?
    saba_finish_item_apply(user, item)
    if alive && dead?
      if enemy?
        if item.enemy_finish_common_id > 0
          $game_temp.reserve_common_event(item.enemy_finish_common_id)
          return
        end
        for s in user.states
          if s.enemy_finish_common_id > 0
            $game_temp.reserve_common_event(s.enemy_finish_common_id)
            return
          end
        end
      else
        if item.friend_finish_common_id > 0
          $game_temp.reserve_common_event(item.friend_finish_common_id)
          return
        end
        for s in user.states
          if s.friend_finish_common_id > 0
            $game_temp.reserve_common_event(s.friend_finish_common_id)
            return
          end
        end
      end
    end
  end
end

module Saba
  module Finish
  def enemy_finish_common_id
    @enemy_finish_common_id ||= /<敵撃破コモン\s*(\d+)\s*>/ =~ @note ? $1.to_i : 0
  end
  def friend_finish_common_id
    @friend_finish_common_id ||= /<味方撃破コモン\s*(\d+)\s*>/ =~ @note ? $1.to_i : 0
  end
  end
end

class RPG::UsableItem
  include Saba::Finish
end

class RPG::State
  include Saba::Finish
end