/*
    File implements a BitSet data structure.
    The user specifies the number of bits contained within the BitSet and the library exposes methods to manipulate those bits.

    The BitSet represents the user-supplied number of bits which are accessed/manipulated based on zero-indexing. Therefore the valid
    range for a Bit Vector containing n-bits is [0,n-1]. A 64-bit vector has valid indices [0,63].

    In David R Hanson's book C Interfaces and Implementations this data structure is called a BitVector (represented as the type Bit)
    which differs from the typical notion of a bit-vector sometimes referring to a C++ style-vector of bools that can dynamically grow.
    Since this implementation uses a fixed amount of memory once the user requests a new instance I've used the name BitSet instead.

    Also the implementation *could* support aliasing based on a type parameter T so as to reduce the amount of excess memory address space
    that can sometimes go unused (ex. request 8 bit set and memory allocated is 8 BYTES, since all procedures alias memory using a *u64).
    Adding this 'feature' would complicate the types and implementation which is already heavy in masking and logical operations so leaving it out for now. 
*/

#scope_export

BitSet :: struct {
    bit_count: int;
    memory:    Memory_Alias;
}

allocate :: ( bit_count: int ) -> ( set: *BitSet ) {
    
    // Allocates BitSet with enough memory to contain 'bit_count' number of bits. Memory is initialized to zero.
    // The number of bytes allocated is a multiple of size_of(u64) which is the largest memory alias for the BitSet's bytes.
    // 
    // Example: bit_count  = 70
    //          boundary   = 64
    //          multiples  = 2 (134/64)
    //          byte_count = 16 (2 * 8); where 8 is size_of(u64)
    // Allocate 16 bytes which is greater than the 9 bytes (72-bits) required to account for the 70 required bits.
    // However, since the memory can be addressed in u64 chunks for large set operations, we need to allocate all 16 bytes.

    assert( bit_count > 0 );

    set: *BitSet = alloc( size_of(BitSet) );
    assert( set != null );

    set.bit_count = bit_count;
    
    boundary   := 8 * size_of(u64);
    multiples  := (set.bit_count + (boundary-1)) / boundary;
    byte_count := multiples * size_of(u64);

    set.memory.as_u8 = alloc( byte_count );
    assert( set.memory.as_u8 != null );
    memset( set.memory.as_u8, 0, byte_count );

    return set; 
}

deallocate :: ( set: *BitSet ) {

    // Free the memory associated with the set, then free the set instance.
    
    assert( set != null );
    assert( set.memory.as_u8 != null );

    free( set.memory.as_u8 );
    free( set );

    return;
}

get_bit_count :: ( set: *BitSet ) -> ( bit_count: int ) {
    
    // Return the number of bits managed by the BitSet instance.
    assert( set != null );
    return set.bit_count;
}

get_bit :: ( set: *BitSet, n: int ) -> ( bit: int ) {

    // Returns the value of the n-th bit in the BitSet instance.
    
    assert( set != null );
    assert( n >= 0,            "Can't find a bit whose index is less than 0." );
    assert( n < set.bit_count, "Bit index exceeds the total number of bits in the bit set." );

    byte := << (set.memory.as_u8 + (n/8));
    return (byte >> (n%8)) & 1;
}

update_bit :: ( set: *BitSet, n: int, bit_value: int ) -> ( previous_bit_value: int ) {

    // Updates the bit_value supplied by the user into the n-th bit in the bit set.
    // Returns the previous bit value of the n-th bit.

    assert( set != null );
    assert( n >= 0,                           "Can't find a bit whose index is less than 0." );
    assert( n <  set.bit_count,               "Bit index exceeds the total number of bits in the bit vector." );
    assert( bit_value == 1 || bit_value == 0, "Supplied bit value must be a one (1) or a zero (0)." );

    previous_bit_value := get_bit( set, n );
    if ( bit_value == 1 ) {
        // Bit at the index is either 0 or 1 so we can OR with a 1 and always get the '1' we want in that bit
        set.memory.as_u8[n/8] |= cast(u8) (1 << (n%8));
    }
    else {
        // Bit at the index is either a 0 or 1 so we can AND with a 0 and always get the '0' we want in that bit.
        // To avoid clearing out the other bits, we set 1 in the n-th bit place then take the complement and AND that together with the target byte which will set the n-th bit to zero.
        // Alias memory as an s8 type since the complement of the shifted-1 will be a negative value in 2's complement notation.
    
        byte   := *set.memory.as_s8[n/8];
        byte.* &= cast(s8)~(1 << (n%8));
    }

    return previous_bit_value;
}

