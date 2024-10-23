CREATE OR REPLACE PACKAGE BODY APPS.AP_UTILITIES_PKG AS
/* $Header: aputilsb.pls 120.51.12020000.10 2015/03/25 07:46:48 sbonala ship $ */
/*#
 * This Package provides different APIs for various operations in
 * Invoices module.
 * @rep:scope public
 * @rep:product AP
 * @rep:lifecycle active
 * @rep:displayname  Utility Package
 * @rep:category BUSINESS_ENTITY AP_INVOICE
 */

   G_PKG_NAME          CONSTANT VARCHAR2(30) := 'AP_UTILITIES_PKG';
   G_MSG_UERROR        CONSTANT NUMBER       := FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR;
   G_MSG_ERROR         CONSTANT NUMBER       := FND_MSG_PUB.G_MSG_LVL_ERROR;
   G_MSG_SUCCESS       CONSTANT NUMBER       := FND_MSG_PUB.G_MSG_LVL_SUCCESS;
   G_MSG_HIGH          CONSTANT NUMBER       := FND_MSG_PUB.G_MSG_LVL_DEBUG_HIGH;
   G_MSG_MEDIUM        CONSTANT NUMBER       := FND_MSG_PUB.G_MSG_LVL_DEBUG_MEDIUM;
   G_MSG_LOW           CONSTANT NUMBER       := FND_MSG_PUB.G_MSG_LVL_DEBUG_LOW;
   G_LINES_PER_FETCH   CONSTANT NUMBER       := 1000;

   G_CURRENT_RUNTIME_LEVEL     NUMBER       := FND_LOG.G_CURRENT_RUNTIME_LEVEL;
   G_LEVEL_UNEXPECTED CONSTANT NUMBER       := FND_LOG.LEVEL_UNEXPECTED;
   G_LEVEL_ERROR      CONSTANT NUMBER       := FND_LOG.LEVEL_ERROR;
   G_LEVEL_EXCEPTION  CONSTANT NUMBER       := FND_LOG.LEVEL_EXCEPTION;
   G_LEVEL_EVENT      CONSTANT NUMBER       := FND_LOG.LEVEL_EVENT;
   G_LEVEL_PROCEDURE  CONSTANT NUMBER       := FND_LOG.LEVEL_PROCEDURE;
   G_LEVEL_STATEMENT  CONSTANT NUMBER       := FND_LOG.LEVEL_STATEMENT;
   G_MODULE_NAME      CONSTANT VARCHAR2(50) :='AP.PLSQL.AP_UTILITIES_PKG';

function AP_Get_Displayed_Field
                             (LookupType    IN varchar2
                             ,LookupCode    IN varchar2)
return varchar2
is
                                                                         --
  cursor c_lookup is
  select displayed_field
  from   ap_lookup_codes
  where  (lookup_code = LookupCode)
  and    (lookup_type = LookupType);
  output_string  ap_lookup_codes.displayed_field%TYPE;
                                                                       --
BEGIN
                                                                         --
  open  c_lookup;
  fetch c_lookup into output_string;
                                                                         --
  IF c_lookup%NOTFOUND THEN
    raise NO_DATA_FOUND;
  END IF;
                                                                         --
  close c_lookup;
  return(output_string);
                                                                         --
END AP_Get_Displayed_Field;
                                                                         --
                                                                         --
function Ap_Round_Currency
                         (P_Amount         IN number
                         ,P_Currency_Code  IN varchar2)
return number is
  l_rounded_amount  number;
  l_minimum_acct_unit  FND_CURRENCIES.minimum_accountable_unit%TYPE;
  l_precision          FND_CURRENCIES.precision%TYPE;

begin

  /* Bug 5572876. Ccaching is done for Currency Data */
  If g_fnd_currency_code_t.COUNT > 0 Then

    If g_fnd_currency_code_t.Exists(p_currency_code) Then

      l_minimum_acct_unit := g_fnd_currency_code_t(p_currency_code).minimum_accountable_unit;
      l_precision         := g_fnd_currency_code_t(p_currency_code).precision;

    Else

      Begin
        select  FC.minimum_accountable_unit, FC.precision
        into    l_minimum_acct_unit, l_precision
        from    fnd_currencies FC
        where   FC.currency_code = P_Currency_Code;

        g_fnd_currency_code_t(p_currency_code).minimum_accountable_unit := l_minimum_acct_unit;
        g_fnd_currency_code_t(p_currency_code).precision := l_precision;
        g_fnd_currency_code_t(p_currency_code).currency_code := p_currency_code;
      Exception
        When No_Data_Found Then
          /* Bug 5722538. If p_currency_code is null then assignments
             to plsql table based on null index fails
             hence commenting out the statements and assigining null to l_minimum_acct_unit
             and l_precision. */
          l_minimum_acct_unit := NULL;
          l_precision         := NULL;
      End;

    End If;

 Else

    Begin
      select  FC.minimum_accountable_unit, FC.precision
      into    l_minimum_acct_unit, l_precision
      from    fnd_currencies FC
      where   FC.currency_code = P_Currency_Code;

      g_fnd_currency_code_t(p_currency_code).minimum_accountable_unit := l_minimum_acct_unit;
      g_fnd_currency_code_t(p_currency_code).precision := l_precision;
      g_fnd_currency_code_t(p_currency_code).currency_code := p_currency_code;

    Exception
      When No_Data_Found Then
        /* Bug 5722538. If p_currency_code is null then assignments
             to plsql table based on null index fails
             hence commenting out the statements and assigining null to l_minimum_acct_unit
             and l_precision. */
        l_minimum_acct_unit := NULL;
        l_precision         := NULL;
    End;

  End If;


  If l_minimum_acct_unit Is Null Then
    /* Bug 5722538. L_precion can be also be null if the p_currency_code
       is null */
    If l_precision Is Not Null Then
      l_rounded_amount := round(P_Amount, l_precision);
    Else
      l_rounded_amount := NULL;
    End If;
  Else
    l_rounded_amount := round(P_amount/l_minimum_acct_unit)*l_minimum_acct_unit;
  End If;

                                                                         --
  return(l_rounded_amount);
                                                                         --
EXCEPTION

  WHEN NO_DATA_FOUND THEN

/* Note: this segment of code affects the purity of the function
         (ie with it, we cannot guarantee that package/dbms state
         will not be altered).  Such guarantees are necessary in
         order to use a stored function in the select-list of a
         query.  Therefore, I am commenting it out NOCOPY and simply
         returning null if no record is retrieved.
                                                                         --
        raise_application_error(-20000,'APUT002/No such currency ' ||
                                P_Currency_Code);
*/

  return (null);
                                                                         --
end AP_ROUND_CURRENCY;
                                                                         --

--===========================================================================
-- AP_Round_Tax: Function that rounds a tax amount.
--               This function was created as part of the development of
--               Consumption tax.  It calculates rounding based on a
--               rounding rule passed on to the function.
-- Parameters:
--             P_Amount: Amount to be rounded
--             P_Currency_Code: Currency Code for the document tax is on.
--             P_Round_Rule: Rounding rule to follow (U for Up, D for Down,
--                           N for Nearest)
--             P_Calling_Sequence: Debugging string to indicate the path
--                                 of module calls to be printed out NOCOPY upon
--                                 error.
-- Returns:    Rounded Amount
--===========================================================================
function Ap_Round_Tax
                         (P_Amount           IN number
                         ,P_Currency_Code    IN varchar2
                         ,P_Round_Rule       IN varchar2
			 ,P_Calling_Sequence IN varchar2)
return number is
  l_func_currency         varchar2(15);
  l_fc_precision          number;  -- precision from currency
  l_fc_min_acct_unit      number;  -- mac from currency
  l_precision             number;  -- precision to be used
  l_min_acct_unit         number;  -- mac to be used
  l_rounded_amount        number;
  l_debug_loc             varchar2(30) := 'Ap_Round_Tax';
  l_curr_calling_sequence varchar2(2000);
  l_debug_info            varchar2(100);
begin

  -------------------------- DEBUG INFORMATION ------------------------------
  --AP_LOGGING_PKG.AP_Begin_Block(l_debug_loc);

  l_curr_calling_sequence := 'AP_UTILITIES_PKG.'||l_debug_loc||'<-'||p_calling_sequence;

  l_debug_info := 'Retrieve the precision, mac and functional currency';
  --AP_LOGGING_PKG.AP_Log(l_debug_info, l_debug_loc);
  ---------------------------------------------------------------------------
  -- eTax Uptake
  -- This select has been modified to obsolete FIN.minimum_accountable_unit
  -- and FC.precision from ap.financials_system_params_all table.
  -- All tax setup has been moved to eTax.
  -- This function may be obsolete totally later on.

  SELECT SP.base_currency_code,
         FC.precision,
         FC.minimum_accountable_unit
  INTO   l_func_currency,
         l_fc_precision,
         l_fc_min_acct_unit
  FROM   ap_system_parameters SP,
         fnd_currencies FC
  WHERE  FC.currency_code = P_Currency_Code;


  -------------------------- DEBUG INFORMATION ------------------------------
  l_debug_info := 'Calculate Rounded Amount';
  --AP_LOGGING_PKG.AP_Log(l_debug_info, l_debug_loc);
  ---------------------------------------------------------------------------
  --
  -- If the invoice is in the functional currency then we need
  -- to evaluate which precision/mac to use i.e. the financials options
  -- one or the currency one.
  -- Else, if the invoice is in a foreign currency we always use
  -- the financials options precision and mac.
  -- NOTE: This use of precision/mac is only valid for tax calculation
  --
  IF (P_Currency_Code = l_func_currency) THEN
    --
    -- When calculating tax in functional currency it is common to want
    -- to use the minimum precision available.  In our case that translates
    -- to taking the least between the financials options precision and the
    -- currency precision together with taking the greatest between the
    -- financials options mac and the currency mac.
    -- Do not use precision or mac defined in financials_system_parameters
    -- eTax Uptake

    l_precision := l_fc_precision;
    l_min_acct_unit := l_fc_min_acct_unit;

  ELSE
    l_precision := l_fc_precision;
    l_min_acct_unit := l_fc_min_acct_unit;
  END IF;

  --
  -- Do actual rounding calculation
  --
  IF (l_min_acct_unit is null) THEN
    IF (nvl(P_Round_Rule, 'N') = 'D') THEN
      l_rounded_amount := TRUNC(P_Amount, l_precision);
    ELSIF (nvl(P_Round_Rule, 'N') = 'U') THEN
      IF (P_Amount = TRUNC(P_Amount, l_precision)) THEN
        l_rounded_amount := P_Amount;
      ELSE
        l_rounded_amount := ROUND(P_Amount+(SIGN(P_Amount) *
                                            (POWER(10,(l_precision*(-1)))/2)),
                                  l_precision);
      END IF;
    ELSE /* Round Nearest by default */
      l_rounded_amount := ROUND(P_Amount, l_precision);
    END IF;
  ELSE
    IF (nvl(P_Round_Rule, 'N') = 'D') THEN
      l_rounded_amount := SIGN(P_Amount)*(FLOOR(ABS(P_Amount)/l_min_acct_unit)
                                          * l_min_acct_unit);
    ELSIF (nvl(P_Round_Rule, 'N') = 'U') THEN
      l_rounded_amount := SIGN(P_Amount)*(CEIL(ABS(P_Amount)/l_min_acct_unit)
                                          * l_min_acct_unit);

    ELSE
      l_rounded_amount := ROUND(P_Amount/l_min_acct_unit)*l_min_acct_unit;
    END IF;
  END IF;

  ---------------------------- DEBUG INFORMATION ----------------------------
  --AP_LOGGING_PKG.AP_End_Block(l_debug_loc);
  ---------------------------------------------------------------------------
  return(l_rounded_amount);

EXCEPTION
  WHEN OTHERS THEN
    --AP_LOGGING_PKG.AP_End_Block(l_debug_loc);
    IF (SQLCODE <> -20001) THEN
      FND_MESSAGE.SET_NAME('SQLAP', 'AP_DEBUG');
      FND_MESSAGE.SET_TOKEN('ERROR', 'SQLERRM');
      FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', l_curr_calling_sequence);
      FND_MESSAGE.SET_TOKEN('PARAMETERS',
                            'Amount to Round = '||to_char(p_amount)
			||', Currency Code = '||p_currency_code
                        ||', Rounding Rule = '||p_round_rule);
    END IF;
    APP_EXCEPTION.RAISE_EXCEPTION;
                                                                         --
end AP_ROUND_TAX;


function Ap_Round_Non_Rec_Tax
                         (P_Amount           IN number
                         ,P_Currency_Code    IN varchar2
                         ,P_Round_Rule       IN varchar2
                         ,P_Calling_Sequence IN varchar2)
return number is
  l_fc_precision          number;  -- precision from currency
  l_fc_min_acct_unit      number;  -- mac from currency
  l_precision             number;  -- precision to be used
  l_min_acct_unit         number;  -- mac to be used
  l_rounded_amount        number;
  l_debug_loc             varchar2(30) := 'Ap_Round_Non_Rec_Tax';
  l_curr_calling_sequence varchar2(2000);
  l_debug_info            varchar2(100);
begin
 -------------------------- DEBUG INFORMATION -------------------------
-----
  --AP_LOGGING_PKG.AP_Begin_Block(l_debug_loc);

  l_curr_calling_sequence :=  'AP_UTILITIES_PKG.'||l_debug_loc||'<-'||p_calling_sequence;

  -------------------------- DEBUG INFORMATION ------------------------
------
  l_debug_info := 'Calculate Rounded Amount';
  --AP_LOGGING_PKG.AP_Log(l_debug_info, l_debug_loc);
  ---------------------------------------------------------------------
------
  SELECT FC.precision,
         FC.minimum_accountable_unit
  INTO   l_fc_precision,
         l_fc_min_acct_unit
  FROM   fnd_currencies FC
  WHERE  FC.currency_code = P_Currency_Code;

    l_precision := l_fc_precision;
    l_min_acct_unit := l_fc_min_acct_unit;
 IF (l_min_acct_unit is null) THEN
    IF (nvl(P_Round_Rule, 'N') = 'D') THEN
    l_rounded_amount := TRUNC(P_Amount, l_precision);
    ELSIF (nvl(P_Round_Rule, 'N') = 'U') THEN
      IF (P_Amount = TRUNC(P_Amount, l_precision)) THEN
        l_rounded_amount := P_Amount;
      ELSE
        l_rounded_amount := ROUND(P_Amount+(SIGN(P_Amount) *
                                            (POWER(10,(l_precision*(-1)
))/2)),
                                  l_precision);
      END IF;
    ELSE /* Round Nearest by default */
      l_rounded_amount := ROUND(P_Amount, l_precision);
    END IF;
  ELSE
    IF (nvl(P_Round_Rule, 'N') = 'D') THEN
      l_rounded_amount := SIGN(P_Amount)*(FLOOR(ABS(P_Amount)/l_min_acct_unit)
                                          * l_min_acct_unit);
    ELSIF (nvl(P_Round_Rule, 'N') = 'U') THEN
      l_rounded_amount := SIGN(P_Amount)*(CEIL(ABS(P_Amount)/l_min_acct_unit)
                                          * l_min_acct_unit);
    ELSE
      l_rounded_amount := ROUND(P_Amount/l_min_acct_unit)*l_min_acct_unit;
    END IF;
  END IF;
  return(l_rounded_amount);

EXCEPTION
  WHEN OTHERS THEN
    --AP_LOGGING_PKG.AP_End_Block(l_debug_loc);
    IF (SQLCODE <> -20001) THEN
      FND_MESSAGE.SET_NAME('SQLAP', 'AP_DEBUG');
      FND_MESSAGE.SET_TOKEN('ERROR', 'SQLERRM');
      FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', l_curr_calling_sequence
);
      FND_MESSAGE.SET_TOKEN('PARAMETERS',
                            'Amount to Round = '||to_char(p_amount)
                        ||', Currency Code = '||p_currency_code
                        ||', Rounding Rule = '||p_round_rule);
    END IF;
    APP_EXCEPTION.RAISE_EXCEPTION;
end AP_Round_Non_Rec_Tax;

function Ap_Round_Precision
                         (P_Amount         IN number
                         ,P_Min_unit 	   IN number
			 ,P_Precision	   IN number
                         ) return number
is
  l_rounded_amount  number;
begin
                                                                         --
  select  decode(P_Min_unit,
            null, round(P_Amount, P_Precision),
                  round(P_Amount/P_Min_unit) * P_Min_unit)
  into    l_rounded_amount
  from    sys.dual;
                                                                         --
  return(l_rounded_amount);
                                                                         --
end AP_Round_Precision;

-----------------------------------------------------------------------
-- function get_current_gl_date() takes argument P_Date and
-- returns the open period in which P_Date falls.  If P_Date
-- does not fall within an open period, the function will return null
-----------------------------------------------------------------------
-- Bug 2106121. This function is returning null Period when the
-- p_date is the last day of the month with a time stamp. Added trunc
-- function to return the correct period.

function get_current_gl_date (P_Date IN date,
                              P_Org_ID IN number default
                                 mo_global.get_current_org_id) return varchar2
is
  cursor l_current_cursor is
    SELECT period_name
      FROM gl_period_statuses GLPS,
           ap_system_parameters_all SP
     WHERE application_id = 200
       AND sp.org_id = P_Org_Id
       AND GLPS.set_of_books_id = SP.set_of_books_id
       AND trunc(P_Date) BETWEEN start_date AND end_date
       AND closing_status in ('O', 'F')
       AND NVL(adjustment_period_flag, 'N') = 'N';

  l_period_name gl_period_statuses.period_name%TYPE := '';
  l_acct_date_org  Varchar2(30);
  l_api_name       CONSTANT VARCHAR2(200) := 'Get_Current_Gl_Date';
  l_debug_info     Varchar2(2000);

begin

   l_debug_info := 'Begining of Function';
   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
   END IF;

   l_acct_date_org := To_Char(P_Date, 'DD-MON-YYYY')||'-'||To_Char(P_Org_Id);

   l_debug_info := 'Index Value: '||l_acct_date_org;
   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
   END IF;


    If g_curr_period_name_t.Count > 0 Then

      If g_curr_period_name_t.exists(l_acct_date_org) Then

        l_period_name := g_curr_period_name_t(l_acct_date_org).period_name;

        l_debug_info := 'Period Name from existing plsql table for index found: '||l_period_name;
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;

      Else

        open l_current_cursor;
        fetch l_current_cursor into l_period_name;
        close l_current_cursor;

        g_curr_period_name_t(l_acct_date_org).period_name := l_period_name;

        l_debug_info :='Period Name from existing plsql table for index not found: '||l_period_name;
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;


      End If;

    Else

      open l_current_cursor;
      fetch l_current_cursor into l_period_name;
      close l_current_cursor;

      g_curr_period_name_t(l_acct_date_org).period_name := l_period_name;

      l_debug_info := 'Period Name not there in plsql table : '||l_period_name;
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;

    End If;

    return (l_period_name);

end get_current_gl_date;

--Bug1715368 The function get_gl_period_name is added to get the
--period name of the date passed irrespective of the period status.
-----------------------------------------------------------------------
-- function get_gl_period_name() takes argument P_Date and
-- returns the period name of the P_Date.
-----------------------------------------------------------------------
function get_gl_period_name (P_Date IN date,
                             P_Org_ID IN NUMBER DEFAULT
                                 mo_global.get_current_org_id) return varchar2
is
  cursor l_current_cursor is
      SELECT /*+ RESULT CACHE */ period_name /*Bug 8547912: added hint in cursor*/
        FROM gl_period_statuses GLPS,
	     ap_system_parameters_all SP
       WHERE application_id = 200
         AND sp.org_id = p_org_id
         AND GLPS.set_of_books_id = SP.set_of_books_id
         /* Bug 5368685 */
         AND trunc(P_Date) BETWEEN start_date AND end_date
         AND NVL(adjustment_period_flag, 'N') = 'N';

    l_period_name       gl_period_statuses.period_name%TYPE := '';

begin

      open l_current_cursor;
      fetch l_current_cursor into l_period_name;
      close l_current_cursor;


    return (l_period_name);

end get_gl_period_name;

-----------------------------------------------------------------------
-- function get_open_gl_date() takes argument P_Date and
-- returns the name and start GL date of the open/future period that falls on
-- or after P_Date.  The GL date and period name are written to
-- IN OUT NOCOPY parameters, P_GL_Date and P_Period_Name, passed to the
-- procedure.  If there is no open period, the procedure returns
-- null in the IN OUT NOCOPY parameters.
-----------------------------------------------------------------------
-- Bug 5572876. Changes related to caching is done
procedure get_open_gl_date
                         (P_Date              IN date
                         ,P_Period_Name       OUT NOCOPY varchar2
                         ,P_GL_Date           OUT NOCOPY date
                         ,P_Org_Id            IN number DEFAULT
                            mo_global.get_current_org_id)
is
  cursor l_open_cursor is
      SELECT MIN(start_date),
             period_name
        FROM gl_period_statuses GLPS,
             ap_system_parameters_all SP
       WHERE application_id = 200
         AND sp.org_id = P_Org_Id
         AND GLPS.set_of_books_id = SP.set_of_books_id
         AND end_date >= P_Date --Bug6809792
         AND closing_status in ('O', 'F')
         AND NVL(adjustment_period_flag, 'N') = 'N'
       GROUP BY period_name
       ORDER BY MIN(start_date);

  l_start_date date := '';
  l_period_name gl_period_statuses.period_name%TYPE := '';
  l_acct_date_org     Varchar2(30);
  l_api_name       CONSTANT VARCHAR2(200) := 'Get_Open_Gl_Date';
  l_debug_info     Varchar2(2000);


begin

    l_debug_info := 'Begining of Function';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;

    l_acct_date_org := To_Char(P_Date, 'DD-MON-YYYY')||'-'||To_Char(P_Org_Id);

    l_debug_info := 'Index Value: '||l_acct_date_org;
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;


    If g_open_period_name_t.Count > 0 Then

      If g_open_period_name_t.exists(l_acct_date_org) Then

        l_period_name := g_open_period_name_t(l_acct_date_org).period_name;
        l_start_date  := g_open_period_name_t(l_acct_date_org).start_date;

        l_debug_info := 'Period Name from existing plsql table for index found: '||l_period_name;
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;

      Else

        open l_open_cursor;
        fetch l_open_cursor into l_start_date, l_period_name;
        close l_open_cursor;

        l_debug_info:='Period Name from existing plsql table for index not found: '||l_period_name;
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;


        g_open_period_name_t(l_acct_date_org).period_name := l_period_name;
        g_open_period_name_t(l_acct_date_org).start_date  := l_start_date;

      End If;

    Else

      open l_open_cursor;
      fetch l_open_cursor into l_start_date, l_period_name;
      close l_open_cursor;

      g_open_period_name_t(l_acct_date_org).period_name := l_period_name;
      g_open_period_name_t(l_acct_date_org).start_date  := l_start_date;

      l_debug_info := 'Period Name not there in  plsql table: '||l_period_name;
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;

   End If;

   P_Period_Name := l_period_name;
   P_GL_Date := l_start_date;

end get_open_gl_date;

-----------------------------------------------------------------------
-- function get_only_open_gl_date() takes argument P_Date and
-- returns the name and start GL date of the open period that falls on
-- or after P_Date.  The GL date and period name are written to
-- IN OUT NOCOPY parameters, P_GL_Date and P_Period_Name, passed to the
-- procedure.  If there is no open period, the procedure returns
-- null in the IN OUT NOCOPY parameters.
-- Bug 5572876. Changes related to caching is done
-----------------------------------------------------------------------
procedure get_only_open_gl_date
                         (P_Date              IN date
                         ,P_Period_Name       OUT NOCOPY varchar2
                         ,P_GL_Date           OUT NOCOPY date
                         ,P_Org_Id            IN number DEFAULT
                              mo_global.get_current_org_id)
is
  cursor l_open_cursor is
      SELECT MIN(start_date),
             period_name
        FROM gl_period_statuses GLPS,
             ap_system_parameters_all SP  --8281653
       WHERE application_id = 200
         AND SP.org_id = P_Org_Id
         AND GLPS.set_of_books_id = SP.set_of_books_id
         AND (start_date > P_Date OR
              P_Date BETWEEN start_date AND end_date)
         AND closing_status = 'O'
         AND NVL(adjustment_period_flag, 'N') = 'N'
       GROUP BY period_name
       ORDER BY MIN(start_date);

  l_start_date date := '';
  l_period_name gl_period_statuses.period_name%TYPE := '';

begin

  open  l_open_cursor;
  fetch l_open_cursor into l_start_date, l_period_name;
  close l_open_cursor;

  P_Period_Name := l_period_name;
  P_GL_Date := l_start_date;

end get_only_open_gl_date;

-----------------------------------------------------------------------
-- Function get_exchange_rate() takes arguments exchange_rate_type,
-- exchange_date, and currency_code and returns the exchange_rate.
-- If no rate can be determined, the function will return null
-----------------------------------------------------------------------
function get_exchange_rate(
                 p_from_currency_code varchar2,
                 p_to_currency_code varchar2,
                 p_exchange_rate_type varchar2,
                 p_exchange_date date,
		 p_calling_sequence in varchar2) return number is

  l_rate  number := '';
  current_calling_sequence VARCHAR2(2000);
  debug_info               VARCHAR2(100);

