//
//  ViewController.swift
//  innovation-manga-reader
//
//  Created by Lucas Le on 8/29/16.
//  Copyright © 2016 Lucas Le. All rights reserved.
//

import UIKit
import Kanna
import Alamofire
import Kingfisher
import SQLite


class ViewController: UIViewController, UIScrollViewDelegate {

    class Chapter {
        var title: String?
        var url: String?
    }

    @IBOutlet var scroll: UIScrollView!

    let screenSize: CGRect = UIScreen.mainScreen().bounds

    var scrollHeight: CGFloat = 0

    var chapters: [Chapter] = []
    
    func testDb() throws {
        print("Start test")
        
        let path = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory, .UserDomainMask, true
            ).first!
        
        print("Path \(path)")
        let db = try Connection("\(path)/db.sqlite3")
        
        print("Connected")
        let users = Table("users")
        let id = Expression<Int64>("id")
        let name = Expression<String?>("name")
        let email = Expression<String>("email")
        
        try db.run(users.drop(ifExists: true))
        
        do{
        try db.run(users.create { t in
            t.column(id, primaryKey: true)
            t.column(name)
            t.column(email, unique: true)
            })
        }catch {
            print(error)
        }
        print("Connected")
        let insert = users.insert(name <- "Alice", email <- "alice@mac.com")
        let rowid = try db.run(insert)
        // INSERT INTO "users" ("name", "email") VALUES ('Alice', 'alice@mac.com')
        
        print("Connected")
        for user in try db.prepare(users) {
            print("id: \(user[id]), name: \(user[name]), email: \(user[email])")
            // id: 1, name: Optional("Alice"), email: alice@mac.com
        }
        // SELECT * FROM "users"
        
        let alice = users.filter(id == rowid)
        
        print("Connected")
        try db.run(alice.update(email <- email.replace("mac.com", with: "me.com")))
        // UPDATE "users" SET "email" = replace("email", 'mac.com', 'me.com')
        // WHERE ("id" = 1)
        
        try db.run(alice.delete())
        // DELETE FROM "users" WHERE ("id" = 1)
        
        print("Connected")
        db.scalar(users.count) // 0
        
    }

    override func viewWillAppear(animated: Bool) {
        
        do{
            try self.testDb()
        }catch {
            print("Error test DB")
        }
        
        // using swift to retrive list chapter of Inu - http://blogtruyen.com/5898/inuyasha-remake
        //retriveListChapter()
        

        //loadChap("http://blogtruyen.com/c94502/inuyasha-remake-vol-10-1");


    }
    
    func retriveListChapter(){
        Alamofire.request(.GET, "http://blogtruyen.com/5898/inuyasha-remake")
            .validate(statusCode: 200 ..< 300)
            .responseString {
                response in
                if let doc = Kanna.HTML(html: response.result.value!, encoding: NSUTF8StringEncoding) {
                    
                    for link in doc.css("#list-chapters a") {
                        let c = Chapter()
                        c.title = link["title"]
                        c.url = "http://blogtruyen.com" + link["href"]!
                        self.chapters.append(c)
                    }
                    
                    self.chapters.sortInPlace {
                        (c1: Chapter, c2: Chapter) -> Bool in
                        let firstNoOfChap1 = self.parseFirstNo(c1.title)
                        let firstNoOfChap2 = self.parseFirstNo(c2.title)
                        
                        let secondNoOfChap1 = self.parseSecondNo(c1.title)
                        let secondNoOfChap2 = self.parseSecondNo(c2.title)
                        
                        return firstNoOfChap1 != firstNoOfChap2 ? firstNoOfChap2 > firstNoOfChap1 : secondNoOfChap2 > secondNoOfChap1
                    }
                    
                    for c in self.chapters {
                        print(c.title)
                    }
                    
                }
        }
    }


    func parseFirstNo(title: String!) -> Int {
        let number = title.characters.split(" ").map(String.init)[4]
        let first = number.characters.split(".").map(String.init)[0]
        return Int(first)!;
    }

    func parseSecondNo(title: String!) -> Int {
        let number = title.characters.split(" ").map(String.init)[4]
        if (number.rangeOfString(".") != nil && number.characters.split(".").map(String.init).count > 0) {
            let second = number.characters.split(".").map(String.init)[1]
            return Int(second)!;
        }
        return 0;
    }

    func loadChap(urlStr: String) {
        Alamofire.request(.GET, urlStr)
        .validate(statusCode: 200 ..< 300)
        .responseString {
            response in
            if let doc = Kanna.HTML(html: response.result.value!, encoding: NSUTF8StringEncoding) {
                print("Start load image")
                for link in doc.css("#content img") {
                    self.loadImage(link)
                }
            }
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        scroll.delegate = self

    }

    func loadImage(link: Kanna.XMLElement) {
        let imageView = UIImageView();

        imageView.kf_setImageWithURL(NSURL(string: link["src"]!)!,
                placeholderImage: nil,
                optionsInfo: nil,
                completionHandler: {
                    (image, error, cacheType, imageURL) -> () in

                    let oldWidth = image?.size.width
                    let oldHeight = image?.size.height

                    let scaleFactor = self.screenSize.width / oldWidth!

                    let newHeight = oldHeight! * scaleFactor;
                    let newWidth = oldWidth! * scaleFactor;

                    imageView.contentMode = .ScaleAspectFill

                    imageView.frame = CGRect(x: 0, y: self.scrollHeight, width: newWidth, height: newHeight)

                    self.scrollHeight = self.scrollHeight + newHeight;
                    self.scroll.addSubview(imageView)
                    self.scroll.contentSize = CGSizeMake(self.screenSize.width, self.scrollHeight);
                }
        )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    var isLoading = false

    func scrollViewDidScroll(scrollView: UIScrollView) {
        let currentYPosition = self.scroll.contentOffset.y
        if (currentYPosition > (self.scrollHeight - 3000) && !isLoading) {

            print("load next chapter")
            isLoading = true
            loadChap("http://blogtruyen.com/c94503/inuyasha-remake-vol-10-2")
        }
    }


}

