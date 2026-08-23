class PhoneContact {
  const PhoneContact({
    required this.id,
    required this.displayName,
    this.phones = const [],
  });

  final String id;
  final String displayName;
  final List<String> phones;
}
