CREATE OR REPLACE PACKAGE APPS.FND_MSG_PUB AUTHID CURRENT_USER AS
/* $Header: AFASMSGS.pls 120.2 2005/11/03 15:47:48 tmorrow ship $ */

--  Global constants used by the Get function/procedure to
--  determine which message to get.

    G_FIRST	    CONSTANT	NUMBER	:=  -1	;
    G_NEXT	    CONSTANT	NUMBER	:=  -2	;
    G_LAST	    CONSTANT	NUMBER	:=  -3	;
    G_PREVIOUS	    CONSTANT	NUMBER	:=  -4	;

--  global that holds the value of the message level profile option.

    G_msg_level_threshold	NUMBER    	:= 9.99E125;

--  Procedure	Initialize
--
--  Usage	Used by API callers and developers to intialize the
--		global message table.
--  Desc	Clears the G_msg_tbl and resets all its global
--		variables. Except for the message level threshold.
--

PROCEDURE Initialize;

--  FUNCTION	Count_Msg
--
--  Usage	Used by API callers and developers to find the count
--		of messages in the  message list.
--  Desc	Returns the value of G_msg_count
--
--  Parameters	None
--
--  Return	NUMBER

FUNCTION    Count_Msg  RETURN NUMBER;

--  PROCEDURE	Count_And_Get
--
--  Usage	Used by API developers to find the count of messages
--		in the message table. If there is only one message in
--		the table it retrieves this message.
--
--  Desc	This procedure is a cover that calls the function
--		Count_Msg and if the count of messages is 1. It calls the
--		procedure Get. It serves as a shortcut for API
--		developers. to make one call instead of making a call
--		to count, a check, and then another call to get.
--
--  Parameters	p_encoded   IN VARCHAR2(1) := 'T'    Optional
--		    If TRUE the message is returned in an encoded
--		    format, else it is translated and returned.
--		p_count OUT NUMBER
--		    Message count.
--		p_data	    OUT VARCHAR2(2000)
--		    Message data.
--

PROCEDURE    Count_And_Get
(   p_encoded		    IN	VARCHAR2    := 'T'    ,
    p_count		    OUT	NOCOPY NUMBER				    ,
    p_data		    OUT NOCOPY VARCHAR2
);

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

PROCEDURE Add;

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
--  Prameters	p_msg_index	IN NUMBER := NULL Optional
--		    holds the index of the message to be deleted.
--

PROCEDURE Delete_Msg
(   p_msg_index IN    NUMBER	:=	NULL
);

--  PROCEDURE 	Get
--
--  Usage	Used to get message info from the global message table.
--
--  Desc	Gets the next message from the message table.
--		This procedure utilizes the G_msg_index to keep track
--		of the last message fetched from the global table and
--		then fetches the next.
--
--  Parameters	p_msg_index	IN NUMBER := G_NEXT
--		    Index of message to be fetched. the default is to
--		    fetch the next message starting by the first
--		    message. Possible values are :
--
--		    G_FIRST
--		    G_NEXT
--		    G_LAST
--		    G_PREVIOUS
--		    Specific message index.
--
--		p_encoded   IN VARCHAR2(1) := G_TRUE	Optional
--		    When set to TRUE retieves the message in an
--		    encoded format. If FALSE, the function calls the
--		    message dictionary utilities to translate the
--		    message and do the token substitution, the message
--		    text is then returned.
--
--		p_msg_data	    OUT	VARCHAR2(2000)
--		p_msg_index_out	    OUT NUMBER

PROCEDURE    Get
(   p_msg_index	    IN	NUMBER	    := G_NEXT		,
    p_encoded	    IN	VARCHAR2    := 'T'              ,
    p_data	    OUT	NOCOPY VARCHAR2			,
    p_msg_index_out OUT	NOCOPY NUMBER
);

