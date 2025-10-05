import SwiftUI
import PhotosUI

struct ChecklistDetailView: View {
    @Bindable var checklist: ChecklistModel
    @ObservedObject var checklistManager: ChecklistManager
    @ObservedObject var galleryStorage: GalleryStorage
    @State private var showingAddItem = false
    
    var body: some View {
        List {
            Section {
                TextField("Checklist Name", text: $checklist.name)
                    .onSubmit {
                        checklistManager.updateChecklist(checklist)
                    }
            }
            
            Section("Items") {
                ForEach(checklist.items) { item in
                    ChecklistItemEditRow(item: item, checklist: checklist, checklistManager: checklistManager, galleryStorage: galleryStorage)
                }
                .onDelete(perform: deleteItems)
                
                Button("Add Item") {
                    showingAddItem = true
                }
            }
        }
        .navigationTitle(checklist.name)    
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddItem) {
            ChecklistAddItemView(checklist: checklist, checklistManager: checklistManager, galleryStorage: galleryStorage)
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            let item = checklist.items[index]
            checklistManager.deleteItem(item)
        }
    }
}