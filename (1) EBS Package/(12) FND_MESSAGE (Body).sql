CREATE OR REPLACE package body APPS.FND_MESSAGE as
/* $Header: AFNLMSGB.pls 120.10 2008/02/11 18:13:27 emiranda ship $ */

    MSGNAME varchar2(30);
    MSGDATA varchar2(32000);
    MSGSET  boolean := FALSE;
    MSGAPP  varchar2(50);
    GLOBAL_AUTO_LOG boolean := TRUE;
    DEFAULT_FND_LOG_MODULE varchar2(255) := 'fnd.plsql.FND_MESSAGE.auto_log';
    FND_LOG_MODULE varchar2(255) := DEFAULT_FND_LOG_MODULE;

    TYPE MSG_REC_TYPE is RECORD (
         message_name     VARCHAR(90), -- Concat of MSGNAME(30), LANGCODE(4), APPSHRT(50)
         message_text     FND_NEW_MESSAGES.message_text%TYPE,
         message_number   FND_NEW_MESSAGES.message_number%TYPE,
         type             FND_NEW_MESSAGES.type%TYPE,
         fnd_log_severity FND_NEW_MESSAGES.fnd_log_severity%TYPE,
         category         FND_NEW_MESSAGES.category%TYPE,
         severity         FND_NEW_MESSAGES.severity%TYPE
    );

    type MSG_TAB_TYPE  is table of MSG_REC_TYPE index by binary_integer;

    TABLE_SIZE    binary_integer := 8192;   /* the cache size */
    INSERTED      boolean := FALSE;


     /*
      ** define the internal table that will cache the messages
      */
      MSG_TAB       MSG_TAB_TYPE;

-------------------- Cache Routines  AOL - INTERNAL ONLY -----------------------------------

/*
** find - find index of an option name in the given table
**
** RETURNS
**    table index if found, TABLE_SIZE if not found.
*/
function FIND(NAME in varchar2, msg_table in MSG_TAB_TYPE)
	return binary_integer is

	TAB_INDEX  binary_integer;
	FOUND      boolean;
	HASH_VALUE number;
	NAME_UPPER varchar2(90); -- Concat of MSGNAME(30), LANGCODE(4), APPSHRT(50)

begin

	NAME_UPPER := upper(NAME);
	TAB_INDEX := dbms_utility.get_hash_value(NAME_UPPER,1,TABLE_SIZE);

	if (msg_table.EXISTS(TAB_INDEX)) then

		if (msg_table(TAB_INDEX).message_name = NAME_UPPER) then
			return TAB_INDEX;
		else

			HASH_VALUE := TAB_INDEX;
			FOUND := false;

			while (TAB_INDEX < TABLE_SIZE) and (not FOUND) loop
				if (msg_table.EXISTS(TAB_INDEX)) then
					if msg_table(TAB_INDEX).message_name = NAME_UPPER then
						FOUND := true;
					else
						TAB_INDEX := TAB_INDEX + 1;
					end if;
				else
					return TABLE_SIZE+1;
				end if;
			end loop;

			if (not FOUND) then /* Didn't find any till the end */
				TAB_INDEX := 1;  /* Start from the beginning */
				while (TAB_INDEX < HASH_VALUE)  and (not FOUND) loop
					if (msg_table.EXISTS(TAB_INDEX)) then
						if msg_table(TAB_INDEX).message_name = NAME_UPPER then
							FOUND := true;
						else
							TAB_INDEX := TAB_INDEX + 1;
						end if;
					else
						return TABLE_SIZE+1;
					end if;
				end loop;
			end if;

			if (not FOUND) then
				return TABLE_SIZE+1;  /* Return a higher value */
			end if;

		end if;

	else
		return TABLE_SIZE+1;
	end if;

	return TAB_INDEX;

exception
	when others then  /* The entry doesn't exists */
		return TABLE_SIZE+1;
end;

/*
** find - find index of an option name
**
** RETURNS
**    table index if found, TABLE_SIZE if not found.
*/
function FIND(NAME in varchar2) return binary_integer is
	TAB_INDEX  binary_integer;
	FOUND      boolean;
	HASH_VALUE number;
begin

	return FIND(NAME,MSG_TAB);

exception
	when others then  /* The entry doesn't exists */
		return TABLE_SIZE+1;
end;

/*
** put - Set or Insert a Message
*/
procedure PUT(
	NAME		in	varchar2,
	VAL		in	MSG_REC_TYPE,
	msg_table	in out NOCOPY MSG_TAB_TYPE)
is
	TABLE_INDEX binary_integer;
	STORED      boolean;
	HASH_VALUE  number;
	NAME_UPPER  varchar2(90); -- Concat of MSGNAME(30), LANGCODE(4), APPSHRT(50)
