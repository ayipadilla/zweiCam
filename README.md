# zweiCam
zweiCam is an iOS camera application built around capturing two perspectives — front and back — at the same time.

The app supports two capture modes:

- **Photo** — captures a back-camera photo followed by a front-camera photo, with a 1.5-second interval between the two shots.
- **Video** — records the back and front cameras simultaneously as separate video assets, with optional audio.

Captured media is stored locally on the device and presented in a feed where users can browse photo and video captures.

*The name comes from “zwei”, the German word for two, reflecting the app's dual-camera concept.*

## Requirements

- iOS 17+
- Xcode
- A physical iOS device with multi-camera capture support

The iOS Simulator is not supported for camera capture.

## Build & Run

1. Clone the repository:

```bash
git clone <repository-url>
cd zweiCam
```
2. Open the project in Xcode:
```bash
open zweiCam.xcodeproj
```
3. Select a supported physical iOS device as the run destination.
4. Build and run the app from Xcode.
5. On first launch, zweiCam will request access to the camera and microphone. Camera access is required for capture. Microphone access is used for video audio capture.

## Device Support

Multi-camera capture (AVCaptureMultiCamSession) is only available on supported iOS hardware. zweiCam checks for multi-camera support at runtime and lets the user know when their device isn't supported.

The app has been tested on:

- iPhone 16
- iPad mini (A17 Pro)

## Got Questions?

Feel free to open a discussion in this repository.
