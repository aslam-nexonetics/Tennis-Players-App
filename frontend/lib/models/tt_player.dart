class TableTennisPlayer {
  final int id;
  final String name;
  final String? country;
  final int? ranking;
  final DateTime? birthDate;
  final String? weight;
  final String? playingStyle;
  final int wins;
  final int losses;
  final String? imageUrl;
  final String? source;
  final String? gender;
  final DateTime? lastUpdated;

  TableTennisPlayer({
    required this.id,
    required this.name,
    this.country,
    this.ranking,
    this.birthDate,
    this.weight,
    this.playingStyle,
    this.wins = 0,
    this.losses = 0,
    this.imageUrl,
    this.source,
    this.gender,
    this.lastUpdated,
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

  factory TableTennisPlayer.fromJson(Map<String, dynamic> json) {
    return TableTennisPlayer(
      id: json['id'],
      name: json['name'],
      country: json['country'],
      ranking: json['ranking'],
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'])
          : null,
      weight: json['weight'],
      playingStyle: json['playing_style'],
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      imageUrl: json['image_url'],
      source: json['source'],
      gender: json['gender'],
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : null,
    );
  }
}

class TtPlayerListResponse {
  final List<TableTennisPlayer> items;
  final int total;
  final int page;
  final int size;

  TtPlayerListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
  });

  factory TtPlayerListResponse.fromJson(Map<String, dynamic> json) {
    return TtPlayerListResponse(
      items: (json['items'] as List)
          .map((i) => TableTennisPlayer.fromJson(i))
          .toList(),
      total: json['total'],
      page: json['page'],
      size: json['size'],
    );
  }
}