begin

	NAME_UPPER := upper(NAME);

	/*
	** search for the option name
	*/
	STORED := false;
	TABLE_INDEX := dbms_utility.get_hash_value(NAME_UPPER,1,TABLE_SIZE);
	if (msg_table.EXISTS(TABLE_INDEX)) then
		if (msg_table(TABLE_INDEX).message_name = NAME_UPPER) then	/* Found the message */
			msg_table(TABLE_INDEX) := VAL;	/* Store the new value */
			STORED := TRUE;
		else	/* Collision */
			HASH_VALUE := TABLE_INDEX;	/* Store the current spot */

			while (TABLE_INDEX < TABLE_SIZE) and (not STORED) loop
				if (msg_table.EXISTS(TABLE_INDEX)) then
					if (msg_table(TABLE_INDEX).message_name = NAME_UPPER) then
						msg_table(TABLE_INDEX) := VAL;
						STORED := true;
					else
						TABLE_INDEX := TABLE_INDEX + 1;
					end if;
				else
					msg_table(TABLE_INDEX) := VAL;
					STORED := true;
				end if;
			end loop;

			if (not STORED) then	/* Didn't find any free bucket till the end*/
				TABLE_INDEX := 1;

				while (TABLE_INDEX < HASH_VALUE) and (not STORED) loop
					if (msg_table.EXISTS(TABLE_INDEX)) then
						if (msg_table(TABLE_INDEX).message_name = NAME_UPPER) then
							msg_table(TABLE_INDEX) := VAL;
							STORED := true;
						else
							TABLE_INDEX := TABLE_INDEX + 1;
						end if;
					else
						msg_table(TABLE_INDEX) := VAL;
						STORED := true;
					end if;
				end loop;
			end if;
                        if (not STORED) then
                              msg_table(HASH_VALUE) := VAL;    /* Store its value  */
                              STORED := TRUE;
                        end if;
		end if;
	else
		msg_table(TABLE_INDEX) := VAL;    /* Store its value  */
		STORED := TRUE;
	end if;

	if (STORED) then
		INSERTED := TRUE;
	end if;
exception
	when others then
		null;
end;

/*
** put - Set or Insert a message
*/
procedure PUT(NAME in varchar2, VAL in MSG_REC_TYPE) is
	TABLE_INDEX binary_integer;
	STORED      boolean;
	HASH_VALUE  number;
begin
	PUT(NAME,VAL,MSG_TAB);
end;

-------------------------------- END of cache routines ----------------------------------

--------------------------- TOKEN REPLACEMENT ROUTINES - AOL Internal -------------------
/****************************************************************************
This procedure will take an input string(p_build_msg), determine if there is
an EXACT match between the input token and a token contained in the message.
If there is a match, the beginning location of the token in the message
is returned.
p_build_msg is the input string.
p_token is the string that must be matched within the input string.
p_srch_begin is the location in the string where the search for token begins.
x_tok_begin is the location in the string of the matched token.
***************************************************************************/

    procedure find_token(
    p_build_msg     IN   VARCHAR2,
    p_token         IN   VARCHAR2,
    p_srch_begin    IN   NUMBER,
    x_tok_begin     OUT  NOCOPY NUMBER)

    IS

    l_start              NUMBER;
    l_check_pos          NUMBER;
    l_char_after_pos     NUMBER;
    -- This creates 'Buffer Overflow' error for Multibyte character langauges.
    -- Hence commenting.
    -- l_char_after         VARCHAR2(1);

    -- Bug 6634185.
    -- This variable requires NVARCHAR declaration to handle multibyte languages
    -- WARNING!!!
    -- NVARCHAR2 introduces dependency with RDBMS 9i version for FND_MESSAGE pkg
    -- So this change can't be backported to older 11i RUPs like RUP4 which are
    -- still certified with RDBMS 8i. Only since 11i RUP6, RDBMS 9i is mandatory
    -- WARNING!!!
    l_char_after         NVARCHAR2(1);
    ALPHANUMERIC_UNDERSCORE_MASK     CONSTANT VARCHAR2(255)  :=
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_';

    BEGIN

       l_start := p_srch_begin;

       LOOP
          -- Find the ampersand token value in the string.
          -- This signifies a possible token match.
          -- We say possible because the match could be a partial match to
          -- another token name (i.e. VALUE in VALUESET).
             l_check_pos := INSTR(p_build_msg, '&' || p_token, l_start);
          IF (l_check_pos = 0) THEN
             -- No more potential token matches exist in string.
             -- Return o for token position
             x_tok_begin := 0;
             EXIT;
          END IF;

          -- Insure that match is not '&&' variable indicating an access key
          IF ((l_check_pos <> 1) AND
              (substr(p_build_msg, l_check_pos - 1, 1) = '&')) THEN
             l_start := l_check_pos + 2;
          ELSE

             -- Determine if the potential match for the token is an EXACT match
             --  or only a partial matc.
             -- Determine if the character following the token match is an
             --  acceptable trailing character for a token (i.e. something
             --  other than an English uppercase alphabetic character,
             --  a number, or an underscore - these indicate the token name
             --  has additional characters)
             -- If so, the token is considered an exact match.
             l_char_after_pos := l_check_pos + LENGTH(p_token) + 1;
             l_char_after := substr(p_build_msg, l_char_after_pos, 1);
             IF ((INSTR(ALPHANUMERIC_UNDERSCORE_MASK, l_char_after) = 0) OR
                 (l_char_after_pos > LENGTH(p_build_msg))) THEN
                x_tok_begin := l_check_pos;
                EXIT;
             ELSE
                l_start := l_char_after_pos;
             END IF;
          END IF;
       END LOOP;
    END find_token;


