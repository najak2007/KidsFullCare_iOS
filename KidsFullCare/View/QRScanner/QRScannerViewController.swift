//
//  QRScannerViewController.swift
//  KidsFullCare
//
//  Created by najak on 9/4/26.
//

import AVFoundation
import UIKit

struct StudentInfo: Codable {
    let code: String
    let uid: String
    var name: String?
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var onCodeScanned: ((StudentInfo?) -> Void)?

    private let scanAreaSize: CGFloat = 250
    private var scanRectView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
        setupOverlay()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
        updateRectOfInterest()
    }

    private func setupCaptureSession() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            failed()
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    // MARK: - Overlay UI

    private func setupOverlay() {
        // 스캔 사각형 프레임 계산 (화면 중앙)
        let rect = CGRect(
            x: (view.bounds.width - scanAreaSize) / 2,
            y: (view.bounds.height - scanAreaSize) / 2,
            width: scanAreaSize,
            height: scanAreaSize
        )

        // 1) 반투명 배경 + 중앙 컷아웃 (마스크 처리)
        let dimmingView = UIView(frame: view.bounds)
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimmingView.isUserInteractionEnabled = false

        let path = UIBezierPath(rect: dimmingView.bounds)
        let cutoutPath = UIBezierPath(roundedRect: rect, cornerRadius: 12)
        path.append(cutoutPath)
        path.usesEvenOddFillRule = true

        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd

        let cutoutMaskLayer = CAShapeLayer()
        cutoutMaskLayer.path = path.cgPath
        cutoutMaskLayer.fillRule = .evenOdd
        dimmingView.layer.mask = cutoutMaskLayer

        view.addSubview(dimmingView)

        // 2) 사각형 테두리
        scanRectView = UIView(frame: rect)
        scanRectView.backgroundColor = .clear
        scanRectView.layer.borderColor = UIColor.white.cgColor
        scanRectView.layer.borderWidth = 2
        scanRectView.layer.cornerRadius = 12
        scanRectView.isUserInteractionEnabled = false
        view.addSubview(scanRectView)

        // 3) 상단 타이틀 라벨
        let titleLabel = UILabel()
        titleLabel.text = "QRCode 인증"
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.bottomAnchor.constraint(equalTo: scanRectView.topAnchor, constant: -24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func updateRectOfInterest() {
        guard let previewLayer = previewLayer, let scanRectView = scanRectView else { return }
        // 화면 좌표(scanRectView.frame) -> 카메라 좌표계로 변환하여 인식 영역 제한
        let metadataRect = previewLayer.metadataOutputRectConverted(fromLayerRect: scanRectView.frame)
        if let metadataOutput = captureSession.outputs.first(where: { $0 is AVCaptureMetadataOutput }) as? AVCaptureMetadataOutput {
            metadataOutput.rectOfInterest = metadataRect
        }
    }

    private func failed() {
 //       sendErrorToJS(provider: "qrScanner", message: "카메라를 사용할 수 없습니다.", code: nil)
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                         didOutput metadataObjects: [AVMetadataObject],
                         from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              readableObject.type == .qr,
              let stringValue = readableObject.stringValue
        else {
            return
        }

        if let url = URL(string: stringValue),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            
            let paramsDict = queryItems.reduce(into: [String: String]()) { dict, item in
                    dict[item.name] = item.value}
            
            do {
                let studentInfo: StudentInfo = try StudentInfo.decode(dictionary: paramsDict)
                
                captureSession.stopRunning()
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                onCodeScanned?(studentInfo)
                dismiss(animated: true)
                return
            } catch {
                
            }
        }
        onCodeScanned?(nil)
        dismiss(animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
}
