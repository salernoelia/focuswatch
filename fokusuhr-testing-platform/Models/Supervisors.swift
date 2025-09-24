//
//  Supervisors.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 07.09.2025.
//

import Foundation


struct Supervisor: Codable, Identifiable {
    let uid: String
    let first_name: String
    let last_name: String
    let email: String?
    let status: String

    var id: String { uid }

    var fullName: String {
        "\(first_name) \(last_name)"
    }
}