--  FUNCTION	Get
--
--  Usage	Used to get message info from the message table.
--
--  Desc	Gets the next message from the message table.
--		This procedure utilizes the G_msg_index to keep track
--		of the last message fetched from the table and
--		then fetches the next or previous message depending on
--		the mode the function is being called in..
--
--  Parameters	p_msg_index	IN NUMBER := G_NEXT
--		    Index of message to be fetched. the default is to
--		    fetch the next message starting by the first
--		    message. Possible values are :
--
--		    G_FIRST
--		    G_NEXT
--		    G_LAST
--		    G_PREVIOUS
--		    Specific message index.
--
--		p_encoded   IN VARCHAR2(1) := 'T'	Optional
--		    When set to TRUE Get retrieves the message in an
--		    encoded format. If FALSE, the function calls the
--		    message dictionary utilities to translate the
--		    message and do the token substitution, the message
--		    text is then returned.
--
--  Return	VARCHAR2(2000) message data.
--		If there are no more messages it returns NULL.
--
--  Notes	The function name Get is overloaded with another
--		procedure Get that performs the exact same function as
--		the function, the only difference is that the
--		procedure returns the message data as well as its
--		index i the message list.

FUNCTION    Get
(   p_msg_index	    IN NUMBER	:= G_NEXT	    ,
    p_encoded	    IN VARCHAR2 := 'T'
)
RETURN VARCHAR2;

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
--  Exceptions	G_EXC_UNEXPECTED_ERROR if it is passed an
--		invalid mode.

PROCEDURE Reset
( p_mode    IN NUMBER := G_FIRST );

--  Pre-defined API message levels
--
--  	Valid values for message levels are from 1-50.
--  	1 being least severe and 50 highest.
--
--  	The pre-defined levels correspond to standard API
--  	return status. Debug levels are used to control the amount of
--	debug information a program writes to the PL/SQL message table.

G_MSG_LVL_UNEXP_ERROR	CONSTANT NUMBER	:= 60;
G_MSG_LVL_ERROR	    	CONSTANT NUMBER	:= 50;
G_MSG_LVL_SUCCESS    	CONSTANT NUMBER	:= 40;
G_MSG_LVL_DEBUG_HIGH   	CONSTANT NUMBER	:= 30;
G_MSG_LVL_DEBUG_MEDIUM 	CONSTANT NUMBER	:= 20;
G_MSG_LVL_DEBUG_LOW   	CONSTANT NUMBER	:= 10;

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
)
RETURN BOOLEAN;

--  PROCEDURE	Build_Exc_Msg()
--
--  USAGE   	Used by APIs to issue a standard message when
--		encountering an unexpected error.
--  Desc    	The IN parameters are used as tokens to a standard
--		message 'FND_API_UNEXP_ERROR'.
--  Parameters	p_pkg_name  	    IN VARCHAR2(30)	Optional
--  	    	p_procedure_name    IN VARCHAR2(30)	Optional
--  	    	p_error_text  	    IN VARCHAR2(240)	Optional
--		    If p_error_text is missing SQLERRM is used.

PROCEDURE Build_Exc_Msg
(   p_pkg_name		IN VARCHAR2 :=null    ,
    p_procedure_name	IN VARCHAR2 :=null    ,
    p_error_text	IN VARCHAR2 :=null
);

--  PROCEDURE	Add_Exc_Msg()
--
--  USAGE   	Same as Build_Exc_Msg but in addition to constructing
--		the messages the procedure Adds it to the global
--		mesage table.

PROCEDURE Add_Exc_Msg
( p_pkg_name		IN VARCHAR2 :=null   ,
  p_procedure_name	IN VARCHAR2 :=null   ,
  p_error_text		IN VARCHAR2 :=null
);

--  PROCEDURE Dump_Msg and Dump_List are used for debugging purposes.
--

PROCEDURE    Dump_Msg
(   p_msg_index IN NUMBER );

PROCEDURE    Dump_List
(   p_messages	IN BOOLEAN  :=	FALSE );


--  global constants to hold message type

    G_ERROR_MSG       constant varchar2(1) := 'E';
    G_WARNING_MSG     constant varchar2(1) := 'W';
    G_INFORMATION_MSG constant varchar2(1) := 'I';
    G_DEPENDENCY_MSG  constant varchar2(1) := 'D';

