# GRAMMAR

program := expressions

expressions := expressions expression
			 | expression
			 | block

block := ( expressions )

expression := label
			| function
			| integer
			| float
			| string
			| boolean

label := [^()"]+[^()"0-9]+[^()"]+

function := label block
		  | expression label expression

integer := [0-9]+

float := [0-9]+(\.[0-9]+)?

string := ".*"

boolean := true
		 | false

# Notes

Blocks always return the value of their last expression

# OOO

Operator functions (exp label exp) are evaluated left-to-right

1 + 2 + 3 + 4 	  => +(1 2 3 4)			=> 10	// Chaining the same function produces a single call
1 + 2 * 3 + 4 	  => +(*(+(1 2) 3) 4)	=> 10	// Because expressions are evaluated L-2-R, this produces odd behaviour
(1 + 2) * (3 + 4) => *(+(1 2) +(3 4))	=> 21	// This is better
1 + (2 * 3) + 4   => +(1 *(2 3) 4)		=> 11	// ...but we probably wanted this

Below is another example of how this can backfire. Let a = 1:

a == 1 and true == false => ==(and(==(a 1) true) false) => false
(a == 1) and (true == false) => and(==(a 1) ==(true false)) => false

The expression on top evaluates correctly... sort of. The answer is right, but the workings are wrong!
