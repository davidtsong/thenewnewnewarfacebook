//  Created by Jessica Joseph on 4/8/18.
//  Copyright © 2018 B0RN BKLYN. All rights reserved.

import ARKit
import UIKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var drawButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    
    let configuration = ARWorldTrackingConfiguration()
    var drawingColor = UIColor.white
    var colors: [UIColor] = [UIColor.black, UIColor.lightGray ,UIColor.blue, UIColor.cyan, UIColor.yellow, UIColor.red, UIColor.magenta]
    
    var flashlightOn: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.session.run(configuration)
        sceneView.delegate = self
        
        drawButton.layer.cornerRadius = drawButton.layer.frame.height / 2
        resetButton.layer.cornerRadius = resetButton.layer.frame.height / 2
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        guard let pointOfView = sceneView.pointOfView else { return }
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31,-transform.m32,-transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let currentPositionOfCamera = orientation + location

        DispatchQueue.main.async {
            if self.drawButton.isHighlighted {
                let drawNode = SCNNode(geometry: SCNSphere(radius: 0.02))
                drawNode.position = currentPositionOfCamera
                drawNode.geometry?.firstMaterial?.diffuse.contents = self.drawingColor
                self.sceneView.scene.rootNode.addChildNode(drawNode)
                print("draw being pressed")
            } else {
                let pointer = SCNNode(geometry: SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0.01/2))
                pointer.position = currentPositionOfCamera
                pointer.name = "pointer"
                self.sceneView.scene.rootNode.enumerateChildNodes({ (node, _) in
                    if node.name == "pointer" {
                        node.removeFromParentNode()
                    }
                })
                
                pointer.geometry?.firstMaterial?.diffuse.contents = self.drawingColor
                self.sceneView.scene.rootNode.addChildNode(pointer)
            }
        }
    }
    
    @IBAction func snapPhoto(_ sender: Any) {
        
    }
    
    func toggleFlashlight(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if on == true {
                    device.torchMode = .on
                } else {
                    device.torchMode = .off
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used :(")
            }
        } else {
            print("Torch is not available :O")
        }
    }
    
    @IBAction func toggleFlashlight(_ sender: Any) {
        if flashlightOn {
            toggleFlashlight(on: false )
            flashlightOn = false
        } else {
            toggleFlashlight(on: true )
            flashlightOn = true
        }
    }
    
    @IBAction func resetPressed(_ sender: Any) {
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
    }
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}


extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "color", for: indexPath)
        cell.backgroundColor = colors[indexPath.row]
        cell.layer.cornerRadius = cell.layer.frame.height / 2
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        drawingColor = (cell?.backgroundColor!)!
    }
}
