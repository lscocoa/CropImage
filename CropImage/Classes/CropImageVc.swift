import UIKit

public class CropImageVc: UIViewController {
    private let image: UIImage
    private let cropRatio: CGFloat
    private let cropType: CropType
    private let complete: ((UIImage) -> Void)
    public enum CropType {
        case rectangle(CGFloat)
        case circular
    }
    public static func show(_ img: UIImage,
              fromVc: UIViewController,
              cropType: CropType = .rectangle(1.0),
              complete: @escaping ((UIImage) -> Void)) {
        let vc = CropImageVc(img, cropType: cropType, complete: complete)
        vc.modalPresentationStyle = .fullScreen
        fromVc.present(vc, animated: true)
    }
    private init(_ img: UIImage,
         cropType: CropType = .rectangle(1.0),
         complete: @escaping ((UIImage) -> Void)) {
        if let img = img.fixedOrientation() {
            image = img
        } else {
            image = img
        }
        self.cropType = cropType
        switch cropType {
        case .rectangle(let cropRatio):
            self.cropRatio = cropRatio
        case .circular:
            self.cropRatio = 1.0
        }
        self.complete  = complete
        super.init(nibName: nil, bundle: nil)
    }
    private let screenSize: CGSize = UIScreen.main.bounds.size
    private lazy var contentImgView: UIImageView = {
        $0.backgroundColor = .clear
        $0.contentMode = .scaleAspectFill
        return $0
    }(UIImageView())
    private lazy var zoomScrollView: UIScrollView = {
        $0.backgroundColor = .clear
        $0.minimumZoomScale = 1
        $0.maximumZoomScale = 3
        $0.zoomScale = 1
        $0.layer.borderWidth = 1.5
        $0.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        $0.layer.masksToBounds = false
        switch cropType {
        case .circular:
            $0.layer.cornerRadius = contentMaxSize.width / 2.0
        case .rectangle: break
        }
        return $0
    }(UIScrollView())
    private lazy var maskShapLayer: CAShapeLayer = {
        $0.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor
        $0.fillRule = .evenOdd
        return $0
    }(CAShapeLayer())
    
    private lazy var bottomBar: UIView = {
        $0.backgroundColor = .clear
        return $0
    }(UIView())
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        let scr_y = (screenSize.height - contentMaxSize.height)/2.0
        zoomScrollView.frame = CGRect(origin: CGPoint(x: 0, y: scr_y), size: contentMaxSize)
        view.addSubview(zoomScrollView)
        var img_w, img_h: CGFloat
        var ofs_x: CGFloat = 0, ofs_y: CGFloat = 0
        if image.size.width/image.size.height <= cropRatio {
            img_w = contentMaxSize.width
            img_h = contentMaxSize.width * image.size.height / image.size.width
            ofs_y = (img_h - contentMaxSize.height)/2.0
        } else {
            img_h = contentMaxSize.height
            img_w = contentMaxSize.height * image.size.width / image.size.height
            ofs_x = (img_w - contentMaxSize.width)/2.0
        }
        zoomScrollView.delegate = self
        contentImgView.image = image
        contentImgView.frame = CGRect(origin: .zero, size: CGSize(width: img_w, height: img_h))
        zoomScrollView.addSubview(contentImgView)
        
        zoomScrollView.contentSize = CGSize(width: img_w, height: img_h)
        zoomScrollView.contentOffset = CGPoint(x: ofs_x, y: ofs_y)
        
        if let ges = zoomScrollView.pinchGestureRecognizer {
            view.addGestureRecognizer(ges)
        }
        view.layer.addSublayer(maskShapLayer)
        view.addSubview(bottomBar)
        for (idx, title) in ["Cancel", "Crop"].enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(title, for: .normal)
            btn.frame = CGRect(x: 0 + (screenSize.width - 80)*CGFloat(idx), y: 0, width: 80, height: 50)
            btn.titleLabel?.font = .systemFont(ofSize: 18)
            btn.setTitleColor(UIColor(red: 241/255.0, green: 241/255.0, blue: 241/255.0, alpha: 1), for: .normal)
            btn.tag = idx
            btn.addTarget(self, action: #selector(actionBtnClick(_:)), for: .touchUpInside)
            bottomBar.addSubview(btn)
        }
    }
    @objc private func actionBtnClick(_ btn: UIButton) {
        dismiss(animated: true)
        if btn.tag == 1, let image = cropImage() {
            switch cropType {
            case .rectangle:
                complete(image)
            case .circular:
                guard let img = image.ovalClip()
                else { return }
                complete(img)
            }
        }
    }
}
extension CropImageVc {
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: screenSize),
                                cornerRadius: 0)
        var cropPath: UIBezierPath
        switch cropType {
        case .rectangle:
            cropPath = UIBezierPath(roundedRect: zoomScrollView.frame, cornerRadius: 0)
        case .circular:
            cropPath = UIBezierPath(ovalIn: zoomScrollView.frame)
        }
        path.append(cropPath)
        maskShapLayer.path = path.cgPath
        bottomBar.frame = CGRect(x: 0,
                                 y: screenSize.height - (50 + view.safeAreaInsets.bottom),
                                 width: contentMaxSize.width,
                                 height: 50)
    }
    private var contentMaxSize: CGSize {
        return CGSize(width: screenSize.width, height: screenSize.width/cropRatio)
    }
    private func centerContent() {
        var imageViewFrame = contentImgView.frame
        let scrollBounds = CGRect(origin: .zero, size: contentMaxSize)
        if imageViewFrame.size.height > scrollBounds.size.height {
            imageViewFrame.origin.y = 0.0
        }else {
            imageViewFrame.origin.y = (scrollBounds.size.height - imageViewFrame.size.height) / 2.0
        }
        if imageViewFrame.size.width < scrollBounds.size.width {
            imageViewFrame.origin.x = (scrollBounds.size.width - imageViewFrame.size.width) / 2.0
        } else {
            imageViewFrame.origin.x = 0.0
        }
        contentImgView.frame = imageViewFrame
    }
    private func cropImage() -> UIImage? {
        let scale  = UIScreen.main.scale
        let offset = zoomScrollView.contentOffset
        //
        var zoom = zoomScrollView.zoomScale
        //
        zoom = zoom / scale
        // If the image is not resampled, transform the coordinates.
        if image.size.width/image.size.height <= cropRatio {
            zoom = zoom / (image.size.width / (contentMaxSize.width * scale))
        } else {
            zoom = zoom / (image.size.height / (contentMaxSize.height * scale))
        }
        let tmp_w = zoomScrollView.frame.size.width
        let tmp_h = zoomScrollView.frame.size.height
        let rect = CGRect(x: offset.x / zoom,
                          y: offset.y / zoom,
                          width: tmp_w / zoom,
                          height: tmp_h / zoom)
        guard let imgRef = image.cgImage,
              let cropRef = imgRef.cropping(to: rect)
        else { return nil }
        return UIImage(cgImage: cropRef)
    }
}
extension CropImageVc: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentImgView
    }
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent()
    }
}
