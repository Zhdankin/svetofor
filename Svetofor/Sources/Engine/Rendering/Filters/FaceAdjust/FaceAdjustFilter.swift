//
//  FaceAdjustFilter.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 7/1/18.
//  Copyright © 2018 Dmytro Hrebeniuk. All rights reserved.
//

import Foundation
import Metal
import Vision
import CoreMedia
import CoreVideo
import CoreGraphics
import UIKit
import CoreML



struct FaceAdjustUniforms {
    var lipsAdjustValue: Float
    var scaleX: Float
    var scaleY: Float
}


extension CIImage {
    
    func createPixelBuffer(in cicontenxt: CIContext = CIContext()) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        let width = Int(Int(self.extent.width))
        let height = Int(Int(self.extent.height))
        CVPixelBufferCreate(kCFAllocatorDefault,
                            width,
                            height,
                            kCVPixelFormatType_32BGRA,
                            attrs,
                            &pixelBuffer)
        pixelBuffer.map { cicontenxt.render(self, to: $0) }
        
        return pixelBuffer
    }
    
}

extension MLMultiArray {
    
    var argMax: (index: Int, value: Float) {
        var maxIndex = 0
        var maxValue = self[0].floatValue
        
        for index in 0..<count {
            let currentValue = self[index].floatValue
            if currentValue > maxValue {
                maxIndex = index
                maxValue = currentValue
            }
        }
        
        return  (index: maxIndex, value: maxValue)
    }
    
}


extension Array where Iterator.Element == CGPoint {
    
    var rect: CGRect {
        let maxX = self.map { $0.x }.max() ?? 0.0
        let minX = self.map { $0.x }.min() ?? 0.0
        
        let maxY = self.map { $0.y }.max() ?? 0.0
        let minY = self.map { $0.y }.min() ?? 0.0

        return CGRect(origin: CGPoint(x: minX, y: minY), size: CGSize(width: maxX - minX, height: maxY - minY))
    }
    
}

class FaceAdjustFilter: Filter {
    
    var isEnabled: Bool = true
 
    var lipsAdjustValue: Float = 0.0

    private var device: MTLDevice?
    private var computePipelineState: MTLComputePipelineState?
    private var outTexture: MTLTexture?
    private var imageCropping: ImageCropping?
    
    var shouldStorePictures = false
    
    init(device: MTLDevice?) {
        self.device = device
        let defaultLibrary = self.device?.makeDefaultLibrary()
        if let computeShader = defaultLibrary?.makeFunction(name: "faceAdjustKernel") {
            if let computePipelineState = try? self.device?.makeComputePipelineState(function: computeShader) {
                self.computePipelineState = computePipelineState
            }
        }
        
        imageCropping = ImageCropping(device: device)
    }
    
    private func createMask(width: Int, height: Int, with face: VNFaceObservation) -> (texture: MTLTexture, points: [CGPoint])? {
        guard let metalDevice = self.device else {
            return nil
        }
        
        let bitmapBytesPerRow = width * 4
        let context = CGContext(data: nil, width:  width, height:  height, bitsPerComponent: 8, bytesPerRow: bitmapBytesPerRow, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 1.0, 1.0]).map() { context?.setStrokeColor($0) }

        context?.setLineWidth(1.0)
        
        var findedPoints = [CGPoint]()
        
        
        if let points = face.landmarks?.faceContour?.pointsInImage(imageSize: CGSize(width: width, height: height)) {
            findedPoints.append(contentsOf: points)
            let path = CGMutablePath()
            
            if let point = points.first {
                path.move(to: point)
            }
            
            for point in points {
                path.addLine(to: point)
            }
            
            context?.addPath(path)
            context?.drawPath(using: CGPathDrawingMode.fill)
        }
        
