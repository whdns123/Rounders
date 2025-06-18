import '../models/game.dart';

class SampleGameData {
  static List<Game> getSampleGames() {
    return [
      Game(
        id: 'game_1',
        title: '호러레이스',
        subtitle: '호러레이스를 한번 즐겨보세요',
        description: '필요하면 내가 너한테 딱 맞는 커리큘럼 짜줄게. 랩이든 팝이든, 멋은 결국 자신감 + 연습량이야.',
        prologue: '필요하면 내가 너한테 딱 맞는 커리큘럼 짜줄게. 랩이든 팝이든, 멋은 결국 자신감 + 연습량이야.',
        imageUrl:
            'https://boardlife.co.kr/wys2/swf_upload/2024/01/30/1706543211911027_lg.jpg',
        images: [
          'https://mblogthumb-phinf.pstatic.net/MjAyMDA3MjBfNiAg/MDAxNTk1MjQyMzE5OTU1.KseJzJ_7uvMlIP1x3v0yq-3FFWXD9__tLtLsuDnDKIcg.ay6M1Yjlug5Vw0lwWQ5sBiCwHHOm6qTzePXFBm208ugg.JPEG.dicemall/%ED%98%B8%EB%9F%AC2.jpg?type=w420',
          'https://images.steamusercontent.com/ugc/1613933019085718935/C931FF5A6FD6B10A765CA0ABA5475119F4A59658/?imw=637&imh=358&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true',
          'https://files.slack.com/files-tmb/T06B9PCLY1E-F08SJ6241T9-ebd8089351/20250516_213220_720.jpg',
          'https://files.slack.com/files-tmb/T06B9PCLY1E-F091QBYPLGM-4a75bcf67c/___________________360.png',
        ],
        timeTable: ['게임 설명 및 아이스브레이킹', '호러레이스 메인 게임 시작', '결과 발표 및 마무리'],
        benefits: ['스릴 넘치는 호러 게임 체험', '새로운 사람들과의 팀워크 경험'],
        targetAudience: [
          '추론 수학 전략 게임을 좋아하는 사람',
          '호러 장르를 즐기는 사람',
          '팀워크와 전략적 사고를 좋아하는 사람',
        ],
        minParticipants: 8,
        maxParticipants: 12,
        price: 25000,
        difficulty: '난이도 중',
        tags: ['추론', '수학', '전략'],
        rating: 4.5,
        reviewCount: 20,
      ),
      Game(
        id: 'game_2',
        title: '마피아 게임: 심리전의 끝판왕',
        subtitle: '누가 마피아인지 찾아내고, 마피아라면 끝까지 숨어라!',
        description: '클래식한 마피아 게임을 현대적으로 재해석한 심리전 게임입니다.',
        prologue: '낮에는 시민으로, 밤에는 마피아로. 당신의 연기력과 추리력을 시험해보세요.',
        imageUrl:
            'https://via.placeholder.com/400x300/333333/FFFFFF?text=Game+Image',
        images: [
          'https://search.pstatic.net/common/?src=https%3A%2F%2Fldb-phinf.pstatic.net%2F20250525_52%2F1748125958192TNHTx_JPEG%2F9359E72A-5968-4D72-AF7A-D13ECCF2FE1F.jpeg',
          'https://boardlife.co.kr/wys2/swf_upload/2024/01/30/1706543211911027_lg.jpg',
          'https://search.pstatic.net/common/?src=https%3A%2F%2Fldb-phinf.pstatic.net%2F20210510_205%2F1620643476435mf0XF_JPEG%2Fmme_mD3WHMoghdkyU8EKL3Lu.jpg',
          'https://ldb-phinf.pstatic.net/20210510_251/1620643352335oIQrR_JPEG/2VPZ18SigvDkO4F2x-n5xtrM.jpg',
        ],
        timeTable: [
          '19:00 - 게임 룰 설명 및 역할 배정',
          '19:30 - 1라운드 시작',
          '21:30 - 최종 결과 발표',
        ],
        benefits: ['우승팀에게 치킨 쿠폰 지급', '게임 후 뒤풀이 참여 기회'],
        targetAudience: [
          '심리전을 즐기는 사람',
          '연기와 추리를 좋아하는 사람',
          '새로운 사람들과 소통하고 싶은 사람',
        ],
        minParticipants: 8,
        maxParticipants: 16,
        price: 15000,
        difficulty: '난이도 중',
        tags: ['심리전', '추리'],
        rating: 4.2,
        reviewCount: 35,
      ),
      Game(
        id: 'game_3',
        title: '방탈출: 시간과의 싸움',
        subtitle: '60분 안에 모든 퍼즐을 풀고 탈출하세요!',
        description: '팀워크와 창의적 사고가 필요한 방탈출 게임입니다.',
        prologue: '갇힌 방에서 단서를 찾고 퍼즐을 풀어 제한 시간 내에 탈출해야 합니다.',
        imageUrl:
            'https://via.placeholder.com/400x300/333333/FFFFFF?text=Game+Image',
        images: [
          'https://search.pstatic.net/common/?src=https%3A%2F%2Fldb-phinf.pstatic.net%2F20250525_52%2F1748125958192TNHTx_JPEG%2F9359E72A-5968-4D72-AF7A-D13ECCF2FE1F.jpeg',
          'https://boardlife.co.kr/wys2/swf_upload/2024/01/30/1706543211911027_lg.jpg',
          'https://search.pstatic.net/common/?src=https%3A%2F%2Fldb-phinf.pstatic.net%2F20210510_205%2F1620643476435mf0XF_JPEG%2Fmme_mD3WHMoghdkyU8EKL3Lu.jpg',
          'https://ldb-phinf.pstatic.net/20210510_251/1620643352335oIQrR_JPEG/2VPZ18SigvDkO4F2x-n5xtrM.jpg',
        ],
        timeTable: [
          '18:00 - 팀 구성 및 룰 설명',
          '18:30 - 방탈출 게임 시작',
          '20:00 - 게임 종료 및 결과 발표',
        ],
        benefits: ['성공팀에게 상품권 지급', '기념품 증정', '단체 사진 촬영'],
        targetAudience: ['퍼즐과 추리를 좋아하는 사람', '팀워크를 중시하는 사람', '스릴을 즐기는 사람'],
        minParticipants: 4,
        maxParticipants: 8,
        price: 20000,
        difficulty: '난이도 중',
        tags: ['팀워크', '퍼즐'],
        rating: 4.7,
        reviewCount: 42,
      ),
    ];
  }

  static Map<String, dynamic> gameToFirestoreMap(Game game) {
    return {
      'title': game.title,
      'subtitle': game.subtitle,
      'description': game.description,
      'prologue': game.prologue,
      'imageUrl': game.imageUrl,
      'images': game.images,
      'timeTable': game.timeTable,
      'benefits': game.benefits,
      'targetAudience': game.targetAudience,
      'minParticipants': game.minParticipants,
      'maxParticipants': game.maxParticipants,
      'price': game.price,
      'difficulty': game.difficulty,
      'tags': game.tags,
      'rating': game.rating,
      'reviewCount': game.reviewCount,
    };
  }
}