begin
  -- Update the calling sequence
  --
  current_calling_sequence :=
     'AP_UTILITIES_PKG.get_exchange_rate<-'||P_Calling_Sequence;

  debug_info := 'Calling GL API to get the rate';
  l_rate := gl_currency_api.get_rate(p_from_currency_code, p_to_currency_code,
                          p_exchange_date, p_exchange_rate_type);

  return(l_rate);

  EXCEPTION
    WHEN gl_currency_api.NO_RATE THEN
       return(l_rate);
    WHEN OTHERS THEN
/* Note: this segment of code affects the purity of the function
         (ie with it, we cannot guarantee that package/dbms state
         will not be altered).  Such guarantees are necessary in
         order to use a stored function in the select-list of a
         query.  Therefore, I am commenting it out NOCOPY and simply
         returning null if no record is retrieved.

      if (SQLCODE <> -20001) then
        FND_MESSAGE.SET_NAME('SQLAP', 'AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR', SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', current_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS', 'p_from_currency_code = '||p_from_currency_code
                                  ||', p_to_currency_code = '||p_to_currency_code
                                  ||', p_exchange_rate_type = ' ||p_exchange_rate_type
                                  ||', p_exchange_date = '      ||TO_CHAR(p_exchange_date));
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO', debug_info);
      end if;
      APP_EXCEPTION.RAISE_EXCEPTION;
*/
     return(l_rate);
end get_exchange_rate;

--------------------------------------------------------------------
-- Procedure that will set the given profile option to the
-- given value on the server
---------------------------------------------------------------------

PROCEDURE Set_Profile(p_profile_option   IN vARCHAR2,
		      p_profile_value    IN VARCHAR2) IS
BEGIN

  FND_PROFILE.PUT(p_profile_option, p_profile_value);

END Set_Profile;

--------------------------------------------------------------------
-- Procedure that will get the AP_DEBUG message from the message
-- stack into a text buffer
---------------------------------------------------------------------

PROCEDURE AP_Get_Message(p_err_txt      OUT NOCOPY VARCHAR2) IS
BEGIN

    p_err_txt := fnd_message.get;

END AP_Get_Message;

--MO Access Control: Added the following new function for the
--multi org access control project.
--This function returns the current responsibility name the user is in.
FUNCTION Get_Window_Title RETURN VARCHAR2 IS

l_application_id fnd_responsibility_vl.application_id%type;
l_resp_id fnd_responsibility_vl.responsibility_id%TYPE;
l_wnd_context fnd_responsibility_vl.responsibility_name%TYPE;

BEGIN

 fnd_profile.get('RESP_ID',l_resp_id);
 fnd_profile.get('RESP_APPL_ID',l_application_id);


 SELECT responsibility_name
 INTO l_wnd_context
 FROM fnd_responsibility_vl
 WHERE application_id = l_application_id
 AND   responsibility_id = l_resp_id;


 return(l_wnd_context);


END Get_Window_Title;


FUNCTION Get_Window_Session_Title RETURN VARCHAR2 IS
  l_multi_org 		VARCHAR2(1);
  l_multi_cur		VARCHAR2(1);
  l_wnd_context 	VARCHAR2(60);
  l_id			VARCHAR2(15);
BEGIN
  /*
  ***
  *** Get multi-org and MRC information on the current
  *** prodcut installation.
  ***
   */
  SELECT 	nvl(multi_org_flag, 'N')
  ,		nvl(multi_currency_flag, 'N')
  INTO 		l_multi_org
  ,		l_multi_cur
  FROM		fnd_product_groups;

  /*
  ***
  *** Case #1 : Non-Multi-Org or Multi-SOB
  ***
  ***  A. MRC not installed, OR
  ***     MRC installed, Non-Primary/Reporting Books
  ***       Form Name (SOB Short Name) - Context Info
  ***       e.g. Maintain Forecast (US OPS) - Forecast Context Info
  ***
  ***  B. MRC installed, Primary Books
  ***       Form Name (SOB Short Name: Primary Currency) - Context Info
  ***       e.g. Maintain Forecast (US OPS: USD) - Forecast Context Info
  ***
  ***  C. MRC installed, Reporting Books
  ***       Form Name (SOB Short Name: Reporting Currency) - Context Info
  ***       e.g. Maintain Forecast (US OPS: EUR) - Forecast Context Info
  ***
   */

  IF (l_multi_org = 'N') THEN
    BEGIN
      select 	substrb((g.SHORT_NAME || decode(g.mrc_sob_type_code, 'N', NULL,
                                  decode(l_multi_cur, 'N', NULL,
                                         ': ' || substr(g.currency_code, 1, 5)))),1,60)
      into 	l_wnd_context
      from 	gl_sets_of_books g
      ,	 	ap_system_parameters aps
      where	aps.SET_OF_BOOKS_ID = g.SET_OF_BOOKS_ID;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        return (null);
    END;

  /*
  ***
  *** Case #2 : Multi-Org
  ***
  ***  A. MRC not installed, OR
  ***     MRC installed, Non-Primary/Reporting Books
  ***       Form Name (OU Name) - Context Info
  ***       e.g. Maintain Forecast (US West) - Forecast Context Info
  ***
  ***  B. MRC installed, Primary Books
  ***       Form Name (OU Name: Primary Currency) - Context Info
  ***       e.g. Maintain Forecast (US West: USD) - Forecast Context Info
  ***
  ***  C. MRC installed, Reporting Books
  ***       Form Name (OU Name: Reporting Currency) - Context Info
  ***       e.g. Maintain Forecast (US West: EUR) - Forecast Context Info
  ***
   */
  ELSE

--Bug 1696006 replace this line
--    FND_PROFILE.GET ('ORG_ID', l_id);
--with the following lines
    l_id := substrb(userenv('CLIENT_INFO'),1,10);
    if substrb(l_id,1,1) = ' ' then
        l_id := NULL;
    end if;
--End Bug 1696006

    BEGIN
      select 	substrb((substr(h.Name, 1, 53)
                || decode(g.mrc_sob_type_code, 'N', NULL,
                            decode(l_multi_cur, 'N', NULL,
                                   ': ' || substr(g.currency_code, 1, 5)))),1,60)
      into 	l_wnd_context
      from      gl_sets_of_books g,
                ap_system_parameters aps,
                hr_operating_units h
      where 	h.organization_id = to_number(l_id)
	--Bug 13975870
      and h.organization_id = aps.org_id
	--Bug 13975870
      and       aps.set_of_books_id = g.set_of_books_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        return (NULL);
    END;


  END IF;

  return l_wnd_context;

END Get_Window_Session_Title;

FUNCTION overlay_segments (
        p_balancing_segment             IN      VARCHAR2,
        p_cost_center_segment           IN      VARCHAR2,
        p_account_segment               IN      VARCHAR2,
        p_concatenated_segments         IN      VARCHAR2,
        p_ccid                          IN OUT NOCOPY  NUMBER,
        p_set_of_books_id               IN      NUMBER,
        p_overlay_mode                  IN      VARCHAR2,
        p_unbuilt_flex                  OUT NOCOPY     VARCHAR2,
        p_reason_unbuilt_flex           OUT NOCOPY     VARCHAR2,
        p_resp_appl_id                  IN      NUMBER,
        p_resp_id                       IN      NUMBER,
        p_user_id                       IN      NUMBER,
        p_calling_sequence              IN      VARCHAR2,
        p_ccid_to_segs                  IN      VARCHAR2 Default NULL,
        p_accounting_date               IN DATE DEFAULT SYSDATE) --7531219

RETURN BOOLEAN IS

overlay_segments_failure        EXCEPTION;
l_ccid                          NUMBER := p_ccid;
l_chart_of_accounts_id          NUMBER;
l_segments                      FND_FLEX_EXT.SEGMENTARRAY;
l_partial_segments              FND_FLEX_EXT.SEGMENTARRAY;
l_num_segments                  NUMBER;
l_account_segment_num           NUMBER;
l_balancing_segment_num         NUMBER;
l_cost_center_segment_num       NUMBER;
l_partial_num_segments          NUMBER;
l_overlayed_segments            VARCHAR2(2000);
l_unbuilt_flex                  VARCHAR2(240):='';
l_reason_unbuilt_flex           VARCHAR2(2000):='';
l_result                        BOOLEAN;
l_segment_delimiter             VARCHAR2(1);
l_counter                       NUMBER;
current_calling_sequence        VARCHAR2(2000);
debug_info                      VARCHAR2(500);

BEGIN
  -- Update the calling sequence
  --
  current_calling_sequence :=  'AP_UTILITIES_PKG.Overlay_Segments<-'||P_calling_sequence;

  -----------------------------------------------------------
  -- Reject if it's item line but no account info
  -----------------------------------------------------------
  debug_info := 'Select Charts of Account';



      SELECT chart_of_accounts_id
        INTO l_chart_of_accounts_id
        FROM gl_sets_of_books
       WHERE set_of_books_id = p_set_of_books_id;

  debug_info := 'Get segment delimiter';


       l_segment_delimiter := FND_FLEX_EXT.GET_DELIMITER(
                                                'SQLGL',
                                                'GL#',
                                                l_chart_of_accounts_id);



       IF (l_segment_delimiter IS NULL) THEN
             l_reason_unbuilt_flex := FND_MESSAGE.GET;
       END IF;

       -- Get Segment array for the input ccid
       --

      IF (l_ccid IS NOT NULL) Then

  debug_info := 'Get segment array';
      l_result := FND_FLEX_EXT.GET_SEGMENTS(
                                      'SQLGL',
                                      'GL#',
                                      l_chart_of_accounts_id,
                                      l_ccid,
                                      l_num_segments,
                                      l_segments);


        IF (NOT l_result) THEN
              l_reason_unbuilt_flex := FND_MESSAGE.GET;
        END IF;

      END IF; -- l_ccid not null
      --
      -- Get concatenated segments from ccid
      IF (nvl(p_ccid_to_segs,'N') = 'Y') Then
      l_overlayed_segments :=  FND_FLEX_EXT.Concatenate_Segments(l_num_segments,
           l_segments,
           l_segment_delimiter);

           IF (NOT l_result) THEN
                  l_reason_unbuilt_flex := FND_MESSAGE.GET;
                  l_ccid := -1;
           END IF;

           p_ccid := l_ccid;
           p_unbuilt_flex := l_overlayed_segments;
           p_reason_unbuilt_flex := 'Used for deriving segments from ccid';
           Return(TRUE);
      END IF;


        -- Get the partial segment array
        --
       IF (p_concatenated_segments IS NOT NULL) THEN

           debug_info := 'Get Partial segment array';

           l_partial_num_segments := FND_FLEX_EXT.breakup_segments(p_concatenated_segments,
                                          l_segment_delimiter,
                                          l_partial_segments); --OUT

       END IF;
        -- Overlay partial with original
        -- only if l_num_segments = l_partial_num_segments

       IF ((l_ccid IS NOT NULL) AND (p_concatenated_segments IS NOT NULL)) Then
        IF (l_num_segments = l_partial_num_segments) Then



           debug_info := 'Overlay Partial segment array';

           For l_counter IN 1..l_num_segments LOOP


               IF (l_partial_segments(l_counter) IS NOT NULL) Then

                   l_segments(l_counter) := l_partial_segments(l_counter);

               End If;



           END LOOP;

        ELSE
           -- Reject Inconsistent Segments
           --
           p_ccid := -1;
           p_reason_unbuilt_flex := 'Inconsistent Segments';
           p_unbuilt_flex := Null;
           RETURN(TRUE);

        END IF;

     ElSIF ((l_ccid IS NULL) AND (p_concatenated_segments IS NOT NULL)) Then

        -- we want to overlay concatenated segment
        l_segments := l_partial_segments;
        l_num_segments := l_partial_num_segments;

     END IF; -- l_ccid is not null

        -- Get the segment num for
        -- GL_ACCOUNT , GL_BALANCING and GL_COST_CENTER


        l_result := FND_FLEX_KEY_API.GET_SEG_ORDER_BY_QUAL_NAME(
                                    101,
                                    'GL#',
                                    l_chart_of_accounts_id,
                                    'GL_ACCOUNT',
                                    l_account_segment_num);


        IF (NOT l_result) THEN
            l_reason_unbuilt_flex := FND_MESSAGE.GET;
        END IF;


        l_result :=  FND_FLEX_KEY_API.GET_SEG_ORDER_BY_QUAL_NAME(
                                    101,
                                    'GL#',
                                    l_chart_of_accounts_id,
                                    'GL_BALANCING',
                                    l_balancing_segment_num);


        IF (NOT l_result) THEN
            l_reason_unbuilt_flex := FND_MESSAGE.GET;
        END IF;


        l_result :=  FND_FLEX_KEY_API.GET_SEG_ORDER_BY_QUAL_NAME(
                                    101,
                                    'GL#',
                                    l_chart_of_accounts_id,
                                    'FA_COST_CTR',
                                    l_cost_center_segment_num);


        IF (NOT l_result) THEN
            l_reason_unbuilt_flex := FND_MESSAGE.GET;
        END IF;



        -- Now overlay the Account, balancing and Cost Center segments
        -- if not null.


        IF (p_balancing_segment IS NOT NULL) Then

           debug_info := 'Overlay balancing segment ';
            l_segments(l_balancing_segment_num) := p_balancing_segment;

        End IF;


        IF (p_cost_center_segment IS NOT NULL) Then

           debug_info := 'Overlay Cost Center segment ';
            l_segments(l_cost_center_segment_num) := p_cost_center_segment;

        End IF;

        IF (p_account_segment IS NOT NULL) Then

           debug_info := 'Overlay Account segment ';
            l_segments(l_account_segment_num) := p_account_segment;

        End IF;


       -- Get Concat Segments Back
       -- from seg array

 l_overlayed_segments :=  FND_FLEX_EXT.Concatenate_Segments(l_num_segments,
                                             l_segments,
                                              l_segment_delimiter);

        IF (NOT l_result) THEN
            l_reason_unbuilt_flex := FND_MESSAGE.GET;
        END IF;





       -- only if for creation  (Use Validate segs with
       -- CHECK_COMBINATION and CREATE_COMBINATION)
     IF (p_overlay_mode = 'CHECK') Then


         debug_info := 'Validate Overlayed segments ';
         IF (fnd_flex_keyval.validate_segs('CHECK_COMBINATION' ,
                        'SQLGL',
                        'GL#',
                        l_chart_of_accounts_id,
                        l_overlayed_segments,
                        'V',
                        nvl(p_accounting_date, sysdate), -- 7531219
                        'ALL',
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        FALSE,
                        FALSE,
        		p_resp_appl_id,
        		p_resp_id,
        		p_user_id) <> TRUE) Then

            l_ccid := -1;
            l_reason_unbuilt_flex  := fnd_flex_keyval.error_message;
            l_unbuilt_flex := l_overlayed_segments;

         Else

            l_ccid := 666;
            l_reason_unbuilt_flex := NULL;
            l_unbuilt_flex := NULL;
         END IF;


     ELSIF (p_overlay_mode = 'CREATE') Then

         debug_info := 'Create Overlayed segments ';
         IF (fnd_flex_keyval.validate_segs('CREATE_COMBINATION' ,
                        'SQLGL',
                        'GL#',
                        l_chart_of_accounts_id,
                        l_overlayed_segments,
                        'V',
                        nvl(p_accounting_date, sysdate), --7531219
                        'ALL',
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        FALSE,
                        FALSE,
        		p_resp_appl_id,
        		p_resp_id,
        		p_user_id) <> TRUE) Then

            l_ccid := -1;
            l_reason_unbuilt_flex  := fnd_flex_keyval.error_message;
            l_unbuilt_flex := l_overlayed_segments;

         Else

            l_ccid := fnd_flex_keyval.combination_id;
            l_reason_unbuilt_flex := NULL;
            l_unbuilt_flex := NULL;

         END IF;

    -- Bug 1414119 Added the ELSIF condition below to avoid autonomous
    -- transaction insert for new code combinations when dynamic insert
    -- is on.

     ELSIF (p_overlay_mode = 'CREATE_COMB_NO_AT') Then

         debug_info := 'Create Overlayed segments ';
         IF (fnd_flex_keyval.validate_segs('CREATE_COMB_NO_AT' ,
                        'SQLGL',
                        'GL#',
                        l_chart_of_accounts_id,
                        l_overlayed_segments,
                        'V',
                        nvl(p_accounting_date, sysdate), --7531219
                        'ALL',
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        FALSE,
                        FALSE,
                p_resp_appl_id,
                p_resp_id,
                p_user_id) <> TRUE) Then

            l_ccid := -1;
            l_reason_unbuilt_flex  := fnd_flex_keyval.error_message;
            l_unbuilt_flex := l_overlayed_segments;

         Else

            l_ccid := fnd_flex_keyval.combination_id;
            l_reason_unbuilt_flex := NULL;
            l_unbuilt_flex := NULL;

         END IF;


     END IF;

 --
 -- Return value
-- Bug 3621994 added if condition. CCID should be returned with the overlayed
-- value only if the mode is not check . (Due to 3282531).
IF (p_overlay_mode <> 'CHECK') Then
 p_ccid := l_ccid;

End IF;

p_unbuilt_flex := l_unbuilt_flex;
 p_reason_unbuilt_flex := l_reason_unbuilt_flex;

 RETURN (TRUE);


EXCEPTION

WHEN OTHERS THEN


      if (SQLCODE <> -20001) then
        FND_MESSAGE.SET_NAME('SQLAP', 'AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR', SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', current_calling_sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO', debug_info);
      end if;


RETURN(FALSE);

END Overlay_Segments;

 --following function added for BUG 1909374
 FUNCTION overlay_segments_by_gldate(
        p_balancing_segment             IN      VARCHAR2,
        p_cost_center_segment           IN      VARCHAR2,
        p_account_segment               IN      VARCHAR2,
        p_concatenated_segments         IN      VARCHAR2,
        p_ccid                          IN OUT NOCOPY  NUMBER,
        p_accounting_date               IN      DATE,
        p_set_of_books_id               IN      NUMBER,
        p_overlay_mode                  IN      VARCHAR2,
        p_unbuilt_flex                  OUT NOCOPY     VARCHAR2,
        p_reason_unbuilt_flex           OUT NOCOPY     VARCHAR2,
        p_resp_appl_id                  IN      NUMBER,
        p_resp_id                       IN      NUMBER,
        p_user_id                       IN      NUMBER,
        p_calling_sequence              IN      VARCHAR2,
        p_ccid_to_segs                  IN      VARCHAR2 Default NULL)

RETURN BOOLEAN IS

overlay_segments_failure        EXCEPTION;
l_ccid                          NUMBER := p_ccid;
l_chart_of_accounts_id          NUMBER;
l_segments                      FND_FLEX_EXT.SEGMENTARRAY;
l_partial_segments              FND_FLEX_EXT.SEGMENTARRAY;
l_num_segments                  NUMBER;
l_account_segment_num           NUMBER;
l_balancing_segment_num         NUMBER;
l_cost_center_segment_num       NUMBER;
l_partial_num_segments          NUMBER;
l_overlayed_segments            VARCHAR2(2000);
l_unbuilt_flex                  VARCHAR2(240):='';
l_reason_unbuilt_flex           VARCHAR2(2000):='';
l_result                        BOOLEAN;
l_segment_delimiter             VARCHAR2(1);
l_counter                       NUMBER;
current_calling_sequence        VARCHAR2(2000);
debug_info                      VARCHAR2(500);

BEGIN
  -- Update the calling sequence
  --
  current_calling_sequence :=  'AP_UTILITIES_PKG.Overlay_Segments<-'||P_calling_sequence;

  -----------------------------------------------------------
  -- Reject if it's item line but no account info
  -----------------------------------------------------------
  debug_info := 'Select Charts of Account';



      SELECT chart_of_accounts_id
        INTO l_chart_of_accounts_id
        FROM gl_sets_of_books
       WHERE set_of_books_id = p_set_of_books_id;

  debug_info := 'Get segment delimiter';


       l_segment_delimiter := FND_FLEX_EXT.GET_DELIMITER(
                                                'SQLGL',
                                                'GL#',
                                                l_chart_of_accounts_id);



       IF (l_segment_delimiter IS NULL) THEN
             l_reason_unbuilt_flex := FND_MESSAGE.GET;
       END IF;

       -- Get Segment array for the input ccid
       --

      IF (l_ccid IS NOT NULL) Then

  debug_info := 'Get segment array';
      l_result := FND_FLEX_EXT.GET_SEGMENTS(
                                      'SQLGL',
                                      'GL#',
                                      l_chart_of_accounts_id,
                                      l_ccid,
                                      l_num_segments,
                                      l_segments);


        IF (NOT l_result) THEN
              l_reason_unbuilt_flex := FND_MESSAGE.GET;
        END IF;

      END IF; -- l_ccid not null
      --
      -- Get concatenated segments from ccid
      IF (nvl(p_ccid_to_segs,'N') = 'Y') Then
      l_overlayed_segments :=  FND_FLEX_EXT.Concatenate_Segments(l_num_segments,
           l_segments,
           l_segment_delimiter);

           IF (NOT l_result) THEN
                  l_reason_unbuilt_flex := FND_MESSAGE.GET;
                  l_ccid := -1;
           END IF;

           p_ccid := l_ccid;
           p_unbuilt_flex := l_overlayed_segments;
           p_reason_unbuilt_flex := 'Used for deriving segments from ccid';
           Return(TRUE);
      END IF;


        -- Get the partial segment array
        --
       IF (p_concatenated_segments IS NOT NULL) THEN

           debug_info := 'Get Partial segment array';

           l_partial_num_segments := FND_FLEX_EXT.breakup_segments(p_concatenated_segments,
                                          l_segment_delimiter,
                                          l_partial_segments); --OUT

       END IF;
        -- Overlay partial with original
        -- only if l_num_segments = l_partial_num_segments

       IF ((l_ccid IS NOT NULL) AND (p_concatenated_segments IS NOT NULL)) Then
        IF (l_num_segments = l_partial_num_segments) Then



           debug_info := 'Overlay Partial segment array';

           For l_counter IN 1..l_num_segments LOOP


               IF (l_partial_segments(l_counter) IS NOT NULL) Then

                   l_segments(l_counter) := l_partial_segments(l_counter);

               End If;



           END LOOP;

        ELSE
           -- Reject Inconsistent Segments
           --
           p_ccid := -1;
           p_reason_unbuilt_flex := 'Inconsistent Segments';
           p_unbuilt_flex := Null;
           RETURN(TRUE);

        END IF;

     ElSIF ((l_ccid IS NULL) AND (p_concatenated_segments IS NOT NULL)) Then

        -- we want to overlay concatenated segment
        l_segments := l_partial_segments;
        l_num_segments := l_partial_num_segments;

     END IF; -- l_ccid is not null

        -- Get the segment num for
        -- GL_ACCOUNT , GL_BALANCING and GL_COST_CENTER


        l_result := FND_FLEX_KEY_API.GET_SEG_ORDER_BY_QUAL_NAME(
                                    101,
                                    'GL#',
                                    l_chart_of_accounts_id,
                                    'GL_ACCOUNT',
                                    l_account_segment_num);


        IF (NOT l_result) THEN
            l_reason_unbuilt_flex := FND_MESSAGE.GET;
        END IF;


        l_result := FND_FLEX_KEY_API.GET_SEG_ORDER_BY_QUAL_NAME(
                                    101,
                                    'GL#',
                                    l_chart_of_accounts_id,
                                    'GL_BALANCING',
                                    l_balancing_segment_num);


        IF (NOT l_result) THEN
            l_reason_unbuilt_flex := FND_MESSAGE.GET;
        END IF;


        l_result := FND_FLEX_KEY_API.GET_SEG_ORDER_BY_QUAL_NAME(
                                    101,
                                    'GL#',
                                    l_chart_of_accounts_id,
                                    'FA_COST_CTR',
                                    l_cost_center_segment_num);


        IF (NOT l_result) THEN
            l_reason_unbuilt_flex := FND_MESSAGE.GET;
        END IF;



        -- Now overlay the Account, balancing and Cost Center segments
        -- if not null.


        IF (p_balancing_segment IS NOT NULL) Then

           debug_info := 'Overlay balancing segment ';
            l_segments(l_balancing_segment_num) := p_balancing_segment;

        End IF;


        IF (p_cost_center_segment IS NOT NULL) Then

           debug_info := 'Overlay Cost Center segment ';
            l_segments(l_cost_center_segment_num) := p_cost_center_segment;

        End IF;

        IF (p_account_segment IS NOT NULL) Then

           debug_info := 'Overlay Account segment ';
            l_segments(l_account_segment_num) := p_account_segment;

        End IF;


       -- Get Concat Segments Back
       -- from seg array

 l_overlayed_segments :=  FND_FLEX_EXT.Concatenate_Segments(l_num_segments,
                                             l_segments,
                                              l_segment_delimiter);

        IF (NOT l_result) THEN
            l_reason_unbuilt_flex := FND_MESSAGE.GET;
        END IF;





       -- only if for creation  (Use Validate segs with
       -- CHECK_COMBINATION and CREATE_COMBINATION)
     IF (p_overlay_mode = 'CHECK') Then


         debug_info := 'Validate Overlayed segments ';
         IF (fnd_flex_keyval.validate_segs('CHECK_COMBINATION' ,
                        'SQLGL',
                        'GL#',
                        l_chart_of_accounts_id,
                        l_overlayed_segments,
                        'V',
                        p_accounting_date,
                        'ALL',
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        FALSE,
                        FALSE,
        		p_resp_appl_id,
        		p_resp_id,
        		p_user_id) <> TRUE) Then

            l_ccid := -1;
            l_reason_unbuilt_flex  := fnd_flex_keyval.error_message;
            l_unbuilt_flex := l_overlayed_segments;

         Else

            l_ccid := 666;
            l_reason_unbuilt_flex := NULL;
            l_unbuilt_flex := NULL;
         END IF;


     ELSIF (p_overlay_mode = 'CREATE') Then

         debug_info := 'Create Overlayed segments ';
         IF (fnd_flex_keyval.validate_segs('CREATE_COMBINATION' ,
                        'SQLGL',
                        'GL#',
                        l_chart_of_accounts_id,
                        l_overlayed_segments,
                        'V',
                        p_accounting_date,
                        'ALL',
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        FALSE,
                        FALSE,
        		p_resp_appl_id,
        		p_resp_id,
        		p_user_id) <> TRUE) Then

            l_ccid := -1;
            l_reason_unbuilt_flex  := fnd_flex_keyval.error_message;
            l_unbuilt_flex := l_overlayed_segments;

         Else

            l_ccid := fnd_flex_keyval.combination_id;
            l_reason_unbuilt_flex := NULL;
            l_unbuilt_flex := NULL;

         END IF;

    -- Bug 1414119 Added the ELSIF condition below to avoid autonomous
    -- transaction insert for new code combinations when dynamic insert
    -- is on.

     ELSIF (p_overlay_mode = 'CREATE_COMB_NO_AT') Then

         debug_info := 'Create Overlayed segments ';
         IF (fnd_flex_keyval.validate_segs('CREATE_COMB_NO_AT' ,
                        'SQLGL',
                        'GL#',
                        l_chart_of_accounts_id,
                        l_overlayed_segments,
                        'V',
                        p_accounting_date,
                        'ALL',
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        FALSE,
                        FALSE,
                p_resp_appl_id,
                p_resp_id,
                p_user_id) <> TRUE) Then

            l_ccid := -1;
            l_reason_unbuilt_flex  := fnd_flex_keyval.error_message;
            l_unbuilt_flex := l_overlayed_segments;

         Else

            l_ccid := fnd_flex_keyval.combination_id;
            l_reason_unbuilt_flex := NULL;
            l_unbuilt_flex := NULL;

         END IF;


     END IF;

 --
 -- Return value
 p_ccid := l_ccid;
 p_unbuilt_flex := l_unbuilt_flex;
 p_reason_unbuilt_flex := l_reason_unbuilt_flex;

 RETURN (TRUE);


