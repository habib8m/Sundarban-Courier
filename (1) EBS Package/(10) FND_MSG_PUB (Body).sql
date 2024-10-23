CREATE OR REPLACE PACKAGE BODY APPS.FND_MSG_PUB AS
/* $Header: AFASMSGB.pls 120.2 2005/11/03 15:48:27 tmorrow ship $ */

--  Constants used as tokens for unexpected error messages.

    G_PKG_NAME	CONSTANT    VARCHAR2(15):=  'FND_MSG_PUB';

--  Global constant for number of associated columns

    G_max_cols constant         NUMBER          := 5;

--  Record type created to store message_type and associated
--  column in addition to message

TYPE Col_Tbl_Type IS TABLE OF varchar2(62)
INDEX BY BINARY_INTEGER;


TYPE Msg_Rec_Type is RECORD
        (encoded_message     varchar2(2000)
        ,message_type        varchar2(1) default FND_MSG_PUB.G_DEPENDENCY_MSG
        ,associated_column1  varchar2(62) default null
        ,associated_column2  varchar2(62) default null
        ,associated_column3  varchar2(62) default null
        ,associated_column4  varchar2(62) default null
        ,associated_column5  varchar2(62) default null
        );

--  record to store token name value pairs

TYPE Msg_Token_Type is RECORD
        (name     varchar2(30)
        ,value     varchar2(2000)
        );

TYPE Msg_Token_Tbl IS TABLE OF Msg_Token_Type
 INDEX BY BINARY_INTEGER;

--  API message table type
--
--      PL/SQL table of Msg_Rec_Type
--  	changed from PL/SQL table of VARCHAR2(2000)
--	This is the datatype of the API message list

TYPE Msg_Tbl_Type IS TABLE OF Msg_Rec_Type
 INDEX BY BINARY_INTEGER;

--  Global message table variable.
--  this variable is global to the FND_MSG_PUB package only.

    G_msg_tbl	    		Msg_Tbl_Type;

--  Global dependency chain table variable.

    G_dep_tbl                   Msg_Tbl_Type;

--  Global variable holding the message count.

    G_msg_count   		NUMBER      	:= 0;

--  Global variable holding the dependency message count.

    G_dep_count   		NUMBER      	:= 0;

--  Index used by the Get function to keep track of the last fetched
--  message.

    G_msg_index			NUMBER		:= 0;

--  Index used by the Get function to keep track of the last fetched
--  dependency message.

    G_dep_index			NUMBER		:= 0;

--  Global to remember the associated column value between the calls to
--  no_all_inclusive_error, no_error_message and add

    G_associated_column                   Col_Tbl_Type;

--  Global variables to remember the values
--  passed into Set_Search_Name and Set_Search_Token procedures.

    G_ser_msgname varchar2(30);
    G_ser_msgdata varchar2(2000);
    G_ser_msgset  boolean := FALSE;
    G_ser_msgapp  varchar2(50);

--  FUNCTION 	Get_Associated_Col
--

FUNCTION    Get_Associated_Col
(   p_message       IN  NUMBER
   ,p_column	    IN	NUMBER
) return varchar2
IS
l_associated_column varchar2(62);
BEGIN
      if (p_column = 1) then
        l_associated_column := G_msg_tbl(p_message).associated_column1;
      elsif (p_column = 2) then
        l_associated_column := G_msg_tbl(p_message).associated_column2;
      elsif (p_column = 3) then
        l_associated_column := G_msg_tbl(p_message).associated_column3;
      elsif (p_column = 4) then
        l_associated_column := G_msg_tbl(p_message).associated_column4;
      elsif (p_column = 5) then
        l_associated_column := G_msg_tbl(p_message).associated_column5;
      end if;

      return l_associated_column;

EXCEPTION

    WHEN NO_DATA_FOUND THEN

        --  No more messages return NULL;

        return null;

END Get_Associated_Col;

--  PROCEDURE 	Set_Associated_Col
--

PROCEDURE    Set_Associated_Col
(   p_message       IN      NUMBER
   ,p_column	    IN      NUMBER
   ,p_value         IN      VARCHAR2
)
IS
BEGIN
      if (p_column = 1) then
        G_msg_tbl(p_message).associated_column1 := p_value;
      elsif (p_column = 2) then
        G_msg_tbl(p_message).associated_column2 := p_value;
      elsif (p_column = 3) then
        G_msg_tbl(p_message).associated_column3 := p_value;
      elsif (p_column = 4) then
        G_msg_tbl(p_message).associated_column4 := p_value;
      elsif (p_column = 5) then
        G_msg_tbl(p_message).associated_column5 := p_value;
      end if;
EXCEPTION

    WHEN NO_DATA_FOUND THEN

        null;

END Set_Associated_Col;

--  FUNCTION 	Get_Dependency_Col
--

FUNCTION    Get_Dependency_Col
(   p_message       IN  NUMBER
   ,p_column	    IN	NUMBER
) return varchar2
IS
l_associated_column varchar2(62);
BEGIN
      if (p_column = 1) then
        l_associated_column := G_dep_tbl(p_message).associated_column1;
      elsif (p_column = 2) then
        l_associated_column := G_dep_tbl(p_message).associated_column2;
      elsif (p_column = 3) then
        l_associated_column := G_dep_tbl(p_message).associated_column3;
      elsif (p_column = 4) then
        l_associated_column := G_dep_tbl(p_message).associated_column4;
      elsif (p_column = 5) then
        l_associated_column := G_dep_tbl(p_message).associated_column5;
      end if;

      return l_associated_column;

