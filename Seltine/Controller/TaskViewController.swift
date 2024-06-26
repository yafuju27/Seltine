import UIKit
import RealmSwift

class TaskViewController: UIViewController {
    
    @IBOutlet weak var taskTableView: UITableView!
    @IBOutlet weak var titleBackView: UIView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var allTimeLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var message: UILabel!
    
    private var viewWidth: CGFloat!
    private var viewHeight: CGFloat!
    private var cellWidth: CGFloat!
    private var cellHeight: CGFloat!
    private var cellOffset: CGFloat!
    private var navHeight: CGFloat!
    private var alertController: UIAlertController!
    
    let realm = try! Realm()
    private let routineModel = Routine()
    
    var routineID = ""
    private var unwrappedAllTimeInt = 0
    private var allTimeCount = 0
    private var taskTitleArray = [""]
    private var taskTimeArray = [0]
    
    private let timeList = [[Int](0...60), [Int](0...60)]
    private let screenWidth = UIScreen.main.bounds.width - 20
    private let screenHeight = UIScreen.main.bounds.height / 2
    private var selectedRow = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let targetRoutine = realm.object(ofType: Routine.self, forPrimaryKey: routineID)
        titleTextField.text = targetRoutine?.routineTitle
        updateTotalTimeLabel()
        taskTableView.reloadData()
        navigationController?.navigationBar.isHidden = true
        print("🟦遷移後のselectedID:\(routineID)")
        print ("🟥全てのデータ🟥\n\(realm.objects(Routine.self))")
    }
    
    private func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.titleTextField.resignFirstResponder()
        return true
    }
    
    private func alert(title:String, message:String) {
        alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true)
    }
    
    private func setupView() {
        taskTableView.delegate = self
        taskTableView.dataSource = self
        taskTableView.dragDelegate = self
        taskTableView.dropDelegate = self
        taskTableView.dragInteractionEnabled = true
        
        taskTableView.register(UINib(nibName: "TaskTableViewCell", bundle: nil), forCellReuseIdentifier: "taskCell")
        taskTableView.separatorStyle = .none
        taskTableView.showsVerticalScrollIndicator = false
        
        startButton.layer.shadowOpacity = 0.2
        startButton.layer.shadowRadius = 12
        startButton.layer.shadowColor = UIColor.black.cgColor
        startButton.layer.shadowOffset = CGSize(width: 1, height: 1)
        
        addButton.layer.shadowOpacity = 0.2
        addButton.layer.shadowRadius = 12
        addButton.layer.shadowColor = UIColor.black.cgColor
        addButton.layer.shadowOffset = CGSize(width: 1, height: 1)
        
        titleBackView.layer.cornerRadius = 15
        titleTextField.borderStyle = .none
        
        viewWidth = view.frame.width
        viewHeight = view.frame.height
        navHeight = self.navigationController?.navigationBar.frame.size.height
        
        titleBackView.layer.borderWidth = 3.0
        titleBackView.layer.borderColor = UIColor.darkGray.cgColor
        
        // 画面がタップされたらキーボード閉じるための処理準備
        let tapGR: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGR.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGR)
        
        let targetRoutine = realm.object(ofType: Routine.self, forPrimaryKey: routineID)
        navigationItem.title = "\(targetRoutine?.routineTitle ?? "")"
        self.navigationController?.navigationBar.barTintColor = .clear
    }
    
    private func updateTotalTimeLabel() {
        let targetRoutine = realm.object(ofType: Routine.self, forPrimaryKey: routineID)
        unwrappedAllTimeInt = targetRoutine?.totalTime ?? 0
        allTimeLabel.text = "合計\(Int(unwrappedAllTimeInt/60))分\(Int(unwrappedAllTimeInt%60))秒"
    }
    
    @IBAction func titleTextfieldChanged(_ sender: Any) {
        let updateTitle = titleTextField.text ?? ""
        routineModel.updateRoutine(routineID: routineID, routineTitle: updateTitle)
    }
    
    @IBAction func addTaskButtonAction(_ sender: Any) {
        Feedbacker.impact(style: .medium)
        let storyboard = UIStoryboard(name: "Detail", bundle: nil)
        let detailVC = storyboard.instantiateViewController(withIdentifier: "DetailView") as! DetailViewController
        detailVC.modalPresentationStyle = .overCurrentContext
        detailVC.modalTransitionStyle = .crossDissolve
        self.present(detailVC, animated: true)
        
        detailVC.selectedRoutineID = routineID
        print ("🟥全てのデータ🟥\n\(realm.objects(Routine.self))")
    }
    
    @IBAction func startButton(_ sender: Any) {
        Feedbacker.impact(style: .medium)
        let storyboard = UIStoryboard(name: "Timer", bundle: nil)
        let timerVC = storyboard.instantiateViewController(withIdentifier: "TimerView") as! TimerViewController
        let taskItems = self.realm.object(ofType: Routine.self, forPrimaryKey: self.routineID)?.task.sorted(byKeyPath: "taskOrder", ascending: true)
        if taskItems?.count == 0 {
            alert(title: "タスクがありません", message: "タスクを追加してください")
            return
        }
        let taskNumber = (taskItems?.count ?? 0) - 1
        taskTitleArray = []
        taskTimeArray = []
        for i in 0...taskNumber {
            taskTitleArray.append(contentsOf: ["\(taskItems?[i].taskTitle ?? "")"])
            taskTimeArray.append(contentsOf: [taskItems?[i].taskTime ?? 0])
        }
        timerVC.titleArray = taskTitleArray
        timerVC.timeArray = taskTimeArray
        if titleTextField.text == "" {
            alert(title: "タイトルがありません", message: "タイトルの欄に文字を入力してください")
            return
        }
        self.navigationController?.pushViewController(timerVC, animated: true)
    }
    
    @IBAction func backBtnAction(_ sender: Any) {
        if titleTextField.text == "" {
            alert(title: "タイトルがありません", message: "タイトルの欄に文字を入力してください")
            return
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    //キーボード閉じる処理
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
}

extension TaskViewController: UITableViewDelegate, UITableViewDataSource, UITableViewDragDelegate, UITableViewDropDelegate {
    //セルの個数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let targetRoutine = realm.object(ofType: Routine.self, forPrimaryKey: routineID)
        return targetRoutine?.task.count ?? 0
    }
    //セルの中身
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskCell", for: indexPath) as! TaskTableViewCell
        let targetRoutine = realm.object(ofType: Routine.self, forPrimaryKey: routineID)
        let targetTask = targetRoutine?.task.sorted(byKeyPath: "taskOrder", ascending: true)
        cell.taskName.text = targetTask?[indexPath.row].taskTitle
        if let unwrappedTime = targetTask?[indexPath.row].taskTime {
            cell.taskTime.text = "\(Int(unwrappedTime/60))分\(Int(unwrappedTime%60))秒"
        } else {
            print("taskTimeはnil")
        }
        
        cell.backView.layer.cornerRadius = viewWidth / 18
        cell.backgroundColor = .clear
        cell.layer.masksToBounds = false
        
        cell.chain1.alpha = indexPath.row == 0 ? 0.0 : 1.0
        cell.chain2.alpha = indexPath.row == Int(targetTask?.endIndex ?? 0)-1 ? 0.0 : 1.0
        
        message.isHidden = targetTask?.count != 0
        return cell
    }
    //セルの高さ
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    //セルが選択された時
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Detail", bundle: nil)
        let detailVC = storyboard.instantiateViewController(withIdentifier: "DetailView") as! DetailViewController
        
        let taskItems = realm.object(ofType: Routine.self, forPrimaryKey: routineID)?.task.sorted(byKeyPath: "taskOrder", ascending: true)
        detailVC.selectedRoutineID = routineID
        detailVC.selectedTaskID = taskItems?[indexPath.row].taskID ?? ""
        detailVC.modalPresentationStyle = .overCurrentContext
        detailVC.modalTransitionStyle = .crossDissolve
        self.present(detailVC, animated: true)
    }
    //セルの編集許可
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    //スワイプしたセルを削除
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            Feedbacker.impact(style: .medium)
            
                let targetRoutine = realm.object(ofType: Routine.self, forPrimaryKey: routineID)
                let taskItems = realm.object(ofType: Routine.self, forPrimaryKey: routineID)?.task.sorted(byKeyPath: "taskOrder", ascending: true)
                let item = taskItems?[indexPath.row]
            try! realm.write {
                let nextOrder = (item?.taskOrder ?? 0) + 1
                let lastOrder = (taskItems?.count ?? 0) - 1
                if lastOrder == 0 || nextOrder == taskItems?.count {
                    targetRoutine?.totalTime -= item?.taskTime ?? 0
                } else {
                    targetRoutine?.totalTime -= item?.taskTime ?? 0
                    for index in nextOrder...lastOrder {
                        let object = taskItems?[index]
                        object?.taskOrder -= 1
                    }
                }
                realm.delete(item!)
            }
            //routineModel.removeTask(indexPath: indexPath.row)
            tableView.deleteRows(at: [indexPath as IndexPath], with: .automatic)
            updateTotalTimeLabel()
            tableView.reloadData()
            print ("🟥全てのデータ🟥\n\(realm.objects(Routine.self))")
        }
        updateTotalTimeLabel()
    }
    //deleteボタンのカスタマイズ
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { (_, _, completionHandler) in
            Feedbacker.impact(style: .medium)
            
                let targetRoutine = self.realm.object(ofType: Routine.self, forPrimaryKey: self.routineID)
                let taskItems = self.realm.object(ofType: Routine.self, forPrimaryKey: self.routineID)?.task.sorted(byKeyPath: "taskOrder", ascending: true)
                let item = taskItems?[indexPath.row]
            try! self.realm.write {
                let nextOrder = (item?.taskOrder ?? 0) + 1
                let lastOrder = (taskItems?.count ?? 0) - 1
                if lastOrder == 0 || nextOrder == taskItems?.count {
                    targetRoutine?.totalTime -= item?.taskTime ?? 0
                } else {
                    targetRoutine?.totalTime -= item?.taskTime ?? 0
                    for index in nextOrder...lastOrder {
                        let object = taskItems?[index]
                        object?.taskOrder -= 1
                    }
                }
                self.realm.delete(item!)
            }
            //self.routineModel.removeTask(indexPath: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
            self.updateTotalTimeLabel()
            tableView.reloadData()
            print ("🟥全てのデータ🟥\n\(self.realm.objects(Routine.self))")
        }
        deleteAction.image = UIImage(named: "delete")
        deleteAction.backgroundColor = .systemRed
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    //セルの並び替え
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        try! realm.write {
            let taskItems = realm.object(ofType: Routine.self, forPrimaryKey: routineID)?.task.sorted(byKeyPath: "taskOrder", ascending: true)
            let sourceObject = taskItems?[sourceIndexPath.row]
            let destinationObject = taskItems?[destinationIndexPath.row]
            
            let destinationObjectOrder = destinationObject?.taskOrder
            
            if sourceIndexPath.row < destinationIndexPath.row {
                // 上から下に移動した場合、間の項目を上にシフト
                for index in sourceIndexPath.row...destinationIndexPath.row {
                    let object = taskItems?[index]
                    object?.taskOrder -= 1
                }
            } else {
                // 下から上に移動した場合、間の項目を下にシフト
                for index in (destinationIndexPath.row..<sourceIndexPath.row).reversed() {
                    let object = taskItems?[index]
                    object?.taskOrder += 1
                }
            }
            // 移動したセルの並びを移動先に更新
            sourceObject?.taskOrder = destinationObjectOrder ?? 0
            tableView.reloadData()
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








