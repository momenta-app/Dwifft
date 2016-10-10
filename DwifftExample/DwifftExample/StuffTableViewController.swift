//
//  StuffTableViewController.swift
//  DwifftExample
//
//  Created by Jack Flintermann on 8/23/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

import UIKit
import Dwifft

struct DemoRow : Identifiable {
    let uuid : String
    var name : String
    
    init(uuid: String, name: String) {
        self.uuid = uuid
        self.name = name
    }
}

// MARK: - Equatable

extension DemoRow : Equatable {}

func ==(lhs: DemoRow, rhs: DemoRow) -> Bool {
    if lhs.uuid != rhs.uuid { return false }
    return lhs.name == rhs.name
}

// MARK: - Hashable

extension DemoRow : Hashable {
    var hashValue : Int {
        return uuid.hash
    }
}


class StuffTableViewController: UITableViewController {

    static let possibleStuff = [
        DemoRow(uuid: UUID().uuidString, name: "Cats"),
        DemoRow(uuid: UUID().uuidString, name: "Onions"),
        DemoRow(uuid: UUID().uuidString, name: "A used lobster"),
        DemoRow(uuid: UUID().uuidString, name: "Splinters"),
        DemoRow(uuid: UUID().uuidString, name: "Mud"),
        DemoRow(uuid: UUID().uuidString, name: "Pineapples"),
        DemoRow(uuid: UUID().uuidString, name: "Fish legs"),
        DemoRow(uuid: UUID().uuidString, name: "Adam's apple"),
        DemoRow(uuid: UUID().uuidString, name: "Igloo cream"),
        DemoRow(uuid: UUID().uuidString, name: "Self-flying car")
    ]
    
    // I shamelessly stole this list of things from my friend Pasquale's blog post because I thought it was funny. You can see it at https://medium.com/elepath-exports/spatial-interfaces-886bccc5d1e9
    
    static func randomArrayOfStuff() -> [DemoRow] {
        var possibleStuff = self.possibleStuff
        for i in 0..<possibleStuff.count - 1 {
            let j = Int(arc4random_uniform(UInt32(possibleStuff.count - i))) + i
            if i != j {
                swap(&possibleStuff[i], &possibleStuff[j])
            }
        }
        let subsetCount: Int = Int(arc4random_uniform(3)) + 5
        return Array(possibleStuff[0...subsetCount])
    }
    
    required init!(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Shuffle", style: .plain, target: self, action: #selector(StuffTableViewController.shuffle))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "TapTap", style: .plain, target: self, action: #selector(StuffTableViewController.taptap))
    }
    
    @objc func shuffle() {
        self.stuff = StuffTableViewController.randomArrayOfStuff()
    }
    
    @objc func taptap() {
        var stuff = self.stuff
        let item = stuff.remove(at: 0)
        stuff.append(item)
        stuff[2].name = "HELLO"
        self.stuff = stuff
    }
    
    
    // MARK: - Dwifft stuff
    // This is the stuff that's relevant to actually using Dwifft. The rest is just boilerplate to get the app working.
    
    var diffCalculator: TableViewDiffCalculator<DemoRow>?
    
    var stuff: [DemoRow] = StuffTableViewController.randomArrayOfStuff() {
        // So, whenever your datasource's array of things changes, just let the diffCalculator know and it'll do the rest.
        didSet {
            self.diffCalculator?.rows = stuff
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        self.diffCalculator = TableViewDiffCalculator<DemoRow>(tableView: self.tableView, initialRows: self.stuff)
        
        // You can change insertion/deletion animations like this! Fade works well. So does Top/Bottom. Left/Right/Middle are a little weird, but hey, do your thing.
        self.diffCalculator?.insertionAnimation = .fade
        self.diffCalculator?.deletionAnimation = .fade
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.stuff.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.textLabel?.text = self.stuff[(indexPath as NSIndexPath).row].name
        return cell
    }

}
