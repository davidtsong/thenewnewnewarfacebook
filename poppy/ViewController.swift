//  Created by Jessica Joseph on 4/8/18.
//  Copyright © 2018 B0RN BKLYN. All rights reserved.

import ARKit
import UIKit
import SceneKit

class ViewController: UIViewController, ARSCNViewDelegate
{

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var drawButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var loadButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var snapshotThumbnail: UIImageView!

    
    var drawingColor = UIColor.white
    var colors: [UIColor] = [UIColor.black, UIColor.white ,UIColor.blue, UIColor.cyan, UIColor.yellow, UIColor.red, UIColor.magenta]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.session.run(defaultConfiguration)
        sceneView.delegate = self
        
        drawButton.layer.cornerRadius = drawButton.layer.frame.height / 2
        resetButton.layer.cornerRadius = resetButton.layer.frame.height / 2
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        UIApplication.shared.isIdleTimerDisabled = true

        if mapDataFromFile == nil{
            self.loadButton.isHidden = true
        }
        snapshotThumbnail.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval)
    {
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
                let  virtualObjectAnchor = ARAnchor(name: String(describing: self.drawingColor), transform: simd_float4x4(drawNode.worldTransform))
                self.sceneView.session.add(anchor:virtualObjectAnchor)
                
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
    
    @IBAction func snapPhoto(_ sender: Any)
    {
        
    }
    
    func toggleFlashlight(on: Bool)
    {
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
    
    @IBAction func resetPressed(_ sender: Any) {
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
    }
    @IBAction func savePressed(_ sender: Any)
    {
        if #available(iOS 12.0, *) {
            sceneView.session.getCurrentWorldMap { worldMap, error in
                guard let map = worldMap
                    else {
                        self.showAlert(title: "Can't get current world map", message: error!.localizedDescription);
                        print("Can't get the current world map")
                        return
                }
                
                // Add a snapshot image indicating where the map was captured.
                guard let snapshotAnchor = SnapshotAnchor(capturing: self.sceneView)
                    else {
                        print("Can't take snapshot")
                        fatalError("Can't take snapshot")
                    }
                map.anchors.append(snapshotAnchor)
                
                do {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                    try data.write(to: self.mapSaveURL, options: [.atomic])
                    DispatchQueue.main.async {
                        self.loadButton.isHidden = false
                        self.loadButton.isEnabled = true
                    }
                } catch {
                    print("Can't save map: \(error.localizedDescription)")
                    fatalError("Can't save map: \(error.localizedDescription)")
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
    @IBAction func loadPressed(_ sender: Any)
    {
        let worldMap: ARWorldMap = {
            guard let data = mapDataFromFile
                else {
                    print("Map data should already be verified to exist before Load button is enabled.")
                    fatalError("Map data should already be verified to exist before Load button is enabled.")
            }
            do {
                guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
                    else { print("Map data should already be verified to exist before Load button is enabled.")
                        fatalError("No ARWorldMap in archive.") }
            
                return worldMap
            } catch {
                print("Can't unarchive ARWorldMap from file data: \(error)")
                fatalError("Can't unarchive ARWorldMap from file data: \(error)")
            }
        }()
        
        // Display the snapshot image stored in the world map to aid user in relocalizing.
        snapshotThumbnail.isHidden = false
        if let snapshotData = worldMap.snapshotAnchor?.imageData,
            let snapshot = UIImage(data: snapshotData) {
            self.snapshotThumbnail.image = snapshot
        } else {
            print("No snapshot image in world map")
        }
        // Remove the snapshot anchor from the world map since we do not need it in the scene.
        worldMap.anchors.removeAll(where: { $0 is SnapshotAnchor })
        
        let configuration = self.defaultConfiguration // this app's standard world tracking settings
        configuration.initialWorldMap = worldMap
        print("Finished loading in a map and is....")
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
//        let drawNode = SCNNode(geometry: SCNSphere(radius: 0.02))
//        drawNode.position = currentPositionOfCamera
//        drawNode.geometry?.firstMaterial?.diffuse.contents = self.drawingColor
//        self.sceneView.scene.rootNode.addChildNode(drawNode)
//        let  virtualObjectAnchor = ARAnchor(name: "dot", transform: simd_float4x4(drawNode.worldTransform))
//        self.sceneView.session.add(anchor:virtualObjectAnchor)
        
       for anchor in worldMap.anchors {
            let drawNode = SCNNode(geometry: SCNSphere(radius: 0.02))
            let color:String = anchor.name ?? "<#default value#>"
            let colorString = color.components(separatedBy: " ")
//            drawNode.position = SCNMatrix4ToMat4(anchor.transform).position()
            drawNode.position = matrix_float4x4(anchor.transform).position()
            drawNode.geometry?.firstMaterial?.diffuse.contents = self.drawingColor
//            drawNode.geometry?.firstMaterial?.diffuse.contents = UIColor(red: colorString[1].FloatValue()!, green:colorString[2].FloatValue()!, blue:colorString[3].FloatValue()!, alpha: colorString[4].FloatValue()!)
            self.sceneView.scene.rootNode.addChildNode(drawNode)
        }
        
//        let drawNode = SCNNode(geometry: SCNSphere(radius: 0.02))
//        drawNode.position = currentPositionOfCamera
//        drawNode.geometry?.firstMaterial?.diffuse.contents = self.drawingColor
//        self.sceneView.scene.rootNode.addChildNode(drawNode)
        
        
//        virtualObjectAnchor = nil
    }
    
    var defaultConfiguration: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        return configuration
    }
    
    var mapDataFromFile: Data? {
        return try? Data(contentsOf: mapSaveURL)
    }
    
    lazy var mapSaveURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("map.arexperience")
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
    }()
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}


extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource
{
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
extension matrix_float4x4 {
    func position() -> SCNVector3 {
        return SCNVector3(columns.3.x, columns.3.y, columns.3.z)
    }
}

extension String {
    
    func FloatValue() -> CGFloat? {
        guard let doubleValue = Double(self) else {
            return nil
        }
        
        return CGFloat(doubleValue)
    }
}

