import SceneKit

struct PlanetSystem {
    var planets = [PlanetNode]()
    var centerPlanet: PlanetNode
}

protocol Planet {
    var mass: CGFloat { get set }
    var radius: CGFloat { get set }
    var rotationPeriod: CGFloat { get set }
}

extension Planet {
    var actualMass: CGFloat {
        return mass
    }
    
    var actualRadius: CGFloat {
        return radius / (0.05 / 6.3e6)
    }
    
    var vEscape: CGFloat {
        return sqrt((2 * 6.674e-11 * actualMass) / actualRadius)
    }
    
    var g: CGFloat {
        return (6.674e-11 * actualMass) / pow(actualRadius, 2)
    }
}

struct StaticPlanet: Planet {
    var mass: CGFloat
    var radius: CGFloat
    var rotationPeriod: CGFloat
}

struct OrbitingPlanet: Planet {
    
    var target: PlanetNode
    
    var mass: CGFloat
    var radius: CGFloat
    var distance: CGFloat
    var rotationPeriod: CGFloat
    var eccentricity: CGFloat
    
    var actualDistance: CGFloat {
        return distance * (149.6e9 / 0.49)
    }
    
    var actualRotationPeriod: CGFloat {
        return rotationPeriod * 86400
    }
    
    var revolutionPeriod: CGFloat {
        return actualRevolutionPeriod / 50
    }
    
    var actualRevolutionPeriod: CGFloat {
        let period = 2 * CGFloat.pi * sqrt(pow(actualDistance, 3) / (target.planet.actualMass * 6.67e-11))
        return period * (1 / (3600 * 24))
    }
    
    var humanWeight: CGFloat {
        return 68 * g * (1 / 4.4482216)
    }
    
    var forceOfGravity: CGFloat {
        return (6.674e-11 * actualMass * target.planet.actualMass) / pow(actualDistance, 2)
    }
    
}