EXCEPTION

    WHEN NO_DATA_FOUND THEN

        --  No more messages return NULL;

        return null;

END Get_Dependency_Col;

--  PROCEDURE 	Set_Dependency_Col
--

PROCEDURE    Set_Dependency_Col
(   p_message       IN      NUMBER
   ,p_column	    IN      NUMBER
   ,p_value         IN      VARCHAR2
)
IS
BEGIN
      if (p_column = 1) then
        G_dep_tbl(p_message).associated_column1 := p_value;
      elsif (p_column = 2) then
        G_dep_tbl(p_message).associated_column2 := p_value;
      elsif (p_column = 3) then
        G_dep_tbl(p_message).associated_column3 := p_value;
      elsif (p_column = 4) then
        G_dep_tbl(p_message).associated_column4 := p_value;
      elsif (p_column = 5) then
        G_dep_tbl(p_message).associated_column5 := p_value;
      end if;
EXCEPTION

    WHEN NO_DATA_FOUND THEN

        null;

END Set_Dependency_Col;

--  Procedure	Initialize
--
--  Usage	Used by API callers and developers to intialize the
--		global message table.
--  Desc	Clears the G_msg_tbl and resets all its global
--		variables. Except for the message level threshold.
--

PROCEDURE Initialize
IS
BEGIN

    G_msg_tbl.DELETE;
    G_msg_count := 0;
    G_msg_index := 0;

    G_dep_tbl.DELETE;
    G_dep_count := 0;
    G_dep_index := 0;

    FOR I IN 1..G_max_cols LOOP
      G_associated_column(I) := null;
    END LOOP;

    G_ser_msgname := null;
    G_ser_msgdata := null;
    G_ser_msgset  := FALSE;
    G_ser_msgapp  := null;

END;

--  FUNCTION	Count_Msg
--
--  Usage	Used by API callers and developers to find the count
--		of messages in the  message list.
--  Desc	Returns the value of G_msg_count
--
--  Parameters	None
--
--  Return	NUMBER

FUNCTION    Count_Msg 	RETURN NUMBER
IS
BEGIN

    RETURN G_msg_Count;

END Count_Msg;

--  PROCEDURE	Count_And_Get
--

PROCEDURE    Count_And_Get
(   p_encoded		    IN	VARCHAR2    := 'T'	    ,
    p_count		    OUT	NOCOPY NUMBER				    ,
    p_data		    OUT NOCOPY VARCHAR2
)
IS
l_msg_count	NUMBER;
BEGIN

    l_msg_count :=  Count_Msg;

    IF l_msg_count = 1 THEN

	p_data := Get ( p_msg_index =>  G_FIRST	    ,
			p_encoded   =>	p_encoded   );

    END IF;

    p_count := l_msg_count ;

END Count_And_Get;

--  PROCEDURE 	Add
--
--  Usage	Used to add messages to the global message table.
--
--  Desc	Reads a message off the message dictionary stack and
--  	    	writes it in an encoded format to the global PL/SQL
--		message table.
--  	    	The message is appended at the bottom of the message
--    	    	table.
--

PROCEDURE Add
IS
BEGIN

    --	Increment message count

    G_msg_count := G_msg_count + 1;

    --	Write message.

    G_msg_tbl(G_msg_count).message_type := FND_MSG_PUB.G_ERROR_MSG;
    G_msg_tbl(G_msg_count).encoded_message := FND_MESSAGE.GET_ENCODED;

    FOR I IN 1..G_max_cols LOOP
      G_associated_column(I) := null;
    END LOOP;


END; -- Add

--  PROCEDURE 	Delete_Msg
--
--  Usage	Used to delete a specific message from the message
--		list, or clear the whole message list.
--
--  Desc	If instructed to delete a specific message, the
--		message is removed from the message table and the
--		table is compressed by moving the messages coming
--		after the deleted messages up one entry in the message
--		table.
--		If there is no entry found the Delete procedure does
--		nothing, and  no exception is raised.
--		If delete is passed no parameters it deletes the whole
--		message table.
--
--  Prameters	p_msg_index	IN NUMBER := null Optional
--		    holds the index of the message to be deleted.
--

PROCEDURE Delete_Msg
(   p_msg_index IN    NUMBER	:=  NULL
)
IS
l_var varchar2(62);
BEGIN

    IF p_msg_index IS NULL THEN

	--  Delete the whole table.

	G_msg_tbl.DELETE;
	G_msg_count := 0;
	G_msg_index := 0;

    ELSE

	--  Check if entry exists

	IF G_msg_tbl.EXISTS(p_msg_index) THEN

	    IF p_msg_index <= G_msg_count THEN

		--  Move all messages up 1 entry.

		FOR I IN p_msg_index..G_msg_count-1 LOOP

                    FOR J IN 1..G_max_cols LOOP
                      Set_Associated_Col(I,J,Get_Associated_Col(I + 1,J));
                    END LOOP;
		    G_msg_tbl( I ).message_type := G_msg_tbl( I + 1 ).message_type;
		    G_msg_tbl( I ).encoded_message := G_msg_tbl( I + 1 ).encoded_message;

		END LOOP;

		--  Delete the last message table entry.

		G_msg_tbl.DELETE(G_msg_count)	;
		G_msg_count := G_msg_count - 1	;

	    END IF;

	END IF;

    END IF;

