#scope_export

main :: () {

    {
        // Allocate a stack of integers.
        numbers := Stack.new( int );
        Stack.push( numbers, 3 );
        Stack.push( numbers, 2 );
        Stack.push( numbers, 1 );

        assert( Stack.pop( numbers ) == 1 && Stack.count( numbers ) == 2 );
        assert( Stack.pop( numbers ) == 2 && Stack.count( numbers ) == 1 );
        assert( Stack.pop( numbers ) == 3 && Stack.count( numbers ) == 0 );

        Stack.deallocate( numbers );
    }

    {
        // Allocate a stack of strings
        names := Stack.new( string );
        Stack.push( names, "Heimer-Schmidt" );
        Stack.push( names, "Jingle" ); 
        Stack.push( names, "Jacob" ); 
        Stack.push( names, "John" ); 

        assert( Stack.count( names ) == 4 );

        while !Stack.is_empty( names ) {  Stack.pop( names ); }

        assert( Stack.is_empty( names ) == true );
        assert( Stack.count( names ) == 0 );

        Stack.deallocate( names );
    }
}

#scope_file

#import "Basic";
Stack :: #import "Stack";
