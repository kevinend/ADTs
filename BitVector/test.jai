#scope_export 

main :: () {

	x1 := BitVector.allocate( 8 );
	x2 := BitVector.allocate( 16 );

	c1 := BitVector.get_bit_count( x1 );
	c2 := BitVector.get_bit_count( x2 );
	print( "c1 == %, c2 == %\n", c1, c2 );

	BitVector.update_bit( x1, 3,  1 );
	BitVector.update_bit( x2, 4,  1 );
	BitVector.update_bit( x2, 15, 1 );

	BitVector.set_bits( x1, 0, 7 );
	print( "Set all bits, what does it say is the count == %\n", BitVector.get_set_bit_count( x1 ) );

	BitVector.set_bits( x2, 0, 3 );
	print( "Set the first four bits in x2, what does it say the bitcount is %\n", BitVector.get_set_bit_count( x2 ) );

	BitVector.clear_bits( x1, 0, 7 );
	print( "Cleared all bits, what does it say is the count == %\n", BitVector.get_set_bit_count( x1 ) );

	BitVector.clear_bits( x2, 9, 15 );
	print( "Cleared bits in the high range, should have removed just one == %\n", BitVector.get_set_bit_count( x2 ) );



	
	// Get total bytes

	print( "Number of bytes == %, %\n", x1.num_bytes, x2.num_bytes );


	sc1 := BitVector.get_set_bit_count( x1 );
	sc2 := BitVector.get_set_bit_count( x2 );

	print( "Set bit count == %, %\n", sc1, sc2 );

	b1 := BitVector.get_bit( x1, 1 );
	b2 := BitVector.get_bit( x2, 1 );

	print( "Get bit == %, %\n", b1, b2 );

	BitVector.deallocate( x1 );
	BitVector.deallocate( x2 );

	return;	
}

#scope_file
#import "Basic";
BitVector :: #import "BitVector";