--  Constants used to set token names for associated columns
--  and message type

    G_ASSOCIATED_COLS_TOKEN_NAME CONSTANT VARCHAR2(30) := 'FND_ERROR_LOCATION_FIELD';
    G_MESSAGE_TYPE_TOKEN_NAME CONSTANT VARCHAR2(30) := 'FND_MESSAGE_TYPE';

--  PROCEDURE   Add_Detail
--
--   Usage: Allows an Error, Warning or Information message to be added to the
--          Multiple Message List. The caller can optionally provide
--          details of which TABLE.COLUMN (or API control parameter) the error is
--          associated. In this case either the p_associated_column1 to 5
--          parameters should be populated with 'TABLE_NAME.COLUMN_NAME' or
--          the p_same_associated_columns parameter should be explicitly set to 'Y'.
--          The p_same_associated_columns parameter is defaulted to 'N' indicating
--          the p_associated_column1 to 5 parameter set in this function call
--          should be used. To use the p_associated_column1 to 5 parameter values
--          past into the most recent "verify" function call
--          (no_all_inclusive_error, no_exclusive_error or no_error_message)
--          then explicitly set p_same_associated_columns to 'Y'. Where a "verify"
--          function has been called, setting p_same_associated_columns to 'Y'
--          will avoid having to maintain the associated column information more
--          than once.
--
-- In Parameters:
--   Name                           Reqd Type     Description
--   p_associated_column1           No   varchar2 Database column or
--                                                API control parameter
--                                                name.
--   p_associated_column2           No   varchar2 Database column or
--                                                API control parameter
--                                                name.
--   p_associated_column3           No   varchar2 Database column or
--                                                API control parameter
--                                                name.
--   p_associated_column4           No   varchar2 Database column or
--                                                API control parameter
--                                                name.
--   p_associated_column5           No   varchar2 Database column or
--                                                API control parameter
--                                                name.
--   p_same_associated_columns      No   varchar2 Set to 'T' or 'F'.
--   p_message_type                 No   varchar2 Set to one of the
--                                                FND_MSG_PUB package
--                                                message type constants.




PROCEDURE    Add_Detail
(    p_associated_column1 IN VARCHAR2 default null
    ,p_associated_column2 IN VARCHAR2 default null
    ,p_associated_column3 IN VARCHAR2 default null
    ,p_associated_column4 IN VARCHAR2 default null
    ,p_associated_column5 IN VARCHAR2 default null
    ,p_same_associated_columns IN VARCHAR2 default 'F'
    ,p_message_type IN VARCHAR2 default FND_MSG_PUB.G_ERROR_MSG
);


