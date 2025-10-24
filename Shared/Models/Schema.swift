import Foundation
import Supabase

internal enum GraphqlPublicSchema {
}
internal enum PublicSchema {
  internal enum Genders: String, Codable, Hashable, Sendable {
    case male = "male"
    case female = "female"
    case hidden = "hidden"
  }
  internal struct AppLogsSelect: Codable, Hashable, Sendable, Identifiable {
    internal let appId: Int64?
    internal let appName: String?
    internal let createdAt: String
    internal let data: AnyJSON?
    internal let id: Int64
    internal enum CodingKeys: String, CodingKey {
      case appId = "app_id"
      case appName = "app_name"
      case createdAt = "created_at"
      case data = "data"
      case id = "id"
    }
  }
  internal struct AppLogsInsert: Codable, Hashable, Sendable, Identifiable {
    internal let appId: Int64?
    internal let appName: String?
    internal let createdAt: String?
    internal let data: AnyJSON?
    internal let id: Int64?
    internal enum CodingKeys: String, CodingKey {
      case appId = "app_id"
      case appName = "app_name"
      case createdAt = "created_at"
      case data = "data"
      case id = "id"
    }
  }
  internal struct AppLogsUpdate: Codable, Hashable, Sendable, Identifiable {
    internal let appId: Int64?
    internal let appName: String?
    internal let createdAt: String?
    internal let data: AnyJSON?
    internal let id: Int64?
    internal enum CodingKeys: String, CodingKey {
      case appId = "app_id"
      case appName = "app_name"
      case createdAt = "created_at"
      case data = "data"
      case id = "id"
    }
  }
  internal struct AppsSelect: Codable, Hashable, Sendable, Identifiable {
    internal let createdAt: String
    internal let data: AnyJSON?
    internal let id: Int64
    internal let name: String
    internal enum CodingKeys: String, CodingKey {
      case createdAt = "created_at"
      case data = "data"
      case id = "id"
      case name = "name"
    }
  }
  internal struct AppsInsert: Codable, Hashable, Sendable, Identifiable {
    internal let createdAt: String?
    internal let data: AnyJSON?
    internal let id: Int64?
    internal let name: String
    internal enum CodingKeys: String, CodingKey {
      case createdAt = "created_at"
      case data = "data"
      case id = "id"
      case name = "name"
    }
  }
  internal struct AppsUpdate: Codable, Hashable, Sendable, Identifiable {
    internal let createdAt: String?
    internal let data: AnyJSON?
    internal let id: Int64?
    internal let name: String?
    internal enum CodingKeys: String, CodingKey {
      case createdAt = "created_at"
      case data = "data"
      case id = "id"
      case name = "name"
    }
  }
  internal struct FeedbackSelect: Codable, Hashable, Sendable {
    internal let appName: String?
    internal let createdAt: String
    internal let description: String?
    internal let id: Int32
    internal let implemented: Bool
    internal enum CodingKeys: String, CodingKey {
      case appName = "app_name"
      case createdAt = "created_at"
      case description = "description"
      case id = "id"
      case implemented = "implemented"
    }
  }
  internal struct FeedbackInsert: Codable, Hashable, Sendable {
    internal let appName: String?
    internal let createdAt: String?
    internal let description: String?
    internal let id: Int32?
    internal let implemented: Bool?
    internal enum CodingKeys: String, CodingKey {
      case appName = "app_name"
      case createdAt = "created_at"
      case description = "description"
      case id = "id"
      case implemented = "implemented"
    }
  }
  internal struct FeedbackUpdate: Codable, Hashable, Sendable {
    internal let appName: String?
    internal let createdAt: String?
    internal let description: String?
    internal let id: Int32?
    internal let implemented: Bool?
    internal enum CodingKeys: String, CodingKey {
      case appName = "app_name"
      case createdAt = "created_at"
      case description = "description"
      case id = "id"
      case implemented = "implemented"
    }
  }
  internal struct JournalsSelect: Codable, Hashable, Sendable {
    internal let appId: Int64?
    internal let appName: String?
    internal let createdAt: String?
    internal let description: String?
    internal let id: Int32
    internal let supervisorUid: UUID?
    internal let testUserId: Int32?
    internal enum CodingKeys: String, CodingKey {
      case appId = "app_id"
      case appName = "app_name"
      case createdAt = "created_at"
      case description = "description"
      case id = "id"
      case supervisorUid = "supervisor_uid"
      case testUserId = "test_user_id"
    }
  }
  internal struct JournalsInsert: Codable, Hashable, Sendable {
    internal let appId: Int64?
    internal let appName: String?
    internal let createdAt: String?
    internal let description: String?
    internal let id: Int32?
    internal let supervisorUid: UUID?
    internal let testUserId: Int32?
    internal enum CodingKeys: String, CodingKey {
      case appId = "app_id"
      case appName = "app_name"
      case createdAt = "created_at"
      case description = "description"
      case id = "id"
      case supervisorUid = "supervisor_uid"
      case testUserId = "test_user_id"
    }
  }
  internal struct JournalsUpdate: Codable, Hashable, Sendable {
    internal let appId: Int64?
    internal let appName: String?
    internal let createdAt: String?
    internal let description: String?
    internal let id: Int32?
    internal let supervisorUid: UUID?
    internal let testUserId: Int32?
    internal enum CodingKeys: String, CodingKey {
      case appId = "app_id"
      case appName = "app_name"
      case createdAt = "created_at"
      case description = "description"
      case id = "id"
      case supervisorUid = "supervisor_uid"
      case testUserId = "test_user_id"
    }
  }
  internal struct SupervisorsSelect: Codable, Hashable, Sendable {
    internal let email: String?
    internal let firstName: String
    internal let lastName: String
    internal let status: String?
    internal let uid: UUID
    internal enum CodingKeys: String, CodingKey {
      case email = "email"
      case firstName = "first_name"
      case lastName = "last_name"
      case status = "status"
      case uid = "uid"
    }
  }
  internal struct SupervisorsInsert: Codable, Hashable, Sendable {
    internal let email: String?
    internal let firstName: String
    internal let lastName: String
    internal let status: String?
    internal let uid: UUID
    internal enum CodingKeys: String, CodingKey {
      case email = "email"
      case firstName = "first_name"
      case lastName = "last_name"
      case status = "status"
      case uid = "uid"
    }
  }
  internal struct SupervisorsUpdate: Codable, Hashable, Sendable {
    internal let email: String?
    internal let firstName: String?
    internal let lastName: String?
    internal let status: String?
    internal let uid: UUID?
    internal enum CodingKeys: String, CodingKey {
      case email = "email"
      case firstName = "first_name"
      case lastName = "last_name"
      case status = "status"
      case uid = "uid"
    }
  }
  internal struct TestUsersSelect: Codable, Hashable, Sendable {
    internal let age: Int32
    internal let firstName: String
    internal let gender: Genders
    internal let id: Int32
    internal let lastName: String
    internal let supervisorUid: UUID?
    internal enum CodingKeys: String, CodingKey {
      case age = "age"
      case firstName = "first_name"
      case gender = "gender"
      case id = "id"
      case lastName = "last_name"
      case supervisorUid = "supervisor_uid"
    }
  }
  internal struct TestUsersInsert: Codable, Hashable, Sendable {
    internal let age: Int32
    internal let firstName: String
    internal let gender: Genders?
    internal let id: Int32?
    internal let lastName: String
    internal let supervisorUid: UUID?
    internal enum CodingKeys: String, CodingKey {
      case age = "age"
      case firstName = "first_name"
      case gender = "gender"
      case id = "id"
      case lastName = "last_name"
      case supervisorUid = "supervisor_uid"
    }
  }
  internal struct TestUsersUpdate: Codable, Hashable, Sendable {
    internal let age: Int32?
    internal let firstName: String?
    internal let gender: Genders?
    internal let id: Int32?
    internal let lastName: String?
    internal let supervisorUid: UUID?
    internal enum CodingKeys: String, CodingKey {
      case age = "age"
      case firstName = "first_name"
      case gender = "gender"
      case id = "id"
      case lastName = "last_name"
      case supervisorUid = "supervisor_uid"
    }
  }
}
