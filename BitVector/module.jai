// File implements a Bit Vector ADT, which is "TODO"

#scope_export

BitVector :: struct {
	num_bits:  	    int;
	num_bytes:      int;
	bytes:   		*u8;
	bytes_as_u32:  *u32;
}


allocate :: ( num_bits: int ) -> ( bit_vector: *BitVector ) {
	
	// Allocates a new BitVector instance with 'num_bits' storage space.
	// The new bit-space is set to zeroes.
	//
	// Allocation of space for bits must be a multiple of a u32 otherwise when you address blocks of bits using '.bytes_as_u32' you could read invalid memory!
	// Example: num_bits  = 33,
	//          boundary  = 32
	//          multiples = 2 (64/32)
	//          allocated_space = 2 * 32-bit == 64-bits 


	assert( num_bits > 0 );

	bit_vector := cast(*BitVector)alloc( size_of(BitVector) );
	assert( bit_vector != null );

	bit_vector.num_bits = num_bits;
	
	boundary  := 8 * size_of(u32);
	multiples := (bit_vector.num_bits + (boundary-1)) / boundary;

	bit_vector.num_bytes = multiples * size_of(u32);

	bit_vector.bytes_as_u32 = alloc( bit_vector.num_bytes );
	assert( bit_vector.bytes_as_u32 != null );
	memset( bit_vector.bytes_as_u32, 0, multiples * size_of(u32) );

	bit_vector.bytes = cast(*u8)bit_vector.bytes_as_u32;

	return bit_vector;	
}

deallocate :: ( bit_vector: *BitVector ) {

	// Free the memory associated with the bit_vector, then free the bit_vector instance.
	
	assert( bit_vector != null );
	assert( bit_vector.bytes_as_u32 != null );

	free( bit_vector.bytes_as_u32 ); // implicitly frees the memory associated with bit_vector.bytes
	free( bit_vector );

	return;
}

get_bit_count :: ( bit_vector: *BitVector ) -> ( num_bits: int ) {
	
	// Return the number of bits managed by the BitVector instance.
	assert( bit_vector != null );
	return bit_vector.num_bits;
}

get_bit :: ( bit_vector: *BitVector, n: int ) -> ( bit: int ) {

	// Returns the value of the n-th bit in the BitVector instance.
	
	assert( bit_vector != null );
	assert( n >= 0, "Can't find a bit whose index is less than 0." );
	assert( n <= bit_vector.num_bits, "Bit index exceeds the total number of bits in the bit vector." );

	byte := (bit_vector.bytes + n/8).*;
	return (byte >> n%8) & 1;
}

set_bit :: ( bit_vector: *BitVector, n: int, bit_value: int ) -> ( previous_bit_value: int ) {

	// Sets bit 'n' in the vector with the value supplied by the caller.
	// Returns the previous bit value set at that bit index to the caller.

	assert( bit_vector != null );
	assert( n >= 0, "Can't find a bit whose index is less than 0." );
	assert( n <= bit_vector.num_bits, "Bit index exceeds the total number of bits in the bit vector." );
	assert( bit_value == 1 || bit_value == 0, "Supplied bit value must be a one (1) or a zero (0)." );

	previous_bit_value := get_bit( bit_vector, n );
	if ( bit_value == 1 ) {
		// Bit at the index is either 0 or 1 so we can OR with a 1 and always get the '1' we want in that bit
		bit_vector.bytes[n/8] |= cast(u8) (1 << (n%8));
	}
	else {
		// Bit at the index is either a 0 or 1 so we can AND with a 0 and always get the '0' we want in that bit
		// To not clear out the other bits we set 1 in the n-th bit place then take the complement and AND that together with the target byte which
		// will set the n-th bit to zero.
		bit_vector.bytes[n/8] &= cast(u8) ~(1 << n%8);
	}

	return previous_bit_value;
}

get_set_bit_count :: ( bit_vector: *BitVector ) -> ( num_set_bits: int ) {

	// Returns the count of set bits (bits with a value of 1) in the BitVector instance.
	// 
	// David R Hanson uses a lookup table by splitting each byte into nibbles and doing a lookup to get the number of bits set in each nibble, summing across nibbles.
	// Typically I would have just iterated over the bytes and checked every bit using shifts and ANDs. Going to try his approach.

	nibbles_to_set_bits: [16] u8 = .[
		 0   // 0
		,1   // 1
		,1   // 2
		,2   // 3
		,1   // 4
		,2   // 5
		,2   // 6
		,3   // 7 (4 + 2 + 1)
		,1   // 8
		,2   // 9
		,2   // 10
		,3   // 11
		,2	 // 12
		,3   // 13
		,3   // 14
		,4   // 15
	];

	assert( bit_vector != null );

	set_bit_count := 0;
	for i: 0..bit_vector.num_bytes-1 {

		byte := (bit_vector.bytes + i).*;	

		hi_nibble := nibbles_to_set_bits[byte & 0x0F];
		lo_nibble := nibbles_to_set_bits[byte >> 4  ];
		
		set_bit_count += hi_nibble + lo_nibble;
	}

	return set_bit_count;
}







#scope_file
#import "Basic";

