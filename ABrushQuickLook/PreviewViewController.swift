//
//  PreviewViewController.swift
//  ABrushQuickLook
//
//  Created by Matthew.J on 2022/11/20.
//

import Cocoa
import Quartz

class PreviewViewController: NSViewController, QLPreviewingController {
    
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var infoLabel: NSTextField!

    private var abrData: AbrData?

    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }

    override func loadView() {
        super.loadView()
        // Do any additional setup after loading the view.
        collectionView.register(NSNib(nibNamed: "CollectionViewItem", bundle: nil), forItemWithIdentifier: collectionViewItemIdentifier)

    }

    /*
     * Implement this method and set QLSupportsSearchableItems to YES in the Info.plist of the extension if you support CoreSpotlight.
     *
    func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping (Error?) -> Void) {
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        handler(nil)
    }
     */
    
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        
        // Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.
        
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.

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
        
        handler(nil)
    }
}

extension PreviewViewController: NSCollectionViewDataSource {

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
