%{
%}

%skeleton "lalr1.cc"
%require "3.0.4"
%defines
%define api.token.constructor
%define api.value.type variant
%define parse.error verbose
%locations


%code requires
{
	/* you may need these deader files 
	 * add more header file if you need more
	 */


#include <list>
#include <string>
#include <functional>
#include <vector>
#include <stdlib.h>
#include <stdio.h>
#include <tuple>
#include <utility>

#ifndef FOO
#define FOO

#define debug false

void debug_print(std::string msg);
void debug_print_char(std::string msg, std::string c);
void debug_print_int(std::string msg, int i);

std::string concat(std::vector<std::string> strings, std::string prefix, std::string delim);



	/* define the sturctures using as types for non-terminals */

	/* end the structures for non-terminal types */

#endif // FOO

}



%code
{
#include "parser.tab.hh"

	/* you may need these deader files 
	 * add more header file if you need more
	 */
#include <iostream>
#include <sstream>
#include <string>
#include <map>
#include <regex>
#include <set>
#include <algorithm>
#include <climits>
#include <unordered_set>

//extern yy::location loc;

yy::parser::symbol_type yylex();

	/* define your symbol table, global variables,
	 * list of keywords or any function you may need here */
	
    class Ident {

    public:
    
        Ident(std::string str, int value = 0) :
            str(str), int_value(value), id(static_id++),
            tempName("__temp__" + std::to_string(id)) {}

        friend std::ostream& operator <<(std::ostream& out, const Ident &id) {

            out << "Identifier \"" << id.str << "\",";

            out << "Int value: ";
            int i = id.int_value;
            if (i == INT_MAX)
                out << "UNDEFINED";
            else
                out << i;

            return out;
        }

        friend bool operator ==(const Ident& lhs, const Ident& rhs) {

            // Test for equivalence
            return lhs.getIdentifier() == rhs.getIdentifier();
            //return lhs.getTempName().compare(rhs.getTempName()) == 0;
            //return lhs.getTempName() == rhs.getTempName();
            //return lhs.id == rhs.id;
        }

        std::string getIdentifier() const {

            return str;
        }

        
        std::string getTempName() const {

            return tempName;
        }

    private:

        static int static_id;

        const std::string tempName;
        std::string str;
        int int_value;
        int id;
        
    };

    bool containsIdentifierName(const std::string& name);

    bool containsIdentifier(const Ident& ident);

    bool containsFuncName(const std::string& funcName);

    std::vector < Ident > variables;                        // string is variable name
    std::vector < std::string > function_names;             // string is function name
    std::unordered_set < std::string > keywords;            // reserved keywords
    keywords.insert("if");


    bool errorOccurred = false;



	/* end of your code */
}

%token END 0 "end of file";

	/* specify tokens, type of non-terminals and terminals here */
%token FUNCTION BEGINPARAMS ENDPARAMS BEGINLOCALS ENDLOCALS BEGINBODY ENDBODY
%token INTEGER ARRAY OF IF THEN ENDIF ELSE 
%token WHILE DO BEGINLOOP ENDLOOP CONTINUE
%token READ WRITE AND OR NOT TRUE FALSE RETURN
%token ADD SUB MULT DIV MOD
%token EQ NEQ LT GT LTE GTE
%token SEMICOLON COLON COMMA L_PAREN R_PAREN L_SQUARE_BRACKET R_SQUARE_BRACKET ASSIGN
%token <std::string> IDENTIFIER
%token <int> NUMBER

%type  <std::string> program function declaration mulop statement var expression
%type  <std::vector<std::string>> id_loop statement_loop declaration_loop var_loop


%right ASSIGN
%left  OR
%left  AND
%right NOT
%left  LT GT LTE GTE EQ NEQ
%left  ADD SUB
%left  MULT DIV MOD
%left  L_SQUARE_BRACKET R_SQUARE_BRACKET
%left  L_PAREN R_PAREN
	/* end of token specifications */

%%

%start prog_start;

	/* define your grammars here use the same grammars 
	 * you used in Phase 2 and modify their actions to generate codes
	 * assume that your grammars start with prog_start
	 */

prog_start:

    program {

        std::cout << (errorOccurred ? "" : $1);

        // Print error if there isn't a main function
        //if (var_contains_str_only("main")) {
        if (!containsFuncName("main")) {

            yy::parser::error(@1, "No main function defined");
            //std::cerr << "Error - no main function found" << std::endl;
        }            
    }
;

program:

    /*epsilon*/ %empty {

        debug_print("program -> epsilon\n"); $$ = "";
    }

    | program function {
        debug_print("program -> program function\n");
        $$ = $1 + $2;


    }
;