get_set_bit_count :: ( set: *BitSet ) -> ( num_set_bits: int ) {

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
        ,2   // 12
        ,3   // 13
        ,3   // 14
        ,4   // 15
    ];

    assert( set != null );

    count := 0;
    n     := bits_to_number_of_u8s( set.bit_count );
    for i: 0..n-1 {
        byte := << (set.memory.as_u8 + i);

        hi_nibble := nibbles_to_num_set_bits[byte & 0x0F];
        lo_nibble := nibbles_to_num_set_bits[byte >> 4  ];
        
        count += hi_nibble + lo_nibble;
    }

    return count;
}

set_bits :: ( set: *BitSet, low: int, high: int ) {

    // Set the range of bits between low and high to a value of 1.
    assert( set != null );
    assert( low   >= 0              ,"Invalid bit range. Low bit specified in the range must be greater than or equal to zero.\n" );
    assert( high  <  set.bit_count  ,"Invalid bit range. High bit specified in the range must be at most n-1 number of bits in the bit set.\n" );
    assert( high  > low             ,"Invalid bit range. High bit specified must be greater thn the low bit.\n"  );

    if low/8 < high/8 {
        // Bit range spans multiple bytes. Set the bits in the low-byte, those between the low and high-byte, then the high-byte.
        set.memory.as_u8[low/8] |= msb_masks[low%8];

        for i: (low/8)+1..(high/8)-1 {
            set.memory.as_u8[i] = 0xFF;
        }

        set.memory.as_u8[high/8] |= lsb_masks[high%8];  
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
        set.memory.as_u8[low/8] |= mask;
    }
    
    return;
}

clear_bits :: ( set: *BitSet, low: int, high: int ) {

    // Set/Clear the range of bits between low and high to a value of 0 (zero).
    // Implementation is based off of 'set_bits' but uses the complements of the masks and ANDs to clear bits in the range.

    assert( set != null );
    assert( low   >= 0              ,"Invalid bit range. Low bit specified in the range must be greater than or equal to zero" );
    assert( high  <  set.bit_count  ,"Invalid bit range. High bit specified in the range must be at most n-1 number of bits in the bit set\n" );
    assert( high  > low             ,"Invalid bit range. High bit specified must be greater thn the low bit.\n"  );

    if low/8 < high/8 {
        // Bit range spans multiple bytes. Clear the bits in the low-byte, those between the low and high-byte, then the high-byte.
        set.memory.as_u8[low/8] &= ~msb_masks[low%8];

        for i: (low/8)+1..(high/8)-1 {
            set.memory.as_u8[i] = 0;
        }

        set.memory.as_u8[high/8] &= ~lsb_masks[high%8];
    }
    else {
        // Clear the bits that fall within a single byte. See 'set_bits' for rationale behind bit mask.
        mask := msb_masks[low%8] & lsb_masks[high%8];
        set.memory.as_u8[low/8]  &= ~mask;
    }

    return;
}

