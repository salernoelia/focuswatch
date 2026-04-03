import Combine
import Foundation

final class ChecklistDataStore: ObservableObject {
    static let shared = ChecklistDataStore()

    @Published private(set) var checklistData: ChecklistData = .default

    private let userDefaults: UserDefaults
    private let persistenceQueue = DispatchQueue(label: "com.fokusuhr.checklist.persistence", qos: .utility)
    private let debounceInterval: TimeInterval
    private var cancellables = Set<AnyCancellable>()

    init(userDefaults: UserDefaults = .standard, debounceInterval: TimeInterval = 0.5) {
        self.userDefaults = userDefaults
        self.debounceInterval = debounceInterval
        loadChecklistData()
        setupPersistence()
    }

    func updateChecklistData(_ data: ChecklistData) {
        checklistData = data
    }

    private func setupPersistence() {
        $checklistData
            .dropFirst()
            .debounce(for: .seconds(debounceInterval), scheduler: DispatchQueue.main)
            .sink { [weak self] data in
                self?.saveChecklistData(data)
            }
            .store(in: &cancellables)
    }

    private func saveChecklistData(_ data: ChecklistData) {
        persistenceQueue.async { [userDefaults] in
            do {
                let encodedData = try JSONEncoder().encode(data)
                userDefaults.set(encodedData, forKey: AppConstants.StorageKeys.checklistData)
            } catch {
                #if DEBUG
                    ErrorLogger.log(AppError.encodingFailed(type: "checklist data", underlying: error))
                #endif
            }
        }
    }

    private func loadChecklistData() {
        guard let data = userDefaults.data(forKey: AppConstants.StorageKeys.checklistData) else {
            checklistData = .default
            saveChecklistData(checklistData)
            return
        }

        do {
            checklistData = try JSONDecoder().decode(ChecklistData.self, from: data)
        } catch {
            #if DEBUG
                ErrorLogger.log(AppError.decodingFailed(type: "checklist data", underlying: error))
            #endif
            checklistData = .default
            saveChecklistData(checklistData)
        }
    }
}
