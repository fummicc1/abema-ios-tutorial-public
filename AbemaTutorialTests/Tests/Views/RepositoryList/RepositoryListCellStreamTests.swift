import XCTest
import RxSwift
import RxTest

@testable import AbemaTutorial

final class RepositoryListCellStreamTests: XCTestCase {
    var dependency: Dependency!

    override func setUp() {
        super.setUp()
        dependency = Dependency()
    }

    func testTitleText() {
        let testTarget = dependency.testTarget

        let owner = User(id: 123, login: "owner")
        let repository = Repository(id: 123, name: "name", description: "description", owner: owner)

        let titleText = WatchStack(testTarget.output.titleText)

        testTarget.input.accept(repository, for: \.repository)

        XCTAssertEqual(titleText.value, "owner / name")
    }
    
    func testDescriptionText() {
        // Testするクラスを取得
        let testTarget = dependency.testTarget
        
        // Inputに流すデータを作成
        let repository = Repository.init(id: 1, name: "test_name", description: "test_description", owner: User(id: 123, login: "owner"))
        
        // outputをWatchStackに入れてテスタブルにする
        let descriptionText = WatchStack(testTarget.output.descriptionText)
        
        // 流す前のデータを確認（いらないかも）
        XCTAssertEqual(descriptionText.value, "")
        
        // Inputを流して、データの状態を変更する
        testTarget.input.accept(repository, for: \.repository)
        
        // 結果をチェックする
        XCTAssertEqual(descriptionText.value, "test_description")
    }
}

extension RepositoryListCellStreamTests {
    struct Dependency {
        let testTarget: RepositoryListCellStream

        init() {
            testTarget = RepositoryListCellStream()
        }
    }
}
