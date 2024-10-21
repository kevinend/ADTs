#scope_export 

main :: () {

    // Remember that all atoms share a single table!!!

    // Set the client procedure used to hash the strings.
    Atom.set_hash_procedure( atom_hash );

    {
        // Allocate an atom for the same static string
        a1 := Atom.allocate( "John" );
        a2 := Atom.allocate( "John" );
        
        assert( a1 == a2 );
        assert( Atom.get_content( a1 ) == "John" && Atom.get_content_length( a1 ) == 4 );
        assert( Atom.get_content( a2 ) == "John" && Atom.get_content_length( a2 ) == 4 );

    }

    {
        // Allocate an atom using the same string variable
        s1 := "Jacob";
        a1 := Atom.allocate( s1 );
        a2 := Atom.allocate( s1 );

        assert( a1 == a2 );
        assert( Atom.get_content( a1 ) == "Jacob" && Atom.get_content_length( a1 ) == 5 );
        assert( Atom.get_content( a2 ) == "Jacob" && Atom.get_content_length( a2 ) == 5 );

    }

    {
        // Allocate an atom using two different string variables
        s0: string = "Jingle";
        s1: string;
        s2: string;

        s1.data = alloc( 4 );
        assert( s1.data != null );
        s1.count = s0.count;
        memcpy( s1.data, s0.data, s0.count );

        s2.data = alloc( 4 );
        assert( s2.data != null );
        s2.count = s0.count;
        memcpy( s2.data, s0.data, s0.count );

        a1 := Atom.allocate( s1 );
        a2 := Atom.allocate( s2 );

        assert( s1.data != s2.data && a1 == a2 );

        assert( Atom.get_content( a1 ) == "Jingle" && Atom.get_content_length( a1 ) == 6 );
        assert( Atom.get_content( a2 ) == "Jingle" && Atom.get_content_length( a2 ) == 6 );
    }

    {
        // Allocate several atoms and make sure they are unique
        a1 := Atom.allocate( "Kevin" );
        a2 := Atom.allocate( "Joey"  );

        assert( a1 != a2 );
        assert( Atom.get_content( a1 ) == "Kevin" && Atom.get_content_length( a1 ) == 5 );
        assert( Atom.get_content( a2 ) == "Joey"  && Atom.get_content_length( a2 ) == 4 );
    }

    return;
}

#scope_file

#import "Basic";
Atom :: #import "Atom";

atom_hash :: ( s: string ) -> ( u64 ) {
    
    // Client function used by the atom module to hash our input strings.
    h: u64 = 0;
    for i: 0..s.count-1 {
        h += cast(u8) s[i];
    }

    return h;
}
