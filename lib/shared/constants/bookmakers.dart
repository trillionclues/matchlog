// Known bookmaker registry used in bet logging form for bookmaker selector.
// Affiliate URLs are populated latez when affiliate links are enabled.

library;

class Bookmaker {
  final String id;
  final String name;
  final String flag;
  final String? affiliateUrl;

  const Bookmaker(
    this.id,
    this.name,
    this.flag, {
    this.affiliateUrl,
  });
}

const kBookmakers = <Bookmaker>[
  // Nigeria
  Bookmaker('bet9ja', 'Bet9ja', '🇳🇬'),
  Bookmaker('sportybet', 'SportyBet', '🇳🇬'),
  Bookmaker('betking', 'BetKing', '🇳🇬'),
  Bookmaker('1xbet', '1xBet', '🌍'),
  Bookmaker('msport', 'MSport', '🇳🇬'),
  Bookmaker('nairabet', 'NairaBet', '🇳🇬'),
  Bookmaker('bangbet', 'BangBet', '🇳🇬'),
  Bookmaker('parimatch', 'Parimatch', '🌍'),

  // Kenya / East Africa
  Bookmaker('betika', 'Betika', '🇰🇪'),
  Bookmaker('odibets', 'OdiBets', '🇰🇪'),
  Bookmaker('mozzartbet', 'MozzartBet', '🌍'),

  // Ghana
  Bookmaker('betway_gh', 'Betway Ghana', '🇬🇭'),

  // International
  Bookmaker('bet365', 'Bet365', '🌍'),
  Bookmaker('betway', 'Betway', '🌍'),
  Bookmaker('williamhill', 'William Hill', '🇬🇧'),
  Bookmaker('paddy_power', 'Paddy Power', '🇬🇧'),
  Bookmaker('draftkings', 'DraftKings', '🇺🇸'),
  Bookmaker('fanduel', 'FanDuel', '🇺🇸'),
  Bookmaker('unibet', 'Unibet', '🌍'),
  Bookmaker('bwin', 'Bwin', '🌍'),

  // Custom
  Bookmaker('other', 'Other', '🌍'),
];
