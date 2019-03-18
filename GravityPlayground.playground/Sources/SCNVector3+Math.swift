import SceneKit

public extension SCNVector3 {
    
    func dis(_ vector: SCNVector3) -> CGFloat {
        return CGFloat(sqrt(pow(vector.x - x, 2) + pow(vector.z - z, 2)))
    }
    
}
