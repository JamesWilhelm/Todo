import SwiftUI

struct TodoItem: Identifiable, Codable {
    var id = UUID()
    var text: String
    var isCompleted: Bool = false
}

class TodoListViewModel: ObservableObject {
    @Published var todoItems: [TodoItem] {
        didSet {
            saveTodoItems()
        }
    }
    var newItemText: String = "" {
        didSet {
            saveNewItemText()
        }
    }
    @Published var showCompleted: Bool {
        didSet {
            saveShowCompleted()
        }
    }
    
    init() {
        self.todoItems = UserDefaults.standard.array(forKey: "todoItems") as? [TodoItem] ?? []
        self.newItemText = UserDefaults.standard.string(forKey: "newItemText") ?? ""
        self.showCompleted = UserDefaults.standard.bool(forKey: "showCompleted")
        
        // Add observer to handle applicationWillTerminate
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    func addItem() {
        guard !newItemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return // Don't add empty strings
        }
        let newItem = TodoItem(text: newItemText)
        todoItems.append(newItem)
        newItemText = ""
    }
    
    func deleteItem(at indexSet: IndexSet) {
        todoItems.remove(atOffsets: indexSet)
    }
    
    func toggleCompleted(for item: TodoItem) {
        if let index = todoItems.firstIndex(where: { $0.id == item.id }) {
            todoItems[index].isCompleted.toggle()
        }
    }
    
    private func saveTodoItems() {
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(todoItems) {
            UserDefaults.standard.set(encodedData, forKey: "todoItems")
        }
    }
    
    private func saveNewItemText() {
        UserDefaults.standard.set(newItemText, forKey: "newItemText")
    }
    
    private func saveShowCompleted() {
        UserDefaults.standard.set(showCompleted, forKey: "showCompleted")
    }
    
    @objc func applicationWillTerminate() {
        // Save data to UserDefaults when app is quitting
        saveTodoItems()
        saveNewItemText()
        saveShowCompleted()
    }
}

struct ContentView: View {
    @StateObject var viewModel = TodoListViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("New item", text: $viewModel.newItemText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: viewModel.addItem) {
                        Text("Add")
                    }
                    .padding(.leading, 10)
                }
                .padding()
                
                Toggle(isOn: $viewModel.showCompleted) {
                    Text("Show completed items")
                }
                .padding(.horizontal)
                
                List {
                    ForEach(viewModel.todoItems) { item in
                        if viewModel.showCompleted || !item.isCompleted {
                            HStack {
                                Button(action: {
                                    viewModel.toggleCompleted(for: item)
                                }) {
                                    Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                                }
                                Text(item.text)
                            }
                        }
                    }
                    .onDelete(perform: viewModel.deleteItem)
                }
            }
            .navigationBarTitle("Todo List")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

