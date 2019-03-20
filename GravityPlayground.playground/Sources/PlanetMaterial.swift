import SceneKit
import UIKit

public class PlanetMaterial {
    
    static var planets = [SCNMaterial]()
    static var moons = [SCNMaterial]()
    static var floor: SCNMaterial!
    static var centerPlanet: SCNMaterial!
    static var planetIndex = 0
    static var moonIndex = 0
    
    public static func loadTextures() {
        func materialForName(_ name: String) -> SCNMaterial {
            let material = SCNMaterial()

            material.lightingModel = .physicallyBased
            material.diffuse.contents = UIImage(named: name)
            material.isDoubleSided = false

            return material
        }

        planets = (1...7).map {
            return materialForName("planet\($0).jpg")
        }

        moons = (1...2).map {
            return materialForName("moon\($0).jpg")
        }

        centerPlanet = materialForName("sun.jpg")
        
        // kinda looks like stars
        floor = materialForName("planet7.jpg")
    }
        
    static func nextPlanetTexture() -> SCNMaterial {
        let material = PlanetMaterial.planets[planetIndex]
        
        planetIndex += 1
        if planetIndex > PlanetMaterial.planets.count - 1 {
            planetIndex = 0
        }
        
        return material
    }
    
    static func nextMoonTexture() -> SCNMaterial {
        let material = PlanetMaterial.moons[moonIndex]
        
        moonIndex += 1
        if moonIndex > PlanetMaterial.moons.count - 1 {
            moonIndex = 0
        }
        
        return material
    }
    
}
