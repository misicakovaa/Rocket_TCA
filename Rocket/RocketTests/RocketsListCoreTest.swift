//
//  RocketsListCoreTest.swift
//  RocketTests
//
//  Created by Adela Mišicáková on 28.07.2022.
//

import XCTest
import ComposableArchitecture
import XCTestDynamicOverlay
import XCTest
@testable import Rocket

class RocketsListTest: XCTestCase {
    
    let testScheduler = DispatchQueue.test
    
    func test_RocketsListCore_GetRockets_Success() {
        
        let rockets = [exampleRocket1, exampleRocket2]
        let details: IdentifiedArrayOf<DetailState> = [DetailState(id:  UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
                                                                   rocket: exampleRocket1),
                                                       DetailState(id:  UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                                                                   rocket: exampleRocket2)]
        
        let testFetch: ( String ) -> Effect<[Rocket], RocketsManager.Failure> = { _ in
            Effect<[Rocket], RocketsManager.Failure> (value: rockets)
        }
        
        let rocketsManager = RocketsManager(fetch: testFetch)
        
        let store = TestStore(initialState: AppState(),
                              reducer: appReducer,
                              environment: AppEnvironment(mainQueue: self.testScheduler.eraseToAnyScheduler(),
                                                          rocketsManager: rocketsManager, motionManager: .live, uuid: UUID.incrementing ))
        
        store
            .send(.getRockets) {
                $0.fetchingState = .loading
            }
        
        testScheduler.advance(by: 1)
        
        store
            .receive(.rocketsResponse(Result.success(rockets))) {
                $0.fetchingState = .success(rockets)
                $0.rockets = rockets
                $0.details = details
            }
    }
}
