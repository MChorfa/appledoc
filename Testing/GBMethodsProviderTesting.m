//
//  GBMethodsProviderTesting.m
//  appledoc
//
//  Created by Tomaz Kragelj on 26.7.10.
//  Copyright (C) 2010 Gentle Bytes. All rights reserved.
//

#import "GBTestObjectsRegistry.h"
#import "GBMethodsProvider.h"

@interface GBMethodsProviderTesting : GHTestCase
@end

@implementation GBMethodsProviderTesting

#pragma mark Method registration testing

- (void)testRegisterMethod_shouldAddMethodToList {
	// setup
	GBMethodsProvider *provider = [[GBMethodsProvider alloc] initWithParentObject:self];
	GBMethodData *method = [GBTestObjectsRegistry instanceMethodWithNames:@"method", nil];
	// execute
	[provider registerMethod:method];
	// verify
	assertThatInteger([provider.methods count], equalToInteger(1));
	assertThat([[provider.methods objectAtIndex:0] methodSelector], is(@"method:"));
}

- (void)testRegisterMethod_shouldSetParentObject {
	// setup
	GBMethodsProvider *provider = [[GBMethodsProvider alloc] initWithParentObject:self];
	GBMethodData *method = [GBTestObjectsRegistry instanceMethodWithNames:@"method", nil];
	// execute
	[provider registerMethod:method];
	// verify
	assertThat(method.parentObject, is(self));
}

- (void)testRegisterMethod_shouldIgnoreSameInstance {
	// setup
	GBMethodsProvider *provider = [[GBMethodsProvider alloc] initWithParentObject:self];
	GBMethodData *method = [GBTestObjectsRegistry instanceMethodWithNames:@"method", nil];
	// execute
	[provider registerMethod:method];
	[provider registerMethod:method];
	// verify
	assertThatInteger([provider.methods count], equalToInteger(1));
}

- (void)testRegisterMethod_shouldAllowSameSelectorIfDifferentType {
	// setup
	GBMethodsProvider *provider = [[GBMethodsProvider alloc] initWithParentObject:self];
	GBMethodData *method1 = [GBTestObjectsRegistry instanceMethodWithNames:@"method", nil];
	GBMethodData *method2 = [GBTestObjectsRegistry classMethodWithNames:@"method", nil];
	// execute
	[provider registerMethod:method1];
	[provider registerMethod:method2];
	// verify
	assertThatInteger([provider.methods count], equalToInteger(2));
	assertThat([[provider.methods objectAtIndex:0] methodSelector], is(@"method:"));
	assertThatInteger([[provider.methods objectAtIndex:0] methodType], equalToInteger(GBMethodTypeInstance));
	assertThat([[provider.methods objectAtIndex:1] methodSelector], is(@"method:"));
	assertThatInteger([[provider.methods objectAtIndex:1] methodType], equalToInteger(GBMethodTypeClass));
}

- (void)testRegisterMethod_shouldMapMethodBySelectorToInstanceMethodRegardlessOfRegistrationOrder {
	// setup
	GBMethodsProvider *provider1 = [[GBMethodsProvider alloc] initWithParentObject:self];
	GBMethodsProvider *provider2 = [[GBMethodsProvider alloc] initWithParentObject:self];
	GBMethodData *method1 = [GBTestObjectsRegistry instanceMethodWithNames:@"method", nil];
	GBMethodData *method2 = [GBTestObjectsRegistry classMethodWithNames:@"method", nil];
	// execute
	[provider1 registerMethod:method1];
	[provider1 registerMethod:method2];
	[provider2 registerMethod:method2];
	[provider2 registerMethod:method1];
	// verify
	assertThat([provider1 methodBySelector:@"method:"], is(method1));
	assertThat([provider2 methodBySelector:@"method:"], is(method1));
}

