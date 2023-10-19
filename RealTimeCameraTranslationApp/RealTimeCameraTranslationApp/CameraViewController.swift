//
//  ViewController.swift
//  RealTimeCameraTranslationApp
//
//  Created by redmango1446 on 2023/10/11.
//

import UIKit
import AVFoundation
import Vision

final class CameraViewController: UIViewController {
    
    private let previewView = UIView()
    
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private let maskLayer = CAShapeLayer()
    private var request : VNRecognizeTextRequest!
    
    let captureSessionQueue = DispatchQueue(label: "RealTimeCamera")
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraPermission()
        constraintPreviewView()
        setupLivePreview()
        configureCamera()
        request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
    }
    
    // MARK: - CameraPermission
    
    private func checkCameraPermission(){
        AVCaptureDevice.requestAccess(for: .video) { [weak self] isAuthorized in
            if isAuthorized {
                print("Camera: 권한 허용")
            } else {
                print("Camera: 권한 거부")
                self?.showAlertGoToSetting()
            }
        }
    }
    
    private func showAlertGoToSetting() {
        let alertController = UIAlertController(
            title: "현재 카메라 사용에 대한 접근 권한이 없습니다.",
            message: "설정 > RealTimeCameraTranslationApp 탭에서 접근을 활성화 할 수 있습니다.",
            preferredStyle: .alert
        )
        
        let cancelAlert = UIAlertAction(
            title: "취소",
            style: .cancel
        ) { _ in
            alertController.dismiss(animated: true, completion: nil)
            exit(0)
        }
        
        let goToSettingAlert = UIAlertAction(
            title: "설정으로 이동하기",
            style: .default
        ) { _ in
            guard let settingURL =
                    URL(string: UIApplication.openSettingsURLString),
                  UIApplication.shared.canOpenURL(settingURL)
            else { return }
            
            UIApplication.shared.open(settingURL, options: [:])
        }
        
        alertController.addAction(cancelAlert)
        alertController.addAction(goToSettingAlert)
        
        DispatchQueue.main.async {
            self.present(alertController, animated: true)
        }
    }
    // MARK: - UI & Constranint
    private func constraintPreviewView() {
        view.addSubview(previewView)
        
        previewView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: self.view.topAnchor),
            previewView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            previewView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            previewView.rightAnchor.constraint(equalTo: self.view.rightAnchor)
        ])
    }
    
    // MARK: - Method
    
    private func configureCamera() {
        captureSession.beginConfiguration()

        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else { return }

        do {
            let cameraInput = try AVCaptureDeviceInput(device: captureDevice)
            
            if captureDevice.supportsSessionPreset(.hd4K3840x2160) {
                captureSession.sessionPreset = .hd4K3840x2160
            } else {
                captureSession.sessionPreset = .hd1920x1080
            }

            if captureSession.canAddInput(cameraInput) {
                captureSession.addInput(cameraInput)
            }
            
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.setSampleBufferDelegate(self, queue: captureSessionQueue)
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
            
            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
                videoDataOutput.connection(with: .video)?.preferredVideoStabilizationMode = .off
            }
            
            captureSession.commitConfiguration()
        } catch {
            print(error)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.previewView.bounds
            }
        }
    }
    
    private func setupLivePreview() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        previewView.layer.addSublayer(videoPreviewLayer)
    }
    
    private func recognizeTextHandler(request: VNRequest, error: Error?) {
        var text = [String]()
        
        guard let results = request.results as? [VNRecognizedTextObservation] else {
            return
        }
        
        let maximumCandidates = 1
        
        for visionResult in results {
            guard let candidate = visionResult.topCandidates(maximumCandidates).first else { continue }

            text.append(candidate.string)
        }
        
        print(text)
    }
    
    var boxLayer = [CAShapeLayer]()
    func draw(rect: CGRect, color: CGColor) {
        let layer = CAShapeLayer()
        layer.opacity = 0.5
        layer.borderColor = color
        layer.borderWidth = 1
        layer.frame = rect
        boxLayer.append(layer)
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            request.recognitionLevel = .fast
            request.usesLanguageCorrection = false
            
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                       orientation: CGImagePropertyOrientation.right,
                                                       options: [:])
            do {
                try requestHandler.perform([request])
            } catch {
                print(error)
            }
        }
    }
}
