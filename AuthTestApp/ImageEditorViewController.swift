//
//  ImageEditorViewController.swift
//  AuthTestApp
//
//  Created by Marina Zeylan on 14.05.2024.
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import PencilKit

extension UISlider {
    var thumbCenterX: CGFloat {
        let trackRect = self.trackRect(forBounds: frame)
        let thumbRect = self.thumbRect(forBounds: bounds, trackRect: trackRect, value: value)
        return thumbRect.midX
    }
}

class ImageEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PKCanvasViewDelegate {
    
    @IBOutlet weak var forCanvasView: UIView!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var addImage: UILabel!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var filterScroll: UIScrollView!
    @IBOutlet weak var filterView: UIView!
    @IBOutlet weak var mainImage: UIImageView!
    //    @IBOutlet weak var sliderMain: UISlider!
    
    var canvasView = PKCanvasView()
    let toolPicker = PKToolPicker()
    var drawing: PKDrawing!
    
    var xCoord: CGFloat = 5
    let yCoord: CGFloat = 5
    let buttonWidth: CGFloat = 70
    let buttonHeight: CGFloat = 70
    let gapBetweenButtons: CGFloat = 5
    var filterName: String!
    var labelName: String!
    var centerVector: CIVector!
    var scaleFactor: CGFloat!
    var editingImage: UIImage!
    var tempFilter: CIFilter!
    var panGesture: UIPanGestureRecognizer!
    let imagePicker = UIImagePickerController()
    var filterList: [String] = [
        "CIPointillize", "CIColorCubeWithColorSpace", "CIColorPosterize", "CICrystallize", "CIColorInvert", "CIColorMonochrome",
        "CIFalseColor", "CIMaximumComponent", "CIMinimumComponent", "CILineOverlay", "CIPhotoEffectChrome", "CIPhotoEffectFade",
        "CIPhotoEffectInstant", "CIPhotoEffectNoir", "CIPhotoEffectProcess", "CIPhotoEffectTonal", "CIPhotoEffectTransfer",
        "CISepiaTone", "CIVignetteEffect", "CITorusLensDistortion", "CITwirlDistortion", "CIVortexDistortion",
        "CIGaussianBlur", "CIMotionBlur", "CIZoomBlur"
    ]
    
    let volatileFiltersName: [String] = [
        "CIZoomBlur", "CIMotionBlur", "CIVortexDistortion", "CITorusLensDistortion", "CITwirlDistortion", "CIGaussianBlur",  "CIVignetteEffect"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationController?.navigationBar.isHidden = true
        
        
        
        filterView.isHidden = true
        saveBtn.setTitleColor(.white, for: .normal)
        saveBtn.backgroundColor = UIColor.blueMain
        saveBtn.layer.cornerRadius = 10
        saveBtn.layer.masksToBounds = true
        cancelBtn.layer.cornerRadius = 10
        cancelBtn.layer.masksToBounds = true
        cancelBtn.layer.borderWidth = 1
        cancelBtn.layer.borderColor = UIColor.blueMain.cgColor
        
        mainImage.isUserInteractionEnabled = true
        editingImage = self.mainImage.image!
        centerVector = CIVector(x: self.editingImage.size.width/2, y: self.editingImage.size.height/2)
        
        
        //        sliderMain.value = 0
        
    }
    
    @IBAction func addImageForApp(_ sender: UIButton) {
        showAlertForImage()
    }
    