not_bits :: ( set : *BitSet, low: int, high: int ) {

    // Flip (logical not) the bits between low and high.
    // Implementation is based off of 'set_bits' but uses the XOR logical operator to flip the bits in the range.

    assert( set != null );
    assert( low   >= 0,                   "Invalid bit range. Low bit specified in the range must be greater than or equal to zero" );
    assert( high  <  set.bit_count, "Invalid bit range. High bit specified in the range must be at most n-1 number of bits in the bit-vector\n" );
    assert( high  > low,                  "Invalid bit range. High bit specified must be greater thn the low bit.\n"  );

    if low/8 < high/8 {
        // Bit range spans multiple bytes. Flip the bits in the low-byte, those between the low and high-byte, then the high-byte.
        set.memory.as_u8[low/8] ^= msb_mask[low%8];

        for i: (low/8)+1..(high/8)-1 {
            set.memory.as_u8[i] ^= 0xFF;
        }

        set.memory.as_u8[high/8] ^= lsb_mask[high%8];
    }
    else {
        // Flip the bits that fall within a single byte. See 'set_bits' for rationale behind bit mask.
        mask := msb_mask[low%8] & lsb_mask[high%8];
        set.memory.as_u8[low/8] ^= mask;
    }

    return;
}

equal :: ( A: *BitSet, B: *BitSet ) -> ( bool )  {

    // Returns true if A is equal (bit for bit) to B; false otherwise.
    assert( A != null && B != null );
    assert( A.bit_count == B.bit_count, "Can't compare two bit sets that do not contain the same number of bits/bit length\n." );

    n := bits_to_number_of_u64s( A.bit_count );

    for i: 0..n-1 {
        if A.memory.as_u64[i] != B.memory.as_u64[i] {
            return false;
        }
    }

    return true;
}

is_subset_of :: ( A: *BitSet, B: *BitSet ) -> ( bool ) {

    // Returns true if A is a subset of B; false otherwise. 
    // A subset means that all set (1) bits in set A are correspondingly the value 1 in set B.  
    assert( A != null && B != null );
    assert( A.bit_count == B.bit_count, "Can't determine a subset of two bit sets that do not contain the same number of bits/bit length.\n" );

    n := bits_to_number_of_u64s( A.bit_count );
    for i: 0..n-1 {
        a := A.memory.as_u64[i];
        b := B.memory.as_u64[i];

        if a & b != a {
            // current bits in A's bytes not set in bit set B. Therefore not a subset.
            return false;
        }
    }

    return true;
} 

is_proper_subset_of :: ( A: *BitSet, B: *BitSet ) -> ( bool ) {

    // Returns true if A is a proper subset of B; false otherwise. 
    // A proper subset means that all set (1) bits in 'a' are correspondingly set in bit vector 'b' but 'a' and 'b' are *not* equal.

    assert( A != null && B != null );
    assert( A.bit_count == B.bit_count, "Can't determine a proper subset when the bit sets do not contain the same number of bits/bit length.\n" );

    matches := 0;
    n := bits_to_number_of_u64s( A.bit_count );
    for i: 0..n-1 {
        a := A.memory.as_u64[i];
        b := B.memory.as_u64[i];

        if a & b != a {
            // current bits in A's bytes not set in bit set B. Therefore not a subset.
            return false;   
        }
        else
        if a == b {
            matches += 1;
        }
    }

    // Returned false above if not a subset, so check if all the bytes in each bit set matched, if they don't then we have a proper subset.
    return matches != n;
}

set_union :: ( A: *BitSet, B: *BitSet ) -> ( C: *BitSet ) {

    // Implements the union of the two bit sets. Result includes all set bits from both arguments.
    // If an argument is null, that is interpreted as an empty bit set.

    assert( A != null && B != null      ,"Both bit sets cannot be null/empty when performing an union of the bits\n" );
    assert( A.bit_count == B.bit_count  ,"Bit sets must be the same length to perform an union.\n" );

    if A == null { return copy( B ); }
    else
    if B == null { return copy( A ); }
    else {
        C := allocate( A.bit_count );
        n := bits_to_number_of_u64s( C.bit_count );
        for i: 0..n-1 {
            C.memory.as_u64[i] = A.memory.as_u64[i] | B.memory.as_u64[i];
        }

        return C;
    }
}

