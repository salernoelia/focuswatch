//
//  Supervisors.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 07.09.2025.
//

import Foundation

typealias Supervisor = PublicSchema.SupervisorsSelect

extension PublicSchema.SupervisorsSelect: Identifiable {
    var id: UUID { uid }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