    private func showAlertForImage() {
        let alert = UIAlertController(title: "", message: "Выберете способ загрузки", preferredStyle: .alert)
        
        let cameraType = UIAlertAction(title: "Camera", style: .default) { (action) in
            self.chooseImg(source: .camera)
        }
        
        let libraryType = UIAlertAction(title: "Photo", style: .default) { (action) in
            self.chooseImg(source: .photoLibrary)
        }
        
        let cancelBtn = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(cameraType)
        alert.addAction(libraryType)
        alert.addAction(cancelBtn)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func chooseImg(source: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(source) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.allowsEditing = true
            picker.sourceType = source
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        mainImage.image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        mainImage.contentMode = .scaleAspectFit
        mainImage.clipsToBounds = true
        
        editingImage = self.mainImage.image!
        centerVector = CIVector(x: self.editingImage.size.width/2, y: self.editingImage.size.height/2)
        
        
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func addPencil(_ sender: UIButton) {
        
        mainImage.isHidden = true
        
        canvasView.delegate = self
        
        let imageView = UIImageView(image: mainImage.image)
        canvasView.drawingPolicy = .anyInput
        
        
        let subView = self.canvasView.subviews[0]
        subView.addSubview(imageView)
        subView.sendSubviewToBack(imageView)
        
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        //
        view.addSubview(canvasView)
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        
        
        
    }
    
    @IBAction func closePencilKit(_ sender: UIButton) {
        canvasView.drawing = PKDrawing()
        mainImage.isHidden = false
        canvasView.isHidden = true
        toolPicker.setVisible(false, forFirstResponder: canvasView)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        canvasView.frame = mainImage.bounds
    }
    
    
    @IBAction func savePhoto(_ sender: UIButton) {
        UIImageWriteToSavedPhotosAlbum(mainImage.image!, nil, nil, nil)
        let alert = UIAlertController(title: "Ура!", message: "Фотография успешно сохранена", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Выйти", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func closeFilters(_ sender: UIButton) {
        filterView.isHidden = true
    }
    
    
    @IBAction func changeOrientation(_ sender: UIButton) {
        mainImage.transform = mainImage.transform.rotated(by: .pi / 2)
    }
    
    @IBAction func addFilters(_ sender: UIButton) {
        filterView.isHidden = false
        self.addFiltersForImg()
    }
    
    @IBAction func changeSlider(_ sender: UISlider,  _ event: UIEvent) {
        let value = Int(sender.value)
        
        guard let touch = event.allTouches?.first, touch.phase != .ended else {
            
            DispatchQueue.global(qos: .userInteractive).async {
                
                @available(iOS, deprecated: 12.0)
                let openGLContext = EAGLContext(api: .openGLES2)
                @available(iOS, deprecated: 12.0)
                let context = CIContext(eaglContext: openGLContext!)
                self.tempFilter!.setDefaults()
                
                switch self.filterName {
                case "CIZoomBlur":
                    if #available(iOS 12.0, *) {
                        self.tempFilter!.setValue(value, forKey: kCIInputAmountKey)
                    }
                    self.tempFilter!.setValue(self.centerVector, forKey: kCIInputCenterKey)
                case  "CITorusLensDistortion":
                    self.tempFilter!.setValue(self.centerVector, forKey: kCIInputCenterKey)
                    self.tempFilter!.setValue(value, forKey: kCIInputWidthKey)
                case "CITwirlDistortion", "CIVortexDistortion", "CIVignetteEffect":
                    self.tempFilter!.setValue((value * 10), forKey: kCIInputRadiusKey)
                    self.tempFilter!.setValue(self.centerVector, forKey: kCIInputCenterKey)
                case "CIGaussianBlur":
                    self.tempFilter!.setValue(value, forKey: kCIInputRadiusKey)
                default:
                    break
                }
                
                
                let coreImage = CIImage(image: self.mainImage.image!)
                self.tempFilter!.setValue(coreImage, forKey: kCIInputImageKey)
                let filteredImageData = self.tempFilter!.value(forKey: kCIOutputImageKey) as! CIImage
                let filteredImageRef = context.createCGImage(filteredImageData, from: filteredImageData.extent)
                self.editingImage = UIImage(cgImage: filteredImageRef!)
                
                DispatchQueue.main.async {
                    self.mainImage.image = self.editingImage
                }
            }
            return
        }
        
        self.addImage.text = "\(value)"
        self.addImage.layer.position = CGPoint(x: sender.thumbCenterX, y: addImage.frame.midY)
        
    }
    
    
    func addFiltersForImg() {
        
        DispatchQueue.global(qos: .userInteractive).async {
            var itemCount = 0
            for index in 0..<self.filterList.count {
                
                itemCount = index
                
                let filterButton = UIButton(type: .custom)
                filterButton.frame = CGRect(x: self.xCoord, y: self.yCoord, width: self.buttonWidth, height: self.buttonHeight)
                filterButton.tag = itemCount
                filterButton.addTarget(self, action: #selector(self.filterTapped(_:)), for: .touchUpInside)
                filterButton.layer.masksToBounds = true
                filterButton.layer.cornerRadius = 5.0
                filterButton.clipsToBounds = true
                
                let filterName = self.filterList[index]
                
                @available(iOS, deprecated: 12.0)
                let openGLContext = EAGLContext(api: .openGLES2)
                @available(iOS, deprecated: 12.0)
                let context = CIContext(eaglContext: openGLContext!)
                
                let filter = CIFilter(name: filterName)
                let coreImage = CIImage(image: self.editingImage)
                filter!.setDefaults()
                
                self.volatileFiltersName.forEach({ (listFilterName) in
                    if filterName == listFilterName {
                        if filterName != "CIGaussianBlur" && filterName != "CIMotionBlur" && filterName != "CIZoomBlur" {
                            filter?.setValue(self.centerVector, forKey: kCIInputCenterKey)
                        }
                        
                        if filterName == "CIPointtillize" {
                            filter?.setValue(5, forKey: kCIInputRadiusKey)
                        }
                    }
                })
                
                filter!.setValue(coreImage, forKey: kCIInputImageKey)
                let filteredImageData = filter!.value(forKey: kCIOutputImageKey) as! CIImage
                let filteredImageRef = context.createCGImage(filteredImageData, from: filteredImageData.extent)
                let imageForButton = UIImage(cgImage: filteredImageRef!)
                
                DispatchQueue.main.async {
                    
                    filterButton.setBackgroundImage(imageForButton, for: .normal)
                    
                    self.xCoord += self.buttonWidth + self.gapBetweenButtons
                    self.filterScroll.addSubview(filterButton)
                    self.filterScroll.setNeedsDisplay()
                    
                    if filterName.hasPrefix("CIColor") {
                        self.labelName = String(filterName.dropFirst(7))
                    } else {
                        self.labelName = String(filterName.dropFirst(2))
                    }
                }
            }
            self.filterScroll.contentSize = CGSize(width: self.buttonWidth * CGFloat(itemCount + 3), height: self.yCoord)
        }
    }
        
    @objc fileprivate func filterTapped(_ sender: UIButton) {
        
        UIView.transition(with: self.mainImage,
                          duration: 0.75,
                          options: .transitionCrossDissolve,
                          animations: { self.mainImage.image = sender.backgroundImage(for: .normal) },
                          completion: nil)
        filterName = filterList[sender.tag]
//        sliderMain.setValue(25, animated: true)
        checkFilterName(name: filterName)
    }
    
    
    fileprivate func checkFilterName(name: String) {
//        self.sliderMain.isHidden = true
        
        volatileFiltersName.forEach { (filter) in
            
            if filter == name {
//                self.sliderMain.isHidden = false
                self.tempFilter = CIFilter(name: name)
            }
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
