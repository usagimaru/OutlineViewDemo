//
//  NSView.swift
//
//  Copyright © 2018 usagimaru.
//

import Cocoa

@objc extension NSView {
	
	/// ヒエラルキーの先祖に parentViewClass がいればそれを返す
	@nonobjc func superview<T: NSView>(whichIs parentViewClass: T.Type) -> T? {
		func check(_ theView: NSView?) -> NSView? {
			if let superview = theView?.superview {
				if superview.isKind(of: parentViewClass) {
					return superview
				}
				return check(superview)
			}
			return nil
		}
		
		return check(self) as? T
	}
	
}
