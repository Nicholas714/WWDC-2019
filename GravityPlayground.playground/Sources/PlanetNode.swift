import SceneKit

public class PlanetNode: SCNNode {
    
    var planet: Planet
    var orbitNode: SCNNode?
    
    init(distance: CGFloat, orbiting: PlanetNode, radius: CGFloat, mass: CGFloat, rotationPeriod: CGFloat, eccentricity: CGFloat, isMoon: Bool = false) {
        planet = OrbitingPlanet(target: orbiting, mass: mass, radius: radius, distance: distance, rotationPeriod: rotationPeriod, eccentricity: eccentricity)
        
        super.init()
        
        if isMoon {
            load(material: PlanetMaterial.nextMoonTexture())
        } else {
            load(material: PlanetMaterial.nextPlanetTexture())
        }

        applyActions()
    }
    
    init(mass: CGFloat, radius: CGFloat, rotationPeriod: CGFloat = 20) {
        planet = StaticPlanet(mass: mass, radius: radius, rotationPeriod: rotationPeriod)
        
        super.init()
        
        load(material: PlanetMaterial.centerPlanet)
        applyActions()
    }
    
    func load(material: SCNMaterial) {
        let sphere = SCNSphere(radius: planet.radius)
        sphere.firstMaterial = material
        sphere.segmentCount = 72
        geometry = sphere
    }
    
    func applyActions() {
        removeAllActions()
        orbitNode?.removeAllActions()
        
        orbitNode?.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: TimeInterval((planet as! OrbitingPlanet).revolutionPeriod * planetView.planetScene.speed))))
        runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: TimeInterval(planet.rotationPeriod * planetView.planetScene.speed))))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
