import RxSwift
import RxRelay

protocol RepositoryStoreType {
    var repositories: Property<[Repository]> { get }
}

final class RepositoryStore: RepositoryStoreType {
    static let shared = RepositoryStore()

    @BehaviorWrapper(value: [])
    var repositories: Property<[Repository]>

    private let disposeBag = DisposeBag()

    init(dispatcher: RepositoryDispatcher = .shared) {
        dispatcher.updateRepositories
            .bind(to: _repositories)
            .disposed(by: disposeBag)
    }
}
