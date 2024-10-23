CREATE OR REPLACE package body APPS.app_exception as
/* $Header: AFEXCEPB.pls 120.2 2005/08/19 20:27:05 tkamiya ship $ */



  --
  -- PRIVATE VARIABLES
  --

  -- Exception information
  exc_type varchar2(30)  := NULL;
  exc_code number        := NULL;
  exc_text varchar2(2000) := NULL;

  --
  -- PUBLIC FUNCTIONS
  --

  -- RAISE_EXCEPTION is normally called without any arguments;
  --                 the args here are from legacy but not now used.
  procedure raise_exception(exception_type varchar2 default null,
                            exception_code number   default null,
                            exception_text varchar2 default null) is
    encoded_text varchar2(4000);
    return_text varchar2(4000);
    msg_app     varchar2(50);
    msg_name    varchar2(30);
    msg_number  number;
    msg_num_str varchar2(80);
    app_str     varchar2(255); /* 'APP'*/
  begin
    exc_type := exception_type;
    exc_code := exception_code;
    exc_text := exception_text;

    if((exception_type is NULL) and
       (exception_code is NULL) and
       (exception_text is NULL)) then
        /* Get the message off the message dict stack, and put it back on*/
	encoded_text := fnd_message.get_encoded;
	fnd_message.set_encoded(encoded_text);
	return_text := fnd_message.get;
        /* Get the message name to look up the message number */
        fnd_message.parse_encoded(encoded_text, msg_app, msg_name);
        msg_number := fnd_message.get_number(msg_app, msg_name);
        if (msg_number >= 1) then /* If there is a message num, append it */
          if msg_number <= 99999 then /* Msg num should always <= 5 digits*/
            msg_num_str := to_char(msg_number, 'FM09999');
          else /* But just for robustness, don't choke on larger numbers */
            msg_num_str := to_char(msg_number);
          end if;
          app_str := fnd_message.get_string('FND', 'AFDICT_APP_PREFIX');
          return_text := app_str||'-'||msg_app||'-'||msg_num_str||': '
                         ||return_text;
        end if;
        fnd_message.set_encoded(encoded_text);
    else
        /* Legacy case */
        return_text := exc_type||'-'||to_char(exc_code)||': '||exc_text;
    end if;

   if (FND_LOG.LEVEL_EXCEPTION >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) then
   FND_LOG.STRING(FND_LOG.LEVEL_EXCEPTION,
       'fnd.plsql.APP_EXCEPTION.RAISE_EXCEPTION.dict_auto_log', return_text);
   end if;

    -- raise_application_error message should be <= 512 bytes
    return_text := substrb(return_text, 1, 512);

    /* Raise the application error and put the message text on the */
    /* OCI buffer so it will display if called from SQL*Plus. */
    raise_application_error(-20001, return_text);
  end raise_exception;

  procedure get_exception(exception_type OUT NOCOPY varchar2,
                          exception_code OUT NOCOPY number,
                          exception_text OUT NOCOPY varchar2) is
  begin
    exception_type := exc_type;
    exception_code := exc_code;
    exception_text := exc_text;
  end get_exception;

  function get_type return varchar2 is
  begin
    return exc_type;
  end get_type;

  function get_code return number is
  begin
    return exc_code;
  end get_code;

  function get_text return varchar2 is
  begin
    return exc_text;
  end get_text;

  procedure invalid_argument(procname varchar2,
                             argument varchar2,
                             value    varchar2) is
  begin
    fnd_message.set_name('FND', 'FORM_INVALID_ARGUMENT');
    fnd_message.set_token('PROCEDURE', procname);
    fnd_message.set_token('ARGUMENT',  argument);
    fnd_message.set_token('VALUE',     value);
    app_exception.raise_exception;
  end invalid_argument;

end app_exception;
/