set_intersection :: ( A: *BitSet, B: *BitSet ) -> ( C: *BitSet ) {
    
    // Implements the intersection of the two bit sets. Result includes only those bits set to a value of one in the same bit-index in both sets.
    // If an argument is null, that is interpreted as an empty bit set/vector.

    assert( A != null && B != null      ,"Both bit sets cannot be null/empty when performing an intersection of the bits\n" );
    assert( A.bit_count == B.bit_count  ,"Bit sets must be the same length to perform an intersection.\n" );

    if A == null { return copy( B ); }
    else
    if B == null { return copy( A ); }
    else {
        C := allocate( A.bit_count );
        n := bits_to_number_of_u64s( C.bit_count );
        for i: 0..n-1 {
            C.memory.as_u64[i] = A.memory.as_u64[i] & B.memory.as_u64[i];
        }

        return C;
    }
}

set_difference :: ( A: *BitSet, B: *BitSet ) -> ( C: *BitSet ) {
    
    // Implements the difference of the two bit sets. Result includes all the bits with value 1 in A but are not in set B.
    // If an argument is null, that is interpreted as an empty bit set/vector.
    //  A:      1 1 1 1
    //  B:      1 0 1 0
    //
    // ~B:      0 1 0 1
    // A & ~B   0 1 0 1 

    assert( A != null && B != null      ,"Both bit sets cannot be null/empty when performing a difference of the bits\n" );
    assert( A.bit_count == B.bit_count  ,"Bit sets must be the same length to perform a difference.\n" );

    if A == null { return copy( B ); }
    else
    if B == null { return copy( A ); }
    else {
        C := allocate( A.bit_count );
        n := bits_to_number_of_u64s( C.bit_count );
        for i: 0..n-1 {
            C.memory.as_u64[i] = A.memory.as_u64[i] & ~B.memory.as_u64[i];
        }

        return C;
    }
}

#scope_file
#import "Basic";

Memory_Alias :: union {
    // TODO: move this into the a Memory module
    as_u8:  *u8;
    as_u16: *u16;
    as_u32: *u32;
    as_u64: *u64;

    as_s8:  *s8;
    as_s16: *s16;
    as_s32: *s32;
    as_s64: *s64;

    as_int: *int;
}

// Memory of the BitSet can be aliased. Macros return the multiples of each alias type (*u8, *u16, etc..) for iterative looping over the memory.
bits_to_number_of_u8s  :: ( bit_count: int ) -> int #expand {
    bits := 8 * size_of(u8);
    return (bit_count + (bits-1)) / bits; 
}

bits_to_number_of_u16s :: ( bit_count: int ) -> int #expand {
    bits := 8 * size_of(u16);
    return (bit_count + (bits-1)) / bits; 
}

bits_to_number_of_u32s :: ( bit_count: int ) -> int #expand {
    bits := 8 * size_of(u32);
    return (bit_count + (bits-1)) / bits; 
}

bits_to_number_of_u64s :: ( bit_count: int ) -> int #expand {
    bits := 8 * size_of(u64);
    return (bit_count + (bits-1)) / bits; 
}

// When the bit range spans multiple bytes you need to set the most-significant-bits of the low-byte and the least-significant bits of the high-byte.
// Use mask tables to extract or set specific bits.
//
//  Example: 
//      64-bit BitSet; Valid bit range [0,63]
//      set_bit( set = bv, low = 3, high = 58 )
//
//  Most-Significant bits of the low-order byte:
//  To find the low-byte take 'low'/ 8. Bits that need set within that byte are those GREATER THAN 'low' % 8.
//  In this example, the first byte (index = 0) needs ALL BUT the first three bits set. This is the same as saying that bits 4-7 need set.
//  A mask of 0xF8 (1111_1000) will make sure that the the most-significant bits starting AFTER the third bit is set.
//
//          1_1_1_1__1_0_0_0
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

copy :: ( B: *BitSet ) -> ( C: *BitSet ) {
    
    // Copies the argument into a new BitSet instance.
    assert( B != null, "Can't copy a bit set that is null.\n" );

    bits := get_bit_count( B );

    C: *BitSet = allocate( bits );

    multiples  := bits_to_number_of_u64s( bits );
    byte_count := multiples * size_of(u64);

    memcpy( C.memory.as_u8, B.memory.as_u8, byte_count );

    return C;
}
