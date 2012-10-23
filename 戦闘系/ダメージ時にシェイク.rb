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
    SHAKE_POWER = 8
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



class Sprite_Battler
  include Saba::BattleEffect

 
  attr_writer :picture_viewport
 
  alias saba_battle_effect_initialize initialize
  def initialize(viewport, battler = nil)
    saba_battle_effect_initialize(viewport, battler)
    @shake = 0
    @shake_power = SHAKE_POWER
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
        @effect_duration -= 1
        return
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
    delta = (@shake_power * @shake_speed * @shake_direction) / 10.0
    if @effect_duration <= 1 and @shake * (@shake + delta) < 0
      @shake = 0
    else
      @shake += delta
    end
    if @shake > @shake_power * 2
      @shake_direction = -1
    end
    if @shake < - @shake_power * 2
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
