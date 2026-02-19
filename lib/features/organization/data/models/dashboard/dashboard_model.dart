class DashboardSummary {
  final int homelessPeopleSupported;
  // final int totalPostedJobs;
  final int activeJobs;
  final int applicationsReceived;
  final DonationsReceived donationsReceived;

  DashboardSummary({
    required this.homelessPeopleSupported,
    // required this.totalPostedJobs,
    required this.activeJobs,
    required this.applicationsReceived,
    required this.donationsReceived,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return DashboardSummary(
      homelessPeopleSupported: parseInt(json['homelessPeopleSupported']),
      // totalPostedJobs: parseInt(json['totalPostedJobs']),
      activeJobs: parseInt(json['activeJobs']),
      applicationsReceived: parseInt(json['applicationsReceived']),
      donationsReceived: DonationsReceived.fromJson(
        json['donationsReceived'] ?? {},
      ),
    );
  }
}

class DonationsReceived {
  final double totalAmount;
  final int count;

  DonationsReceived({required this.totalAmount, required this.count});

  factory DonationsReceived.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return DonationsReceived(
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      count: parseInt(json['count']),
    );
  }
}

class KpiCard {
  final String title;
  final int value;
  final String description;
  final String icon;

  KpiCard({
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
  });

  factory KpiCard.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return KpiCard(
      title: json['title'] ?? '',
      value: parseInt(json['value']),
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
    );
  }
}

class DashboardResponse {
  final DashboardSummary summary;
  final List<KpiCard> kpiCards;

  DashboardResponse({required this.summary, required this.kpiCards});

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return DashboardResponse(
      summary: DashboardSummary.fromJson(data['summary'] ?? {}),
      kpiCards:
          (data['kpiCards'] as List<dynamic>?)
              ?.map((e) => KpiCard.fromJson(e))
              .toList() ??
          [],
    );
  }
}
