import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final Set<String> _favoriteIds = <String>{};
  bool _isLoaded = false;

  FavoritesProvider(this._firestoreService);

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  bool get isLoaded => _isLoaded;

  bool isFavorite(String meetingId) {
    return _favoriteIds.contains(meetingId);
  }

  Future<void> loadFavorites() async {
    if (_isLoaded) return;

    try {
      // 타임아웃을 설정하여 무한 대기 방지
      final favorites = await _firestoreService
          .getFavoriteMeetings()
          .timeout(const Duration(seconds: 10))
          .first;

      _favoriteIds.clear();
      _favoriteIds.addAll(favorites.map((meeting) => meeting.id));
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      print('Error loading favorites: $e');
      // 오류가 발생해도 로딩 완료로 표시 (빈 상태로)
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> addToFavorites(String meetingId) async {
    try {
      // 즉시 UI 업데이트
      _favoriteIds.add(meetingId);
      notifyListeners();

      // 백그라운드에서 Firebase 업데이트
      await _firestoreService.addToFavorites(meetingId);
    } catch (e) {
      print('Error adding to favorites: $e');
      // 실패 시 롤백
      _favoriteIds.remove(meetingId);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeFromFavorites(String meetingId) async {
    try {
      // 즉시 UI 업데이트
      _favoriteIds.remove(meetingId);
      notifyListeners();

      // 백그라운드에서 Firebase 업데이트
      await _firestoreService.removeFromFavorites(meetingId);
    } catch (e) {
      print('Error removing from favorites: $e');
      // 실패 시 롤백
      _favoriteIds.add(meetingId);
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> toggleFavorite(String meetingId) async {
    final wasFavorite = isFavorite(meetingId);

    if (wasFavorite) {
      await removeFromFavorites(meetingId);
    } else {
      await addToFavorites(meetingId);
    }

    return !wasFavorite; // 새로운 상태 반환
  }
}
