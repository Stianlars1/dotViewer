import Foundation
import Shared

let listener = NSXPCListener.service()
let delegate = HighlightService()
listener.delegate = delegate
listener.resume()
