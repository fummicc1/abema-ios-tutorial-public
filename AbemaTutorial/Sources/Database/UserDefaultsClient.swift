//
//  UserDefaultsClient.swift
//  AbemaTutorial
//
//  Created by Fumiya Tanaka on 2020/04/17.
//

import Foundation
import RxSwift
import RxCocoa

protocol UserDefaultsClientType {
    func fetchFavoriteRepositoriesID() -> Observable<[Int]>
    func addFavoriteRepositoryId(repository id: Int) -> Observable<[Int]>
    func removeFavoriteRepositoryId(repository id: Int) -> Observable<[Int]>
}

class UserDefaultsClient: UserDefaultsClientType {
    static let shared = UserDefaultsClient()
    private let database: UserDefaults
    
    init(database: UserDefaults = .standard) {
        self.database = database
    }
    
    private func fetchFavoriteRepositoriesIDFromDatabase() -> [Int] {
        guard let favoriteRepositoriesID = database.array(forKey: UserDefaults.Key.favoriteRepositoriesID) as? [Int] else {
            return []
        }
        return favoriteRepositoriesID
    }
    
    private func persistFavoriteRepositoriesIDToDatabase(repositories: [Int]) {
        database.set(repositories, forKey: UserDefaults.Key.favoriteRepositoriesID)
    }
    
    func fetchFavoriteRepositoriesID() -> Observable<[Int]> {
        Observable<[Int]>.create { [weak self] observer -> Disposable in
            guard let self = self else {
                return Disposables.create()
            }
            observer.onNext(self.fetchFavoriteRepositoriesIDFromDatabase())
            return Disposables.create()
        }
    }
    
    func addFavoriteRepositoryId(repository id: Int) -> Observable<[Int]> {
        Single<[Int]>.create { [weak self] observer -> Disposable in
            guard let self = self else {
                return Disposables.create()
            }
            let newFavoriteRepositoriesID = self.fetchFavoriteRepositoriesIDFromDatabase() + [id]
            self.persistFavoriteRepositoriesIDToDatabase(repositories: newFavoriteRepositoriesID)
            observer(.success(newFavoriteRepositoriesID))
            return Disposables.create()
        }.asObservable()
    }
    
    func removeFavoriteRepositoryId(repository id: Int) -> Observable<[Int]> {
        Single<[Int]>.create { [weak self] observer -> Disposable in
            guard let self = self else {
                return Disposables.create()
            }
            var favoriteRepositoriesID = self.fetchFavoriteRepositoriesIDFromDatabase()
            if let index = favoriteRepositoriesID.lazy.firstIndex(of: id) {
                favoriteRepositoriesID.remove(at: index)
                self.persistFavoriteRepositoriesIDToDatabase(repositories: favoriteRepositoriesID)
                observer(.success(favoriteRepositoriesID))
            } else {
                observer(.error(UserDefaultsError.doesNotExistRepositoryID))
            }
            return Disposables.create()
        }.asObservable()
    }
    
}
