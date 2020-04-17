import Action
import RxRelay
import RxSwift
import RxOptional
import Unio

protocol RepositoryListViewStreamType: AnyObject {
    var input: InputWrapper<RepositoryListViewStream.Input> { get }
    var output: OutputWrapper<RepositoryListViewStream.Output> { get }
}

final class RepositoryListViewStream: UnioStream<RepositoryListViewStream>, RepositoryListViewStreamType {

    convenience init(flux: Flux = .shared) {
        self.init(input: Input(),
                  state: State(),
                  extra: Extra(flux: flux))
    }
}

extension RepositoryListViewStream {
    struct Input: InputType {
        let viewWillAppear = PublishRelay<Void>()
        let refreshControlValueChanged = PublishRelay<Void>()
        let retryFetchingRepositories = PublishRelay<Void>()
        let didTapCell = PublishRelay<IndexPath>()
        let filterButtonTapped = PublishRelay<Void>()
    }

    struct Output: OutputType {
        let repositories: BehaviorRelay<[Repository]>
        let reloadData: PublishRelay<Void>
        let isRefreshControlRefreshing: BehaviorRelay<Bool>
        let failedToFetchRespositories: PublishRelay<Void>
        let isDisplayingOnlyFavoriteRepositories: BehaviorRelay<Bool>
    }

    struct State: StateType {
        let repositories = BehaviorRelay<[Repository]>(value: [])
        let favoriteRepositories = BehaviorRelay<[Int]>(value: [])
        let isRefreshControlRefreshing = BehaviorRelay<Bool>(value: false)
        let isDisplayingOnlyFavoriteRepositories = BehaviorRelay<Bool>(value: false)
        
        var currentRepositories: [Repository] {
            if isDisplayingOnlyFavoriteRepositories.value {
                return repositories.value.filter { favoriteRepositories.value.contains(Int($0.id)) }
            } else {
                return repositories.value
            }
        }
    }

    struct Extra: ExtraType {
        let flux: Flux

        let fetchRepositoriesAction: Action<(limit: Int, offset: Int), Void>
        let fetchFavoriteRepositoriesAction: Action<Void, Void>
        let toggleFavoriteRepositoryAction: Action<(isRemoving: Bool, Int), Void>
    }
}

extension RepositoryListViewStream {
    static func bind(from dependency: Dependency<Input, State, Extra>, disposeBag: DisposeBag) -> Output {
        let state = dependency.state
        let extra = dependency.extra

        let flux = extra.flux
        let fetchRepositoriesAction = extra.fetchRepositoriesAction
        let fetchFavoriteRepositoriesAction = extra.fetchFavoriteRepositoriesAction
        let toggleFavoriteRepositoryAction = extra.toggleFavoriteRepositoryAction

        let viewWillAppear = dependency.inputObservables.viewWillAppear
        let refreshControlValueChanged = dependency.inputObservables.refreshControlValueChanged
        let retryFetchingRepositories = dependency.inputObservables.retryFetchingRepositories
        let didTapCell = dependency.inputObservables.didTapCell
        let filterButtonTapped = dependency.inputObservables.filterButtonTapped

        filterButtonTapped.withLatestFrom(state.isDisplayingOnlyFavoriteRepositories.asObservable())
            .map { !$0 }
            .bind(to: state.isDisplayingOnlyFavoriteRepositories)
            .disposed(by: disposeBag)
        
        let fetchRepositories = Observable
            .merge(viewWillAppear,
                   refreshControlValueChanged,
                   retryFetchingRepositories
        )

        fetchRepositories
            .map { (limit: Const.count, offset: 0) }
            .bind(to: fetchRepositoriesAction.inputs)
            .disposed(by: disposeBag)
        
        fetchRepositories
            .bind(to: fetchFavoriteRepositoriesAction.inputs)
            .disposed(by: disposeBag)

        flux.repositoryStore.repositories.asObservable()
            .bind(to: state.repositories)
            .disposed(by: disposeBag)
        
        flux.repositoryStore.favoriteRepositoriesID.asObservable()
            .bind(to: state.favoriteRepositories)
            .disposed(by: disposeBag)

        let failedToFetch = PublishRelay<Void>()
        
        fetchRepositoriesAction.errors
            .subscribe(onNext: { error in
                print("API Error: \(error)")
                failedToFetch.accept(())
            })
            .disposed(by: disposeBag)

        let debouncedDidTapCell = didTapCell
        
        debouncedDidTapCell
            .map ({ indexPath -> Repository in
                let row = indexPath.row
                let repository = state.currentRepositories[row]
                return repository
            }).withLatestFrom(state.favoriteRepositories, resultSelector: { repository, favorites -> (Bool, Int) in
                let isRemoving = favorites.contains(Int(repository.id))
                return (isRemoving, Int(repository.id))
            })
            .bind(to: toggleFavoriteRepositoryAction.inputs)
            .disposed(by: disposeBag)
        
        fetchRepositoriesAction
            .executing
            .bind(to: state.isRefreshControlRefreshing)
            .disposed(by: disposeBag)
        
        
        
        let targetRepositories = Observable
            .merge(
                state.repositories.map(void),
                state.favoriteRepositories.map(void),
                state.isDisplayingOnlyFavoriteRepositories.map(void))
            .map { _ in state.currentRepositories }
        
        let outputRepositories: BehaviorRelay<[Repository]> = .init(value: [])
        targetRepositories.bind(to: outputRepositories).disposed(by: disposeBag)
        
        let reloadData = PublishRelay<Void>()
        
        outputRepositories
            .map(void)
            .bind(to: reloadData)
            .disposed(by: disposeBag)

        return Output(repositories: outputRepositories,
                      reloadData: reloadData,
                      isRefreshControlRefreshing: state.isRefreshControlRefreshing,
                      failedToFetchRespositories: failedToFetch,
                      isDisplayingOnlyFavoriteRepositories: state.isDisplayingOnlyFavoriteRepositories
        )
    }
}

extension RepositoryListViewStream.Extra {
    init(flux: Flux) {
        self.flux = flux

        let repositoryAction = flux.repositoryAction

        self.fetchRepositoriesAction = Action { limit, offset in
            repositoryAction.fetchRepositories(limit: limit, offset: offset)
        }
        
        self.fetchFavoriteRepositoriesAction = Action { _ in
            repositoryAction.fetchFavoriteRepositoriesID()
        }
        
        self.toggleFavoriteRepositoryAction = Action { (isRemoving, id) in
            if isRemoving {
                return repositoryAction.removeFavoriteRepository(repository: id)
            } else {
                return repositoryAction.addFavoriteRepository(repository: id)
            }
        }
    }
}

extension RepositoryListViewStream {
    enum Const {
        static let count: Int = 20
    }
}
