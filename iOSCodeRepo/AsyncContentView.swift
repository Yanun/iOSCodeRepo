//
//  AsyncContentView.swift
//  Test
//
//  Created by xndm on 2025/1/21.
//

import Foundation
import SwiftUI
import Combine

enum LoadingState<Value> {
    case idle
    case loading
    case failed(Error)
    case loaded(Value)
}

protocol LoadableObject: ObservableObject {
    associatedtype Output
    var state: LoadingState<Output> { get }
    func load()
}

struct ErrorView: View {
    
    let error: Error
    let retryHandler: () -> Void
    
    var body: some View {
        VStack {
            Text("\(error)")
            Button(action: retryHandler) {
                Text("Retry")
            }
        }
    }
}

struct AsyncContentView<Source: LoadableObject,
                        LoadingView: View,
                        Content: View>: View {
    @ObservedObject var source: Source
    var loadingView: LoadingView
    var content: (Source.Output) -> Content

    init(source: Source,
         loadingView: LoadingView,
         @ViewBuilder content: @escaping (Source.Output) -> Content) {
        self.source = source
        self.loadingView = loadingView
        self.content = content
    }

    var body: some View {
        switch source.state {
        case .idle:
            Color.clear.onAppear(perform: source.load)
        case .loading:
            loadingView
        case .failed(let error):
            ErrorView(error: error, retryHandler: source.load)
        case .loaded(let output):
            content(output)
        }
    }
}

class PublishedObject<Wrapped: Publisher>: LoadableObject {
    @Published private(set) var state = LoadingState<Wrapped.Output>.idle

    private let publisher: Wrapped
    private var cancellable: AnyCancellable?

    init(publisher: Wrapped) {
        self.publisher = publisher
    }

    func load() {
        state = .loading

        cancellable = publisher
            .map(LoadingState.loaded)
            .catch { error in
                Just(LoadingState.failed(error))
            }
            .sink { [weak self] state in
                self?.state = state
            }
    }
}

extension AsyncContentView {
    init<P: Publisher>(
        publisher: P,
        loadingView: LoadingView,
        @ViewBuilder content: @escaping (P.Output) -> Content
    ) where Source == PublishedObject<P> {
        self.init(
            source: PublishedObject(publisher: publisher),
            loadingView: loadingView,
            content: content
        )
    }
}