EXCEPTION

WHEN OTHERS THEN


      if (SQLCODE <> -20001) then
        FND_MESSAGE.SET_NAME('SQLAP', 'AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR', SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', current_calling_sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO', debug_info);
      end if;


RETURN(FALSE);

END Overlay_Segments_by_gldate;


FUNCTION check_partial(
        p_concatenated_segments         IN      VARCHAR2,
        p_partial_segments_flag         OUT NOCOPY     VARCHAR2,
        p_set_of_books_id               IN      NUMBER,
        p_error_message                 OUT NOCOPY     VARCHAR2,
        p_calling_sequence              IN      VARCHAR2)

RETURN BOOLEAN IS

l_chart_of_accounts_id          NUMBER;
l_segments                      FND_FLEX_EXT.SEGMENTARRAY;
l_num_segments                  NUMBER;
l_segment_delimiter             VARCHAR2(1);
current_calling_sequence        VARCHAR2(2000);
debug_info                      VARCHAR2(500);



BEGIN
  -- Update the calling sequence
  --
  current_calling_sequence :=  'AP_UTILITIES_PKG.Check_Partial<-'||P_calling_sequence;



  debug_info := 'Select Charts of Account';

      SELECT chart_of_accounts_id
        INTO l_chart_of_accounts_id
        FROM gl_sets_of_books
       WHERE set_of_books_id = p_set_of_books_id;

  debug_info := 'Get Segment Delimiter';

       l_segment_delimiter := FND_FLEX_EXT.GET_DELIMITER(
                                                'SQLGL',
                                                'GL#',
                                                l_chart_of_accounts_id);



       IF (l_segment_delimiter IS NULL) THEN
             p_error_message:= FND_MESSAGE.GET;
       END IF;

        debug_info := 'Break Segments';
        l_num_segments := FND_FLEX_EXT.breakup_segments(p_concatenated_segments,
                                          l_segment_delimiter,
                                          l_segments); --OUT

           p_partial_segments_flag := 'N';

           For l_counter IN 1..l_num_segments LOOP


               IF (l_segments(l_counter) IS NULL) Then

                  p_partial_segments_flag := 'Y';

               End If;


           END LOOP;
RETURN (TRUE);

EXCEPTION



WHEN OTHERS THEN

      if (SQLCODE <> -20001) then
        FND_MESSAGE.SET_NAME('SQLAP', 'AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR', SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', current_calling_sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO', debug_info);
      end if;
      RETURN(FALSE);

END Check_partial;

FUNCTION IS_CCID_VALID ( p_ccid IN NUMBER,
                         p_chart_of_accounts_id  IN NUMBER,
                         p_date  IN DATE ,
                         p_calling_sequence IN VARCHAR2  )

RETURN BOOLEAN IS

-- Bug 3621994 -Deleted the unnecessary variables (due to 3086316)

l_enabled_flag                  gl_code_combinations.enabled_flag%type;
current_calling_sequence        VARCHAR2(2000);
debug_info                      VARCHAR2(500);

BEGIN
  -- Update the calling sequence
  --
  current_calling_sequence :=  'AP_UTILITIES_PKG.Ccid_Valid<-'||P_calling_sequence;

  debug_info := 'Validate ccid as a whole';

  If (( fnd_flex_keyval.validate_ccid(
                          APPL_SHORT_NAME =>'SQLGL',
                          KEY_FLEX_CODE =>  'GL#',
                          STRUCTURE_NUMBER =>p_chart_of_accounts_id,
                          COMBINATION_ID =>p_ccid,
                          DISPLAYABLE =>'ALL',
                          DATA_SET => NULL,
                          VRULE => NULL,
                          SECURITY => 'ENFORCE',
                          GET_COLUMNS => NULL,
			  RESP_APPL_ID => FND_GLOBAL.resp_appl_id,
                          RESP_ID => FND_GLOBAL.resp_id,
                          USER_ID => FND_GLOBAL.user_id))) then

             If (NOT ( fnd_flex_keyval.is_valid ) OR
                  (fnd_flex_keyval.is_secured)) then
                RETURN(FALSE);
             end if;

   Else
            RETURN(FALSE);
   End if;

-- Bug 3621994 - Removed following code to get and validate segments as It
  --Is redundant and casused performance issue (due to 3086316)

/* Bug: 3486932 Check to see if the ccid is enabled in GL. If the ccid
       is not enabled then return -1 */

     SELECT nvl(enabled_flag,'N')
     INTO   l_enabled_flag
     FROM   gl_code_combinations
     WHERE  code_combination_id = p_ccid
     AND    chart_of_accounts_id = p_chart_of_accounts_id
      -- Bug 3486932 - Added the following conditions to verify if GL account
      -- is valid and summary flag and template id are proper.

     -- Bug 3379623 deleted the previous AND stmt and added the below two.
     AND    NVL(start_date_active, TRUNC(p_date))   <= TRUNC(p_date)
     AND    NVL(end_date_active,
                TO_DATE('12/31/4012','MM/DD/YYYY')) >= TRUNC(p_date)
     AND    summary_flag = 'N'
     AND    template_id is NULL;

     IF l_enabled_flag = 'N' then

         Return (FALSE);

     End If;


  RETURN (TRUE);

EXCEPTION

WHEN OTHERS THEN

      if (SQLCODE <> -20001) then
        FND_MESSAGE.SET_NAME('SQLAP', 'AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR', SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', current_calling_sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO', debug_info);
      end if;
      RETURN(FALSE);

END IS_CCID_VALID;



-- MO Access Control: Added the parameter p_org_id.
-- including default to the current_org_id

FUNCTION Get_Inventory_Org(P_org_id Number default mo_global.get_current_org_id) return NUMBER IS
   inv_org_id financials_system_parameters.inventory_organization_id%TYPE;
BEGIN

  select inventory_organization_id
  into   inv_org_id
  from   financials_system_parameters
  where  org_id = p_org_id;

  return(inv_org_id);

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      return(null);
END Get_Inventory_Org;


PROCEDURE mc_flag_enabled(  p_sob_id            IN     NUMBER,
                            p_appl_id           IN     NUMBER,
                            p_org_id            IN     NUMBER,
                            p_fa_book_code      IN     VARCHAR2,
                            p_base_currency     IN     VARCHAR2,
                            p_mc_flag_enabled   OUT NOCOPY    VARCHAR2,
                            p_calling_sequence  IN     VARCHAR2) IS

    loop_index      NUMBER := 1;
    l_sob_list      gl_mc_info.r_sob_list:= gl_mc_info.r_sob_list() ;
    current_calling_sequence        VARCHAR2(2000);
    debug_info                      VARCHAR2(500);
    NO_GL_DATA 						EXCEPTION;

BEGIN
    -- Update the calling sequence
    --
	current_calling_sequence := 'AP_UTILITIES_PKG.mc_flag_enabled<-'||p_calling_sequence;

    debug_info := 'Calling GL package to get a list of reporting set of books';
    gl_mc_info.get_associated_sobs (p_sob_id,
                                    p_appl_id, p_org_id, NULL,
                                    l_sob_list);
    p_mc_flag_enabled := 'Y';

    debug_info := 'Loop through every set of books and see if all the reporting currency is euro derived';

    WHILE   loop_index <= l_sob_list.count LOOP
        if ( gl_currency_api.is_fixed_rate (p_base_currency,
                                            l_sob_list(loop_index).r_sob_curr,
                                            sysdate) <> 'Y' ) then
                p_mc_flag_enabled := 'N';
                EXIT;
        end if;
        if ( gl_currency_api.is_fixed_rate (p_base_currency,
                                            l_sob_list(loop_index).r_sob_curr,
                                            sysdate) is NULL ) then
             raise NO_GL_DATA;
        end if;
        loop_index := loop_index +1;
    END LOOP;

EXCEPTION
WHEN NO_GL_DATA THEN

     p_mc_flag_enabled := NULL;

    if (SQLCODE <> -20001) then
        FND_MESSAGE.SET_NAME('SQLAP', 'AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR', SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', current_calling_sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO', debug_info);
    end if;

END mc_flag_enabled;


function AP_Get_Sob_Order_Col
                          (P_Primary_SOB_ID     IN   number
                          ,P_Secondary_SOB_ID   IN   number
                          ,P_SOB_ID             IN   number
                          ,P_ORG_ID             IN   number
                          ,P_Calling_Sequence   IN   varchar2)
return NUMBER is
	l_primary_sob_id   	 number;
	l_sob_order_col 	 number;
	current_calling_sequence varchar2(2000);
	debug_info  		 varchar2(500);
begin
   -- Update the calling sequence
   --
   current_calling_sequence :=
       'AP_UTILITIES_PKG.AP_Get_Sob_Order_Col<-'||p_calling_sequence;
   debug_info := 'Getting the order column value';
   l_primary_sob_id :=GL_MC_INFO.get_source_ledger_id(P_SOB_ID,200,P_ORG_ID,'');

/*
   SELECT DISTINCT primary_set_of_books_id
   INTO   l_primary_sob_id
   FROM   gl_mc_reporting_options
   WHERE  reporting_set_of_books_id = P_SOB_ID
   AND    application_id = 200;
*/
   if (l_primary_sob_id = P_Primary_SOB_ID) then
      l_sob_order_col := 1;
   else
      l_sob_order_col := 2;
   end if;

  return (l_sob_order_col);

EXCEPTION
WHEN OTHERS THEN

    if (SQLCODE <> -20001) then
        FND_MESSAGE.SET_NAME('SQLAP', 'AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR', SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', current_calling_sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO', debug_info);
    end if;
        return NULL;

end AP_Get_Sob_Order_Col;


FUNCTION get_charge_account
                          ( p_ccid                 IN  NUMBER,
                            p_chart_of_accounts_id IN  NUMBER,
                            p_calling_sequence     IN  VARCHAR2)
RETURN VARCHAR2 IS

    current_calling_sequence        VARCHAR2(2000);
    debug_info                      VARCHAR2(500);
    l_return_val                    VARCHAR2(2000);
BEGIN
    -- Update the calling sequence
    --
    current_calling_sequence := 'AP_UTILITIES_PKG.get_charge_account<-'||p_calling_sequence;
    debug_info := 'Calling fnd function to validate ccid';

      if p_ccid <> -1 then

            l_return_val := FND_FLEX_EXT.GET_SEGS(
                               APPLICATION_SHORT_NAME => 'SQLGL',
                               KEY_FLEX_CODE          => 'GL#',
                               STRUCTURE_NUMBER       => P_CHART_OF_ACCOUNTS_ID,
                               COMBINATION_ID         => P_CCID);

       else
		l_return_val := null;
     end if;
                return (l_return_val);

EXCEPTION
WHEN OTHERS THEN

    if (SQLCODE <> -20001) then
        FND_MESSAGE.SET_NAME('SQLAP', 'AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR', SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', current_calling_sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO', debug_info);
    end if;
        return NULL;

END get_charge_account;

FUNCTION get_invoice_status(p_invoice_id        IN NUMBER,
                            p_calling_sequence  IN VARCHAR2)
         RETURN VARCHAR2
 IS
         l_force_revalidation_flag       VARCHAR2(1);   --bug7244642
         invoice_status                  VARCHAR2(80);
         invoice_approval_status         VARCHAR2(25);
         invoice_approval_flag           VARCHAR2(1);
         distribution_approval_flag      VARCHAR2(1);
         encumbrance_flag                VARCHAR2(1);
         invoice_holds                   NUMBER;
         l_org_id                        NUMBER;
         l_curr_calling_sequence         VARCHAR2(2000);
         l_debug_info                    VARCHAR2(100);


         ---------------------------------------------------------------------
         -- Declare cursor to establish the invoice-level approval flag
         --
         -- The first select simply looks at the match status flag for the
         -- distributions.  The rest is to cover one specific case when some
         -- of the distributions are tested (T or A) and some are untested
         -- (NULL).  The status should be needs reapproval (N).
         --
         CURSOR approval_cursor IS
         SELECT match_status_flag
         FROM   ap_invoice_distributions_all
         WHERE  invoice_id = p_invoice_id
         UNION
         SELECT 'N'
         FROM   ap_invoice_distributions_all
         WHERE  invoice_id = p_invoice_id
         AND    match_status_flag IS NULL
         AND EXISTS
                (SELECT 'There are both untested and tested lines'
                 FROM   ap_invoice_distributions_all
                 WHERE  invoice_id = p_invoice_id
                 AND    match_status_flag IN ('T','A'))
	UNION  -- Bug 6866672
	SELECT 'N'
	FROM ap_invoice_lines_all ail, ap_invoices_all ai
	WHERE ai.invoice_id = p_invoice_id
	AND ai.invoice_id = ail.invoice_id
	AND ai.cancelled_date is NULL
	AND NOT EXISTS
		(SELECT 1
		 FROM ap_invoice_distributions_all
		 WHERE invoice_id = p_invoice_id
		 AND invoice_line_number = ail.line_number)
	AND ail.amount <> 0;	 -- Bug 6911199. Should ignore 0 Line Amounts.(Also one test case is an open issue)

     BEGIN

         l_curr_calling_sequence := 'AP_UTILITIES_PKG.'||'
                                    <-'||p_calling_sequence;

         l_debug_info := 'Getting org_id';
     ---------------------------------------------------------------------
         -- Get the org_id
         --
         SELECT org_id
         INTO l_org_id
         FROM ap_invoices_all
         WHERE invoice_id = p_invoice_id;

     ---------------------------------------------------------------------
         l_debug_info := 'Getting encumbrance flag';

         -- Get the encumbrance flag
         --
         -- Fix for 1407074. Substituting the org_id with -99 if it's null

           SELECT NVL(purch_encumbrance_flag,'N')
           INTO   encumbrance_flag
           FROM   financials_system_params_all
           WHERE  NVL(org_id, -99) = NVL(l_org_id, -99);

       ---------------------------------------------------------------------
         l_debug_info := 'Get hold count for invoice';

         -- Get the number of holds for the invoice
         --
         SELECT count(*)
         INTO   invoice_holds
         FROM   ap_holds_all
         WHERE  invoice_id = p_invoice_id
         AND    release_lookup_code is NULL;

       ---------------------------------------------------------------------
         -- bug7244642
         l_debug_info := 'get the force revalidation flag on the Invoice header';

         BEGIN

           SELECT nvl(ai.force_revalidation_flag, 'N')
             INTO l_force_revalidation_flag
             FROM ap_invoices_all ai
            WHERE ai.invoice_id = p_invoice_id;

         EXCEPTION
           WHEN OTHERS THEN
             null;

         END;

         -- Establish the invoice-level approval flag
         --
         -- Use the following ordering sequence to determine the
         -- invoice-level approval flag:
         --
         --                     'N' - Needs Reapproval
         --                     'T' - Tested
         --                     'A' - Approved
         --                     ''  - Never Approved
         --
         -- Initialize invoice-level approval flag
         --
         invoice_approval_flag := '';

         l_debug_info := 'Open approval_cursor';

         OPEN approval_cursor;

         LOOP
             l_debug_info := 'Fetching approval_cursor';
	     FETCH approval_cursor INTO distribution_approval_flag;
             EXIT WHEN approval_cursor%NOTFOUND;

             IF (distribution_approval_flag = 'N') THEN
                 invoice_approval_flag := 'N';
             ELSIF (distribution_approval_flag = 'T' AND
                    (invoice_approval_flag <> 'N'
		     or invoice_approval_flag is null)) THEN
                 invoice_approval_flag := 'T';
             ELSIF (distribution_approval_flag = 'A' AND
                    (invoice_approval_flag NOT IN ('N','T')
                     or invoice_approval_flag is null)) THEN
                 invoice_approval_flag := 'A';
             END IF;

         END LOOP;
         l_debug_info := 'Closing approval_cursor';
         CLOSE approval_cursor;

            IF (invoice_approval_flag = 'A') THEN
                invoice_approval_status := 'APPROVED';
            ELSIF (invoice_approval_flag is null) THEN
                invoice_approval_status := 'NEVER APPROVED';
            ELSIF (invoice_approval_flag = 'N') THEN
                invoice_approval_status := 'NEEDS REAPPROVAL';
            ELSIF (invoice_approval_flag = 'T') THEN
                 IF (encumbrance_flag = 'Y') THEN
                    invoice_approval_status := 'NEEDS REAPPROVAL';
                 ELSE
                    invoice_approval_status := 'APPROVED';
                 END IF;
            END IF;  -- invoice_approval_flag

         -- bug7244642
         IF ((invoice_approval_status = 'APPROVED') AND
             (l_force_revalidation_flag = 'Y')) THEN
              invoice_approval_status := 'NEEDS REAPPROVAL';
         END IF;

         IF (invoice_approval_status = 'APPROVED') THEN
            invoice_status := 'UNACCOUNTED';
         ELSE
            invoice_status := 'UNAPPROVED';
         END IF;

         RETURN(invoice_status);
EXCEPTION
   WHEN OTHERS THEN
      if (SQLCODE <> -20001) then
        FND_MESSAGE.SET_NAME('SQLAP', 'AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR', SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
                            'Invoice id = '||to_char(p_invoice_id)
			||', Org id = '||l_org_id
                        ||', Encumbrance flag = '||encumbrance_flag);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      end if;
      APP_EXCEPTION.RAISE_EXCEPTION;
END get_invoice_status;
---------------------------------------------------------------------

     -- Added by Bug:2022200
     -- Function net_invoice_amount returns the Net Invoice amount
     -- after subtracting the Prepayment amount applied and the
     -- Amount Withheld from the original Invoice amount.
     -- This function has been created because till release 11.0
     -- we used to reduce the Invoice amount by the prepaid amount
     -- and the amount withheld. This was discontinued in release 11.5.
     -- From release 11.5 Invoice amount is not changed. So to use
     -- any code from earlier releases where the reduced invoice amount
     -- is important, this function can be used.
     -- Modify this function to get the prepay_amount from the lines
     -- instead of distributions.  The prepay_invoice_id and prepay_line_number
     -- columns will be populated for exclusive tax lines created for
     -- prepayment application.  For the inclusive case the PREPAY line
     -- will include the tax amount applied.

     FUNCTION net_invoice_amount(p_invoice_id IN NUMBER)
         RETURN NUMBER
     IS
         l_prepay_amount          NUMBER := 0;
         l_net_inv_amount         NUMBER := 0;
     BEGIN
         SELECT nvl((0 - sum(AIL.amount)),0)
         INTO l_prepay_amount
         FROM ap_invoice_lines_all AIL
         WHERE AIL.invoice_id = p_invoice_id
         AND nvl(AIL.invoice_includes_prepay_flag,'N') = 'N'
         AND (AIL.line_type_lookup_code = 'PREPAY'
           OR (AIL.line_type_lookup_code = 'TAX'
             AND AIL.prepay_invoice_id IS NOT NULL
             AND AIL.prepay_line_number IS NOT NULL));

         SELECT nvl(AI.invoice_amount,0)- l_prepay_amount
                - nvl(AP_INVOICES_UTILITY_PKG.get_amount_withheld(p_invoice_id),0)
         INTO l_net_inv_amount
         FROM ap_invoices_all AI
         WHERE AI.invoice_id = p_invoice_id;


         RETURN(l_net_inv_amount);

     END net_invoice_amount;

-------------------------------------------------------------------------------
-- PROCEDURE Build_Offset_Account
-- Given the base account and the overlay account, this procedure builds the new
-- offSET account by overlaying them in the appropriate way determined by the
-- auto-offset system option.

-- Parameters
   ----------
--    Base_CCID -       the account on which the overlaying will be done. In the
--                      case of invoices, this is the liability account.
--    Overlay_CCID -    the account whose segments will be used to do the
--                      overlaying onto the base account. In the case of invoices,
--                      this is the expense account.
--    Accounting_Date - The date the flexbuilder will validate the ccid.
--    Result_CCID - OUT NOCOPY param fOR the resulting offSET account
--    Reason_Unbuilt_Flex - IN/OUT param. If (and only if) the account could
--                          not be built, it sends back the reason why
--                          flexbuilding failed. Otherwise, it goes back with
--                          the same value it came in with.
-------------------------------------------------------------------------------
PROCEDURE BUILD_OFFSET_ACCOUNT
                          (P_base_ccid             IN     NUMBER
                          ,P_overlay_ccid          IN     NUMBER
                          ,P_accounting_date       IN     DATE
                          ,P_result_ccid           OUT NOCOPY    NUMBER
                          ,P_Reason_Unbuilt_Flex   OUT NOCOPY    VARCHAR2
                          ,P_calling_sequence      IN     VARCHAR2
                          ) IS

  l_base_segments                FND_FLEX_EXT.SEGMENTARRAY ;
  l_overlay_segments             FND_FLEX_EXT.SEGMENTARRAY ;
  l_segments                     FND_FLEX_EXT.SEGMENTARRAY ;
  l_num_of_segments              NUMBER ;
  l_result                       BOOLEAN ;
  l_curr_calling_sequence        VARCHAR2(2000);
  G_flex_qualifier_name          VARCHAR2(100);
  l_primary_sob_id               AP_SYSTEM_PARAMETERS.set_of_books_id%TYPE;
  l_liability_post_lookup_code   AP_SYSTEM_PARAMETERS.liability_post_lookup_code%TYPE;
  l_chart_of_accts_id            GL_SETS_OF_BOOKS.chart_of_accounts_id%TYPE;
  G_flex_segment_num             NUMBER;


