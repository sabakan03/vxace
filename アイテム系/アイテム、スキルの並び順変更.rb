#==============================================================================
# ■ アイテム、スキルの並び順変更
#   @version 0.01 12/09/15
#   @author さば缶
#------------------------------------------------------------------------------
# 　特定のアイテム/スキルの、アイテムウィンドウ/スキルウィンドウにおける並び順を
#  変更します。
#
# ■使い方
# ・アイテム、スキルのメモ欄に以下のように記述することで、
# 　指定したIDと同じ並び順になります。
# <ORDER 並び順決定の時に使うID番号>
#
# 例
# <ORDER 10>
# このアイテムの並び順が、IDが10のアイテムと同じ並び順になります。
# もし同一IDのものが複数あれば、その中で元のID順に並びます。
#==============================================================================
module Saba
  module Sort
    # お店の品物も並び替える場合、trueに設定します。
    SORT_SHOP_ITEMS = false
  end
end


class RPG::BaseItem
  def <=>(value)
    result = self.item_type <=> value.item_type
    if result != 0
      return result
    end
    return self.sort_priority <=> value.sort_priority
  end

  def sort_priority
    setup_sort_priority
    result = @sort_priority * 10000
    return result + id * 10
  end
  def setup_sort_priority
    return if @sort_priority != nil
    @sort_priority = id
    note.split(/[\r\n]+/).each do |line|
      if line.scan(/\<ORDER\s+([0-9]+)\s*\>/)
        @sort_priority = $1.to_i
     end
    end
  end
  def item_type
    case self
    when RPG::Item
      return 0
    when RPG::Weapon
      return 1
    when RPG::Armor
      return 2
    end
    # スキル
    return 3
  end
end

class Game_Party
  #--------------------------------------------------------------------------
  # ● アイテムオブジェクトの配列取得 
  #--------------------------------------------------------------------------
  alias saba_sort_items items
  def items
    saba_sort_items.sort
  end
  #--------------------------------------------------------------------------
  # ● 武器オブジェクトの配列取得 
  #--------------------------------------------------------------------------
  alias saba_sort_weapons weapons
  def weapons
    saba_sort_weapons.sort
  end
  #--------------------------------------------------------------------------
  # ● 防具オブジェクトの配列取得 
  #--------------------------------------------------------------------------
  alias saba_sort_armors armors
  def armors
    saba_sort_armors.sort
  end
end

class Game_Actor
  #--------------------------------------------------------------------------
  # ● スキルオブジェクトの配列取得
  #--------------------------------------------------------------------------
  alias saba_sort_skills skills
  def skills
    return saba_sort_skills.sort
  end
end

if Saba::Sort::SORT_SHOP_ITEMS
class Window_ShopBuy
  #--------------------------------------------------------------------------
  # ● アイテムリストの作成
  #--------------------------------------------------------------------------
  alias saba_sort_make_item_list make_item_list
  def make_item_list
    saba_sort_make_item_list
    @data.sort!
  end
end
end