function:   FUNCTION IDENTIFIER { function_names.push_back($2); } SEMICOLON
            BEGINPARAMS declaration_loop ENDPARAMS
            BEGINLOCALS declaration_loop ENDLOCALS
            BEGINBODY statement_loop ENDBODY {

        debug_print_char("function -> FUNCTION IDENTIFIER %s SEMICOLON ", $2);
        debug_print("BEGINPARAMS declaration_loop ENDPARAMS ");
        debug_print("BEGINLOCALS declaration_loop ENDLOCALS ");
        debug_print("BEGINBODY statement_loop ENDBODY\n");

        $$ = "func " + $2 + "\n";

        // params declaration loop
        $$ += concat($6, "", "");

        // locals declaration loop
        $$ += concat($9, "", "");

        // body statement loop
        $$ += concat($12, "", "");

        $$ += "endfunc\n";
    }
;

declaration_loop:

    /*epsilon*/ %empty {

        debug_print("declaration_loop -> epsilon\n");
        // don't add anything to vector
    }

	| declaration_loop declaration SEMICOLON {

        debug_print("declaration_loop -> declaration_loop declaration SEMICOLON\n");

        $$ = $1;
        $$.push_back($2);
    }
;

statement_loop:

    statement SEMICOLON {

        debug_print("statement_loop -> statement SEMICOLON\n");
        $$.push_back($1);
    }

	| statement_loop statement SEMICOLON {

        debug_print("statement_loop -> statement_loop statement SEMICOLON\n");

        $$ = $1;
        $$.push_back($2);
    }
;

declaration:

    id_loop COLON INTEGER {

        debug_print("declaration -> id_loop COLON INTEGER\n");

        $$ += concat($1, ". ", "\n");
                
    }

	| id_loop COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {

        debug_print_int("declaration -> id_loop COLON ARRAY L_SQUARE_BRACKET NUMBER %d R_SQUARE_BRACKET OF INTEGER\n", $5);

        $$ += concat($1,                        // id_loop
            ".[] ",                             // prefix
            ", " + std::to_string($5) + "\n"    // postfix, using NUMBER
        );

        if ($5 <= 0) {
            yy::parser::error(@1, "Array \"" + $$ + "\" must be of size greater than zero.");
        }
    }
;

id_loop:

    IDENTIFIER {

        debug_print("id_loop -> IDENTIFIER");
        $$.push_back($1);

        Ident id($1, INT_MAX);

        if (containsIdentifier(id)) {

            yy::parser::error(@1, "Multiple declarations of variable \"" + $1 + "\"");

        }

        else {

            variables.push_back(id);
        }
    }

    | id_loop COMMA IDENTIFIER {

        debug_print("id_loop -> id_loop COMMA IDENTIFIER");
               
        // Maintain id_loop's vector         
        for (std::string s : $1)
            $$.push_back(s);
                        
        $$.push_back($3);
        


        // Push back id,
        // only if it hasn't previously been declared
        Ident id($3, INT_MAX);

        if (containsIdentifier(id)) {
        // if (containsIdentifierName(id.getIdentifier())) {

            yy::parser::error(@3, "Multiple declarations of variable \"" + $3 + "\"");

        } else {

            variables.push_back(id);
        }
    }
;

statement:

    var ASSIGN expression { debug_print("statement -> var ASSIGN expression\n"); }

	| IF bool_expr THEN statement_loop ENDIF {

        debug_print("statement -> IF bool_expr THEN statement_loop ENDIF\n");

        // TODO
    
    }

	| IF bool_expr THEN statement_loop ELSE statement_loop ENDIF {

        debug_print("statement -> IF bool_expr THEN statement_loop ELSE statement_loop ENDIF\n");
        
        // TODO

    }

	| bool_expr BEGINLOOP statement_loop ENDLOOP {

        debug_print("statement -> WHILE bool_expr BEGINLOOP statement_loop ENDLOOP\n");

        // TODO
    }

	| DO BEGINLOOP statement_loop ENDLOOP WHILE bool_expr {

        debug_print("statement -> DO BEGINLOOP statement_loop ENDLOOP WHILE bool_expr\n"); }

		| READ var_loop {

            debug_print("statement -> READ var_loop\n");
            $$ = concat($2, ".< ", "\n");
            
        }

		| WRITE var_loop {

            debug_print("statement -> WRITE var_loop\n");
            $$ = concat($2, ".> ", "\n");
        }

		| CONTINUE { debug_print("statement -> CONTINUE\n"); }
		| RETURN expression { debug_print("statement -> RETURN expression\n"); }
		;

var_loop:

    var {

        debug_print("var_loop -> var\n");
        $$.push_back($1);

    }

	| var_loop COMMA var {

        debug_print("var_loop -> var_loop COMMA var\n");
        $$ = $1;
        $$.push_back($3);
    }
;

bool_expr:	  relation_and_expr { debug_print("bool_expr -> relation_and_expr\n"); }
        | bool_expr OR relation_and_expr { debug_print("bool_expr -> bool_expr OR relation_and_expr\n"); }
        ;

relation_and_expr:	  relation_expr { debug_print("relation_and_expr -> relation_expr\n"); }
        | relation_and_expr AND relation_expr { debug_print("relation_and_expr -> relation_and_expr AND relation_expr\n"); }
        ;