BEGIN

   SELECT set_of_books_id,
          nvl(liability_post_lookup_code, 'NONE')
   INTO   l_primary_sob_id,
          l_liability_post_lookup_code
   FROM   ap_system_parameters
   where org_id = nvl(AP_UTILITIES_PKG.g_org_id,org_id); /*Bug11720134*/

   SELECT chart_of_accounts_id
   INTO   l_chart_of_accts_id
   FROM   gl_sets_of_books
   WHERE  set_of_books_id = l_primary_sob_id;

    -- Get flexfield qualifier segment number
      IF (l_Liability_Post_Lookup_Code = 'ACCOUNT_SEGMENT_VALUE') THEN

        G_flex_qualifier_name := 'GL_ACCOUNT' ;

      ELSIF (l_Liability_Post_Lookup_Code = 'BALANCING_SEGMENT') THEN

        G_flex_qualifier_name := 'GL_BALANCING' ;

      END IF;

      l_result := FND_FLEX_KEY_API.GET_SEG_ORDER_BY_QUAL_NAME(
                                 101, 'GL#',
                                 l_chart_of_accts_id,
                                 G_flex_qualifier_name,
                                 G_flex_segment_num);


  l_curr_calling_sequence := 'AP_ACCOUNTING_MAIN_PKG.Build_Offset_Account<-'
                             || P_calling_sequence;

  -- Get the segments of the two given accounts
  IF (NOT FND_FLEX_EXT.GET_SEGMENTS('SQLGL', 'GL#',
                                    l_chart_of_accts_id,
                                    P_base_ccid, l_num_of_segments,
                                    l_base_segments)
     ) THEN

    -- Print reason why flex failed
    P_result_ccid := -1;
    P_reason_unbuilt_flex := 'INVALID ACCOUNT';
    RETURN ;

  END IF;


  IF (NOT FND_FLEX_EXT.GET_SEGMENTS('SQLGL', 'GL#',
                                    l_chart_of_accts_id,
                                    P_overlay_ccid, l_num_of_segments,
                                    l_overlay_segments)
     ) THEN
    -- Print reason why flex failed
    P_result_ccid := -1;
    P_reason_unbuilt_flex := 'INVALID ACCOUNT';
    RETURN ;

  END IF;

  /*
   Overlay segments depending on system option
    Case 1: Account Segment Overlay
    Base      A    A    [A]  A
    Overlay   B    B    [B]  B
    Result    B    B    [A]  B

    Case 2: Balancing Segment Overlay
    Base      [A]  A    A    A
    Overlay   [B]  B    B    B
    Result    [B]  A    A    A
  */

  FOR i IN 1.. l_num_of_segments LOOP


    IF (G_Flex_Qualifier_Name = 'GL_ACCOUNT') THEN

      -- Case 1: Account segment overlay
      IF (i = G_flex_segment_num) THEN
        l_segments(i) := l_base_segments(i);
      ELSE
        l_segments(i) := l_overlay_segments(i);
      END IF;

    ELSIF (G_Flex_Qualifier_Name = 'GL_BALANCING') THEN

      -- Case 2: Balancing segment overlay
      IF (i = G_flex_segment_num) THEN
        l_segments(i) := l_overlay_segments(i);
      ELSE
        l_segments(i) := l_base_segments(i);
      END IF;

    END IF;

  END LOOP;

  -- Get ccid fOR overlayed segments
  l_result := FND_FLEX_EXT.GET_COMBINATION_ID('SQLGL', 'GL#',
                                   l_chart_of_accts_id,
                                   P_accounting_date, l_num_of_segments,
                                   l_segments, P_result_ccid) ;

  IF (NOT l_result) THEN

    -- Store reason why flex failed
    P_result_ccid := -1;
    P_reason_unbuilt_flex := 'INVALID ACCOUNT';

  END IF;

EXCEPTION
  WHEN OTHERS THEN
    IF (SQLCODE <> -20001) THEN
      AP_Debug_Pkg.Print('Y','SQLAP','AP_DEBUG','ERROR',SQLERRM,
                     'CALLING_SEQUENCE', l_curr_calling_sequence,
                     FALSE);
    END IF;
    APP_EXCEPTION.RAISE_EXCEPTION;

END Build_Offset_Account;

-----------------------------------------------------------------------------------------------------
-- Function get_auto_offsets_segments returns either ACCOUNTING or BALANCING segment of the
-- input ccid.
--
--          For e.g. Accounting Flexfield Structure is
--                        Balancing Segment- Cost Center - Account
--                              100 - 213 - 3000
--
-- Case 1 : Auto-offsets to Balancing
--          Function returns "100"  i.e Balancing Segment
--
--
-- Case 2 : Auto-offsets to Accounting
--          Function returns "100213" i.e. Concatenated segments except Accounting Segment
--
--
----------------------------------------------------------------------------------------
FUNCTION get_auto_offsets_segments
                          (P_base_ccid  IN   NUMBER) return varchar2 is


  l_base_segments                FND_FLEX_EXT.SEGMENTARRAY ;
  l_overlay_segments             FND_FLEX_EXT.SEGMENTARRAY ;
  l_segments                     FND_FLEX_EXT.SEGMENTARRAY ;
  l_num_of_segments              NUMBER ;
  l_result                       BOOLEAN ;
  l_curr_calling_sequence        VARCHAR2(2000);
  G_flex_qualifier_name          VARCHAR2(100);
  l_primary_sob_id               AP_SYSTEM_PARAMETERS.set_of_books_id%TYPE;
  l_liability_post_lookup_code   AP_SYSTEM_PARAMETERS.liability_post_lookup_code%TYPE;
  l_chart_of_accts_id            GL_SETS_OF_BOOKS.chart_of_accounts_id%TYPE;
  G_flex_segment_num             NUMBER;
  l_return_segments              varchar2(200) := null;


  BEGIN

   ----------------------------------------------------------------------------------------
   -- Get Set of Books and Auto-offsets Option info

   SELECT set_of_books_id,
          nvl(liability_post_lookup_code, 'NONE')
   INTO   l_primary_sob_id,
          l_liability_post_lookup_code
   FROM   ap_system_parameters;

   -----------------------------------------------------------------------------------------
   -- Get Chart of Accounts Information

   SELECT chart_of_accounts_id
   INTO   l_chart_of_accts_id
   FROM   gl_sets_of_books
   WHERE  set_of_books_id = l_primary_sob_id;

    -----------------------------------------------------------------------------------------
    -- Get flexfield qualifier segment number

      IF (l_Liability_Post_Lookup_Code = 'ACCOUNT_SEGMENT_VALUE') THEN

        G_flex_qualifier_name := 'GL_ACCOUNT' ;

      ELSIF (l_Liability_Post_Lookup_Code = 'BALANCING_SEGMENT') THEN

        G_flex_qualifier_name := 'GL_BALANCING' ;

      ELSIF (l_liability_post_lookup_code = 'NONE') then

           return null;

      END IF;

      l_result := FND_FLEX_KEY_API.GET_SEG_ORDER_BY_QUAL_NAME(
                                 101, 'GL#',
                                 l_chart_of_accts_id,
                                 G_flex_qualifier_name,
                                 G_flex_segment_num);

   -----------------------------------------------------------------------------------------
   -- Get the segments of the given account

     IF (NOT FND_FLEX_EXT.GET_SEGMENTS('SQLGL', 'GL#',
                                    l_chart_of_accts_id,
                                    P_base_ccid, l_num_of_segments,
                                    l_base_segments)
     ) THEN

    -- Print reason why flex failed
    --P_result_ccid := -1;
    --P_reason_unbuilt_flex := 'INVALID ACCOUNT';
    RETURN -1 ;

  END IF;

  ---------------------------------------------------------------------------------------
  -- Get the Balancing Segment or Accounting Segment based on the auto-offset option


  FOR i IN 1.. l_num_of_segments LOOP

     IF (G_Flex_Qualifier_Name = 'GL_BALANCING') THEN

      IF (i = G_flex_segment_num) THEN
         l_segments(i) := l_base_segments(i);
         l_return_segments := l_segments(i);
      END IF;

     ELSIF (G_Flex_Qualifier_Name = 'GL_ACCOUNT') THEN

       IF (i = G_flex_segment_num) THEN
          l_segments(i) := l_base_segments(i);
       ELSE
          l_segments(i) := l_base_segments(i);
          l_return_segments :=  l_return_segments || l_segments(i) ;
       END IF;

     END IF;

  END LOOP;

  return l_return_segments;

 EXCEPTION
  WHEN OTHERS THEN
    IF (SQLCODE <> -20001) THEN
      AP_Debug_Pkg.Print('Y','SQLAP','AP_DEBUG','ERROR',SQLERRM,
                     'CALLING_SEQUENCE', l_curr_calling_sequence,
                     FALSE);
    END IF;
   -- return l_number;
    APP_EXCEPTION.RAISE_EXCEPTION;


END get_auto_offsets_segments;

-----------------------------------------------------------------------------------------------------
-- This function is a modified version of the original one above.
-- We modified it to accept more parameters  but do less work.
-- Created for bug 2475913.
----------------------------------------------------------------------------------------
FUNCTION get_auto_offsets_segments
           (P_base_ccid IN NUMBER,
	    P_flex_qualifier_name   IN       VARCHAR2,
	    P_flex_segment_num   IN     NUMBER,
	    P_chart_of_accts_id  IN GL_SETS_OF_BOOKS.chart_of_accounts_id%TYPE
	) return varchar2 is


  l_base_segments                FND_FLEX_EXT.SEGMENTARRAY ;
  l_overlay_segments             FND_FLEX_EXT.SEGMENTARRAY ;
  l_segments                     FND_FLEX_EXT.SEGMENTARRAY ;
  l_result                       BOOLEAN ;
  l_curr_calling_sequence        VARCHAR2(2000);
  l_return_segments              varchar2(200) := null;
  l_num_of_segments		 NUMBER;


  BEGIN

   -----------------------------------------------------------------------------------------
   -- Get the segments of the given account

     IF (NOT FND_FLEX_EXT.GET_SEGMENTS('SQLGL', 'GL#',
                                    P_chart_of_accts_id,
                                    P_base_ccid, l_num_of_segments,
                                    l_base_segments)
     ) THEN

    -- Print reason why flex failed
    --P_result_ccid := -1;
    --P_reason_unbuilt_flex := 'INVALID ACCOUNT';
    RETURN -1 ;

  END IF;

  ---------------------------------------------------------------------------------------
  -- Get the Balancing Segment or Accounting Segment based on the auto-offset option


  FOR i IN 1.. l_num_of_segments LOOP

     IF (P_Flex_Qualifier_Name = 'GL_BALANCING') THEN

      IF (i = P_flex_segment_num) THEN
         l_segments(i) := l_base_segments(i);
         l_return_segments := l_segments(i);
      END IF;

     ELSIF (P_Flex_Qualifier_Name = 'GL_ACCOUNT') THEN

       IF (i = P_flex_segment_num) THEN
          l_segments(i) := l_base_segments(i);
       ELSE
          l_segments(i) := l_base_segments(i);
          l_return_segments :=  l_return_segments || l_segments(i) ;
       END IF;

     END IF;

  END LOOP;

  return l_return_segments;

 EXCEPTION
  WHEN OTHERS THEN
    IF (SQLCODE <> -20001) THEN
      AP_Debug_Pkg.Print('Y','SQLAP','AP_DEBUG','ERROR',SQLERRM,
                     'CALLING_SEQUENCE', l_curr_calling_sequence,
                     FALSE);
    END IF;

   -- return l_number;
    APP_EXCEPTION.RAISE_EXCEPTION;


END get_auto_offsets_segments;

FUNCTION delete_invoice_from_interface(p_invoice_id_table in number_table_type,
                                       p_invoice_line_id_table in number_table_type,
                                       p_calling_sequence VARCHAR2) return boolean as

  current_calling_sequence        VARCHAR2(2000);
  debug_info                      VARCHAR2(500);

 BEGIN
  current_calling_sequence :=
       'AP_UTILITIES_PKG.delete_invoice_from_interface<-'||P_calling_sequence;
  debug_info := 'Delete records from rejection and interface tables';

  /* Delete invoices from interface */
  forall i in nvl(p_invoice_id_table.first,0)..nvl(p_invoice_id_table.last,0)
    delete from ap_invoices_interface where invoice_id = p_invoice_id_table(i);
  /* Delete invoice lines from interface */
  forall i in nvl(p_invoice_id_table.first,0)..nvl(p_invoice_id_table.last,0)
    delete from ap_invoice_lines_interface where invoice_id = p_invoice_id_table(i);

  /* Delete invoice rejections from the rejections table */
  forall i in nvl(p_invoice_id_table.first,0)..nvl(p_invoice_id_table.last,0)
    delete from ap_interface_rejections
           where parent_id = p_invoice_id_table(i) and
                 parent_table = 'AP_INVOICES_INTERFACE';

  /* Delete invoice lines rejections from the rejections table */
  forall i in nvl(p_invoice_line_id_table.first,0)..nvl(p_invoice_line_id_table.last,0)
    delete from ap_interface_rejections
           where parent_id = p_invoice_line_id_table(i) and
                 parent_table = 'AP_INVOICE_LINES_INTERFACE';
  return TRUE;
 EXCEPTION
   WHEN OTHERS THEN
      if (SQLCODE <> -20001) then
        FND_MESSAGE.SET_NAME('SQLAP', 'AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR', SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', current_calling_sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO', debug_info);
      end if;
      RETURN(FALSE);
 END delete_invoice_from_interface ;

  -- Added following function for Exchange Rate Calculation Project.
  FUNCTION calculate_user_xrate(P_invoice_curr         IN VARCHAR2,
                                P_base_curr            IN VARCHAR2,
                                P_exchange_date        IN DATE,
                                P_exchange_rate_type   IN VARCHAR2)
  RETURN VARCHAR2
  IS
    l_calc_user_xrate         VARCHAR2(1);

  BEGIN

    SELECT nvl(calc_user_xrate, 'N')
      INTO l_calc_user_xrate
      FROM ap_system_parameters;

    IF (P_exchange_rate_type = 'User') THEN
      IF (gl_euro_user_rate_api.is_cross_rate(P_invoice_curr,
                                             P_base_curr,
                                             P_exchange_date,
                                             P_exchange_rate_type) = 'N') THEN
        RETURN l_calc_user_xrate;
      END IF;
    END IF;

    RETURN 'N';

  END calculate_user_xrate;

-- Added the following function to get the GL Batch Name
-- Function Called by Posted Payment Register and Posted Invoice Register.
-- Inputs : Batch Id , GL and Subledger Link Id
-- Output : GL batch Name for that Batch Id.
FUNCTION get_gl_batch_name(P_batch_id IN NUMBER, P_GL_SL_link_id IN NUMBER, P_ledger_id IN NUMBER)
RETURN varchar2 AS
ret_val varchar2(100);
BEGIN
      IF P_batch_id = -999 and P_gl_sl_link_id is not NULL THEN
        BEGIN
        /* Definitely a Batch Name is avaialble with the LINK */
             SELECT jb.name INTO ret_val
             FROM gl_je_batches jb
             WHERE JB.je_batch_id IN (SELECT IR.je_batch_id
                                    FROM   gl_import_references IR
                                    WHERE  IR.gl_sl_link_id = P_GL_SL_link_id
                                    AND    IR.gl_sl_link_table = 'APECL');
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           /* Link is available and No Batch Name then We don't
              want such rows */
            SELECT '-999' into ret_val
            FROM DUAL
            WHERE NOT EXISTS (SELECT 'this link id exists in IR'
                              FROM gl_import_references IR
                              WHERE IR.gl_sl_link_id=P_gl_sl_link_id
                              AND IR.gl_sl_link_table = 'APECL');
         END;
       RETURN ret_val;
      ELSIF P_batch_id = -999 and P_gl_sl_link_id is NULL THEN
        /* No Link NO Batch, we would print such rows */
            return '-999';
      ELSE
        /* The Batch Name is Provided */
           SELECT jb.name INTO ret_val
           FROM gl_je_batches jb
           WHERE JB.je_batch_id = P_batch_id
           and P_GL_SL_link_id IN
                             (SELECT IR.gl_sl_link_id
                              FROM   gl_import_references IR, gl_je_headers JEH
                              WHERE  IR.je_header_id = JEH.je_header_id
                              AND    JEH.ledger_id = P_Ledger_id
                              AND    JEH.je_batch_id = P_batch_id
                              AND    IR.gl_sl_link_table = 'APECL');
               RETURN ret_val;
     END IF;
EXCEPTION
WHEN OTHERS THEN
     return NULL;
END get_gl_batch_name;

-- Bug 2249806
-- Code modified by MSWAMINA
-- Added a new stored function for the performance reasons
-- This will get the Lookup code and the lookup type
-- as the input arguments and will return the corresponding
-- Meaning as output.
-- This function is created inorder to avoid the reparsing
-- of these simple/common SQLs in our reports.

FUNCTION FND_Get_Displayed_Field
                             (LookupType    IN VARCHAR2
                             ,LookupCode    IN VARCHAR2
                             ) RETURN VARCHAR2 IS

  CURSOR c_lookup is
  SELECT meaning
  FROM   fnd_lookups
  WHERE  (lookup_code = LookupCode)
  AND    (lookup_type = LookupType);
  output_string  fnd_lookups.meaning%TYPE;
                                                                         --
BEGIN
                                                                         --
  open  c_lookup;
  fetch c_lookup into output_string;
                                                                         --
  IF c_lookup%NOTFOUND THEN
    raise NO_DATA_FOUND;
  END IF;
                                                                         --
  close c_lookup;
  return(output_string);

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    return NULL;

END FND_Get_Displayed_Field;

-- Bug 2693900.  Forward porting Bug 2610252.
--Bug2610252 The function get_reversal_gl_date is added to get
--gl date for reversed distribution. If the date passed is not
--in an open period then first day of the next open period will
--be returned otherwise an error message will be displayed.
-----------------------------------------------------------------------
--function get_reversal_gl_date takes argument P_Date and
--returns gl date
-----------------------------------------------------------------------
-- Bug 5584997.  Added the P_org_id
Function get_reversal_gl_date(P_date in date,
                              P_Org_Id In Number) return date
is
    l_open_gl_date      date :='';
    l_period_name gl_period_statuses.period_name%TYPE := '';
begin
    l_period_name := ap_utilities_pkg.get_current_gl_date(p_date, P_org_id);
    if l_period_name is null then
       ap_utilities_pkg.get_open_gl_date(p_date,
                                         l_period_name,
                                         l_open_gl_date,
                                         P_org_id);
        if l_period_name is null then
           RAISE NO_DATA_FOUND;
        end if;
     else
        l_open_gl_date := p_date;
     end if;
     return l_open_gl_date;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
       FND_MESSAGE.SET_NAME('SQLAP', 'AP_CANCEL_NO_OPEN_FUT_PERIOD');
       FND_MESSAGE.SET_TOKEN('DATE', to_char(p_date, 'dd-mon-yyyy'));
       APP_EXCEPTION.RAISE_EXCEPTION;
End get_reversal_gl_date;

--Bug2610252 The function get_reversal_period is added to get
--period for reversed distribution. If the date passed is not
--in an open period then period name of the next open period will
--be returned otherwise an error message will be displayed.
-----------------------------------------------------------------------
--function get_reversal_period takes argument P_Date and
--returns period name
-----------------------------------------------------------------------
-- Bug 5584997.  Added the P_org_id
Function get_reversal_period(P_date in date,
                             P_org_id In Number) return varchar2
is
    l_open_gl_date      date :='';
    l_period_name gl_period_statuses.period_name%TYPE := '';
begin
    l_period_name := ap_utilities_pkg.get_current_gl_date(p_date, p_org_id);
    if l_period_name is null then
       ap_utilities_pkg.get_open_gl_date(p_date,
                                         l_period_name,
                                         l_open_gl_date,
                                         p_org_id);
        if l_period_name is null then
           RAISE NO_DATA_FOUND;
        end if;
     else
        l_open_gl_date := p_date;
     end if;
     return l_period_name;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
       FND_MESSAGE.SET_NAME('SQLAP', 'AP_CANCEL_NO_OPEN_FUT_PERIOD');
       FND_MESSAGE.SET_TOKEN('DATE', to_char(p_date, 'dd-mon-yyyy'));
       APP_EXCEPTION.RAISE_EXCEPTION;
End get_reversal_period;

/* =======================================================================*/
/* New Function pa_flexbuild was created for in the scope of the Invoice  */
/* Lines Project - Stage 1                                                */
/* =======================================================================*/

FUNCTION pa_flexbuild(
   p_vendor_id                 IN            NUMBER,
   p_employee_id               IN            NUMBER,
   p_set_of_books_id           IN            NUMBER,
   p_chart_of_accounts_id      IN            NUMBER,
   p_base_currency_code        IN            VARCHAR2,
   p_Accounting_date           IN                DATE,
   p_award_id                  IN            NUMBER,
   P_project_id                IN AP_INVOICE_DISTRIBUTIONS.PROJECT_ID%TYPE,
   p_task_id                   IN AP_INVOICE_DISTRIBUTIONS.TASK_ID%TYPE,
   p_expenditure_type          IN
             AP_INVOICE_DISTRIBUTIONS.EXPENDITURE_TYPE%TYPE,
   p_expenditure_org_id        IN
             AP_INVOICE_DISTRIBUTIONS.EXPENDITURE_ORGANIZATION_ID%TYPE,
   p_expenditure_item_date     IN
             AP_INVOICE_DISTRIBUTIONS.EXPENDITURE_ITEM_DATE%TYPE,
   p_invoice_attribute_rec      IN  AP_UTILITIES_PKG.r_invoice_attribute_rec, --bug 8713737
   p_billable_flag              IN            VARCHAR2, --Bug6523162
   p_employee_ccid              IN            NUMBER,   --Bug5003249
   p_web_parameter_id           IN            NUMBER,   --Bug5003249
   p_invoice_type_lookup_code   IN            VARCHAR2, --Bug5003249
   p_default_last_updated_by   IN            NUMBER,
   p_default_last_update_login IN            NUMBER,
   p_pa_default_dist_ccid         OUT NOCOPY NUMBER,
   p_pa_concatenated_segments	  OUT NOCOPY VARCHAR2,
   p_debug_Info                   OUT  NOCOPY VARCHAR2,
   p_debug_Context                OUT  NOCOPY VARCHAR2,
   p_calling_sequence          IN            VARCHAR2,
   p_default_dist_ccid         IN  AP_INVOICE_LINES.DEFAULT_DIST_CCID%TYPE --bug 5386396
   ) RETURN BOOLEAN
IS
   procedure_billable_flag       	VARCHAR2(60) := '';
   l_concat_ids  		        VARCHAR2(2000); --bug9064023
   l_errmsg      	         	VARCHAR2(2000); --bug9064023
   l_concat_descrs 		        VARCHAR2(2000); --bug9064023
   l_concat_segs 		        VARCHAR2(2000);
   current_calling_sequence  	        VARCHAR2(2000);
   debug_info   		        VARCHAR2(2000); --bug9064023
   l_app_short_name                     VARCHAR2(10);   --bug 8980626
   l_message_name                       VARCHAR2(200);  --bug 8980626

   l_pa_installed          VARCHAR2(10);
   l_status                VARCHAR2(10);
   l_industry              VARCHAR2(10);
   l_attribute_category    AP_INVOICES_ALL.attribute_category%TYPE;
   l_attribute1            AP_INVOICES_ALL.attribute1%TYPE;
   l_attribute2            AP_INVOICES_ALL.attribute2%TYPE;
   l_attribute3            AP_INVOICES_ALL.attribute3%TYPE;
   l_attribute4            AP_INVOICES_ALL.attribute4%TYPE;
   l_attribute5            AP_INVOICES_ALL.attribute5%TYPE;
   l_attribute6            AP_INVOICES_ALL.attribute6%TYPE;
   l_attribute7            AP_INVOICES_ALL.attribute7%TYPE;
   l_attribute8            AP_INVOICES_ALL.attribute8%TYPE;
   l_attribute9            AP_INVOICES_ALL.attribute9%TYPE;
   l_attribute10           AP_INVOICES_ALL.attribute10%TYPE;
   l_attribute11           AP_INVOICES_ALL.attribute11%TYPE;
   l_attribute12           AP_INVOICES_ALL.attribute12%TYPE;
   l_attribute13           AP_INVOICES_ALL.attribute13%TYPE;
   l_attribute14           AP_INVOICES_ALL.attribute14%TYPE;
   l_attribute15           AP_INVOICES_ALL.attribute15%TYPE;
   li_attribute_category   AP_INVOICES_ALL.attribute_category%TYPE;
   li_attribute1           AP_INVOICE_LINES_ALL.attribute1%TYPE;
   li_attribute2           AP_INVOICE_LINES_ALL.attribute2%TYPE;
   li_attribute3           AP_INVOICE_LINES_ALL.attribute3%TYPE;
   li_attribute4           AP_INVOICE_LINES_ALL.attribute4%TYPE;
   li_attribute5           AP_INVOICE_LINES_ALL.attribute5%TYPE;
   li_attribute6           AP_INVOICE_LINES_ALL.attribute6%TYPE;
   li_attribute7           AP_INVOICE_LINES_ALL.attribute7%TYPE;
   li_attribute8           AP_INVOICE_LINES_ALL.attribute8%TYPE;
   li_attribute9           AP_INVOICE_LINES_ALL.attribute9%TYPE;
   li_attribute10          AP_INVOICE_LINES_ALL.attribute10%TYPE;
   li_attribute11          AP_INVOICE_LINES_ALL.attribute11%TYPE;
   li_attribute12          AP_INVOICE_LINES_ALL.attribute12%TYPE;
   li_attribute13          AP_INVOICE_LINES_ALL.attribute13%TYPE;
   li_attribute14          AP_INVOICE_LINES_ALL.attribute14%TYPE;
   li_attribute15          AP_INVOICE_LINES_ALL.attribute15%TYPE;

BEGIN

  -- Update the calling sequence
  --
  current_calling_sequence :=
    'AP_IMPORT_UTILITIES_PKG.pa_flexbuild<-'||P_calling_sequence;

    --------------------------------------------------------------------------
    -- Step 1 - Flexbuild
    --------------------------------------------------------------------------

    -- Flexbuild using Workflow.

    debug_info := '(PA Flexbuild 1) Call pa_acc_gen_wf_pkg.'||
                  'ap_inv_generate_account for flexbuilding';
