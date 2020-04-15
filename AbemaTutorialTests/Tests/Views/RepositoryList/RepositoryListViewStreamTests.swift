import XCTest
import RxSwift
import RxTest

@testable import AbemaTutorial

final class RepositoryListViewStreamTests: XCTestCase {
    var dependency: Dependency!

    override func setUp() {
        super.setUp()
        dependency = Dependency()
    }

    func testViewWillAppear() {
        let testTarget = dependency.testTarget
        let repositoryAction = dependency.repositoryAction
        let repositoryStore = dependency.repositoryStore

        let mockRepository = Repository.mock()

        let repositories = WatchStack(testTarget.output.repositories)
        let reloadData = WatchStack(testTarget.output.reloadData.map { true }) // Voidだと比較できないのでBool化
        let isRefreshControlRefreshing = WatchStack(testTarget.output.isRefreshControlRefreshing)
        let failedToFetchRespositories = WatchStack(testTarget.output.failedToFetchRespositories.map { true }) // voidで比較できない

        // 初期状態

        XCTAssertEqual(repositories.value, [])
        XCTAssertEqual(reloadData.events, [])
        XCTAssertEqual(isRefreshControlRefreshing.value, false)
        // PubishRelayに関しては、TestableObserver.eventsでcheckしてあげる
        XCTAssertEqual(failedToFetchRespositories.events, [])

        // viewWillAppearの後

        testTarget.input.accept((), for: \.viewWillAppear)

        XCTAssertEqual(repositories.value, [])
        XCTAssertEqual(reloadData.events, [])
        XCTAssertEqual(isRefreshControlRefreshing.value, true)
        XCTAssertEqual(failedToFetchRespositories.events, [])

        // データが返ってきた後

        repositoryAction._fetchResult.accept(.next(()))
        repositoryAction._fetchResult.accept(.completed)
        repositoryStore._repositories.accept([mockRepository])

        XCTAssertEqual(repositories.value, [mockRepository])
        XCTAssertEqual(reloadData.events, [.next(true)])
        XCTAssertEqual(isRefreshControlRefreshing.value, false)
        XCTAssertEqual(failedToFetchRespositories.events, [])

        // リフレッシュ後

        testTarget.input.accept((), for: \.refreshControlValueChanged)

        XCTAssertEqual(repositories.value, [mockRepository])
        XCTAssertEqual(reloadData.events, [.next(true)])
        XCTAssertEqual(isRefreshControlRefreshing.value, true)
        XCTAssertEqual(failedToFetchRespositories.events, [])

        // データが返ってきた後

        repositoryAction._fetchResult.accept(.next(()))
        repositoryAction._fetchResult.accept(.completed)
        repositoryStore._repositories.accept([mockRepository])
        XCTAssertEqual(failedToFetchRespositories.events, [])

        XCTAssertEqual(repositories.value, [mockRepository])
        XCTAssertEqual(reloadData.events, [.next(true), .next(true)])
        XCTAssertEqual(isRefreshControlRefreshing.value, false)
    }
    
    func testRefreshControlValueChanged() {
        // setup
        let testTarget = dependency.testTarget
        let repositoryAction = dependency.repositoryAction
        let repositoryStore = dependency.repositoryStore
        
        let mockRepository = Repository.mock()
        
        let repositories = WatchStack(testTarget.output.repositories)
        let reloadData = WatchStack(testTarget.output.reloadData.map { true })
        let isRefreshControlRefreshing = WatchStack(testTarget.output.isRefreshControlRefreshing)
        let failedToFetchRespositories = WatchStack(testTarget.output.failedToFetchRespositories.map { true })
        
        // check initial state.
        XCTAssertEqual(repositories.value, [])
        XCTAssertEqual(reloadData.events, [])
        XCTAssertEqual(isRefreshControlRefreshing.value, false)
        XCTAssertEqual(failedToFetchRespositories.events, [])
        
        // input
        testTarget.input.accept((), for: \.refreshControlValueChanged)
        
        // check after refreshControlValueChanged
        XCTAssertEqual(repositories.value, [])
        XCTAssertEqual(reloadData.events, [])
        XCTAssertEqual(isRefreshControlRefreshing.value, true)
        XCTAssertEqual(failedToFetchRespositories.events, [])
        
        // get repositories
        repositoryAction._fetchResult.accept(.next(()))
        repositoryAction._fetchResult.accept(.completed)
        repositoryStore._repositories.accept([mockRepository])
        
        // check
        XCTAssertEqual(repositories.value, [mockRepository])
        XCTAssertEqual(reloadData.events, [.next(true)])
        XCTAssertEqual(isRefreshControlRefreshing.value, false)
        XCTAssertEqual(failedToFetchRespositories.events, [])
    }
    
