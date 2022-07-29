import UIKit

private class FirstResponderTableView: UITableView {
    override var canBecomeFirstResponder: Bool {
        return true
    }
}

protocol ConsoleDelegate: class {
    func console(executed command: String)
    func reloadConsole()
    func unreadMessagesCount(count: Int)
}

class ConsoleViewController: UIViewController, UIWebViewDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, NotificationHandler {
    private var tableView = FirstResponderTableView()
    private let executeField = ConsoleExecuteField()
    private let executeButton = UIButton()
    private let containerView = UIView()
    
    private var trailingFieldMargin: NSLayoutConstraint!
    private var bottomConstraint: NSLayoutConstraint!
    private var leadingFieldMargin: NSLayoutConstraint!
    
    internal var messagesArray: [ConsoleMessage] = []
    internal var messages = 0
    internal var isLoaded = false
    
    private let maxMessages = 1000
    private let font = UIFont(name: "DejaVuSansMono", size: 14)!
    weak var delegate: ConsoleDelegate!
    
    private var history = [ConsoleCacheItem]()
    private var historyIndex: Int!
    private var scriptCache: ConsoleCacheItem!
    
    static var font = UIFont(name: "DejaVuSansMono", size: 12)!
    static var fontItalic = UIFont(name: "DejaVuSansMono-Oblique", size: 12)!
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    static var activeColorScheme: [UIColor] {
        if userPreferences.currentTheme.isDark {
            return darkColorScheme
        } else {
            return lightColorScheme
        }
    }
    
    static var inactiveColorScheme: [UIColor] {
        if userPreferences.currentTheme.isDark {
            return lightColorScheme
        } else {
            return darkColorScheme
        }
    }
    
    static var lightColorScheme = [
        #colorLiteral(red: 1, green: 0.20458019, blue: 0.1013487829, alpha: 1), // Строка
        #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1), // Ключевое слово (NaN, undefined, true, false, и т.д)
        #colorLiteral(red: 0.1764705926, green: 0.01176470611, blue: 0.5607843399, alpha: 1), // Число
        #colorLiteral(red: 0.4431372549, green: 0, blue: 0.4862745098, alpha: 1), // Ключ в объектах
        #colorLiteral(red: 0.9960784314, green: 0, blue: 0.02745098039, alpha: 1)  // Для полей с геттером, который умеет делать throw
    ]
    
    static var darkColorScheme = [
        #colorLiteral(red: 0.9176470588, green: 0.537254902, blue: 0.2509803922, alpha: 1), // Строка
        #colorLiteral(red: 0.9098039216, green: 0.5764705882, blue: 0.9254901961, alpha: 1), // Ключевое слово (NaN, undefined, true, false, и т.д)
        #colorLiteral(red: 0.8431372549, green: 0.6196078431, blue: 0.9960784314, alpha: 1), // Число
        #colorLiteral(red: 0.5764705882, green: 0.5764705882, blue: 0.5764705882, alpha: 1), // Ключ в объектах
        #colorLiteral(red: 0.9882352941, green: 0.09411764706, blue: 0.1529411765, alpha: 1)  // Для полей с геттером, который умеет делать throw
    ]
    
    var cachedKeyCommands = [
        UIKeyCommand(input: "r", modifierFlags: .command, action: #selector(reload), discoverabilityTitle: localize("reload")),
        UIKeyCommand(input: "\r", modifierFlags: [.shift], action: #selector(addLine)),
        UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(moveHistoryUp)),
        UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(moveHistoryDown))
    ]
    
    @objc func reload() {
        delegate?.reloadConsole()
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return cachedKeyCommands
    }
    
    @objc func addLine() {
        executeField.insertText("\n")
        
        adjustTextViewHeight()
    }
    
    private func applyHistoryItem(item: ConsoleCacheItem) {
        
        if(item.text.isEmpty && !executeField.isFirstResponder) {
            executeField.showPlaceholder()
        } else {
            executeField.hidePlaceholder()
            executeField.text = item.text
            executeField.selectedTextRange = item.cursorPosition
        }
        
        adjustTextViewHeight()
    }
    
