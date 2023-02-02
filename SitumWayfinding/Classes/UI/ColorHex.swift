import Foundation

extension UIColor {
    convenience init?(hex: String) {
        if hex.count == 6{
            self.init(sixDigitStringHex:hex)
            return
        }else if hex.count == 9{
            self.init(nineDigitStringHex: hex)
            return
        }
        return nil
    }
    
    //111111 -> If they come from dashboard
    private convenience init?(sixDigitStringHex:String){
        self.init(nineDigitStringHex: "#"+sixDigitStringHex+"FF")
    }
    
    //#111111FF -> If they come from code
    private convenience init?(nineDigitStringHex:String) {
        let r, g, b, a: CGFloat
        
        if nineDigitStringHex.hasPrefix("#") {
            let start = nineDigitStringHex.index(nineDigitStringHex.startIndex, offsetBy: 1)
            let hexColor = String(nineDigitStringHex[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        return nil
    }
}