        return context?.createTexture(device: metalDevice).map { (texture: $0, points: findedPoints) }
    }

    func applyEffect(inputTexture: MTLTexture, in commandBuffer: MTLCommandBuffer?) -> MTLTexture? {
        return inputTexture
    }
   
    private lazy var mlModel: TonguePositionClassification? = {
        let configuration = MLModelConfiguration()
        let mlModel = try? TonguePositionClassification(configuration: configuration)

        return mlModel
    }()
    
    private lazy var mlModel2: TongueClassifier? = {
        let configuration = MLModelConfiguration()
        let mlModel = try? TongueClassifier(configuration: configuration)

        return mlModel
    }()
    
    
    
    private lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let configuration = MLModelConfiguration()
            let mlModel = try TonguePositionClassification(configuration: configuration)
            let visionModel = try VNCoreMLModel(for: mlModel.model)
            let request = VNCoreMLRequest(model: visionModel) { request, _ in
                if let classifications = request.results as? [VNClassificationObservation] {
                    if let identifier = classifications.first?.identifier {
                        print("\(identifier)")
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PredictedTongues"), object: identifier)
                    }
                }
                else if let classifications = request.results as? [VNCoreMLFeatureValueObservation] {
                    if let multiArrayValue = classifications.first?.featureValue.multiArrayValue {
                        let argMax = multiArrayValue.argMax
                        
                        var identifier = "none"
                        if argMax.index == 0 {
                            identifier = "down"
                        }
                        else if argMax.index == 1 {
                            identifier = "left"
                        }
                        else if argMax.index == 2 {
                            identifier = "none"
                        }
                        else if argMax.index == 3 {
                            identifier = "right"
                        }
                        else if argMax.index == 4 {
                            identifier = "right"
                        }
                        
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PredictedTongues"), object: identifier)

                        print("index: \(argMax.index), value: \(argMax.value)")
                        print("\(multiArrayValue)")
                    }
                }
            }

