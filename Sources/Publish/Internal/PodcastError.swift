/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

internal struct PodcastError: Error {
    var path: Path
    var reason: Reason
}

extension PodcastError {
    enum Reason {
        case missingAudio
        case missingAudioDuration
        case missingAudioSize
        case missingMetadata
    }
}

extension PodcastError: PublishingErrorConvertible {
    func publishingError(forStepNamed stepName: String?) -> PublishingError {
        PublishingError(
            stepName: stepName,
            path: path,
            infoMessage: infoMessage
        )
    }

    private var infoMessage: String {
        switch reason {
        case .missingAudio:
            return "Podcast items need to include audio data"
        case .missingAudioSize:
            return "Podcast items need to include audio size info (audio.size)"
        case .missingAudioDuration:
            return "Podcast items need to include audio duration info (audio.duration)"
        case .missingMetadata:
            return "Podcast items need to define 'podcast' metadata"
        }
    }
}
