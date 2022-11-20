//
//  DropTargetView.swift
//  ABrushViewer
//
//  Created by Matthew.J on 2022/11/19.
//

import Cocoa

protocol DropTargetDelegate: AnyObject {
    func handleDragInfo(_ dragInfo: NSDraggingInfo) -> Bool
}

class DropTargetView: NSView {

    weak var delegate: DropTargetDelegate?

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .generic
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return delegate?.handleDragInfo(sender) ?? false
    }
}
