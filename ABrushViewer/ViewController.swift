//
//  ViewController.swift
//  ABrushViewer
//
//  Created by Matthew.J on 2022/11/18.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var infoLabel: NSTextField!
    @IBOutlet weak var collectionView: NSCollectionView!

    private var abrData: AbrData?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let v = view as! DropTargetView
        v.delegate = self
        v.registerForDraggedTypes([.fileURL])
        collectionView.register(NSNib(nibNamed: "CollectionViewItem", bundle: nil), forItemWithIdentifier: collectionViewItemIdentifier)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func loadAbrFile(url: URL) {
        self.abrData = nil
        do {
            let data = try Data(contentsOf: url)
            let abrData = try parseAbrData(data)
            infoLabel.stringValue = "version: \(abrData.version.description); images count: \(abrData.images.count)"
            self.abrData = abrData
        } catch let e as AbrParserError {
            infoLabel.stringValue = e.description
        } catch let e {
            infoLabel.stringValue = e.localizedDescription
        }
        collectionView.reloadData()
    }

}

extension ViewController: DropTargetDelegate {
    func handleDragInfo(_ dragInfo: NSDraggingInfo) -> Bool {
        guard let url = NSURL(from: dragInfo.draggingPasteboard) as? URL else {
            return false
        }
        loadAbrFile(url: url)
        return true
    }
}

extension ViewController: NSCollectionViewDataSource {

    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        self.abrData?.images.count ?? 0
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let view = collectionView.makeItem(withIdentifier: collectionViewItemIdentifier, for: indexPath)
        let index = indexPath.item
        let image = abrData!.images[index]
        switch image {
        case .bitmap(let image):
            view.imageView?.image = NSImage(cgImage: image, size: .zero)
            view.imageView?.isHidden = false
            view.textField?.isHidden = true
        case .unsupportedType:
            view.textField?.stringValue = "unsupported type"
            view.imageView?.isHidden = true
            view.textField?.isHidden = false
        }
        return view
    }

}
