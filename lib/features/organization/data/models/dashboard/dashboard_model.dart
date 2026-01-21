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
    return DashboardSummary(
      homelessPeopleSupported: json['homelessPeopleSupported'] ?? 0,
      // totalPostedJobs: json['totalPostedJobs'] ?? 0,
      activeJobs: json['activeJobs'] ?? 0,
      applicationsReceived: json['applicationsReceived'] ?? 0,
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
    return DonationsReceived(totalAmount: 11111.5, count: json['count'] ?? 0);
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
    return KpiCard(
      title: json['title'] ?? '',
      value: json['value'] ?? 0,
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
