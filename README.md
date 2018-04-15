# HackDay_GestureVideoPlayer

## 요구사항(필수)
비디오 리스트뷰
- 비디오 리스트 제공 (컬렉션뷰)
  - 구현.
- 비디오 리스트는 네트워크를 통해서 받는다. (URLSession, 또는 Alamofire)
  -  `AVAssetDownloadURLSession`을 사용함.
- 비디오 클릭시 바로 플레이어 재생
  - VideoListViewController에서 PlayerViewController에 다운 중인 Asset을 전달해 재생.

플레이어 (가로모드만 제공)
- 재생(버튼) / 정지(버튼)
  - 버튼 구현.
- Seeking(슬라이더) / 10초전(버튼)
  - 구현.
- 제스쳐
  - 탭: 탭할때 마다 컨트롤뷰 토글
    - **`Dispatch.main.ayncAfter`를 통해 구현했지만 불안정.**
  - 더블 탭
    - 영상 확대 및 원본 비율 토글
  - 좌우 팬: Seeking
    - 구현.
  - 좌측 상하: 화면 밝기
    - 구현.
  - 우측 상하: 볼륨 조절
    - 구현.
  - 컨트롤뷰 잠금
  
## 요구사항(선택)
플레이어
- 메뉴(dummy 데이터로 표시)
  - 화질정보 (고화질, 일반화질, 저화질)
    - `preferredPeakBitRate`를 제한하여 화질 수정하기.
  - 자막정보 (한국어, 영어, 자막끄기)
    - PlayerItem의 select 메서드를 통해 자막 설정.

## 문제점
- 컨트롤뷰를 토글 시 애니메이션 간에 엉켜서 제대로 나타나지 않거나 갑자기 나타나는 경우 발생.
- 자막과 화질 설정을 UITableView을 통해서 하려고 밑에서 나타나게끔 했으나 영상이 재생 중일 경우 바로 닫히는 문제가 존재.
- 자막을 지원하는 영상으로 테스트를 하지 못함.
