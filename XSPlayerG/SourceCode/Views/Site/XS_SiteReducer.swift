//
//  XS_SiteReducer.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/26.
//

import Foundation
import ComposableArchitecture
import SwiftUI

private extension [String:XS_FilmModel._FilterData._Value] {
    var xs_f: [String:String] {
        reduce(into: [:]) { partialResult, item in
            partialResult[item.key] = item.value.v
        }
    }
}

@Reducer
struct XS_SiteReducer {
    static var store: StoreOf<XS_SiteReducer> { .init(initialState: .init()) { XS_SiteReducer() } }
    @ObservableState
    struct State: Equatable {
        var film: XS_FilmModel?
        var site: XS_SiteM!
        var currentClass: XS_FilmModel.ClassData = .init(type_id: "", type_name: "")//.init(type_id: "0", type_name: "最新")
        var filters: [String:XS_FilmModel._FilterData._Value] = [:]
        var page: Int = 0
        var list: [XS_VideoModel] = []
        var loading: XS_LoadingModel = .init()
        var current: _Current = .init(t: "")
    }
    enum Action: BindableAction {
        case onAppear(XS_SiteM)
        case setClass(XS_FilmModel.ClassData)
        case setFilters(String, XS_FilmModel._FilterData._Value)
        case insertList([XS_VideoModel], Int, _Current)
        case loading(String, XS_LoadingModel.XS_Status)
        case refresh
        case loadMore
        case binding(BindingAction<State>)
    }
    private var classKey: String { "classKey" }
    private var listKey: String { "listKey" }
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .loadMore:
                guard state.loading.status == .idle else { return .none }
                state.current = _Current(t: state.currentClass.type_id, f: state.filters.xs_f)
                return getListRun(site: state.site, pg: state.page+1, c: state.current)
            case .refresh:
                state.current = _Current(t: state.currentClass.type_id, f: state.filters.xs_f)
                return getListRun(site: state.site, c: state.current, refresh: true)
            case let .loading(key, value):
                state.loading.set(value, key: key)
                return .none
            case let .insertList(value, pg, current):
                if current == state.current {
                    if pg == 1 {
                        state.list = value
                    } else {
                        state.list += value
                    }
                    state.page = pg
                }
                return .none
            case let .setFilters(key, value):
                let value = value.v.isEmpty ? nil : value
                if value == state.filters[key] { return .none }
                state.filters[key] = value
                state.list = []
                state.page = 0
                let f: [String:String] = state.filters.reduce(into: [:]) { partialResult, item in
                    partialResult[item.key] = item.value.v
                }
                state.current = _Current(t: state.currentClass.type_id, f: f)
                return getListRun(site: state.site, c: state.current)
            case let .setClass(current):
                guard current != state.currentClass else { return .none }
                state.currentClass = current
                state.filters = [:]
                state.list = []
                state.page = 0
                state.current = _Current(t: current.type_id)
                return getListRun(site: state.site, c: state.current)
            case let .onAppear(value):
                guard state.film == nil else { return .none }
                state.site = value
                state.loading.set(.loading, key: classKey)
                return .run { send in
                    do {
                        let film = try await XS_NetWork.shared.classify(site: value)
                        if !film.classData.isEmpty {
                            await send(.setClass(film.classData[0]))
                            await send(.binding(.set(\.film, film)))
                        }
                    } catch {
                        debugPrint(error.localizedDescription)
                    }
                    await send(.loading(classKey, .idle))
                }
            }
        }
    }
    
    struct _Current: Equatable {
        var t: String
        var f: [String:String] = [:]
    }
    private func getListRun(site: XS_SiteM, pg: Int = 1, c: _Current, refresh: Bool = false) -> Effect<Action> {
        .run { send in
            await send(.loading(listKey, refresh ? .refresh : .loading))
            do {
                switch try await XS_NetWork.shared.list(site: site, pg: pg, t: c.t, f: c.f) {
                case let .list(list):
                    await send(.insertList(list, pg, c))
                    await send(.loading(listKey, .idle))
                case let .noMore(list):
                    await send(.insertList(list, pg, c))
                    await send(.loading(listKey, .noMore))
                }
            } catch {
                debugPrint(error.localizedDescription)
                await send(.loading(listKey, .idle))
            }
        }
    }
}
