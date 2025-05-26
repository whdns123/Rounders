import 'package:flutter/material.dart';
import '../services/user_profile_service.dart';

class GameResultTestScreen extends StatefulWidget {
  const GameResultTestScreen({super.key});

  @override
  State<GameResultTestScreen> createState() => _GameResultTestScreenState();
}

class _GameResultTestScreenState extends State<GameResultTestScreen> {
  final _userProfileService = UserProfileService();

  final _gameNameController = TextEditingController();
  bool _isWin = true;
  int _pointsChange = 100;
  bool _isLoading = false;

  @override
  void dispose() {
    _gameNameController.dispose();
    super.dispose();
  }

  Future<void> _addGameResult() async {
    if (_gameNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게임 이름을 입력해주세요')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _userProfileService.addGameResult(
        _gameNameController.text,
        _isWin,
        _isWin ? _pointsChange : -_pointsChange,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게임 결과가 추가되었습니다')),
        );

        _gameNameController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게임 결과 추가 실패: $e')),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게임 결과 테스트'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 현재 티어 정보
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      '현재 티어 정보',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '티어: ${_userProfileService.userTier.tierName}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'ELO 레이팅: ${_userProfileService.userTier.eloRating}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      '게임 수: ${_userProfileService.userTier.gamesPlayed} / 승리: ${_userProfileService.userTier.gamesWon}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 게임 결과 추가 폼
            const Text(
              '게임 결과 추가',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _gameNameController,
              decoration: const InputDecoration(
                labelText: '게임 이름',
                border: OutlineInputBorder(),
                hintText: '예) 브레인 서바이벌 - 강남',
              ),
            ),
            const SizedBox(height: 16),

            // 승패 선택
            Row(
              children: [
                const Text('게임 결과:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('승리'),
                  selected: _isWin,
                  onSelected: (selected) {
                    setState(() {
                      _isWin = true;
                    });
                  },
                  selectedColor: Colors.green.shade100,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('패배'),
                  selected: !_isWin,
                  onSelected: (selected) {
                    setState(() {
                      _isWin = false;
                    });
                  },
                  selectedColor: Colors.red.shade100,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 포인트 선택
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '포인트 변화: ${_isWin ? '+' : '-'}$_pointsChange',
                  style: TextStyle(
                    fontSize: 16,
                    color: _isWin ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  value: _pointsChange.toDouble(),
                  min: 50,
                  max: 300,
                  divisions: 5,
                  label: _pointsChange.toString(),
                  onChanged: (value) {
                    setState(() {
                      _pointsChange = value.toInt();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _addGameResult,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('게임 결과 추가하기'),
            ),
          ],
        ),
      ),
    );
  }
}
