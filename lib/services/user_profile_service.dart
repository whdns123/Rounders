import '../models/user_tier.dart';
import 'firestore_service.dart';

class UserProfileService {
  // 싱글톤 인스턴스
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal() {
    // 생성자에서 초기화
    initialize();
  }

  // Firestore 서비스
  final FirestoreService _firestoreService = FirestoreService();

  // 캐시 데이터
  late UserTier _userTier = UserTier(
    rank: CardRank.two,
    suit: CardSuit.clubs,
    eloRating: 1000,
    gamesPlayed: 0,
    gamesWon: 0,
  );
  List<String> _achievements = [];
  List<Map<String, dynamic>> _gameHistory = [];

  // 사용자 통계 데이터
  int _totalScore = 0;
  int _meetingsPlayed = 0;
  String _userTierString = '브론즈';
  double _avgScore = 0.0;
  int _hostedMeetingsCount = 0;

  // 데이터 로딩 상태
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // 초기화 메서드
  Future<void> initialize() async {
    _isLoading = true;

    try {
      // 기본 티어 정보 설정 (초기값)
      _userTier = UserTier(
        rank: CardRank.two,
        suit: CardSuit.clubs,
        eloRating: 1000,
        gamesPlayed: 0,
        gamesWon: 0,
      );

      // 빈 업적 목록 설정 (초기값)
      _achievements = [];

      // 빈 게임 기록 설정 (초기값)
      _gameHistory = [];

      // 기본 통계 정보 설정 (초기값)
      _totalScore = 0;
      _meetingsPlayed = 0;
      _userTierString = '브론즈';
      _avgScore = 0.0;
      _hostedMeetingsCount = 0;

      // 사용자 통계 불러오기 (getUserStats 메서드는 있음)
      if (_firestoreService.currentUserId != null) {
        try {
          final stats = await _firestoreService
              .getUserStats(_firestoreService.currentUserId!);
          _totalScore = stats['totalScore'] ?? 0;
          _meetingsPlayed = stats['meetingsPlayed'] ?? 0;
          _userTierString = stats['tier'] ?? '브론즈';
          _avgScore = stats['avgScore'] ?? 0.0;

          // 호스트인 모임 수 불러오기
          try {
            final userData = await _firestoreService
                .getUserById(_firestoreService.currentUserId!);
            if (userData != null) {
              _hostedMeetingsCount = userData.hostedMeetings.length ?? 0;
            }
          } catch (hostError) {
            print('호스트 정보 불러오기 실패: $hostError');
          }
        } catch (statsError) {
          print('사용자 통계 불러오기 실패: $statsError');
          // 오류 발생 시 기본 통계 값 유지
        }
      }
    } catch (e) {
      print('유저 프로필 초기화 오류: $e');
      // 오류 시 기본값 사용 (이미 초기값으로 설정되어 있음)
    } finally {
      _isLoading = false;
    }
  }

  // 사용자 티어 정보 가져오기
  UserTier get userTier => _userTier;

  // 사용자 통계 정보
  int get totalScore => _totalScore;
  int get meetingsPlayed => _meetingsPlayed;
  String get userTierString => _userTierString;
  double get avgScore => _avgScore;
  int get hostedMeetingsCount => _hostedMeetingsCount;

  // 업적 목록 가져오기
  List<String> get achievements => _achievements;

  // 게임 기록 가져오기
  List<Map<String, dynamic>> get gameHistory => _gameHistory;

  // 티어 업데이트 (로컬만 업데이트)
  Future<void> updateTier(int additionalPoints) async {
    int newRating = _userTier.eloRating + additionalPoints;
    if (newRating < 1000) newRating = 1000;

    // 새 티어 계산
    _userTier = UserTier.tierFromElo(
      newRating,
      _userTier.gamesPlayed,
      _userTier.gamesWon,
    );

    // Firestore 업데이트 메서드가 없으므로 로컬만 변경
    print('티어 업데이트됨 (로컬만): ${_userTier.tierName}');
  }

  // 게임 결과 추가 (로컬만 업데이트)
  Future<void> addGameResult(
      String gameName, bool isWin, int pointsChange) async {
    // 로컬 데이터만 업데이트
    final now = DateTime.now();
    _gameHistory.add({
      'gameName': gameName,
      'result': isWin ? 'Win' : 'Loss',
      'pointsGained': pointsChange,
      'date': '${now.year}-${now.month}-${now.day}',
    });

    // 점수 업데이트
    _totalScore += pointsChange;

    print('게임 결과 추가됨 (로컬만): $gameName, ${isWin ? '승리' : '패배'}, $pointsChange점');
  }

  // 업적 추가 (로컬만 업데이트)
  Future<void> addAchievement(String achievement) async {
    if (!_achievements.contains(achievement)) {
      // 로컬 데이터만 업데이트
      _achievements.add(achievement);
      print('업적 추가됨 (로컬만): $achievement');
    }
  }

  // 데이터 새로고침
  Future<void> refreshData() async {
    await initialize();
  }
}