relation_expr:	  expression comp expression { debug_print("relation_expr -> expression comp expression\n"); }
		| NOT expression comp expression { debug_print("relation_expr -> NOT expression comp expression\n"); }
		| TRUE { debug_print("relation_expr -> TRUE\n"); }
		| NOT TRUE { debug_print("relation_expr -> NOT TRUE\n"); }
		| FALSE { debug_print("relation_expr -> FALSE\n"); }
		| NOT FALSE { debug_print("relation_expr -> NOT FALSE\n"); }
		| L_PAREN bool_expr R_PAREN { debug_print("relation_expr -> L_PAREN bool_expr R_PAREN\n"); }
		;

comp:		  EQ { debug_print("comp -> EQ\n"); }
		| NEQ { debug_print("comp -> NEQ\n"); }
		| LT { debug_print("comp -> LT\n"); }
		| GT { debug_print("comp -> GT\n"); }
		| LTE { debug_print("comp -> LTE\n"); }
		| GTE { debug_print("comp -> GTE\n"); }
		;

expression: mult_expr { debug_print("expression -> mult_expr\n"); }
        | expression ADD mult_expr { debug_print("expression -> expression ADD mult_expr\n"); }
        | expression SUB mult_expr { debug_print("expression -> expression SUB mult_expr\n"); }
        ;

mult_expr:	  term  { debug_print("mult_expr -> term\n"); }
        | mult_expr mulop term { debug_print_char("mult_expr -> mult_expr %s term\n", $2); }
        ;

mulop: 	  MULT { $$ = "MULT"; }
	| DIV  { $$ = "DIV"; }
	| MOD { $$ = "MOD"; }
	;

term:
    var { debug_print("term -> var\n"); }
		| SUB var { debug_print("term -> SUB var\n"); }
		| NUMBER { debug_print_int("term -> NUMBER %d\n", $1); }
		| SUB NUMBER { debug_print_int("term -> SUB NUMBER %d\n", $2); }
		| L_PAREN expression R_PAREN { debug_print("term -> L_PAREN expression R_PAREN\n"); }
		| SUB L_PAREN expression R_PAREN { debug_print("term -> SUB L_PAREN expression R_PAREN\n"); }
		| IDENTIFIER L_PAREN R_PAREN { debug_print_char("term -> IDENTIFIER %s L_PAREN R_PAREN\n", $1); }
	| IDENTIFIER L_PAREN expression_loop R_PAREN {

        debug_print_char("term -> IDENTIFIER %s L_PAREN expression_loop R_PAREN\n", $1);
    
        if (!containsFuncName($1)) {

            yy::parser::error(@1, "Attempted to call undeclared function \"" + $1 + "\"");
        }
    }
;

expression_loop:    expression { debug_print("expression_loop -> expression"); }
    | expression_loop COMMA expression { debug_print("expression_loop -> expression_loop COMMA expression"); }
    ;
		
var:

    IDENTIFIER {

        debug_print_char("var -> IDENTIFIER %s\n", $1);

        Ident id($1);

        // TODO implement

        // Look for p. If it's not contained,
        // print an error that the variable p does not exist
        if (!containsIdentifierName(id.getIdentifier())) {

            yy::parser::error(@1, "Variable \"" + $1 + "\" does not exist in the current context.");
        }

        $$ = $1;
    }

	| IDENTIFIER L_SQUARE_BRACKET expression R_SQUARE_BRACKET {

        debug_print_char("var -> IDENTIFIER %s L_SQUARE_BRACKET expression R_SQUARE_BRACKET\n", $1);

        $$ = ".[] " + $1 + ", " + $3;
    }
;

/*
inc_scope: %empty {

    scope++; 
    maxScope = (scope > maxScope ? scope : maxScope);
    }
;

dec_scope: %empty { scope--; } ;
*/

%%

int main(int argc, char *argv[])
{
	yy::parser p;
	return p.parse();
}

void yy::parser::error(const yy::location& l, const std::string& m)
{
	std::cerr << "Error at location " << l << ": " << m << std::endl;
    errorOccurred = true;
}

void debug_print(std::string msg) {

    if (debug) printf("%s", msg.c_str());
}

void debug_print_char(std::string msg, std::string c) {

    if (debug) printf(msg.c_str(), c.c_str());
}

void debug_print_int(std::string msg, int i) {

    if (debug) printf(msg.c_str(), i);
}

std::string concat(std::vector<std::string> strings, std::string prefix, std::string delim) {

    std::string str = "";

    for (std::string this_str : strings)
        str += prefix + this_str + delim;

    return str;

}

bool containsIdentifierName(const std::string& name) {

    for (Ident id : variables) {

        if (id.getIdentifier() == name) return true;
    }

    return false;
}


bool containsIdentifier(const Ident& ident) {

    for (Ident this_id : variables) {

        if (ident == this_id) return true;
    }

    return false;
}

bool containsFuncName(const std::string& funcName) {

    return std::find(function_names.begin(), function_names.end(), funcName)
        != function_names.end();
}

int Ident::static_id = 0;