    private func moveCursor(up: Bool) -> Bool {
        if let cursorPosition = executeField.selectedTextRange?.start {
            let caretPositionRect = executeField.caretRect(for: cursorPosition)
            
            let yMiddle = caretPositionRect.origin.y + (caretPositionRect.height / 2)
            let lineHeight = caretPositionRect.height
            
            var estimatedUpPoint = CGPoint(x: caretPositionRect.origin.x, y: up ? (yMiddle - lineHeight) : (yMiddle + lineHeight))
            if let newSelection = executeField.characterRange(at: estimatedUpPoint) {
                
                // При сдвиге курсора вниз на самой нижней строке он перемещается в конец строке, так что
                // делаем дополнительную проверку: сдвинулись ли мы действительно?
                
                if !up, executeField.caretRect(for: newSelection.end).origin.y == caretPositionRect.origin.y {
                    return false
                }
                
                executeField.selectedTextRange = executeField.textRange(from: newSelection.end, to: newSelection.end)
                return true
            }
            
            estimatedUpPoint.x += caretPositionRect.width
            
            if let newSelection = executeField.characterRange(at: estimatedUpPoint) {
               
                // При сдвиге курсора вниз на самой нижней строке он перемещается в конец строке, так что
                // делаем дополнительную проверку: сдвинулись ли мы действительно?
                
                if !up, executeField.caretRect(for: newSelection.start).origin.y == caretPositionRect.origin.y {
                    return false
                }
                
                executeField.selectedTextRange = executeField.textRange(from: newSelection.start, to: newSelection.start)
                return true
            }
            
            return false
        }
        
        return true
    }
    
    @objc func moveHistoryUp() {
        
        guard !moveCursor(up: true) else { return }
        
        guard !history.isEmpty else { return }
        
        if let index = historyIndex, let range = executeField.selectedTextRange {
            history[index].cursorPosition = range
        }
        
        if historyIndex == nil {
            historyIndex = history.count - 1
            
            scriptCache = ConsoleCacheItem(field: executeField)
        } else {
            historyIndex -= 1
            
            if historyIndex < 0 {
                historyIndex = 0
                return
            }
        }
        
        applyHistoryItem(item: history[historyIndex])
    }
    
    @objc func moveHistoryDown() {
        
        guard !moveCursor(up: false) else { return }
        
        guard !history.isEmpty else { return }
        
        if historyIndex == nil {
            return
        }
        
        if let range = executeField.selectedTextRange {
            history[historyIndex!].cursorPosition = range
        }
        
        historyIndex += 1
        
        if historyIndex >= history.count {
            historyIndex = nil
            applyHistoryItem(item: scriptCache)
            scriptCache = nil
        } else {
            let cacheItem = history[historyIndex]
            
            applyHistoryItem(item: cacheItem)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if(scrollView == tableView) {
            // Скролл консоли
            
        } else {
            // Скролл поля ввода
            
            let y = scrollView.contentOffset.y
            let height = scrollView.bounds.height
            let contentHeight = scrollView.contentSize.height
            let offsetY = max(0, min(y, contentHeight - height))
            
            scrollView.contentOffset.y = offsetY
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if !appeared {
            appeared = true
            self.tableView.reloadData()
            return
        }
        
        if #available(iOS 11.0, *) {
            
        } else {
            self.tableView.reloadData() // Bugfix iOS 10 и iOS 9
                                        // Без этого ячейки в первом сообщении становятся скукоженными
        }
    }
    
    final var unreadMessagesCount: Int = 0 {
        didSet {
            self.delegate.unreadMessagesCount(count: unreadMessagesCount)
        }
    }
    
    override func didReceiveMemoryWarning() {
        history = []
        historyIndex = nil
        scriptCache = nil
    }
    
    private var maxScrollY: CGFloat {
        return tableView.contentSize.height - tableView.bounds.height + tableView.contentInset.bottom
    }
    
    private var messagesTotal = 0
    private var shouldScrollBottom = false
    
    private var shouldUpdateTableView = false
    
    private var tableViewUpdates: Int = 0
    private var skippedUpdates: Int = 0
    private static let queueLimit = 100
    
    private var scrolledBottom: Bool {
        return self.maxScrollY - tableView.contentOffset.y < 30 || shouldScrollBottom || ignoreScrollViewContentInsetChanges
    }
    
    private func scrollBottom() {
            
        shouldScrollBottom = true
        let messagesTotal = self.messagesTotal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if messagesTotal != self.messagesTotal || self.messages == 0 {
                return
            }
            
            self.shouldScrollBottom = false
            
            self.ignoreScrollViewContentInsetChanges = true
            
            self.tableView.scrollToRow(at: IndexPath(row: self.messages - 1, section: 0), at: .bottom, animated: false)
        }
    }
    