END Delete_Msg;

--  PROCEDURE 	Get
--

PROCEDURE    Get
(   p_msg_index	    IN	NUMBER	    := G_NEXT		,
    p_encoded	    IN	VARCHAR2    := 'T'	,
    p_data	    OUT	NOCOPY VARCHAR2			,
    p_msg_index_out OUT	NOCOPY NUMBER
)
IS
l_msg_index NUMBER := G_msg_index;
BEGIN

    IF p_msg_index = G_NEXT THEN
	G_msg_index := G_msg_index + 1;
    ELSIF p_msg_index = G_FIRST THEN
	G_msg_index := 1;
    ELSIF p_msg_index = G_PREVIOUS THEN
	G_msg_index := G_msg_index - 1;
    ELSIF p_msg_index = G_LAST THEN
	G_msg_index := G_msg_count ;
    ELSE
	G_msg_index := p_msg_index ;
    END IF;


    IF FND_API.To_Boolean( p_encoded ) THEN

	p_data := G_msg_tbl( G_msg_index ).encoded_message;

    ELSE

        FND_MESSAGE.SET_ENCODED ( G_msg_tbl( G_msg_index ).encoded_message );
	p_data := FND_MESSAGE.GET;

    END IF;

    p_msg_index_out	:=  G_msg_index		    ;

EXCEPTION

    WHEN NO_DATA_FOUND THEN

	--  No more messages, revert G_msg_index and return NULL;

	G_msg_index := l_msg_index;

	p_data		:=  NULL;
	p_msg_index_out	:=  NULL;

END Get;

--  FUNCTION	Get
--

FUNCTION    Get
(   p_msg_index	    IN NUMBER	:= G_NEXT	    ,
    p_encoded	    IN VARCHAR2	:= 'T'
)
RETURN VARCHAR2
IS
    l_data	    VARCHAR2(2000)  ;
    l_msg_index_out NUMBER	    ;
BEGIN

    Get
    (	p_msg_index	    ,
	p_encoded	    ,
	l_data		    ,
	l_msg_index_out
    );

    RETURN l_data ;

END Get;

--  PROCEDURE	Reset
--
--  Usage	Used to reset the message table index used in reading
--		messages to point to the top of the message table or
--		the botom of the message table.
--
--  Desc	Sets G_msg_index to 0 or G_msg_count+1 depending on
--		the reset mode.
--
--  Parameters	p_mode	IN NUMBER := G_FIRST	Optional
--		    possible values are :
--			G_FIRST	resets index to the begining of msg tbl
--			G_LAST  resets index to the end of msg tbl
--

PROCEDURE Reset ( p_mode    IN NUMBER := G_FIRST )
IS
l_procedure_name    CONSTANT VARCHAR2(15):='Reset';
BEGIN

    IF p_mode = G_FIRST THEN

	G_msg_index := 0;

    ELSIF p_mode = G_LAST THEN

	G_msg_index := G_msg_count + 1 ;

    ELSE

	--  Invalid mode.

	FND_MSG_PUB.Add_Exc_Msg
    	(   p_pkg_name		=>  G_PKG_NAME			,
    	    p_procedure_name	=>  l_procedure_name		,
    	    p_error_text	=>  'Invalid p_mode: '||p_mode
	);

	RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

    END IF;

END Reset;

--  FUNCTION 	Check_Msg_Level
--
--  Usage   	Used by API developers to check if the level of the
--  	    	message they want to write to the message table is
--  	    	higher or equal to the message level threshold or not.
--  	    	If the function returns TRUE the developer should go
--  	    	ahead and write the message to the message table else
--  	    	he/she should skip writing this message.
--  Desc    	Accepts a message level as input fetches the value of
--  	    	the message threshold profile option and compares it
--  	    	to the input level.
--  Return  	TRUE if the level is equal to or higher than the
--  	    	threshold. Otherwise, it returns FALSE.
--

FUNCTION Check_Msg_Level
(   p_message_level IN NUMBER := G_MSG_LVL_SUCCESS
) RETURN BOOLEAN
IS
BEGIN

    IF G_msg_level_threshold = 9.99E125 THEN

    	--  Read the Profile option value.

    	G_msg_level_threshold :=
    	TO_NUMBER ( FND_PROFILE.VALUE('FND_AS_MSG_LEVEL_THRESHOLD') );

    	IF G_msg_level_threshold IS NULL THEN

       	    G_msg_level_threshold := G_MSG_LVL_SUCCESS;

    	END IF;

    END IF;

    RETURN p_message_level >= G_msg_level_threshold ;

END; -- Check_Msg_Level