--Bug5003249 Start
     If (p_invoice_type_lookup_code = 'EXPENSE REPORT') then
      IF ( NOT pa_acc_gen_wf_pkg.ap_er_generate_account (
        p_project_id  => p_project_id,
          p_task_id     => p_task_id,
          p_expenditure_type  => p_expenditure_type,
          p_vendor_id         => P_VENDOR_ID,
          p_expenditure_organization_id  => P_EXPENDITURE_ORG_ID,
          p_expenditure_item_date  => P_EXPENDITURE_ITEM_DATE,
          p_billable_flag        => p_billable_flag,  --Bug6523162
          p_chart_of_accounts_id => P_CHART_OF_ACCOUNTS_ID,
          p_calling_module      => 'APXINWKB',
          p_employee_id         => P_employee_id,
          p_employee_ccid               => p_employee_ccid,
          p_expense_type                => p_web_parameter_id,
        p_expense_cc            => null,
        /* bug 8713737 Passing p_invoice_attribute_rec */
        P_ATTRIBUTE_CATEGORY => p_invoice_attribute_rec.attribute_category,
        P_ATTRIBUTE1  => p_invoice_attribute_rec.attribute1,
        P_ATTRIBUTE2  => p_invoice_attribute_rec.attribute2,
        P_ATTRIBUTE3  => p_invoice_attribute_rec.attribute3,
        P_ATTRIBUTE4  => p_invoice_attribute_rec.attribute4,
        P_ATTRIBUTE5  => p_invoice_attribute_rec.attribute5,
        P_ATTRIBUTE6  => p_invoice_attribute_rec.attribute6,
        P_ATTRIBUTE7  => p_invoice_attribute_rec.attribute7,
        P_ATTRIBUTE8  => p_invoice_attribute_rec.attribute8,
        P_ATTRIBUTE9  => p_invoice_attribute_rec.attribute9,
        P_ATTRIBUTE10 => p_invoice_attribute_rec.attribute10,
        P_ATTRIBUTE11 => p_invoice_attribute_rec.attribute11,
        P_ATTRIBUTE12 => p_invoice_attribute_rec.attribute12,
        P_ATTRIBUTE13 => p_invoice_attribute_rec.attribute13,
        P_ATTRIBUTE14 => p_invoice_attribute_rec.attribute14,
        P_ATTRIBUTE15 => p_invoice_attribute_rec.attribute15,
        P_LINE_ATTRIBUTE_CATEGORY => p_invoice_attribute_rec.line_attribute_CATEGORY,
        P_LINE_ATTRIBUTE1 => p_invoice_attribute_rec.line_attribute1,
        P_LINE_ATTRIBUTE2 => p_invoice_attribute_rec.line_attribute2,
        P_LINE_ATTRIBUTE3 => p_invoice_attribute_rec.line_attribute3,
        P_LINE_ATTRIBUTE4 => p_invoice_attribute_rec.line_attribute4,
        P_LINE_ATTRIBUTE5 => p_invoice_attribute_rec.line_attribute5,
        P_LINE_ATTRIBUTE6 => p_invoice_attribute_rec.line_attribute6,
        P_LINE_ATTRIBUTE7 => p_invoice_attribute_rec.line_attribute7,
        P_LINE_ATTRIBUTE8 => p_invoice_attribute_rec.line_attribute8,
        P_LINE_ATTRIBUTE9 => p_invoice_attribute_rec.line_attribute9,
        P_LINE_ATTRIBUTE10 => p_invoice_attribute_rec.line_attribute10,
        P_LINE_ATTRIBUTE11 => p_invoice_attribute_rec.line_attribute11,
        P_LINE_ATTRIBUTE12 => p_invoice_attribute_rec.line_attribute12,
        P_LINE_ATTRIBUTE13 => p_invoice_attribute_rec.line_attribute13,
        P_LINE_ATTRIBUTE14 => p_invoice_attribute_rec.line_attribute14,
        P_LINE_ATTRIBUTE15 => p_invoice_attribute_rec.line_attribute15,
        x_return_ccid => P_PA_DEFAULT_DIST_CCID,
        x_concat_segs => l_concat_segs,
        x_concat_ids  => l_concat_ids,
        x_concat_descrs => l_concat_descrs,
        x_error_message => l_errmsg,
        P_award_id => P_AWARD_ID,  --Bug5198018
        p_input_ccid => p_default_dist_ccid --bug 5386396
        ))THEN
         --
          -- Show error message
          --
      /*debug_info :=
        '(PA Flexbuild 1 ) pa_acc_gen_wf_pkg.ap_er_generate_account Failed ';
          p_debug_info := debug_info || ': Error encountered';*/

          --start bug 8980626
          p_debug_info := l_errmsg;			--bug 8320268    /*Bug 16842904*/
	  /*Commented below code for Bug 16842904*/
          /*fnd_message.parse_encoded(l_errmsg, l_app_short_name, l_message_name);
          fnd_message.set_name(l_app_short_name, l_message_name);
          p_debug_info := fnd_message.get;*/
          --end bug 8980626

          p_debug_Context := current_calling_sequence;
          RETURN(FALSE);

       END IF;
  else

    debug_info :=  ' Call pa_acc_gen_wf_pkg.ap_inv_generate_account with billable flag '||p_billable_flag; --Bug6523162

    IF ( NOT pa_acc_gen_wf_pkg.ap_inv_generate_account (
        p_project_id                      => p_project_id,
        p_task_id                         => p_task_id,
        P_AWARD_ID	                  => p_award_id,  --Bug5198018
        p_expenditure_type                => p_expenditure_type,
        p_vendor_id                       => p_vendor_id,
        p_expenditure_organization_id     => p_expenditure_org_id,
        p_expenditure_item_date           => p_expenditure_item_date,
        p_billable_flag                   => p_billable_flag,   --Bug6523162
        p_chart_of_accounts_id            => P_chart_of_accounts_id,
        p_accounting_date                 => P_accounting_date,
        /* bug 8713737 Passing p_invoice_attribute_rec */
        P_ATTRIBUTE_CATEGORY              => p_invoice_attribute_rec.attribute_category,
        P_ATTRIBUTE1 	    	          => p_invoice_attribute_rec.attribute1,
        P_ATTRIBUTE2 		          => p_invoice_attribute_rec.attribute2,
        P_ATTRIBUTE3 		          => p_invoice_attribute_rec.attribute3,
        P_ATTRIBUTE4 		          => p_invoice_attribute_rec.attribute4,
        P_ATTRIBUTE5 		          => p_invoice_attribute_rec.attribute5,
        P_ATTRIBUTE6 		          => p_invoice_attribute_rec.attribute6,
        P_ATTRIBUTE7 		          => p_invoice_attribute_rec.attribute7,
        P_ATTRIBUTE8 		          => p_invoice_attribute_rec.attribute8,
        P_ATTRIBUTE9 		          => p_invoice_attribute_rec.attribute9,
        P_ATTRIBUTE10 		          => p_invoice_attribute_rec.attribute10,
        P_ATTRIBUTE11 		          => p_invoice_attribute_rec.attribute11,
        P_ATTRIBUTE12 		          => p_invoice_attribute_rec.attribute12,
        P_ATTRIBUTE13 		          => p_invoice_attribute_rec.attribute13,
        P_ATTRIBUTE14 		          => p_invoice_attribute_rec.attribute14,
        P_ATTRIBUTE15 		          => p_invoice_attribute_rec.attribute15,
        P_DIST_ATTRIBUTE_CATEGORY         => p_invoice_attribute_rec.line_attribute_category,
        P_DIST_ATTRIBUTE1 	          => p_invoice_attribute_rec.line_attribute1,
        P_DIST_ATTRIBUTE2 	          => p_invoice_attribute_rec.line_attribute2,
        P_DIST_ATTRIBUTE3 	          => p_invoice_attribute_rec.line_attribute3,
        P_DIST_ATTRIBUTE4 	          => p_invoice_attribute_rec.line_attribute4,
        P_DIST_ATTRIBUTE5 	          => p_invoice_attribute_rec.line_attribute5,
        P_DIST_ATTRIBUTE6 	          => p_invoice_attribute_rec.line_attribute6,
        P_DIST_ATTRIBUTE7 	          => p_invoice_attribute_rec.line_attribute7,
        P_DIST_ATTRIBUTE8	          => p_invoice_attribute_rec.line_attribute8,
        P_DIST_ATTRIBUTE9	          => p_invoice_attribute_rec.line_attribute9,
        P_DIST_ATTRIBUTE10	          => p_invoice_attribute_rec.line_attribute10,
        P_DIST_ATTRIBUTE11	          => p_invoice_attribute_rec.line_attribute11,
        P_DIST_ATTRIBUTE12	          => p_invoice_attribute_rec.line_attribute12,
        P_DIST_ATTRIBUTE13	          => p_invoice_attribute_rec.line_attribute13,
        P_DIST_ATTRIBUTE14	          => p_invoice_attribute_rec.line_attribute14,
        P_DIST_ATTRIBUTE15	          => p_invoice_attribute_rec.line_attribute15,
        x_return_ccid                     => P_PA_DEFAULT_DIST_CCID, -- OUT
        x_concat_segs                     => l_concat_segs,   -- OUT NOCOPY
        x_concat_ids                      => l_concat_ids,    -- OUT NOCOPY
        x_concat_descrs                   => l_concat_descrs, -- OUT NOCOPY
        x_error_message                   => l_errmsg,        -- OUT NOCOPY
        p_input_ccid =>      p_default_dist_ccid)) THEN  /* IN for bug#9010924 */

      -- Show error message
     /* debug_info :=
        '(PA Flexbuild 1 ) pa_acc_gen_wf_pkg.ap_inv_generate_account Failed ';
          p_debug_info := debug_info || ': Error encountered';*/

          --start bug 8980626
          p_debug_info := l_errmsg;			--bug 8320268       /*Bug 16842904*/
          /*Commented below code for Bug 16842904*/
	  /*fnd_message.parse_encoded(l_errmsg, l_app_short_name, l_message_name);
          fnd_message.set_name(l_app_short_name, l_message_name);
          p_debug_info := fnd_message.get;*/
          --end bug 8980626

          p_debug_Context := current_calling_sequence;
          RETURN(FALSE);
      END IF;
     End if;

      -------------------------------------------------------------------------
      -- Step 2 - Return Concatenated Segments
      --------------------------------------------------------------------------
      debug_info := '(PA Flexbuild 2) Return Concatenated Segments';
      P_PA_CONCATENATED_SEGMENTS := l_concat_segs;
      debug_info :=
 	    'p_pa_default_dist_ccid = '||to_char(p_pa_default_dist_ccid)
           ||' p_pa_concatenated_segments = '||p_pa_concatenated_segments
           ||' l_concat_segs = '             ||l_concat_segs
           ||' l_concat_ids = '              ||l_concat_ids
           ||' p_billable_flag = '   ||p_billable_flag --Bug6523162
           ||' l_concat_descrs = '           ||l_concat_descrs
           ||' l_errmsg = '                  ||l_errmsg;

  RETURN(TRUE);

EXCEPTION
  WHEN OTHERS THEN
     p_debug_info := debug_info || ': Error encountered in Flexbuild';
     p_debug_Context := current_calling_sequence;

    IF (SQLCODE < 0) then
      IF (AP_IMPORT_INVOICES_PKG.g_debug_switch = 'Y') THEN
        AP_IMPORT_UTILITIES_PKG.print(
          AP_IMPORT_INVOICES_PKG.g_debug_switch, SQLERRM);
      END IF;
    END IF;

    RETURN (FALSE);
END pa_flexbuild;

PROCEDURE Get_Invoice_LE (
     p_vendor_site_id                IN            NUMBER,
     p_inv_liab_ccid                 IN            NUMBER,
     p_org_id                        IN            NUMBER,
     p_le_id                         OUT NOCOPY NUMBER) IS

l_ptop_le_info                  XLE_BUSINESSINFO_GRP.ptop_le_rec;
l_le_return_status              varchar2(1);
l_msg_data                      varchar2(1000);

l_bill_to_location_id           NUMBER(15);
l_supp_site_liab_ccid           NUMBER(15);
l_ccid_to_api                   NUMBER(15);
l_valid_le                      VARCHAR2(100);

BEGIN
  -- Get Bill TO Location and Liab Acct from Supplier Site
  BEGIN
    SELECT bill_to_location_id,
           accts_pay_code_combination_id
    INTO   l_bill_to_location_id,
           l_supp_site_liab_ccid
    FROM   po_vendor_sites
    WHERE  vendor_site_id = p_vendor_site_id;

    l_ccid_to_api := NVL(p_inv_liab_ccid,
                         l_supp_site_liab_ccid);
  EXCEPTION
     WHEN OTHERS THEN
       l_bill_to_location_id := NULL;
       l_ccid_to_api := p_inv_liab_ccid;
  END;
  --
  -- Call LE API
  XLE_BUSINESSINFO_GRP.Get_PurchasetoPay_Info
                         (l_le_return_status,
                          l_msg_data,
                          null,
                          null,
                          l_bill_to_location_id,
                          l_ccid_to_api,
                          p_org_id,
                          l_ptop_le_info);

  IF (l_le_return_status = FND_API.G_RET_STS_SUCCESS) THEN
      p_le_id := l_ptop_le_info.legal_entity_id;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    APP_EXCEPTION.RAISE_EXCEPTION;
END Get_Invoice_LE;

FUNCTION Get_Check_LE (
     p_bank_acct_use_id              IN            NUMBER)
RETURN NUMBER IS
l_legal_entity_id NUMBER;
BEGIN

SELECT account_owner_org_id
INTO   l_legal_entity_id
FROM   ce_bank_accounts cba,
       ce_bank_acct_uses_all cbau
WHERE  cbau.bank_account_id = cba.bank_account_id
AND    cbau.bank_acct_use_id = p_bank_acct_use_id;

RETURN (l_legal_entity_id);

EXCEPTION
   WHEN OTHERS THEN
      APP_EXCEPTION.RAISE_EXCEPTION;
END Get_Check_LE;

/*==========================================================
 | PROCEDURE - getInvoiceLEInfo
 |             This is a wrapper for get_invoice_le()
 |             with more detailed L.E. info returned
 *=========================================================*/
PROCEDURE getInvoiceLEInfo (
     p_vendor_site_id                IN            NUMBER,
     p_inv_liab_ccid                 IN            NUMBER,
     p_org_id                        IN            NUMBER,
     p_le_id                         OUT NOCOPY    NUMBER,
     p_le_name                       OUT NOCOPY    VARCHAR2,
     p_le_registration_num           OUT NOCOPY    VARCHAR2,
     p_le_address1                   OUT NOCOPY    VARCHAR2,
     p_le_city                       OUT NOCOPY    VARCHAR2,
     p_le_postal_code                OUT NOCOPY    VARCHAR2,
     p_le_country                    OUT NOCOPY    VARCHAR2) IS

l_ptop_le_info                  XLE_BUSINESSINFO_GRP.ptop_le_rec;
l_le_return_status              varchar2(1);
l_msg_data                      varchar2(1000);

l_bill_to_location_id           NUMBER(15);
l_supp_site_liab_ccid           NUMBER(15);
l_ccid_to_api                   NUMBER(15);
l_valid_le                      VARCHAR2(100);

BEGIN
  -- Get Bill TO Location and Liab Acct from Supplier Site
  BEGIN
    SELECT bill_to_location_id,
           accts_pay_code_combination_id
    INTO   l_bill_to_location_id,
           l_supp_site_liab_ccid
    FROM   po_vendor_sites
    WHERE  vendor_site_id = p_vendor_site_id;

    l_ccid_to_api := NVL(p_inv_liab_ccid,
                         l_supp_site_liab_ccid);
  EXCEPTION
     WHEN OTHERS THEN
       l_bill_to_location_id := NULL;
       l_ccid_to_api := p_inv_liab_ccid;
  END;
  --
  -- Call LE API
  XLE_BUSINESSINFO_GRP.Get_PurchasetoPay_Info
                         (l_le_return_status,
                          l_msg_data,
                          null,
                          null,
                          l_bill_to_location_id,
                          l_ccid_to_api,
                          p_org_id,
                          l_ptop_le_info);

  IF (l_le_return_status = FND_API.G_RET_STS_SUCCESS) THEN
      p_le_id := l_ptop_le_info.legal_entity_id;
      p_le_name := l_ptop_le_info.name;
      p_le_registration_num := l_ptop_le_info.registration_number;
      -- p_le_party_id := l_ptop_le_info.party_id;
      p_le_address1 := l_ptop_le_info.address_line_1;
      p_le_city := l_ptop_le_info.town_or_city;
      p_le_postal_code := l_ptop_le_info.postal_code;
      p_le_country := l_ptop_le_info.country;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    APP_EXCEPTION.RAISE_EXCEPTION;
END getInvoiceLEInfo;

PROCEDURE Delete_AP_Profiles
     (P_Profile_Option_Name          IN            VARCHAR2)
IS
BEGIN
  FND_PROFILE_OPTIONS_PKG.Delete_Row(P_Profile_Option_Name);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    NULL;
END Delete_AP_Profiles;

/*
3881457 : Create new function that returns the closing status of the
                  period that the input date is in.
*/
FUNCTION PERIOD_STATUS (p_gl_date IN DATE)
   RETURN VARCHAR2 IS

   CURSOR c_input_period IS
      SELECT GLPS.closing_status
        FROM gl_period_statuses GLPS,
             ap_system_parameters SP
       WHERE GLPS.application_id = 200
         AND GLPS.set_of_books_id = SP.set_of_books_id
         AND TRUNC(p_gl_date) BETWEEN GLPS.start_date AND GLPS.end_date
         AND NVL(GLPS.adjustment_period_flag, 'N') = 'N';

   v_closing_status GL_PERIOD_STATUSES.CLOSING_STATUS%TYPE;

BEGIN

   OPEN c_input_period;

   FETCH c_input_period
    INTO v_closing_status;

   CLOSE c_input_period;

   RETURN v_closing_status;

END PERIOD_STATUS;


PROCEDURE clob_to_file
        (p_xml_clob           IN CLOB) IS

l_clob_size                NUMBER;
l_offset                   NUMBER;
l_chunk_size               INTEGER;
l_chunk                    VARCHAR2(32767);
l_log_module               VARCHAR2(240);

BEGIN


   l_clob_size := dbms_lob.getlength(p_xml_clob);

   IF (l_clob_size = 0) THEN
      RETURN;
   END IF;

   l_offset     := 1;
   l_chunk_size := 3000;

   WHILE (l_clob_size > 0) LOOP
      l_chunk := dbms_lob.substr (p_xml_clob, l_chunk_size, l_offset);
      fnd_file.put
         (which     => fnd_file.output
         ,buff      => l_chunk);

      l_clob_size := l_clob_size - l_chunk_size;
      l_offset := l_offset + l_chunk_size;
   END LOOP;

   fnd_file.new_line(fnd_file.output,1);

EXCEPTION
  WHEN OTHERS THEN
    APP_EXCEPTION.RAISE_EXCEPTION;

END clob_to_file;

FUNCTION pa_period_status(
        p_gl_date      IN      DATE,
        p_org_id       IN      number default
           mo_global.get_current_org_id)  RETURN varchar2 IS

   CURSOR c_closing_status IS
      SELECT GLPS.closing_status
        FROM gl_period_statuses GLPS,
             ap_system_parameters SP
       WHERE GLPS.application_id = 8721
         AND SP.org_id = P_Org_Id
         AND GLPS.set_of_books_id = SP.set_of_books_id
         AND TRUNC(p_gl_date) BETWEEN GLPS.start_date AND GLPS.end_date
         AND NVL(GLPS.adjustment_period_flag, 'N') = 'N';

   v_closing_status GL_PERIOD_STATUSES.CLOSING_STATUS%TYPE;

BEGIN
   OPEN c_closing_status;

   FETCH c_closing_status
    INTO v_closing_status;

   CLOSE c_closing_status;

   RETURN v_closing_status;
END pa_period_status;

/*============================================================================
 |  FUNCTION - Get_PO_REVERSED_ENCUMB_AMOUNT
 |
 |  DESCRIPTION
 |      fetch the amount of PO encumbrance reversed against the given PO
 |      distribution from all invoices for a given date range in functional
 |      currency. Calculation includes PO encumbrance which are in GL only.
 |      In case Invoice encumbrance type is the same as PO encumbrance, we
 |      need to exclude the variance.
 |      it returns actual amount or 0 if there is po reversed encumbrance
 |      line existing, otherwise returns NULL.
 |
 |      This function is only applicable to pre 11i and 11i data. Due to R12
 |      new funds/encumbrance solution. AP will be maintaining this function
 |      for pre-upgrade data because of PSA team decide no upgrade for
 |      AP_ENCUMBRANCE_LINES_ALL table.
 |
 |  PARAMETERS
 |      P_Po_distribution_id - po_distribution_id (in)
 |      P_Start_date - Start gl date (in)
 |      P_End_date - End gl date (in)
 |      P_Calling_Sequence - debug usage
 |
 |  KNOWN ISSUES:
 |
 |  NOTES:
 |
 |      1. In case user changes the purchase order encumbrance
 |         type or Invoice encumbrance type after invoice is
 |         validated, this API might not return a valid value.
 |
 |  MODIFICATION HISTORY
 |  Date         Author             Description of Change
 |  2-18-06      sfeng              move function to different pkg and
 |                                  back out the change of bug 3851654
 |
 *==========================================================================*/

 FUNCTION Get_PO_Reversed_Encumb_Amount(
              P_Po_Distribution_Id   IN            NUMBER,
              P_Start_gl_Date        IN            DATE,
              P_End_gl_Date          IN            DATE,
              P_Calling_Sequence     IN            VARCHAR2 DEFAULT NULL)

 RETURN NUMBER
 IS

   l_current_calling_sequence VARCHAR2(2000);
   l_procedure_name CONSTANT VARCHAR2(60) := 'Get_PO_Reversed_Encumb_Amount';
   l_log_msg        FND_LOG_MESSAGES.MESSAGE_TEXT%TYPE;

   l_unencumbered_amount       NUMBER;
   l_upg_unencumbered_amount   NUMBER;
   l_total_unencumbered_amount NUMBER;

   CURSOR po_enc_reversed_cur IS
   SELECT sum(nvl(ael.accounted_cr,0) - nvl(ael.accounted_dr,0) )
     FROM (SELECT DISTINCT old_distribution_id, encumbered_flag, org_id
             FROM AP_INVOICE_DISTRIBUTIONS dist
            WHERE po_distribution_id = p_po_distribution_id
          ) aid,
          AP_ENCUMBRANCE_LINES ael,
          financials_system_parameters fsp
    WHERE 1=1 --aid.po_distribution_id = P_po_distribution_id --commented for bug12962585
      AND aid.old_distribution_id = ael.invoice_distribution_id -- added for bug12962585
      -- AND aid.invoice_distribution_id = ael.invoice_distribution_id --commented for bug12962585
      AND ( ( p_start_gl_date is not null
              and p_start_gl_date <= ael.accounting_date ) or
            ( p_start_gl_date is null ) )
      AND ( (p_end_gl_date is not null
             and  p_end_gl_date >= ael.accounting_date ) or
            (p_end_gl_date is null ) )
      --AND ael.encumbrance_line_type not in ('IPV', 'ERV', 'QV','AV') --commented for bug12962585
      AND  nvl(aid.org_id,-1) =  nvl(fsp.org_id,-1)
      AND  ael.encumbrance_type_id =  fsp.purch_encumbrance_type_id
      --added below condition for bug12962585
      AND ( (ael.ae_header_id is null and aid.encumbered_flag = 'Y' ) or
            (ael.ae_header_id is not null and
             'Y' = ( select gl_transfer_flag
                     from ap_ae_headers aeh
                     where aeh.ae_header_id = ael.ae_header_id ) )
          )
