import UIKit
import RxCocoa
import RxSwift

final class RepositoryListViewController: UIViewController {

    private let viewStream = RepositoryListViewStream()

    private lazy var dataSource = RepositoryListViewDataSource(viewStream: viewStream)

    private let disposeBag = DisposeBag()

    // MARK: UI

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = dataSource
        tableView.refreshControl = refreshControl
        tableView.register(RepositoryListCell.self)
        tableView.register(UITableViewCell.self) // フォールバック用
        return tableView
    }()
    
    private let filterButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let refreshControl = UIRefreshControl()

    init() {
        super.init(nibName: nil, bundle: nil)

        // Bind
        // Output
        viewStream.output.reloadData
            .bind(to: Binder(tableView) { tableView, _ in
                tableView.reloadData()
            })
            .disposed(by: disposeBag)

        viewStream.output.failedToFetchRespositories
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                let alert = UIAlertController(title: L10n.error, message: L10n.sorrySomethingUnexpectedHappenedPleaseTryAgainLater, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: L10n.close, style: .default, handler: { [weak self] _ in
                    self?.viewStream.input.accept((), for: \.retryFetchingRepositories)
                }))
                self?.present(alert, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        viewStream.output.isRefreshControlRefreshing
            .bind(to: refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)

        viewStream.output.isDisplayingOnlyFavoriteRepositories.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] onlyFavorite in
                self?.toggleFilterButton(isFavoriteMode: onlyFavorite)
            })
            .disposed(by: disposeBag)
        
        // Input
        refreshControl.rx.controlEvent(.valueChanged)
            .bind(to: viewStream.input.accept(for: \.refreshControlValueChanged))
            .disposed(by: disposeBag)
        
        tableView.rx.itemSelected.asObservable()
            .bind(to: viewStream.input.accept(for: \.didTapCell))
            .disposed(by: disposeBag)
        
        filterButton.rx.tap
            .bind(to: viewStream.input.accept(for: \.filterButtonTapped))
            .disposed(by: disposeBag)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Layout
        view.addSubview(tableView)
        view.addSubview(filterButton)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        NSLayoutConstraint.activate([
            filterButton.heightAnchor.constraint(equalToConstant: 64),
            filterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            filterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            filterButton.widthAnchor.constraint(equalToConstant: 64)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewStream.input.accept((), for: \.viewWillAppear)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Adjust UI Layout.
        filterButton.layer.cornerRadius = filterButton.frame.size.width / 2
    }
    
    private func toggleFilterButton(isFavoriteMode: Bool) {
        if isFavoriteMode {
            
            if #available(iOS 13, *) {
                filterButton.backgroundColor = UIColor.systemBackground
                filterButton.setImage(UIImage(systemName: "heart_fill", withConfiguration: UIImage.SymbolConfiguration.init(pointSize: 32, weight: .bold)), for: .normal)
            } else {
                filterButton.backgroundColor = UIColor.white
                filterButton.setTitle("❤️", for: .normal)
                filterButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
            }
        } else {
            
            if #available(iOS 13, *) {
                filterButton.backgroundColor = UIColor.systemBackground
                filterButton.setImage(UIImage(systemName: "heart", withConfiguration: UIImage.SymbolConfiguration.init(pointSize: 32, weight: .bold)), for: .normal)
            } else {
                filterButton.backgroundColor = UIColor.white
                filterButton.setTitle("♡", for: .normal)
                filterButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
            }
        }
    }
}
