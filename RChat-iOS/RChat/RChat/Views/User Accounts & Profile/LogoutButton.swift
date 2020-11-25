//
//  LogoutButton.swift
//  RChat
//
//  Created by Andrew Morgan on 23/11/2020.
//

import RealmSwift
import SwiftUI

struct LogoutButton: View {
    @EnvironmentObject var state: AppState
    
    @AppStorage("shouldSharePresence") var shouldSharePresence = false
    
    var body: some View {
        Button("Log Out") {
            state.shouldIndicateActivity = true
            if shouldSharePresence {
                let realmConfig = app.currentUser?.configuration(partitionValue: state.user?.partition ?? "")
                guard var config = realmConfig else {
                    state.error = "Cannot get Realm config from current user"
                    return
                }
                config.objectTypes = [User.self, UserPreferences.self, Conversation.self, Photo.self]
                Realm.asyncOpen(configuration: config)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { result in
                        if case let .failure(error) = result {
                            self.state.error = "Failed to open realm: \(error.localizedDescription)"
                        }
                    }, receiveValue: { realm in
                        print("Realm User file location: \(realm.configuration.fileURL!.path)")
                        do {
                            try realm.write {
                                state.user?.presenceState = .offLine
                            }
                        } catch {
                            state.error = "Unable to open Realm write transaction"
                        }
                        state.shouldIndicateActivity = false
                    })
                    .store(in: &self.state.cancellables)
            }
            
            app.currentUser?.logOut()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in
                }, receiveValue: {
                    state.shouldIndicateActivity = false
                    state.logoutPublisher.send($0)
                })
                .store(in: &state.cancellables)
        }
        .disabled(state.shouldIndicateActivity)
    }
}

struct LogoutButton_Previews: PreviewProvider {
    static var previews: some View {
        AppearancePreviews(
            LogoutButton()
                .environmentObject(AppState())
                .previewLayout(.sizeThatFits)
                .padding()
        )
    }
}
