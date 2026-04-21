// Popular football leagues used in diary feed filter chips and
// Bookie Group league focus selector. IDs correspond to TheSportsDB league IDs.

library;

class League {
  final String id;
  final String name;
  final String country;
  final String flag;

  const League({
    required this.id,
    required this.name,
    required this.country,
    required this.flag,
  });
}

const kPopularLeagues = <League>[
  // England
  League(id: '4328', name: 'Premier League', country: 'England', flag: '🏴󠁧󠁢󠁥󠁮󠁧󠁿'),
  League(id: '4329', name: 'Championship', country: 'England', flag: '🏴󠁧󠁢󠁥󠁮󠁧󠁿'),
  League(id: '4330', name: 'League One', country: 'England', flag: '🏴󠁧󠁢󠁥󠁮󠁧󠁿'),
  League(id: '4331', name: 'League Two', country: 'England', flag: '🏴󠁧󠁢󠁥󠁮󠁧󠁿'),
  League(id: '4480', name: 'FA Cup', country: 'England', flag: '🏴󠁧󠁢󠁥󠁮󠁧󠁿'),

  // Europe
  League(id: '4480', name: 'UEFA Champions League', country: 'Europe', flag: '🇪🇺'),
  League(id: '4481', name: 'UEFA Europa League', country: 'Europe', flag: '🇪🇺'),
  League(id: '4335', name: 'La Liga', country: 'Spain', flag: '🇪🇸'),
  League(id: '4332', name: 'Bundesliga', country: 'Germany', flag: '🇩🇪'),
  League(id: '4334', name: 'Serie A', country: 'Italy', flag: '🇮🇹'),
  League(id: '4334', name: 'Ligue 1', country: 'France', flag: '🇫🇷'),
  League(id: '4337', name: 'Eredivisie', country: 'Netherlands', flag: '🇳🇱'),
  League(id: '4336', name: 'Primeira Liga', country: 'Portugal', flag: '🇵🇹'),

  // Africa
  League(id: '4346', name: 'NPFL', country: 'Nigeria', flag: '🇳🇬'),
  League(id: '4347', name: 'KPL', country: 'Kenya', flag: '🇰🇪'),
  League(id: '4348', name: 'Ghana Premier League', country: 'Ghana', flag: '🇬🇭'),
  League(id: '4349', name: 'CAF Champions League', country: 'Africa', flag: '🌍'),

  // Americas
  League(id: '4346', name: 'MLS', country: 'USA', flag: '🇺🇸'),
  League(id: '4351', name: 'Brasileirão', country: 'Brazil', flag: '🇧🇷'),
  League(id: '4406', name: 'Copa Libertadores', country: 'South America', flag: '🌎'),

  // International
  League(id: '4399', name: 'FIFA World Cup', country: 'International', flag: '🌍'),
  League(id: '4400', name: 'UEFA Euro', country: 'Europe', flag: '🇪🇺'),
  League(id: '4401', name: 'Africa Cup of Nations', country: 'Africa', flag: '🌍'),
];
