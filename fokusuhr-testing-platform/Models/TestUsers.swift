//
//  TestUsers.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 07.09.2025.
//

import Foundation

typealias TestUser = PublicSchema.TestUsersSelect

extension PublicSchema.TestUsersSelect: Identifiable {
    var id: Int32 { self.id }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var genderString: String? {
        switch gender {
        case .male: return "male"
        case .female: return "female" 
        case .hidden: return "hidden"
        }
    }
}