;


   -- Bug 7004146, added the condition on the historical flag
   -- and line types, to make sure that only the pre-11i
   -- distributions are picked up.
   CURSOR upgraded_po_enc_rev_cur IS
   SELECT sum (nvl(nvl(aid.base_amount,aid.amount),0) -
               nvl(aid.base_invoice_price_variance ,0) -
               nvl(aid.exchange_rate_variance,0) -
               nvl(aid.base_quantity_variance,0))
     FROM   ap_invoice_dists_arch aid, --bug12962585, changed to old table
            po_distributions pd,
            financials_system_parameters fs
    where aid.po_distribution_id = p_po_distribution_id
      and aid.po_distribution_id = pd.po_distribution_id
      and nvl(aid.org_id,-1) = nvl(fs.org_id,-1)
      /* and fs.inv_encumbrance_type_id <> fs.purch_encumbrance_type_id Bug 14063588*/
      and NVL(PD.accrue_on_receipt_flag,'N') = 'N'
      AND AID.po_distribution_id is not null
      AND nvl(aid.match_status_flag, 'N') = 'A'
      AND nvl(aid.encumbered_flag, 'N') = 'Y'
      /* AND nvl(aid.historical_flag, 'N') = 'Y' Bug 14063588*/
      AND aid.line_type_lookup_code NOT IN ('IPV', 'ERV', 'TIPV', 'TERV', 'TRV', 'QV', 'AV')
      AND (aid.accrual_posted_flag = 'Y' or aid.cash_posted_flag = 'Y')
      AND (( p_start_gl_date is not null and p_start_gl_date <= aid.accounting_date) or (p_start_gl_date is null))
      AND ((p_end_gl_date is not null and p_end_gl_date >= aid.accounting_date) or (p_end_gl_date is null))
      AND NOT EXISTS (SELECT 'release 11.5 encumbrance'
                        from ap_encumbrance_lines_all ael
                       where ael.invoice_distribution_id = aid.invoice_distribution_id)
      -- bug 7225570
      AND aid.bc_event_id is null
      AND NOT EXISTS (SELECT 'release 11.5 encumbrance tax'
              from ap_encumbrance_lines_all ael
              where ael.invoice_distribution_id = aid.charge_applicable_to_dist_id);

 BEGIN

   l_current_calling_sequence :=  'AP_UTILITIES_PKG.'
                                 || 'Get_PO_Reversed_Encumb_Amount<-'
                                 || P_calling_sequence;

   G_CURRENT_RUNTIME_LEVEL := FND_LOG.G_CURRENT_RUNTIME_LEVEL;

   l_log_msg := 'Begin of procedure '|| l_procedure_name;
   IF (G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL ) THEN
    FND_LOG.STRING(G_LEVEL_PROCEDURE,
                   G_MODULE_NAME||l_procedure_name||'.begin',
                   l_log_msg);
   END IF;

   -----------------------------------------------------------
   l_log_msg :=  'Start to Open the po_encumbrance_cur' ;
   -----------------------------------------------------------
   IF (G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL ) THEN
     FND_LOG.STRING(G_LEVEL_PROCEDURE,
                   G_MODULE_NAME||l_procedure_name||'.begin',
                   l_log_msg);
   END IF;


   OPEN po_enc_reversed_cur;
   FETCH po_enc_reversed_cur INTO
         l_unencumbered_amount;

   IF (po_enc_reversed_cur%NOTFOUND) THEN
     -----------------------------------------------------------
     l_log_msg :=  'NO encumbrance line exists' ;
     -----------------------------------------------------------
     IF (G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL ) THEN
       FND_LOG.STRING(G_LEVEL_PROCEDURE,
                   G_MODULE_NAME||l_procedure_name||'.begin',
                   l_log_msg);
     END IF;

     l_unencumbered_amount :=  NULL;
   END IF;

   CLOSE po_enc_reversed_cur;

   -----------------------------------------------------------
   l_log_msg :=  'close the cursor po_enc_reversed_cur' ;
   -----------------------------------------------------------
   IF (G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL ) THEN
     FND_LOG.STRING(G_LEVEL_PROCEDURE,
                   G_MODULE_NAME||l_procedure_name||'.begin',
                   l_log_msg);
   END IF;


     OPEN upgraded_po_enc_rev_cur;
     -----------------------------------------------------------
     l_log_msg :=  'Open upgraded_po_enc_rev_cur' ;
     -----------------------------------------------------------
     IF (G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL ) THEN
       FND_LOG.STRING(G_LEVEL_PROCEDURE,
                      G_MODULE_NAME||l_procedure_name||'.begin',
                      l_log_msg);
     END IF;

     FETCH upgraded_po_enc_rev_cur INTO
         l_upg_unencumbered_amount;

     IF (upgraded_po_enc_rev_cur%NOTFOUND) THEN
       -----------------------------------------------------------
       l_log_msg :=  'NO upgraded encumbrance reversals exist' ;
       -----------------------------------------------------------
       IF (G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL ) THEN
         FND_LOG.STRING(G_LEVEL_PROCEDURE,
                        G_MODULE_NAME||l_procedure_name||'.begin',
                        l_log_msg);
       END IF;

       l_upg_unencumbered_amount :=  NULL;
     END IF;

     CLOSE upgraded_po_enc_rev_cur;


   IF (l_unencumbered_amount is not null or l_upg_unencumbered_amount is not null) THEN
     l_total_unencumbered_amount := nvl(l_unencumbered_amount,0) + nvl(l_upg_unencumbered_amount,0);
   ELSE
     l_total_unencumbered_amount := NULL;
   END IF;

   RETURN (l_total_unencumbered_amount);

 EXCEPTION
   WHEN OTHERS THEN

     IF (G_LEVEL_EXCEPTION >= G_CURRENT_RUNTIME_LEVEL ) THEN
        FND_LOG.STRING(G_LEVEL_EXCEPTION,
                       G_MODULE_NAME || l_procedure_name,
                       'EXCEPTION');
     END IF;

     IF ( po_enc_reversed_cur%ISOPEN ) THEN
       CLOSE po_enc_reversed_cur;
     END IF;

     IF ( upgraded_po_enc_rev_cur%ISOPEN ) THEN
       CLOSE upgraded_po_enc_rev_cur;
     END IF;

     RAISE;
 END Get_PO_Reversed_Encumb_Amount;

/* Bug 5572876. Asset Book for Ledger is cached */
Function Ledger_Asset_Book (P_ledger_id     IN Number)
    Return Varchar2
IS
  l_asset_book   fa_book_controls.book_type_code%TYPE;

BEGIN


  If g_asset_book_code_t.count > 0 Then

    If  g_asset_book_code_t.exists(p_ledger_id) Then

       l_asset_book :=  g_asset_book_code_t(p_ledger_id).asset_book_code;

    Else

      Begin
        SELECT book_type_code
        INTO l_asset_book
        FROM fa_book_controls fc
        WHERE fc.book_class = 'CORPORATE' -- bug 8843743: modify
        AND fc.set_of_books_id = p_ledger_id
        AND fc.date_ineffective  IS NULL;
      Exception
        WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
          l_asset_book := NULL;
      End;

      g_asset_book_code_t(p_ledger_id).asset_book_code := l_asset_book;

    End If;

  Else

    Begin
      SELECT book_type_code
      INTO l_asset_book
      FROM fa_book_controls fc
      WHERE fc.book_class = 'CORPORATE' -- bug 8843743: modify
      AND fc.set_of_books_id = p_ledger_id
      AND fc.date_ineffective  IS NULL;
    Exception
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
        l_asset_book := NULL;
    End;

    g_asset_book_code_t(p_ledger_id).asset_book_code := l_asset_book;

  End If;

  Return (l_asset_book);

End Ledger_Asset_Book;


--Function Get_CCR_Status, added for the R12 FSIO gap--
--bug6053476

FUNCTION get_ccr_status(P_object_id              IN     NUMBER,
                        P_object_type            IN     VARCHAR2
                        )
return VARCHAR2 IS

   l_return_status  		VARCHAR2(255);
   l_msg_count			NUMBER;
   l_msg_data			VARCHAR2(255);
   l_ccr_id			NUMBER;
   l_out_status		        VARCHAR2(1);
   l_error_code			NUMBER;

BEGIN

 FV_CCR_GRP.fv_is_ccr(
           p_api_version     => 1.0,
           p_init_msg_list   => FND_API.G_FALSE,
           P_object_id       => P_object_id,
           P_object_type     => P_object_type,
           x_return_status   => l_return_status,
           x_msg_count       => l_msg_count,
           x_msg_data        => l_msg_data,
           x_ccr_id          => l_ccr_id,
           x_out_status      => l_out_status,
           x_error_code      => l_error_code
           );

   IF l_out_status is not Null THEN
        Return l_out_status;
   ELSE
        Return 'F';
   END IF;

 EXCEPTION
  When Others Then
    Return 'F';
END get_ccr_status;

/*--------------------------------------------------------------------------
 * * Function get_gl_natural_account
 * *	Input parameters:
 * *		p_coa_id: Chart of Accounts ID
 * *		p_ccid:    Code Combination ID
 * *	This function returns the value of the natural segment
 * *	of a CCID that is passed as input parameter to it.
 * *
 * * Remarks: Bug 6980939 - Added  the Function.
 * *------------------------------------------------------------------------*/

FUNCTION get_gl_natural_account(
      p_coa_id IN NUMBER,
      p_ccid IN NUMBER,
      P_calling_sequence IN VARCHAR2 DEFAULT NULL
      )
RETURN VARCHAR2 IS

	l_success BOOLEAN;
	l_segment_num VARCHAR2(15);
	l_nat_account VARCHAR2(25);
        l_coa_ccid    VARCHAR2(35); -- bug 7172942
	l_current_calling_sequence VARCHAR2(2000);
	l_debug_info VARCHAR2(2000);
	l_api_name CONSTANT VARCHAR2(100) := 'get_gl_natural_account';
	e_api_failure EXCEPTION;

BEGIN

l_current_calling_sequence := P_calling_sequence||'->'||'get_gl_natural_account';

l_debug_info := 'Begin of get_gl_natural_account';
IF (G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,l_debug_info);
END IF;

    /* Bug 7172942 - Added caching logic to improve performance. */

    l_coa_ccid := to_char(p_coa_id)||'-'||to_char(p_ccid);

IF (( g_natural_acct_seg_t.count > 0 ) AND (g_natural_acct_seg_t.exists(l_coa_ccid))) Then
        l_nat_account := g_natural_acct_seg_t(l_coa_ccid).natural_acct_seg;
