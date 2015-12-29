//
//  FavouritesViewController.swift
//  FlickrContinuousAccessment
//
//  Created by Yu Yu Mon Win on 10/2/15.
//  Copyright (c) 2015 ISS. All rights reserved.
//

import UIKit

class FavouritesViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate
{
    
    
    var flickrCADB:COpaquePointer = nil;
    var selectStatement:COpaquePointer=nil;
    var deleteStatement:COpaquePointer=nil;
    var imageDataList = [ImageData]();
    
    
    
    override func viewDidLoad()
    {
        println("DidLoad");
        super.viewDidLoad()
        
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        var paths=NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) [0] as String
        var docsDir=paths.stringByAppendingPathComponent("FlickrCADB.sqlite")
        
        if(sqlite3_open(docsDir, &flickrCADB) == SQLITE_OK)
        {
        }
        else
        {
            println("Failed to open database")
            println(sqlite3_errmsg(flickrCADB));
        }
        prepareStatement();
        
        navigationItem.title = "Favourites"
        
    }
    
    override func viewWillAppear(animated:Bool)
    {
        imageDataList = [ImageData]();
        while(sqlite3_step(selectStatement) == SQLITE_ROW)
        {
            var imageData = ImageData()
            
            let id = sqlite3_column_text(selectStatement, 0)
            imageData.id = String.fromCString(UnsafePointer<CChar>(id))!;
            
            let thumbnailurl = sqlite3_column_text(selectStatement, 1)
            imageData.thumbnailUrl = String.fromCString(UnsafePointer<CChar>(thumbnailurl))!;
            
            let imageurl = sqlite3_column_text(selectStatement, 2)
            imageData.imageUrl = String.fromCString(UnsafePointer<CChar>(imageurl))!;
            
            let title = sqlite3_column_text(selectStatement, 3)
            imageData.title = String.fromCString(UnsafePointer<CChar>(title))!;
            
            let comment = sqlite3_column_text(selectStatement, 4)
            imageData.comment = String.fromCString(UnsafePointer<CChar>(comment))!;
            
            let urlx = NSURL(string: imageData.thumbnailUrl);
            let data = NSData(contentsOfURL: urlx!);
            
            imageData.thumbnail = UIImage(data : data!)!;
            imageDataList.append(imageData);
            
        }
        
        sqlite3_reset(selectStatement);
        sqlite3_clear_bindings(selectStatement);
        
        self.tableView.reloadData();
    }
    
    

    func prepareStatement()
    {
        var sqlString:String
        
        sqlString = "SELECT ID,THUMBURL, IMAGEURL, TITLE, COMMENT from FlickrCADB"
        var csql=sqlString.cStringUsingEncoding(NSUTF8StringEncoding)
        sqlite3_prepare_v2(flickrCADB, csql!, -1, &selectStatement, nil)
        
        sqlString = "DELETE FROM FlickrCADB WHERE ID =?"
        csql=sqlString.cStringUsingEncoding(NSUTF8StringEncoding)
        sqlite3_prepare_v2(flickrCADB, csql!, -1, &deleteStatement, nil)
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return imageDataList.count;
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FavouriteCell", forIndexPath: indexPath) as UITableViewCell
        var imageData = imageDataList[indexPath.row];
        
        cell.textLabel?.text = imageData.title;
        cell.imageView?.image = imageData.thumbnail as UIImage;
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete
        {
            removeFromFavourites(imageDataList[indexPath.row]);
            imageDataList.removeAtIndex(indexPath.row);
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
        }
    }
    
    func removeFromFavourites(imageData:ImageData)
    {
        var id = (imageData.id as NSString).UTF8String
        sqlite3_bind_text(deleteStatement, 1, id, -1, nil)
        
        if(sqlite3_step(deleteStatement) == SQLITE_DONE)
        {
        }
        else
        {
            println("Error code: ",sqlite3_errcode(flickrCADB))
            let error = String.fromCString(sqlite3_errmsg(flickrCADB))
            println("Eror message: ", error)
        }
        sqlite3_reset(deleteStatement)
        sqlite3_clear_bindings(deleteStatement)
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "FavouriteShowImage" {
            if let indexPath = self.tableView.indexPathForSelectedRow()
            {
                let seg = (segue.destinationViewController as FavouriteShowImageViewController);
                seg.imageData = imageDataList[indexPath.row];
                seg.flickrCADB = self.flickrCADB;
            }
        }
    }
    
}






