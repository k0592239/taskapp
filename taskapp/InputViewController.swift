//
//  InputViewController.swift
//  taskapp
//
//  Created by 佐藤佳子 on 2022/12/25.
//

import UIKit
import RealmSwift
import UserNotifications

class InputViewController: UIViewController {
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var categoryTextField: UITextField!
    let realm = try! Realm()
    var task: Task!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        contentsTextView.layer.borderWidth = 0.6
        contentsTextView.layer.borderColor = UIColor.systemGray5.cgColor
        contentsTextView.layer.cornerRadius = 6
        contentsTextView.layer.masksToBounds = true
        
        titleTextField.text = task.title
        contentsTextView.text = task.contents
        datePicker.date = task.date
        categoryTextField.text = task.category
    }
    // Saveボタン押下時（DB保存）
    @IBAction func onSave(_ sender: Any) {
        print("save")
        try! realm.write {
            self.task.title = self.titleTextField.text!
            self.task.contents = self.contentsTextView.text
            self.task.date = self.datePicker.date
            self.task.category = self.categoryTextField.text!
            self.realm.add(self.task, update: .modified)
        }
        setNotification(task: task)
        self.navigationController?.popViewController(animated: true)
    }
    // Cancelボタン押下時（画面遷移のみ）
    @IBAction func onCancel(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    // 遷移元に戻る
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    // タスクのローカル通知を登録する
    func setNotification(task: Task) {
        let content = UNMutableNotificationContent()
        // タイトルと内容を設定（中身が無い場合メッセージ無しで音だけの通知になるので「（xxなし）」を表示する）
        if task.title == "" {
            content.title = "(タイトルなし)"
        } else {
            content.title = task.title
        }
        if task.contents == "" {
            content.body = "(内容なし)"
        } else {
            content.body = task.contents
        }
        if task.category == "" {
            content.body = "(カテゴリなし)"
        } else {
            content.body = task.category
        }
        content.sound = UNNotificationSound.default
        // ローカル通知が発動するtrigger(日付マッチ)を作成
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        // identifier, content, triggerからローカル通知を作成（identifierが同じだとローカル通知を上書き保存）
        let request = UNNotificationRequest(identifier: String(task.id), content: content, trigger: trigger)
        // ローカル通知を登録
        let center = UNUserNotificationCenter.current()
        center.add(request) {
            (error) in print(error ?? "ローカル通知登録 OK")
        }
        // 未通知のローカル通知一覧をログ出力
        center.getPendingNotificationRequests{(requests: [UNNotificationRequest]) in
            for request in requests {
                print("/--------------")
                print(request)
                print("--------------/")
            }
        }
    }
    @objc func dismissKeyboard(){
        // キーボードを閉じる
        view.endEditing(true)
    }
}
