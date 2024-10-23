CREATE OR REPLACE package APPS.FND_MESSAGE AUTHID DEFINER as
/* $Header: AFNLMSGS.pls 120.2.12000000.1 2007/01/18 13:21:41 appldev ship $ */
/*#
* APIs to Set, Retrieve, Clear the messages in Message Stack.
* @rep:scope public
* @rep:product FND
* @rep:displayname Message Dictionary
* @rep:lifecycle active
* @rep:compatibility S
* @rep:category BUSINESS_ENTITY FND_MESSAGE
* @rep:ihelp FND/@mesgdict#mesgdict See the related online help
*/


    /*
    ** SET_NAME - sets the message name
    */

    /*#
     * In Database Server, this Sets a message name in the global area
     * without actually retrieving the message from Message Dictionary.
     * FND_MESSAGE.SET_NAME should be called before calling FND_MESSAGE.SET_TOKEN.
     * @param application The short name of the application this message is associated with.
     * @param name Message Name
     * @rep:scope public
     * @rep:lifecycle active
     * @rep:displayname Set Message Name
     * @rep:compatibility S
     * @rep:ihelp FND/@mesgdict#mesgdict See the related online help
     */
    procedure SET_NAME(APPLICATION in varchar2, NAME in varchar2);
    pragma restrict_references(SET_NAME, WNDS);

    /*
    ** SET_TOKEN - defines a message token with a value
    */

    /*#
     * In Database Server, SET_TOKEN adds a token/value pair to the
     * global area without actually doing the substitution.
     * Call FND_MESSAGE.SET_TOKEN once for each token/value pair in a
     * message. The optional translate parameter can be set to TRUE to
     * indicate that the value should be translated before substitution. (The
     * value should be translated if it is, itself, a Message Dictionary
     * message name).
     * @param token name of the token you want to substitute - token should not include the '&' in Message Dictionary calls
     * @param value substitute text
     * @param translate Indicates whether the value is itself a Message Dictionary message
     * @rep:scope public
     * @rep:lifecycle active
     * @rep:displayname Set Token value
     * @rep:compatibility S
     * @rep:ihelp FND/@mesgdict#mesgdict See the related online help
     */
    procedure SET_TOKEN(TOKEN     in varchar2,
                        VALUE     in varchar2,
                        TRANSLATE in boolean default false);
    pragma restrict_references(SET_TOKEN, WNDS);

    /*
    ** SET_MODULE - defines the Module for FND_LOG purposes
    */
    procedure SET_MODULE(MODULE in varchar2);

    /*
    ** GET_MESSAGE_INTERNAL - Internal use only.
    */
    procedure GET_MESSAGE_INTERNAL(APPIN in varchar2,
                                   NAMEIN in varchar2, LANGIN in varchar2,
				   AUTO_LOG in varchar2,
                                   MSG out NOCOPY varchar2, MSG_NUMBER out NOCOPY NUMBER,
                                   MSG_TYPE out NOCOPY varchar2,
				   FND_LOG_SEVERITY out NOCOPY NUMBER,
				   ALERT_CATEGORY out NOCOPY varchar2,
				   ALERT_SEVERITY out NOCOPY varchar2);
    pragma restrict_references(GET_MESSAGE_INTERNAL, WNDS);

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
                             VALUE in varchar2);

    /*
    ** RETRIEVE - gets the message and token data, clears message buffer
    */
    procedure RETRIEVE(MSGOUT out NOCOPY varchar2);
    pragma restrict_references(RETRIEVE, WNDS);

    /*
    ** CLEAR - clears the message buffer
    */

    /*#
     * Clears the message stack of all messages
     * @rep:scope public
     * @rep:lifecycle active
     * @rep:displayname Clear Message Buffer
     * @rep:compatibility S
     * @rep:ihelp FND/@mesgdict#mesgdict See the related online help
     */
    procedure CLEAR;
    pragma restrict_references(CLEAR, WNDS);

    /*
    **	GET_STRING- get a particular translated message
    **       from the message dictionary database.
    **
    **  This is a one-call interface for when you just want to get a
    **  message without doing any token substitution.
    **  Returns NULL if the message cannot be found.
    */
    function GET_STRING(APPIN in varchar2,
	      NAMEIN in varchar2) return varchar2;
    /* bug 4287370 - added back pragma WNPS with TRUST for backwards compatibility  */
    pragma restrict_references(GET_STRING, WNDS, WNPS, TRUST);

    /*
    **  GET_STRING- get a particular translated message
    **       from the message dictionary database.
    **
    **  This is a one-call interface for when you just want to get a
    **  message without doing any token substitution.
    **  Returns NULL if the message cannot be found.
    */
    function GET_STRING(APPIN in varchar2,
              NAMEIN in varchar2, AUTO_LOG in varchar2) return varchar2;
    pragma restrict_references(GET_STRING, WNDS);


    /*
    **  FETCH_SQL_TOKEN- get the value for a SQL Query token
    **     This procedure is only to be called by the ATG
    **     not for external use
    */
    function FETCH_SQL_TOKEN(TOK_VAL in varchar2) return varchar2;
    pragma restrict_references(FETCH_SQL_TOKEN, WNDS);

    /*
    **	GET_NUMBER- get the message number of a particular message.
    **
    **  Returns 0 if the message has no message number,
    **         or if its message number is zero.
    **       NULL if the message can't be found.
    */
    function GET_NUMBER(APPIN in varchar2,
	      NAMEIN in varchar2) return NUMBER;
    pragma restrict_references(GET_NUMBER, WNDS);

    /*
    **	GET- get a translated and token substituted message
    **       from the message dictionary database.
    **       Returns NULL if the message cannot be found.
    */

    /*#
     * Retrieves a translated and token-substituted message from the
     * message stack and then clears that message from the message stack.
     * GET returns up to 2000 bytes of message. <p>
     * If this function is called from a stored procedure on the database server
     * side, the message is retrieved from the Message Dictionary table. If the
     * function is called from a form or forms library, the message is retrieved
     * from the messages file on the forms server.
     * @return text Message Text
     * @rep:scope public
     * @rep:lifecycle active
     * @rep:displayname Get Message Text
     * @rep:compatibility S
     * @rep:ihelp FND/@mesgdict#mesgdict See the related online help
     */
    function GET return varchar2;
    pragma restrict_references(GET, WNDS);

    /*
    **  GET- get a translated and token substituted message
    **       from the message dictionary database.
    **       Returns NULL if the message cannot be found.
    */
    function GET(AUTO_LOG in varchar2) return varchar2;
    pragma restrict_references(GET, WNDS);

    /*
    ** GET_ENCODED- Get an encoded message from the message stack.
    */
    function GET_ENCODED return varchar2;
    pragma restrict_references(GET_ENCODED, WNDS);

   /*
    ** GET_ENCODED- Get an encoded message from the message stack.
    */
    function GET_ENCODED(AUTO_LOG in varchar2) return varchar2;
    pragma restrict_references(GET_ENCODED, WNDS);

    /*
    ** PARSE_ENCODED- Parse the message name and application short name
    **                out of a message in "encoded" format.
    */
    procedure PARSE_ENCODED(ENCODED_MESSAGE IN varchar2,
			APP_SHORT_NAME  OUT NOCOPY varchar2,
			MESSAGE_NAME    OUT NOCOPY varchar2);
    pragma restrict_references(PARSE_ENCODED, WNDS);

    /*
    ** SET_ENCODED- Set an encoded message onto the message stack
    */
    procedure SET_ENCODED(ENCODED_MESSAGE IN varchar2);
    pragma restrict_references(SET_ENCODED, WNDS);

    /*
    ** raise_error - raises the error to the calling entity
    **               via raise_application_error() prodcedure
    */
    procedure RAISE_ERROR;
    pragma restrict_references(RAISE_ERROR, WNDS);

    /*
    **  GET_TOKEN- Obtains the value of a named token from the
    **             current message.
    **         IN: TOKEN- the name of the token that was passed to SET_TOKEN
    **             REMOVE_FROM_MESSAGE- default NULL means 'N'
    **              'Y'- Remove the token value from the current message
    **              'N'- Leave the token value on the current message
    **    RETURNs: the token value that was set previously with SET_TOKEN
    */
    function GET_TOKEN(TOKEN IN VARCHAR2
            ,REMOVE_FROM_MESSAGE IN VARCHAR2 default NULL /* NULL means 'N'*/
            ) return varchar2;

    /*
    **  GET_TOKEN- Obtains the value of a named token from the
    **             current message.
    **         IN: TOKEN- the name of the token that was passed to SET_TOKEN
    **             REMOVE_FROM_MESSAGE- default NULL means 'N'
    **              'Y'- Remove the token value from the current message
    **              'N'- Leave the token value on the current message
    **    RETURNs: the token value that was set previously with SET_TOKEN
    */
    function GET_TOKEN(TOKEN IN VARCHAR2
            ,REMOVE_FROM_MESSAGE IN VARCHAR2 default NULL /* NULL means 'N'*/
            ,AUTO_LOG in varchar2) return varchar2;

    /*
    **	GET_TEXT_NUMBER - get a particular message text
    **       and message number from the message dictionary database.
    **
    **  This is a one-call interface for when you just want to get a
    **  message text and number without doing any token substitution.
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

    /*#
     * Retrieves the message text and message number from fnd_new_messages
     * table for a given message name.
     * param appin message application short name
     * param namein message name
     * param msgtext message text
     * param msgnumber message number
     * @rep:scope public
     * @rep:lifecycle active
     * @rep:displayname Get Message Text and Number
     * @rep:compatibility S
     * @rep:ihelp FND/@mesgdict#mesgdict See the related online help
     */
    procedure GET_TEXT_NUMBER(APPIN in varchar2,
	                      NAMEIN in varchar2,
                              MSGTEXT out nocopy varchar2,
                              MSGNUMBER out nocopy number);
    pragma restrict_references(GET_TEXT_NUMBER, WNDS);
end FND_MESSAGE;
/
