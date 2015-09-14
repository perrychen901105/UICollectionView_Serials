//
//  FlickrPhotosViewController.swift
//  FlickrSearch
//
//  Created by PerryChen on 9/11/15.
//  Copyright (c) 2015 PerryChen. All rights reserved.
//

import UIKit

class FlickrPhotosViewController: UICollectionViewController {

    private let reuseIdentifier = "FlickrCell"
    private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0 )
    private var searches = [FlickrSearchResults]()
    private let flickr = Flickr()
    
    private var selectedPhotos = [FlickrPhoto]()
    private let shareTextLabel = UILabel()
    
    @IBAction func share(sender: AnyObject) {
        if searches.isEmpty {
            return
        }
        
        if !selectedPhotos.isEmpty {
            // TODO
            var imageArray = [UIImage]()
            for photo in self.selectedPhotos {
                imageArray.append(photo.thumbnail!)
            }
            let shareScreen = UIActivityViewController(activityItems: imageArray, applicationActivities: nil)
            let popover = UIPopoverController(contentViewController: shareScreen)
            popover.presentPopoverFromBarButtonItem(self.navigationItem.rightBarButtonItems!.first as! UIBarButtonItem, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
        }
        
        sharing = !sharing
        
    }
    func updateSharedPhotoCount() {
        shareTextLabel.textColor = themeColor
        shareTextLabel.text = "\(selectedPhotos.count) photos selected"
        shareTextLabel.sizeToFit()
    }
    // hold the sharing state
    var sharing : Bool = false {
        didSet {
            collectionView?.allowsMultipleSelection = sharing
            collectionView?.selectItemAtIndexPath(nil, animated: true, scrollPosition: .None)
            selectedPhotos.removeAll(keepCapacity: false)
            if sharing && largePhotoIndexPath != nil {
                largePhotoIndexPath = nil
            }
            
            let shareButton = self.navigationItem.rightBarButtonItems!.first as! UIBarButtonItem
            if sharing {
                updateSharedPhotoCount()
                let sharingDetailItem = UIBarButtonItem(customView: shareTextLabel)
                navigationItem.setRightBarButtonItems([shareButton, sharingDetailItem], animated: true)
            } else {
                navigationItem.setRightBarButtonItems([shareButton], animated: true)
            }
        }
    }
    
    var largePhotoIndexPath: NSIndexPath? {
        didSet {
            var indexPaths = [NSIndexPath]()
            if largePhotoIndexPath != nil {
                indexPaths.append(largePhotoIndexPath!)
            }
            if oldValue != nil {
                indexPaths.append(oldValue!)
            }
            // animate any chages to the collection view performed inside the block.
            collectionView?.performBatchUpdates({ () -> Void in
                self.collectionView?.reloadItemsAtIndexPaths(indexPaths)
                return
            }, completion: { (completed) -> Void in
                if self.largePhotoIndexPath != nil {
                    self.collectionView?.scrollToItemAtIndexPath(self.largePhotoIndexPath!, atScrollPosition: .CenteredVertically, animated: true)
                }
            })
        }
    }
    
    func photoForIndexPath(indexPath: NSIndexPath) -> FlickrPhoto {
        return searches[indexPath.section].searchResults[indexPath.row]
    }
    
}

extension FlickrPhotosViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // 1
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        textField.addSubview(activityIndicator)
        activityIndicator.frame = textField.bounds
        activityIndicator.startAnimating()
        flickr.searchFlickrForTerm(textField.text, completion: { (results, error) -> Void in
            // 2
            activityIndicator.removeFromSuperview()
            if error != nil {
                println("Error searching : \(error)")
            }
            
            if results != nil {
                // 3
                println("Found \(results!.searchResults.count) maching \(results!.searchTerm)")
                self.searches.insert(results!, atIndex: 0)
                
                // 4
                self.collectionView?.reloadData()
            }
        })
        textField.text = nil
        textField.resignFirstResponder()
        return true
    }
}

extension FlickrPhotosViewController : UICollectionViewDataSource {
    // 1
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return searches.count
    }
    
    // 2
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searches[section].searchResults.count
    }
    
    // 3
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! FlickrPhotoCell
        // 2
        let flickrPhoto = photoForIndexPath(indexPath)
        
        cell.activityIndicator.stopAnimating()
        
        if indexPath != largePhotoIndexPath {
            cell.imgView.image = flickrPhoto.thumbnail
            return cell
        }
        
        if flickrPhoto.largeImage != nil {
            cell.imgView.image = flickrPhoto.largeImage
            return cell
        }
        
        cell.imgView.image = flickrPhoto.thumbnail
        cell.activityIndicator.startAnimating()
        
        flickrPhoto.loadLargeImage { (flickrPhoto, error) -> Void in
            cell.activityIndicator.stopAnimating()
            
            if error != nil {
                return
            }
            if flickrPhoto.largeImage == nil {
                return
            }
            
            if indexPath == self.largePhotoIndexPath {
                if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? FlickrPhotoCell {
                    cell.imgView.image = flickrPhoto.largeImage
                }
            }
        }
        
        cell.backgroundColor = UIColor.blackColor()
        // 3
        cell.imgView.image = flickrPhoto.thumbnail
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        // 1
        switch kind {
            // 2
            case UICollectionElementKindSectionHeader:
                // 3
                let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "FlickrPhotoHeaderView", forIndexPath: indexPath) as! FlickrPhotoHeaderView
                headerView.label.text = searches[indexPath.section].searchTerm
                return headerView
            default:
            // 4
            assert(false, "Unexpected element kind")
        }
    }
    
}

extension FlickrPhotosViewController : UICollectionViewDelegate {
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        if sharing {
            return true
        }
        if largePhotoIndexPath == indexPath {
            largePhotoIndexPath = nil
        } else {
            largePhotoIndexPath = indexPath
        }
        return false
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if sharing {
            let photo = photoForIndexPath(indexPath)
            selectedPhotos.append(photo)
            updateSharedPhotoCount()
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if sharing {
            if let foundIndex = find(selectedPhotos, photoForIndexPath(indexPath)) {
                selectedPhotos.removeAtIndex(foundIndex)
                updateSharedPhotoCount()
            }
        }
    }
}

extension FlickrPhotosViewController : UICollectionViewDelegateFlowLayout {
    // 1
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let flickrPhoto = photoForIndexPath(indexPath)
        
        if indexPath == largePhotoIndexPath {
            var size = collectionView.bounds.size
            size.height -= topLayoutGuide.length
            size.height -= (sectionInsets.top + sectionInsets.right)
            size.width -= (sectionInsets.left + sectionInsets.right)
            return flickrPhoto.sizeToFillWidthOfSize(size)
        }
        
        // 2
        if var size = flickrPhoto.thumbnail?.size {
            size.width += 10
            size.height += 10
            return size
        }
        return CGSize(width: 100, height: 100)
    }
    
    // 3
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        // return the spacing between the cells, headers, and footers. A constant is used to store the value
        return sectionInsets
    }
}