ELSE
--Bug 7172942
    l_debug_info := 'Natural Segment not found in Cache';
    IF (G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;

        l_success := FND_FLEX_APIS.get_segment_column(101,
			    'GL#',
			    p_coa_id,
			    'GL_ACCOUNT',
			    l_segment_num);

    l_debug_info := 'FND API returned Natural Account: '||To_Char(l_segment_num);
    IF (G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;

    IF (l_success = FALSE) THEN
    	l_debug_info := 'FND API Failed';
    	IF (G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
    	  FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,l_debug_info);
    	END IF;
    	RAISE e_api_failure;
    END IF;

    l_debug_info := 'Dyn SQL to be run for ccid: '||p_ccid||' and CoA ID:'||p_coa_id;
    IF (G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;

    EXECUTE IMMEDIATE 'SELECT '|| l_segment_num ||
    		' from gl_code_combinations where code_combination_id = :a '
    INTO l_nat_account USING p_ccid;

    l_debug_info := 'Natural account: '||l_nat_account||'. end of function call. ';
    IF (G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;

    --Bug 7172942
    g_natural_acct_seg_t(l_coa_ccid).natural_acct_seg := l_nat_account ;
END IF;
--End Bug 7172942

RETURN l_nat_account;

EXCEPTION
	WHEN OTHERS THEN
	    IF (SQLCODE <> -20001 ) THEN
	       FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
	       FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
	       FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_current_calling_sequence);
	       FND_MESSAGE.SET_TOKEN('DEBUG_INFO', l_debug_info );

      APP_EXCEPTION.RAISE_EXCEPTION;

      END IF;

END get_gl_natural_account;

-- bug 7531219
-- Function to validate balancing segment to the ledger
FUNCTION is_balancing_segment_valid (
        p_set_of_books_id               IN      gl_sets_of_books.set_of_books_id%type,
        p_balancing_segment_value	IN    	gl_ledger_segment_values.segment_value%type,
	p_date				IN	DATE,
	p_calling_sequence		IN	VARCHAR2)
RETURN BOOLEAN IS
 l_valid varchar2(1) := 'N';
 l_current_calling_sequence VARCHAR2(2000);
 l_debug_info VARCHAR2(2000);
 l_bal_seg_value_option_code varchar2(1);
 l_api_name CONSTANT VARCHAR2(100) := 'is_balancing_segment_valid';

BEGIN
  l_current_calling_sequence := P_calling_sequence||'->'||'is_balancing_segment_valid';

  l_debug_info := 'Begin of is_balancing_segment_valid';
  IF (G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,l_debug_info);
  END IF;

   select bal_seg_value_option_code
    into l_bal_seg_value_option_code
    from gl_ledgers
   where ledger_id = p_set_of_books_id;

   if nvl(l_bal_seg_value_option_code, 'A') <> 'A'
   then
       begin

        SELECT 'Y'
          INTO l_valid
          FROM gl_ledger_segment_values glsv
         WHERE glsv.segment_value = p_balancing_segment_value
           AND glsv.segment_type_code = 'B'
           AND glsv.ledger_id = p_set_of_books_id
           AND p_date BETWEEN NVL(glsv.start_date, p_date)
                          AND NVL(glsv.end_date, p_date)
           AND rownum = 1;

       exception
         when others then
           l_debug_info := 'invalid balancing segment: '||p_balancing_segment_value||' to the ledger: '||p_set_of_books_id;
           IF (G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;
           return false;
       end;
    end if;

  return true;

EXCEPTION
	WHEN OTHERS THEN
	    IF (SQLCODE <> -20001 ) THEN
	       FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
	       FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
	       FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_current_calling_sequence);
	       FND_MESSAGE.SET_TOKEN('DEBUG_INFO', l_debug_info );

      APP_EXCEPTION.RAISE_EXCEPTION;

      END IF;
END is_balancing_segment_valid;

-- Added for bug 8408345.

PROCEDURE Get_gl_date_and_period_1 (
          P_Date              IN            DATE,
          P_Receipt_Date      IN            DATE DEFAULT NULL,
          P_Period_Name          OUT NOCOPY VARCHAR2,
          P_GL_Date              OUT NOCOPY DATE,
          P_Batch_GL_Date     IN            DATE DEFAULT NULL,
          P_Org_Id            IN            NUMBER DEFAULT
                                             MO_GLOBAL.GET_CURRENT_ORG_ID)
  IS
  l_period_name gl_period_statuses.period_name%TYPE := '';
  l_current_date date := '';
  l_gl_date date      := '';
  y_date date         := '';
  n_date date         := '';

BEGIN

  -- Determine which date we should be using

  -- First set up temporary variables y_date and n_date

  IF (P_Batch_GL_Date is null) THEN
    IF (P_Receipt_Date is null) THEN
       y_date := TRUNC(SYSDATE);
       n_date := TRUNC(P_date);
    ELSE
       y_date := TRUNC(P_Receipt_Date);
       n_date := TRUNC(P_Receipt_Date);
    END IF;
  END IF;

  -- MOAC.  Added org_id parameter and predicate to select statement
  SELECT NVL(P_Batch_GL_Date,
             DECODE(SP.gl_date_from_receipt_flag,
                   'S',TRUNC(SYSDATE),
                   'Y',y_date,
                   'N',n_date,
                   TRUNC(P_Date)))
    INTO l_current_date
    FROM ap_system_parameters_all SP  --5126689
   WHERE sp.org_id = p_org_id;

  -- Initialize the IN OUT NOCOPY variables
  P_GL_Date     := '';
  P_Period_Name := '';

  -- See IF the period corresponding to P_Date is open
   -- Added org_id parameter to this call MOAC
  l_period_name := get_current_gl_date_no_cache(
              l_current_date, P_Org_Id);

  IF (l_period_name is null) THEN

    -- The date is in a closed period, roll forward until we find one
    -- MOAC.  Added org_id parameter to call
    get_open_gl_date_no_cache
           (l_current_date,
            l_period_name,
            l_gl_date,
            P_Org_Id);
  ELSE
    -- No need to call the function.  The GL date will be the
    -- date passed to the function
    l_gl_date := l_current_date;
  END IF;

  P_Period_Name := l_Period_Name;
  P_GL_Date := l_GL_Date;

END Get_gl_date_and_period_1;

-- Added for bug 8408345.

function get_current_gl_date_no_cache (P_Date IN date,
                              P_Org_ID IN number default
                                 mo_global.get_current_org_id) return varchar2
is
  cursor l_current_cursor is
    SELECT period_name
      FROM gl_period_statuses GLPS,
           ap_system_parameters_all SP
     WHERE application_id = 200
       AND sp.org_id = P_Org_Id
       AND GLPS.set_of_books_id = SP.set_of_books_id
       AND trunc(P_Date) BETWEEN start_date AND end_date
       AND closing_status in ('O', 'F')
       AND NVL(adjustment_period_flag, 'N') = 'N';

  l_period_name gl_period_statuses.period_name%TYPE := '';
  l_api_name       CONSTANT VARCHAR2(200) := 'Get_Current_Gl_Date_No_Cache';
  l_debug_info     Varchar2(2000);

begin

   l_debug_info := 'Begining of Function';
   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
   END IF;

   open l_current_cursor;
   fetch l_current_cursor into l_period_name;
   close l_current_cursor;


   return (l_period_name);

end get_current_gl_date_no_cache;

-- Added for bug 8408345.

procedure get_open_gl_date_no_cache
                         (P_Date              IN date
                         ,P_Period_Name       OUT NOCOPY varchar2
                         ,P_GL_Date           OUT NOCOPY date
                         ,P_Org_Id            IN number DEFAULT
                            mo_global.get_current_org_id)
is
  cursor l_open_cursor is
      SELECT MIN(start_date),
             period_name
        FROM gl_period_statuses GLPS,
             ap_system_parameters_all SP
       WHERE application_id = 200
         AND sp.org_id = P_Org_Id
         AND GLPS.set_of_books_id = SP.set_of_books_id
         AND end_date >= P_Date --Bug6809792
         AND closing_status in ('O', 'F')
         AND NVL(adjustment_period_flag, 'N') = 'N'
       GROUP BY period_name
       ORDER BY MIN(start_date);

  l_start_date date := '';
  l_period_name gl_period_statuses.period_name%TYPE := '';
  l_api_name       CONSTANT VARCHAR2(200) := 'Get_Open_Gl_Date_No_Cache';
  l_debug_info     Varchar2(2000);


begin

    l_debug_info := 'Begining of Function';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;

    open l_open_cursor;
    fetch l_open_cursor into l_start_date, l_period_name;
    close l_open_cursor;

    P_Period_Name := l_period_name;
    P_GL_Date := l_start_date;

end get_open_gl_date_no_cache;

/****************** FUNCTION get_ccr_reg_status ****************************/

--Start 8691645

FUNCTION get_ccr_reg_status(p_vendor_site_id IN AP_INVOICES.VENDOR_SITE_ID%TYPE)
              return VARCHAR2 IS

   l_init_msg_list  varchar2(1000);
   l_return_status varchar2(1);
   l_msg_count NUMBER;
   l_msg_data  VARCHAR2(1000);
   l_vndr_ccr_status varchar2(1);
   l_error_code			NUMBER;
   l_api_name       CONSTANT VARCHAR2(200) := 'get_ccr_reg_status';
   l_debug_info     Varchar2(2000);

BEGIN

  l_debug_info := 'Begining of Function';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;

 FV_CCR_GRP.FV_CCR_REG_STATUS(
                  p_api_version      =>	'1.0',
  	          p_init_msg_list    =>	l_init_msg_list,
	          p_vendor_site_id   => p_vendor_site_id,
	          x_return_status    => l_return_status,
	          x_msg_count	     => l_msg_count,
	          x_msg_data	     => l_msg_data,
	          x_ccr_status	     => l_vndr_ccr_status,
	          x_error_code	     => l_error_code);

        Return l_vndr_ccr_status;
EXCEPTION
  When Others Then
    Return 'U';  --unexpected error
END get_ccr_reg_status;

--End 8691645


 --Begin ER#19675818. Hold Event Procedure, which get called  when there is hold placed/released for BPM

procedure Raise_Hold_Event(P_INVOICE_ID          IN NUMBER,
                           P_LINE_LOCATION_ID    IN NUMBER,
                           P_HOLD_LOOKUP_CODE    IN VARCHAR2,
		           P_HOLD_REASON         IN VARCHAR2,
		           P_RELEASE_LOOKUP_CODE IN VARCHAR2,
		           P_RELEASE_REASON      IN VARCHAR2,
		           P_STATUS_FLAG         IN VARCHAR2,
		           P_HOLD_ID             IN NUMBER,
			   P_CALLING_SEQUENCE    IN VARCHAR2) IS


l_parameter_list	        wf_parameter_list_t;
l_event_key			VARCHAR2(100);
l_event_name		        VARCHAR2(100) := 'oracle.apps.ap.invoice.hold';

 l_api_name       CONSTANT VARCHAR2(200) := 'Raise_Hold_Event';
 l_debug_info     Varchar2(2000);


BEGIN

   l_debug_info := 'Parameters : '
		        || 'P_INVOICE_ID = ' || P_INVOICE_ID
			|| 'P_LINE_LOCATION_ID = ' || P_LINE_LOCATION_ID
			|| 'P_HOLD_LOOKUP_CODE = ' || P_HOLD_LOOKUP_CODE
			|| 'P_HOLD_REASON = ' || P_HOLD_REASON
			|| 'P_RELEASE_LOOKUP_CODE = ' || P_RELEASE_LOOKUP_CODE
			|| 'P_RELEASE_REASON = ' || P_RELEASE_REASON
			|| 'P_STATUS_FLAG = ' || P_STATUS_FLAG
			|| 'P_HOLD_ID = ' || P_HOLD_ID
		        || ' P_CALLING_SEQUENCE = ' || P_CALLING_SEQUENCE ;

  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
   END IF;


  l_parameter_list := wf_parameter_list_t( wf_parameter_t('INVOICE_ID',TO_CHAR(P_INVOICE_ID)),
                                           wf_parameter_t('LINE_LOCATION_ID',TO_CHAR(P_LINE_LOCATION_ID)),
                                           wf_parameter_t('HOLD_LOOKUP_CODE',P_HOLD_LOOKUP_CODE),
					   wf_parameter_t('HOLD_REASON',P_HOLD_REASON),
					   wf_parameter_t('RELEASE_LOOKUP_CODE',P_RELEASE_LOOKUP_CODE),
					   wf_parameter_t('RELEASE_REASON',P_RELEASE_REASON),
					   wf_parameter_t('STATUS_FLAG',P_STATUS_FLAG),
					   wf_parameter_t('HOLD_ID',TO_CHAR(P_HOLD_ID) )
					 );


  SELECT to_char(AP_BPM_EVENT_S.NEXTVAL)
  INTO   l_event_key
  FROM   dual;

  l_debug_info := 'Before raising workflow event : '
		        || 'event_name = ' || l_event_name
		        || ' event_key = ' || l_event_key ;

  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
   END IF;


  WF_EVENT.RAISE( p_event_name => l_event_name,
		  p_event_key  => l_event_key,
		  p_parameters => l_parameter_list);


 EXCEPTION


  WHEN OTHERS THEN
     l_debug_info := 'Error occured when event raised while placing/releasing hold';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
     END IF;

     WF_CORE.CONTEXT(P_CALLING_SEQUENCE, 'Raise_Hold_Event', l_event_name, l_event_key);
     RAISE;

END Raise_Hold_Event;


/*#
 * This Api to derive Payment terms details based on supplier site details.
 * This is used by BPM to estimate payment terms when invoice data is
 * received from third party into interface tables.
 * @param P_ORG_ID Organization Identifier Mandatory
 * @param P_VENDOR_ID Supplier Identifier Mandatory
 * @param P_VENDOR_SITE_ID Supplier Site Identifier Mandatory
 * @param P_INVOICE_DATE  Invoice Date
 * @param P_INVOICE_AMOUNT Invoice Amount
 * @param P_INVOICE_TYPE_LOOKUP_CODE Invoice Type
 *        If invoice is assoicated with PO then any one of below PO
 *        details is must to get correct terms id value
 * @param P_PO_HEADER_ID PO Header identifier
 * @param P_PO_LINE_LOCATION_ID PO shipment Identifier
 * @param P_PO_DISTRIBUTION_ID PO distribution identifier
 * @param P_GOODS_RECEIVED_DATE Invoice goods received date
 * @param P_INVOICE_RECEIVED_DATE Invoice received date
 * @param P_TERMS_ID Payment Terms Identifier
 * @param P_TERMS_NAME Payment Terms Name
 * @param P_TERMS_DATE Payment Terms Date
 * @param P_ERROR_CODE Error code
 * @param P_CALLING_SEQUENCE Calling Sequence
 * @return get payment terms info
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Get Payment Terms
 * @rep:category BUSINESS_ENTITY AP_INVOICE
 */

FUNCTION get_payment_terms (
    P_ORG_ID		         IN    NUMBER,
    P_VENDOR_ID                  IN    NUMBER,
    P_VENDOR_SITE_ID		 IN    NUMBER,
    P_INVOICE_DATE               IN    DATE      DEFAULT NULL,
    P_INVOICE_AMOUNT		 IN    NUMBER    DEFAULT NULL,
    P_INVOICE_TYPE_LOOKUP_CODE   IN    VARCHAR2  DEFAULT NULL,
    P_PO_HEADER_ID               IN    NUMBER    DEFAULT NULL,
    P_PO_LINE_LOCATION_ID        IN    NUMBER    DEFAULT NULL,
    P_PO_DISTRIBUTION_ID         IN    NUMBER    DEFAULT NULL,
    P_GOODS_RECEIVED_DATE        IN    DATE      DEFAULT NULL,
    P_INVOICE_RECEIVED_DATE      IN    DATE      DEFAULT NULL,
    P_TERMS_ID                   OUT   NOCOPY  NUMBER,
    P_TERMS_NAME                 OUT   NOCOPY  VARCHAR2,
    P_TERMS_DATE                 OUT   NOCOPY  DATE,
    P_ERROR_CODE                 OUT   NOCOPY  VARCHAR2,
    P_CALLING_SEQUENCE           IN    VARCHAR2) RETURN BOOLEAN IS

l_invoice_type_lookup_code      ap_invoices_all.invoice_type_lookup_code%TYPE;
l_terms_date_basis	   	ap_system_parameters_all.terms_date_basis%TYPE;
current_calling_sequence        VARCHAR2(2000);
debug_info                      VARCHAR2(2000);
l_api_name 			VARCHAR2(50);


BEGIN

  current_calling_sequence := 'AP_UTILITIES_PKG.get_payment_terms<-' ||P_calling_sequence;
  l_api_name := 'get_payment_terms';
  --------------------------------------------------------------------------
  -- terms defaulting: if PO exists for the invoice,
  -- use PO terms, otherwise use terms from Supplier Site.
  --------------------------------------------------------------------------

  debug_info := l_api_name || ': P_ORG_ID = ' || P_ORG_ID ||
	', P_VENDOR_ID = ' || P_VENDOR_ID ||
	', P_VENDOR_SITE_ID = ' || P_VENDOR_SITE_ID ||
	', P_INVOICE_DATE = ' || P_INVOICE_DATE ||
	', P_INVOICE_AMOUNT = '|| P_INVOICE_AMOUNT ||
	', P_INVOICE_TYPE_LOOKUP_CODE = '|| P_INVOICE_TYPE_LOOKUP_CODE ||
	', P_PO_HEADER_ID = '|| P_PO_HEADER_ID ||
	', P_PO_LINE_LOCATION_ID = '|| P_PO_LINE_LOCATION_ID ||
        ', P_PO_DISTRIBUTION_ID = '|| P_PO_DISTRIBUTION_ID ||
	', P_GOODS_RECEIVED_DATE = '|| P_GOODS_RECEIVED_DATE ||
	', P_INVOICE_RECEIVED_DATE = '||  P_INVOICE_RECEIVED_DATE;

  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
  END IF;

    SELECT terms_date_basis
    INTO l_terms_date_basis
    FROM po_vendor_sites pvs
    WHERE vendor_site_id = p_vendor_site_id;

    debug_info := 'l_terms_date_basis: '|| l_terms_date_basis;
  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
  END IF;

   IF (l_terms_date_basis = 'Invoice Received' )THEN
       IF(p_invoice_received_date is null) THEN
          P_ERROR_CODE := 'AP_INV_RCVD_NULL';
   	  RETURN(TRUE);
       ELSE
          P_TERMS_DATE  := P_INVOICE_RECEIVED_DATE;
       END IF;
   ELSIF (l_terms_date_basis = 'Goods Received') THEN
	 IF(p_goods_received_date is null) THEN
	   P_ERROR_CODE := 'AP_GDS_RCVD_NULL';
	   RETURN(TRUE);
         ELSE
            P_TERMS_DATE := P_GOODS_RECEIVED_DATE;
	 END IF;
    ELSIF (l_terms_date_basis = 'Invoice') THEN
	  IF(p_invoice_date is null) THEN
            P_ERROR_CODE := 'AP_INV_DATE_NULL';
	    RETURN(TRUE);
          ELSE
	    P_TERMS_DATE := P_INVOICE_DATE;
	  END IF;
   END IF;

   debug_info := 'P_TERMS_DATE: '|| P_TERMS_DATE;
  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
  END IF;


IF (P_INVOICE_TYPE_LOOKUP_CODE IS NULL OR
    P_INVOICE_TYPE_LOOKUP_CODE NOT IN ('STANDARD','CREDIT', 'DEBIT',
                    'PO PRICE ADJUST','PREPAYMENT','EXPENSE REPORT',
                   'PAYMENT REQUEST'))THEN

   IF(P_INVOICE_AMOUNT IS NOT NULL) THEN
	 IF(P_INVOICE_AMOUNT >=0) THEN
		  L_INVOICE_TYPE_LOOKUP_CODE := 'STANDARD';
	  ELSIF(P_INVOICE_AMOUNT<0)THEN
		  L_INVOICE_TYPE_LOOKUP_CODE := 'CREDIT';
	  END IF;
    ELSE
       L_INVOICE_TYPE_LOOKUP_CODE := 'STANDARD';
    END IF;
ELSE
  L_INVOICE_TYPE_LOOKUP_CODE := P_INVOICE_TYPE_LOOKUP_CODE;
END IF;

  debug_info := ' L_INVOICE_TYPE_LOOKUP_CODE: '|| L_INVOICE_TYPE_LOOKUP_CODE;
  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
      END IF;

--------------------------------------------------------------------------
  -- Step 1
  -- get payment terms from Payables Options if invoice is prepayment type.
  --------------------------------------------------------------------------

 IF(L_INVOICE_TYPE_LOOKUP_CODE = 'PREPAYMENT') THEN

    SELECT prepayment_terms_id
    INTO  p_terms_id
    FROM ap_system_parameters_all
    where org_id = P_ORG_ID;

 END IF;

  --------------------------------------------------------------
  -- Step 2
  -- get payment terms from PO or Supplier Site.
  --------------------------------------------------------------

IF(P_TERMS_ID IS NULL)THEN
    IF (P_PO_HEADER_ID IS NOT NULL ) Then

      SELECT terms_id
        INTO P_TERMS_ID
        FROM po_headers
       WHERE po_header_id = P_PO_HEADER_ID;

    ELSIF (P_PO_LINE_LOCATION_ID IS NOT NULL ) Then

        SELECT poh.terms_id
        INTO P_TERMS_ID
        FROM po_headers poh, po_line_locations_all pll
        WHERE poh.po_header_id = pll.po_header_id
	  and pll.line_location_id = P_PO_LINE_LOCATION_ID;

     ELSIF (P_PO_DISTRIBUTION_ID IS NOT NULL) Then

        SELECT poh.terms_id
        INTO P_TERMS_ID
        FROM po_headers poh, po_line_locations_all pll, po_distributions_all pod
        WHERE poh.po_header_id = pll.po_header_id
	  and pll.line_location_id=pod.line_location_id
	  and pod.po_distribution_id=P_PO_DISTRIBUTION_ID;
     END IF;
  END IF;


 debug_info := 'P_VENDOR_SITE_ID: ' || P_VENDOR_SITE_ID;

IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
END IF;

   IF(P_TERMS_ID IS NULL)THEN
    IF (L_INVOICE_TYPE_LOOKUP_CODE <> 'PAYMENT REQUEST' AND P_VENDOR_SITE_ID IS NOT NULL)  THEN

       debug_info := 'Get term_id from supplier site';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
      END IF;


      SELECT terms_id
      INTO   P_TERMS_ID
      FROM   po_vendor_sites
      WHERE  vendor_site_id = P_VENDOR_SITE_ID;

    ELSIF (L_INVOICE_TYPE_LOOKUP_CODE = 'PAYMENT REQUEST')  THEN

       debug_info := 'Get term_id from financials options';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
      END IF;

        SELECT terms_id
      INTO   p_terms_id
      FROM   financials_system_params_all
      WHERE  org_id = p_org_id;

    END IF;
  END IF;

  debug_info := 'terms id derived: '|| p_terms_id;
  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
  END IF;


  ------------------------------------------------------------------------------
  -- Step 4
  -- Derive terms name
  -----------------------------------------------------------------------------
   debug_info := 'Check terms name';

   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
   END IF;

   IF (p_terms_id IS NOT NULL)  THEN

      select name
      into p_terms_name
      from ap_terms
      where term_id = p_terms_id;

   END IF;

   debug_info := 'p_terms_name: '||p_terms_name;

   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
   END IF;


   RETURN(TRUE);

EXCEPTION
  WHEN OTHERS THEN
        IF (G_LEVEL_ERROR >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_ERROR,G_MODULE_NAME||l_api_name, debug_info);
        END IF;

    IF (SQLCODE < 0) THEN
        IF (G_LEVEL_ERROR >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_ERROR,G_MODULE_NAME||l_api_name, SQLERRM);
        END IF;
    END IF;
    RETURN(FALSE);

END get_payment_terms;


/*#
 * This Api to derive Due and Discount dates.
 * This is used by BPM to estimate discount amounts for invoices
 * received from third party into interface tables.
 * @param P_ORG_ID Organization Identifier Mandatory
 * @param P_VENDOR_ID Supplier Identifier Mandatory
 * @param P_VENDOR_SITE_ID Supplier Site Identifier Mandatory
 * @param P_INVOICE_DATE  Invoice Date
 * @param P_INVOICE_AMOUNT Invoice Amount
 * @param P_INV_CURR Invoice Currency
 * @param P_INVOICE_TYPE_LOOKUP_CODE Invoice Type
 *        If invoice is assoicated with PO then any one of below PO
 *        details is must to get correct terms id value
 * @param P_PO_HEADER_ID PO Header identifier
 * @param P_PO_LINE_LOCATION_ID PO shipment Identifier
 * @param P_PO_DISTRIBUTION_ID PO distribution identifier
 * @param P_GOODS_RECEIVED_DATE Invoice goods received date
 * @param P_INVOICE_RECEIVED_DATE Invoice received date
 * @param P_TERMS_ID Payment Terms Identifier
 * @param P_TERMS_NAME Payment Terms Name
 * @param P_TERMS_DATE Payment Terms Date
 * @param P_AMT_APPL_TO_DISC Total invoice amount applicable for discount
 * @param P_PAY_CURR Payment Currency
 * @param P_PAY_CROSS_RATE Invoice and Payment currency exchange rate
 * @param P_SCHDS_REC_LIST Payment schedules record.
 * @param P_ERROR_CODE Error code
 * @param P_CALLING_SEQUENCE Calling Sequence
 * @return get discount and due date
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Get Payment Terms
 * @rep:category BUSINESS_ENTITY AP_INVOICE
 */

FUNCTION GET_DISCOUNT_DUE_DATE(
    P_ORG_ID                     IN  NUMBER,
    P_VENDOR_ID                  IN  NUMBER,
    P_VENDOR_SITE_ID             IN  NUMBER,
    P_INVOICE_DATE               IN  DATE,
    P_INVOICE_AMOUNT		 IN  NUMBER,
    P_INV_CURR                   IN  VARCHAR2,
    P_INVOICE_TYPE_LOOKUP_CODE   IN  VARCHAR2 DEFAULT NULL,
    P_PO_HEADER_ID               IN  NUMBER   DEFAULT NULL,
    P_PO_LINE_LOCATION_ID        IN  NUMBER   DEFAULT NULL,
    P_PO_DISTRIBUTION_ID         IN  NUMBER   DEFAULT NULL,
    P_TERMS_ID                   IN  NUMBER   DEFAULT NULL,
    P_TERMS_NAME                 IN  VARCHAR2 DEFAULT NULL,
    P_TERMS_DATE                 IN  DATE     DEFAULT NULL,
    P_GOODS_RECEIVED_DATE        IN  DATE     DEFAULT NULL,
    P_INVOICE_RECEIVED_DATE      IN  DATE     DEFAULT NULL,
    P_AMT_APPL_TO_DISC           IN   NUMBER   DEFAULT NULL,
    P_PAY_CURR                   IN   VARCHAR2 DEFAULT NULL,
    P_PAY_CROSS_RATE             IN   NUMBER   DEFAULT NULL,
    P_SCHDS_REC_LIST             OUT NOCOPY  ap_utilities_pkg.schds_table,
    P_ERROR_CODE                 OUT NOCOPY  VARCHAR2,
    P_CALLING_SEQUENCE           IN  VARCHAR2) RETURN BOOLEAN IS

  debug_info                       VARCHAR2(1000);
  current_calling_sequence         VARCHAR2(500);
  l_api_name 			   VARCHAR2(50);
  l_fnd_currency_table             AP_IMPORT_INVOICES_PKG.Fnd_Currency_Tab_Type;
  l_valid_pay_currency            VARCHAR2(10);
  l_start_date_active              DATE;
  l_end_date_active                DATE;
  j                                INTEGER;
  i                                 BINARY_INTEGER := 0;
  l_invoice_type_lookup_code       ap_invoices.invoice_type_lookup_code%type;

  l_pay_curr                       VARCHAR2(10);
  L_AMT_APPL_TO_DISC               NUMBER;
  L_PAY_CROSS_RATE                 NUMBER;


  l_sequence_num	         ap_terms_lines.sequence_num%TYPE := 0;
  l_sign_due_amount	   ap_terms_lines.due_amount%TYPE;
  l_sign_remaining_amount  ap_terms_lines.due_amount%TYPE;
  l_calendar               ap_terms_lines.calendar%TYPE;
  l_terms_calendar         ap_terms_lines.calendar%TYPE;
  l_terms_id               ap_terms_lines.term_id%TYPE;
  l_terms_name             varchar2(50);
  l_terms_date                     DATE;
  l_due_date               ap_other_periods.due_date%TYPE;
  l_invoice_sign	         NUMBER;
  l_remaining_amount	   ap_payment_schedules.amount_remaining%TYPE;
  l_old_remaining_amount   ap_payment_schedules.amount_remaining%TYPE;
  l_ins_gross_amount	   ap_payment_schedules.gross_amount%TYPE;
  l_last_line_flag	   BOOLEAN;
  l_dummy		         VARCHAR2(200);
  l_min_acc_unit_pay_curr  fnd_currencies.minimum_accountable_unit%TYPE;
  l_precision_pay_curr     fnd_currencies.precision%TYPE;
  l_pay_curr_inv_amount    NUMBER;

  l_disc_amt_by_percent    NUMBER;
  l_disc_amt_by_percent_2  NUMBER;
  l_disc_amt_by_percent_3  NUMBER;
  l_discount_amount        NUMBER;
  l_discount_amount_2      NUMBER;
  l_discount_amount_3      NUMBER;
  L_ERROR_CODE             VARCHAR2(50);


  CURSOR c_terms_percent IS
    SELECT 'Terms are percent type'
    FROM   ap_terms_lines
    WHERE  term_id = l_Terms_Id
    AND    sequence_num = 1
    AND    due_percent IS NOT NULL;

  CURSOR c_terms IS
  SELECT calendar, sequence_num
  FROM ap_terms_lines
  WHERE term_id = l_terms_id
   ORDER BY sequence_num;

   CURSOR c_amounts IS
    SELECT SIGN(ABS(P_Invoice_Amount))
    ,      SIGN(due_amount)
    ,      due_amount
    ,      SIGN(ABS(l_remaining_amount) - ABS(due_amount))
    ,      ABS(l_remaining_amount) - ABS(due_amount)
    ,      calendar
    FROM   ap_terms_lines
    WHERE  term_id = l_Terms_Id
    AND    sequence_num = l_sequence_num;

BEGIN

  current_calling_sequence :=
  'AP_UTILITIES_PKG.GET_DISCOUNT_DUE_DATE<-'||P_calling_sequence;
  l_api_name := 'GET_DISCOUNT_DUE_DATE';

  debug_info := 'Organization Id: ' || P_ORG_ID;
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
      END IF;

IF(P_ORG_ID IS NULL)THEN

  P_ERROR_CODE := 'AP_ORG_INFO_NULL';
  debug_info := 'Organization Id is null';

  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
  END IF;
  RETURN(TRUE);
END IF;

debug_info := 'Invoice Amount: ' || P_INVOICE_AMOUNT;

IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
END IF;

IF(P_INVOICE_AMOUNT IS NULL)THEN
    P_ERROR_CODE := 'AP_INV_AMT_NULL';
  debug_info := 'Invoice Amount is null';

  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
  END IF;
  RETURN(TRUE);

END IF;

debug_info := 'Invoice currency: ' || P_INV_CURR;

IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
END IF;

IF(P_INV_CURR IS NULL)THEN

 P_ERROR_CODE := 'AP_INV_CURR_NULL';
  debug_info := 'Invoice Currency is null';

  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
  END IF;
  RETURN(TRUE);

END IF;

debug_info := 'Invoice Date: ' || P_INVOICE_DATE;

IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
END IF;

IF(P_INVOICE_DATE IS NULL)THEN

 P_ERROR_CODE := 'AP_INV_DATE_NULL';
  debug_info := 'Invoice Date is null';

  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
  END IF;
  RETURN(TRUE);
END IF;


IF(P_VENDOR_ID IS NULL)THEN

 P_ERROR_CODE := 'AP_INV_VNDR_NULL';
  debug_info := 'Supplier Detail is null';

  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
  END IF;
  RETURN(TRUE);
END IF;


IF(P_VENDOR_SITE_ID IS NULL)THEN

 P_ERROR_CODE := 'AP_INV_VNDR__SITE_NULL';
  debug_info := 'Supplier Site Detail is null';

  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
  END IF;
  RETURN(TRUE);
END IF;

debug_info := 'Invoice Type: ' || P_INVOICE_TYPE_LOOKUP_CODE;

IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
END IF;

IF (P_INVOICE_TYPE_LOOKUP_CODE IS NULL OR
    P_INVOICE_TYPE_LOOKUP_CODE NOT IN ('STANDARD','CREDIT', 'DEBIT',
                    'PO PRICE ADJUST','PREPAYMENT','EXPENSE REPORT',
                   'PAYMENT REQUEST'))THEN
    IF(P_INVOICE_AMOUNT >=0) THEN
       L_INVOICE_TYPE_LOOKUP_CODE := 'STANDARD';
    ELSIF(P_INVOICE_AMOUNT<0)THEN
     L_INVOICE_TYPE_LOOKUP_CODE := 'CREDIT';
    END IF;

END IF;


 debug_info := 'P_INVOICE_TYPE_LOOKUP_CODE: ' || L_INVOICE_TYPE_LOOKUP_CODE;

IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
END IF;

debug_info := 'P_TERMS_ID: ' || P_TERMS_ID||' P_TERMS_NAME: '||P_TERMS_NAME;

IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
END IF;

 IF (P_TERMS_ID IS NULL ) THEN

   IF(P_TERMS_NAME IS NOT NULL) THEN

      SELECT term_id
       INTO l_terms_id
       FROM ap_terms
      WHERE name = P_TERMS_NAME;

   ELSE

     IF  NOT(AP_UTILITIES_PKG.get_payment_terms (
	      P_ORG_ID			 => P_ORG_ID,
	      P_VENDOR_ID		 => P_VENDOR_ID,
	      P_VENDOR_SITE_ID		 => P_VENDOR_SITE_ID,
	      P_INVOICE_DATE		 => P_INVOICE_DATE,
	      P_INVOICE_AMOUNT		 => P_INVOICE_AMOUNT,
	      P_INVOICE_TYPE_LOOKUP_CODE => L_INVOICE_TYPE_LOOKUP_CODE,
	      P_PO_HEADER_ID             => P_PO_HEADER_ID,
	      P_PO_LINE_LOCATION_ID      => P_PO_LINE_LOCATION_ID,
	    P_PO_DISTRIBUTION_ID         => P_PO_DISTRIBUTION_ID,
	    P_GOODS_RECEIVED_DATE        => P_GOODS_RECEIVED_DATE,
	    P_INVOICE_RECEIVED_DATE      => P_INVOICE_RECEIVED_DATE,
	    P_TERMS_ID                   => l_terms_id,
	    P_TERMS_NAME                 => l_terms_name,
	    P_TERMS_DATE                 => l_terms_date,
	    P_ERROR_CODE                 => l_error_code,
	    P_CALLING_SEQUENCE           => current_calling_sequence)) THEN

              P_ERROR_CODE := l_error_code;
	      RETURN(TRUE);
       END IF;

    END IF;

    ELSE
      l_terms_id := P_TERMS_ID;

    END IF;

debug_info := 'l_terms_id: '||l_terms_id;

IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
END IF;

IF(l_terms_id IS NULL )THEN
	debug_info := 'P_TERMS_ID is null after trying from all other values ';
	IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	    FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
	END IF;

   P_ERROR_CODE := 'AP_INV_TERMS_ID_NULL';

   RETURN(TRUE);
END IF;

debug_info := 'l_terms_date: '||l_terms_date;

IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
END IF;

IF(l_terms_date IS NULL)THEN
   IF(p_terms_date IS NULL) THEN
	debug_info := 'l_terms_date is null';
	IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	    FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
	END IF;

      P_ERROR_CODE := 'AP_INV_TERMS_DATE_NULL';
      RETURN(TRUE);
   ELSE
     l_terms_date := p_terms_date;
   END IF;
END IF;


debug_info := 'P_PAY_CURR: '||P_PAY_CURR;

IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
END IF;

IF(P_PAY_CURR IS NULL)THEN
   L_PAY_CURR := P_INV_CURR;
   L_PAY_CROSS_RATE := 1;
   l_pay_curr_inv_amount := P_INVOICE_AMOUNT;
ELSE
 L_PAY_CURR := P_PAY_CURR;
  --Check whether passed currency is valid or not
debug_info := 'Calling AP_IMPORT_UTILITIES_PKG.Cache_Fnd_Currency';

IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
END IF;
  IF (AP_IMPORT_UTILITIES_PKG.Cache_Fnd_Currency (
           P_Fnd_Currency_Table   => l_fnd_currency_table,
           P_Calling_Sequence     => current_calling_sequence ) <> TRUE) THEN
     APP_EXCEPTION.RAISE_EXCEPTION;
  END IF;

   FOR j IN l_fnd_currency_table.First..l_fnd_currency_table.Last LOOP
      IF l_fnd_currency_table(j).currency_code = L_PAY_CURR THEN
        l_valid_pay_currency  := l_fnd_currency_table(j).currency_code;
        l_start_date_active   := l_fnd_currency_table(j).start_date_active;
        l_end_date_active     := l_fnd_currency_table(j).end_date_active;
        EXIT;
      END IF;
    END LOOP;

     debug_info := 'l_valid_pay_currency: '||l_valid_pay_currency||
                   ' l_start_date_active: '||l_start_date_active||
		   ' l_end_date_active: '||l_end_date_active;

IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
END IF;

    IF l_valid_pay_currency IS NOT NULL THEN
      IF (trunc(sysdate) <   nvl(l_start_date_active, trunc(sysdate))) OR
         (trunc(sysdate) >=   nvl(l_end_date_active,trunc(sysdate)+1)) THEN

	  debug_info := 'Invalid Pay currency';

         IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
         END IF;

         P_ERROR_CODE := 'AP_INVALID_PAY_CUR';
	 RETURN(TRUE);
      END IF;
    ELSE
       P_ERROR_CODE := 'AP_INVALID_PAY_CUR';
	 RETURN(TRUE);
    END IF;

    IF (L_PAY_CURR <> P_INV_CURR) THEN

    debug_info := 'Before checking fixed rate type conversions';

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
    END IF;

    IF ( gl_currency_api.is_fixed_rate(
               P_INV_CURR,
               L_PAY_CURR,
               P_INVOICE_DATE) <> 'Y' ) THEN  --pay cross rate date

        P_ERROR_CODE := 'AP_NO_RATE_CONV';

	 debug_info := 'No fixed rate conversions';

        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
         END IF;

	 RETURN(TRUE);
     ELSE
         L_PAY_CROSS_RATE := ap_utilities_pkg.get_exchange_rate(
                                    P_INV_CURR,
                                    L_PAY_CURR,
                                    'EMU FIXED',
                                    P_INVOICE_DATE, --payment cross rate date
                                    current_calling_sequence);

       debug_info := 'P_PAY_CROSS_RATE: '||P_PAY_CROSS_RATE;

       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
       END IF;

       IF ( L_PAY_CROSS_RATE is NOT NULL) THEN
        l_pay_curr_inv_amount := gl_currency_api.convert_amount(
          x_from_currency => P_INV_CURR,
          x_to_currency => L_PAY_CURR,
          x_conversion_date => P_INVOICE_DATE,
          x_conversion_type => 'EMU FIXED',
          x_amount => P_INVOICE_AMOUNT);

  END IF;
      END IF;

     END IF;

END IF;

debug_info := 'P_AMT_APPL_TO_DISC: '||P_AMT_APPL_TO_DISC;

IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
END IF;

IF(P_AMT_APPL_TO_DISC IS NULL)THEN
   L_AMT_APPL_TO_DISC := P_INVOICE_AMOUNT;
ELSE
   L_AMT_APPL_TO_DISC := P_AMT_APPL_TO_DISC;
END IF;

  debug_info := 'Convert discount amount to payment currency';

   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
   END IF;
  L_AMT_APPL_TO_DISC :=  ap_utilities_pkg.ap_round_currency(
                                 L_AMT_APPL_TO_DISC * L_PAY_CROSS_RATE,
                                 L_PAY_CURR);


 debug_info := 'fetch pay currency precision and min acct unit';

   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
   END IF;

BEGIN
    SELECT fc.minimum_accountable_unit,
           fc.precision
      INTO l_min_acc_unit_pay_curr,
           l_precision_pay_curr
      FROM fnd_currencies fc
     WHERE fc.currency_code = L_PAY_CURR;
  EXCEPTION
     WHEN OTHERS THEN
     NULL;
  END;


 OPEN  c_terms_percent;
 FETCH c_terms_percent INTO l_dummy;

IF c_terms_percent%NOTFOUND THEN

 debug_info := 'Terms type is Slab';

 IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
     FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
 END IF;

  debug_info := 'l_pay_curr_inv_amount '||l_pay_curr_inv_amount;

 IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
     FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
 END IF;

 l_remaining_amount := l_pay_curr_inv_amount;

 debug_info := 'l_remaining_amount '||l_remaining_amount;

 IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
     FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
 END IF;

 <<slab_loop>>
    LOOP
      l_sequence_num := l_sequence_num + 1;
      l_old_remaining_amount := l_remaining_amount;

      debug_info := 'l_sequence_num '||l_sequence_num||' l_old_remaining_amount'||l_old_remaining_amount ;

 IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
     FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
 END IF;

      debug_info := 'Open cursor c_amounts';

      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
      END IF;

      OPEN  c_amounts;
      FETCH c_amounts INTO l_invoice_sign
                         , l_sign_due_amount
                         , l_ins_gross_amount
                         , l_sign_remaining_amount
                         , l_remaining_amount
                         , l_calendar ;
     CLOSE c_amounts;

      IF L_INVOICE_TYPE_LOOKUP_CODE in ('CREDIT','DEBIT') THEN
         l_ins_gross_amount := 1 * l_ins_gross_amount;
         l_remaining_amount := -1 * l_remaining_amount;

      END IF;
                                                                         --
      IF (
          (l_sign_remaining_amount <= 0)
          OR
          (l_invoice_sign <= 0)
          OR
          (l_sign_due_amount = 0)
         ) THEN
        l_ins_gross_amount := l_old_remaining_amount;
        l_last_line_flag := TRUE;
      END IF;

                                                                       --
      debug_info := 'Calculate Due Date - terms slab type';

       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
      END IF;

      l_due_date := AP_CREATE_PAY_SCHEDS_PKG.Calc_Due_Date ( l_terms_date,
                                    l_terms_id,
                                    l_calendar,
                                    l_sequence_num,
                                    p_calling_sequence );

      debug_info := 'Insert into ap_payment_schedules';

      i := i + 1;

  debug_info := 'Calculating discount amounts by percent for slab type BEGIN';

   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
      END IF;

  SELECT DECODE(l_min_acc_unit_pay_curr,
  	  NULL, ROUND( l_ins_gross_amount *
             DECODE(l_pay_curr_inv_amount, 0, 0, (l_AMT_APPL_TO_DISC/
                   DECODE(l_pay_curr_inv_amount, 0, 1,
                           l_pay_curr_inv_amount))) *
              NVL(ap_terms_lines.discount_percent,0)/100 ,l_precision_pay_curr),
        	  ROUND(( l_ins_gross_amount *
            DECODE(l_pay_curr_inv_amount, 0, 0,
                   (L_AMT_APPL_TO_DISC/
                    DECODE(l_pay_curr_inv_amount, 0, 1,
                           l_pay_curr_inv_amount))) *
            NVL(ap_terms_lines.discount_percent,0)/100)
            / l_min_acc_unit_pay_curr) * l_min_acc_unit_pay_curr)
        ,	DECODE(l_min_acc_unit_pay_curr,
  	  NULL, ROUND( l_ins_gross_amount *
              DECODE(l_pay_curr_inv_amount, 0, 0,
                   (L_AMT_APPL_TO_DISC/
                    DECODE(l_pay_curr_inv_amount, 0, 1,
                           l_pay_curr_inv_amount))) *
              NVL(ap_terms_lines.discount_percent_2,0)/100 ,l_precision_pay_curr),
        	    ROUND(( l_ins_gross_amount *
              DECODE(l_pay_curr_inv_amount, 0, 0,
                   (P_AMT_APPL_TO_DISC/
                    DECODE(l_pay_curr_inv_amount, 0, 1,
                           l_pay_curr_inv_amount))) *
              NVL(ap_terms_lines.discount_percent_2,0)/100)
              / l_min_acc_unit_pay_curr) * l_min_acc_unit_pay_curr)
        ,	DECODE(l_min_acc_unit_pay_curr,
  	  NULL, ROUND( l_ins_gross_amount *
              DECODE(l_pay_curr_inv_amount, 0, 0,
                   (L_AMT_APPL_TO_DISC/
                    DECODE(l_pay_curr_inv_amount, 0, 1,
                           l_pay_curr_inv_amount))) *
              NVL(ap_terms_lines.discount_percent_3,0)/100 ,l_precision_pay_curr),
              ROUND(( l_ins_gross_amount *
              DECODE(l_pay_curr_inv_amount, 0, 0,
                   (L_AMT_APPL_TO_DISC/
                    DECODE(l_pay_curr_inv_amount, 0, 1,
                           l_pay_curr_inv_amount))) *
              NVL(ap_terms_lines.discount_percent_3,0)/100)
              / l_min_acc_unit_pay_curr) * l_min_acc_unit_pay_curr),
              discount_amount,
              discount_amount_2,
              discount_amount_3
  INTO
           l_disc_amt_by_percent, l_disc_amt_by_percent_2, l_disc_amt_by_percent_3,
           l_discount_amount, l_discount_amount_2, l_discount_amount_3

  FROM 	ap_terms
        ,	ap_terms_lines
  WHERE ap_terms.term_id = ap_terms_lines.term_id
        AND ap_terms_lines.term_id = l_terms_id
        AND ap_terms_lines.sequence_num = l_sequence_num;

  debug_info := 'Making discount amount negative for credit/debit memos';

   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
      END IF;

   IF L_INVOICE_TYPE_LOOKUP_CODE in ('CREDIT','DEBIT') THEN
        l_discount_amount   := -1 * l_discount_amount;
        l_discount_amount_2 := -1 * l_discount_amount_2;
        l_discount_amount_3 := -1 * l_discount_amount_3;
   END IF;


   debug_info := 'Sequence:'|| l_sequence_num ||
                 ' Disc1 by percent:' || l_disc_amt_by_percent ||
                 ' Disc2 by percent:' || l_disc_amt_by_percent_2 ||
                 ' Disc3 by percent:' || l_disc_amt_by_percent_3 ||
                 ' Disc1 by amount:' || l_discount_amount ||
                 ' Disc2 by amount:' || l_discount_amount_2 ||
                 ' Disc3 by amount:' || l_discount_amount_3;

   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL ) THEN
     FND_LOG.STRING(G_LEVEL_STATEMENT, G_MODULE_NAME||l_api_name, debug_info);
   END IF;

  SELECT
             l_sequence_num,
             l_due_date,
             DECODE(ap_terms_lines.discount_days,
	     NULL,
	     DECODE(ap_terms_lines.discount_day_of_month, NULL, NULL,
      	          TO_DATE(TO_CHAR(LEAST(NVL(ap_terms_lines.discount_day_of_month,32),
      	         TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS
      	        (l_terms_date, NVL(ap_terms_lines.discount_months_forward,0) +
      	         DECODE(ap_terms.due_cutoff_day, NULL, 0,
      	          DECODE(GREATEST(LEAST(NVL(ap_terms.due_cutoff_day, 32),
       	          TO_NUMBER(TO_CHAR(LAST_DAY(l_terms_date), 'DD'))),
       	          TO_NUMBER(TO_CHAR(l_terms_date, 'DD'))),
       	          TO_NUMBER(TO_CHAR(l_terms_date, 'DD'))
       	          , 1, 0)))), 'DD')))) || '-' ||
       	          TO_CHAR(ADD_MONTHS(l_terms_date,
       	          NVL(ap_terms_lines.discount_months_forward,0) +
      	          DECODE(ap_terms.due_cutoff_day, NULL, 0,
      	          DECODE(GREATEST(LEAST(NVL(ap_terms.due_cutoff_day, 32),
       	          TO_NUMBER(TO_CHAR(LAST_DAY(l_terms_date),'DD'))),
       	          TO_NUMBER(TO_CHAR(l_terms_date, 'DD'))),
       	          TO_NUMBER(TO_CHAR(l_terms_date, 'DD')), 1, 0))),
		'MON-RR'),'DD-MON-RR')
		      ),
      	      l_terms_date + NVL(ap_terms_lines.discount_days,0)
	      ),

      	DECODE(ap_terms_lines.discount_days_2,
                 NULL,DECODE(ap_terms_lines.discount_day_of_month_2,NULL,NULL,
      	    TO_DATE(TO_CHAR(LEAST
		(NVL(ap_terms_lines.discount_day_of_month_2,32),
      	    TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS(l_terms_date,
      	    NVL(ap_terms_lines.discount_months_forward_2,0) +
      	    DECODE(ap_terms.due_cutoff_day, NULL, 0,
      	    DECODE(GREATEST(LEAST(NVL(ap_terms.due_cutoff_day, 32),
       	      TO_NUMBER(TO_CHAR(LAST_DAY(l_terms_date), 'DD'))),
       	      TO_NUMBER(TO_CHAR(l_terms_date, 'DD'))),
       	      TO_NUMBER(TO_CHAR(l_terms_date, 'DD'))
       	      , 1, 0)))), 'DD')))) || '-' ||
       	    TO_CHAR(ADD_MONTHS(l_terms_date,
       	    NVL(ap_terms_lines.discount_months_forward_2,0) +
      	    DECODE(ap_terms.due_cutoff_day, NULL, 0,
      	    DECODE(GREATEST(LEAST(NVL(ap_terms.due_cutoff_day, 32),
              TO_NUMBER(TO_CHAR(LAST_DAY(l_terms_date),'DD'))),
       	      TO_NUMBER(TO_CHAR(l_terms_date, 'DD'))),
       	      TO_NUMBER(TO_CHAR(l_terms_date, 'DD')), 1, 0))),
		'MON-RR'),'DD-MON-RR')), /*bugfix:5647464 */
       	      l_terms_date + NVL(ap_terms_lines.discount_days_2,0)),

      	DECODE(ap_terms_lines.discount_days_3,
	  NULL, DECODE(ap_terms_lines.discount_day_of_month_3, NULL,
		NULL,
      	    TO_DATE(TO_CHAR(LEAST
		(NVL(ap_terms_lines.discount_day_of_month_3,32),
      	    TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS(l_terms_date,
       	    NVL(ap_terms_lines.discount_months_forward_3,0) +
      	    DECODE(ap_terms.due_cutoff_day, NULL, 0,
      	    DECODE(GREATEST(LEAST(NVL(ap_terms.due_cutoff_day, 32),
       	      TO_NUMBER(TO_CHAR(LAST_DAY(l_terms_date), 'DD'))),
       	      TO_NUMBER(TO_CHAR(l_terms_date, 'DD'))),
       	      TO_NUMBER(TO_CHAR(l_terms_date, 'DD'))
       		, 1, 0)))), 'DD')))) || '-' ||
       	    TO_CHAR(ADD_MONTHS(l_terms_date,
       	    NVL(ap_terms_lines.discount_months_forward_3,0) +
      	    DECODE(ap_terms.due_cutoff_day, NULL, 0,
      	    DECODE(GREATEST(LEAST(NVL(ap_terms.due_cutoff_day, 32),
       	      TO_NUMBER(TO_CHAR(LAST_DAY(l_terms_date),'DD'))),
       	      TO_NUMBER(TO_CHAR(l_terms_date, 'DD'))),
       	      TO_NUMBER(TO_CHAR(l_terms_date, 'DD')), 1, 0))),
		'MON-RR'),'DD-MON-RR')), /*Bug14071766 : M0N to MON */
      	      l_terms_date + NVL(ap_terms_lines.discount_days_3,0)),

        CASE
        WHEN discount_criteria IS NULL OR discount_criteria = 'H' THEN
              CASE WHEN abs(nvl(l_discount_amount,0)) > abs(l_disc_amt_by_percent) THEN
                        l_discount_amount
                   ELSE l_disc_amt_by_percent
              END
        ELSE  CASE WHEN abs(nvl(l_discount_amount,0)) < abs(l_disc_amt_by_percent) THEN
                        l_discount_amount
                   ELSE l_disc_amt_by_percent
              END
        END,
      CASE
         WHEN discount_criteria_2 IS NULL OR discount_criteria_2 = 'H' THEN
              CASE WHEN abs(nvl(l_discount_amount_2,0)) > abs(l_disc_amt_by_percent_2) THEN
                        l_discount_amount_2
                   ELSE l_disc_amt_by_percent_2
              END
        ELSE  CASE WHEN abs(nvl(l_discount_amount_2,0)) < abs(l_disc_amt_by_percent_2) THEN
                        l_discount_amount_2
                   ELSE l_disc_amt_by_percent_2
              END
      END,
      CASE
        WHEN discount_criteria_3 IS NULL OR discount_criteria_3 = 'H' THEN
              CASE WHEN abs(nvl(l_discount_amount_3,0)) > abs(l_disc_amt_by_percent_3) THEN
                        l_discount_amount_3
                   ELSE l_disc_amt_by_percent_3
              END
        ELSE  CASE WHEN abs(nvl(l_discount_amount_3,0)) < abs(l_disc_amt_by_percent_3) THEN
                        l_discount_amount_3
                   ELSE l_disc_amt_by_percent_3
              END
     END
    INTO
    P_SCHDS_REC_LIST(i).payment_num,
    P_SCHDS_REC_LIST(i).due_date,
    P_SCHDS_REC_LIST(i).discount_date,
    P_SCHDS_REC_LIST(i).second_discount_date,
    P_SCHDS_REC_LIST(i).third_discount_date,
    P_SCHDS_REC_LIST(i).discount_amount_available,
    P_SCHDS_REC_LIST(i).second_disc_Amt_available,
    P_SCHDS_REC_LIST(i).third_disc_Amt_available
    FROM 	ap_terms
      , 	ap_terms_lines
      WHERE ap_terms.term_id = ap_terms_lines.term_id
      AND 	ap_terms_lines.term_id = l_terms_id
      AND 	ap_terms_lines.sequence_num = l_sequence_num;

                                                                         --
     IF P_SCHDS_REC_LIST(i).discount_date IS NULL THEN
        P_SCHDS_REC_LIST(i).discount_amount_available := NULL;
      END IF;

      IF P_SCHDS_REC_LIST(i).second_discount_date IS NULL THEN
        P_SCHDS_REC_LIST(i).second_disc_Amt_available := NULL;
      END IF;

      IF P_SCHDS_REC_LIST(i).third_discount_date IS NULL THEN
         P_SCHDS_REC_LIST(i).third_disc_Amt_available := NULL;
      END IF;

      IF (l_last_line_flag = TRUE) THEN
        EXIT;
      END IF;

     END LOOP slab_loop;
                                                                         --
  ELSE
    /* Terms type is Percent */
   debug_info := 'Terms type is Percent';

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL ) THEN
     FND_LOG.STRING(G_LEVEL_STATEMENT, G_MODULE_NAME||l_api_name, debug_info);
    END IF;

      OPEN c_terms;

    LOOP
      FETCH c_terms INTO l_terms_calendar, l_sequence_num;
      EXIT WHEN c_terms%NOTFOUND;

      debug_info := 'Calculate Due Date - terms type is percent';

      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,debug_info);
      END IF;

      l_due_date := AP_CREATE_PAY_SCHEDS_PKG.Calc_Due_Date ( l_terms_date,
                                    l_terms_id,
                                    l_terms_calendar,
                                    l_sequence_num,
                                    p_calling_sequence);


    debug_info := 'Insert into ap_payment_schedules : term type is percent';

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,debug_info);
      END IF;

    i := i + 1;

    debug_info := 'Calculating discount amounts by percent for Percent type BEGIN';

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,debug_info);
      END IF;

    SELECT DECODE(l_min_acc_unit_pay_curr,NULL,
    	  ROUND( L_AMT_APPL_TO_DISC *
            NVL(ap_terms_lines.discount_percent,0)/100 *
            NVL(ap_terms_lines.due_percent, 0)/100, l_precision_pay_curr),
            ROUND(( L_AMT_APPL_TO_DISC *
            NVL(ap_terms_lines.discount_percent,0)/100 *
            NVL(ap_terms_lines.due_percent, 0)/100)
              / l_min_acc_unit_pay_curr)
	    * l_min_acc_unit_pay_curr)
    , DECODE(l_min_acc_unit_pay_curr,NULL,
    	  ROUND( L_AMT_APPL_TO_DISC *
            NVL(ap_terms_lines.discount_percent_2,0)/100 *
            NVL(ap_terms_lines.due_percent, 0)/100, l_precision_pay_curr),
    	  ROUND(( L_AMT_APPL_TO_DISC *
            NVL(ap_terms_lines.discount_percent_2,0)/100 *
            NVL(ap_terms_lines.due_percent, 0)/100)
              / l_min_acc_unit_pay_curr)*l_min_acc_unit_pay_curr)
    , DECODE(l_min_acc_unit_pay_curr,NULL,
    	  ROUND( L_AMT_APPL_TO_DISC *
            NVL(ap_terms_lines.discount_percent_3,0)/100 *
            NVL(ap_terms_lines.due_percent, 0)/100, l_precision_pay_curr),
    	  ROUND(( L_AMT_APPL_TO_DISC *
            NVL(ap_terms_lines.discount_percent_3,0)/100 *
            NVL(ap_terms_lines.due_percent, 0)/100)
              / l_min_acc_unit_pay_curr)*l_min_acc_unit_pay_curr),
              discount_amount,
              discount_amount_2,
              discount_amount_3
  INTO
           l_disc_amt_by_percent, l_disc_amt_by_percent_2, l_disc_amt_by_percent_3,
           l_discount_amount, l_discount_amount_2, l_discount_amount_3

    FROM 	ap_terms,
      	  ap_terms_lines
    WHERE ap_terms.term_id = ap_terms_lines.term_id
    AND 	ap_terms_lines.term_id = l_terms_id
    AND   ap_terms_lines.sequence_num = l_sequence_num;

    IF L_INVOICE_TYPE_LOOKUP_CODE in ('CREDIT','DEBIT') THEN
        l_discount_amount   := -1 * l_discount_amount;
        l_discount_amount_2 := -1 * l_discount_amount_2;
        l_discount_amount_3 := -1 * l_discount_amount_3;
    END IF;


     debug_info := 'Sequence:'|| l_sequence_num ||
                 ' Disc1 by percent:' || l_disc_amt_by_percent ||
                 ' Disc2 by percent:' || l_disc_amt_by_percent_2 ||
                 ' Disc3 by percent:' || l_disc_amt_by_percent_3 ||
                 ' Disc1 by amount:' || l_discount_amount ||
                 ' Disc2 by amount:' || l_discount_amount_2 ||
                 ' Disc3 by amount:' || l_discount_amount_3;

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL ) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT, G_MODULE_NAME||l_api_name, debug_info);
    END IF;

    SELECT l_sequence_num
    , l_due_date
    , DECODE(L_AMT_APPL_TO_DISC, NULL, NULL,
       DECODE(ap_terms_lines.discount_days,
        NULL, DECODE(ap_terms_lines.discount_day_of_month, NULL, NULL,
          TO_DATE(TO_CHAR(LEAST(NVL(ap_terms_lines.discount_day_of_month,32),
    	    TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS
    	    (l_terms_date,
		NVL(ap_terms_lines.discount_months_forward,0) +
    	    DECODE(ap_terms.due_cutoff_day, NULL, 0,
    	    DECODE(GREATEST(LEAST(NVL(ap_terms.due_cutoff_day, 32),
    	     TO_NUMBER(TO_CHAR(LAST_DAY(l_terms_date), 'DD'))),
    	     TO_NUMBER(TO_CHAR(l_terms_date, 'DD'))),
    	     TO_NUMBER(TO_CHAR(l_terms_date, 'DD'))
    	     , 1, 0)))), 'DD')))) || '-' ||
    	     TO_CHAR(ADD_MONTHS(l_terms_date,
    	     NVL(ap_terms_lines.discount_months_forward,0) +
    	    DECODE(ap_terms.due_cutoff_day, NULL, 0,
    	    DECODE(GREATEST(LEAST(NVL(ap_terms.due_cutoff_day, 32),
     	     TO_NUMBER(TO_CHAR(LAST_DAY(l_terms_date),'DD'))),
    	     TO_NUMBER(TO_CHAR(l_terms_date, 'DD'))),
    	     TO_NUMBER(TO_CHAR(l_terms_date, 'DD')), 1, 0))),
		'MON-RR'),'DD-MON-RR')),
    	     l_terms_date + NVL(ap_terms_lines.discount_days,0)))
    , DECODE(L_AMT_APPL_TO_DISC, NULL, NULL,
       DECODE(ap_terms_lines.discount_days_2,
        NULL,DECODE(ap_terms_lines.discount_day_of_month_2,NULL,NULL,
          TO_DATE(TO_CHAR(LEAST(
		NVL(ap_terms_lines.discount_day_of_month_2,32),
    	    TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS(l_terms_date,
    	    NVL(ap_terms_lines.discount_months_forward_2,0) +
    	    DECODE(ap_terms.due_cutoff_day, NULL, 0,
    	    DECODE(GREATEST(LEAST(NVL(ap_terms.due_cutoff_day, 32),
    	     TO_NUMBER(TO_CHAR(LAST_DAY(l_terms_date), 'DD'))),
    	     TO_NUMBER(TO_CHAR(l_terms_date, 'DD'))),
    	     TO_NUMBER(TO_CHAR(l_terms_date, 'DD'))
    	     , 1, 0)))), 'DD')))) || '-' ||
    	     TO_CHAR(ADD_MONTHS(l_terms_date,
    	     NVL(ap_terms_lines.discount_months_forward_2,0) +
    	    DECODE(ap_terms.due_cutoff_day, NULL, 0,
    	    DECODE(GREATEST(LEAST(NVL(ap_terms.due_cutoff_day, 32),
    	     TO_NUMBER(TO_CHAR(LAST_DAY(l_terms_date),'DD'))),
    	     TO_NUMBER(TO_CHAR(l_terms_date, 'DD'))),
    	     TO_NUMBER(TO_CHAR(l_terms_date, 'DD')), 1, 0))),
		'MON-RR'),'DD-MON-RR')),
    	     l_terms_date + NVL(ap_terms_lines.discount_days_2,0)))
    , DECODE(L_AMT_APPL_TO_DISC, NULL, NULL,
       DECODE(ap_terms_lines.discount_days_3,
        NULL,DECODE(ap_terms_lines.discount_day_of_month_3,NULL,NULL,
          TO_DATE(TO_CHAR(LEAST(
		NVL(ap_terms_lines.discount_day_of_month_3,32),
    	    TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS(l_terms_date,
    	     NVL(ap_terms_lines.discount_months_forward_3,0) +
    	    DECODE(ap_terms.due_cutoff_day, NULL, 0,
    	    DECODE(GREATEST(LEAST(NVL(ap_terms.due_cutoff_day, 32),
    	     TO_NUMBER(TO_CHAR(LAST_DAY(l_terms_date), 'DD'))),
    	     TO_NUMBER(TO_CHAR(l_terms_date, 'DD'))),
    	     TO_NUMBER(TO_CHAR(l_terms_date, 'DD'))
    	     , 1, 0)))), 'DD')))) || '-' ||
    		     TO_CHAR(ADD_MONTHS(l_terms_date,
    	     NVL(ap_terms_lines.discount_months_forward_3,0) +
    	    DECODE(ap_terms.due_cutoff_day, NULL, 0,
    	    DECODE(GREATEST(LEAST(NVL(ap_terms.due_cutoff_day, 32),
    	     TO_NUMBER(TO_CHAR(LAST_DAY(l_terms_date),'DD'))),
    	     TO_NUMBER(TO_CHAR(l_terms_date, 'DD'))),
    	     TO_NUMBER(TO_CHAR(l_terms_date, 'DD')), 1, 0))),
		'MON-RR'),'DD-MON-RR')), /*Bug14071766 : M0N to MON */
    	     l_terms_date + NVL(ap_terms_lines.discount_days_3,0)))

