import PlaygroundSupport
import SceneKit
import SpriteKit
import ARKit

public class Introduction {
    
    var field: SCNPhysicsField!
    var wwdcNode: SCNNode!
    var cameraNode: SCNNode!
    var fieldNode: SCNNode!
    var scene: SCNScene!
    var sceneView: SCNView!
    var introSKScene: IntroSKScene!
    
    public init() {
//         TODO: make start()
//        loadAR()
        start()
    }
    
    func loadAR() {
        PlanetMaterial.loadTextures()
        planetView = PlanetView(frame: CGRect(x: 0, y: 0, width: 800, height: 800))
        PlaygroundPage.current.liveView = planetView
        
        planetView.setup()
    }
    
    func start() {
        // temp set to AR to get the AR camera dialog permission to come up
        let ar = ARSCNView(frame: CGRect.zero)
        ar.session.run(ARWorldTrackingConfiguration())
        PlaygroundPage.current.liveView = ar
            
        sceneView = SCNView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        PlaygroundPage.current.liveView = sceneView
        
        scene = SCNScene()
        sceneView.scene = scene
        
        sceneView.backgroundColor = .black
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false
        
        cameraNode = SCNNode()
        cameraNode.physicsBody = SCNPhysicsBody.dynamic()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 10000
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 450)
        scene.rootNode.addChildNode(cameraNode)
        
        var x = 0
        var shape = SCNCylinder(radius: 50, height: 3)
        
        func configure(system: SCNParticleSystem, colors: [UIColor], vel: CGFloat) {
            for color in colors {
                system.loops = true
                system.birthRate = 1500
                system.emissionDuration = 5
                system.emitterShape = shape
                system.particleLifeSpan = 15
                system.particleSize = 0.4
                system.particleVelocity = vel
                system.particleColor = color
                system.isAffectedByPhysicsFields = true
                system.isAffectedByGravity = false
                x += 36
                scene.addParticleSystem(system, transform: SCNMatrix4MakeRotation(Float(x), 0, 0, Float.pi))
            }
        }
        
        for i in 0...10 {
            if i % 2 == 0 {
                configure(system: SCNParticleSystem(), colors: [UIColor.darkGray], vel: -10)
            } else {
                configure(system: SCNParticleSystem(), colors: [UIColor.brown], vel: -10)
            }
        }
        
        field = SCNPhysicsField.vortex()
        field.strength = -0.5
        fieldNode = SCNNode()
        fieldNode.physicsField = field
        
        let wwdcText = SCNText(string: "", extrusionDepth: 2)
        wwdcText.firstMaterial?.emission.contents = UIColor.white 
        
