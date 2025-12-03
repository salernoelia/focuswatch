import Foundation
import Supabase

internal enum GraphqlPublicSchema {
}
internal enum PublicSchema {
  internal enum AppPermission: String, Codable, Hashable, Sendable {
    case testResultsSelect = "test_results.select"
    case logsSelect = "logs.select"
    case logsInsert = "logs.insert"
    case userRolesSelect = "user_roles.select"
    case testProcessesSelect = "test_processes.select"
    case testProcessesInsert = "test_processes.insert"
    case testProcessesUpdate = "test_processes.update"
    case testProcessesDelete = "test_processes.delete"
  }
  internal enum AppRole: String, Codable, Hashable, Sendable {
    case admin = "admin"
    case user = "user"
  }
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
    internal let watchId: UUID
    internal enum CodingKeys: String, CodingKey {
      case appId = "app_id"
      case appName = "app_name"
      case createdAt = "created_at"
      case data = "data"
      case id = "id"
      case watchId = "watch_id"
    }
  }
  internal struct AppLogsInsert: Codable, Hashable, Sendable, Identifiable {
    internal let appId: Int64?
    internal let appName: String?
    internal let createdAt: String?
    internal let data: AnyJSON?
    internal let id: Int64?
    internal let watchId: UUID
    internal enum CodingKeys: String, CodingKey {
      case appId = "app_id"
      case appName = "app_name"
      case createdAt = "created_at"
      case data = "data"
      case id = "id"
      case watchId = "watch_id"
    }
  }
  internal struct AppLogsUpdate: Codable, Hashable, Sendable, Identifiable {
    internal let appId: Int64?
    internal let appName: String?
    internal let createdAt: String?
    internal let data: AnyJSON?
    internal let id: Int64?
    internal let watchId: UUID?
    internal enum CodingKeys: String, CodingKey {
      case appId = "app_id"
      case appName = "app_name"
      case createdAt = "created_at"
      case data = "data"
      case id = "id"
      case watchId = "watch_id"
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
  internal struct RolePermissionsSelect: Codable, Hashable, Sendable, Identifiable {
    internal let id: Int64
    internal let permission: AppPermission
    internal let role: AppRole
    internal enum CodingKeys: String, CodingKey {
      case id = "id"
      case permission = "permission"
      case role = "role"
    }
  }
  internal struct RolePermissionsInsert: Codable, Hashable, Sendable, Identifiable {
    internal let id: Int64?
    internal let permission: AppPermission
    internal let role: AppRole
    internal enum CodingKeys: String, CodingKey {
      case id = "id"
      case permission = "permission"
      case role = "role"
    }
  }
  internal struct RolePermissionsUpdate: Codable, Hashable, Sendable, Identifiable {
    internal let id: Int64?
    internal let permission: AppPermission?
    internal let role: AppRole?
    internal enum CodingKeys: String, CodingKey {
      case id = "id"
      case permission = "permission"
      case role = "role"
    }
  }
  internal struct TestProcessesSelect: Codable, Hashable, Sendable {
    internal let createdAt: String
    internal let dailyLogs: AnyJSON?
    internal let endDate: String?
    internal let exitInterview: AnyJSON?
    internal let id: Int64
    internal let initialQuestions: AnyJSON?
    internal let lockedForms: AnyJSON?
    internal let midTermQuestions: AnyJSON?
    internal let startDate: String
    internal let status: String
    internal let testUserId: Int32
    internal let testerId: UUID
    internal let updatedAt: String
    internal enum CodingKeys: String, CodingKey {
      case createdAt = "created_at"
      case dailyLogs = "daily_logs"
      case endDate = "end_date"
      case exitInterview = "exit_interview"
      case id = "id"
      case initialQuestions = "initial_questions"
      case lockedForms = "locked_forms"
      case midTermQuestions = "mid_term_questions"
      case startDate = "start_date"
      case status = "status"
      case testUserId = "test_user_id"
      case testerId = "tester_id"
      case updatedAt = "updated_at"
    }
  }
  internal struct TestProcessesInsert: Codable, Hashable, Sendable {
    internal let createdAt: String?
    internal let dailyLogs: AnyJSON?
    internal let endDate: String?
    internal let exitInterview: AnyJSON?
    internal let id: Int64?
    internal let initialQuestions: AnyJSON?
    internal let lockedForms: AnyJSON?
    internal let midTermQuestions: AnyJSON?
    internal let startDate: String
    internal let status: String?
    internal let testUserId: Int32
    internal let testerId: UUID
    internal let updatedAt: String?
    internal enum CodingKeys: String, CodingKey {
      case createdAt = "created_at"
      case dailyLogs = "daily_logs"
      case endDate = "end_date"
      case exitInterview = "exit_interview"
      case id = "id"
      case initialQuestions = "initial_questions"
      case lockedForms = "locked_forms"
      case midTermQuestions = "mid_term_questions"
      case startDate = "start_date"
      case status = "status"
      case testUserId = "test_user_id"
      case testerId = "tester_id"
      case updatedAt = "updated_at"
    }
  }
  internal struct TestProcessesUpdate: Codable, Hashable, Sendable {
    internal let createdAt: String?
    internal let dailyLogs: AnyJSON?
    internal let endDate: String?
    internal let exitInterview: AnyJSON?
    internal let id: Int64?
    internal let initialQuestions: AnyJSON?
    internal let lockedForms: AnyJSON?
    internal let midTermQuestions: AnyJSON?
    internal let startDate: String?
    internal let status: String?
    internal let testUserId: Int32?
    internal let testerId: UUID?
    internal let updatedAt: String?
    internal enum CodingKeys: String, CodingKey {
      case createdAt = "created_at"
      case dailyLogs = "daily_logs"
      case endDate = "end_date"
      case exitInterview = "exit_interview"
      case id = "id"
      case initialQuestions = "initial_questions"
      case lockedForms = "locked_forms"
      case midTermQuestions = "mid_term_questions"
      case startDate = "start_date"
      case status = "status"
      case testUserId = "test_user_id"
      case testerId = "tester_id"
      case updatedAt = "updated_at"
    }
  }
  internal struct TestUsersSelect: Codable, Hashable, Sendable {
    internal let age: Int32
    internal let firstName: String
    internal let gender: Genders
    internal let id: Int32
    internal let lastName: String
    internal let testSupervisorUserId: UUID
    internal enum CodingKeys: String, CodingKey {
      case age = "age"
      case firstName = "first_name"
      case gender = "gender"
      case id = "id"
      case lastName = "last_name"
      case testSupervisorUserId = "test_supervisor_user_id"
    }
  }
  internal struct TestUsersInsert: Codable, Hashable, Sendable {
    internal let age: Int32
    internal let firstName: String
    internal let gender: Genders?
    internal let id: Int32?
    internal let lastName: String
    internal let testSupervisorUserId: UUID
    internal enum CodingKeys: String, CodingKey {
      case age = "age"
      case firstName = "first_name"
      case gender = "gender"
      case id = "id"
      case lastName = "last_name"
      case testSupervisorUserId = "test_supervisor_user_id"
    }
  }
  internal struct TestUsersUpdate: Codable, Hashable, Sendable {
    internal let age: Int32?
    internal let firstName: String?
    internal let gender: Genders?
    internal let id: Int32?
    internal let lastName: String?
    internal let testSupervisorUserId: UUID?
    internal enum CodingKeys: String, CodingKey {
      case age = "age"
      case firstName = "first_name"
      case gender = "gender"
      case id = "id"
      case lastName = "last_name"
      case testSupervisorUserId = "test_supervisor_user_id"
    }
  }
  internal struct UserProfilesSelect: Codable, Hashable, Sendable {
    internal let betaAgreementAccepted: Bool
    internal let createdAt: String
    internal let email: String?
    internal let firstName: String
    internal let howTheyFoundOut: String?
    internal let lastName: String
    internal let occupationAffiliation: String?
    internal let status: String?
    internal let updatedAt: String
    internal let userId: UUID
    internal enum CodingKeys: String, CodingKey {
      case betaAgreementAccepted = "beta_agreement_accepted"
      case createdAt = "created_at"
      case email = "email"
      case firstName = "first_name"
      case howTheyFoundOut = "how_they_found_out"
      case lastName = "last_name"
      case occupationAffiliation = "occupation_affiliation"
      case status = "status"
      case updatedAt = "updated_at"
      case userId = "user_id"
    }
  }
  internal struct UserProfilesInsert: Codable, Hashable, Sendable {
    internal let betaAgreementAccepted: Bool?
    internal let createdAt: String?
    internal let email: String?
    internal let firstName: String
    internal let howTheyFoundOut: String?
    internal let lastName: String
    internal let occupationAffiliation: String?
    internal let status: String?
    internal let updatedAt: String?
    internal let userId: UUID
    internal enum CodingKeys: String, CodingKey {
      case betaAgreementAccepted = "beta_agreement_accepted"
      case createdAt = "created_at"
      case email = "email"
      case firstName = "first_name"
      case howTheyFoundOut = "how_they_found_out"
      case lastName = "last_name"
      case occupationAffiliation = "occupation_affiliation"
      case status = "status"
      case updatedAt = "updated_at"
      case userId = "user_id"
    }
  }
  internal struct UserProfilesUpdate: Codable, Hashable, Sendable {
    internal let betaAgreementAccepted: Bool?
    internal let createdAt: String?
    internal let email: String?
    internal let firstName: String?
    internal let howTheyFoundOut: String?
    internal let lastName: String?
    internal let occupationAffiliation: String?
    internal let status: String?
    internal let updatedAt: String?
    internal let userId: UUID?
    internal enum CodingKeys: String, CodingKey {
      case betaAgreementAccepted = "beta_agreement_accepted"
      case createdAt = "created_at"
      case email = "email"
      case firstName = "first_name"
      case howTheyFoundOut = "how_they_found_out"
      case lastName = "last_name"
      case occupationAffiliation = "occupation_affiliation"
      case status = "status"
      case updatedAt = "updated_at"
      case userId = "user_id"
    }
  }
  internal struct UserRolesSelect: Codable, Hashable, Sendable, Identifiable {
    internal let id: Int64
    internal let role: AppRole
    internal let userId: UUID
    internal enum CodingKeys: String, CodingKey {
      case id = "id"
      case role = "role"
      case userId = "user_id"
    }
  }
  internal struct UserRolesInsert: Codable, Hashable, Sendable, Identifiable {
    internal let id: Int64?
    internal let role: AppRole
    internal let userId: UUID
    internal enum CodingKeys: String, CodingKey {
      case id = "id"
      case role = "role"
      case userId = "user_id"
    }
  }
  internal struct UserRolesUpdate: Codable, Hashable, Sendable, Identifiable {
    internal let id: Int64?
    internal let role: AppRole?
    internal let userId: UUID?
    internal enum CodingKeys: String, CodingKey {
      case id = "id"
      case role = "role"
      case userId = "user_id"
    }
  }
  internal struct WatchesSelect: Codable, Hashable, Sendable, Identifiable {
    internal let createdAt: String
    internal let id: Int64
    internal let userId: UUID
    internal enum CodingKeys: String, CodingKey {
      case createdAt = "created_at"
      case id = "id"
      case userId = "user_id"
    }
  }
  internal struct WatchesInsert: Codable, Hashable, Sendable, Identifiable {
    internal let createdAt: String?
    internal let id: Int64?
    internal let userId: UUID
    internal enum CodingKeys: String, CodingKey {
      case createdAt = "created_at"
      case id = "id"
      case userId = "user_id"
    }
  }
  internal struct WatchesUpdate: Codable, Hashable, Sendable, Identifiable {
    internal let createdAt: String?
    internal let id: Int64?
    internal let userId: UUID?
    internal enum CodingKeys: String, CodingKey {
      case createdAt = "created_at"
      case id = "id"
      case userId = "user_id"
    }
  }
}
