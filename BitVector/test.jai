#scope_export 

main :: () {

	x1 := BitVector.allocate( 8 );
	x2 := BitVector.allocate( 16 );

	c1 := BitVector.get_bit_count( x1 );
	c2 := BitVector.get_bit_count( x2 );
	print( "c1 == %, c2 == %\n", c1, c2 );

	BitVector.set_bit( x1, 3,  1 );
	BitVector.set_bit( x2, 4,  1 );
	BitVector.set_bit( x2, 15, 1 );
	

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
