#scope_export

main :: () {

	names: Stack(string);

	push( *names, "Jingle" );
	push( *names, "Jacob"  );
	push( *names, "John" );

	print( "Count == %\n", count( *names ) );

	// Empty the stack
	while !is_empty( *names ) {
		print( "Count == %\n, Name == %\n", pop( *names ), count( *names ) );	
	}

	// Add new entries onto the stack
	push( *names, "Schmidt" );
	push( *names, "Heimer" );

	// Empty the new stack elements
	while !is_empty( *names ) {
		print( "Count == %\n, Name == %\n", pop( *names ), count( *names ) );	
	}

	// Stack is empty, crash.
	pop( *names ); 
}

#scope_file

#import "Basic";
#import "Stack";
