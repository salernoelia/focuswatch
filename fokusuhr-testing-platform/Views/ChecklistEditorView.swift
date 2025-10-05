import SwiftUI
import PhotosUI

struct ChecklistEditorView: View {
    @ObservedObject var checklistManager: ChecklistManager
    @EnvironmentObject private var galleryStorage: GalleryStorage
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(checklistManager.checklists) { checklist in
                    NavigationLink(destination: ChecklistDetailView(checklist: checklist, checklistManager: checklistManager, galleryStorage: galleryStorage)) {
                        Text(checklist.name)
                    }   
                }
                .onDelete(perform: deleteChecklists)
                
                Button("Add Checklist") {
                    checklistManager.addChecklist(name: "New Checklist")
                }
            }
            .navigationTitle("Checklists")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func deleteChecklists(offsets: IndexSet) {
        for index in offsets {
            checklistManager.deleteChecklist(checklistManager.checklists[index])
        }
    }
}







