//
//  InjectionVerifiable.swift
//  Swinject
//
//  Created by Jakub Vaňo on 28/10/16.
//  Copyright © 2016 Swinject Contributors. All rights reserved.
//

@objc internal protocol InjectionVerifiable: AnyObject {
    var wasInjected: Bool { get set }
}
