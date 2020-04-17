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
    func fetchFavoriteRepositoriesID() -> Observable<Int>
    func addFavoriteRepositoryId(repository id: Int) -> Observable<Void>
    func removeFavoriteRepositoryId(repository id: Int) -> Observable<Void>
}

class UserDefaultsClient: UserDefaultsClientType {
    static let shared = UserDefaultsClient()
    private let database: UserDefaults
    
    init(database: UserDefaults = .standard) {
        self.database = database
    }
    
    func fetchFavoriteRepositoriesID() -> Observable<Int> {
        Observable<Int>.create { observer -> Disposable in
            
            return Disposables.create()
        }
    }
    
    func addFavoriteRepositoryId(repository id: Int) -> Observable<Void> {
        Observable<Void>.create { observer -> Disposable in
            
            return Disposables.create()
        }
    }
    
    func removeFavoriteRepositoryId(repository id: Int) -> Observable<Void> {
        Observable<Void>.create { observer -> Disposable in
            
            return Disposables.create()
        }
    }
    
}