PROCEDURE Build_Exc_Msg
( p_pkg_name	    IN VARCHAR2 :=null    ,
  p_procedure_name  IN VARCHAR2 :=null    ,
  p_error_text	    IN VARCHAR2 :=null
)
IS
l_error_text	VARCHAR2(240)	:=  p_error_text ;
BEGIN

    -- If p_error_text is missing use SQLERRM.

    IF p_error_text is null THEN

	l_error_text := SUBSTRB (SQLERRM , 1 , 240);

    END IF;

    FND_MESSAGE.SET_NAME('FND','FND_AS_UNEXPECTED_ERROR');

    IF p_pkg_name is not null and p_pkg_name <> chr(0) THEN
    	FND_MESSAGE.SET_TOKEN('PKG_NAME',p_pkg_name);
    END IF;

    IF p_procedure_name is not null and p_procedure_name <> chr(0) THEN
    	FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME',p_procedure_name);
    END IF;

    IF l_error_text is not null and l_error_text <> chr(0) THEN
    	FND_MESSAGE.SET_TOKEN('ERROR_TEXT',l_error_text);
    END IF;

END; -- Build_Exc_Msg

PROCEDURE Add_Exc_Msg
(   p_pkg_name		IN VARCHAR2 :=null   ,
    p_procedure_name	IN VARCHAR2 :=null   ,
    p_error_text	IN VARCHAR2 :=null
)
IS
BEGIN

    Build_Exc_Msg
    (	p_pkg_name	    ,
	p_procedure_name    ,
	p_error_text
    );

    Add;

END Add_Exc_Msg ;

--  PROCEDURE	Dump_Msg
--

PROCEDURE    Dump_Msg
(   p_msg_index		IN NUMBER )
IS
    l_msg varchar2(2000);
BEGIN
    l_msg := G_msg_tbl(p_msg_index).encoded_message;

/* Commented these out because dbms_output. put_line is illegal in our */
/* shipping code.  If someone really needs to use this routine to debug */
/* a problem, the workaround is to copy this package, uncomment these lines*/
/* and apply that to the database in question.  */

/*    dbms_ou#tput.pu#t_line('Dumping Message number : '||p_msg_index);	*/

/*    dbms_ou#tput.pu#t_line('DATA = '||replace(l_msg, chr(0), ' '));*/


END Dump_Msg;

--  PROCEDURE	Dump_List
--

PROCEDURE    Dump_List
(   p_messages	IN BOOLEAN  :=	FALSE
)
IS
BEGIN

/* Commented these out because dbms_output. put_line is illegal in our */
/* shipping code.  If someone really needs to use this routine to debug */
/* a problem, the workaround is to copy this package, uncomment these lines*/
/* and apply that to the database in question.  */

/*    dbms_ou#tput.pu#t_line('Dumping Message List :');*/
/*    dbms_ou#tput.pu#t_line('G_msg_tbl.COUNT = '||G_msg_tbl.COUNT);*/
/*    dbms_ou#tput.pu#t_line('G_msg_count = '||G_msg_count);*/
/*    dbms_ou#tput.pu#t_line('G_msg_index = '||G_msg_index);*/

    IF p_messages THEN

	FOR I IN 1..G_msg_tbl.COUNT LOOP

	    dump_Msg (I);

	END LOOP;

    END IF;

END Dump_List;

--  PROCEDURE  Add_Detail
--

PROCEDURE    Add_Detail
(    p_associated_column1 IN VARCHAR2 default null
    ,p_associated_column2 IN VARCHAR2 default null
    ,p_associated_column3 IN VARCHAR2 default null
    ,p_associated_column4 IN VARCHAR2 default null
    ,p_associated_column5 IN VARCHAR2 default null
    ,p_same_associated_columns IN VARCHAR2 default 'F'
    ,p_message_type IN VARCHAR2 default FND_MSG_PUB.G_ERROR_MSG
)
IS
   l_procedure_name    CONSTANT VARCHAR2(15):='Add_Detail';

BEGIN

    -- validate message type
    if p_message_type not in (g_error_msg,
                              g_warning_msg,
                              g_information_msg,
                              g_dependency_msg) then

	--  Invalid mode.

	FND_MSG_PUB.Add_Exc_Msg
    	(   p_pkg_name		=>  G_PKG_NAME			,
    	    p_procedure_name	=>  l_procedure_name		,
    	    p_error_text	=>  'Invalid p_message_type: '||p_message_type
	);

	RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   end if;

   -- store the associated column parameters in the global array
   -- if the previously saved columns are not to be used

   if p_same_associated_columns <> 'T' then
     g_associated_column(1) := p_associated_column1;
     g_associated_column(2) := p_associated_column2;
     g_associated_column(3) := p_associated_column3;
     g_associated_column(4) := p_associated_column4;
     g_associated_column(5) := p_associated_column5;
   end if;


   --	Write message.

   if p_message_type <> FND_MSG_PUB.G_DEPENDENCY_MSG then

     G_msg_count := G_msg_count + 1;
     G_msg_tbl(G_msg_count).message_type := p_message_type;
     G_msg_tbl(G_msg_count).encoded_message := fnd_message.get_encoded;

     if p_message_type = FND_MSG_PUB.G_ERROR_MSG then
       FOR J IN 1..G_max_cols LOOP
         Set_Associated_Col(G_msg_count,J,g_associated_column(J));
       END LOOP;
     end if;

   else

     G_dep_count := G_dep_count + 1;
     G_dep_tbl(G_dep_count).message_type := FND_MSG_PUB.G_DEPENDENCY_MSG;
     G_dep_tbl(G_dep_count).encoded_message := null;

     FOR J IN 1..G_max_cols LOOP
       Set_Dependency_Col(G_dep_count,J,g_associated_column(J));
     END LOOP;

   end if;

   -- set g_associated_columns to null

   FOR J IN 1..G_max_cols LOOP
     g_associated_column(J) := null;
   END LOOP;