- (void)testRegisterMethod_shouldMapMethodBySelectorToPropertyRegardlessOfRegistrationOrder {
	// setup
	GBMethodsProvider *provider1 = [[GBMethodsProvider alloc] initWithParentObject:self];
	GBMethodsProvider *provider2 = [[GBMethodsProvider alloc] initWithParentObject:self];
	GBMethodData *method1 = [GBTestObjectsRegistry propertyMethodWithArgument:@"method"];
	GBMethodData *method2 = [GBTestObjectsRegistry classMethodWithArguments:[GBMethodArgument methodArgumentWithName:@"method"],  nil];
	// execute
	[provider1 registerMethod:method1];
	[provider1 registerMethod:method2];
	[provider2 registerMethod:method2];
	[provider2 registerMethod:method1];
	// verify
	assertThat([provider1 methodBySelector:@"method"], is(method1));
	assertThat([provider2 methodBySelector:@"method"], is(method1));
}

- (void)testRegisterMethod_shouldMergeDifferentInstanceWithSameName {
	// setup
	GBMethodType expectedType = GBMethodTypeInstance;
	GBMethodsProvider *provider = [[GBMethodsProvider alloc] initWithParentObject:self];
	GBMethodData *source = [GBTestObjectsRegistry instanceMethodWithNames:@"method", nil];
	OCMockObject *destination = [OCMockObject niceMockForClass:[GBMethodData class]];
	[[[destination stub] andReturn:@"method:"] methodSelector];
	[[[destination stub] andReturnValue:[NSValue value:&expectedType withObjCType:@encode(GBMethodType)]] methodType];
	[[destination expect] mergeDataFromObject:source];
	[provider registerMethod:(GBMethodData *)destination];
	// execute
	[provider registerMethod:source];
	// verify
	[destination verify];
}

#pragma mark Sections and methods handling

- (void)testRegisterSection_shouldCreateSectionWithGivenName {
	// setup
	GBMethodsProvider *provider = [[GBMethodsProvider alloc] initWithParentObject:self];
	// execute
	GBMethodSectionData *section = [provider registerSection:@"section"];
	// verify
	assertThatInteger([[provider sections] count], equalToInteger(1));
	assertThat(section.sectionName, is(@"section"));
}

- (void)testRegisterMethod_shouldAddMethodToLastSection {
	// setup
	GBMethodsProvider *provider = [[GBMethodsProvider alloc] initWithParentObject:self];
	GBMethodData *method = [GBTestObjectsRegistry instanceMethodWithNames:@"method", nil];
	GBMethodSectionData *section1 = [provider registerSection:@"section"];
	GBMethodSectionData *section2 = [provider registerSection:@"section"];
	// execute
	[provider registerMethod:method];
	// verify
	assertThatInteger([[section1 methods] count], equalToInteger(0));
	assertThatInteger([[section2 methods] count], equalToInteger(1));
	assertThat([section2.methods objectAtIndex:0], is(method));
}

- (void)testRegisterMethod_shouldCreateDefaultSectionIfNoneExists {
	// setup
	GBMethodsProvider *provider = [[GBMethodsProvider alloc] initWithParentObject:self];
	GBMethodData *method = [GBTestObjectsRegistry instanceMethodWithNames:@"method", nil];
	// execute
	[provider registerMethod:method];
	// verify
	assertThatInteger([[provider sections] count], equalToInteger(1));
	GBMethodSectionData *section = [[provider sections] objectAtIndex:0];
	assertThatInteger([[section methods] count], equalToInteger(1));
	assertThat([section.methods objectAtIndex:0], is(method));
}

#pragma mark Helper methods testing

- (void)testMethodBySelector_shouldReturnProperInstanceOrNil {
	// setup
	GBMethodsProvider *provider = [[GBMethodsProvider alloc] initWithParentObject:self];
	GBMethodData *method1 = [GBTestObjectsRegistry instanceMethodWithNames:@"method1", nil];
	GBMethodData *method2 = [GBTestObjectsRegistry instanceMethodWithNames:@"method", @"arg", nil];
	GBMethodData *method3 = [GBTestObjectsRegistry classMethodWithNames:@"method3", nil];
	GBMethodData *property = [GBTestObjectsRegistry propertyMethodWithArgument:@"name"];
	[provider registerMethod:method1];
	[provider registerMethod:method2];
	[provider registerMethod:method3];
	[provider registerMethod:property];
	// execute & verify
	assertThat([provider methodBySelector:@"method1:"], is(method1));
	assertThat([provider methodBySelector:@"method:arg:"], is(method2));
	assertThat([provider methodBySelector:@"method3:"], is(method3));
	assertThat([provider methodBySelector:@"name"], is(property));
	assertThat([provider methodBySelector:@"some:other:"], is(nil));
	assertThat([provider methodBySelector:@"single"], is(nil));
	assertThat([provider methodBySelector:@""], is(nil));
	assertThat([provider methodBySelector:nil], is(nil));
}