/****************************************************************************
This procedure will take an input string(p_msg),  call find_token to determine
if there is an EXACT match between the input token and a token contained in
the message, and replace the instance of the token found in the message
text with the input token value. The code loops until all instances of the
token name are found in the message text.
p_msg is the input string.
p_token is the string that must be replaced within the input string.
p_token_val is the value to replace a token name in the message string.
x_msg is the output string with matched token names replaced with token values
***************************************************************************/

    procedure token_value_replace(
    p_msg         IN  VARCHAR2,
    p_token       IN  VARCHAR2,
    p_token_val   IN  VARCHAR2,
    x_msg         OUT NOCOPY VARCHAR2)

    IS
    l_token_exists NUMBER;
    l_token        VARCHAR2(30);
    l_build_tmpmsg VARCHAR2(2000);
    l_msg          VARCHAR2(2000);
    l_srch_begin   NUMBER;
    l_tok_begin    NUMBER;

    BEGIN
        -- Check to see if any tokens exist in the error message
        l_token := p_token;
        l_token_exists := instr(p_msg, '&' || l_token);

        /* If the input token isn't found in the message text, */
        /* try the uppercased version of the token name in case */
        /* the caller is (wrongly) passing a mixed case token name */
        /* As of July 99 all tokens in msg text should be */
        /* uppercase. */
        IF (l_token_exists = 0) THEN
             l_token := UPPER(l_token);
             l_token_exists := instr(p_msg, '&' || l_token);
        END IF;

        -- Only process if instances of the token exist in the msg
        IF(l_token_exists <> 0)THEN
             l_build_tmpmsg := '';
             l_srch_begin := 1;
             l_msg := p_msg;

             LOOP

               find_token(l_msg, l_token, l_srch_begin, l_tok_begin);

               IF (l_tok_begin = 0) THEN
                   -- No more tokens found in message
                   EXIT;
               END IF;

               -- Build string, replacing token with token value
               l_build_tmpmsg := l_build_tmpmsg ||
                 substr(l_msg, l_srch_begin, l_tok_begin - l_srch_begin) ||
                 p_token_val;

               -- Begin next search at the end of the processed token
               --  including ampersand (the +1)
               l_srch_begin := l_tok_begin + LENGTH(l_token) + 1;

             END LOOP;

             -- No more tokens in message. Concatenate the remainder
             --   of the message.
             l_build_tmpmsg := l_build_tmpmsg ||
                substr(l_msg, l_srch_begin, LENGTH(l_msg) - l_srch_begin + 1);

             x_msg := l_build_tmpmsg;

        END IF;
    END token_value_replace;