    func testRetryFetchingRepositories() {
        // setup
        let testTarget = dependency.testTarget
        let repositoryAction = dependency.repositoryAction
        let repositoryStore = dependency.repositoryStore
        
        let mockRepository = Repository.mock()
        
        let repositories = WatchStack(testTarget.output.repositories)
        let reloadData = WatchStack(testTarget.output.reloadData.map { true })
        let isRefreshControlRefreshing = WatchStack(testTarget.output.isRefreshControlRefreshing)
        let failedToFetchRespositories = WatchStack(testTarget.output.failedToFetchRespositories.map { true })
        
        // check initial state.
        XCTAssertEqual(repositories.value, [])
        XCTAssertEqual(reloadData.events, [])
        XCTAssertEqual(isRefreshControlRefreshing.value, false)
        XCTAssertEqual(failedToFetchRespositories.events, [])
        
        // input
        testTarget.input.accept((), for: \.retryFetchingRepositories)
        
        // retry fetching repositories
        repositoryAction._fetchResult.accept(.next(()))
        repositoryAction._fetchResult.accept(.completed)
        repositoryStore._repositories.accept([mockRepository])
        
        // check
        XCTAssertEqual(repositories.value, [mockRepository])
        XCTAssertEqual(reloadData.events, [.next(true)])
        XCTAssertEqual(isRefreshControlRefreshing.value, false)
        XCTAssertEqual(failedToFetchRespositories.events, [])
    }
    
    func testFailedFetchingRepositories() {
        // setup
        let testTarget = dependency.testTarget
        let repositoryAction = dependency.repositoryAction
        
        let repositories = WatchStack(testTarget.output.repositories)
        let reloadData = WatchStack(testTarget.output.reloadData.map { true })
        let isRefreshControlRefreshing = WatchStack(testTarget.output.isRefreshControlRefreshing)
        let failedToFetchRespositories = WatchStack(testTarget.output.failedToFetchRespositories.map { true })
        
        // check initial state.
        XCTAssertEqual(repositories.value, [])
        XCTAssertEqual(reloadData.events, [])
        XCTAssertEqual(isRefreshControlRefreshing.value, false)
        XCTAssertEqual(failedToFetchRespositories.events, [])
        
        // input
        testTarget.input.accept((), for: \.viewWillAppear)
        
        // retry fetching repositories
        repositoryAction._fetchResult.accept(.error(APIError.internalServerError))
        
        // check
        XCTAssertEqual(repositories.value, [])
        XCTAssertEqual(reloadData.events, [])
        XCTAssertEqual(isRefreshControlRefreshing.value, false)
        XCTAssertEqual(failedToFetchRespositories.events, [.next(true)])
    }
}

extension RepositoryListViewStreamTests {
    struct Dependency {
        let testTarget: RepositoryListViewStream

        let repositoryStore: MockRepositoryStore
        let repositoryAction: MockRepositoryAction

        init() {
            repositoryStore = MockRepositoryStore()
            repositoryAction = MockRepositoryAction()

            let flux = Flux(repositoryStore: repositoryStore,
                            repositoryAction: repositoryAction)

            testTarget = RepositoryListViewStream(flux: flux)
        }
    }
}
