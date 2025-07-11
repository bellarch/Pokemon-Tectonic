BattleHandlers::DefenseCalcUserItem.add(:STRIKEVEST,
  proc { |item, _user, _battle, defenseMult|
      defenseMult *= 1.5
      next defenseMult
  }
)

BattleHandlers::DefenseCalcUserItem.add(:FRAGILELOCKET,
  proc { |item, user, _battle, defenseMult|
      defenseMult *= (1.0 - FRAGILE_LOCKET_STAT_REDUCTION)
      next defenseMult
  }
)

BattleHandlers::DefenseCalcUserItem.add(:PEARLOFWISDOM,
  proc { |item, user, _battle, defenseMult|
      defenseMult *= (1.0 + PEARL_OF_WISDOM_STAT_BOOST)
      next defenseMult
  }
)