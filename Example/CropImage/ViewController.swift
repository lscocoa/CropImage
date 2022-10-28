import UIKit
import CropImage
class ViewController: UIViewController {
    lazy var imageView: UIImageView = {
        $0.backgroundColor = .lightGray
        $0.contentMode = .scaleAspectFit
        $0.isUserInteractionEnabled = true
        return $0
    }(UIImageView())
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        imageView.frame = CGRect(origin: CGPoint(x: 0, y: 150),
                                 size: CGSize(width: view.bounds.width, height: view.bounds.width))
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(imageView)
        let tap = UITapGestureRecognizer(target: self, action: #selector(takeOrChoosePhoto))
        imageView.addGestureRecognizer(tap)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController {
    @objc func takeOrChoosePhoto() {
        let alertVc = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Take Photo", style: .default) { action in
                let imgPicker = UIImagePickerController()
                imgPicker.delegate = self
                imgPicker.sourceType = .camera
                imgPicker.modalPresentationStyle = .fullScreen
                self.present(imgPicker, animated: true, completion: nil)
            }
            alertVc.addAction(cameraAction)
        }
        let albumAction = UIAlertAction(title: "Choose Album", style: .default) { action in
            let imgPicker = UIImagePickerController()
            imgPicker.delegate = self
            imgPicker.sourceType = .photoLibrary
            imgPicker.modalPresentationStyle = .fullScreen
            self.present(imgPicker, animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertVc.addAction(albumAction)
        alertVc.addAction(cancelAction)
        present(alertVc, animated: true, completion: nil)
    }
}
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        else { return }
        CropImageVc.show(image, fromVc: self, cropType: .circular) { [weak self] img in
            guard let self = self else { return }
            self.imageView.image = img
        }
    }
}
