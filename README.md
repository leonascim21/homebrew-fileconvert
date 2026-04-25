# FileConvert

A small macOS utility for converting files between common formats — images, PDFs, movies, and Word documents.

## Install

```sh
brew install --cask leonascim21/fileconvert/fileconvert
```

This taps the repo and installs `FileConvert.app` into `/Applications`.

### First launch

This build is not notarized, so macOS Gatekeeper may block it the first time. Either:

- Right-click `FileConvert.app` in `/Applications`, choose **Open**, and confirm; **or**
- Run:
  ```sh
  xattr -dr com.apple.quarantine /Applications/FileConvert.app
  ```

## Requirements

- macOS 26 (Tahoe) or later
- Universal binary (Apple Silicon + Intel)

## Uninstall

```sh
brew uninstall --cask leonascim21/fileconvert/fileconvert
brew untap leonascim21/fileconvert
```

## Building from source

```sh
git clone https://github.com/leonascim21/homebrew-fileconvert.git
cd homebrew-fileconvert
open FileConvert.xcodeproj
```

## License

[MIT](LICENSE)