---------------------------------END of TOKEN REPLACEMENT routines ----------------------

    procedure SET_NAME(APPLICATION in varchar2, NAME in varchar2) is
    begin
        MSGAPP  := APPLICATION;
        -- Bug 5397597. Added SUBSTR to handle worst cases where product teams
        -- pass incorrect message names with more than 30 chars.
        MSGNAME := SUBSTR(NAME,1,30);
        MSGDATA := '';
        FND_LOG_MODULE := DEFAULT_FND_LOG_MODULE;
        MSGSET  := TRUE;
    end;

    /*
    **  ### OVERLOADED (new private version) ###
    **
    **	SET_TOKEN - define a message token with a value
    **  Private:  This procedure is only to be called by the ATG
    **            not for external use
    **  Arguments:
    **   token    - message token
    **   value    - value to substitute for token
    **   ttype    - type of token substitution:
    **                 'Y' translated, or "Yes, translated"
    **                 'N' constant, or "No, not translated"
    **                 'S' SQL query
    **
    */
    procedure SET_TOKEN(TOKEN in varchar2,
                        VALUE in varchar2,
                        TTYPE in varchar2 default 'N') is
    tok_type varchar2(1);
    begin

        if ( TTYPE not in ('Y','N','S')) then
           tok_type := 'N';
        else
           tok_type := TTYPE;
        end if;

        /* Note that we are intentionally using chr(0) rather than */
        /* FND_GLOBAL.LOCAL_CHR() for a performance bug (982909) */
	/* 3722358 - replace chr(0) in VALUE with spaces */

        /* Bug 5397597. If TTYPE='Y' then substrb(VALUE,1,30) (intentionally
         * used substrb instead of substr to handle the worst cases that the
         * product teams can introduce by calling this api improperly).
         * This is to avoid ORA-6502 error when the product teams
         * incorrectly calls this api.
         */
        if (TTYPE = 'Y') then  /* translated token */
          MSGDATA := MSGDATA||tok_type||chr(0)||TOKEN||chr(0)||
                     replace(SUBSTRB(VALUE,1,30),chr(0),' ')||chr(0);
        else
          MSGDATA := MSGDATA||tok_type||chr(0)||TOKEN||chr(0)||
                     replace(VALUE,chr(0),' ')||chr(0);
        end if;

    end set_token;

    /*
    **  ### OVERLOADED (original version) ###
    **
    **	SET_TOKEN - define a message token with a value,
    **              either constant or translated
    **  Public:  This procedure to be used by all
    */
    procedure SET_TOKEN(TOKEN in varchar2,
                        VALUE in varchar2,
                        TRANSLATE in boolean default false) is
    TTYPE varchar2(1);
    begin
        if TRANSLATE then
            TTYPE := 'Y';
        else
            TTYPE := 'N';
        end if;

        SET_TOKEN(TOKEN, VALUE, TTYPE);

    end set_token;

    /*
    ** SET_TOKEN_SQL - define a message token with a SQL query value
    **
    ** Description:
    **   Like SET_TOKEN, except here the value is a SQL statement which
    **   returns a single varchar2 value.  (e.g. A translated concurrent
    **   manager name.)  This statement is run when the message text is
    **   resolved, and the result is used in the token substitution.
    **
    ** Arguments:
    **   token - Token name
    **   value - Token value.  A SQL statement
    **
    */
    procedure SET_TOKEN_SQL (TOKEN in varchar2,
                             VALUE in varchar2) is

    TTYPE  varchar2(1) := 'S';  -- SQL Query
    begin

        SET_TOKEN(TOKEN, VALUE, TTYPE );

    end set_token_sql;

    /* This procedure is only to be called by the ATG; */
    /*  not for external use */
    procedure RETRIEVE(MSGOUT out NOCOPY varchar2) is
        OUT_VAL varchar2(2000);
    begin
        if MSGSET then
            /* Note that we are intentionally using chr(0) rather than */
            /* FND_GLOBAL.LOCAL_CHR() for a performance bug (982909) */
            OUT_VAL := MSGAPP||chr(0)||MSGNAME||chr(0)||MSGDATA;
            MSGSET := FALSE;
        else
            OUT_VAL := '';
        end if;

	MSGOUT := OUT_VAL;
    end;

    procedure CLEAR is
    begin
        msgset := FALSE;
    end;

    procedure RAISE_ERROR is
    begin
	/* Note that we are intentionally using chr(0) rather than */
        /* FND_GLOBAL.LOCAL_CHR() for a performance bug (982909) */
        raise_application_error(-20001,
                                MSGNAME||': '||replace(rtrim(MSGDATA,chr(0)),
                                chr(0), ', '));
    end;

    /*
    ** SET_MODULE - defines the Module for FND_LOG purposes
    */
    procedure SET_MODULE(MODULE in varchar2) is
    begin
      FND_LOG_MODULE := MODULE;
    end;

