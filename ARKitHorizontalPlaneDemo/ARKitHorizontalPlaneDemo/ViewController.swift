//
//  ViewController.swift
//  ARKitHorizontalPlaneDemo
//

import UIKit
import ARKit
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    var customPlaneAnchor : ARPlaneAnchor!
    var dataModelArr = [dataModel]()
    var nodeData = [NodeData]()
    
    @IBOutlet weak var deleteSwitch : UISwitch!
    @IBOutlet weak var lblArea : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addTapGestureToSceneView()
        
        configureLighting()
        getSavedData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func setUpSceneView() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
        
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    //MARK:- Custom events
    @IBAction func btnSave_clicked(sender : UIButton) {
        saveToCoreData()
    }
    
    @IBAction func modeChanged(sender : UISwitch) {
        if(sender.isOn) {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDeleteNode(_:)))
            sceneView.addGestureRecognizer(tapGesture)
        } else {
            addTapGestureToSceneView()
        }
    }
    
    @objc
    func handleDeleteNode(_ gestureRecognize: UIGestureRecognizer) {
        // HERE YOU NEED TO DETECT THE TAP
        // check what nodes are tapped
        
        let location = gestureRecognize.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: [:])
        
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            hitResults[0].node.removeFromParentNode()
            // HERE YOU CAN SHOW POSSIBLE MOVES
            //Ex. showPossibleMoves(for: tappedPiece)
        }
        
    }
    
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.addGeometryNode(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func updateArea() {
        let width = String(format: "%.2f", customPlaneAnchor.extent.x)
        let height = String(format: "%.2f", customPlaneAnchor.extent.z)
         DispatchQueue.main.async {
            self.lblArea.text = "\(width) X \(height) mtrs"
        }
    }
    
    //MARK:- Coredata Methods
    func saveToCoreData() {
        dataModelArr.removeAll()
        for childNode in sceneView.scene.rootNode.childNodes {
            if(childNode.accessibilityValue == "rectangle") {
                if let planeData = childNode.geometry as? SCNPlane {
                    let dataModelObj = dataModel(xPos: CGFloat(childNode.position.x)
                        , yPos: CGFloat(childNode.position.y), zPos:CGFloat(childNode.position.z), width: planeData.width, height: planeData.height, angle: CGFloat(childNode.eulerAngles.x))
                    dataModelArr.append(dataModelObj)
                }
            }
        }
        
        if #available(iOS 10.0, *) {
            let coreDataDiary = NodeData(context: CoreDataStack.managedObjectContext)
            coreDataDiary.node_data = dataModelArr as NSObject
           
        } else {
            // Fallback on earlier versions
            let entityDesc = NSEntityDescription.entity(forEntityName: "NodeData", in: CoreDataStack.managedObjectContext)
            let coreDataDiary = NodeData(entity: entityDesc!, insertInto: CoreDataStack.managedObjectContext)
            coreDataDiary.node_data = dataModelArr as NSObject
        }
        
        if(dataModelArr.count == 0) {
            deleteAllRecords()
            let alertController = UIAlertController(title: "Alert", message: "Nothing to save.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            self.present(alertController, animated: true, completion: nil)
        } else {
            let alertController = UIAlertController(title: "Alert", message: "Saved successfully.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alertController, animated: true, completion: nil)
            CoreDataStack.saveContext()
        }
    }

    // This method is used to retrieve data from LocalStorage
    func getSavedData()
    {
        let fetchRequest: NSFetchRequest<NodeData> = NodeData.fetchRequest()
        do {
            self.nodeData = try CoreDataStack.managedObjectContext.fetch(fetchRequest)
            for modelData in self.nodeData {
                    let modelArr = modelData.node_data as! [dataModel]
                    for modelObj in modelArr {
                    let x = modelObj.xPos
                    let y = modelObj.yPos
                    let z = modelObj.zPos
                    
                    let width = CGFloat(modelObj.width)
                    let height = CGFloat(modelObj.height)
                    let plane = SCNPlane(width: width, height: height)
                    
                    plane.materials.first?.diffuse.contents = UIColor.transparentLightBlue
                    
                    let planeNode = SCNNode(geometry: plane)
                    planeNode.accessibilityValue = "rectangle"
                    planeNode.position = SCNVector3(x,y,z)
                    planeNode.eulerAngles.x = Float(modelObj.angle)
                    sceneView.scene.rootNode.addChildNode(planeNode)
                }
            }
        } catch {
            print(error)
        }
    }
    
    func deleteAllRecords() {
    //getting context from your Core Data Manager Class
        let managedContext = CoreDataStack.managedObjectContext
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "NodeData")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        do {
            try managedContext.execute(deleteRequest)
            try managedContext.save()
        } catch {
            print ("There is an error in deleting records")
        }
    }
    
    @objc func addGeometryNode(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        
        guard let hitTestResult = hitTestResults.first else { return }
        let translation = hitTestResult.worldTransform.translation
        let x = translation.x
        let y = translation.y
        let z = translation.z
        
        let width = CGFloat(customPlaneAnchor.extent.x)
        let height = CGFloat(customPlaneAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        plane.materials.first?.diffuse.contents = UIColor.transparentLightBlue
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.accessibilityValue = "rectangle"
        
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        sceneView.scene.rootNode.addChildNode(planeNode)
        
    }
    
    
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

extension UIColor {
    open class var transparentLightGreen: UIColor {
        return UIColor(red: 23/255, green: 67/255, blue: 88/255, alpha: 0.50)
    }
    open class var transparentLightBlue: UIColor {
        return UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 0.50)
    }
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // 1
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        customPlaneAnchor = planeAnchor
        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        // 3
        plane.materials.first?.diffuse.contents = UIColor.transparentLightGreen
        
        // 4
        let planeNode = SCNNode(geometry: plane)
        
        // 5
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        updateArea()
        // 6
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // 1
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        customPlaneAnchor = planeAnchor
        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        
        // 3
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        updateArea()
        planeNode.position = SCNVector3(x, y, z)
    }
}