END Add_Detail;


--  FUNCTION   No_All_Inclusive_Error
--

FUNCTION    No_All_Inclusive_Error
(   p_check_column1 IN VARCHAR2
   ,p_check_column2 IN VARCHAR2 default null
   ,p_check_column3 IN VARCHAR2 default null
   ,p_check_column4 IN VARCHAR2 default null
   ,p_check_column5 IN VARCHAR2 default null
   ,p_associated_column1 IN VARCHAR2 default null
   ,p_associated_column2 IN VARCHAR2 default null
   ,p_associated_column3 IN VARCHAR2 default null
   ,p_associated_column4 IN VARCHAR2 default null
   ,p_associated_column5 IN VARCHAR2 default null
) return varchar2
IS
l_check_column   Col_Tbl_Type;
BEGIN

  -- set up an array of check columns

  l_check_column(1) := p_check_column1;
  l_check_column(2) := p_check_column2;
  l_check_column(3) := p_check_column3;
  l_check_column(4) := p_check_column4;
  l_check_column(5) := p_check_column5;

  -- save associated columns to global array

  g_associated_column(1) := p_associated_column1;
  g_associated_column(2) := p_associated_column2;
  g_associated_column(3) := p_associated_column3;
  g_associated_column(4) := p_associated_column4;
  g_associated_column(5) := p_associated_column5;

  -- Checks done for p_check_column1 then p_check_column2 etc... since
  -- we are more likely to find a match for p_check_column1

  -- check p_check_column1 against all associated columns in message list

  FOR J IN 1..G_max_cols LOOP
    if l_check_column(J) is not null then

      -- check columns against all associated columns in message list

      FOR I IN 1..G_msg_tbl.COUNT LOOP
        if G_msg_tbl(I).message_type = FND_MSG_PUB.G_ERROR_MSG then
          FOR K IN 1..G_max_cols LOOP
            if l_check_column(J) = Get_Associated_Col(I,K) then
              -- Now add dummy messages to the dependency list
              fnd_msg_pub.Add_Detail
                (p_associated_column1      => p_associated_column1
                ,p_associated_column2      => p_associated_column2
                ,p_associated_column3      => p_associated_column3
                ,p_associated_column4      => p_associated_column4
                ,p_associated_column5      => p_associated_column5
                ,p_same_associated_columns => 'F'
                ,p_message_type            => FND_MSG_PUB.G_DEPENDENCY_MSG
                );
              return 'F';
            end if;
          END LOOP;
        end if;
      END LOOP;

      -- check columns against all associated columns in dependency list

      FOR I IN 1..G_dep_tbl.COUNT LOOP
        -- NOTE the associated columns can never take a null value
        -- so no need to check for nulls
        FOR K IN 1..G_max_cols LOOP
          if l_check_column(J) = Get_Dependency_Col(I,K) then
            -- Now add dummy messages to the dependency list
            fnd_msg_pub.Add_Detail
              (p_associated_column1      => p_associated_column1
              ,p_associated_column2      => p_associated_column2
              ,p_associated_column3      => p_associated_column3
              ,p_associated_column4      => p_associated_column4
              ,p_associated_column5      => p_associated_column5
              ,p_same_associated_columns => 'F'
              ,p_message_type            => FND_MSG_PUB.G_DEPENDENCY_MSG
              );
            return 'F';
          end if;
        END LOOP;
      END LOOP;
    end if;
  END LOOP;

  -- no errors found matching check columns so return true

  return 'T';

END No_All_Inclusive_Error;

--  FUNCTION   Is_Exclusive_Msg_Error
--             evaluates if message has more than
--             one associated column

FUNCTION    Is_Exclusive_Msg_Error ( p_message IN NUMBER
) return boolean
IS
l_msg_count   		NUMBER      	:= 0;
BEGIN

  -- Checks done for p_check_column1 then p_check_column2 etc... since
  -- we are more likely to find a match for p_check_column1

  FOR K IN 1..G_max_cols LOOP
    if Get_Associated_Col(p_message,K) is not null then
      l_msg_count := l_msg_count + 1;
      if l_msg_count > 1 then
        return false;
      end if;
    end if;
  END LOOP;

  -- count is less than 2 so return true

  return true;


END Is_Exclusive_Msg_Error;

--  FUNCTION   Is_Exclusive_Dep_Error
--             evaluates if dependency message has more than
--             one associated column

FUNCTION    Is_Exclusive_Dep_Error ( p_message IN NUMBER
) return boolean
IS
l_msg_count   		NUMBER      	:= 0;
BEGIN

  -- Checks done for p_check_column1 then p_check_column2 etc... since
  -- we are more likely to find a match for p_check_column1

  FOR K IN 1..G_max_cols LOOP
    if Get_Dependency_Col(p_message,K) is not null then
      l_msg_count := l_msg_count + 1;
      if l_msg_count > 1 then
        return false;
      end if;
    end if;
  END LOOP;

  -- count is less than 2 so return true

  return true;


