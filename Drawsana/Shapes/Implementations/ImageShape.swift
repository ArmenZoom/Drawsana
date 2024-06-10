//
//  ImageShape.swift
//  Drawsana
//
//  Created by David Grigoryan on 5/8/20.
//  Copyright © 2020 Asana. All rights reserved.
//

import UIKit

public class ImageShape: Shape {
    private enum CodingKeys: String, CodingKey {
      case id, type, drawRect, image
    }
    public static let type = "Image"

    public func hitTest(point: CGPoint) -> Bool {
        return false
    }
    
    public func apply(userSettings: UserSettings) {
        
    }    

    public var id: String = UUID().uuidString
    public var drawRect: CGRect = CGRect.zero
    var image: UIImage?

    public func render(in context: CGContext) {
        if let image = self.image {
            context.saveGState()
            image.draw(in: CGRect(origin: drawRect.origin, size: drawRect.size))
            context.restoreGState()
        }
    }
    
    public init(image: UIImage, rect: CGRect) {
        self.image = image
        self.drawRect = rect
    }

    public required init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)

      let type = try values.decode(String.self, forKey: .type)
      if type != TextShape.type {
        throw DrawsanaDecodingError.wrongShapeTypeError
      }

      id = try values.decode(String.self, forKey: .id)
      drawRect = try values.decode(CGRect.self, forKey: .drawRect)
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(TextShape.type, forKey: .type)
      try container.encode(id, forKey: .id)
      try container.encode(drawRect, forKey: .drawRect)
    }
}
