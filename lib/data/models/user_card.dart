class UserCard {
  const UserCard({
    required this.userId,
    required this.nfcId,
    required this.cardName,
    required this.claimedAt,
    this.status = 'active',
  });

  final String userId;
  final String nfcId;
  final String cardName;
  final DateTime claimedAt;
  final String status;

  factory UserCard.fromJson(Map<String, dynamic> json) {
    return UserCard(
      userId: json['user_id'] as String,
      nfcId: json['nfc_id'] as String,
      cardName: json['card_name'] as String,
      claimedAt: DateTime.parse(json['claimed_at'] as String),
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'nfc_id': nfcId,
        'card_name': cardName,
        'claimed_at': claimedAt.toIso8601String(),
        'status': status,
      };
}

/// Demo merchant VPA for Zep Card orders — not a @zeppay handle.
const kZepCardOrderVpa = 'zepcard.store@okaxis';

const kZepCardPricePaise = 19900;