--------------------------
procedure GET_MESSAGE_INTERNAL(APPIN in varchar2,
                                   NAMEIN in varchar2,
                                   LANGIN in varchar2,
				   AUTO_LOG in varchar2,
                                   MSG out NOCOPY varchar2, MSG_NUMBER out NOCOPY NUMBER,
                                   MSG_TYPE out NOCOPY varchar2,
				   FND_LOG_SEVERITY out NOCOPY NUMBER,
				   ALERT_CATEGORY out NOCOPY varchar2,
				   ALERT_SEVERITY out NOCOPY varchar2) is
        MSG_INDEX        binary_integer;
        MSG_REC          MSG_REC_TYPE;
        LANG_CODE        varchar2(4);
        cursor c1(NAME_ARG varchar2, LANG_ARG varchar2) is
            select message_text, message_number, type, fnd_log_severity, category, severity
            from fnd_new_messages m, fnd_application a
            where NAME_ARG = m.message_name
            and LANG_ARG = m.language_code
            and APPIN = a.application_short_name
            and m.application_id = a.application_id;
    begin
         /* Bug 5005625. */
         /* This API is used only within this package and is called from
          * GET_STRING and GET_NUMBER passing NULL for LANGIN parameter.
          * So irrespective of the NLS session language, the message
          * was always cached and retrieved with an index 'NAME|NULL|APP'.
          * Hence the same message text was returned irrespective of the
          * session language. Now, the code is modified to properly set
          * the LANGIN to correct value and consequently to properly
          * cache and retrieve the messages with index 'NAME|LANGIN|APP'
          * This resolves the issue in bug 5005625
          */

         /* If the passed LANGIN is NULL then get the userenv('LANG') */
           if (LANGIN is NULL) then
              LANG_CODE := userenv('LANG');
           else
              LANG_CODE := LANGIN;
           end if;

        /* Get Message from cache */
           MSG_INDEX:=FIND(NAMEIN||CHR(0)||LANG_CODE||CHR(0)||APPIN);

        if ( MSG_INDEX <= TABLE_SIZE) then
           MSG:=MSG_TAB(MSG_INDEX).message_text;
           MSG_NUMBER:=MSG_TAB(MSG_INDEX).message_number;
           MSG_TYPE:=MSG_TAB(MSG_INDEX).type;
           FND_LOG_SEVERITY:=MSG_TAB(MSG_INDEX).fnd_log_severity;
           ALERT_CATEGORY:=MSG_TAB(MSG_INDEX).category;
           ALERT_SEVERITY:=MSG_TAB(MSG_INDEX).severity;
           return;
        end if;

        /* Message is not available in the cache. So get it from the table */
        open c1(UPPER(NAMEIN), LANG_CODE);
        fetch c1 into MSG, MSG_NUMBER, MSG_TYPE, FND_LOG_SEVERITY,
		ALERT_CATEGORY, ALERT_SEVERITY;

        if (c1%NOTFOUND) then
           close c1;
           /* MessageText is not available in the table for LANG_CODE language.
            * So get the MessageText in 'US' language
            */
           LANG_CODE := 'US';

           /* First Check the Cache for Message in 'US' language */
           MSG_INDEX:=FIND(NAMEIN||CHR(0)||LANG_CODE||CHR(0)||APPIN);

           if ( MSG_INDEX <= TABLE_SIZE) then
              MSG:=MSG_TAB(MSG_INDEX).message_text;
              MSG_NUMBER:=MSG_TAB(MSG_INDEX).message_number;
              MSG_TYPE:=MSG_TAB(MSG_INDEX).type;
              FND_LOG_SEVERITY:=MSG_TAB(MSG_INDEX).fnd_log_severity;
              ALERT_CATEGORY:=MSG_TAB(MSG_INDEX).category;
              ALERT_SEVERITY:=MSG_TAB(MSG_INDEX).severity;
              return;
           end if;

           /* Not found in the Cache, so get from table */
           open c1(UPPER(NAMEIN), 'US');
           fetch c1 into MSG, MSG_NUMBER, MSG_TYPE, FND_LOG_SEVERITY,
                                ALERT_CATEGORY, ALERT_SEVERITY;
        end if;
	close c1;

	/* NULL Handling */
	if ( MSG is NULL ) then 	-- i.e. Message was not found
	   MSG := NAMEIN;
	else
	   if (MSG_NUMBER is NULL) then	-- per GET_NUMBER api- NUMBER should be NULL
	      MSG_NUMBER := 0;		-- only if Message does not exist
	   end if;
	end if;

        /* double ampersands don't have anything to do with tokens, they */
        /* represent access keys.  So we translate them to single ampersands*/
        /* so that the access key code will recognize them. */
        MSG := substrb(REPLACE(MSG, '&&', '&'),1,2000);

        /* PUT the message in the cache */
        MSG_REC.message_name     := UPPER(NAMEIN||CHR(0)||LANG_CODE||CHR(0)||APPIN);
        MSG_REC.message_text     := MSG;
        MSG_REC.message_number   := MSG_NUMBER;
        MSG_REC.type             := MSG_TYPE;
        MSG_REC.fnd_log_severity := FND_LOG_SEVERITY;
        MSG_REC.category         := ALERT_CATEGORY;
        MSG_REC.severity         := ALERT_SEVERITY;
        PUT(NAMEIN||CHR(0)||LANG_CODE||CHR(0)||APPIN, MSG_REC);
    end;
