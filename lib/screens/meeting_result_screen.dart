import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/meeting.dart';

class MeetingResultScreen extends StatefulWidget {
  final Meeting meeting;

  const MeetingResultScreen({Key? key, required this.meeting})
      : super(key: key);

  @override
  _MeetingResultScreenState createState() => _MeetingResultScreenState();
}

class _MeetingResultScreenState extends State<MeetingResultScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  late FirestoreService _firestoreService;
  late AuthService _authService;
  List<Map<String, dynamic>> _participants = [];
  final List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _loadParticipants();
  }

  // 참가자 목록 불러오기
  Future<void> _loadParticipants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final participants =
          await _firestoreService.getMeetingParticipants(widget.meeting.id);

      // 호스트를 최상단으로 이동
      participants.sort((a, b) {
        if (a['userId'] == widget.meeting.hostId) return -1;
        if (b['userId'] == widget.meeting.hostId) return 1;
        return 0;
      });

      setState(() {
        _participants = participants;

        // 결과 데이터 초기화
        _results.clear();
        for (var participant in participants) {
          _results.add({
            'userId': participant['userId'],
            'name': participant['name'],
            'rank': 0, // 0은 아직 등수가 할당되지 않음을 의미
            'attended': true, // 기본적으로 참석으로 설정
          });
        }
      });
    } catch (e) {
      _showMessage('참가자 정보를 불러오는데 실패했습니다: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 결과 제출
  Future<void> _submitResults() async {
    // 등수 검증
    final attendedResults =
        _results.where((r) => r['attended'] == true).toList();
    final uniqueRanks =
        attendedResults.map((r) => r['rank']).where((rank) => rank > 0).toSet();

    if (uniqueRanks.length !=
        attendedResults.where((r) => r['rank'] > 0).length) {
      _showMessage('동일한 등수가 여러 명에게 지정되었습니다. 각 참가자에게 고유한 등수를 지정해주세요.');
      return;
    }

    if (attendedResults.any((r) => r['rank'] == 0)) {
      _showMessage('참석한 모든 참가자에게 등수를 지정해주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _firestoreService.recordMeetingResults(widget.meeting.id, _results);
      _showMessage('모임 결과가 성공적으로 저장되었습니다.');

      // 모임 완료 처리
      await _firestoreService.completeMeeting(widget.meeting.id);

      // 화면 닫기
      if (mounted) {
        Navigator.of(context).pop(true); // 결과 저장 성공 여부를 반환
      }
    } catch (e) {
      _showMessage('결과 저장 실패: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // 메시지 표시 헬퍼 함수
  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // 참가자 카드 위젯
  Widget _buildParticipantCard(Map<String, dynamic> participant, int index) {
    final bool isHost = participant['userId'] == widget.meeting.hostId;
    final userId = participant['userId'];

    // 결과 데이터 찾기
    final resultIndex = _results.indexWhere((r) => r['userId'] == userId);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isHost ? Colors.blue.shade300 : Colors.grey.shade300,
          width: isHost ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: participant['photoURL'] != null
                      ? NetworkImage(participant['photoURL'])
                      : null,
                  child: participant['photoURL'] == null
                      ? const Icon(Icons.person, size: 24, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            participant['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isHost)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '호스트',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              participant['tier'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '총점: ${participant['totalScore']}점',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // 참석 여부 체크박스
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Checkbox(
                        value: _results[resultIndex]['attended'],
                        onChanged: (value) {
                          setState(() {
                            _results[resultIndex]['attended'] = value;
                            // 불참 시 등수 초기화
                            if (value == false) {
                              _results[resultIndex]['rank'] = 0;
                            }
                          });
                        },
                      ),
                      const Text('참석'),
                    ],
                  ),
                ),
                // 등수 선택 드롭다운
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: '등수',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    value: _results[resultIndex]['rank'] > 0
                        ? _results[resultIndex]['rank']
                        : null,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('선택하세요'),
                      ),
                      for (int i = 1; i <= _participants.length; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text('$i등'),
                        ),
                    ],
                    onChanged: _results[resultIndex]['attended']
                        ? (value) {
                            setState(() {
                              _results[resultIndex]['rank'] = value;
                            });
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A55A2),
        title: const Text('모임 결과 입력', style: TextStyle(color: Colors.white)),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 설명 부분
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            '모임 결과 입력 가이드',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. 모든 참석자에게 등수를 지정해주세요.\n'
                        '2. 불참자는 체크를 해제하고 등수를 입력하지 않으셔도 됩니다.\n'
                        '3. 중복 등수는 지정할 수 없습니다.\n\n'
                        '등수별 점수: 1등(5점), 2등(3점), 3등(2점), 그 외(1점), 불참(0점)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),

                // 참가자 목록
                Expanded(
                  child: _participants.isEmpty
                      ? const Center(child: Text('참가자가 없습니다.'))
                      : ListView.builder(
                          itemCount: _participants.length,
                          itemBuilder: (context, index) {
                            return _buildParticipantCard(
                                _participants[index], index);
                          },
                        ),
                ),

                // 제출 버튼
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitResults,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A55A2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            '결과 저장하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
