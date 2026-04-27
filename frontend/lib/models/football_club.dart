class FootballClub {
  final int id;
  final String name;
  final String? country;
  final String? league;
  final int? foundedYear;
  final String? stadium;
  final int? capacity;
  final String? manager;
  final String? nickname;
  final String? imageUrl;
  final String? website;
  final String? description;
  final int? ranking;
  
  // Enhanced Statistics
  final int totalTrophies;
  final String? marketValue;
  final int? leaguePosition;
  final String? captain;
  final String? owner;
  final String? mainRivals;
  final int? averageAttendance;

  FootballClub({
    required this.id,
    required this.name,
    this.country,
    this.league,
    this.foundedYear,
    this.stadium,
    this.capacity,
    this.manager,
    this.nickname,
    this.imageUrl,
    this.website,
    this.description,
    this.ranking,
    this.totalTrophies = 0,
    this.marketValue,
    this.leaguePosition,
    this.captain,
    this.owner,
    this.mainRivals,
    this.averageAttendance,
  });

  factory FootballClub.fromJson(Map<String, dynamic> json) {
    return FootballClub(
      id: json['id'],
      name: json['name'],
      country: json['country'],
      league: json['league'],
      foundedYear: json['founded_year'],
      stadium: json['stadium'],
      capacity: json['capacity'],
      manager: json['manager'],
      nickname: json['nickname'],
      imageUrl: json['image_url'],
      website: json['website'],
      description: json['description'],
      ranking: json['ranking'],
      totalTrophies: json['total_trophies'] ?? 0,
      marketValue: json['market_value'],
      leaguePosition: json['league_position'],
      captain: json['captain'],
      owner: json['owner'],
      mainRivals: json['main_rivals'],
      averageAttendance: json['average_attendance'],
    );
  }
}

class FootballClubListResponse {
  final List<FootballClub> items;
  final int total;
  final int page;
  final int size;

  FootballClubListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
  });

  factory FootballClubListResponse.fromJson(Map<String, dynamic> json) {
    return FootballClubListResponse(
      items: (json['items'] as List)
          .map((i) => FootballClub.fromJson(i))
          .toList(),
      total: json['total'],
      page: json['page'],
      size: json['size'],
    );
  }
}
