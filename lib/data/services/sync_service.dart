/// Optional remote sync hook. Local JSON in AppStore is the source of truth.
class SyncService {
  Future<void> push(Object snapshot) async {}
  Future<Object?> pull(String? phone) async => null;
}
