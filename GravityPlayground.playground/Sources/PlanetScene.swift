import ARKit

public enum SelectionState {
    
    case none
    case sun(PlanetNode)
    case planet(PlanetNode)
    
}

public var planetView: PlanetView!

public class PlanetView: ARSCNView, ARSCNViewDelegate, UIGestureRecognizerDelegate {
    
    var planetScene: PlanetScene!
    var planetNode: PlanetNode?
    var floorNode: SCNNode?
    var highlightedNode: SCNNode?
    
    var informationView: InformationView!
    
    var state: SelectionState {
        if floorNode != nil {
            return .none
        }
        
        if let selected = highlightedNode, let planetValue = selected as? PlanetNode {
            if selected == planetNode {
                return .sun(planetValue)
            }
            return .planet(planetValue)
        }
        
        return .none
    }
    
    public func setup() {
        
        let actionView = ActionView()
        addSubview(actionView)
        informationView = InformationView(actionView)
        addSubview(informationView)
        
        planetScene = PlanetScene()
        scene = planetScene
        planetScene.setup(self)
        delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        addGestureRecognizer(tap)
        
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.isLightEstimationEnabled = true
        configuration.planeDetection = .horizontal
        
        session.run(configuration)
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        if let floor = planetScene.createFloor(anchor: anchor) {
            node.addChildNode(floor)
        }
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        planetScene.rootNode.childNodes { (node, _) -> Bool in
            return node.name == "floor"
            }.forEach { (node) in
                node.removeFromParentNode()
        }
        
        if let floor = planetScene.createFloor(anchor: anchor) {
            node.addChildNode(floor)
        }
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        scene.lightingEnvironment.intensity = 1
    }
    
    @objc func tapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let hit = hitTest(location, options: [:])
        
        guard let _ = hit.first else {
            unselect()
            return
        }
        
        if planetNode != nil {
            let past = highlightedNode?.geometry?.firstMaterial
            if let p = past {
                
                unselect()
                
                if let node = hit.first?.node {
                    
                    if node.geometry!.firstMaterial! != p {
                        self.select(node: node)
                    }
                    
                }
                
            } else {
                if let node = hit.first?.node {
                    
                    if node.geometry!.firstMaterial! == past {
                        return
                    }
                    
                    select(node: node)
                }
            }
            
            
        } else {
            if let node = hit.first?.node {
                node.removeFromParentNode()
                let arHit = hitTest(location, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
                if let first = arHit.first {
                    planetScene.createSun()
                    planetNode?.position = SCNVector3(x: first.worldTransform.columns.3.x, y: first.worldTransform.columns.3.y, z: first.worldTransform.columns.3.z)

                }
            }
        }
    }
    
    func select(node: SCNNode) {
        informationView.planetNode = node as? PlanetNode
        
        highlightedNode = node
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        
        highlightedNode?.geometry?.firstMaterial?.emission.contents = UIColor.red
        
        SCNTransaction.commit()
    }
    
    func unselect(funct: (() -> ())? = nil) {
        informationView.planetNode = nil
        
        if let mat = highlightedNode?.geometry?.firstMaterial {
            
            if let f = funct {
                f()
            }
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            mat.emission.contents = UIColor.black
            
            SCNTransaction.commit()
            
            highlightedNode = nil
        }
    }
    
    var actions = [SCNNode : [SCNAction]]()
    
    func togglePause() {
        planetScene.isPaused = !planetScene.isPaused
    }
    
    func resetTimers() {
        for node in planetScene.rootNode.childNodes {
            if node.geometry is SCNTorus {
                node.rotation = SCNVector4(x: 0, y: 0, z: 0, w: 0)
            }
            
            for n0 in node.childNodes {
                if n0.geometry is SCNTorus {
                    n0.rotation = SCNVector4(x: 0, y: 0, z: 0, w: 0)
                }
                
                for n1 in n0.childNodes {
                    if n1.geometry is SCNTorus {
                        n1.rotation = SCNVector4(x: 0, y: 0, z: 0, w: 0)
                    }
                }
            }
        }
    }
    
}

public class PlanetScene: SCNScene, UIGestureRecognizerDelegate {
    
    var sceneView: PlanetView!
    var planetSystem: PlanetSystem?
    var scale: Float = 1
    var speed: CGFloat = 1
    
    func setup(_ sceneView: PlanetView) {
        self.sceneView = sceneView
        
        setupLighting()
    }
    