END Is_Exclusive_Dep_Error;

--  FUNCTION   No_Exclusive_Error
--

FUNCTION    No_Exclusive_Error
(   p_check_column1 IN VARCHAR2
   ,p_check_column2 IN VARCHAR2 default null
   ,p_check_column3 IN VARCHAR2 default null
   ,p_check_column4 IN VARCHAR2 default null
   ,p_check_column5 IN VARCHAR2 default null
   ,p_associated_column1 IN VARCHAR2 default null
   ,p_associated_column2 IN VARCHAR2 default null
   ,p_associated_column3 IN VARCHAR2 default null
   ,p_associated_column4 IN VARCHAR2 default null
   ,p_associated_column5 IN VARCHAR2 default null
) return varchar2
IS
l_check_column   Col_Tbl_Type;
BEGIN

  -- set up an array of check columns

  l_check_column(1) := p_check_column1;
  l_check_column(2) := p_check_column2;
  l_check_column(3) := p_check_column3;
  l_check_column(4) := p_check_column4;
  l_check_column(5) := p_check_column5;

  -- save associated columns to global array

  g_associated_column(1) := p_associated_column1;
  g_associated_column(2) := p_associated_column2;
  g_associated_column(3) := p_associated_column3;
  g_associated_column(4) := p_associated_column4;
  g_associated_column(5) := p_associated_column5;

  -- Checks done for p_check_column1 then p_check_column2 etc... since
  -- we are more likely to find a match for p_check_column1

  -- check p_check_column1 against all associated columns in message list

  FOR J IN 1..G_max_cols LOOP
    if l_check_column(J) is not null then

      -- check columns against all associated columns in message list
      -- assume number of check columns is equal to the number of
      -- associated columns

      FOR I IN 1..G_msg_tbl.COUNT LOOP
        if G_msg_tbl(I).message_type = FND_MSG_PUB.G_ERROR_MSG and
           Is_Exclusive_Msg_Error(I) then
          FOR K IN 1..G_max_cols LOOP
            if l_check_column(J) = Get_Associated_Col(I,K) then
              -- Now add dummy message to the dependency list
              fnd_msg_pub.Add_Detail
                (p_associated_column1      => p_associated_column1
                ,p_associated_column2      => p_associated_column2
                ,p_associated_column3      => p_associated_column3
                ,p_associated_column4      => p_associated_column4
                ,p_associated_column5      => p_associated_column5
                ,p_same_associated_columns => 'F'
                ,p_message_type            => FND_MSG_PUB.G_DEPENDENCY_MSG
                );
              return 'F';
            end if;
          END LOOP;
        end if;
      END LOOP;

      -- check columns against all associated columns in dependency list

      FOR I IN 1..G_dep_tbl.COUNT LOOP
        if Is_Exclusive_Dep_Error(I) then
          FOR K IN 1..G_max_cols LOOP
            if l_check_column(J) = Get_Dependency_Col(I,K) then
              -- Now add dummy message to the dependency list
              fnd_msg_pub.Add_Detail
                (p_associated_column1      => p_associated_column1
                ,p_associated_column2      => p_associated_column2
                ,p_associated_column3      => p_associated_column3
                ,p_associated_column4      => p_associated_column4
                ,p_associated_column5      => p_associated_column5
                ,p_same_associated_columns => 'F'
                ,p_message_type            => FND_MSG_PUB.G_DEPENDENCY_MSG
                );
              return 'F';
            end if;
          END LOOP;
        end if;
      END LOOP;
    end if;
  END LOOP;

  -- no errors found matching check columns so return true

  return 'T';

END No_Exclusive_Error;

--  FUNCTION   No_Error_Message
--

FUNCTION    No_Error_Message
(   p_check_message_name1 IN VARCHAR2
   ,p_check_message_name2 IN VARCHAR2 default null
   ,p_check_message_name3 IN VARCHAR2 default null
   ,p_check_message_name4 IN VARCHAR2 default null
   ,p_check_message_name5 IN VARCHAR2 default null
   ,p_associated_column1 IN VARCHAR2 default null
   ,p_associated_column2 IN VARCHAR2 default null
   ,p_associated_column3 IN VARCHAR2 default null
   ,p_associated_column4 IN VARCHAR2 default null
   ,p_associated_column5 IN VARCHAR2 default null
) return varchar2
IS

l_message_name varchar2(30);
l_application  varchar2(50);

