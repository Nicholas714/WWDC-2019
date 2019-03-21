import SceneKit

class ControlView {
    
    // control for scale, speed, and delete system (when no object is selected)
    var systemSliderView: SystemSliderView!
    // controls for mass, distance, radius (when a planet/moon/sun is selected)
    var planetSliderView: PlanetSliderView!
    // controls for play, pause, and add
    var actionView: ActionView!
    // view for displaying directions for using the scene
    var directionView: DirectionView!
    // view for each formula being displayed
    var formulaView: FormulaView!
    
    // determines if the clicked node is the sun or a planet/moon
    var isSun: Bool {
        if let clickedNode = planetView.controlView.planetNode, clickedNode == planetView.planetNode {
            return true
        }
        return false
    }
    
    // current selected planet/sun/moon, on change update UI to show only needed views
    var planetNode: PlanetNode? {
        didSet {
            if planetNode == nil {
                planetSliderView.fadeOut(duration: 0.2)
                systemSliderView.fadeIn(duration: 0.2)
                formulaView.fadeOut(duration: 0.2)
            } else {
                if let planet = planetNode?.planet {
                    planetSliderView.updateControls(for: planet)
                }
                
                planetSliderView.fadeIn(duration: 0.2)
                systemSliderView.fadeOut(duration: 0.2)
                formulaView.fadeIn(duration: 0.2)
                formulaView.reloadEquations()
                
                if (isSun) {
                    planetSliderView.distanceSlider.isEnabled = false
                } else {
                    planetSliderView.distanceSlider.isEnabled = true
                }
            }
        }
    }
    
    /*
     On Startup:
     - direction view saying to click screen
     
     On Create Sun/deselect planet:
     - direction view saying to add planets
     - system slider view
     - action view
     
     On select Planet/Moon/Sun:
     - direction saying to change controls
     - planet slider view
     - formula view
     - action view
     
     */
    
    init() {
        systemSliderView = SystemSliderView()
        planetSliderView = PlanetSliderView()
        directionView = DirectionView()
        formulaView = FormulaView()
        actionView = ActionView()
        
        planetView.addSubview(planetSliderView)
        planetView.addSubview(actionView)
        planetView.addSubview(systemSliderView)
        planetView.addSubview(directionView)
        planetView.addSubview(formulaView)
        
        // only show directions view
        [systemSliderView, planetSliderView, formulaView, actionView].forEach {
            $0?.alpha = 0.0
        }
        
        updateView(with: planetView.frame)
    }
    
    // on create sun, show system slider, directions, anda action view
    func enableControls() {
        [systemSliderView, directionView, actionView].forEach {
            $0?.fadeIn(duration: 0.2)
        }
        
        [planetSliderView, formulaView].forEach {
            $0?.fadeOut(duration: 0.2)
        }
    }
    
    // on delete, hide everything except directions
    func deleteSystem() {
        [systemSliderView, planetSliderView, formulaView, actionView].forEach {
            $0?.fadeOut(duration: 0.2)
        }
        directionView.fadeIn(duration: 0.2)
        directionView.currentDirection = .moveAround
        directionView.directionText.text = directionView.directions[.moveAround]
        planetView.controlView.updateView(with: planetView.frame)
    }
    
    func updateView(with newFrame: CGRect) {
        actionView.center = CGPoint(x: newFrame.maxX - actionView.frame.width / 2 - 8, y: 8 + actionView.frame.height / 2)
        directionView.center = CGPoint(x: newFrame.midX, y: newFrame.maxY - directionView.frame.height / 2 - 8)
    }
    
}

enum Direction: Int {
    case moveAround
    case placeFloor
    case placePlanet
    case useControls
    case placeMoon
    case done
}

class DirectionView: UIView {
    
    var directionText: UILabel!
    
    var currentDirection: Direction = .moveAround {
        didSet {
            if self.currentDirection != .done {
                self.frame.size.width = 300
                for view in self.subviews {
                    view.frame.size.width = 300
                }
            } 
        }
    }
    
