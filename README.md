# HackDay_GestureVideoPlayer

## 데모 영상
[![Video Label](http://img.youtube.com/vi/F3nACRtB1TY/0.jpg)](https://youtu.be/F3nACRtB1TY)

## 공부 방법
- [Media Playback Programming Guide - Apple Developer Documentation](https://developer.apple.com/library/content/documentation/AudioVideo/Conceptual/MediaPlaybackGuide/Contents/Resources/en.lproj/Introduction/Introduction.html#//apple_ref/doc/uid/TP40016757-CH1-SW1)
  - 최대한 가이드를 따라 기본적인 Playback에 대한 개념 공부.
  - AVFoundation 기초 공부.
- [Advances in AVFoundation Playback - WWDC 2016 Session 503](https://developer.apple.com/videos/play/wwdc2016/503/)
  - `AVPlayerItem`의 *BufferingState* 공부.
  - 각 화질에 맞는 `preferredPeakBitRate`에 대한 정보로 화질 정보 구현.
- [What's New in HTTP Live Streaming - WWDC 2016 Session 504](https://developer.apple.com/videos/play/wwdc2016/504/)
  - HLS로 받은 `AVAsset`에 대한 자막 정보 얻어오기 공부.

## 요구사항(필수)
비디오 리스트뷰
- 비디오 리스트 제공 (컬렉션뷰)
  - 구현.
- 비디오 리스트는 네트워크를 통해서 받는다. (URLSession, 또는 Alamofire)
  -  `AVAssetDownloadURLSession`을 사용함.
  -  다운로드가 된 asset의 local path를 `UserDefaults`에 remoteURL를 key 값으로 저장해 다시 다운로드 받지 않게끔 구현.
- 비디오 클릭시 바로 플레이어 재생
  - VideoListViewController에서 PlayerViewController에 다운 중인 Asset을 전달해 재생.
  - bufferingState이 waiti

플레이어 (가로모드만 제공)
- 재생(버튼) / 정지(버튼)
  - 버튼 구현.
- Seeking(슬라이더) / 10초전(버튼)
  - 구현.
- 제스쳐
  - 탭: 탭할때 마다 컨트롤뷰 토글
    - **`Dispatch.main.ayncAfter`를 통해 컨트롤 뷰가 나타난 뒤 2초 후에 사라지도록 통해 구현했지만 불안정.**
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
    - **`AVAsset`에서 자막 정보 얻어오기 구현 중 어려움.**

## 문제점
- 컨트롤뷰를 토글 시 애니메이션 간에 엉켜서 제대로 나타나지 않거나 갑자기 나타나는 경우 발생.
- 자막과 화질 설정을 UITableView을 통해서 하려고 밑에서 나타나게끔 했으나 영상이 재생 중일 경우 바로 닫히는 문제가 존재.
- 자막을 뿌려주는 것을 구현하지 못함.