BEGIN

  -- save associated columns to global array

  g_associated_column(1) := p_associated_column1;
  g_associated_column(2) := p_associated_column2;
  g_associated_column(3) := p_associated_column3;
  g_associated_column(4) := p_associated_column4;
  g_associated_column(5) := p_associated_column5;

  FOR I IN 1..G_msg_tbl.COUNT LOOP
    -- only check error messages
    if G_msg_tbl(I).message_type = FND_MSG_PUB.G_ERROR_MSG then

      -- get the message name from the encoded message

      fnd_message.parse_encoded
           (encoded_message => G_msg_tbl(I).encoded_message
           ,app_short_name => l_application
           ,message_name => l_message_name);

      if l_message_name = p_check_message_name1 or
         l_message_name = p_check_message_name2 or
         l_message_name = p_check_message_name3 or
         l_message_name = p_check_message_name4 or
         l_message_name = p_check_message_name5 then

        fnd_msg_pub.Add_Detail
                (p_associated_column1      => p_associated_column1
                ,p_associated_column2      => p_associated_column2
                ,p_associated_column3      => p_associated_column3
                ,p_associated_column4      => p_associated_column4
                ,p_associated_column5      => p_associated_column5
                ,p_same_associated_columns => 'F'
                ,p_message_type            => FND_MSG_PUB.G_DEPENDENCY_MSG
                );
        return 'F';

      end if;

    end if;
  END LOOP;

  -- no errors found matching so return true

  return 'T';

END No_Error_Message;

--  PROCEDURE  Set_Search_Name
--

PROCEDURE    Set_Search_Name
(   p_application  IN VARCHAR2
   ,p_message_name IN VARCHAR2
)
IS
BEGIN

    G_ser_msgname := p_message_name;
    G_ser_msgdata := '';
    G_ser_msgset  := TRUE;
    G_ser_msgapp  := p_application;

END Set_Search_Name;

--  PROCEDURE  Set_Search_Token
--

PROCEDURE    Set_Search_Token
(   p_token     in varchar2
   ,p_value     in varchar2
   ,p_translate in boolean default false
)
IS
l_flag varchar2(1);
BEGIN

    if p_translate then
        l_flag := 'Y';
    else
        l_flag := 'N';
    end if;
    /* Note that we are intentionally using chr(0) rather than */
    /* FND_GLOBAL.LOCAL_CHR() for a performance bug (982909) */
    G_ser_msgdata := G_ser_msgdata||l_flag||chr(0)||p_token||chr(0)||p_value||chr(0);

END Set_Search_Token;

--  FUNCTION 	Match_Msg
--
--                Usage: Details of the message to search for must first
--                       be set by calling Set_Search_Message and
--                       optionally calling Set_Search_Token. This
--                       function will return 0 if the message
--                       is not found or the message number if it was found
--
--
--

FUNCTION Match_Msg return number
IS

l_token Msg_Token_Tbl;
l_search_token Msg_Token_Tbl;
l_count number;
l_message_name varchar2(30);
l_application  varchar2(50);
l_start_position number;
l_end_position number;
l_length number;

BEGIN

  -- first tokenize search tokens
  l_start_position := 3;
  l_count := 1;
  l_length := length(G_ser_msgdata);

  while l_start_position < l_length loop

    -- get token name and value from search string

    l_end_position := instr(G_ser_msgdata,chr(0),l_start_position);
    l_search_token(l_count).name := substrb(G_ser_msgdata
                                          ,l_start_position
                                          ,l_end_position-l_start_position);

    -- now get token value
    -- first encode the search message so we can call get_token

    fnd_message.set_encoded(G_ser_msgapp||chr(0)||G_ser_msgname||chr(0)||G_ser_msgdata);
    l_search_token(l_count).value := fnd_message.get_token(l_search_token(l_count).name);
    fnd_message.clear;

    l_count := l_count + 1;

    -- set start position to begining of next token
    l_start_position := instr(G_ser_msgdata,chr(0),l_end_position+1)+3;

  end loop;


  --  Loop through all messages

  for I in 1..G_msg_tbl.count loop

    -- get message name and app from encoded message

    fnd_message.parse_encoded
           (encoded_message => G_msg_tbl(I).encoded_message
           ,app_short_name => l_application
           ,message_name => l_message_name);

    -- check if message name/app matches

    if l_application = G_ser_msgapp and l_message_name = G_ser_msgname then

      -- check if any search tokens have been set - if so
      -- tokenize name/value pairs and see if there's a match
      -- check if message tokens match all those set in G_ser_msgdata

      -- first tokenize message tokens
      -- place start postion at begining of first token name
      l_start_position := instr(G_msg_tbl(I).encoded_message,chr(0),1,2) + 3;
      l_count := 1;
      l_length := length(G_msg_tbl(I).encoded_message);

      -- set the encoded message
      fnd_message.set_encoded(G_msg_tbl(I).encoded_message);

      while l_start_position < l_length loop

        -- get token name and value from encoded message

        l_end_position := instr(G_msg_tbl(I).encoded_message,chr(0),l_start_position);
        l_token(l_count).name := substrb(G_msg_tbl(I).encoded_message
                                       ,l_start_position
                                       ,l_end_position-l_start_position);

        -- now get token value
        l_token(l_count).value := fnd_message.get_token(l_token(l_count).name);

        l_count := l_count + 1;

        -- set start position to begining of next token
        l_start_position := instr(G_msg_tbl(I).encoded_message,chr(0),l_end_position+1)+3;

      end loop;

      -- now check if the search tokens match
      l_count := 0;
      for J in 1..l_search_token.count loop
        for K in 1..l_token.count loop
          if l_token(K).name = l_search_token(J).name and
             l_token(K).value = l_search_token(J).value then
            l_count := l_count + 1;
          end if;
        end loop;
      end loop;

      -- check if all the search tokens matched
      -- if a match is found for all the search tokens that were set
      -- or if no search tokens were set then
      -- the message will be deleted
      if l_count = l_search_token.count or l_search_token.count = 0 then
        return I;
      end if;

    end if;
    -- clear the message before moving to the next
    fnd_message.clear;

  end loop;

  -- no match found, therefore, return false
  -- reset search globals

  return 0;