    private var rowsToAddQueue: [IndexPath] = {
        var array = Array<IndexPath>()
        array.reserveCapacity(queueLimit) // Пусть будет, нам жалко 12 килобайт оперативки?
        return array
    }()
    
    var appeared: Bool = false
    
    private func addRow(row: IndexPath) {
        
        if !appeared && view.window == nil {
            return
        }
        
        rowsToAddQueue.append(row)
        
        appeared = true
        
        let oldCount = rowsToAddQueue.count
        
        DispatchQueue.main.async {
            let newCount = self.rowsToAddQueue.count
            if(newCount == 0) { // Значит, в ходе ожидания консоль очистили
                return
            }
            if(oldCount != newCount && newCount <= ConsoleViewController.queueLimit) {
                return
            }
            
            let wasScrolledToBottom = self.scrolledBottom
            self.tableView.insertRows(at: self.rowsToAddQueue, with: .none)
            if(wasScrolledToBottom) {
                self.scrollBottom()
            }
            self.rowsToAddQueue.removeAll(keepingCapacity: true)
        }
    }
    
    private func updateTableViewIfNecessary() {
        tableViewUpdates += 1
        
        // Здесь я решил добавить немного оптимизации, которая
        // срабатывает, если в консоль прилетает сразу много
        // сообщений. Консоль ждет один цикл, и обновляется
        // только если за это время не появилось новых сообщений.
        // Это позволяет обрабатывать их не по одному,
        // а все сразу. Но установлен лимит - 100 сообщений, чтобы
        // консоль сильно не зависала.
        
        let oldTableViewUpdates = tableViewUpdates
        DispatchQueue.main.async {
            if(oldTableViewUpdates != self.tableViewUpdates) {
                self.skippedUpdates += 1
                
                // Пропускаем только если не достигли лимита
                
                if(self.skippedUpdates <= ConsoleViewController.queueLimit) {
                    return
                }
            }
            self.skippedUpdates = 0
            
            if self.view.window != nil {
                self.updateTableViewAndScrollBottom()
                
                self.shouldUpdateTableView = false
            } else {
                self.shouldUpdateTableView = true
            }
        }
    }
    