--  FUNCTION   No_All_Inclusive_Error
--    Usage: For finding out if there are any known messages
--           associated, with any column in a set of
--           TABLE.COLUMN values (or set of API control parameters).
--           i.e. Search the message lists for each TABLE.COLUMN.
--           If any message contains that TABLE.COLUMN then
--           a match has been found.
--           Details:
--           Returns 'T' for TRUE when any p_check_column%
--           parameter (TABLE.COLUMN) value is NOT
--           associated with an existing error message in the
--           either the Multiple Message List or the internal
--           Dependency Chain List. Returns 'F' for FALSE
--           when at least one of the p_check_column1 to 5
--           parameter values is associated with an existing
--           error message in either list. If the
--           p_assoicated_column% parameter has also been set
--           then a message will be added to the Dependency
--           Chain List and will be associated with the
--           p_associated_column% values.
--
--     For example, say the message list contains two entries:
--       Message_1  associated with TABLE_A.COLUMN_1
--       Message_2  associated with TABLE_A.COLUMN_2 and TABLE_A.COLUMN_3
--
--       Calls to this function and results:
--       a) p_check_column1 parameter set to 'TABLE_A.COLUMN_4'
--          TRUE will be returned.
--       b) p_check_column1 parameter set to 'TABLE_A.COLUMN_1'
--          FALSE will be returned.
--       c) p_check_column1 parameter set to 'TABLE_A.COLUMN_2'
--          FALSE will be returned.
--       d) p_check_column1 parameter set to 'TABLE_A.COLUMN_1' and
--          p_check_column2 parameter set to 'TABLE_A.COLUMN_2'
--          FALSE will be returned.
--       e) p_check_column1 parameter set to 'TABLE_A.COLUMN_2' and
--          p_check_column2 parameter set to 'TABLE_A.COLUMN_3'
--          FALSE will be returned.
--       f) p_check_column1 parameter set to 'TABLE_A.COLUMN_2' and
--          p_check_column2 parameter set to 'TABLE_A.COLUMN_4'
--          FALSE will be returned.
--
-- In Parameters:
--   Name                           Reqd Type     Description
--   p_check_column1                Yes  varchar2 Column or API control
--                                                parameter name to
--                                                verify in the message
--                                                list.
--   p_check_column2                No   varchar2 Column or API control
--                                                parameter name to
--                                                verify in the message
--                                                list.
--   p_check_column3                No   varchar2 Column or API control
--                                                parameter name to
--                                                verify in the message
--                                                list.
--   p_check_column4                No   varchar2 Column or API control
--                                                parameter name to
--                                                verify in the message
--                                                list.
--   p_check_column5                No   varchar2 Column or API control
--                                                parameter name to
--                                                verify in the message
--                                                list.
--   p_associated_column1           No   varchar2 Dependent database
--                                                column or API
--                                                control parameter
--                                                name. Only used if
--                                                an existing message
--                                                is found.
--   p_associated_column2           No   varchar2 Dependent database
--                                                column or API
--                                                control parameter
--                                                name. Only used if
--                                                an existing message
--                                                is found.
--   p_associated_column3           No   varchar2 Dependent database
--                                                column or API
--                                                control parameter
--                                                name. Only used if
--                                                an existing message
--                                                is found.
--   p_associated_column4           No   varchar2 Dependent database
--                                                column or API
--                                                control parameter
--                                                name. Only used if
--                                                an existing message
--                                                is found.
--   p_associated_column5           No   varchar2 Dependent database
--                                                column or API
--                                                control parameter
--                                                name. Only used if
--                                                an existing message
--                                                is found.


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
) return varchar2;

--  FUNCTION   No_Exclusive_Error
-- Usage: For finding out if there are any known single
--        column messages for a set of up to five
--        TABLE.COLUMN values. Any messages for more
--        than one column will not included in the
--        search. Useful when about to execute a
--        "combination style" validation check between a
--        group of columns. Alternatively messages can
--        be associated with API control parameters
--        rather than table columns.
--
--        For example, a validation check needs to verify
--        that the COLUMN_A and COLUMN_B column values
--        are compatible. This validation should only
--        go ahead if the individual COLUMN_A and
--        individual COLUMN_B values is not known to
--        be error. But need to ignore any errors
--        which have been raised by other combination
--        style checks such as COLUMN_A-COLUMN_C.
--        Details:
--        Returns 'T' for TRUE when each of the
--        p_check_column1 to 5 parameter values are NOT
--        exclusively associated with an existing error
--        message in the either the Multiple Message List
--        or the internal Dependency Chain List.
--        Returns 'F' for FALSE when at least one of the
--        p_check_column1 to 5 parameter values is
--        exclusively associated with an existing error
--        message in either list. If any of the
--        p_assoicated_column% parameters have also
--        been set then an entry will be added to the
--        Dependency Chain List and will be associated
--        with the p_assoicated_column1 to 5 values.
--
--     Example: say the message list contains two entries:
--       Message_1  associated with TABLE_A.COLUMN_1
--       Message_2  associated with TABLE_A.COLUMN_2 and TABLE_A.COLUMN_3
--
--       Calls to this function and results:
--       a) p_check_column1 parameter set to 'TABLE_A.COLUMN_4'
--          TRUE will be returned.
--       b) p_check_column1 parameter set to 'TABLE_A.COLUMN_1'
--          FALSE will be returned.
--       c) p_check_column1 parameter set to 'TABLE_A.COLUMN_2'
--          TRUE will be returned.
--       d) p_check_column1 parameter set to 'TABLE_A.COLUMN_1' and
--          p_check_column2 parameter set to 'TABLE_A.COLUMN_2'
--          FALSE will be returned.
--       e) p_check_column1 parameter set to 'TABLE_A.COLUMN_2' and
--          p_check_column2 parameter set to 'TABLE_A.COLUMN_3'
--          TRUE will be returned.
--       f) p_check_column1 parameter set to 'TABLE_A.COLUMN_2' and
--          p_check_column2 parameter set to 'TABLE_A.COLUMN_4'
--          TRUE will be returned.
--
-- In Parameters:
--   Name                           Reqd Type     Description
--   p_check_column1                Yes  varchar2 Column or API control
--                                                parameter name to
--                                                verify in the message
--                                                list.
--   p_check_column2                No   varchar2 Column or API control
--                                                parameter name to
--                                                verify in the message
--                                                list.
--   p_check_column3                No   varchar2 Column or API control
--                                                parameter name to
--                                                verify in the message
--                                                list.
--   p_check_column4                No   varchar2 Column or API control
--                                                parameter name to
--                                                verify in the message
--                                                list.
--   p_check_column5                No   varchar2 Column or API control
--                                                parameter name to
--                                                verify in the message
--                                                list.
--   p_associated_column1           No   varchar2 Dependent database
--                                                column or API
--                                                control parameter
--                                                name. Only used if
--                                                an existing message
--                                                is found.
--   p_associated_column2           No   varchar2 Dependent database
--                                                column or API
--                                                control parameter
--                                                name. Only used if
--                                                an existing message
--                                                is found.
--   p_associated_column3           No   varchar2 Dependent database
--                                                column or API
--                                                control parameter
--                                                name. Only used if
--                                                an existing message
--                                                is found.
--   p_associated_column4           No   varchar2 Dependent database
--                                                column or API
--                                                control parameter
--                                                name. Only used if
--                                                an existing message
--                                                is found.
--   p_associated_column5           No   varchar2 Dependent database
--                                                column or API
--                                                control parameter
--                                                name. Only used if
--                                                an existing message
--                                                is found.



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
) return varchar2;

