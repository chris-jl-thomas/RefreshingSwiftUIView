//
//  ContentView.swift
//  RefreshingPublisherView
//
//  Created by Chris Thomas on 26/02/2020.
//  Copyright © 2020 ChrisThomas. All rights reserved.
//

import Combine
import SwiftUI

struct ContentView: View {
    
    @ObservedObject var data = DataObject(publisher: Just("success"))
    
    var body: some View {
        TabView {
            VStack {
                Text(data.date.description)
                data.value.map(Text.init)
            }
                .tabItem { Text("One") }
                .modifier(ContentLoader(dataLoader: data))
            Text("data.date.description")
                .tabItem { Text("Two") }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class DataObject<Publisher>: ObservableObject where Publisher: Combine.Publisher {
    
    public typealias Output = Publisher.Output
    public typealias Failure = Publisher.Failure
    
    let publisher: Publisher
    var lastRefresh: Date = Date()
    
    @Published var date: Date = Date()
    @Published var value: Output?
    @Published var error: Failure?
    
    @Published var loading: Bool = false {
        didSet {
            if oldValue == false && loading == true {
                self.reload(refreshTime: 0)
            }
        }
    }
    
    var subscription: AnyCancellable?
    
    init(publisher: Publisher) {
        self.publisher = publisher
        reload(refreshTime: -1)
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

struct ContentLoader<Publisher>: ViewModifier where Publisher: Combine.Publisher {
    
    @ObservedObject var dataLoader: DataObject<Publisher>
    
    struct ContentView: View {
        
        @ObservedObject var dataLoader: DataObject<Publisher>
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
        ContentView(dataLoader: dataLoader, content: content)
    }
    
    
}
//
//extension View {
//    func reloadable() -> some View {
//        modifier(ContentLoader())
//    }
//}
