import Testing

struct watch_testing {

    @Test func simpleTest() async throws {
        #expect(1 + 1 == 2)
    }

}