//            request.imageCropAndScaleOption = .centerCrop
            return request
        }
        catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
        
    let inputImageSize = 229
    
    func apppyEffect(inputTexture: MTLTexture, withFace: VNFaceObservation, in commandBuffer: MTLCommandBuffer?, commandQueue: MTLCommandQueue?) -> MTLTexture? {
        guard let metalDevice = self.device else {
            return nil
        }
        
        let commandQueue1 = device?.makeCommandQueue(maxCommandBufferCount: 1)
        
        guard let faceCommandBuffer = commandQueue1?.makeCommandBuffer() else {
            return nil
        }
        
        guard let mask = createMask(width: inputTexture.width, height: inputTexture.height, with: withFace) else {
            return inputTexture
        }
              
        let lipsTexture = imageCropping?.applyCrop(inputTexture: inputTexture, cropArea: mask.points.rect, in: faceCommandBuffer)
        
        guard let compute = faceCommandBuffer.makeComputeCommandEncoder() else {
            return nil
        }
        
        let textureWidth = lipsTexture?.width ?? 0
        let textureHeight = lipsTexture?.height ?? 0
        
        let scaleX = Float(textureWidth) / Float(inputImageSize)
        let scaleY = Float(textureHeight) / Float(inputImageSize)

        let textureCacheManager = TextureCacheManager(device: metalDevice)
        let result = textureCacheManager?.createOutputTexture(width: inputImageSize, height: inputImageSize)
        
        self.outTexture = result?.texure
        
        guard let computePipelineState = self.computePipelineState else {
            return nil
        }
                
        compute.setComputePipelineState(computePipelineState)
        compute.setTexture(inputTexture, index: 0)
        compute.setTexture(mask.texture, index: 1)
        compute.setTexture(lipsTexture, index: 2)

        var faceAdjustUniform = FaceAdjustUniforms(lipsAdjustValue: self.lipsAdjustValue, scaleX: Float(scaleX), scaleY: Float(scaleY))
        let buffer = device?.makeBuffer(bytes: &faceAdjustUniform, length: MemoryLayout<FaceAdjustUniforms>.size, options: [])
        compute.setBuffer(buffer, offset: 0, index: 0)
        
        
        compute.setTexture(self.outTexture, index: 3)
        
        let threadGroupSize = MTLSize(width: 32, height: 32, depth: 1)
        let groupsCount = MTLSize(width: inputTexture.width/threadGroupSize.width+1,
                                  height: inputTexture.height/threadGroupSize.height+1,
                                  depth: 1)
        
        compute.dispatchThreadgroups(groupsCount, threadsPerThreadgroup: threadGroupSize)
        
        compute.endEncoding()
        
        faceCommandBuffer.commit()
        
//        let handler = pixelBuffer.map { VNImageRequestHandler(cvPixelBuffer: $0, options: [:]) }
//        do {
//            try handler?.perform([self.classificationRequest])
//        } catch {
//            print("Failed to perform classification.\n\(error.localizedDescription)")
//        }
//
        
        
//        let testImage = outTexture.flatMap { CIImage(mtlTexture: $0, options:  [:]) }
//        let testImage = CIImage(contentsOf: Bundle.main.url(forResource: "testimage", withExtension: "png")!)
        
//        let handler: VNImageRequestHandler? = VNImageRequestHandler(ciImage: testImage!, options: [:])
//        let handler = testImage.flatMap { CIImage(mtlTexture: $0, options: nil) }
//            .map {
//                VNImageRequestHandler(ciImage: $0, options: [:])
//            }

//        do {
//            try handler?.perform([self.classificationRequest])
//        } catch {
//            print("Failed to perform classification.\n\(error.localizedDescription)")
//        }
        
//        DispatchQueue.global().async {
        
        
        
//        pixelBuffer.map {
//                let mlInput = try? TongueClassifierInput(input_image: $0)
//                let output = mlInput.flatMap { try? self.mlModel2?.prediction(input: $0) }
//                let argMax = output?.input_57.argMax
//
//
//                var identifier = "none"
//                if argMax?.index == 0 {
//                    identifier = "down"
//                }
//                else if argMax?.index == 1 {
//                    identifier = "left"
//                }
//                else if argMax?.index == 2 {
//                    identifier = "none"
//                }
//                else if argMax?.index == 3 {
//                    identifier = "right"
//                }
//                else if argMax?.index == 4 {
//                    identifier = "riught"
//                }
//
//                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PredictedTongues"), object: identifier)
//
//                print("index: \(argMax?.index), value: \(argMax?.value)")
//                let mlInput = try? TonguePositionClassificationInput(image: $0)
//                let output = mlInput.flatMap { try? self.mlModel?.prediction(input: $0) }
//
//                if let identifier = output?.classLabel {
//                    print("\(identifier)")
//                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PredictedTongues"), object: identifier)
//                }
////            }
//
//        }
        
//        if shouldStorePictures {
//            DispatchQueue.global().async {
//                if let tonguesURL = FileManager.default.tonguesFolderURL {
//                    if FileManager.default.fileExists(atPath: tonguesURL.path) == false  {
//                        try? FileManager.default.createDirectory(at: tonguesURL, withIntermediateDirectories: false, attributes: nil)
//                    }
//
//                    result?.texure?.toCGImage().map {
//                        let pathURL = tonguesURL.appendingPathComponent("\(Date())-activity").appendingPathExtension("png")
//                        print("pathURL: \(pathURL)")
//                        do {
//                            try UIImage(cgImage: $0).pngData()?.write(to: pathURL)
//                        }
//                        catch {
//                            print("error: \(error)")
//                        }
//                    }
//                }
//            }
//        }
        
        return outTexture
    }
    
}

extension FaceAdjustFilter {
    
    var isRequiredFace: Bool {
        return true
    }
    
    var name: String {
        return NSLocalizedString("FaceAdjust", comment: "")
    }
    
    var iconName: String {
        return "FaceOverlay-Icon"
    }
}
