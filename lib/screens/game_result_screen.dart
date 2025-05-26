import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meeting.dart';
import '../models/game_result.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class GameResultScreen extends StatefulWidget {
  final Meeting meeting;

  const GameResultScreen({super.key, required this.meeting});

  @override
  State<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen> {
  bool _isLoading = false;
  final List<ParticipantResult> _results = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeResults();
  }

  // 참가자 목록에서 결과 초기화
  void _initializeResults() {
    // 각 참가자마다 결과 입력 항목 추가
    int rank = 1;
    for (final userId in widget.meeting.participants) {
      _results.add(
        ParticipantResult(
          userId: userId,
          scoreController: TextEditingController(),
          tags: [],
          rank: rank++,
        ),
      );
    }
  }

  // 게임 결과 제출
  Future<void> _submitResults() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 폼 저장
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      // 각 참가자별 결과 객체 생성
      final List<GameResult> gameResults = [];
      for (final result in _results) {
        final score = int.tryParse(result.scoreController.text) ?? 0;

        gameResults.add(
          GameResult(
            userId: result.userId,
            userName: result.displayName,
            score: score,
            rank: result.rank,
            tags: result.tags,
          ),
        );
      }

      // Firestore에 결과 저장
      await firestoreService.submitGameResults(
        widget.meeting.id,
        gameResults,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게임 결과가 등록되었습니다!')),
        );
        Navigator.pop(context); // 결과 등록 후 이전 화면으로 돌아가기
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('결과 등록 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // 컨트롤러 해제
    for (final result in _results) {
      result.scoreController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게임 결과 입력'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final result = _results[index];
                        return ParticipantResultCard(
                          result: result,
                          onRankChanged: (newRank) {
                            setState(() {
                              result.rank = newRank;
                            });
                          },
                          onTagAdded: (tag) {
                            setState(() {
                              if (!result.tags.contains(tag)) {
                                result.tags.add(tag);
                              }
                            });
                          },
                          onTagRemoved: (tag) {
                            setState(() {
                              result.tags.remove(tag);
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitResults,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          '결과 제출하기',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// 참가자 결과 데이터 클래스
class ParticipantResult {
  final String userId;
  final TextEditingController scoreController;
  String displayName;
  int rank;
  List<String> tags;

  ParticipantResult({
    required this.userId,
    required this.scoreController,
    this.displayName = '참가자',
    required this.rank,
    required this.tags,
  });
}

// 참가자 결과 입력 카드
class ParticipantResultCard extends StatelessWidget {
  final ParticipantResult result;
  final Function(int) onRankChanged;
  final Function(String) onTagAdded;
  final Function(String) onTagRemoved;

  const ParticipantResultCard({
    super.key,
    required this.result,
    required this.onRankChanged,
    required this.onTagAdded,
    required this.onTagRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 참가자 정보
            Text(
              '참가자: ${result.displayName}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 점수 입력
            TextFormField(
              controller: result.scoreController,
              decoration: const InputDecoration(
                labelText: '점수',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '점수를 입력해주세요';
                }
                if (int.tryParse(value) == null) {
                  return '유효한 숫자를 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 순위 선택
            Row(
              children: [
                const Text('순위: '),
                DropdownButton<int>(
                  value: result.rank,
                  items: List.generate(
                    10, // 최대 10등까지 선택 가능
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('${index + 1}등'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      onRankChanged(value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 태그 추가
            const Text(
              '태그:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // 태그 칩
            Wrap(
              spacing: 8,
              children: [
                ...result.tags.map((tag) => Chip(
                      label: Text(tag),
                      onDeleted: () => onTagRemoved(tag),
                    )),
                ActionChip(
                  label: const Text('태그 추가'),
                  onPressed: () => _showTagDialog(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 태그 추가 다이얼로그
  void _showTagDialog(BuildContext context) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('태그 추가'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: '태그 이름',
            hintText: '예: MVP, 선플레이어, 베스트 플레이 등',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final tag = textController.text.trim();
              if (tag.isNotEmpty) {
                onTagAdded(tag);
              }
              Navigator.pop(context);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    ).then((_) => textController.dispose());
  }
}
