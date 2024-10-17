#scope_export

main :: () {

	names: Stack(string);
	push( *names, "Kevin" );
	push( *names, "Joey"  );
	push( *names, "Slurpies" );

	print( "Count == %\n", count( *names ) );

	while !empty( *names ) {
		print( "%\n", pop( *names ) );	
		print( "Count == %\n", count( *names ) );

	}

	pop( *names ); // crash-o
}

#scope_file

#import "Basic";
#load "./module.jai";
