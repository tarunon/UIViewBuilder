//
//  SceneDelegate.swift
//  Example
//
//  Created by tarunon on 2020/01/05.
//  Copyright © 2020 tarunon. All rights reserved.
//

import UIKit
import UIViewBuilder

@available(iOS 13, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        if let windowScene = scene as? UIWindowScene {
            var emoji = [String]()

            for codePoint in 0x1F600...0x1F64F {
                guard let scalarValue = Unicode.Scalar(codePoint) else {
                    continue
                }
                emoji.append(String(scalarValue))
            }

            let window = UIWindow(windowScene: windowScene)
            let vc = HostingController {
                List {
                    ForEach(data: emoji) { text in
                        VStack {
                            Spacer()
                            Label(text: text)
                            Spacer()
                        }
                    }
                }
            }
            window.rootViewController = vc
            self.window = window
            window.makeKeyAndVisible()

            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (_) in
                vc.component.body.data = Array(emoji.shuffled()[0..<Int.random(in: 0..<emoji.count)])
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