--------------------------
    /*
    **	GET_STRING- get a particular translated message
    **       from the message dictionary database.
    **
    **  This is a one-call interface for when you just want to get a
    **  message without doing any token substitution.
    **  Returns NAMEIN (Msg name)  if the message cannot be found.
    */
    function GET_STRING(APPIN in varchar2,
	      NAMEIN in varchar2) return varchar2 is
    begin
	/* get the message text out of the table */
	return GET_STRING(APPIN, NAMEIN, 'Y');
    end;

    /*
    **  GET_STRING- get a particular translated message
    **       from the message dictionary database.
    **
    **  This is a one-call interface for when you just want to get a
    **  message without doing any token substitution.
    **  Returns NAMEIN (Msg name)  if the message cannot be found.
    */
    function GET_STRING(APPIN in varchar2,
              NAMEIN in varchar2, AUTO_LOG in varchar2) return varchar2 is
        MSG  varchar2(2000)  := NULL;
        MSG_NUMBER    NUMBER := 0;
        MSG_TYPE varchar2(30):= NULL;
        FND_LOG_SEVERITY NUMBER := 0;
        ALERT_CATEGORY varchar2(10) := NULL;
        ALERT_SEVERITY varchar2(10) := NULL;
    begin
        /* get the message text out of the table */
        GET_MESSAGE_INTERNAL(APPIN, NAMEIN, NULL, AUTO_LOG,
			     MSG, MSG_NUMBER, MSG_TYPE, FND_LOG_SEVERITY,
			     ALERT_CATEGORY, ALERT_SEVERITY);
        return MSG;
    end;

    /*
    **	FETCH_SQL_TOKEN- get the value for a SQL Query token
    **     This procedure is only to be called by the ATG
    **     not for external use
    */
    function FETCH_SQL_TOKEN(TOK_VAL in varchar2) return varchar2 is
      token_text  varchar2(2000);
	username varchar2(2000);
	apps_schema_name varchar2(2000);
    begin

	select user into username from dual;

	select distinct oracle_username into apps_schema_name from fnd_oracle_userid where upper(read_only_flag)='U';

	if(upper(username) <> upper(apps_schema_name) ) then
		return NULL;
	end if;

      if ( UPPER(SUBSTR(TOK_VAL, 1, 6) ) = 'SELECT' ) then
        execute immediate TOK_VAL
           into token_text;
      else
        token_text :=
                'Parameter error in FND_MESSAGE.FETCH_SQL_TOKEN(Token SQL):  '
                || FND_GLOBAL.NEWLINE
                || 'TOK_VAL must begin with keyword SELECT';
      end if;
      return token_text;
    exception
      when others then
       token_text :=
                'SQL-Generic error in FND_MESSAGE.FETCH_SQL_TOKEN(Token SQL):  '
                || FND_GLOBAL.NEWLINE
                || SUBSTR(sqlerrm, 1, 1900);
       return token_text;
    end;

    /*
    **	GET_NUMBER- get the message number of a particular message.
    **
    **  This routine returns only the message number, given a message
    **  name.  This routine will be only used in rare cases; normally
    **  the message name will get displayed automatically by message
    **  dictionary when outputting a message on the client.
    **
    **  You should _not_ use this routine to construct a system for
    **  storing translated messages (along with numbers) on the server.
    **  If you need to store translated messages on a server for later
    **  display on a client, use the set_encoded/get_encoded routines
    **  to store the messages as untranslated, encoded messages.
    **
    **  If you don't know the name of the message on the stack, you
    **  can use get_encoded and parse_encoded to find it out.
    **
    **  Returns 0 if the message has no message number,
    **         or if its message number is zero.
    **       NULL if the message can't be found.
    */
    function GET_NUMBER(APPIN in varchar2,
	      NAMEIN in varchar2) return NUMBER is
        MSG  varchar2(2000)  := NULL;
        MSG_NUMBER    NUMBER := 0;
        MSG_TYPE varchar2(30):= NULL;
        FND_LOG_SEVERITY NUMBER := 0;
        ALERT_CATEGORY varchar2(10) := NULL;
        ALERT_SEVERITY varchar2(10) := NULL;
    begin
        /* get the message text out of the table */
        GET_MESSAGE_INTERNAL(APPIN, NAMEIN, NULL, 'Y', MSG, MSG_NUMBER,
		MSG_TYPE, FND_LOG_SEVERITY, ALERT_CATEGORY, ALERT_SEVERITY);
        return MSG_NUMBER;
    end;

    /*
    **  GET- get a translated and token substituted message
    **       from the message dictionary database.
    **       Returns NULL if the message cannot be found.
    */
    function GET return varchar2 is
    begin
	return GET('Y');
    end;


    /*
    **	GET- get a translated and token substituted message
    **       from the message dictionary database.
    **       Returns NULL if the message cannot be found.
    */
    function GET(AUTO_LOG in varchar2) return varchar2 is
        MSG       varchar2(2000);
	TOK_NAM   varchar2(30);
	TOK_VAL   varchar2(2000);
	SRCH      varchar2(2000);
        TTYPE     varchar2(1);
        POS       NUMBER;
	NEXTPOS   NUMBER;
	DATA_SIZE NUMBER;
        l_pop_msg VARCHAR2(2000);

    begin
        if (not MSGSET) then
            MSG := '';
            return MSG;
        end if;
	MSG := GET_STRING(MSGAPP, MSGNAME, AUTO_LOG);
	if ((msg is NULL) OR (msg = '')) then
            MSG := MSGNAME;
	end if;
        POS := 1;
	DATA_SIZE := LENGTH(MSGDATA);
        while POS < DATA_SIZE loop
            TTYPE := SUBSTR(MSGDATA, POS, 1);
            POS := POS + 2;
            /* Note that we are intentionally using chr(0) rather than */
            /* FND_GLOBAL.LOCAL_CHR() for a performance bug (982909) */
            NEXTPOS := INSTR(MSGDATA, chr(0), POS);
            if (NEXTPOS = 0) then /* For bug 1893617 */
              exit; /* Should never happen, but prevent spins on bad data*/
            end if;
	    TOK_NAM := SUBSTR(MSGDATA, POS, NEXTPOS - POS);
            POS := NEXTPOS + 1;
            NEXTPOS := INSTR(MSGDATA, chr(0), POS);
            if (NEXTPOS = 0) then /* For bug 1893617 */
              exit; /* Should never happen, but prevent spins on bad data*/
            end if;
            TOK_VAL := SUBSTR(MSGDATA, POS, NEXTPOS - POS);
            POS := NEXTPOS + 1;

            if (TTYPE = 'Y') then  /* translated token */
                TOK_VAL := GET_STRING(MSGAPP, TOK_VAL, AUTO_LOG);
            elsif (TTYPE = 'S') then  /* SQL query token */
                TOK_VAL := FETCH_SQL_TOKEN(TOK_VAL);
            end if;
            l_pop_msg := ' ';
            token_value_replace(MSG, TOK_NAM, TOK_VAL, l_pop_msg);

            -- BUG 6734576 fixed by replacing this line with a simpler
            -- validation.
            IF (l_pop_msg <> ' ') THEN
                MSG := substrb(l_pop_msg, 1, 2000);
            ELSE
                -- Bug6779374  complete the error message with
                -- token-name and token-value
                MSG := substrb(MSG||' ('||TOK_NAM||'='||TOK_VAL||')',1,2000);
            END IF;

        END LOOP;
        /* double ampersands don't have anything to do with tokens, they */
        /* represent access keys.  So we translate them to single ampersands*/
        /* so that the access key code will recognize them. */
	MSG := substrb(REPLACE(MSG, '&&', '&'),1,2000);
	MSGSET := FALSE;
	return MSG;
    end;

    function GET_ENCODED(AUTO_LOG in varchar2) return varchar2 is
    begin
        if MSGSET then
	    if AUTO_LOG <> 'Y' then
              MSGSET := FALSE;
	    end if;
            /* Note that we are intentionally using chr(0) rather than */
            /* FND_GLOBAL.LOCAL_CHR() for a performance bug (982909) */
	    return  (MSGAPP||chr(0)||MSGNAME||chr(0)||MSGDATA);
        else
            return ('');
        end if;
    end;

    function GET_ENCODED
	return varchar2 is
    begin
	return GET_ENCODED('N');
    end;

    /*
    ** SET_ENCODED- Set an encoded message onto the message stack
    */
    procedure SET_ENCODED(ENCODED_MESSAGE IN varchar2) is
        POS       NUMBER;
	NEXTPOS   NUMBER;
    begin
        POS := 1;

	/* Note that we are intentionally using chr(0) rather than */
        /* FND_GLOBAL.LOCAL_CHR() for a performance bug (982909) */
        NEXTPOS := INSTR(ENCODED_MESSAGE, chr(0), POS);
        MSGAPP := SUBSTR(ENCODED_MESSAGE, POS, NEXTPOS - POS);
        POS := NEXTPOS + 1;

        NEXTPOS := INSTR(ENCODED_MESSAGE, chr(0), POS);
        MSGNAME := SUBSTR(ENCODED_MESSAGE, POS, NEXTPOS - POS);
        POS := NEXTPOS + 1;

        MSGDATA := SUBSTR(ENCODED_MESSAGE, POS);

	if((MSGAPP is not null) and (MSGNAME is not null)) then
           MSGSET := TRUE;
	end if;
    end;


    /*
    ** PARSE_ENCODED- Parse the message name and application short name
    **                out of a message in "encoded" format.
    */
    procedure PARSE_ENCODED(ENCODED_MESSAGE IN varchar2,
			APP_SHORT_NAME  OUT NOCOPY varchar2,
			MESSAGE_NAME    OUT NOCOPY varchar2) is
        POS       NUMBER;
	NEXTPOS   NUMBER;
    begin
        null;
        POS := 1;

	/* Note that we are intentionally using chr(0) rather than */
        /* FND_GLOBAL.LOCAL_CHR() for a performance bug (982909) */
        NEXTPOS := INSTR(ENCODED_MESSAGE, chr(0), POS);
        APP_SHORT_NAME := SUBSTR(ENCODED_MESSAGE, POS, NEXTPOS - POS);
        POS := NEXTPOS + 1;

        NEXTPOS := INSTR(ENCODED_MESSAGE, chr(0), POS);
        MESSAGE_NAME := SUBSTR(ENCODED_MESSAGE, POS, NEXTPOS - POS);
        POS := NEXTPOS + 1;
    end;

    /*
    **  GET_TOKEN- Obtains the value of a named token from the
    **             current message.
    */
    function GET_TOKEN(TOKEN IN VARCHAR2
            ,REMOVE_FROM_MESSAGE IN VARCHAR2 default NULL /* NULL means 'N'*/
            ) return varchar2 is
    begin
	return GET_TOKEN(TOKEN, REMOVE_FROM_MESSAGE, 'Y');
    end;

    /*
    **	GET_TOKEN- Obtains the value of a named token from the
    **             current message.
    */
    function GET_TOKEN(TOKEN IN VARCHAR2
            ,REMOVE_FROM_MESSAGE IN VARCHAR2 default NULL /* NULL means 'N'*/
            ,AUTO_LOG in varchar2) return varchar2 is
	TOK_NAM   varchar2(30);
	TOK_VAL   varchar2(2000);
        TTYPE     varchar2(1);
        POS       NUMBER;
	NEXTPOS   NUMBER;
	STARTPOS   NUMBER;
	DATA_SIZE NUMBER;
        L_REMOVE_FROM_MESSAGE VARCHAR2(1):= NULL;
    begin
        if (REMOVE_FROM_MESSAGE is NULL) then
          L_REMOVE_FROM_MESSAGE := 'N';
        else
          L_REMOVE_FROM_MESSAGE := substrb(REMOVE_FROM_MESSAGE,1,1);
        end if;
        if (not MSGSET) then
            return null;
        end if;
        POS := 1;
	DATA_SIZE := LENGTH(MSGDATA);
        while POS < DATA_SIZE loop
            STARTPOS := POS;
            TTYPE := SUBSTR(MSGDATA, POS, 1);
            POS := POS + 2;
            /* Note that we are intentionally using chr(0) rather than */
            /* FND_GLOBAL.LOCAL_CHR() for a performance bug (982909) */
            NEXTPOS := INSTR(MSGDATA, chr(0), POS);
            if (NEXTPOS = 0) then /* For bug 1893617 */
              exit; /* Should never happen, but prevent spins on bad data*/
            end if;
	    TOK_NAM := SUBSTR(MSGDATA, POS, NEXTPOS - POS);
            POS := NEXTPOS + 1;
            NEXTPOS := INSTR(MSGDATA, chr(0), POS);
            if (NEXTPOS = 0) then /* For bug 1893617 */
              exit; /* Should never happen, but prevent spins on bad data*/
            end if;
            /* if token matches return value */
            if (TOK_NAM = TOKEN) then
              TOK_VAL := SUBSTR(MSGDATA, POS, NEXTPOS - POS);

              if (TTYPE = 'Y') then  /* translated token */
                TOK_VAL := GET_STRING(MSGAPP, TOK_VAL, AUTO_LOG);
              elsif (TTYPE = 'S') then  /* SQL query token */
                TOK_VAL := FETCH_SQL_TOKEN(TOK_VAL);
              end if;

              if (L_REMOVE_FROM_MESSAGE = 'Y') then
                MSGDATA := replace(MSGDATA,SUBSTR(MSGDATA, STARTPOS,
                                   NEXTPOS - STARTPOS + 1));
              end if;
              return TOK_VAL;
            end if;
            POS := NEXTPOS + 1;
        END LOOP;
        /* token not found */
        return null;
    end;

    /*
    **	GET_TEXT_NUMBER - get a particular message text
    **       and message number from the message dictionary database.
    **
    **  This is a one-call interface for when you just want to get a
    **  message and number without doing any token substitution.
    **
    **  IN
    **    APPIN:  Application Short Name of message
    **    NAMEIN: Message Name
    **  OUT
    **    MSGTEXT:   Returns NAMEIN (Msg name)  if the message cannot be found.
    **    MSGNUMBER: Returns 0 if the message has no message number,
    **               or if its message number is zero.
    **               NULL if the message can't be found.
    */
    procedure GET_TEXT_NUMBER(APPIN in varchar2,
	                      NAMEIN in varchar2,
                              MSGTEXT out nocopy varchar2,
                              MSGNUMBER out nocopy number) is
    begin
	MSGTEXT := GET_STRING(APPIN, NAMEIN, 'Y');
        MSGNUMBER := GET_NUMBER(APPIN, NAMEIN);
    end;


end FND_MESSAGE;
/