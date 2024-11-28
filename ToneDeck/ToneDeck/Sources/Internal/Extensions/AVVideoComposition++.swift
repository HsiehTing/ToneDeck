//
//  AVVideoComposition++.swift of MijickCameraView
//
//  Created by Tomasz Kurylik
//    - Twitter: https://twitter.com/tkurylik
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//
//  Copyright ©2024 Mijick. Licensed under MIT License.

import AVKit

// MARK: - Applying Filters
extension AVVideoComposition {
    static func applyFilters(to asset: AVAsset, applyFiltersAction: @escaping (AVAsynchronousCIImageFilteringRequest) -> Void, completionHandler: @escaping (AVVideoComposition?, (any Error)?) -> Void)
    {
        if #available(iOS 16.0, *) { applyFiltersNewWay(asset, applyFiltersAction, completionHandler) } else { applyFiltersOldWay(asset, applyFiltersAction, completionHandler) }
    }
}
private extension AVVideoComposition {
    @available(iOS 16.0, *)
    static func applyFiltersNewWay(_ asset: AVAsset, _ applyFiltersAction: @escaping (AVAsynchronousCIImageFilteringRequest) ->Void
        , _ completionHandler: @escaping (AVVideoComposition?, (any Error)?) -> Void) {
        AVVideoComposition.videoComposition(with: asset, applyingCIFiltersWithHandler: applyFiltersAction, completionHandler: completionHandler)
    }
    static func applyFiltersOldWay(_ asset: AVAsset, _ applyFiltersAction: @escaping (AVAsynchronousCIImageFilteringRequest) -> Void, _ completionHandler:

        @escaping (AVVideoComposition?, (any Error)?) -> Void) {
        let composition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: applyFiltersAction)
        completionHandler(composition, nil)
    }
}
