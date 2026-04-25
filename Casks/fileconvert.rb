cask "fileconvert" do
  version "1.0.0"
  sha256 "eba1113b80836e668d26a208686117f82f8925d70209ceb6c704d15960d0295b"

  url "https://github.com/leonascim21/homebrew-fileconvert/releases/download/v#{version}/FileConvert.zip"
  name "File Convert"
  desc "Convert images, PDFs, movies, and Word documents between formats"
  homepage "https://github.com/leonascim21/homebrew-fileconvert"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :tahoe"

  app "FileConvert.app"

  zap trash: [
    "~/Library/Preferences/com.leonascim.FileConvert.plist",
    "~/Library/Saved Application State/com.leonascim.FileConvert.savedState",
  ]

  caveats <<~EOS
    FileConvert is not notarized. On first launch macOS Gatekeeper may block it.
    To allow it to run, either:

      • Right-click FileConvert.app in /Applications, choose "Open", then confirm; or
      • Run:  xattr -dr com.apple.quarantine /Applications/FileConvert.app
  EOS
end
