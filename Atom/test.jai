#scope_export 


atom_hash :: ( s: string ) -> ( u64 ) {
	
	// Client function used by the atom module to hash our input strings.
	h: u64 = 0;
	for i: 0..s.count-1 {
		h += cast(u8) s[i];
	}

	return h;
}

main :: () {

	// Set the hash procedure for our Atoms
	Atom.set_hash_procedure( atom_hash );

	// Allocate two new atoms to add to the atom table	
	a1 := Atom.new( "John" );
	a2 := Atom.new( "Jacob"  );
	a3 := Atom.new( "Jingle" );

	// Attempt to create two new atoms, these should just point to our previous atoms
	a11 := Atom.new( "John" );
	a21 := Atom.new( "Jacob" );

	// Check that atoms that have the same string contents point to the same atom
	if a1 != a11 {
		print( "Atoms should point to the same address.\n" );
		print( "a1 address == %\n", a1 );
		print( "a3 address == %\n", a11 );

	}

	if a2 != a21 {
		print( "Atoms should point to the same address.\n" );
		print( "a1 address == %\n", a2 );
		print( "a3 address == %\n", a21 );
	}

	// Retrieve the contents of the atom (the strings)	
	print( "a1  value == %, content == %, Length == %\n", Atom.get_content( a1 ),  Atom.get_length( a1 ) );
	print( "a11 content == %, Length == %\n", Atom.get_content( a11 ), Atom.get_length( a11 ) );
	print( "a2  content == %, Length == %\n", Atom.get_content( a2 ),  Atom.get_length( a2 ) );
	print( "a21 content == %, Length == %\n", Atom.get_content( a21 ), Atom.get_length( a21 ) );
	print( "a3  content == %, Length == %\n", Atom.get_content( a3 ),  Atom.get_length( a3 ) );


	return;
}

#scope_file

#import "Basic";
Atom :: #import "Atom";
