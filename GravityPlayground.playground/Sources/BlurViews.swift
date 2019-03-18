import SceneKit

class InformationView: UIView {
    
    var informationViewFrame = CGRect(x: 8, y: 8, width: 325, height: 208)
    var planetNode: PlanetNode? {
        didSet {
            setShowPlanet(show: planetNode != nil )
        }
    }
    
    var deleteSystem: UIButton!
    var actionView: ActionView!
    
    init(_ actionView: ActionView) {
        self.actionView = actionView
        
        super.init(frame: informationViewFrame)
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        blurView.layer.cornerRadius = 20
        blurView.clipsToBounds = true
        addSubview(blurView)
        
        let scaleText = UILabel(frame: CGRect(x: 16, y: 16, width: 86, height: 24))
        scaleText.text = "Scale"
        scaleText.textColor = .white
        addSubview(scaleText)
        
        let scaleSlider = UISlider(frame: CGRect(x: 16, y: scaleText.frame.maxY, width: frame.width * 0.9, height: 30))
        addSubview(scaleSlider)
        
        let speedText = UILabel(frame: CGRect(x: 16, y: scaleSlider.frame.maxY + 16, width: 86, height: 24))
        speedText.text = "Speed"
        speedText.textColor = .white
        addSubview(speedText)
        
        let speedSlider = UISlider(frame: CGRect(x: 16, y: speedText.frame.maxY, width: frame.width * 0.9, height: 30))
        addSubview(speedSlider)
        
        speedSlider.addTarget(nil, action: #selector(speedDidChange), for: .valueChanged)
        speedSlider.minimumValue = 0.1
        speedSlider.maximumValue = 2
        speedSlider.value = 1.05
        
        scaleSlider.addTarget(nil, action: #selector(scaleDidChange), for: .valueChanged)
        scaleSlider.minimumValue = 0.1
        scaleSlider.maximumValue = 2
        scaleSlider.value = 1.05
        
        deleteSystem = UIButton(frame: CGRect(x: scaleSlider.frame.midX - 168/2, y: speedSlider.frame.maxY + 16, width: 168, height: 40))
        deleteSystem.setTitle("Delete System", for: .normal)
        deleteSystem.addTarget(nil, action: #selector(deleteSystemClicked), for: .touchUpInside)
        deleteSystem.setTitleColor(.red, for: .normal)
        deleteSystem.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        deleteSystem.clipsToBounds = true
        deleteSystem.layer.cornerRadius = 15
        addSubview(deleteSystem)
        
        // TODO: delete planet, if sun delete system
    }
    
    @objc func deleteSystemClicked(_ sender: UIButton) {
        
        if (deleteSystem.currentTitle == "Delete System" || planetNode == planetView.planetNode) {
            for node in planetView.planetScene.rootNode.childNodes {
                if node.geometry is SCNSphere || node.geometry is SCNTorus || node.geometry is SCNPlane {
                    node.removeFromParentNode()
                }
            }
            
            actionView.addButton.isEnabled = false
            actionView.playButton.isEnabled = false
            // TODO: disable scale/speed slider
            planetView.floorNode = nil
            planetView.highlightedNode = nil
            planetView.planetNode = nil
            planetView.planetScene.scale = 1
            planetView.planetScene.planetSystem = nil

        } else {
            planetView.planetScene.removePlanet(planet: planetNode)
            planetNode = nil
        }
        
        
    }
    
    func enableControls() {
        actionView.playButton.isEnabled = true
        actionView.addButton.isEnabled = true
    }
    
    @objc func speedDidChange(_ sender: UISlider) {
        let value = sender.value
        let scene = planetView.planetScene!
        scene.speed = CGFloat(sender.maximumValue + sender.minimumValue) - CGFloat(value)
        
        scene.sceneView.planetNode?.applyActions()
        
        scene.planetSystem?.planets.forEach({ (planet) in
            planet.applyActions()
        })
    }
    
    @objc func scaleDidChange(_ sender: UISlider) {
        let scene = planetView.planetScene!
        let scale = sender.value
        scene.scale = scale
        
        for node in scene.rootNode.childNodes.filter({ (node) -> Bool in
            return !(node.geometry is SCNPlane)
        }) {
            node.scale = SCNVector3(x: scale, y: scale, z: scale)
        }
    }
    
    private func setShowPlanet(show: Bool) {
        if show {
            deleteSystem.setTitle("Delete Planet", for: .normal)

            // reload equations
        } else {
            deleteSystem.setTitle("Delete System", for: .normal)
            
            // show scale/speed/delete system
            // remove equations view
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

class ActionView: UIView {
    
    private var actionViewFrame = CGRect(x: 8, y: 224, width: 40, height: 72)
    
    var addButton: UIButton!
    var playButton: UIButton!
    
    init() {
        super.init(frame: actionViewFrame)
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        blurView.layer.cornerRadius = 10
        blurView.clipsToBounds = true
        addSubview(blurView)
        
        addButton = UIButton(type: .contactAdd)
        addButton.tintColor = .white
        addButton.frame = CGRect(x: 0, y: 8, width: actionViewFrame.width, height: addButton.frame.height)
        addSubview(addButton)
        
        playButton = UIButton(type: .detailDisclosure)
        playButton.frame = CGRect(x: 0, y: addButton.frame.maxY + 8, width: actionViewFrame.width, height: playButton.frame.height)
        playButton.tintColor = .white
        addSubview(playButton)
        
        playButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pauseClicked)))
        addButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addClicked)))
        
        addButton.isEnabled = false
        playButton.isEnabled = false
    }
    
    @objc func pauseClicked() {
        planetView.togglePause()
    }
    
    @objc func addClicked() {
        switch planetView.state {
        case .planet(let node):
            planetView.planetScene.createMoon(planetNode: node)
        case .sun:
            fallthrough
        case .none:
            planetView.planetScene.createPlanet()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
