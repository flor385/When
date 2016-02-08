//
//  FSArrayObjectTransformer.h
//  ArrayPopupBinding
//
//  Created by Florijan Stamenkovic on 2009 08 13.
//  Copyright 2009 FloCo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 Defines a value transformer that converts arrays into
 a different object based on the size of the array.
 
 1. If the array is nil, nil is returned.
 2. If the array contains no items, nil is returned.
 3. If the array contains a single item, that item is returned.
 4. If the array contains multiple items, the whole array is
 wrapped into an FSArrayProxy which is then returned.
 
 The puropse of this value transformer is to allow the binding
 of arrays to for example popup selections. That way the binding
 is tolerant of arrays that represent multiple values, but allows
 the popup to be populated with other objects that are selectable,
 and will be wrapped in an array if selected.
 
 The FSArray proxy is used only so that a different description
 (NSString*) can be returned instead of NSArray's, which is not
 really user friendly.
 
 */


@interface FSArrayProxyObjectTransformer : NSValueTransformer {

}

@end





@interface FSArrayProxy : NSObject {
	
	NSArray* array;
}

@property(readonly) NSArray* array;

+(void)setDescription:(NSString*)aDescription;
+(NSString*)description;

-(id)initWithArray:(NSArray*)anArray;

@end