import RxSwift
import RxRelay

protocol RepositoryStoreType {
    var repositories: Property<[Repository]> { get }
    var favoriteRepositoriesID: Property<[Int]> { get }
}

final class RepositoryStore: RepositoryStoreType {
    static let shared = RepositoryStore()

    @BehaviorWrapper(value: [])
    var repositories: Property<[Repository]>

    @BehaviorWrapper(value: [])
    var favoriteRepositoriesID: Property<[Int]>
    
    private let disposeBag = DisposeBag()
    
    init(dispatcher: RepositoryDispatcher = .shared) {
        dispatcher.updateRepositories
            .bind(to: _repositories)
            .disposed(by: disposeBag)
        
        dispatcher.updateFavoriteRepositoriesID
            .bind(to: _favoriteRepositoriesID)
            .disposed(by: disposeBag)
    }
}
