//
//  ViewController.swift
//  taskapp
//
//  Created by 佐藤佳子 on 2022/12/25.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController,UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var whereTextField: UITextField!
    // Realmインスタンスを取得する
    let realm = try! Realm()
    // DB内のタスクが格納されるリスト
    // 日付の近い順でソート：昇順
    // 移行内容をアップデートするとリスト内は自動的に更新される
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.fillerRowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        whereTextField?.delegate = self

        let imageView = UIImageView(frame: CGRect(x: 4.0, y: 0.0, width: 22.0, height: 22.0))
        let image = UIImage(systemName: "magnifyingglass")
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.systemGray4

        let view = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 22))
        view.addSubview(imageView)
        whereTextField?.leftView = view
        whereTextField?.leftViewMode = UITextField.ViewMode.always

        // Backボタンの変更
        self.navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "戻る"
        )
        
    }
    // データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        // Cellに値を設定する
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        let dateString:String = formatter.string(from: task.date)
        cell.detailTextLabel?.text = "\(dateString) \(task.category)"

        return cell
    }
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue", sender: nil)
    }
    // セルが削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 削除するタスクを取得する
            let task = self.taskArray[indexPath.row]
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            // データベースから削除
            try! realm.write {
                self.realm.delete(self.taskArray[indexPath.row])
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests{(requests:[UNNotificationRequest]) in
                for request in requests {
                    print("/--------------")
                    print(request)
                    print("--------------/")
                }
            }
        }
    }
    // segue で画面遷移するときに呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let inputViewController:InputViewController = segue.destination as! InputViewController
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            let task = Task()
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
            inputViewController.task = task
        }
    }
    // 入力画面から戻ってきたときに TableView を更新させる
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    @IBAction func searchReloadData(_ sender: UITextField) {
        self.taskArray = self.realm.objects(Task.self)
        if !sender.text!.isEmpty {
            self.taskArray = self.taskArray.filter("category == %@", sender.text!)
        }
        self.taskArray = self.taskArray.sorted(byKeyPath: "date", ascending: true)
        self.tableView.reloadData()
    }
    
}

