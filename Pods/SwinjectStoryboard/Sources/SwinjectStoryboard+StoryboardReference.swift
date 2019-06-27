//
//  SwinjectStoryboard+StoryboardReference.
//  SwinjectStoryboard
//
//  Created by Jakub Vaňo on 01/09/16.
//  Copyright © 2016 Swinject Contributors. All rights reserved.
//

internal extension SwinjectStoryboard {

    static func pushInstantiatingStoryboard(_ storyboard: SwinjectStoryboard) {
        storyboardStack.append(storyboard)
    }

    @discardableResult
    static func popInstantiatingStoryboard() -> SwinjectStoryboard? {
        return storyboardStack.popLast()
    }

    class var isCreatingStoryboardReference: Bool {
        return referencingStoryboard != nil
    }

    static var referencingStoryboard: SwinjectStoryboard? {
        return storyboardStack.last
    }
#if os(iOS) || os(tvOS)
    class func createReferenced(name: String, bundle storyboardBundleOrNil: Bundle?) -> SwinjectStoryboard {
        if let container = referencingStoryboard?.container.value {
            return create(name: name, bundle: storyboardBundleOrNil, container: container)
        } else {
            return create(name: name, bundle: storyboardBundleOrNil)
        }
    }
#elseif os(OSX)
    class func createReferenced(name: NSStoryboard.Name, bundle storyboardBundleOrNil: Bundle?) -> SwinjectStoryboard {
        if let container = referencingStoryboard?.container.value {
            return create(name: name, bundle: storyboardBundleOrNil, container: container)
        } else {
            return create(name: name, bundle: storyboardBundleOrNil)
        }
    }
#endif
}

private var storyboardStack = [SwinjectStoryboard]()
