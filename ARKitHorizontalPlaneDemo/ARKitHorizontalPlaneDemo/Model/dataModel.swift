
import Foundation
import CoreGraphics
class dataModel : NSObject,NSCoding {
    
    var xPos : CGFloat
    var yPos : CGFloat
    var zPos : CGFloat
    var width : CGFloat
    var height : CGFloat
    var angle : CGFloat
    
    init(xPos : CGFloat, yPos : CGFloat, zPos : CGFloat, width : CGFloat, height : CGFloat, angle : CGFloat)
    {
        self.xPos = xPos
        self.yPos = yPos
        self.zPos = zPos
        self.width = width
        self.height = height
        self.angle = angle
    }
    
    // MARK: NSCoding
    
    required init(coder decoder: NSCoder) {
        self.xPos = (decoder.decodeObject(forKey: "xPos") as? CGFloat) ?? 0
        self.yPos = (decoder.decodeObject(forKey: "yPos") as? CGFloat) ?? 0
        self.zPos = (decoder.decodeObject(forKey: "zPos") as? CGFloat) ?? 0
        self.width = (decoder.decodeObject(forKey: "width") as? CGFloat) ?? 0
        self.height = (decoder.decodeObject(forKey: "height") as? CGFloat) ?? 0
        self.angle = (decoder.decodeObject(forKey: "angle") as? CGFloat) ?? 0
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.xPos, forKey: "xPos")
        coder.encode(self.yPos, forKey: "yPos")
        coder.encode(self.zPos, forKey: "zPos")
        coder.encode(self.width, forKey: "width")
        coder.encode(self.height, forKey: "height")
        coder.encode(self.angle, forKey: "angle")
    }
}
