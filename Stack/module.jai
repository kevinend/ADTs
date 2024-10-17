// File implements a variable length Stack data structure.
// 
// TODO: where does this directory have to be to import it?
//       can you specify a relative path? I don't remember.

#scope_export

Stack :: struct (T: Type) {
	count: int;
	head:  *Stack_Element(T);
}

// Returns true if the stack contains no elements;
empty :: ( stack: *Stack ) -> ( bool ) {
	return stack.count == 0;
}

// Add an element to the top of the Stack.
// The last pushed element is the "head" of the Stack and will be returned on the next call to pop.
// The element contains a shallow copy of the argument 'value' so non-primitive types that may be updated later in the client application
// could unintentionally update the elements of the stack.
push :: ( stack: *Stack($T), value: T ) {
	assert( stack != null );

	element: *Stack_Element(T) =  alloc( size_of(Stack_Element(T)) );
	assert( element != null );

	element.value = value;
	element.next  = stack.head;

	stack.head = element;
	stack.count += 1;
}

// If the Stack is non-empty, return the last pushed element.
// If the Stack is empty, runtime assert and halt the program.
pop :: ( stack: *Stack($T) ) -> ( value: T ) {
	assert( stack != null );
	assert( stack.count > 0, "Cannot pop an empty Stack" );

	head  := stack.head;
	value := head.value;
	
	stack.head = head.next;
	free( head );

	stack.count -= 1;

	return value;
}

// Return the number of elements currently in the Stack
count :: ( stack: *Stack($T) ) -> ( n: int ) {
	assert( stack != null );
	return stack.count;
}

#scope_file
#import "Basic";

Stack_Element :: struct (T: Type) {
	value: T;
	next: *Stack_Element(T);
}
