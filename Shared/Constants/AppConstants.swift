import CoreGraphics
import Foundation

enum AppConstants {

    enum Timing {
        static let shortDelay: TimeInterval = 0.5
        static let mediumDelay: TimeInterval = 1.0
        static let longDelay: TimeInterval = 2.0
        static let reconnectionDelay: TimeInterval = 4.0
        static let animationDuration: TimeInterval = 0.3
    }

    enum UI {
        static let cornerRadius: CGFloat = 12

        static let smallSpacing: CGFloat = 12
        static let mediumSpacing: CGFloat = 20
        static let largeSpacing: CGFloat = 24

        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let standardPadding: CGFloat = 20

        static let statusIndicatorSize: CGFloat = 8
        static let iconFrameSize: CGFloat = 20
        static let largeIconSize: CGFloat = 60
        static let smallImageHeight: CGFloat = 80
        static let mediumImageHeight: CGFloat = 120
        static let largeImageHeight: CGFloat = 160
        static let maxImageHeight: CGFloat = 200
        static let minTextHeight: CGFloat = 100

        static let overlayOpacity: Double = 0.2
        static let progressScaleFactor: Double = 0.8
    }

    enum Grid {
        static let smallColumns: Int = 2
        static let mediumColumns: Int = 3
        static let largeColumns: Int = 4
        static let gridSpacing: CGFloat = 12
    }

    enum Image {
        static let thumbnailSize = CGSize(width: 300, height: 300)
        static let compressionQuality: CGFloat = 0.3
        static let renderingScale: CGFloat = 1.0
    }

    enum Audio {
        static let sampleRate: Double = 44100.0
        static let numberOfChannels: Int = 1
        static let recordingFileName = "recording.m4a"
    }

    enum Network {
        static let maxPayloadSizeKB: Double = 60.0
        static let bytesToKBDivisor: Double = 1024.0
    }

    enum StorageKeys {
        static let checklistData = "checklistData"
        static let authToken = "authToken"
        static let refreshToken = "refreshToken"
    }

    enum TestUser {
        static let noTestUserID: Int32 = -1
        static let noTestUserDisplayName = "No Testuser (Supervisor Entry)"
    }

    enum Validation {
        static let minTextLength: Int = 1
        static let maxTextLength: Int = 1000
        static let maxLength: Int = 1000
    }
}
