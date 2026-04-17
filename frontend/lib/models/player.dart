class Player {
  final int id;
  final String name;
  final String? country;
  final int? ranking;
  final int? highestRanking;
  final DateTime? highestRankingDate;
  final DateTime? birthDate;
  final String? height;
  final String? weight;
  final String? playingStyle;
  final int wins;
  final int losses;
  final String? imageUrl;
  final String? source;
  final DateTime lastUpdated;

  Player({
    required this.id,
    required this.name,
    this.country,
    this.ranking,
    this.highestRanking,
    this.highestRankingDate,
    this.birthDate,
    this.height,
    this.weight,
    this.playingStyle,
    this.wins = 0,
    this.losses = 0,
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

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
      country: json['country'],
      ranking: json['ranking'],
      highestRanking: json['highest_ranking'],
      highestRankingDate: json['highest_ranking_date'] != null
          ? DateTime.parse(json['highest_ranking_date'])
          : null,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'])
          : null,
      height: json['height'],
      weight: json['weight'],
      playingStyle: json['playing_style'],
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      imageUrl: json['image_url'],
      source: json['source'],
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }
}

class PlayerListResponse {
  final List<Player> items;
  final int total;
  final int page;
  final int size;

  PlayerListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
  });

  factory PlayerListResponse.fromJson(Map<String, dynamic> json) {
    return PlayerListResponse(
      items: (json['items'] as List).map((i) => Player.fromJson(i)).toList(),
      total: json['total'],
      page: json['page'],
      size: json['size'],
    );
  }
}