,    CASE
        WHEN discount_criteria IS NULL OR discount_criteria = 'H' THEN
              CASE WHEN abs(nvl(l_discount_amount,0)) > abs(l_disc_amt_by_percent) THEN
                        l_discount_amount
                   ELSE l_disc_amt_by_percent
              END
        ELSE  CASE WHEN abs(nvl(l_discount_amount,0)) < abs(l_disc_amt_by_percent) THEN
                        l_discount_amount
                   ELSE l_disc_amt_by_percent
              END
    END,
    CASE
        WHEN discount_criteria_2 IS NULL OR discount_criteria_2 = 'H' THEN
              CASE WHEN abs(nvl(l_discount_amount_2,0)) > abs(l_disc_amt_by_percent_2) THEN
                        l_discount_amount_2
                   ELSE l_disc_amt_by_percent_2
              END
        ELSE  CASE WHEN abs(nvl(l_discount_amount_2,0)) < abs(l_disc_amt_by_percent_2) THEN
                        l_discount_amount_2
                   ELSE l_disc_amt_by_percent_2
              END
    END,
    CASE
        WHEN discount_criteria_3 IS NULL OR discount_criteria_3 = 'H' THEN
              CASE WHEN abs(nvl(l_discount_amount_3,0)) > abs(l_disc_amt_by_percent_3) THEN
                        l_discount_amount_3
                   ELSE l_disc_amt_by_percent_3
              END
        ELSE  CASE WHEN abs(nvl(l_discount_amount_3,0)) < abs(l_disc_amt_by_percent_3) THEN
                        l_discount_amount_3
                   ELSE l_disc_amt_by_percent_3
              END
    END

    INTO
      P_SCHDS_REC_LIST(i).payment_num,
      P_SCHDS_REC_LIST(i).due_date,
       P_SCHDS_REC_LIST(i).discount_date,
    P_SCHDS_REC_LIST(i).second_discount_date,
    P_SCHDS_REC_LIST(i).third_discount_date,
    P_SCHDS_REC_LIST(i).discount_amount_available,
    P_SCHDS_REC_LIST(i).second_disc_Amt_available,
    P_SCHDS_REC_LIST(i).third_disc_Amt_available
    FROM 	ap_terms
    , 	ap_terms_lines
    WHERE 	ap_terms.term_id = ap_terms_lines.term_id
    AND 	ap_terms_lines.term_id = l_terms_id
    AND     ap_terms_lines.sequence_num = l_sequence_num;


     IF P_SCHDS_REC_LIST(i).discount_date IS NULL THEN
        P_SCHDS_REC_LIST(i).discount_amount_available := NULL;
      END IF;

      IF P_SCHDS_REC_LIST(i).second_discount_date IS NULL THEN
        P_SCHDS_REC_LIST(i).second_disc_Amt_available := NULL;
      END IF;

      IF P_SCHDS_REC_LIST(i).third_discount_date IS NULL THEN
         P_SCHDS_REC_LIST(i).third_disc_Amt_available:= NULL;
      END IF;

  END LOOP;

  CLOSE c_terms;

END IF;

  CLOSE c_terms_percent;

RETURN(TRUE);

EXCEPTION
  WHEN OTHERS THEN
      debug_info := 'Exception occured at: '||debug_info;

       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
       END IF;
      IF (SQLCODE <> -20001 ) THEN
	       FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
	       FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
	       FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',current_calling_sequence);
	       FND_MESSAGE.SET_TOKEN('DEBUG_INFO', debug_info );
              APP_EXCEPTION.RAISE_EXCEPTION;
             END IF;
      RETURN(FALSE);
END GET_DISCOUNT_DUE_DATE;

 --End ER#19675818


END AP_UTILITIES_PKG;
/