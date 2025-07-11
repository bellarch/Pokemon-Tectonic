BattleHandlers::AttackCalcUserItem.add(:MUSCLEBAND,
    proc { |item, _user, _battle, attackMult|
        attackMult *= 1.1
        next attackMult
    }
)

BattleHandlers::AttackCalcUserItem.add(:CHOICEBAND,
  proc { |item, _user, _battle, attackMult|
      attackMult *= 1.4
      next attackMult
  }
)

BattleHandlers::AttackCalcUserItem.add(:THICKCLUB,
  proc { |item, user, _battle, attackMult|
      attackMult *= 1.5 if user.isSpecies?(:CUBONE) || user.isSpecies?(:MAROWAK)
      next attackMult
  }
)

BattleHandlers::AttackCalcUserItem.add(:FRAGILELOCKET,
  proc { |item, user, _battle, attackMult|
      attackMult *= (1.0 - FRAGILE_LOCKET_STAT_REDUCTION)
      next attackMult
  }
)

BattleHandlers::AttackCalcUserItem.add(:PEARLOFWISDOM,
  proc { |item, user, _battle, attackMult|
    attackMult *= (1.0 + PEARL_OF_WISDOM_STAT_BOOST)
    next attackMult
  }
)