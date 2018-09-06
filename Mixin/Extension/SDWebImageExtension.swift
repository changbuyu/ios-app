import SDWebImage

extension SDWebImageManager {
    
    static let animatedImageManager = SDWebImageManager(cache: SDImageCache(), downloader: SDWebImageDownloader.shared())
    
}

extension URL {
    
    var maybeAnimatedImageURL: Bool {
        let lowercasedPathExtension = pathExtension.lowercased()
        return lowercasedPathExtension.hasSuffix(ExtensionName.webp.rawValue)
            || lowercasedPathExtension.hasSuffix(ExtensionName.gif.rawValue)
    }
    
}

extension FLAnimatedImageView {
    
    func animationSafeSetImage(url: URL?, placeholderImage: UIImage? = nil, options: SDWebImageOptions = [], progress: SDWebImageDownloaderProgressBlock? = nil, completed: SDExternalCompletionBlock? = nil) {
        if let url = url, url.maybeAnimatedImageURL {
            setAnimationImage(url: url, placeholderImage: placeholderImage, options: options, progress: progress, completed: completed)
        } else {
            sd_setImage(with: url, placeholderImage: placeholderImage, options: options, progress: progress, completed: completed)
        }
    }
    
    private func setAnimationImage(url: URL?, placeholderImage: UIImage? = nil, options: SDWebImageOptions = [], progress: SDWebImageDownloaderProgressBlock? = nil, completed: SDExternalCompletionBlock? = nil) {
        let group = DispatchGroup()
        let context: [String: Any] = [
            SDWebImageInternalSetImageGroupKey: group,
            SDWebImageExternalCustomManagerKey: SDWebImageManager.animatedImageManager
        ]
        let setImageBlock = { [weak self] (image: UIImage?, data: Data?) in
            guard let weakSelf = self else {
                return
            }
            if let animatedImage = image?.sd_FLAnimatedImage {
                weakSelf.animatedImage = animatedImage
                weakSelf.image = nil
                group.leave()
            } else if NSData.sd_imageFormat(forImageData: data) == .GIF {
                weakSelf.image = image?.images?.first ?? image
                weakSelf.animatedImage = nil
                DispatchQueue.global(qos: .userInitiated).async {
                    let animatedImage = FLAnimatedImage(animatedGIFData: data,
                                                        optimalFrameCacheSize: weakSelf.sd_optimalFrameCacheSize,
                                                        predrawingEnabled: weakSelf.sd_predrawingEnabled)
                    DispatchQueue.main.async {
                        weakSelf.animatedImage = animatedImage
                        weakSelf.image = nil
                        group.leave()
                    }
                }
            } else {
                weakSelf.image = image
                weakSelf.animatedImage = nil
                group.leave()
            }
        }
        sd_internalSetImage(with: url,
                            placeholderImage: nil,
                            options: options,
                            operationKey: nil,
                            setImageBlock: setImageBlock,
                            progress: progress,
                            completed: completed,
                            context: context)
    }
    
}
