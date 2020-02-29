//
//  ContentView.swift
//  RefreshingPublisherView
//
//  Created by Chris Thomas on 26/02/2020.
//  Copyright © 2020 ChrisThomas. All rights reserved.
//

import Combine
import SwiftUI
import PublisherView

struct ContentView: View {
    
    @EnvironmentObject var data: DataObject<Just<String>>
    
    var body: some View {
        TabView {
            VStack {
                Text(data.date.description)
                data.value.map(Text.init)
            }
            .tabItem { Text("One") }
            .modifier(ContentLoader<DataObject<Just<String>>>())
//            .reloadable<DataObject<Just<String>>>()
            Text(data.date.description)
                .tabItem { Text("Two") }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

protocol Loader: ObservableObject {
    func reload(refreshTime: TimeInterval)
    func cancel()
}

class DataObject<Publisher>: Loader where Publisher: Combine.Publisher {
    
    public typealias Output = Publisher.Output
    public typealias Failure = Publisher.Failure
    
    let publisher: Publisher
    var lastRefresh: Date = Date()
    
    @Published var date: Date = Date()
    @Published var value: Output?
    @Published var error: Failure?
    @Published var loading: Bool = true
    
    var subscription: AnyCancellable?
    
    init(publisher: Publisher) {
        self.publisher = publisher
    }
    
    func reload(refreshTime: TimeInterval) {
        if lastRefresh.addingTimeInterval(refreshTime) < Date() {
            loading = true
            subscription = publisher
                .sink(receiveCompletion: { completion in
                    self.loading = false
                    guard
                        case let .failure(failure) = completion
                        else {
                            self.date = Date()
                            self.lastRefresh = self.date
                            return
                    }
                    self.error = failure
                }, receiveValue:{ value in
                    self.loading = false
                    self.date = Date()
                    self.value = value
                    self.lastRefresh = self.date
                })
        }
    }
    
    func cancel() {
        loading = false
        subscription?.cancel()
    }
}

struct ContentLoader<DataLoader>: ViewModifier where DataLoader: Loader {
    
    struct ContentView: View {
        
        @EnvironmentObject var dataLoader: DataLoader
        let content: Content
        
        var body: some View {
            content
                .onAppear {
                    self.dataLoader.reload(refreshTime: 3)
            }
                .onDisappear {
                    self.dataLoader.cancel()
            }
        }
    }
    
    func body(content: Content) -> some View {
        ContentView(content: content)
    }
    
    
}

extension View {
    func reloadable<DataObject>() -> some View where DataObject: Loader {
        modifier(ContentLoader<DataObject>())
    }
}
