//
//  RocketListCore.swift
//  Rocket
//
//  Created by Adela Mišicáková on 26.07.2022.
//

import Foundation
import ComposableArchitecture
import ComposableCoreMotion

//MARK: - Environment

struct AppEnvironment {
    var mainQueue: AnySchedulerOf<DispatchQueue>
    var rocketsManager: RocketsManager
    var motionManager: MotionManager
    var uuid: () -> UUID
}

//MARK: - Reducer

let appReducer: Reducer<AppState, AppAction, AppEnvironment> = .combine(
    
    detailReducer
        .forEach(
            state: \.details,
            action: /AppAction.detail(id:action:),
            environment: { DetailEnvironment(motionManager: $0.motionManager) }
        ),
    
        .init { state, action, env in
            switch action {
                
            case .getRockets:
                state.fetchingState = .loading
                
                return env.rocketsManager.fetchRockets()
                    .receive(on: env.mainQueue)
                    .catchToEffect()
                    .map(AppAction.rocketsResponse)
                
            case .rocketsResponse(.success(let rockets)):
                rockets.forEach { rocket in
                    state.details.append(
                        DetailState(id: env.uuid(), rocket: rocket))
                }
                
                state.fetchingState = .success(state.details)
                return .none
                
            case .rocketsResponse(.failure(let error)):
                state.fetchingState = .error(error.localizedDescription)
                
                state.alert = .init(
                    title: TextState("Error"),
                    message: TextState(error.localizedDescription),
                    buttons: [.default(TextState("Retry"), action: .send(.getRockets))]
                )
                return .none
                
            case .retry:
                state.alert = nil
                return .init(value: .getRockets)
                
            case .detail(id: let id, action: let action):
                return .none
                
            case .showDetail(let rocket):
                print("show detail for \(rocket.rocketName)")
                state.presentDetail = true
                return .none
                
            case .dismissDetail(let rocket):
                print("dismiss detail for: \(rocket.rocketName)")
                state.presentDetail = false
                return .none
            }
        }
)