    final func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        ignoreScrollViewContentInsetChanges = false
    }
    
    private var ignoreScrollViewContentInsetChanges = false
    
    final func addMessage(message: ConsoleMessage) {
        messages += 1
        
        messagesTotal += 1
        
        let indexpath = IndexPath(row: messages - 1, section: 0)
        
        UIView.setAnimationsEnabled(false) // Иначе глючит и не прокручивается вниз.
        
        messagesArray.append(message)
        
        //print("added \(message.body.string)")
        
        if(messages > maxMessages) {
            messages -= 1
            messagesArray.removeFirst()
            updateTableViewIfNecessary()
        } else {
            addRow(row: indexpath)
        }
        
        UIView.setAnimationsEnabled(true)
        
        // Скроллинг вниз до последнего элемента в списке. Оч сложная система
    }
    
    final func clearConsole()
    {
        self.unreadMessagesCount = 0
        self.messages = 0
        self.messagesTotal = 0
        self.messagesArray = []
        self.rowsToAddQueue.removeAll(keepingCapacity: true)
        tableView.reloadData()
        //updateTableViewIfNecessary() <-- Могло быть оптимизированее, но вылетает.
    }
    
    private func configureExecuteField() {
        
        let borderView = UIView()
        
        view.addSubview(containerView)
        containerView.addSubview(executeField)
        containerView.addSubview(executeButton)
        containerView.addSubview(borderView)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        executeField.translatesAutoresizingMaskIntoConstraints = false
        executeButton.translatesAutoresizingMaskIntoConstraints = false
        borderView.translatesAutoresizingMaskIntoConstraints = false
        
        //containerView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        bottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        containerView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
        containerView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
        bottomConstraint.isActive = true
        
        executeButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        executeButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        executeButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0).isActive = true
        executeButton.leftAnchor.constraint(equalTo: executeField.rightAnchor, constant: 0).isActive = true
        trailingFieldMargin = executeButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0)
        trailingFieldMargin.isActive = true
        
        executeField.heightAnchor.constraint(greaterThanOrEqualToConstant: 30).isActive = true
        executeField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 7).isActive = true
        executeField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -7).isActive = true
        leadingFieldMargin = executeField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 5)
        leadingFieldMargin.isActive = true
        
        containerView.topAnchor.constraint(equalTo: borderView.topAnchor).isActive = true
        containerView.leftAnchor.constraint(equalTo: borderView.leftAnchor).isActive = true
        containerView.rightAnchor.constraint(equalTo: borderView.rightAnchor).isActive = true
        borderView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        executeButton.setImage(#imageLiteral(resourceName: "run.png").withRenderingMode(.alwaysTemplate), for: .normal)
        executeButton.imageView?.contentMode = .scaleAspectFit
        executeField.layer.borderWidth = 1
        executeField.layer.cornerRadius = 5
        (executeField as UIScrollView).delegate = self
        
        borderView.backgroundColor = .gray
        
        executeFieldHeightConstraint = executeField.heightAnchor.constraint(equalToConstant: 35)
        executeFieldHeightConstraint.isActive = true
        executeField.bounces = false
        
        adjustTextViewHeight()
    }
    
    private func configureTableView() {
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tableView)
        
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        tableView.register(ConsoleTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorInset = UIEdgeInsets.zero
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.keyboardDismissMode = .interactive
    }
    
    override func viewDidLoad()
    {
        configureExecuteField()
        configureTableView()
        
        self.edgesForExtendedLayout = []
        
        executeButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        executeButton.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        executeField.delegate = self
        executeField.font = font
        
        setupTheme()
        
        setupThemeChangedNotificationHandling()
        setupRotationNotificationHandling()
        
        let height: CGFloat = 1
        let keyboardInputView = BABFrameObservingInputAccessoryView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width
            , height: height))
        
        weak var weakself: ConsoleViewController! = self;
        
        keyboardInputView.inputAcessoryViewFrameChangedBlock = {
            frame in
            
            guard weakself != nil else { return }
            
            let value = max(0, UIScreen.main.bounds.height - frame.minY - (UIScreen.main.bounds.height - weakself.view.globalFrame!.maxY))
            
            weakself.bottomConstraint.constant = -value
            
            weakself.adjustTableViewOffset()
            weakself.view.layoutIfNeeded()
        }
        
        executeField.inputAccessoryView = keyboardInputView
        updateKeyboardAppearance()
    }
    
    override func didMove(toParent parent: UIViewController?) {
        tabBarItem?.image = UIImage(named: "console")
    }
    
    private func setupTheme() {
        tableView.separatorColor = userPreferences.currentTheme.tableViewDelimiterColor
        tableView.backgroundColor = userPreferences.currentTheme.background
        
        containerView.backgroundColor = userPreferences.currentTheme.tabBarBackgroundColor
        executeButton.tintColor = userPreferences.currentTheme.tabBarSelectedItemColor
        executeField.backgroundColor = UIColor.clear
        executeField.layer.borderColor = userPreferences.currentTheme.secondaryTextColor.withAlphaComponent(0.5).cgColor
    }
    
    private var oldInverseState = userPreferences.currentTheme.isDark
    
    final func updateTheme() {
        
        
        if oldInverseState != userPreferences.currentTheme.isDark {
            oldInverseState = userPreferences.currentTheme.isDark
            // Я не нашел другого способа менять цвета в консоли, кроме как понимать,
            // с какими они ассоциированы, и менять на соответствующие в другой теме.
            // Костыльный костыль. Ужас. Но это - самое оптимизированное решение.
            // Можно было в теории хранить дампы всех консольных записей, но это лишние
            // строки, которые могут занимать довольно много места в памяти. А
            // NSAttribitedString и так жрёт как 4 Google Chrome вместе взятых.
            
            // Поправка - layer столько жрет. не строка.
            
            for message in messagesArray {
                var attributelist = [[NSAttributedString.Key : Any]]()
                var rangelist = [NSRange]()
                
                message.body.enumerateAttributes(in: NSRange(location: 0, length: message.body.length), options: []) { (attributes, range, stop) in
                    attributelist.append(attributes)
                    rangelist.append(range)
                }
                message.body = NSMutableAttributedString(string: message.body.string)
                
                for i in 0..<rangelist.count {
                    
                    var attribute = attributelist[i]
                    
                    if var color = attribute[.foregroundColor] as? UIColor {
                        
                        var found = false
                        for (i, schemecolor) in ConsoleViewController.inactiveColorScheme.enumerated()
                            where color == schemecolor {
                            color = ConsoleViewController.activeColorScheme[i]
                            found = true
                            break
                        }
                        
                        if(!found) {
                            color = userPreferences.currentTheme.cellTextColor
                        }
                    
                        attribute[.foregroundColor] = color
                }
                    
                    message.body.addAttributes(attribute, range: rangelist[i])
                }
            }
        }
        
        if let visibleRows = tableView.indexPathsForVisibleRows {
            tableView.reloadRows(at: visibleRows, with: .none)
        }
        
        setupTheme()
        updateKeyboardAppearance()
    }
    
    private func updateKeyboardAppearance() {
        executeField.keyboardAppearance = userPreferences.currentTheme.isDark ? .dark : .light
    }
    
    @objc func buttonAction(_ sender: UIButton) {
        execute()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        executeField.hidePlaceholder()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if executeField.text.isEmpty {
            executeField.showPlaceholder()
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            execute()
            return false
        }
        
        return true
    }
    
    private var executeFieldHeightConstraint: NSLayoutConstraint!
    
    func textViewDidChange(_ textView: UITextView) {
        self.adjustTextViewHeight()
    }
    
    private var maxFieldHeight: CGFloat = 150
    private var oldHeight: CGFloat = 0
    
    private func adjustTextViewHeight() {
        
        let fixedWidth = self.executeField.frame.size.width
        
        let newSize = self.executeField.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        
        if(self.maxFieldHeight < newSize.height) {
            self.executeFieldHeightConstraint?.constant = self.maxFieldHeight
            self.executeField.contentOffset.y = newSize.height - self.maxFieldHeight
        } else {
            self.executeFieldHeightConstraint?.constant = newSize.height
            self.executeField.contentOffset = .zero
        }
        
        adjustTableViewOffset()
    }
    
    func adjustTableViewOffset() {
        
        let newHeight = -bottomConstraint.constant + executeFieldHeightConstraint.constant
        
        if oldHeight != newHeight {
            
            var newOffset = tableView.contentOffset.y + newHeight - oldHeight
            
            newOffset = min(newOffset, tableView.contentOffset.y - tableView.bounds.height)
            newOffset = max(newOffset, 0)
            
            tableView.contentOffset.y += newHeight - oldHeight
            
            oldHeight = newHeight
        }
    }
    
    final func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages
    }
    
    final func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    final func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ConsoleTableViewCell
        
        let message = messagesArray[indexPath.row]
        
        if(userPreferences.currentTheme.isDark) {
            switch(message.type) {
                case 1:
                    cell.cellimage.image = #imageLiteral(resourceName: "warning")
                    cell.backgroundColor = #colorLiteral(red: 0.2528697961, green: 0.1811837355, blue: 0.03988216204, alpha: 1)
                case 2:
                    cell.cellimage.image = #imageLiteral(resourceName: "error")
                    cell.backgroundColor = #colorLiteral(red: 0.1885707487, green: 0.08288257902, blue: 0.06516177385, alpha: 1)
                case 3:
                    cell.cellimage.image = #imageLiteral(resourceName: "information")
                    cell.backgroundColor = #colorLiteral(red: 0.04023324034, green: 0.1145467235, blue: 0.1762393459, alpha: 1)
                case 4:
                    cell.cellimage.image = #imageLiteral(resourceName: "debug")
                    cell.backgroundColor = #colorLiteral(red: 0.0807960695, green: 0.1482756271, blue: 0.04116575061, alpha: 1)
                case 5:
                    cell.cellimage.image = #imageLiteral(resourceName: "consolearrow")
                    cell.cellimage.tintColor = .gray
                    cell.backgroundColor = userPreferences.currentTheme.cellColor1
                case 6:
                    cell.cellimage.image = #imageLiteral(resourceName: "consolearrowleft")
                    cell.cellimage.tintColor = .darkGray
                    cell.backgroundColor = userPreferences.currentTheme.cellColor2
                default:
                    cell.cellimage.image = nil
                    cell.backgroundColor = userPreferences.currentTheme.background
            }
        } else {
            switch(message.type) {
            case 1:
                cell.cellimage.image = #imageLiteral(resourceName: "warning")
                cell.backgroundColor = #colorLiteral(red: 1, green: 0.9375025014, blue: 0.7917142436, alpha: 1)
            case 2:
                cell.cellimage.image = #imageLiteral(resourceName: "error")
                cell.backgroundColor = #colorLiteral(red: 1, green: 0.8334024496, blue: 0.8194538663, alpha: 1)
            case 3:
                cell.cellimage.image = #imageLiteral(resourceName: "information")
                cell.backgroundColor = #colorLiteral(red: 0.8130888701, green: 0.9372396334, blue: 1, alpha: 1)
            case 4:
                cell.cellimage.image = #imageLiteral(resourceName: "debug")
                cell.backgroundColor = #colorLiteral(red: 0.8694924493, green: 1, blue: 0.8168637747, alpha: 1)
            case 5:
                cell.cellimage.image = #imageLiteral(resourceName: "consolearrow")
                cell.cellimage.tintColor = .gray
                cell.backgroundColor = userPreferences.currentTheme.cellColor1
            case 6:
                cell.cellimage.image = #imageLiteral(resourceName: "consolearrowleft");
                cell.cellimage.tintColor = .darkGray
                cell.backgroundColor = userPreferences.currentTheme.cellColor2
            default:
                cell.cellimage.image = nil;
                cell.backgroundColor = userPreferences.currentTheme.background;
            }
        }
        
        cell.content.attributedText = message.body
        cell.time.text = message.date
        
        return cell
    }
    
    private func execute() {
        
        historyIndex = nil
        scriptCache = nil
        
        var command = executeField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? ""
        
        if executeField.placeholderShown || command.isEmpty {
            if let last = history.last {
                applyHistoryItem(item:  last)
            }
            return
        }
        
        var isSame = false
        
        if messages != 0, let last = history.last {
            if last.text != executeField.text {
                history.append(ConsoleCacheItem(field: executeField))
            } else if let range = executeField.selectedTextRange {
                last.cursorPosition = range
                isSame = true
            }
        } else {
            history.append(ConsoleCacheItem(field: executeField))
        }
        
        if(!isSame) {
            addMessage(
                message: ConsoleMessage(
                    body: NSMutableAttributedString(
                        string: command,
                        attributes: [
                            .font: ConsoleViewController.font,
                            .foregroundColor: userPreferences.currentTheme.cellTextColor
                            ]
                    ),
                type: 6)
            )
        }
        command = EditorViewController.getEscapedJavaScriptString(command)
        
        delegate.console(executed: command)
        
        if userPreferences.consoleShouldVanishCode {
            executeField.text = ""
            adjustTextViewHeight()
        }
    }
    
    final func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    private func updateTableViewAndScrollBottom() {
        let wasScrolledBottom = self.scrolledBottom
        self.tableView.reloadData()
        
        if(wasScrolledBottom) {
            self.scrollBottom()
        }
    }
    
    final func focus() {
         tableView.becomeFirstResponder()
    }
    
    final func navigatedToConsole() {
       focus()
        unreadMessagesCount = 0
        if(!isLoaded) {
            delegate?.reloadConsole()
            isLoaded = true
        }
        
        
        if(shouldUpdateTableView) {
            
            tableView.reloadData()
            
            shouldUpdateTableView = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.estimatedRowHeight = 56
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    final func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }
    
    final func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    final func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        if action == #selector(copy(_:)) {
            let cell = tableView.cellForRow(at: indexPath) as! ConsoleTableViewCell
            UIPasteboard.general.string = cell.content.text
        }
    }
    
    final func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let message = messagesArray[indexPath.row]
        if(message.type == 6) {
            executeField.hidePlaceholder()
            executeField.text = message.body.string
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func updateKeyboardSize(sender: NSNotification) {
        let userInfo = sender.userInfo!
        
        var offset: CGSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey]! as AnyObject).cgRectValue.size
        
        // Проверка на то, откреплена ли клавиатура от низа экрана
        // такое может быть на iPadOS
        
        if offset.width < UIScreen.main.bounds.width {
            offset.height = 0
        }
        let time = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        
        let slidersContainerBounds = containerView.convert(containerView.bounds, to: UIApplication.shared.delegate?.window!?.rootViewController?.view)
        
        var y = UIScreen.main.bounds.height - slidersContainerBounds.maxY
        
        y = -offset.height + y
        
        self.bottomConstraint.constant += y
        UIView.animate(withDuration: time, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    final func deviceRotated() {
        if UIDevice.current.hasAnEyebrow {
            transitionManager()
        }
    }
    
    final func transitionManager(animation: Bool = true)
    {
        if #available(iOS 11.0, *), UIDevice.current.hasAnEyebrow
        {
            let orientation = UIApplication.shared.statusBarOrientation
            if orientation == .landscapeRight
            {
                let instance = PrimarySplitViewController.instance(for: view)!
                if instance.isCollapsed ||
                   instance.displayMode == .primaryHidden {
                    self.leadingFieldMargin.constant = 39
                } else {
                    self.leadingFieldMargin.constant = 5
                }
                
                self.trailingFieldMargin.constant = 1
            } else if orientation == .landscapeLeft {
                self.leadingFieldMargin.constant = 5
                self.trailingFieldMargin.constant = -35
            } else {
                self.leadingFieldMargin.constant = 5
                self.trailingFieldMargin.constant = 1
            }
        } else {
            self.leadingFieldMargin.constant = 5
            self.trailingFieldMargin.constant = 1
        }
        
        if animation {
            UIView.animate(withDuration: 0.3, animations: self.view.layoutIfNeeded)
        } else {
            updateViewConstraints()
        }
    }
    
    private var oldFrame: CGRect?
    
    override func viewDidLayoutSubviews() {
        
        if(self.view.frame == oldFrame) {
            return
        }
        
        oldFrame = self.view.frame
        
        transitionManager(animation: false)
        
        adjustTextViewHeight()
    }
    
    deinit {
        clearNotificationHandling()
    }
}

