import UIKit
import RealmSwift

class RoutineViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var routinesTableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var todayDateLabel: UILabel!
    @IBOutlet weak var message: UILabel!
    
    private var viewWidth: CGFloat!
    private var viewHeight: CGFloat!
    private var cellWidth: CGFloat!
    private var cellHeight: CGFloat!
    private var cellOffset: CGFloat!
    private var navHeight: CGFloat!
    
    let realm = try! Realm()
    private let routineModel = Routine()
    private let dateModel = DateModel()
    
    var routineID = ""
    var selectedID = ""
    var routineOrder = 0
    private var unwrappedAllTimeInt = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        routinesTableView.reloadData()
        navigationController?.navigationBar.isHidden = true
        print ("🟥全てのデータ🟥\n\(realm.objects(Routine.self))")
    }
    
    private func setupView() {
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .clear
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        todayDateLabel.text = dateModel.getTodayDate()
        addButton.tintColor = .darkGray
        addButton.layer.shadowOpacity = 0.2
        addButton.layer.shadowRadius = 8
        addButton.layer.shadowColor = UIColor.black.cgColor
        addButton.layer.shadowOffset = CGSize(width: 1, height: 1)
        
        viewWidth = view.frame.width
        viewHeight = view.frame.height
        navHeight = self.navigationController?.navigationBar.frame.size.height
        
        routinesTableView.delegate = self
        routinesTableView.dataSource = self
        routinesTableView.dragDelegate = self
        routinesTableView.dropDelegate = self
        routinesTableView.dragInteractionEnabled = true
        routinesTableView.register(UINib(nibName: "RoutineTableViewCell", bundle: nil), forCellReuseIdentifier: "routineCell")
        routinesTableView.separatorStyle = .none
        routinesTableView.showsVerticalScrollIndicator = false
    }
    //finishViewControllerからの帰還
    @IBAction func unwindSegue(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) {}
    
    @IBAction func addButton(_ sender: Any) {
        var alertTextField: UITextField?
        let alert = UIAlertController(title: "新しいルーティーン",
                                      message: "ルーティーンのタイトルを\n入力してください",
                                      preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "キャンセル", style: .default)
        let saveAction = UIAlertAction(title: "保存", style: .default) { _ in
            let newTitle = alertTextField?.text ?? ""
            
            let routineItems = self.realm.objects(Routine.self).sorted(byKeyPath: "routineOrder", ascending: true)
            self.routineModel.createRoutine(routineTitle: "\(newTitle)", routineOrder: routineItems.count)
            self.routinesTableView.reloadData()
            Feedbacker.impact(style: .medium)
            print(":large_red_square:全てのデータ:large_red_square:\n\(self.realm.objects(Routine.self))")
        }
        saveAction.isEnabled = false
        alert.addTextField { (textField) in
            alertTextField = textField
            textField.placeholder = "例：朝の準備"
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: .main, using: { _ in
                let textCount = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).count ?? 0
                saveAction.isEnabled = textCount > 0
            })
            alert.addAction(cancelAction)
            alert.addAction(saveAction)
            self.present(alert, animated: true)
        }
    }
}

extension RoutineViewController: UITableViewDelegate, UITableViewDataSource, UITableViewDragDelegate, UITableViewDropDelegate {
    //セルの個数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let routineItems = self.realm.objects(Routine.self)
        return routineItems.count
    }
    //セルの中身
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "routineCell", for: indexPath) as! RoutineTableViewCell
        let routineItems = realm.objects(Routine.self).sorted(byKeyPath: "routineOrder", ascending: true)
        cell.cellTitle?.text = "\(routineItems[indexPath.row].routineTitle)"
        cell.cellTime?.text = "合計\(routineItems[indexPath.row].totalTime/60)分\(routineItems[indexPath.row].totalTime%60)秒"
        cell.mainBackground.layer.cornerRadius = 0.035*viewWidth
        cell.mainBackground.layer.masksToBounds = true
        message.isHidden = routineItems.count != 0
        return cell
    }
    //セルの高さ
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    //セルが選択された時
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //画面遷移
//        let taskVC = self.storyboard?.instantiateViewController(withIdentifier: "TaskView") as! TaskViewController
        let storyboard = UIStoryboard(name: "Task", bundle: nil)
        let taskVC = storyboard.instantiateViewController(withIdentifier: "TaskView") as! TaskViewController
        
        let routineItems = realm.objects(Routine.self).sorted(byKeyPath: "routineOrder", ascending: true)
        taskVC.routineID = routineItems[indexPath.row].routineID
        self.navigationController?.pushViewController(taskVC, animated: true)
        
        Feedbacker.impact(style: .medium)
    }
    //セルの編集許可
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    //スワイプしたセルを削除
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            Feedbacker.impact(style: .medium)
            routineModel.removeRoutine(indexPath: indexPath.row)
            tableView.deleteRows(at: [indexPath as IndexPath], with: .automatic)
            print("🟥全てのデータ🟥\n\(self.realm.objects(Routine.self))")
        }
    }
    //deleteボタンのカスタマイズ
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { (_, _, completionHandler) in
            Feedbacker.impact(style: .medium)
            self.routineModel.removeRoutine(indexPath: indexPath.row)
            tableView.deleteRows(at: [indexPath as IndexPath], with: .automatic)
            print("🟥全てのデータ🟥\n\(self.realm.objects(Routine.self))")
            completionHandler(true)
        }
        deleteAction.image = UIImage(named: "delete")
        deleteAction.backgroundColor = .systemRed
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    //セルの並び替え
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        try! realm.write {
            let routineItems = realm.objects(Routine.self).sorted(byKeyPath: "routineOrder", ascending: true)
            let sourceObject = routineItems[sourceIndexPath.row]
            let destinationObject = routineItems[destinationIndexPath.row]
            
            let destinationObjectOrder = destinationObject.routineOrder
            
            if sourceIndexPath.row < destinationIndexPath.row {
                // 上から下に移動した場合、間の項目を上にシフト
                for index in sourceIndexPath.row...destinationIndexPath.row {
                    let object = routineItems[index]
                    object.routineOrder -= 1
                }
            } else {
                // 下から上に移動した場合、間の項目を下にシフト
                for index in (destinationIndexPath.row..<sourceIndexPath.row).reversed() {
                    let object = routineItems[index]
                    object.routineOrder += 1
                }
            }
            // 移動したセルの並びを移動先に更新
            sourceObject.routineOrder = destinationObjectOrder
            print ("🟥全てのデータ🟥\n\(realm.objects(Routine.self))")
        }
    }
    //ドラッグ
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return [UIDragItem(itemProvider: NSItemProvider())]
    }
    //ドロップ
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        if session.localDragSession != nil {
            return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UITableViewDropProposal(operation: .cancel, intent: .unspecified)
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
    }
}
