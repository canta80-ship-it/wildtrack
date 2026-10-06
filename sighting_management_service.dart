import '../models/sighting.dart';
import 'community_service.dart';
import 'database_service.dart';

class SightingManagementService {
  SightingManagementService({Future<void> Function(String)? deletePublic})
    : _deletePublic = deletePublic ?? CommunityService.instance.deleteSighting;
  static final instance = SightingManagementService();
  final Future<void> Function(String) _deletePublic;

  Future<void> delete(Sighting sighting) async {
    final community = CommunityService.instance;
    final queued = community.pending.any((item) => item['id'] == sighting.id);
    final published =
        sighting.isPublic ||
        community.sightings.any(
          (item) => item['id'] == sighting.id && item['mine'] == 1,
        );
    if (community.syncing && (queued || published)) {
      throw Exception('Sincronizzazione in corso. Riprova quando termina.');
    }
    // If online deletion fails, keep the local record so the user can retry.
    if (published) await _deletePublic(sighting.id);
    if (queued) await community.cancelPending(sighting.id);
    await DatabaseService.instance.deleteSighting(sighting.id);
  }
}
