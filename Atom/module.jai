// File implements an Atom data structure.
// Atoms are containers that point to an arbitrary sequence of bytes.
// There is only a single canonical reference of an Atom within an application which means two Atoms are equal if they point to the same location.
//
// Sometimes the Atom datatype refers to an opaque key that is encoded in an unsigned integer type such as in the Win32 API.
// This is obviously done for security reasons not to leak kernel address space to end-users/clients. These are often referred to as 'Handles'
// in Game Development circles.
//
// Atom here is used in how David R. Hanson describes them in the book C Interfaces and Implementations where it is an atomic piece of data
// that serves as a canonical reference during program execution. As an example, instead of storing the string "Hello" 50 different times you create the "Hello" atom
// and all references point to the single atom containing the string "Hello". Each "Hello" character string has been reduced to a simple pointer to one instance of "Hello".

#scope_export

ATOM_TABLE_SIZE :: 256;

Atom :: struct {
	content: string;
	next:  	 *Atom;
}

buckets: [ATOM_TABLE_SIZE] *Atom;

atom_hash: ( s: string ) -> ( u64 );  

set_hash_procedure :: ( procedure: (string) -> u64 ) {	

	// Bind the user-supplied hash procedure used to hash the input string to a bucket index.

	atom_hash = procedure;
	return;
}

new :: ( s: string ) -> ( atom: *Atom ) {

	// Copies the input string into a new Atom and returns a pointer to that Atom.
	// Atom's are case sensitive so "Test" and "test" return two different Atoms.

	assert( s.count > 0, "Cannot create Atom whose length is zero." );
	assert( atom_hash != null, "Hash procedure MUST be set by the client before creating an Atom." );
	
	h := atom_hash( s );
	h = h % ATOM_TABLE_SIZE;


	found := false;
	atom := buckets[h];
	while atom != null {
		if atom.content == s {
			found = true;
			break;
		}
		atom = atom.next;
	}

	if !found {
		atom = alloc( size_of(Atom) + s.count ); // allocate string immediately following the atom structure
		assert( atom != null );

		atom.content.data  = cast(*u8)(atom + 1); 	// advance past the atom structure
		atom.content.count = s.count;
		memcpy( atom.content.data, s.data, s.count );

		atom.next = buckets[h];
		buckets[h] = atom;
	}

	return atom;	
}

get_content :: ( atom: *Atom ) -> ( s: string ) {

	// Returns the string data that is stored within the Atom pointed to by the argument.

	assert( atom != null );
	return atom.content;
}

get_length :: ( atom: *Atom ) -> ( c: int ) {

	// Returns the length of the string contained within the atom.

	assert( atom != null );
	return atom.content.count;
}

#scope_file
#import "Basic";



