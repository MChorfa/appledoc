//
//  GBTokenizer.h
//  appledoc
//
//  Created by Tomaz Kragelj on 25.7.10.
//  Copyright (C) 2010, Gentle Bytes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ParseKit.h"

/** Provides common methods for tokenizing input source strings.
 
 Main responsibilities of the class are to split the given source string into tokens and provide simple methods for iterating over the tokens stream. It works upon ParseKit framework's `PKTokenizer`. As different parsers require different tokenizers and setups, the class itself doesn't create a tokenizer, but instead requires the client to provide one. Here's an example of simple usage:
 
	NSString *input = ...
	PKTokenizer *worker = [PKTokenizer tokenizerWithString:input];
	GBTokenizer *tokenizer = [[GBTokenizer allow] initWithTokenizer:worker];
	while (![tokenizer eof]) {
		NSLog(@"%@", [tokenizer currentToken]);
		[tokenizer consume:1];
	}
 
 This example simply iterates over all tokens and prints each one to the log. If you want to parse a block of input with known start and/or end token, you can use one of the block consuming methods instead.
 
 To make comments parsing simpler, `GBTokenizer` automatically enables comment reporting to the underlying `PKTokenizer`, however to prevent higher level parsers dealing with complexity of comments, any lookahead and consume method doesn't report them. Instead these methods skip all comment tokens, however they do make them accessible through properties, so if the client wants to check whether there's any comment associated with current token, it can simply ask by sending `lastCommentString`. Additionally, the client can also get the value of a comment just before the last one by sending `previousCommentString` - this can be used to get any method section comments which aren't associated with any element. If there is no "stand-alone" comment before the last one, `previousCommentString` returns `nil`. Both value are automatically cleared when another non-comment token is consumed, so make sure to read it before consuming any further token! `GBTokenizer` goes even further when dealing with comments - it automatically groups single line comments into a single comment group and removes all prefixes and suffixes.
 */
@interface GBTokenizer : NSObject

///---------------------------------------------------------------------------------------
/// @name Initialization & disposal
///---------------------------------------------------------------------------------------

/** Returns initialized autoreleased instance using the given source `PKTokenizer`.
 
 @param tokenizer The underlying (worker) tokenizer to use for actual splitting.
 @return Returns initialized instance or `nil` if failed.
 @exception NSException Thrown if the given tokenizer is `nil`.
 */
+ (id)tokenizerWithSource:(PKTokenizer *)tokenizer;

/** Initializes tokenizer with the given source `PKTokenizer`.
 
 This is designated initializer.
 
 @param tokenizer The underlying (worker) tokenizer to use for actual splitting.
 @return Returns initialized instance or `nil` if failed.
 @exception NSException Thrown if the given tokenizer is `nil`.
 */
- (id)initWithSourceTokenizer:(PKTokenizer *)tokenizer;

///---------------------------------------------------------------------------------------
/// @name Tokenizing handling
///---------------------------------------------------------------------------------------

/** Returns the current token.
 
 @see consume
 @see lookahead
 */
- (PKToken *)currentToken;

/** Returns the token by looking ahead the given number of tokens from current position.
 
 If offset "points" within a valid token, the token is returned, otherwise EOF token is	returned. Note that this method automatically skips any comment tokens and only counts actual language tokens.
 
 @param offset The offset from the current position.
 @return Returns the token at the given offset or EOF token if offset point after EOF.
 @see consume
 */
- (PKToken *)lookahead:(NSUInteger)offset;

/** Consumes the given ammoun of tokens, starting at the current position.
 
 This effectively "moves" `currentToken` to the new position. If EOF is reached before consuming the given ammount of tokens, consuming stops at the end of stream and `currentToken` returns EOF token. If comment tokens are detected while consuming, they are not counted and consuming count continues with actual language tokens. However if there is a comment just before the next current token (i.e. after the last consumed token), the comment data is saved and is available through `lastCommentString`. Otherwise last comment data is cleared, even if a comment was detected in between.
 
 @param count The number of tokens to consume.
 @see lastCommentString
 */
- (void)consume:(NSUInteger)count;

/** Enumerates and consumes all tokens starting at current token up until the given end token is detected.
 
 For each token, the given block is called which gives client a chance to inspect and handle tokens. End token is not reported and is automatically consumed after all previous tokens are reported. Sending this message is equivalent to sending `consumeFrom:to:usingBlock:` and passing `nil` for start token. Also read `consume:` documentation to understand how comments are dealt with.
 
 @param end Ending token.
 @param block The block to be called for each token.
 @exception NSException Thrown if the given end token is `nil`.
 @see lastCommentString
 */
- (void)consumeTo:(NSString *)end usingBlock:(void (^)(PKToken *token, BOOL *consume, BOOL *stop))block;

/** Enumerates and consumes all tokens starting at current token up until the given end token is detected.
 
 For each token, the given block is called which gives client a chance to inspect and handle tokens. If start token is given and current token matches it, the token is consumed without reporting it to block. However if the token doesn't match, the method returns immediately without doint anything. End token is also not reported and is also automatically consumed after all previous tokens are reported. Also read `consume:` documentation to understand how comments are dealt with.
 
 @param start Optional starting token or `nil`.
 @param end Ending token.
 @param block The block to be called for each token.
 @exception NSException Thrown if the given end token is `nil`.
 @see lastCommentString
 */
- (void)consumeFrom:(NSString *)start to:(NSString *)end usingBlock:(void (^)(PKToken *token, BOOL *consume, BOOL *stop))block;

/** Specifies whether we're at EOF.
 
 @return Returns `YES` if we're at EOF, `NO` otherwise.
 */
- (BOOL)eof;

///---------------------------------------------------------------------------------------
/// @name Comments handling
///---------------------------------------------------------------------------------------

/** Returns the last comment string or `nil` if comment is not available.
 
 This returns the whole last comment string, without prefixes or suffixes. To optimize things a bit, the actual comment string value is prepared on the fly, as you send the message, so it's only handled if needed. As creating comment string adds some computing overhead, you should cache returned value if possible.
 
 If there's no comment available for current token, `nil` is returned.
 
 @see previousCommentString
 */
@property (readonly) NSString *lastCommentString;

/** Returns "stand-alone" comment found immediately before the comment returned from `lastCommentString`.
 
 Previous comment is a "stand-alon" comment which is found immediately before `lastCommentString` but isn't associated with any language element. These are ussually used to provide meta data and other instructions for formatting or grouping of "normal" comments returned with `lastCommentString`. The value should be used at the same time as `lastCommentString` as it is automatically cleared on the next consuming! If there's no stand-alone comment immediately before last comment, the value returned is `nil`.
 
 This returns the whole previous comment string, without prefixes or suffixes. To optimize things a bit, the actual comment string value is prepared on the fly, as you send the message, so it's only handled if needed. As creating comment string adds some computing overhead, you should cache returned value if possible.
 
 @see lastCommentString
 */
@property (readonly) NSString *previousCommentString;

@end