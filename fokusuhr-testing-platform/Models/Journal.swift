//
//  Journal.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 24.09.2025.
//

import Foundation

typealias Journal = PublicSchema.JournalsSelect

extension PublicSchema.JournalsSelect: Identifiable {
    var createdAt: Date {
        // For now return current date - we could parse created_at if it exists in the schema
        return Date()
    }
}