--  FUNCTION   No_Error_Message
--      Usage: Returns 'T' for TRUE when none of the
--             p_check_message_name1 to 5 parameter message
--             name values do not exist in the Multiple
--             Message List.
--             Returns 'F' for FALSE when at least one of the
--             p_check_message_name1 to 5 parameter message
--             names is found to exist in the list. If the
--             p_associated_column% parameter has also been set
--             then a message will be added to the Dependency
--             Chain List and will be associated with the
--             p_associated_column% values.
--
--     For example, say the message list contains two entries:
--       Message_1  associated with TABLE_A.COLUMN_1
--       Message_2  associated with TABLE_A.COLUMN_2 and TABLE_A.COLUMN_3
--
--       Calls to this function and results:
--       a) p_check_message_name1 parameter set to 'Message_3'
--          TRUE will be returned.
--       b) p_check_message_name1 parameter set to 'Message_1'
--          FALSE will be returned.
--       c) p_check_message_name1 parameter set to 'Message_1' and
--          p_check_message_name2 parameter set to 'Message_2'
--          FALSE will be returned.
--       d) p_check_message_name1 parameter set to 'Message_2' and
--          p_check_message_name2 parameter set to 'Message_3'
--          FALSE will be returned.
--
-- In Parameters:
--   Name                           Reqd Type     Description
--   p_check_message_name1          Yes  varchar2 Application Error
--                                                Message Name to
--                                                verify in the list.
--   p_check_message_name2          No   varchar2 Application Error
--                                                Message Name to
--                                                verify in the list.
--   p_check_message_name3          No   varchar2 Application Error
--                                                Message Name to
--                                                verify in the list.
--   p_check_message_name4          No   varchar2 Application Error
--                                                Message Name to
--                                                verify in the list.
--   p_check_message_name5          No   varchar2 Application Error
--                                                Message Name to
--                                                verify in the list.
--   p_associated_column1           No   varchar2 Dependent database
--                                                column or API
--                                                control parameter
--                                                name. Only used if
--                                                an existing error
--                                                is found.
--   p_associated_column2           No   varchar2 Dependent database
--                                                column or API
--                                                control parameter
--                                                name. Only used if
--                                                an existing error
--                                                is found.
--   p_associated_column3           No   varchar2 Dependent database
--                                                column or API
--                                                control parameter
--                                                name. Only used if
--                                                an existing error
--                                                is found.
--   p_associated_column4           No   varchar2 Dependent database
--                                                column or API
--                                                control parameter
--                                                name. Only used if
--                                                an existing error
--                                                is found.
--   p_associated_column5           No   varchar2 Dependent database
--                                                column or API
--                                                control parameter
--                                                name. Only used if
--                                                an existing error
--                                                is found.
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
) return varchar2;

