class FootballPlayer {
  final int id;
  final String name;
  final String? country;
  final int? ranking;
  final String? currentClub;
  final String? position;
  final DateTime? birthDate;
  final String? height;
  final String? weight;
  final String? marketValue;
  final int goals;
  final int assists;
  final String? imageUrl;
  final String? source;
  final DateTime lastUpdated;

  FootballPlayer({
    required this.id,
    required this.name,
    this.country,
    this.ranking,
    this.currentClub,
    this.position,
    this.birthDate,
    this.height,
    this.weight,
    this.marketValue,
    this.goals = 0,
    this.assists = 0,
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

  factory FootballPlayer.fromJson(Map<String, dynamic> json) {
    return FootballPlayer(
      id: json['id'],
      name: json['name'],
      country: json['country'],
      ranking: json['ranking'],
      currentClub: json['current_club'],
      position: json['position'],
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'])
          : null,
      height: json['height'],
      weight: json['weight'],
      marketValue: json['market_value'],
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      imageUrl: json['image_url'],
      source: json['source'],
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }
}

class FootballPlayerListResponse {
  final List<FootballPlayer> items;
  final int total;
  final int page;
  final int size;

  FootballPlayerListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
  });

  factory FootballPlayerListResponse.fromJson(Map<String, dynamic> json) {
    return FootballPlayerListResponse(
      items: (json['items'] as List).map((i) => FootballPlayer.fromJson(i)).toList(),
      total: json['total'],
      page: json['page'],
      size: json['size'],
    );
  }
}
