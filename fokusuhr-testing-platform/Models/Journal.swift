//
//  Journal.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 24.09.2025.
//

import Foundation

struct Journal: Identifiable, Codable {
    let id: Int
    let description: String?
    let test_user_id: Int?
    let supervisor_uid: String?
    let app_id: Int?
}