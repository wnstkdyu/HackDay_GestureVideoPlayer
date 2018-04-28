# 앞으로 할 일

## 코드의 가독성 유의
1. `tuple`을 지양하자.다른 이가 볼 때 한 번 더 타고 들어가야 한다.
2. 상수는 따로 빼서 변수로 저장하자.
3. 많은 `switch` 대신 `if else`로, 중복되는 로직은 대체하자.

## 로직 분리 시 유의할 점
어디서 처리하는 것이 나은지 한 번 더 생각하기.

## AVFoundation에 대해 다시 공부
문서화해서 보기 좋게 정리하자.

- [AVFoundation Programming Guide](https://developer.apple.com/library/content/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/00_Introduction.html)
- [Media Playback Programming Guide - Apple Developer Documentation](https://developer.apple.com/library/content/documentation/AudioVideo/Conceptual/MediaPlaybackGuide/Contents/Resources/en.lproj/Introduction/Introduction.html#//apple_ref/doc/uid/TP40016757-CH1-SW1)
  - 최대한 가이드를 따라 기본적인 Playback에 대한 개념 공부.
  - AVFoundation 기초 공부.
- [Advances in AVFoundation Playback - WWDC 2016 Session 503](https://developer.apple.com/videos/play/wwdc2016/503/)
  - `AVPlayerItem`의 *BufferingState* 공부.
  - 각 화질에 맞는 `preferredPeakBitRate`에 대한 정보로 화질 정보 구현.
- [What's New in HTTP Live Streaming - WWDC 2016 Session 504](https://developer.apple.com/videos/play/wwdc2016/504/)
  - HLS로 받은 `AVAsset`에 대한 자막 정보 얻어오기 공부.
