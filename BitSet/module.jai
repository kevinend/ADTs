// File implements a Bit Vector
// The user specifies the number of bits contained within the BitSet and the library exposes methods to manipulate those bits.
// Note: The Bit Vector represents the user-supplied number of bits which are accessed/manipulated based on zero-indexing. Therefore the valid
//       range for a Bit Vector containing n-bits is [0,n-1]. A 64-bit vector has valid indices [0,63].

// TODO: Introduce a local MemoryAddress type that bytes: MemoryAddress bytes.as_u8, bytes_as_u32, etc..
// TODO: Implement, union, intersection, difference and then be done with this module! good lord this is a long one
// TODO: Then clean this up as well, MemoryAddress type and some renaming of things to make it easier to read

#scope_export

BitSet :: struct {
	num_bits:  	    int;
	num_bytes:      int;
	bytes:   		*u8;
	bytes_as_u32:  *u32;
}


allocate :: ( num_bits: int ) -> ( bit_vector: *BitSet ) {
	
	// Allocates a new BitSet instance with 'num_bits' storage space.
	// The new bit-space is set to zeroes.
	//
	// Allocation of space for bits must be a multiple of a u32 otherwise when you address blocks of bits using '.bytes_as_u32' you could read invalid memory!
	// Example: num_bits  = 33,
	//          boundary  = 32
	//          multiples = 2 (64/32)
	//          allocated_space = 2 * 32-bit == 64-bits 


	assert( num_bits > 0 );

	bit_vector := cast(*BitSet)alloc( size_of(BitSet) );
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

deallocate :: ( bit_vector: *BitSet ) {

	// Free the memory associated with the bit_vector, then free the bit_vector instance.
	
	assert( bit_vector != null );
	assert( bit_vector.bytes_as_u32 != null );

	free( bit_vector.bytes_as_u32 ); // implicitly frees the memory associated with bit_vector.bytes
	free( bit_vector );

	return;
}

get_bit_count :: ( bit_vector: *BitSet ) -> ( num_bits: int ) {
	
	// Return the number of bits managed by the BitSet instance.
	assert( bit_vector != null );
	return bit_vector.num_bits;
}

get_bit :: ( bit_vector: *BitSet, n: int ) -> ( bit: int ) {

	// Returns the value of the n-th bit in the BitSet instance.
	
	assert( bit_vector != null );
	assert( n >= 0, "Can't find a bit whose index is less than 0." );
	assert( n < bit_vector.num_bits, "Bit index exceeds the total number of bits in the bit vector." );

	byte := (bit_vector.bytes + n/8).*;
	return (byte >> n%8) & 1;
}

update_bit :: ( bit_vector: *BitSet, n: int, bit_value: int ) -> ( previous_bit_value: int ) {

	// Updates the bit_value supplied by the user into the n-th bit in the bit-vector.
	// Returns the previous bit value of the n-th bit.

	assert( bit_vector != null );
	assert( n >= 0, "Can't find a bit whose index is less than 0." );
	assert( n <  bit_vector.num_bits, "Bit index exceeds the total number of bits in the bit vector." );
	assert( bit_value == 1 || bit_value == 0, "Supplied bit value must be a one (1) or a zero (0)." );

	previous_bit_value := get_bit( bit_vector, n );
	if ( bit_value == 1 ) {
		// Bit at the index is either 0 or 1 so we can OR with a 1 and always get the '1' we want in that bit
		bit_vector.bytes[n/8] |= cast(u8) (1 << (n%8));
	}
	else {
		// Bit at the index is either a 0 or 1 so we can AND with a 0 and always get the '0' we want in that bit.
		// To avoid clearing out the other bits, we set 1 in the n-th bit place then take the complement and AND that together with the target byte which will set the n-th bit to zero.
	
		// Wont complie: bit_vector.bytes[n/8] &= cast(s8) ~(1 << (n%8));
		// complement will generate a signed u8 that can't be put in the u8 location; aliasing the byte and applying the mask.
		byte   := cast(*s8)*bit_vector.bytes[n/8];
		byte.* &= cast( s8)~(1 << (n%8));
	}

	return previous_bit_value;
}

get_set_bit_count :: ( bit_vector: *BitSet ) -> ( num_set_bits: int ) {

	// Returns the count of set bits (bits with a value of 1) in the BitSet instance.
	// 
	// David R Hanson uses a lookup table by splitting each byte into nibbles and doing a lookup to get the number of bits set in each nibble, summing across nibbles.
	// Typically I would have just iterated over the bytes and checked every bit using shifts and ANDs. Going to try his approach.

	nibbles_to_num_set_bits: [16] u8 = .[
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

		hi_nibble := nibbles_to_num_set_bits[byte & 0x0F];
		lo_nibble := nibbles_to_num_set_bits[byte >> 4  ];
		
		set_bit_count += hi_nibble + lo_nibble;
	}

	return set_bit_count;
}

set_bits :: ( bit_vector: *BitSet, low: int, high: int ) {

	// Set the range of bits between low and high to a value of 1.
	assert( bit_vector != null );
	assert( low   >= 0, 				  "Invalid bit range. Low bit specified in the range must be greater than or equal to zero" );
	assert( high  <  bit_vector.num_bits, "Invalid bit range. High bit specified in the range must be at most n-1 number of bits in the bit-vector\n" );
	assert( high  > low,                  "Invalid bit range. High bit specified must be greater thn the low bit.\n"  );

	if low/8 < high/8 {
		// Bit range spans multiple bytes. Set the bits in the low-byte, those between the low and high-byte, then the high-byte.
		bit_vector.bytes[low/8] |= msb_masks[low%8];

		for i: (low/8)+1..(high/8)-1 {
			bit_vector.bytes[i] = 0xFF;
		}

		bit_vector.bytes[high/8] |= lsb_masks[high%8];	
	}
	else {
		// Bit range specified falls within a single byte.
		// The mask for the bits that need set within the byte are the AND of the msb and lsb for the respective byte indices.
		// Example from the text (page 208):
		//    set( 9, 13 )
		//    9 % 8 = 1; mask in the msb table 0XFE
		//   13 % 8 = 5; mask in the lsb table 0x3F
		// 
		//   0XFE: 1111_1110
		//   0X3F: 0011_1111
		//       ___________
		//   AND : 0011_1110 | 0000_0000
		//         ^       ^   ^       ^
		//        15  ...  8   7  ...  0
		//
		// So the AND of the mask's returns a new mask that returns the range we are interested in [9,13] in this case.

		mask := msb_masks[low%8] & lsb_masks[high%8];
		bit_vector.bytes[low/8] |= mask;
	}
	
	return;
}

clear_bits :: ( bit_vector: *BitSet, low: int, high: int ) {

	// Set/Clear the range of bits between low and high to a value of 0 (zero).
	// Implementation is based off of 'set_bits' but uses the complements of the masks and ANDs to clear bits in the range.

	assert( bit_vector != null );
	assert( low   >= 0, 				  "Invalid bit range. Low bit specified in the range must be greater than or equal to zero" );
	assert( high  <  bit_vector.num_bits, "Invalid bit range. High bit specified in the range must be at most n-1 number of bits in the bit-vector\n" );
	assert( high  > low,                  "Invalid bit range. High bit specified must be greater thn the low bit.\n"  );

	if low/8 < high/8 {
		// Bit range spans multiple bytes. Clear the bits in the low-byte, those between the low and high-byte, then the high-byte.
		bit_vector.bytes[low/8] &= ~msb_masks[low%8];

		for i: (low/8)+1..(high/8)-1 {
			bit_vector.bytes[i] = 0;
		}

		bit_vector.bytes[high/8] &= ~lsb_masks[high%8];
	}
	else {
		// Clear the bits that fall within a single byte. See 'set_bits' for rationale behind bit mask.
		mask := msb_masks[low%8] & lsb_masks[high%8];
		bit_vector.bytes[low/8] &= ~mask;
	}

	return;
}

not_bits :: ( bit_vector : *BitSet, low: int, high: int ) {

	// Flip (logical not) the bits between low and high.
	// Implementation is based off of 'set_bits' but uses the XOR logical operator to flip the bits in the range.

	assert( bit_vector != null );
	assert( low   >= 0, 				  "Invalid bit range. Low bit specified in the range must be greater than or equal to zero" );
	assert( high  <  bit_vector.num_bits, "Invalid bit range. High bit specified in the range must be at most n-1 number of bits in the bit-vector\n" );
	assert( high  > low,                  "Invalid bit range. High bit specified must be greater thn the low bit.\n"  );

	if low/8 < high/8 {
		// Bit range spans multiple bytes. Flip the bits in the low-byte, those between the low and high-byte, then the high-byte.
		bit_vector.bytes[low/8] ^= msb_mask[low%8];

		for i: (low/8)+1..(high/8)-1 {
			bit_vector.bytes[i] ^= 0xFF;
		}

		bit_vector.bytes[high/8] ^= lsb_mask[high%8];
	}
	else {
		// Flip the bits that fall within a single byte. See 'set_bits' for rationale behind bit mask.
		mask := msb_mask[low%8] & lsb_mask[high%8];
		bit_vector.bytes[low/8] ^= mask;
	}

	return;
}

equal :: ( a: *BitSet, b: *BitSet ) -> ( bool )  {

	// Compares the bit vectors and returns true if the bit vectors are equal and false otherwise.
	assert( a != null && b != null );
	assert( a.num_bits == b.num_bits, "Can't compare two bit vectors that do not contain the same number of bits/bit length\n." );

	size := a.num_bytes / size_of(u32);

	for i: 0..size-1 {
		if a.bytes_as_u32[i] != b.bytes_as_u32[i] {
			return false;
		}
	}

	return true;
}

is_subset_of :: ( a: *BitSet, b: *BitSet ) -> ( bool ) {

	// Compares the bit vectors and returns whether a is a subset of b.
	// A subset means that all set (1) bits in 'a' are correspondingly set in bit vector 'b'.	
	assert( a != null && b != null );
	assert( a.num_bits == b.num_bits, "Can't determine a subset of two bit vectors that do not contain the same number of bits/bit length.\n" );

	count := a.num_bytes / size_of(u32);
	for i: 0..count-1 {
		A := a.bytes_as_u32[i];
		B := b.bytes_as_u32[i];
		if A & B != A {
			// bits in 'a' not set in bit vector 'b' therefore not a subset
			return false;
		}
	}

	return true;
} 

is_proper_subset_of ::  ( a: *BitSet, b: *BitSet ) -> ( bool ) {

	// Compares the bit vectors and returns whether 'a is a proper subset of 'b'.
	// A proper subset means that all set (1) bits in 'a' are correspondingly set in bit vector 'b' but 'a' and 'b' are *not* equal.

	assert( a != null && b != null );
	assert( a.num_bits == b.num_bits, "Can't determine a proper subset when the bit vectors do not contain the same number of bits/bit length.\n" );

	count := a.num_bytes / size_of(u32);
	
	matches := 0;
	for i: 0..count-1 {
		A := a.bytes_as_u32[i];
		B := b.bytes_as_u32[i];

		if A & B != A {
			return false;	
		}
		else
		if A == B {
			matches += 1;
		}
	}

	return matches != count;
}

union_bits :: ( a: *BitSet, b: *BitSet ) -> ( r: *BitSet ) {

	// Implements the union of the two bit vectors.
	// Result includes all set bits from both arguments.
	// If an argument is null, that is interpreted as an empty bit set/vector.

	assert( a != null && b != null,   "Both bit vectors cannot be null/empty when performing a union of the bits\n" );
	assert( a.num_bits == b.num_bits, "Bit vectors must be the same length to perform a union.\n" );

	if b == null {
		return copy( a );
	}
	else 
	if a == null {
		return copy( b );
	}
	else {
		r := allocate( a.num_bits );
		count := a.num_bytes / size_of(u32);
		for i: 0..count-1 {
			r.bytes_as_u32[i] = a.bytes_as_u32[i] | b.bytes_as_u32[i];
		}

		return r;
	}
}

intersect_bits :: ( a: *BitSet, b: *BitSet ) -> ( r: *BitSet ) {
	
	// Implements the intersection of the two bit vectors.
	// Result includes bits from both arguments at the same index that are set.
	// If an argument is null, that is interpreted as an empty bit set/vector.

	assert( a != null && b != null,   "Both bit vectors cannot be null/empty when performing an intersection of the bits\n" );
	assert( a.num_bits == b.num_bits, "Bit vectors must be the same length to perform an intersection.\n" );

	if b == null {
		return copy( a );
	}
	else 
	if a == null {
		return copy( b );
	}
	else {
		r := allocate( a.num_bits );
		count := a.num_bytes / size_of(u32);
		for i: 0..count-1 {
			r.bytes_as_u32[i] = a.bytes_as_u32[i] & b.bytes_as_u32[i];
		}

		return r;
	}
}

difference_bits :: ( a: *BitSet, b: *BitSet ) -> ( r: *BitSet ) {
	
	// Implements the difference of the two bit vectors.
	// Result includes all the bits with value 1 in A but are not in set B.
	// If an argument is null, that is interpreted as an empty bit set/vector.
	//  A:  	1 1 1 1
	//  B:  	1 0 1 0
	//
	// ~B:  	0 1 0 1
	// A & ~B   0 1 0 1 

	assert( a != null && b != null,   "Both bit vectors cannot be null/empty when performing an difference of the bits\n" );
	assert( a.num_bits == b.num_bits, "Bit vectors must be the same length to perform a difference operation.\n" );

	if b == null {
		return copy( a );
	}
	else 
	if a == null {
		return copy( b );
	}
	else {
		r := allocate( a.num_bits );
		count := a.num_bytes / size_of(u32);
		for i: 0..count-1 {
			r.bytes_as_u32[i] = a.bytes_as_u32[i] & ~b.bytes_as_u32[i];
		}

		return r;
	}
}

#scope_file
#import "Basic";

// When the bit range spans multiple bytes you need to set the most-significant-bits of the low-byte and the least-significant bits of the high-byte.
// Use mask tables to extract or set specific bits.
//
//  Example: 
//		64-bit BitSet; Valid bit range [0,63]
//		set_bit( bit_vector = bv, low = 3, high = 58 )
//
//	Most-Significant bits of the low-order byte:
//  To find the low-byte take 'low'/ 8. Bits that need set within that byte are those GREATER THAN 'low' % 8.
//  In this example, the first byte (index = 0) needs ALL BUT the first three bits set. This is the same as saying that bits 4-7 need set.
//  A mask of 0xF8 (1111_1000) will make sure that the the most-significant bits starting AFTER the third bit is set.
//
//			1_1_1_1__1_0_0_0
//  Bit     7 6 5 4  3 2 1 0
//
// Least-Significant bits of the high-order byte:
//  To find the high-order byte take 'high'/ 8. Bits that need set within that byte are those LESS THAN 'high' % 8.
//  In this example, the last byte (index = 7) needs bits 0 through 2 set. A mask of 0x07 (0000_0111) will make sure that the least-significant bits starting FROM the zeroeth bit are set.
//   
//           0_0_0_0__0_1_1_1
//  Bit:     7 6 5 4  3 2 1 0
//
// Summary: 'low'  % 8 == 0 means all the bits in the byte need set
//          'high' % 8 == 0 means that the first bit in the byte needs set.
//           The MSB and LSB masks tables are built from each of these opposite persectives.
//
// All bytes in-between this range [('low'/8) + 1, ('high'/8)-1] need their bits set.

msb_masks : [8] u8 : .[ 0xFF, 0xFE, 0xFC, 0xF8, 0xF0, 0xE0, 0xC0, 0x80 ];
lsb_masks : [8] u8 : .[ 0x01, 0x03, 0x07, 0x0F, 0x1F, 0x3F, 0x7F, 0xFF ];

copy :: ( b: *BitSet ) -> ( c: *BitSet ) {
	
	// Copies the argument into a new BitSet instance.
	assert( b != null,      "Can't copy a bit vector that is null.\n" );

	c := allocate( b.num_bits );
	memcpy( c.bytes, b.bytes, b.num_bytes );

	return c;
}