--  PROCEDURE  Set_Search_Name
--
--      Usage: To register the message name search criteria
--             to be used when the Delete_Msg or Change_Msg
--             functions are called. Refer to those two
--             function specifications for example calls.
--             Values will not be used by the existing
--             Delete_Msg(p_msg_index) procedure.

PROCEDURE    Set_Search_Name
(   p_application  IN VARCHAR2
   ,p_message_name IN VARCHAR2
);

--  PROCEDURE  Set_Search_Token
--      Usage: To register a message token name and value
--             search criteria, to be used when the Delete_Msg
--             or Change_Msg functions are called. Refer to the
--             those two function specifications for example
--             calls. Values will not be used by the existing
--             Delete_Msg procedure. It is optional to call
--             this procedure. When used must be called after
--             Set_Search_Name. Can be called multiple times
--             when more than one token needs to be set in the
--             search criteria.
--

PROCEDURE    Set_Search_Token
(   p_token     in varchar2
   ,p_value     in varchar2
   ,p_translate in boolean default false
);

--  FUNCTION    Delete_Msg
--
--        Usage: Provide similar functionality to the existing
--               Delete_Msg procedure, except allows removal of
--               a message when the caller knows the name of the
--               message but not the position in the list.
--               Details of the message to search for must first
--               be set by calling Set_Search_Message and
--               optionally calling Set_Search_Token. This
--               function will return 'T' for TRUE or 'F' for
--               FALSE to indicate if the specified message had
--               actually been found and removed.
--
--              Example: To remove the 'MESSAGE1' message or the
--                       'MESSAGE2' message with
--                       certain token values from anywhere in the list.
--
--                         fnd_msg_pub.set_search_name
--                           ('FND' ,'MESSAGE1');
--                         l_found := fnd_msg_pub.delete_msg;
--                         fnd_msg_pub.set_search_name
--                           ('FND', 'MESSAGE2');
--                         fnd_msg_pub.set_search_token
--                           ('TOKEN1', 'VALUE1');
--                         fnd_msg_pub.set_search_token
--                           ('TOKEN2', 'VALUE2');
--                         fnd_msg_pub.Delete_Msg;
--
--
--
--

FUNCTION Delete_Msg return varchar2;

--  FUNCTION    Change_Msg
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
--                       raised and fnd_message.clear is called
--
--              Example: If the 'MESSAGE1' message exists change it to
--                       'MESSAGE2'.
--
--                         fnd_msg_pub.set_search_name
--                           ('FND', 'MESSAGE1');
--                         fnd_message.set_name
--                           ('FND','MESSAGE2');
--                         fnd_msg_pub.change_msg;
--
--

FUNCTION Change_Msg return varchar2;

--  FUNCTION    Get_Detail
--      Usage: Used by the OAFramework Java Helper classes
--             to retrieve the message details from the
--             DataServer tier to the Middle tier.
--             This functionreturns all the details
--             for each entry in the Multiple Error Message
--             List. Where provided Associated column and
--             message type information will be incorporated as
--             token values in the encoded message. Using token
--             names G_ASSOCIATED_COLS_TOKEN_NAME and
--             G_MESSAGE_TYPE_TOKEN_NAME. Entries in the Dependency
--             Chain List are not returned.
--
-- Parameters: p_msg_index IN  NUMBER   default G_NEXT
--             p_encoded   IN  VARCHAR2 default 'T'
--
--

FUNCTION    Get_Detail
(   p_msg_index     IN  NUMBER      := G_NEXT
   ,p_encoded       IN  VARCHAR2    := 'T'
) return varchar2;





END FND_MSG_PUB ;
/