END Match_Msg;

--  FUNCTION 	Delete_Msg
--
--                Usage: Provide similar functionality to the existing
--                       Delete_Msg procedure, except allows removal of
--                       a message when the caller knows the name of the
--                       message but not the position in the list.
--                       Details of the message to search for must first
--                       be set by calling Set_Search_Message and
--                       optionally calling Set_Search_Token. This
--                       function will return 'T' for TRUE or 'F' for
--                       FALSE to indicate if the specified message had
--                       actually been found and removed.
--
--
--

FUNCTION Delete_Msg return varchar2
IS

l_message_number number;

BEGIN

  -- return if message has not been set
  if G_ser_msgset  = FALSE then
    return 'F';
  end if;

  -- Find the number of the matching message
  l_message_number := Match_Msg;

  -- clear the globals
  G_ser_msgname := null;
  G_ser_msgdata := null;
  G_ser_msgset  := FALSE;
  G_ser_msgapp  := null;

  if l_message_number <> 0 then
    Delete_Msg(l_message_number);
    return 'T';
  else
    return 'F';
  end if;


END Delete_Msg;

--  FUNCTION 	Change_Msg
--
--               Usage: Allows an existing message in the Multiple
--                       Message list to be changed for a different
--                       message name. Provides a useful utility,
--                       so the caller does have to explicitly delete a
--                       message and create a new entry. Details of the
--                       message to search for must first be set by
--                       calling Set_Search_Message and optionally
--                       Set_Search_Token. Details of the replacement
--                       message must first be set by calling
--                       fnd_message.set_message and optionally
--                       fnd_message.set_token. This function will return
--                       'T' for TRUE or 'F' for FALSE to indicate if the
--                       specified message had actually been found and
--                       changed. Any associated_column and error type
--                       details will not be altered. If the message to
--                       be replaced is not found in the list no error is
--                       raised.
--
--

FUNCTION Change_Msg return varchar2
IS

l_save_new_message varchar2(2000);
l_message_number number;

BEGIN

  -- return if message has not been set
  if G_ser_msgset  = FALSE then
    return 'F';
  end if;

  -- save new message to local variable, return if not set
  l_save_new_message := fnd_message.get_encoded;
  if l_save_new_message = '' then
    return 'F';
  end if;

  -- Find the number of the matching message
  l_message_number := Match_Msg;

  -- clear the globals
  G_ser_msgname := null;
  G_ser_msgdata := null;
  G_ser_msgset  := FALSE;
  G_ser_msgapp  := null;

  if l_message_number <> 0 then
    G_msg_tbl(l_message_number).encoded_message := l_save_new_message;
    fnd_message.clear;
    return 'T';
  else
    return 'F';
  end if;

END Change_Msg;

--  FUNCTION 	Get_Detail
--

FUNCTION    Get_Detail
(   p_msg_index	    IN	NUMBER	    := G_NEXT
   ,p_encoded	    IN	VARCHAR2    := 'T'
) return varchar2
IS
l_msg_index NUMBER := G_msg_index;
l_col_string VARCHAR2(2000) := '';
l_separator VARCHAR2(1) :='';
l_check boolean;
BEGIN

    IF p_msg_index = G_NEXT THEN
	G_msg_index := G_msg_index + 1;
    ELSIF p_msg_index = G_FIRST THEN
	G_msg_index := 1;
    ELSIF p_msg_index = G_PREVIOUS THEN
	G_msg_index := G_msg_index - 1;
    ELSIF p_msg_index = G_LAST THEN
	G_msg_index := G_msg_count ;
    ELSE
	G_msg_index := p_msg_index ;
    END IF;

    -- generate a colon delimited string of associated columns
    for J IN 1..G_max_cols loop
      if Get_Associated_Col(G_msg_index,J) is not null then
        l_col_string := l_col_string || l_separator || Get_Associated_Col(G_msg_index,J);
      end if;
      if J = 1 then
        l_separator := ':';
      end if;
    end loop;

    -- add the string as a token

    FND_MESSAGE.SET_ENCODED ( G_msg_tbl( G_msg_index ).encoded_message );
    FND_MESSAGE.SET_TOKEN ( G_associated_cols_token_name, l_col_string );

    -- add the message type as a token

    FND_MESSAGE.SET_TOKEN ( G_message_type_token_name, G_msg_tbl( G_msg_index ).message_type );


    IF ( FND_API.To_Boolean( p_encoded ) ) THEN

	return FND_MESSAGE.GET_ENCODED;

    ELSE

	return FND_MESSAGE.GET;

    END IF;


EXCEPTION

    WHEN NO_DATA_FOUND THEN

        --  No more messages, revert G_msg_index and return NULL;

        G_msg_index := l_msg_index;

	return null;

END Get_Detail;

END FND_MSG_PUB ;
/