    var directions: [Direction: String] = [
        .moveAround: "Move around and find a flat surface",
        .placeFloor: "Tap on a floor to place a sun",
        .placePlanet: "Tap + to add a planet where you are",
        .useControls: "Tap a planet and change the sliders",
        .placeMoon: "Tap a planet, then + to add a moon",
        .done: "WWDC19"
    ]
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 300, height: 40))
        
        addBlur(15)
        
        directionText = UILabel(frame: frame)
        directionText.textAlignment = .center
        directionText.textColor = .white
        directionText.text = directions[.moveAround]
        addSubview(directionText)
    }
    
    func nextDirection(shouldBe: Direction) {
        // only move on to next direction if at that step (prevents being called too many times)
        if currentDirection != shouldBe {
            return
        }
        
        let newDirection = currentDirection.rawValue + 1
        
        // if no more directions, don't do anything
        if newDirection >= directions.count {
            return
        }
        
        if let newDirection = Direction(rawValue: newDirection) {
            currentDirection = newDirection
            
            // fade out label and fade in
            UIView.animate(withDuration: 0.4, animations: {
                self.directionText.alpha = 0.0
            }) { _ in
                self.directionText.text = self.directions[self.currentDirection]
                self.directionText.fadeIn(duration: 0.4)
                UIView.animate(withDuration: 0.4, animations: {
                    self.directionText.alpha = 1.0
                }, completion: { (_) in
                    if self.currentDirection == .done {
                        self.frame.size.width = 125
                        for view in self.subviews {
                            view.frame.size.width = 125
                        }
                    }
                    planetView.controlView.updateView(with: planetView.frame)
                })
                
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

class FormulaCell: UITableViewCell {
    
    var formulaName: String = "" {
        didSet {
            formulaNameLabel.text = "\(formulaName)"
        }
    }
    
    var formulaAnswer: String = "" {
        didSet {
            formulaAnswerLabel.text = "\(formulaAnswer)"
        }
    }
    
    private var formulaNameLabel: UILabel!
    private var formulaAnswerLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String!) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        formulaNameLabel = UILabel(frame: CGRect(x: 16, y: 0, width: frame.width / 2, height: 50))
        formulaAnswerLabel = UILabel(frame: CGRect(x: 132, y: 0, width: frame.width / 2, height: 50))
        
        formulaNameLabel.textColor = .white
        formulaAnswerLabel.textColor = .white
        
        formulaAnswerLabel.textAlignment = .right
        
        addSubview(formulaNameLabel)
        addSubview(formulaAnswerLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
}

class FormulaView: UIView, UITableViewDelegate, UITableViewDataSource {
    
    private let formulaFrame = CGRect(x: 8, y: 304, width: 300, height: 175)
    
    private var formulaTable: UITableView!
    
    init() {
        super.init(frame: formulaFrame)
        
        addBlur()
        
        formulaTable = UITableView(frame: CGRect(x: -8, y: 0, width: frame.width, height: frame.height), style: .plain)
        formulaTable.clipsToBounds = true
        formulaTable.layer.cornerRadius = 20
        formulaTable.allowsSelection = false
        
        formulaTable.delegate = self
        formulaTable.dataSource = self
        formulaTable.backgroundColor = .clear
        
        formulaTable.register(FormulaCell.self, forCellReuseIdentifier: "formulaCell")
        
        self.addSubview(formulaTable)
        
        reloadEquations()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let selected = planetView?.controlView?.planetNode?.planet else {
            return 0
        }
        
        if selected is OrbitingPlanet {
            return 4
        } else {
            return 2
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "formulaCell", for: indexPath) as? FormulaCell, let planet = planetView.controlView.planetNode?.planet else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        
        cell.backgroundColor = .clear
        
        switch indexPath.row {
        case 0:
            cell.formulaName = "Escape Velocity"
            cell.formulaAnswer = "\(planet.vEscape.format()) m/s²"
        case 1:
            cell.formulaName = "Gravity"
            cell.formulaAnswer = "\(planet.g.format()) m/s²"
        case 2:
            if let orbit = planet as? OrbitingPlanet {
                cell.formulaName = "Fg"
                cell.formulaAnswer = "\(orbit.forceOfGravity.format()) N"
            }
        case 3:
            if let orbit = planet as? OrbitingPlanet {
                cell.formulaName = "Revolution"
                cell.formulaAnswer = "\(orbit.actualRevolutionPeriod.format()) days"
            }
        default:
            return cell
        }
        
        return cell
    }
    
    func reloadEquations() {
        guard let _ = planetView.controlView?.planetNode?.planet else {
            return
        }
        
        formulaTable.reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

class PlanetSliderView: UIView {
    
    var informationViewFrame = CGRect(x: 8, y: 8, width: 300, height: 280)
    
    var deleteSystem: UIButton!
    var massSlider: UISlider!
    var distanceSlider: UISlider!
    var radiusSlider: UISlider!
    
    var massText: UILabel!
    var distanceText: UILabel!
    var radiusText: UILabel!
    
    init() {
        super.init(frame: informationViewFrame)
        
        addBlur()
        
        massText = UILabel(frame: CGRect(x: 16, y: 16, width: 284, height: 24))
        
        massText.text = "Mass"
        massText.textColor = .white
        addSubview(massText)
        
        massSlider = UISlider(frame: CGRect(x: 16, y: massText.frame.maxY, width: frame.width * 0.9, height: 30))
        addSubview(massSlider)
        
        distanceText = UILabel(frame: CGRect(x: 16, y: massSlider.frame.maxY + 16, width: 284, height: 24))
        distanceText.text = "Distance"
        distanceText.textColor = .white
        addSubview(distanceText)
        
        distanceSlider = UISlider(frame: CGRect(x: 16, y: distanceText.frame.maxY, width: frame.width * 0.9, height: 30))
        addSubview(distanceSlider)
        
        radiusText = UILabel(frame: CGRect(x: 16, y: distanceSlider.frame.maxY + 16, width: 284, height: 24))
        radiusText.text = "Radius"
        radiusText.textColor = .white
        addSubview(radiusText)
        
        radiusSlider = UISlider(frame: CGRect(x: 16, y: radiusText.frame.maxY, width: frame.width * 0.9, height: 30))
        addSubview(radiusSlider)
        
        massSlider.addTarget(nil, action: #selector(massDidChange), for: .valueChanged)
        massSlider.minimumValue = 0.1
        massSlider.maximumValue = 2
        massSlider.value = 1.05
        
        distanceSlider.addTarget(nil, action: #selector(distanceDidChange), for: .valueChanged)
        distanceSlider.minimumValue = 0.1
        distanceSlider.maximumValue = 2
        distanceSlider.value = 1.05
        
        radiusSlider.addTarget(nil, action: #selector(radiusDidChange), for: .valueChanged)
        radiusSlider.minimumValue = 0.1
        radiusSlider.maximumValue = 2
        radiusSlider.value = 1.05
        
        deleteSystem = UIButton(frame: CGRect(x: radiusSlider.frame.midX - 168/2, y: radiusSlider.frame.maxY + 16, width: 168, height: 40))
        deleteSystem.setTitle("Delete Planet", for: .normal)
        deleteSystem.addTarget(nil, action: #selector(deleteSystemClicked), for: .touchUpInside)
        deleteSystem.setTitleColor(.red, for: .normal)
        deleteSystem.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        deleteSystem.clipsToBounds = true
        deleteSystem.layer.cornerRadius = 15
        addSubview(deleteSystem)
    }
    
    func updateControls(for planet: Planet) {
        let isSun = planetView.controlView.isSun
        
        massSlider.value = Float(planet.mass) / (isSun ? 1.989e30 : 5e24)
        
        if let orb = planet as? OrbitingPlanet {
            distanceSlider.value = Float(orb.distance) / Float(orb.eccentricity)
        }
        
        radiusSlider.value = Float(planet.radius) / (isSun ? 0.15 : 0.05)
    }
    
    @objc func deleteSystemClicked(_ sender: UIButton) {
        
        if planetView.controlView.isSun {
            for node in planetView.planetScene.rootNode.childNodes {
                if node.geometry is SCNSphere || node.geometry is SCNTorus || node.geometry is SCNPlane {
                    node.removeFromParentNode()
                }
            }
            
            planetView.unselect()
            planetView.controlView.deleteSystem()
            planetView.floorNode = nil
            planetView.highlightedNode = nil
            planetView.planetNode = nil
            planetView.planetScene.scale = 1
            planetView.planetScene.planetSystem = nil
        } else {
            planetView.planetScene.removePlanet(planet: planetView.controlView.planetNode)
            planetView.controlView.planetNode = nil
        }
        
    }
    
    @objc func massDidChange(_ sender: UISlider) {
        let value = sender.value
        
        if Int(100000 * value) % 2 != 0 {
            return
        }
        
        planetView.controlView.directionView.nextDirection(shouldBe: .useControls)
        
        let isSun = planetView.controlView.isSun
        
        if isSun {
            if let system = planetView.planetScene.planetSystem {
                for node in system.planets {
                    node.applyActions()
                }
            }
        } else {
            planetView.controlView.planetNode?.applyActions()
        }
        
        planetView.controlView.planetNode?.planet.mass = (isSun ? 1.989e30 : 5e24) * CGFloat(value)
        planetView.controlView.formulaView.reloadEquations()
    }
    
    @objc func distanceDidChange(_ sender: UISlider) {
        let value = sender.value
        
        if Int(100000 * value) % 2 != 0 {
            return
        }
        
        planetView.controlView.directionView.nextDirection(shouldBe: .useControls)
        
        let planetNode = planetView.controlView.planetNode
        
        if let _ = (planetNode?.orbitNode?.geometry as? SCNTorus)?.ringRadius {
            var orb = (planetNode?.planet as! OrbitingPlanet)
            let newSphere = SCNTorus(ringRadius: orb.eccentricity * CGFloat(value), pipeRadius: 0.0005)
            
            orb.distance = orb.eccentricity * CGFloat(value)
            planetNode?.planet = orb
            newSphere.materials = (planetNode?.orbitNode?.geometry?.materials)!
            planetNode?.orbitNode?.geometry = newSphere
            
            let x = Float(orb.distance) * -cos(planetNode!.orbitNode!.rotation.y)
            let z = Float(orb.distance) * -sin(planetNode!.orbitNode!.rotation.y)
            
            planetNode?.position = SCNVector3(x: x, y: 0, z: z)
        }
        
        planetNode?.applyActions()
        planetView.controlView.formulaView.reloadEquations()
    }
    
    @objc func radiusDidChange(_ sender: UISlider) {
        let value = sender.value
        
        if Int(100000 * value) % 2 != 0 {
            return
        }
        
        planetView.controlView.directionView.nextDirection(shouldBe: .useControls)
        
        let isSun = planetView.controlView.isSun
        let planetNode = planetView.controlView.planetNode
        
        if let _ = (planetNode?.geometry as? SCNSphere)?.radius {
            let newSphere = SCNSphere(radius: (isSun ? 0.15 : 0.05) * CGFloat(value))
            planetNode?.planet.radius = newSphere.radius
            newSphere.materials = (planetNode?.geometry?.materials)!
            planetNode?.geometry = newSphere
        }
        
        planetView.controlView.formulaView.reloadEquations()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

class SystemSliderView: UIView {
    
    var informationViewFrame = CGRect(x: 8, y: 8, width: 300, height: 208)
    
    init() {
        super.init(frame: informationViewFrame)
        
        addBlur()
        
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
        
        let deleteSystem = UIButton(frame: CGRect(x: scaleSlider.frame.midX - 168/2, y: speedSlider.frame.maxY + 16, width: 168, height: 40))
        deleteSystem.setTitle("Delete System", for: .normal)
        deleteSystem.addTarget(nil, action: #selector(deleteSystemClicked), for: .touchUpInside)
        deleteSystem.setTitleColor(.red, for: .normal)
        deleteSystem.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        deleteSystem.clipsToBounds = true
        deleteSystem.layer.cornerRadius = 15
        addSubview(deleteSystem)
        
    }
    
    @objc func deleteSystemClicked(_ sender: UIButton) {
        
        for node in planetView.planetScene.rootNode.childNodes {
            if node.geometry is SCNSphere || node.geometry is SCNTorus || node.geometry is SCNPlane {
                node.removeFromParentNode()
            }
        }
        
        planetView.unselect()
        planetView.controlView.deleteSystem()
        planetView.floorNode = nil
        planetView.highlightedNode = nil
        planetView.planetNode = nil
        planetView.planetScene.scale = 1
        planetView.planetScene.planetSystem = nil
        
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
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

class ActionView: UIView {
    
    private var actionViewFrame = CGRect(x: 316, y: 8, width: 40, height: 72)
    
    var addButton: UIButton!
    var playButton: UIButton!
    
    init() {
        super.init(frame: actionViewFrame)
        
        addBlur(10)
        
        addButton = UIButton(type: .contactAdd)
        addButton.tintColor = .white
        addButton.frame = CGRect(x: 0, y: 8, width: actionViewFrame.width, height: addButton.frame.height)
        addSubview(addButton)
        
        playButton = UIButton(frame: CGRect(x: 8, y: addButton.frame.maxY + 8, width: 24, height: 24))
        playButton.tintColor = .white
        playButton.setImage(UIImage(named: "pause.png"), for: .normal)
        addSubview(playButton)
        
        playButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pauseClicked)))
        addButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addClicked)))
    }
    
    @objc func pauseClicked() {
        planetView.togglePause()
        
        if planetView.planetScene.isPaused {
            playButton.setImage(UIImage(named: "play.png"), for: .normal)
        } else {
            playButton.setImage(UIImage(named: "pause.png"), for: .normal)
        }
        
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

extension UIView {
    
    func fadeOut(duration: TimeInterval) {
        UIView.animate(withDuration: duration) {
            self.alpha = 0.0
        }
    }
    
    func fadeIn(duration: TimeInterval) {
        UIView.animate(withDuration: duration) {
            self.alpha = 1.0
        }
    }
    
    func addBlur(_ cornerRadius: CGFloat = 20) {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        blurView.layer.cornerRadius = cornerRadius
        blurView.clipsToBounds = true
        addSubview(blurView)
    }
    
}

extension CGFloat {
    
    func format() -> String {
        let numberFormatter = NumberFormatter()
        
        if self > 1000 || self < -1000 {
            let valueAsString = String(format: "%.0f", self)
            let exponentCount = valueAsString.count + (self < 0 ? -2 : -1)
            
            return CGFloat.superScript(for: Float(self), strValue: valueAsString, count: exponentCount)
        } else {
            if self > 100 || self < 100 {
                numberFormatter.minimumFractionDigits = 0
                numberFormatter.maximumFractionDigits = 1
                return "\(numberFormatter.string(from: NSNumber(value: Float(self)))!)"
            }
            numberFormatter.minimumFractionDigits = 0
            numberFormatter.maximumFractionDigits = 0
            return "\(numberFormatter.string(from: NSNumber(value: Float(self)))!)"
        }
    }
    
    private static func superScript(for value: Float, strValue: String, count: Int) -> String {
        var superScript: String = ""
        
        func unicode(of c: Int) -> String {
            switch c {
            case 0:
                return "\u{2070}"
            case 1:
                return "\u{B9}"
            case 2:
                return "\u{B2}"
            case 3:
                return "\u{B3}"
            case 4:
                return "\u{2074}"
            case 5:
                return "\u{2075}"
            case 6:
                return "\u{2076}"
            case 7:
                return "\u{2077}"
            case 8:
                return "\u{2078}"
            case 9:
                return "\u{2079}"
            default:
                return ""
            }
        }
        
        
        if count > 9 {
            for c in String(count) {
                superScript += unicode(of: Int(String(c))!)
            }
        } else {
            superScript = unicode(of: count)
        }
        
        if superScript == "" {
            return String(format: "%.0f", value)
        } else {
            var final = strValue
            
            if value < 0 {
                final = String(final.dropFirst())
            }
            
            let first = final.first!
            final = String(final.dropFirst())
            let second = final.first!
            
            return "\(first).\(second)x10\(superScript)"
        }
        
    }
    
}
