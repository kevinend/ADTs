// File implements a variable length Stack data structure.

#scope_export

Stack :: struct (T: Type) {
	count: int;
	head:  *Stack_Element(T);
}

is_empty :: ( stack: *Stack ) -> ( bool ) {
	
	// Returns true if the stack contains no elements;
	return stack.count == 0;
}

push :: ( stack: *Stack($T), value: T ) {

	// Add an element to the top of the Stack.
	// The last pushed element is the "head" of the Stack and will be returned on the next call to pop.
	// The element contains a shallow copy of the argument 'value' so non-primitive types that may be updated later in the client application
	// could unintentionally update the elements of the stack.

	assert( stack != null );

	element: *Stack_Element(T) =  alloc( size_of(Stack_Element(T)) );
	assert( element != null );

	element.value = value;
	element.next  = stack.head;

	stack.head = element;
	stack.count += 1;
}

pop :: ( stack: *Stack($T) ) -> ( value: T ) {

	// If the Stack is non-empty, return the last pushed element.
	// If the Stack is empty, runtime assert and halt the program.

	assert( stack != null );
	assert( stack.count > 0, "Cannot pop an empty Stack" );

	head  := stack.head;
	value := head.value;
	
	stack.head = head.next;
	free( head );

	stack.count -= 1;

	return value;
}

count :: ( stack: *Stack($T) ) -> ( n: int ) {
	
	// Return the number of elements currently in the Stack

	assert( stack != null );
	return stack.count;
}

#scope_file
#import "Basic";

Stack_Element :: struct (T: Type) {
	value: T;
	next: *Stack_Element(T);
}
