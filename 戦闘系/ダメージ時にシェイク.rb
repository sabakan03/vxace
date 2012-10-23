#==============================================================================
# ■ ダメージ時にシェイク
#   @version 0.1 12/10/23
#   @author さば缶
#------------------------------------------------------------------------------
# 　敵の戦闘エフェクトを変更するスクリプトです。
# 以下の変更ができます。
#
# ■敵にダメージを与えたとき
# デフォ：点滅
#   ↓
# このスクリプト：ランダムシェイク
#  
#==============================================================================
module Saba
  module BattleEffect
    # 敵にダメージを与えたときのシェイクを有効にする場合、true に設定します。
    SHAKE_ENABLED = true
    # シェイクの時間です。
    SHAKE_DURATION = 8
    
    # シェイクの強さです。
    # 最大HPに対する与えたダメージの割合（単位パーセント）と、
    # シェイクの強さのマップ
    # SHAKE_POWER_RATES = {0=>8}
    # と書くと一定の強さでシェイクします。
    SHAKE_POWER_RATES = {
                             0 => 2,    # すこしでもダメージをあたえたらシェイク
                            10 => 4,    # 一度に 10% ダメージでちょいシェイク
                            30 => 8,    # 一度に 30% ダメージでだいぶシェイク
                            50 => 16    # 一度に 50% ダメージですごくシェイク
                        }
    

    
    # シェイクの速度です。
    SHAKE_SPEED = 10
    # 同時にピクチャもシェイクする場合、trueに設定します。
    SHAKE_PICTURE = false
  end
end

class Spriteset_Battle
  #--------------------------------------------------------------------------
  # ● 敵キャラスプライトの作成
  #--------------------------------------------------------------------------
  alias saba_battle_effect_create_enemies create_enemies
  def create_enemies
    saba_battle_effect_create_enemies
    for sprite in @enemy_sprites
      sprite.picture_viewport = @viewport2
    end
  end
end

class Game_Actor
  def shake_power
    return 0
  end
end

class Game_Enemy
  include Saba::BattleEffect
  attr_reader :shake_power
  #--------------------------------------------------------------------------
  # ● ダメージ効果の実行
  #--------------------------------------------------------------------------
  alias saba_battle_effect_perform_damage_effect perform_damage_effect
  def perform_damage_effect
    return if result.hp_damage <= 0
    return if mhp <= 0
    rate = result.hp_damage * 100 / mhp
    power = 0
    SHAKE_POWER_RATES.keys.each do |per|
      next if per > rate
      next if SHAKE_POWER_RATES[per] < power
      power = SHAKE_POWER_RATES[per]
    end
    @shake_power = power
    saba_battle_effect_perform_damage_effect
  end
end

class Sprite_Battler
  include Saba::BattleEffect

  attr_writer :picture_viewport
 
  alias saba_battle_effect_initialize initialize
  def initialize(viewport, battler = nil)
    saba_battle_effect_initialize(viewport, battler)
    @shake = 0
    @shake_speed = SHAKE_SPEED
    @shake_direction = 1
  end
  alias saba_battle_effect_update update
  def update
    duration = @effect_duration
    saba_battle_effect_update
    if @battler != nil && duration > 0 && @effect_duration == 0
      @use_sprite = @battler.use_sprite?
      if @use_sprite && @picture_viewport && SHAKE_PICTURE
        @picture_viewport.ox = 0
        @picture_viewport.oy = 0
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 新しいエフェクトの設定
  #--------------------------------------------------------------------------
  alias saba_battle_effect_setup_new_effect setup_new_effect
  def setup_new_effect
    effect = @battler.sprite_effect_type
    saba_battle_effect_setup_new_effect
    if effect == :blink
      @effect_type = :shake
      @effect_duration = SHAKE_DURATION
    end
  end
  #--------------------------------------------------------------------------
  # ● エフェクトの更新
  #--------------------------------------------------------------------------
  alias saba_battle_effect_update_effect update_effect
  def update_effect
    if @effect_duration > 0
      case @effect_type
      when :shake
        update_shake
      end
    end
    saba_battle_effect_update_effect
  end
  #--------------------------------------------------------------------------
  # ● シェイクエフェクトの更新
  #--------------------------------------------------------------------------
  def update_shake
    self.blend_type = 0
    self.color.set(0, 0, 0, 0)
    self.opacity = 255
    delta = (@battler.shake_power * @shake_speed * @shake_direction) / 10.0
    if @effect_duration <= 1 and @shake * (@shake + delta) < 0
      @shake = 0
    else
      @shake += delta
    end
    if @shake > @battler.shake_power * 2
      @shake_direction = -1
    end
    if @shake < - @battler.shake_power * 2
      @shake_direction = 1
    end
    if @use_sprite && (! @battler.actor?)
      x_value = rand(@shake) * random_direction
      self.x = @battler.screen_x + x_value
      y_value = rand(@shake) * random_direction
      self.y = @battler.screen_y + y_value
      self.z = @battler.screen_z
      if @picture_viewport && SHAKE_PICTURE
        @picture_viewport.ox = x_value
        @picture_viewport.oy = y_value
      end
    end
  end
  def random_direction
    if rand(2) == 0
      return 1
    else
      return -1
    end
  end
end
