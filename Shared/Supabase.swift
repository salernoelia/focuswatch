//
//  Supabase.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 07.09.2025.
//

import Foundation
import Supabase

enum SupabaseConfig {
    static let url: URL = {
        guard let supabaseURLString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let url = URL(string: supabaseURLString) else {
            fatalError("Missing or invalid SUPABASE_URL in Info.plist")
        }
        return url
    }()
    
    static let anonKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
            fatalError("Missing SUPABASE_ANON_KEY in Info.plist")
        }
        return key
    }()
}

let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.anonKey
)
