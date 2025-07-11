BattleHandlers::SpecialDefenseCalcUserItem.add(:ASSAULTVEST,
  proc { |item, _user, _battle, spDefMult|
      spDefMult *= 1.5
      next spDefMult
  }
)

BattleHandlers::SpecialDefenseCalcUserItem.add(:FRAGILELOCKET,
  proc { |item, user, _battle, spDefMult|
      spDefMult *= (1.0 - FRAGILE_LOCKET_STAT_REDUCTION)
      next spDefMult
  }
)

BattleHandlers::SpecialDefenseCalcUserItem.add(:PEARLOFWISDOM,
  proc { |item, user, _battle, spDefMult|
      spDefMult *= (1.0 + PEARL_OF_WISDOM_STAT_BOOST)
      next spDefMult
  }
)