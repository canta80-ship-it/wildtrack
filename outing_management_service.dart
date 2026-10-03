import '../models/track_session.dart';
import 'community_service.dart';
import 'database_service.dart';
import 'tracking_service.dart';

class OutingManagementService {
  OutingManagementService({Future<void> Function(String)? deletePublic})
    : _deletePublic =
          deletePublic ??
          ((id) async {
            await CommunityService.instance.api(
              'activities/$id',
              method: 'DELETE',
            );
          });
  static final instance = OutingManagementService();
  final Future<void> Function(String) _deletePublic;
  Future<void> delete(TrackSession session) async {
    final tracker = TrackingService.instance;
    if ((tracker.isTracking || tracker.busy) &&
        tracker.activeSessionId == session.id) {
      throw Exception(
        'Termina la registrazione prima di eliminare questa uscita.',
      );
    }
    if (session.isPublic) await _deletePublic(session.id);
    await DatabaseService.instance.deleteSession(session.id);
  }
}
