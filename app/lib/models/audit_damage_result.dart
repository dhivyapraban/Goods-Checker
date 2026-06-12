class AuditDamageResult {
  final bool severeDamage;
  final double damagePercent;
  final double confidence;
  final String reason;
  final bool escalatedToAdmin;

  const AuditDamageResult({
    required this.severeDamage,
    required this.damagePercent,
    required this.confidence,
    required this.reason,
    required this.escalatedToAdmin,
  });

  factory AuditDamageResult.fromJson(Map<String, dynamic> json) {
    final damage = (json['damage_percent'] as num?)?.toDouble() ?? 0;
    final conf = (json['confidence'] as num?)?.toDouble() ?? 0;

    return AuditDamageResult(
      severeDamage: json['severe_damage'] == true,
      damagePercent: damage,
      confidence: conf,
      reason: (json['reason'] as String?) ?? '',
      escalatedToAdmin: json['escalated_to_admin'] == true,
    );
  }
}
