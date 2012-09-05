class Window_BattleStatus
  #--------------------------------------------------------------------------
  # ● ウィンドウ幅の取得
  #--------------------------------------------------------------------------
  def window_width
    Graphics.width
  end
end

class Window_BattleActorStatus 
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    contents.clear
    return unless @actor

    draw_actor_hp(actor, 6 ,22, 91)
    draw_actor_mp(actor, 105, 22, 91)
    draw_actor_tp(actor, 6, 2, 91) if $data_system.opt_display_tp
    
    draw_actor_name(@actor, 6, 0, 98)
    draw_actor_icons(@actor, 102, 0, 100)
  end
 end