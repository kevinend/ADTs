#scope_export

main :: () {

	names: Stack(string);

	push( *names, "Kevin" );
	push( *names, "Joey"  );
	push( *names, "Slurpies" );

	print( "Count == %\n", count( *names ) );

	while !is_empty( *names ) {
		print( "%\n", pop( *names ) );	
		print( "Count == %\n", count( *names ) );

	}

	// Stack is empty, crash.
	pop( *names ); 
}

#scope_file

#import "Basic";
#import "Stack";