        wwdcText.flatness = 0.3
        wwdcNode = SCNNode(geometry: wwdcText)
        wwdcNode.position = SCNVector3(x: -27, y: -35, z: 100)
        wwdcNode.scale = SCNVector3Make(5, 5, 0)
        wwdcNode.opacity = 0.0
        
//        let wwdcText = SCNText(string: "WWDC19", extrusionDepth: 2)
//        wwdcText.flatness = 0.3
//        wwdcNode = SCNNode(geometry: wwdcText)
//        wwdcNode.position = SCNVector3(x: -100, y: -20, z: 60)
//        wwdcNode.scale = SCNVector3Make(3, 3, 0)
//        wwdcNode.opacity = 0.0
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (timer) in
            self.wwdcNode.runAction(SCNAction.fadeIn(duration: 10))
        }
        
        introSKScene = IntroSKScene(intro: self)
        sceneView.overlaySKScene = introSKScene
        
        Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { (timer) in
            self.introSKScene.startLabel.show()
            self.introSKScene.startBackground.show()
            self.introSKScene.isAnimationFinished = true
        }
        
        scene.rootNode.addChildNode(wwdcNode)

    }
    
    func moveCamera() {
        self.scene.rootNode.addChildNode(self.fieldNode)
        self.wwdcNode.runAction(SCNAction.fadeOut(duration: 3))
        
        let camMove = SCNAction.move(to: SCNVector3Make(0, 400, 0), duration: 15)
        let lookDown = SCNAction.rotate(toAxisAngle: SCNVector4Make(-1, 0, 0, Float.pi / 2), duration: 15)
        camMove.timingMode = .easeIn
        lookDown.timingMode = .easeIn
        self.cameraNode.runAction(SCNAction.group([camMove, lookDown]))
        
        Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { (timer) in
            self.field = SCNPhysicsField.vortex()
            self.field.strength = 200
            self.fieldNode.physicsField = self.field
            Timer.scheduledTimer(withTimeInterval: 6, repeats: false) { (timer) in
                let sun = SCNSphere(radius: 60)
                sun.firstMaterial?.diffuse.contents = UIColor.brown
                let sunNode = SCNNode(geometry: sun)
                sunNode.opacity = 0.0
                self.field = SCNPhysicsField.drag()
                self.field.strength = 200
                self.fieldNode.physicsField = self.field
                
                self.scene.rootNode.addChildNode(sunNode)
                
                
                
                let camMove = SCNAction.move(to: SCNVector3Make(0, 30, 0), duration: 2)
                camMove.timingMode = .easeIn
                self.cameraNode.runAction(camMove)
                self.introSKScene.blackFadeOut()
                
                Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { (t) in
                    self.loadAR()
                })
            }
        }
    }
    
    class IntroSKScene: SKScene {
        
        let intro: Introduction
        let startLabel: SKLabelNode
        var startBackground: SKShapeNode!
        
        init(intro: Introduction) {
            self.intro = intro
            self.startLabel = SKLabelNode(text: "Tap anywhere when the iPad is in fullscreen and you are ready.")
            
            super.init(size: intro.sceneView.frame.size)
            
            let infoFont = UIFont.boldSystemFont(ofSize: 40.0).fontName
            
            startLabel.verticalAlignmentMode = .center
            startLabel.horizontalAlignmentMode = .center
            
            scaleMode = .aspectFit
            
            self.startBackground = SKShapeNode(rect: CGRect(origin: CGPoint.zero, size: CGSize(width: 1000, height: startLabel.frame.height)), cornerRadius: 1.0)
            
            startBackground.fillColor = UIColor.black
            startBackground.strokeColor = UIColor.black
            startBackground.alpha = 0.0
            
            addChild(startBackground)
            
            startLabel.fontSize = 14
            startLabel.alpha = 0
            startLabel.fontName = infoFont
            
            addChild(startLabel)
            
            updatePositions()

        }
        
        func blackFadeOut() {
            let background = SKShapeNode(rectOf: CGSize(width: 5000, height: 5000))
            background.fillColor = UIColor.black
            background.strokeColor = UIColor.black
            background.alpha = 0.0
            background.zPosition = 5
            startBackground.run(SKAction.fadeOut(withDuration: 0.2))
            addChild(background)
            background.run(SKAction.fadeIn(withDuration: 2))
        }
        
        var isStarted = false
        var isAnimationFinished = false
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            if isAnimationFinished == false {
                return
            }
            
            if let _ = touches.first, !isStarted {
                startLabel.fade()
                startBackground.fade()
                self.intro.moveCamera()
                isStarted = true
            }
        }
        
        func updatePositions() {
            startLabel.position = CGPoint(x: frame.midX, y: frame.midY - 38 - startBackground.frame.height / 2)
            startBackground.position = CGPoint(x: frame.midX - startBackground.frame.width / 2, y: frame.midY - startBackground.frame.height - 35)
        }
        
        override func update(_ currentTime: TimeInterval) {
            let newSize = intro.sceneView.frame.size
            
            if size != newSize {
                size = newSize
                updatePositions()
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }

    
}

extension SKLabelNode {
    
    func fade() {
        run(SKAction.fadeOut(withDuration: 0.5))
    }
    
    func show() {
        run(SKAction.fadeIn(withDuration: 0.5))
    }
    
    func showThenFade() {
        alpha = 0
        
        show()
        
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { (_) in
            self.fade()
        })
    }
}

extension SKShapeNode {
    
    func fade() {
        run(SKAction.fadeOut(withDuration: 0.5))
    }
    
    func show() {
        run(SKAction.fadeIn(withDuration: 0.5))
    }
    
}

