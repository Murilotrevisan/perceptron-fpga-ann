-- Pacote de operações em ponto fixo
-- Autores: Leonardo José Ribeiro Baptistella / Murilo Henrique Pasini Trevisan / Adriel Araújo dos Santos
-- Definição de constantes, tipos e subtipos para o pacote

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
PACKAGE fixed_package IS

    CONSTANT MAX_IND : integer := 15;
    CONSTANT MIN_IND : integer := - 15;
    SUBTYPE fixed_range IS integer RANGE MIN_IND TO MAX_IND;
    TYPE fixed IS array (fixed_range RANGE <>) OF STD_LOGIC;
    TYPE matrix IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF BIT;
    --Funções internas
    FUNCTION MAXIMUM (arg_L, arg_R: INTEGER) RETURN INTEGER;
    FUNCTION MINIMUM (arg_L, arg_R: INTEGER) RETURN INTEGER;
    FUNCTION COMP1_FIXED(arg_L: fixed) RETURN fixed;
    FUNCTION ADD_SUB_FIXED (arg_L, arg_R: fixed; c: BIT) RETURN fixed;
    FUNCTION MULT_FIXED (arg_L, arg_R: fixed) RETURN fixed;
    --Funções externas
    FUNCTION to_fixed (arg_L : INTEGER; max_range : fixed_range := MAX_IND;
        min_range : fixed_range := 0
    ) RETURN fixed;
    FUNCTION to_integer (arg_L : fixed) RETURN INTEGER;
    FUNCTION "+"(arg_L, arg_R : fixed) RETURN fixed;
    FUNCTION "-"(arg_L, arg_R : fixed) RETURN fixed;

    
END fixed_package;

PACKAGE BODY fixed_package IS
	--Internas
	--Auxiliares aritmeticas
	
	--MAXIMUM
	FUNCTION MAXIMUM (arg_L, arg_R: INTEGER) RETURN INTEGER IS
		BEGIN
			IF arg_L > arg_R THEN
				return arg_L;
			ELSE
				return arg_R;
			END IF;
	END MAXIMUM;

	--MINIMUM
	FUNCTION MINIMUM (arg_L, arg_R: INTEGER) RETURN INTEGER IS
		BEGIN
			IF arg_L < arg_R THEN
				RETURN arg_L;
			ELSE
				RETURN arg_R;
			END IF;
	END MINIMUM;
		
	--COMP1_FIXED
	FUNCTION COMP1_FIXED (arg_L: fixed) RETURN fixed IS;
		   VARIABLE arg_L_comp1: fixed(arg_L'HIGH DOWNTO arg_L'LOW);
		BEGIN
			FOR i IN arg_L'LOW TO arg_L'HIGH LOOP
				arg_L_comp1(i) := NOT(arg_L(i)); 
			END LOOP;
			RETURN arg_L_comp1;
	END COMP1_FIXED;
		
	--ADD_SUB_FIXED
	FUNCTION ADD_SUB_FIXED (arg_L, arg_R: fixed; c: BIT) RETURN fixed IS;
		VARIABLE s: fixed(arg_L'HIGH DOWNTO arg_L'LOW);
			VARIABLE vs: BIT;
		BEGIN
			vs := c;
			FOR i in arg_L'LOW TO arg_L'HIGH LOOP
				s(i) := (arg_L(i) XOR arg_R(i)) XOR vs;
				vs := (arg_L(i) AND arg_R(i)) OR (vs AND (arg_L(i) OR arg_R(i)));
			END LOOP;
			RETURN s;
		
	END ADD_SUB_FIXED;
		
	--MULT_FIXED
	FUNCTION MULT_FIXED (arg_L, arg_R: fixed) return fixed IS
		
		CONSTANT m: INTEGER := arg_L'LENGTH;
	    CONSTANT n: INTEGER := arg_R'LENGTH;
		VARIABLE Mij: matrix(0 TO m-1, 0 TO m+n-1);
		VARIABLE Cij: matrix(0 TO m-1, 0 TO m+n);
		VARIABLE Pij: matrix(0 TO m, 0 TO m+n);
		VARIABLE blinha: fixed(m+n-1 DOWNTO 0);
		VARIABLE P: fixed(m+n-1 DOWNTO 0);
		
		BEGIN
			
			blinha := (m+n-1 downto n => '0') & arg_R;
			
			initCij: FOR i IN 0 TO m-1 LOOP
				Cij(i, 0) := '0';
			END LOOP initCij;
			
			initPijcol: FOR i IN 0 to m LOOP
				Pij(i, 0) := '0';
			END LOOP initPijcol;
			
			initPijrow: FOR j IN 1 TO m+n-1 LOOP
				Pij(m, j) := '0';
			END LOOP initPijrow;
			
			Mijcol: FOR i IN m-1 DOWNTO 0 LOOP
				Mijrow: FOR j IN m+n-1 DOWNTO 0 LOOP
					Mij(i,j) := arg_L(i) and blinha(j);
				END LOOP Mijrow;
			END LOOP Mijcol;
			
			Pijcol: FOR i IN m-1 DOWNTO 0 LOOP
				Pijrow: FOR j IN 0 TO m+n-1 LOOP
					Pij(i,j+1) := Pij(i+1,j) XOR Mij(i,j) XOR Cij(i,j);
					Cij(i,j+1) := (Pij(i+1,j) AND (Mij(i,j) OR Cij(i,j))) OR (Mij(i,j) AND Cij(i,j));
				END LOOP Pijrow;
			END LOOP Pijcol;
			
			gen_Pi: FOR i IN m+n-1 DOWNTO 0 LOOP
				P(i) := Pij(0,i+1);
			END LOOP gen_Pi;

			RETURN P;		
	END MULT_FIXED;
	
--------------------------------------------------------------------------------------------------------------
	
	--To_fixed
	FUNCTION to_fixed (arg_L : INTEGER; max_range : fixed_range := MAX_IND;
		min_range : fixed_range := 0) RETURN fixed IS
		VARIABLE p_int : fixed(max_range DOWNTO min_range);
	BEGIN
		FOR i IN max_range DOWNTO 0 LOOP
    			p_int(i) := to_signed(arg_L, max_range + 1)(i);
		END LOOP;
		FOR i IN min_range TO -1 LOOP
    			p_int(i) := '0';
		END LOOP;
		RETURN p_int;
	END to_fixed;
	
	--To_integer
	FUNCTION to_integer (arg_L : fixed) RETURN INTEGER IS
        	VARIABLE s : signed(arg_L'high DOWNTO 0);
    	BEGIN
        	FOR i IN s'RANGE LOOP
            		s(i) := arg_L(i);
        	END LOOP;
        	RETURN to_integer(s);
    	END to_integer;
    	
    	--"+"
    	FUNCTION "+"(arg_L, arg_R : fixed) RETURN fixed IS
        	VARIABLE s : fixed(arg_L'RANGE);
    	BEGIN
        	s := ADD_SUB_FIXED(arg_L, arg_R, '0');
        	RETURN s;
    	END "+";
    	
    	--"-"
    	FUNCTION "-"(arg_L, arg_R : fixed) RETURN fixed IS
        	VARIABLE s : fixed(arg_L'RANGE);
        	VARIABLE arg_R_comp : fixed(arg_R'RANGE);
    	BEGIN
        	arg_R_comp := COMP1_FIXED(arg_R);
        	s := ADD_SUB_FIXED(arg_L, arg_R_comp, '1');
        	RETURN s;
    	END "-";

END fixed_package;