    func setupLighting() {
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = false
        
        let lighting = UIImage(named: "spherical.jpg")
        sceneView.scene.lightingEnvironment.contents = lighting
    }
    
    func addNode(_ node: SCNNode) {
        addNode(node, to: rootNode)
    }
    
    func addNode(_ node: SCNNode, to rootNode: SCNNode) {
        node.scale = SCNVector3(x: scale, y: scale, z: scale)
        rootNode.addChildNode(node)
    }
    
    func createSun() {
        guard let floorNode = sceneView.floorNode else {
            return
        }
        
        sceneView.planetNode = PlanetNode(mass: 1.989e30, radius: 0.15, rotationPeriod: 10)
        sceneView.planetNode!.position = floorNode.position
        addNode(sceneView.planetNode!)
        
        planetSystem = PlanetSystem(planets: [PlanetNode](), centerPlanet: sceneView.planetNode!)
        
        floorNode.removeFromParentNode()
        sceneView.floorNode = nil
                
        planetView.informationView.enableControls()
    }
    
    func createPlanet() {        
        guard let position = sceneView.pointOfView?.position, let system = planetSystem else {
            return
        }
        
        let planetPosition = SCNVector3(x: position.x, y: system.centerPlanet.position.y, z: position.z)
        let distance = system.centerPlanet.position.dis(planetPosition)
        let planetNode = PlanetNode(distance: distance, orbiting: system.centerPlanet, radius: 0.05, mass: 5e24, rotationPeriod: 30, eccentricity: distance)
        let orbitNode = createOrbit(distance: distance)
        
        addNode(orbitNode, to: (planetNode.planet as! OrbitingPlanet).target)
        planetNode.position = orbitNode.convertPosition(planetPosition, from: nil)
        
        addNode(planetNode, to: orbitNode)

        planetNode.orbitNode = orbitNode
        planetNode.applyActions()
        planetSystem?.planets.append(planetNode)
    }
    
    func createMoon(planetNode: PlanetNode) {
        guard let _ = planetSystem, let orbitPlanet = sceneView.highlightedNode as? PlanetNode else {
            return
        }
        
        let distance: CGFloat = 0.1
        let moonNode = PlanetNode(distance: distance, orbiting: orbitPlanet, radius: 0.005, mass: 7.34767e22, rotationPeriod: 30, eccentricity: distance)
        let orbitNode = SCNNode()
        
        addNode(orbitNode, to: planetNode)
        moonNode.position = SCNVector3(x: 0, y: 0, z: 0.1)
        orbitNode.addChildNode(moonNode)

        planetNode.orbitNode = orbitNode
        planetNode.applyActions()
        planetSystem?.planets.append(moonNode)
    }
    
    func createOrbit(distance: CGFloat) -> SCNNode {
        let torus = SCNTorus(ringRadius: distance, pipeRadius: 0.0005)
        torus.pipeSegmentCount = 72
        torus.ringSegmentCount = 144
        let torusNode = SCNNode(geometry: torus)
        return torusNode
    }
    
    func createFloor(anchor: ARPlaneAnchor) -> SCNNode? {
        if sceneView.planetNode == nil {
//            let floor = SCNPlane(width: 0.2, height: 0.2)
//            floor.cornerRadius = (floor.width / 2) * 0.5
//
//            let floorNode = SCNNode(geometry: floor)
//            floorNode.name = "floor"
//            floorNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
//            sceneView.floorNode = floorNode
//            return floorNode
            
            let sphere = SCNSphere(radius: 0.15)
            sphere.firstMaterial?.diffuse.contents = UIColor.gray
            sphere.segmentCount = 72
            
            let sunNode = SCNNode(geometry: sphere)
            sunNode.name = "floor"
            sceneView.floorNode = sunNode
            sunNode.opacity = 0.3
            sunNode.position = SCNVector3(anchor.center.x, anchor.center.y, anchor.center.z)
            
            return sunNode
        }
        
        return nil
    }
    
    func removePlanet(planet: PlanetNode?) {
        guard let planet = planet else {
            return
        }
        
        if let index = planetSystem?.planets.index(of: planet) {
            planetSystem?.planets.remove(at: index)
        }
        
        planet.removeFromParentNode()
        planet.orbitNode?.removeFromParentNode()
        planetView.highlightedNode = nil
    }
    
    func recalculateSpeeds() {
        if let system = planetSystem {
            for planet in system.planets {
                planet.applyActions()
            }
        }
    }
}
