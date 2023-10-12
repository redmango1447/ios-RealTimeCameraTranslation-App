//
//  ViewController.swift
//  RealTimeCameraTranslationApp
//
//  Created by redmango1446 on 2023/10/11.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraPermission()
        openCamera()
    }
    
    // MARK: - CameraPermission
    
    func checkCameraPermission(){
        AVCaptureDevice.requestAccess(for: .video) { [weak self] isAuthorized in
            if isAuthorized {
                print("Camera: 권한 허용")
            } else {
                print("Camera: 권한 거부")
                self?.showAlertGoToSetting()
            }
        }
    }
    
    func showAlertGoToSetting() {
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
    
    func openCamera() {
        DispatchQueue.main.async {
            let pickerController = UIImagePickerController()
            pickerController.sourceType = .camera
            pickerController.delegate = self
            self.present(pickerController, animated: true)
        }
    }
}

extension ViewController: UINavigationControllerDelegate ,UIImagePickerControllerDelegate {
    
}