- (void)testMethodBySelector_prefersInstanceMethodToClassMethod {
	// setup
	GBMethodsProvider *provider = [[GBMethodsProvider alloc] initWithParentObject:self];
	GBMethodData *method1 = [GBTestObjectsRegistry instanceMethodWithNames:@"method", nil];
	GBMethodData *method2 = [GBTestObjectsRegistry classMethodWithNames:@"method", nil];
	[provider registerMethod:method1];
	[provider registerMethod:method2];
	// execute & verify
	assertThat([provider methodBySelector:@"method:"], is(method1));
}

- (void)testMethodBySelector_prefersPropertyToClassMethod {
	// setup
	GBMethodsProvider *provider = [[GBMethodsProvider alloc] initWithParentObject:self];
	GBMethodData *method1 = [GBTestObjectsRegistry propertyMethodWithArgument:@"method"];
	GBMethodData *method2 = [GBTestObjectsRegistry classMethodWithArguments:[GBMethodArgument methodArgumentWithName:@"method"], nil];
	[provider registerMethod:method1];
	[provider registerMethod:method2];
	// execute & verify
	assertThat([provider methodBySelector:@"method"], is(method1));
}

#pragma mark Method merging testing

- (void)testMergeDataFromObjectsProvider_shouldMergeAllDifferentMethods {
	// setup
	GBMethodsProvider *original = [[GBMethodsProvider alloc] initWithParentObject:self];
	[original registerMethod:[GBTestObjectsRegistry instanceMethodWithNames:@"m1", nil]];
	[original registerMethod:[GBTestObjectsRegistry instanceMethodWithNames:@"m2", nil]];
	GBMethodsProvider *source = [[GBMethodsProvider alloc] initWithParentObject:self];
	[source registerMethod:[GBTestObjectsRegistry instanceMethodWithNames:@"m1", nil]];
	[source registerMethod:[GBTestObjectsRegistry instanceMethodWithNames:@"m3", nil]];
	// execute
	[original mergeDataFromMethodsProvider:source];
	// verify - only basic testing here, details at GBMethodDataTesting!
	NSArray *methods = [original methods];
	assertThatInteger([methods count], equalToInteger(3));
	assertThat([[methods objectAtIndex:0] methodSelector], is(@"m1:"));
	assertThat([[methods objectAtIndex:1] methodSelector], is(@"m2:"));
	assertThat([[methods objectAtIndex:2] methodSelector], is(@"m3:"));
}

- (void)testMergeDataFromObjectsProvider_shouldPreserveSourceData {
	// setup
	GBMethodsProvider *original = [[GBMethodsProvider alloc] initWithParentObject:self];
	[original registerMethod:[GBTestObjectsRegistry instanceMethodWithNames:@"m1", nil]];
	[original registerMethod:[GBTestObjectsRegistry instanceMethodWithNames:@"m2", nil]];
	GBMethodsProvider *source = [[GBMethodsProvider alloc] initWithParentObject:self];
	[source registerMethod:[GBTestObjectsRegistry instanceMethodWithNames:@"m1", nil]];
	[source registerMethod:[GBTestObjectsRegistry instanceMethodWithNames:@"m3", nil]];
	// execute
	[original mergeDataFromMethodsProvider:source];
	// verify - only basic testing here, details at GBMethodDataTesting!
	NSArray *methods = [source methods];
	assertThatInteger([methods count], equalToInteger(2));
	assertThat([[methods objectAtIndex:0] methodSelector], is(@"m1:"));
	assertThat([[methods objectAtIndex:1] methodSelector], is(@"m3:"));
}

@end