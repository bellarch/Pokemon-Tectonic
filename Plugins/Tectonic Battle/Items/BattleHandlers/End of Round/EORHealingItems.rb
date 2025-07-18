BattleHandlers::EORHealingItem.add(:BLACKSLUDGE,
    proc { |item, battler, battle|
        if battler.pbHasType?(:POISON)
            battler.applyFractionalHealing(1.0 / 16.0, item: item)
            battler.aiLearnsItem(item)
        elsif battler.takesIndirectDamage?
            battle.pbCommonAnimation("UseItem", battler)
            battle.pbDisplay(_INTL("{1} is hurt by its {2}!", battler.pbThis, getItemName(item)))
            battler.applyFractionalDamage(1.0 / 8.0)
            battler.aiLearnsItem(item)
        end
    }
)

LEFTOVERS_HEALING_FRACTION = 0.0625 # 1/16

BattleHandlers::EORHealingItem.add(:LEFTOVERS,
  proc { |item, battler, _battle|
      next unless battler.canLeftovers?
      battler.applyFractionalHealing(LEFTOVERS_HEALING_FRACTION, item: item)
      battler.aiLearnsItem(item)
  }
)