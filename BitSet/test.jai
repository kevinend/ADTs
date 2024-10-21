#scope_export 

// TODO: Clean up this example file to test all exported procedures. 

main :: () {

    
    {
        // Allocate, get bit count, get set bit count, deallocate
        a := BitSet.allocate( 8 );
        b := BitSet.allocate( 16 );
        c := BitSet.allocate( 32 );
        d := BitSet.allocate( 64 );

        // Check bit counts of each bit set
        assert( BitSet.get_bit_count( a ) == 8 );
        assert( BitSet.get_bit_count( b ) == 16 );
        assert( BitSet.get_bit_count( c ) == 32 );
        assert( BitSet.get_bit_count( d ) == 64 );

        BitSet.deallocate( a );
        BitSet.deallocate( b );
        BitSet.deallocate( c );
        BitSet.deallocate( d );
    }

    {
        // Allocate bit set
        // Check that the bits are initialized to zero.
        // Update a couple of bits
        // Check the return of the previous value from update.
        // Check the number of set bits in the set.

        a := BitSet.allocate( 16 );
        assert( BitSet.get_bit( a, 0  ) == 0 );
        assert( BitSet.get_bit( a, 15 ) == 0 );

        assert( BitSet.get_set_bit_count( a ) == 0 );

        previous := BitSet.update_bit( a, 1, 1 );
        assert( previous == 0 );

        BitSet.update_bit( a, 2, 1 );
        BitSet.update_bit( a, 3, 1 );

        assert( BitSet.get_set_bit_count( a ) == 3 );

        previous = BitSet.update_bit( a, 2, 0 );
        assert( previous == 1 );

        assert( BitSet.get_set_bit_count( a ) == 2 );

        BitSet.deallocate( a );
    }

    {
        // Allocate a bit set
        // Update a range of bits using 'set_bits'
        // Check set bit count
        // Get bit's from the bottom and top and middle of the range
        // Clear the bits
        // Check the set bit count
        // Get those same bits and make sure they are cleared.

        a := BitSet.allocate( 16 );
        
        BitSet.set_bits( a, 3, 12 ); // 4th to 13th bit 
        assert( BitSet.get_set_bit_count( a ) == 10 ); 

        assert( BitSet.get_bit( a, 2 )  == 0 ); // bit before the set range
        assert( BitSet.get_bit( a, 3 )  == 1 );
        assert( BitSet.get_bit( a, 3 )  == 1 );
        assert( BitSet.get_bit( a, 12 ) == 1 );
        assert( BitSet.get_bit( a, 13 ) == 0 ); // bit after the set range

        BitSet.clear_bits( a, 3, 12 );
        assert( BitSet.get_set_bit_count( a ) == 0 );

        assert( BitSet.get_bit( a, 2 )  == 0 ); // bit before the set range
        assert( BitSet.get_bit( a, 3 )  == 0 );
        assert( BitSet.get_bit( a, 3 )  == 0 );
        assert( BitSet.get_bit( a, 12 ) == 0 );
        assert( BitSet.get_bit( a, 13 ) == 0 ); // bit after the set range

        BitSet.deallocate( a );     
    }

    {
        // Allocate two bit sets
        // Test for equality 
        // Test subset operations

        a := BitSet.allocate( 8 );
        b := BitSet.allocate( 8 );

        BitSet.update_bit( a, 0, 1 );
        BitSet.update_bit( a, 1, 1 );
        BitSet.update_bit( a, 2, 1 );
        BitSet.update_bit( a, 3, 1 );

        BitSet.set_bits( b, 0, 5 );

        assert( BitSet.equal( a, b )               == false );
        assert( BitSet.is_subset_of( a, b )        == true  );
        assert( BitSet.is_subset_of( b, a )        == false );
        assert( BitSet.is_proper_subset_of( a, b ) == true  );
        assert( BitSet.is_proper_subset_of( b, a ) == false );

        BitSet.deallocate( a );
        BitSet.deallocate( b );
    }

    {
        // Allocate two bit sets
        // Take union, intersection and difference 

        a := BitSet.allocate( 32 );
        b := BitSet.allocate( 32 );

        BitSet.set_bits( a, 17, 23 ); // 7 bits
        BitSet.set_bits( b, 19, 25 ); // 7 bits, two past set a
    
        // Check min and max range, since all bits in the range should be set
        u := BitSet.set_union( a, b );
        assert( BitSet.get_set_bit_count( u ) == 9 );
        assert( BitSet.get_bit( u, 17 ) == 1 );
        assert( BitSet.get_bit( u, 25 ) == 1 );

        i := BitSet.set_intersection( a, b );
        assert( BitSet.get_set_bit_count( i ) == 5 );
        assert( BitSet.get_bit( i, 19 ) == 1 );
        assert( BitSet.get_bit( i, 23 ) == 1 );

        d := BitSet.set_difference( a, b );
        assert( BitSet.get_set_bit_count( d ) == 2 ); // 17 and 18
        assert( BitSet.get_bit( d, 17 ) == 1 );
        assert( BitSet.get_bit( d, 18 ) == 1 );

        BitSet.deallocate( a );
        BitSet.deallocate( b );
    }

    return; 
}

#scope_file
#import "Basic";
BitSet :: #import "BitSet";
