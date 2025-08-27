import SwiftUI
import PhotosUI

enum PhotoSource {
    case photoLibrary
    case camera
}

struct PhotoPicker: UIViewControllerRepresentable {
    let source: PhotoSource
    var onComplete: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        switch source {
        case .photoLibrary:
            var config = PHPickerConfiguration(photoLibrary: .shared())
            config.selectionLimit = 1
            config.filter = .images
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = context.coordinator
            return picker
        case .camera:
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = context.coordinator
            return picker
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onComplete: ([UIImage]) -> Void
        init(onComplete: @escaping ([UIImage]) -> Void) { self.onComplete = onComplete }
        
        // PHPickerViewControllerDelegate
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            let group = DispatchGroup()
            var images: [UIImage] = []

            for res in results {
                group.enter()
                res.itemProvider.loadObject(ofClass: UIImage.self) { reading, _ in
                    if let img = reading as? UIImage {
                        images.append(img)
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.onComplete(images)
            }
        }
        
        // UIImagePickerControllerDelegate
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            if let image = info[.originalImage] as? UIImage {
                onComplete([image])
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}