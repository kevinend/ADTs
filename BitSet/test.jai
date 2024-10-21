#scope_export 

// TODO: Clean up this example file to test all exported procedures. 

main :: () {

	x1 := BitSet.allocate( 8 );
	x2 := BitSet.allocate( 16 );

	c1 := BitSet.get_bit_count( x1 );
	c2 := BitSet.get_bit_count( x2 );
	print( "c1 == %, c2 == %\n", c1, c2 );

	BitSet.update_bit( x1, 3,  1 );
	BitSet.update_bit( x2, 4,  1 );
	BitSet.update_bit( x2, 15, 1 );

	BitSet.set_bits( x1, 0, 7 );
	print( "Set all bits, what does it say is the count == %\n", BitSet.get_set_bit_count( x1 ) );

	BitSet.set_bits( x2, 0, 3 );
	print( "Set the first four bits in x2, what does it say the bitcount is %\n", BitSet.get_set_bit_count( x2 ) );

	BitSet.clear_bits( x1, 0, 7 );
	print( "Cleared all bits, what does it say is the count == %\n", BitSet.get_set_bit_count( x1 ) );

	BitSet.clear_bits( x2, 9, 15 );
	print( "Cleared bits in the high range, should have removed just one == %\n", BitSet.get_set_bit_count( x2 ) );

	{
		// equal bit arrays
		a := BitSet.allocate( 8 );
		b := BitSet.allocate( 8 );

		BitSet.update_bit( a, 0, 1 );
		BitSet.update_bit( a, 1, 1 );
		BitSet.update_bit( a, 2, 1 );
		BitSet.update_bit( a, 3, 1 );

		BitSet.set_bits( b, 0, 5 );

		print( "Are the bit vectors equal?\n" );
		if BitSet.equal( a, b ) {
			print( "Bit vectors are equal.\n" );
		}
		else { print( "Bit vectors are NOT equal.\n" ); }

		print( "Is A a subset of B?\n" );
		if BitSet.is_subset_of( a, b ) {
			print( "A is a subset of B\n" );
		}
		else { print( "A is not a subset of B.\n" ); }

		print( "Is B a subset of A?\n" );
		if BitSet.is_subset_of( b, a ) {
			print( "B is a subset of A.\n" );
		}
		else { print("B is a not a subset of A.\n"); }

		print( "Is A a proper subset of B?\n" );
		if BitSet.is_proper_subset_of( a, b ) {
			print( "A is a proper subset of B.\n" );
		}
		else { print( "A is NOT a proper subset of B\n" ); }

		print( "Is B a proper subset of A?\n" );
		if BitSet.is_proper_subset_of( b, a ) {
			print( "B is a proper subset of A.\n" );
		}
		else { print( "B is NOT a proper subset of A\n" ); }

	}

	sc1 := BitSet.get_set_bit_count( x1 );
	sc2 := BitSet.get_set_bit_count( x2 );

	print( "Set bit count == %, %\n", sc1, sc2 );

	b1 := BitSet.get_bit( x1, 1 );
	b2 := BitSet.get_bit( x2, 1 );

	print( "Get bit == %, %\n", b1, b2 );

	BitSet.deallocate( x1 );
	BitSet.deallocate( x2 );

	return;	
}

#scope_file
#import "Basic";
BitSet :: #import "BitSet";
