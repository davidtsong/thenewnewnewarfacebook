//  Created by Jessica Joseph on 4/8/18.
//  Copyright © 2018 B0RN BKLYN. All rights reserved.

import ARKit
import UIKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var drawButton: UIButton!
    
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        sceneView.session.run(configuration)
        sceneView.delegate = self
        
        drawButton.layer.cornerRadius = drawButton.layer.frame.height / 2
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
                drawNode.geometry?.firstMaterial?.diffuse.contents = UIColor.cyan
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
                
                pointer.geometry?.firstMaterial?.diffuse.contents = UIColor.cyan
                self.sceneView.scene.rootNode.addChildNode(pointer)
            }
        }
    }

}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}
