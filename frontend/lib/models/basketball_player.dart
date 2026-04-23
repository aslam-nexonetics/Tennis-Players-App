class BasketballPlayer {
  final int id;
  final String name;
  final String? country;
  final int? ranking;
  final String? team;
  final String? position;
  final int? jerseyNumber;
  final String? height;
  final String? weight;
  final DateTime? birthDate;
  final String? college;
  final int? draftYear;
  final int? draftPick;
  
  // Stats
  final double ppg;
  final double rpg;
  final double apg;
  final double spg;
  final double bpg;
  final double fgPct;
  final double threePtPct;
  final double ftPct;
  
  final String? imageUrl;
  final String? source;
  final DateTime lastUpdated;

  BasketballPlayer({
    required this.id,
    required this.name,
    this.country,
    this.ranking,
    this.team,
    this.position,
    this.jerseyNumber,
    this.height,
    this.weight,
    this.birthDate,
    this.college,
    this.draftYear,
    this.draftPick,
    this.ppg = 0.0,
    this.rpg = 0.0,
    this.apg = 0.0,
    this.spg = 0.0,
    this.bpg = 0.0,
    this.fgPct = 0.0,
    this.threePtPct = 0.0,
    this.ftPct = 0.0,
    this.imageUrl,
    this.source,
    required this.lastUpdated,
  });

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  factory BasketballPlayer.fromJson(Map<String, dynamic> json) {
    return BasketballPlayer(
      id: json['id'],
      name: json['name'],
      country: json['country'],
      ranking: json['ranking'],
      team: json['team'],
      position: json['position'],
      jerseyNumber: json['jersey_number'],
      height: json['height'],
      weight: json['weight'],
      birthDate: json['birth_date'] != null ? DateTime.parse(json['birth_date']) : null,
      college: json['college'],
      draftYear: json['draft_year'],
      draftPick: json['draft_pick'],
      ppg: (json['ppg'] ?? 0.0).toDouble(),
      rpg: (json['rpg'] ?? 0.0).toDouble(),
      apg: (json['apg'] ?? 0.0).toDouble(),
      spg: (json['spg'] ?? 0.0).toDouble(),
      bpg: (json['bpg'] ?? 0.0).toDouble(),
      fgPct: (json['fg_pct'] ?? 0.0).toDouble(),
      threePtPct: (json['three_pt_pct'] ?? 0.0).toDouble(),
      ftPct: (json['ft_pct'] ?? 0.0).toDouble(),
      imageUrl: json['image_url'],
      source: json['source'],
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }
}

class BasketballPlayerListResponse {
  final List<BasketballPlayer> items;
  final int total;
  final int page;
  final int size;

  BasketballPlayerListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
  });

  factory BasketballPlayerListResponse.fromJson(Map<String, dynamic> json) {
    return BasketballPlayerListResponse(
      items: (json['items'] as List).map((i) => BasketballPlayer.fromJson(i)).toList(),
      total: json['total'],
      page: json['page'],
      size: json['size'],
    );
  }
}