class ConsoleTableViewCell: UITableViewCell {
    var time = UILabel()
    var cellimage = UIImageView()
    var content = UILabel()
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(cellimage)
        contentView.addSubview(time)
        contentView.addSubview(content)
        
        cellimage.translatesAutoresizingMaskIntoConstraints = false
        time.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        
        let marginGuide = contentView.layoutMarginsGuide
        
        cellimage.widthAnchor.constraint(equalToConstant: 14).isActive = true
        cellimage.heightAnchor.constraint(equalToConstant: 14).isActive = true
        cellimage.topAnchor.constraint(equalTo: marginGuide.topAnchor, constant: 8).isActive = true
        cellimage.leftAnchor.constraint(equalTo: marginGuide.leftAnchor).isActive = true
        
        content.leftAnchor.constraint(equalTo: cellimage.rightAnchor, constant: 8).isActive = true
        content.topAnchor.constraint(equalTo: marginGuide.topAnchor, constant: 8).isActive = true
        content.rightAnchor.constraint(equalTo: time.leftAnchor, constant: -8).isActive = true
        content.bottomAnchor.constraint(equalTo: marginGuide.bottomAnchor, constant: -8).isActive = true
        
        content.numberOfLines = 0
        content.heightAnchor.constraint(greaterThanOrEqualToConstant: 14).isActive = true
        
        time.rightAnchor.constraint(equalTo: marginGuide.rightAnchor).isActive = true
        time.topAnchor.constraint(equalTo: marginGuide.topAnchor).isActive = true
        
        time.textColor = .gray
        time.font = UIFont.systemFont(ofSize: 9.0)
    
        content.backgroundColor = .clear

        time.setContentCompressionResistancePriority(.required, for: .horizontal)
        content.setContentHuggingPriority(.init(0), for: .horizontal)
        content.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
}