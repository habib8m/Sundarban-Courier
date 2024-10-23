
CREATE OR REPLACE PACKAGE BODY APPS.XX_GL_PKG
AS
    FUNCTION GET_LEDGER_NAME (P_LEDGER_ID NUMBER)
        RETURN VARCHAR2
    IS
        V_LEDGER_NAME   VARCHAR2 (100);
    BEGIN
        SELECT NAME
          INTO V_LEDGER_NAME
          FROM GL_LEDGERS
         WHERE LEDGER_ID = P_LEDGER_ID;

        RETURN V_LEDGER_NAME;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;



    FUNCTION CREATE_GET_GL_CCID (P_CONCAT_SEGMENTS VARCHAR2)
        RETURN NUMBER
    IS
        LV_CCID        NUMBER;
        LV_STRUCTURE   NUMBER;
    BEGIN
        SELECT ID_FLEX_NUM
          INTO LV_STRUCTURE
          FROM FND_ID_FLEX_STRUCTURES
         WHERE ID_FLEX_CODE = 'GL#' AND ID_FLEX_STRUCTURE_CODE = 'ACCOUNTING_FLEXFIELD';

        LV_CCID :=
            FND_FLEX_EXT.GET_CCID ('SQLGL',
                                   'GL#',
                                   LV_STRUCTURE,
                                   TO_CHAR (SYSDATE, 'DD-MON-YYYY'),
                                   P_CONCAT_SEGMENTS);

        IF LV_CCID <= 0
        THEN
            RAISE_APPLICATION_ERROR (-20101, 'Wrong CCID for ' || P_CONCAT_SEGMENTS);
        ELSE
            RETURN (LV_CCID);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            RAISE_APPLICATION_ERROR (-20101, 'Wrong CCID for ' || P_CONCAT_SEGMENTS);
    END CREATE_GET_GL_CCID;
	
	

    FUNCTION GET_ACCT_FLEX_SEGMENT_DESC (P_SEQUENCE IN NUMBER, P_FLEX_CODE IN VARCHAR2)
        RETURN VARCHAR2
    AS
        V_DESCRIPTION   VARCHAR2 (240);
    BEGIN
        SELECT DESCRIPTION
          INTO V_DESCRIPTION
          FROM FND_FLEX_VALUES_VL
         WHERE     FLEX_VALUE_SET_ID =
								   DECODE (P_SEQUENCE,
										   1, 1016209,
										   2, 1016210,
										   3, 1016211,
										   4, 1016212,
										   5, 1016213,
										   6, 1016214,
										   7, 1016215)
               AND FLEX_VALUE = P_FLEX_CODE;

        RETURN V_DESCRIPTION;
    EXCEPTION
        WHEN OTHERS
        THEN
            RAISE;
    END GET_ACCT_FLEX_SEGMENT_DESC;
	


    PROCEDURE CLEAN_GL_INTERFACE (ERRBUF         OUT NOCOPY VARCHAR2,
                                  RETCODE        OUT NOCOPY NUMBER,
                                  P_USER_ID                 NUMBER,
                                  P_RESP_ID                 NUMBER)
    AS
    BEGIN
        DELETE GL_INTERFACE
         WHERE USER_JE_SOURCE_NAME = 'Spreadsheet';

        COMMIT;
    END CLEAN_GL_INTERFACE;
	
	

    FUNCTION GET_CCID_FROM_CONCAT_SEGMENTS (P_CONCAT_SEGMENTS VARCHAR2)
        RETURN NUMBER
    IS
        V_CCID   NUMBER;
    BEGIN
        V_CCID :=
            FND_FLEX_EXT.GET_CCID ('SQLGL',
                                   'GL#',
                                   101,
                                   TO_CHAR (SYSDATE, 'DD-MON-YYYY'),
                                   P_CONCAT_SEGMENTS);

        RETURN (V_CCID);

        FND_FILE.PUT_LINE (FND_FILE.OUTPUT, 'CCID RETURN: ' || V_CCID);
    EXCEPTION
        WHEN OTHERS
        THEN
            FND_FILE.PUT_LINE (FND_FILE.OUTPUT, 'DEBUG ERROR: ' || SQLERRM);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'ERROR: ' || SQLERRM);
    END GET_CCID_FROM_CONCAT_SEGMENTS;



    FUNCTION GET_GL_BALANCE (P_ACTIVITY        IN VARCHAR2,
                             P_LEDGER_ID       IN NUMBER,
                             P_CURRENCY_CODE   IN VARCHAR2,
                             P_PERIOD_FROM     IN NUMBER,
                             P_PERIOD_TO       IN NUMBER,
                             P_COMPANY         IN VARCHAR2,
                             P_ACCOUNT_FROM    IN VARCHAR2,
                             P_ACCOUNT_TO      IN VARCHAR2)
        RETURN NUMBER
    AS
        V_OUTPUT   VARCHAR2 (4000);
    BEGIN
        WITH
            XX_WITH_CLAUSE_TAB
            AS
                (SELECT 'BEGIN_BALANCE' ACTIVITY,
                        SUM (NVL (BAL.BEGIN_BALANCE_DR, 0) - NVL (BAL.BEGIN_BALANCE_CR, 0)) AMOUNT
                   FROM GL_BALANCES BAL, GL_CODE_COMBINATIONS GCC, GL_PERIOD_STATUSES GPS
                  WHERE     BAL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                        AND BAL.LEDGER_ID = GPS.LEDGER_ID
                        AND BAL.PERIOD_NAME = GPS.PERIOD_NAME
                        AND GCC.TEMPLATE_ID IS NULL
                        AND GPS.APPLICATION_ID = 101
                        AND BAL.ACTUAL_FLAG = 'A'
                        AND GCC.SUMMARY_FLAG = 'N'
                        AND BAL.LEDGER_ID = P_LEDGER_ID
                        AND BAL.CURRENCY_CODE = P_CURRENCY_CODE
                        AND GPS.EFFECTIVE_PERIOD_NUM = P_PERIOD_FROM
                        AND GCC.SEGMENT1 = P_COMPANY
                        AND GCC.SEGMENT4 BETWEEN P_ACCOUNT_FROM AND P_ACCOUNT_TO
                 UNION ALL
                 SELECT 'PERIOD_NET',
                        (SUM (NVL (BAL.PERIOD_NET_DR, 0) - NVL (BAL.PERIOD_NET_CR, 0)))
                   FROM GL_BALANCES BAL, GL_CODE_COMBINATIONS GCC, GL_PERIOD_STATUSES GPS
                  WHERE     BAL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                        AND BAL.LEDGER_ID = GPS.LEDGER_ID
                        AND BAL.PERIOD_NAME = GPS.PERIOD_NAME
                        AND GCC.TEMPLATE_ID IS NULL
                        AND GPS.APPLICATION_ID = 101
                        AND BAL.ACTUAL_FLAG = 'A'
                        AND GCC.SUMMARY_FLAG = 'N'
                        AND BAL.LEDGER_ID = P_LEDGER_ID
                        AND BAL.CURRENCY_CODE = P_CURRENCY_CODE
                        AND GPS.EFFECTIVE_PERIOD_NUM >= P_PERIOD_FROM
                        AND GPS.EFFECTIVE_PERIOD_NUM <= P_PERIOD_TO
                        AND GCC.SEGMENT1 = P_COMPANY
                        AND GCC.SEGMENT4 BETWEEN P_ACCOUNT_FROM AND P_ACCOUNT_TO
                 UNION ALL
                   SELECT 'END_BALANCE', SUM (BEGIN_BALANCE) + SUM (PERIOD_NET)
                     FROM (  SELECT GCC.SEGMENT4 ACCOUNT,
                                    SUM (NVL (BAL.BEGIN_BALANCE_DR, 0) - NVL (BAL.BEGIN_BALANCE_CR, 0)) BEGIN_BALANCE,
                                    0 PERIOD_NET
                               FROM GL_BALANCES BAL, GL_CODE_COMBINATIONS GCC, GL_PERIOD_STATUSES GPS
                              WHERE     BAL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                                    AND BAL.LEDGER_ID = GPS.LEDGER_ID
                                    AND BAL.PERIOD_NAME = GPS.PERIOD_NAME
                                    AND GCC.TEMPLATE_ID IS NULL
                                    AND GPS.APPLICATION_ID = 101
                                    AND BAL.ACTUAL_FLAG = 'A'
                                    AND GCC.SUMMARY_FLAG = 'N'
                                    AND BAL.LEDGER_ID = P_LEDGER_ID
                                    AND BAL.CURRENCY_CODE = P_CURRENCY_CODE
                                    AND GPS.EFFECTIVE_PERIOD_NUM = P_PERIOD_FROM
                                    AND GCC.SEGMENT1 = P_COMPANY
                                    AND GCC.SEGMENT4 BETWEEN P_ACCOUNT_FROM AND P_ACCOUNT_TO
                           GROUP BY GCC.SEGMENT4
                           UNION ALL
                             SELECT GCC.SEGMENT4 ACCOUNT,
                                    0 BEGIN_BALANCE,
                                    (SUM (NVL (BAL.PERIOD_NET_DR, 0) - NVL (BAL.PERIOD_NET_CR, 0))) PERIOD_NET
                               FROM GL_BALANCES BAL, GL_CODE_COMBINATIONS GCC, GL_PERIOD_STATUSES GPS
                              WHERE     BAL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                                    AND BAL.LEDGER_ID = GPS.LEDGER_ID
                                    AND BAL.PERIOD_NAME = GPS.PERIOD_NAME
                                    AND GCC.TEMPLATE_ID IS NULL
                                    AND GPS.APPLICATION_ID = 101
                                    AND BAL.ACTUAL_FLAG = 'A'
                                    AND GCC.SUMMARY_FLAG = 'N'
                                    AND BAL.LEDGER_ID = P_LEDGER_ID
                                    AND BAL.CURRENCY_CODE = P_CURRENCY_CODE
                                    AND GPS.EFFECTIVE_PERIOD_NUM >= P_PERIOD_FROM
                                    AND GPS.EFFECTIVE_PERIOD_NUM <= P_PERIOD_TO
                                    AND GCC.SEGMENT1 = P_COMPANY
                                    AND GCC.SEGMENT4 BETWEEN P_ACCOUNT_FROM AND P_ACCOUNT_TO
                           GROUP BY GCC.SEGMENT4)
                 GROUP BY ACCOUNT)
        SELECT SUM (AMOUNT)
          INTO V_OUTPUT
          FROM XX_WITH_CLAUSE_TAB
         WHERE ACTIVITY =
               (CASE
                    WHEN P_ACTIVITY = 'B' THEN 'BEGIN_BALANCE'
                    WHEN P_ACTIVITY = 'P' THEN 'PERIOD_NET'
                    WHEN P_ACTIVITY = 'E' THEN 'END_BALANCE'
                    ELSE NULL
                END);

        RETURN V_OUTPUT;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_GL_BALANCE;



    PROCEDURE INSERT_INFO_TB (P_LEDGER_ID       IN NUMBER,
                              P_COMPANY         IN NUMBER,
                              P_CURRENCY_CODE   IN VARCHAR2,
                              P_PERIOD_FROM     IN NUMBER,
                              P_PERIOD_TO       IN NUMBER,
                              P_PROCESS_MODE    IN VARCHAR2)
    AS
    BEGIN
        DECLARE
            P_DATE_FROM   DATE;
            P_DATE_TO     DATE;
        BEGIN
            SELECT START_DATE
              INTO P_DATE_FROM
              FROM GL_PERIOD_STATUSES
             WHERE     APPLICATION_ID = 101
                   AND SET_OF_BOOKS_ID = P_LEDGER_ID
                   AND EFFECTIVE_PERIOD_NUM = P_PERIOD_FROM;

            SELECT END_DATE
              INTO P_DATE_TO
              FROM GL_PERIOD_STATUSES
             WHERE     APPLICATION_ID = 101
                   AND SET_OF_BOOKS_ID = P_LEDGER_ID
                   AND EFFECTIVE_PERIOD_NUM = P_PERIOD_TO;

            IF P_PROCESS_MODE = 'D'
            THEN
                INSERT INTO XX_FINANCIAL_STATEMENT_GT (ACCOUNT,
                                                       DESCRIPTION,
                                                       BEGINNING,
                                                       DEBITS,
                                                       CREDITS)
                    WITH
                        XX_WITH_CLAUSE_TAB
                        AS
                            (  SELECT TBD.COMPANY,
                                      TBD.ACCOUNT,
                                      TBD.DESCRIPTION,
                                      SUM (NVL (TBD.ACCOUNTED_DR, 0) - NVL (TBD.ACCOUNTED_CR, 0)) BEGIN_BALANCE,
                                      0 PERIOD_DR,
                                      0 PERIOD_CR
                                 FROM XX_TRIAL_BALANCE_DRAFT_V TBD
                                WHERE     TBD.LEDGER_ID = P_LEDGER_ID
                                      AND (CASE
                                               WHEN     P_COMPANY = 100
                                                    AND TBD.COMPANY BETWEEN 101 AND 599
                                               THEN
                                                   1
                                               WHEN     P_COMPANY BETWEEN 101 AND 599
                                                    AND TBD.COMPANY = P_COMPANY
                                               THEN
                                                   1
                                               ELSE
                                                   NULL
                                           END) =
                                          1
                                      AND TBD.ACCOUNTING_DATE < P_DATE_FROM
                             GROUP BY TBD.COMPANY, TBD.ACCOUNT, TBD.DESCRIPTION
                             UNION ALL
                               SELECT TBD.COMPANY,
                                      TBD.ACCOUNT,
                                      TBD.DESCRIPTION,
                                      0 BEGIN_BALANCE,
                                      SUM (NVL (TBD.ACCOUNTED_DR, 0))     PERIOD_DR,
                                      SUM (NVL (TBD.ACCOUNTED_CR, 0))     PERIOD_CR
                                 FROM XX_TRIAL_BALANCE_DRAFT_V TBD
                                WHERE     TBD.LEDGER_ID = P_LEDGER_ID
                                      AND (CASE
                                               WHEN     P_COMPANY = 100
                                                    AND TBD.COMPANY BETWEEN 101 AND 599
                                               THEN
                                                   1
                                               WHEN     P_COMPANY BETWEEN 101 AND 599
                                                    AND TBD.COMPANY = P_COMPANY
                                               THEN
                                                   1
                                               ELSE
                                                   NULL
                                           END) =
                                          1
                                      AND TBD.ACCOUNTING_DATE >= P_DATE_FROM
                                      AND TBD.ACCOUNTING_DATE <= P_DATE_TO
                             GROUP BY TBD.COMPANY, TBD.ACCOUNT, TBD.DESCRIPTION)
                    SELECT ACCOUNT,
                           DESCRIPTION,
                           BEGIN_BALANCE,
                           PERIOD_DR,
                           PERIOD_CR
                      FROM XX_WITH_CLAUSE_TAB;
            ELSE
                INSERT INTO XX_FINANCIAL_STATEMENT_GT (ACCOUNT,
                                                       DESCRIPTION,
                                                       BEGINNING,
                                                       DEBITS,
                                                       CREDITS)
                    WITH
                        XX_WITH_CLAUSE_TAB
                        AS
                            (  SELECT GCC.SEGMENT4 ACCOUNT,
                                      SUM (
                                            NVL (BAL.BEGIN_BALANCE_DR, 0)
                                          - NVL (BAL.BEGIN_BALANCE_CR, 0)) BEGIN_BALANCE,
                                      0 PERIOD_DR,
                                      0 PERIOD_CR
                                 FROM GL_BALANCES         BAL,
                                      GL_CODE_COMBINATIONS GCC,
                                      GL_PERIOD_STATUSES  GPS
                                WHERE     BAL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                                      AND BAL.LEDGER_ID = GPS.LEDGER_ID
                                      AND BAL.PERIOD_NAME = GPS.PERIOD_NAME
                                      AND GCC.TEMPLATE_ID IS NULL
                                      AND GPS.APPLICATION_ID = 101
                                      AND BAL.ACTUAL_FLAG = 'A'
                                      AND GCC.SUMMARY_FLAG = 'N'
                                      AND BAL.LEDGER_ID = P_LEDGER_ID
                                      AND BAL.CURRENCY_CODE = P_CURRENCY_CODE
                                      AND GPS.EFFECTIVE_PERIOD_NUM = P_PERIOD_FROM
                                      AND (CASE
                                               WHEN     P_COMPANY = 100
                                                    AND GCC.SEGMENT1 BETWEEN 101 AND 599
                                               THEN
                                                   1
                                               WHEN     P_COMPANY BETWEEN 101 AND 599
                                                    AND GCC.SEGMENT1 = P_COMPANY
                                               THEN
                                                   1
                                               ELSE
                                                   NULL
                                           END) =
                                          1
                             GROUP BY GCC.SEGMENT4
                               HAVING    SUM (
                                               NVL (BAL.BEGIN_BALANCE_DR, 0)
                                             - NVL (BAL.BEGIN_BALANCE_CR, 0)) <>
                                         0
                                      OR SUM (BAL.PERIOD_NET_DR) <> 0
                                      OR SUM (BAL.PERIOD_NET_CR) <> 0
                             UNION ALL
                               SELECT GCC.SEGMENT4
                                          ACCOUNT,
                                      0 BEGIN_BALANCE,
                                      NVL (SUM (DECODE (PERIOD_NET_DR, 0, NULL, PERIOD_NET_DR)), 0)
                                          PERIOD_DR,
                                      NVL (SUM (DECODE (PERIOD_NET_CR, 0, NULL, PERIOD_NET_CR)), 0)
                                          PERIOD_CR
                                 FROM GL_BALANCES         BAL,
                                      GL_CODE_COMBINATIONS GCC,
                                      GL_PERIOD_STATUSES  GPS
                                WHERE     BAL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                                      AND BAL.LEDGER_ID = GPS.LEDGER_ID
                                      AND BAL.PERIOD_NAME = GPS.PERIOD_NAME
                                      AND GCC.TEMPLATE_ID IS NULL
                                      AND GPS.APPLICATION_ID = 101
                                      AND BAL.ACTUAL_FLAG = 'A'
                                      AND GCC.SUMMARY_FLAG = 'N'
                                      AND BAL.LEDGER_ID = P_LEDGER_ID
                                      AND BAL.CURRENCY_CODE = P_CURRENCY_CODE
                                      AND GPS.EFFECTIVE_PERIOD_NUM >= P_PERIOD_FROM
                                      AND GPS.EFFECTIVE_PERIOD_NUM <= P_PERIOD_TO
                                      AND (CASE
                                               WHEN     P_COMPANY = 100
                                                    AND GCC.SEGMENT1 BETWEEN 101 AND 599
                                               THEN
                                                   1
                                               WHEN     P_COMPANY BETWEEN 101 AND 599
                                                    AND GCC.SEGMENT1 = P_COMPANY
                                               THEN
                                                   1
                                               ELSE
                                                   NULL
                                           END) =
                                          1
                             GROUP BY GCC.SEGMENT4
                               HAVING    SUM (
                                               NVL (BAL.BEGIN_BALANCE_DR, 0)
                                             - NVL (BAL.BEGIN_BALANCE_CR, 0)) <>
                                         0
                                      OR SUM (BAL.PERIOD_NET_DR) <> 0
                                      OR SUM (BAL.PERIOD_NET_CR) <> 0)
                      SELECT ACCOUNT,
                             XX_COM_PKG.GET_FLEX_VALUES_FROM_FLEX_ID (ACCOUNT, 4)     DESCRIPTION,
                             SUM (BEGIN_BALANCE)                                      BEGINNING,
                             SUM (PERIOD_DR)                                          PERIOD_DR,
                             SUM (PERIOD_CR)                                          PERIOD_CR
                        FROM XX_WITH_CLAUSE_TAB
                    GROUP BY ACCOUNT;
            END IF;
        END;
    END INSERT_INFO_TB;
	


    PROCEDURE INSERT_INFO_BS (P_LEDGER_ID         IN NUMBER,
                              P_COMPANY           IN NUMBER,
                              P_CURRENCY_CODE     IN VARCHAR2,
                              P_CURRENT_PERIOD    IN NUMBER,
                              P_PREVIOUS_PERIOD   IN NUMBER,
                              P_PROCESS_MODE      IN VARCHAR2)
    AS
    BEGIN
        DECLARE
            P_CURRENT_DATE    DATE;
            P_PREVIOUS_DATE   DATE;
        BEGIN
            SELECT END_DATE
              INTO P_CURRENT_DATE
              FROM GL_PERIOD_STATUSES
             WHERE     APPLICATION_ID = 101
                   AND SET_OF_BOOKS_ID = P_LEDGER_ID
                   AND EFFECTIVE_PERIOD_NUM = P_CURRENT_PERIOD;

            SELECT END_DATE
              INTO P_PREVIOUS_DATE
              FROM GL_PERIOD_STATUSES
             WHERE     APPLICATION_ID = 101
                   AND SET_OF_BOOKS_ID = P_LEDGER_ID
                   AND EFFECTIVE_PERIOD_NUM = P_PREVIOUS_PERIOD;

            INSERT INTO XX_FINANCIAL_STATEMENT_GT (SL,
                                                   ORD,
                                                   DESCRIPTION,
                                                   NOTES,
                                                   CURRENT_PERIOD,
                                                   PREVIOUS_PERIOD)
                  SELECT TO_NUMBER (SUBSTR (SL, 1, 1))     SL,
                         TO_NUMBER (SUBSTR (SL, 2, 2))     ORD,
                         DESCRIPTION,
                         NOTES,
                         SUM (CURRENT_PERIOD)              CURRENT_PERIOD,
                         SUM (PREVIOUS_PERIOD)             PREVIOUS_PERIOD
                    FROM (  SELECT RRA.AXIS_SEQ
                                       SL,
                                   RRA.DESCRIPTION,
                                   RRA.ATTRIBUTE1
                                       NOTES,
                                     (CASE WHEN RRA.CHANGE_SIGN_FLAG = 'Y' THEN -1 ELSE 1 END)
                                   * (SUM (
                                            (CASE WHEN SIGN = '-' THEN -1 ELSE 1 END)
                                          * (NVL (TBD.ACCOUNTED_DR, 0) - NVL (TBD.ACCOUNTED_CR, 0))))
                                       CURRENT_PERIOD,
                                   0
                                       PREVIOUS_PERIOD
                              FROM XX_TRIAL_BALANCE_DRAFT_V TBD,
                                   RG_REPORT_AXES        RRA,
                                   RG_REPORT_AXIS_CONTENTS RAC
                             WHERE     RRA.AXIS_SET_ID = RAC.AXIS_SET_ID
                                   AND RRA.AXIS_SEQ = RAC.AXIS_SEQ
                                   AND TBD.ACCOUNT BETWEEN NVL (RAC.SEGMENT4_LOW, TBD.ACCOUNT)
                                                       AND NVL (RAC.SEGMENT4_HIGH, TBD.ACCOUNT)
                                   AND RRA.AXIS_SET_ID = 1000
                                   AND TBD.LEDGER_ID = P_LEDGER_ID
                                   AND (CASE
                                            WHEN P_COMPANY = 100 AND TBD.COMPANY BETWEEN 101 AND 599
                                            THEN
                                                1
                                            WHEN     P_COMPANY BETWEEN 101 AND 599
                                                 AND TBD.COMPANY = P_COMPANY
                                            THEN
                                                1
                                            ELSE
                                                NULL
                                        END) =
                                       1
                                   AND TRUNC (TBD.ACCOUNTING_DATE) <= P_CURRENT_DATE
                          GROUP BY RRA.AXIS_SEQ,
                                   RRA.DESCRIPTION,
                                   RRA.ATTRIBUTE1,
                                   RRA.CHANGE_SIGN_FLAG
                          UNION ALL
                            SELECT RRA.AXIS_SEQ                                                          SL,
                                   RRA.DESCRIPTION,
                                   RRA.ATTRIBUTE1                                                        NOTES,
                                   0                                                                     CURRENT_PERIOD,
                                     (CASE WHEN RRA.CHANGE_SIGN_FLAG = 'Y' THEN -1 ELSE 1 END)
                                   * (SUM (
                                            (CASE WHEN SIGN = '-' THEN -1 ELSE 1 END)
                                          * (NVL (TBD.ACCOUNTED_DR, 0) - NVL (TBD.ACCOUNTED_CR, 0))))    PREVIOUS_PERIOD
                              FROM XX_TRIAL_BALANCE_DRAFT_V TBD,
                                   RG_REPORT_AXES        RRA,
                                   RG_REPORT_AXIS_CONTENTS RAC
                             WHERE     RRA.AXIS_SET_ID = RAC.AXIS_SET_ID
                                   AND RRA.AXIS_SEQ = RAC.AXIS_SEQ
                                   AND TBD.ACCOUNT BETWEEN NVL (RAC.SEGMENT4_LOW, TBD.ACCOUNT)
                                                       AND NVL (RAC.SEGMENT4_HIGH, TBD.ACCOUNT)
                                   AND RRA.AXIS_SET_ID = 1000
                                   AND TBD.LEDGER_ID = P_LEDGER_ID
                                   AND (CASE
                                            WHEN P_COMPANY = 100 AND TBD.COMPANY BETWEEN 101 AND 599
                                            THEN
                                                1
                                            WHEN     P_COMPANY BETWEEN 101 AND 599
                                                 AND TBD.COMPANY = P_COMPANY
                                            THEN
                                                1
                                            ELSE
                                                NULL
                                        END) =
                                       1
                                   AND TRUNC (TBD.ACCOUNTING_DATE) <= P_PREVIOUS_DATE
                          GROUP BY RRA.AXIS_SEQ,
                                   RRA.DESCRIPTION,
                                   RRA.ATTRIBUTE1,
                                   RRA.CHANGE_SIGN_FLAG
                          UNION ALL
                          SELECT RRA.AXIS_SEQ       SL,
                                 RRA.DESCRIPTION,
                                 RRA.ATTRIBUTE1     NOTES,
                                 0,
                                 0
                            FROM RG_REPORT_AXES RRA
                           WHERE RRA.AXIS_SET_ID = 1000 AND DISPLAY_ZERO_AMOUNT_FLAG = 'Y')
                   WHERE P_PROCESS_MODE = 'D'
                GROUP BY SL, DESCRIPTION, NOTES;

            -- Final
            INSERT INTO XX_FINANCIAL_STATEMENT_GT (SL,
                                                   ORD,
                                                   DESCRIPTION,
                                                   NOTES,
                                                   CURRENT_PERIOD,
                                                   PREVIOUS_PERIOD)
                WITH
                    XX_WITH_CLAUSE_TAB
                    AS
                        (  SELECT RRA.AXIS_SEQ                                     SL,
                                  RRA.DESCRIPTION,
                                  RRA.ATTRIBUTE1                                   NOTES,
                                    (CASE WHEN RRA.CHANGE_SIGN_FLAG = 'Y' THEN -1 ELSE 1 END)
                                  * (SUM (
                                           (CASE WHEN SIGN = '-' THEN -1 ELSE 1 END)
                                         * (  (  NVL (BAL.BEGIN_BALANCE_DR, 0)
                                               - NVL (BAL.BEGIN_BALANCE_CR, 0))
                                            + (  NVL (BAL.PERIOD_NET_DR, 0)
                                               - NVL (BAL.PERIOD_NET_CR, 0)))))    CURRENT_PERIOD,
                                  0                                                PREVIOUS_PERIOD
                             FROM GL_BALANCES            BAL,
                                  GL_CODE_COMBINATIONS   GCC,
                                  GL_PERIOD_STATUSES     GPS,
                                  RG_REPORT_AXES         RRA,
                                  RG_REPORT_AXIS_CONTENTS RAC
                            WHERE     BAL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                                  AND BAL.LEDGER_ID = GPS.LEDGER_ID
                                  AND BAL.PERIOD_NAME = GPS.PERIOD_NAME
                                  AND RRA.AXIS_SET_ID = RAC.AXIS_SET_ID
                                  AND RRA.AXIS_SEQ = RAC.AXIS_SEQ
                                  AND GCC.TEMPLATE_ID IS NULL
                                  AND GPS.APPLICATION_ID = 101
                                  AND BAL.ACTUAL_FLAG = 'A'
                                  AND GCC.SUMMARY_FLAG = 'N'
                                  AND BAL.LEDGER_ID = P_LEDGER_ID
                                  AND BAL.CURRENCY_CODE = 'BDT'
                                  AND RRA.AXIS_SET_ID = 1000
                                  AND GPS.EFFECTIVE_PERIOD_NUM = P_CURRENT_PERIOD
                                  AND (CASE
                                           WHEN P_COMPANY = 100 AND GCC.SEGMENT1 BETWEEN 101 AND 599
                                           THEN
                                               1
                                           WHEN     P_COMPANY BETWEEN 101 AND 599
                                                AND GCC.SEGMENT1 = P_COMPANY
                                           THEN
                                               1
                                           ELSE
                                               NULL
                                       END) =
                                      1
                                  AND GCC.SEGMENT2 BETWEEN NVL (RAC.SEGMENT2_LOW, GCC.SEGMENT2)
                                                       AND NVL (RAC.SEGMENT2_HIGH, GCC.SEGMENT2)
                                  AND GCC.SEGMENT3 BETWEEN NVL (RAC.SEGMENT3_LOW, GCC.SEGMENT3)
                                                       AND NVL (RAC.SEGMENT3_HIGH, GCC.SEGMENT3)
                                  AND GCC.SEGMENT4 BETWEEN NVL (RAC.SEGMENT4_LOW, GCC.SEGMENT4)
                                                       AND NVL (RAC.SEGMENT4_HIGH, GCC.SEGMENT4)
                                  AND GCC.SEGMENT5 BETWEEN NVL (RAC.SEGMENT5_LOW, GCC.SEGMENT5)
                                                       AND NVL (RAC.SEGMENT5_HIGH, GCC.SEGMENT5)
                                  AND GCC.SEGMENT6 BETWEEN NVL (RAC.SEGMENT6_LOW, GCC.SEGMENT6)
                                                       AND NVL (RAC.SEGMENT6_HIGH, GCC.SEGMENT6)
                         GROUP BY RRA.AXIS_SEQ,
                                  RRA.DESCRIPTION,
                                  RRA.ATTRIBUTE1,
                                  RRA.CHANGE_SIGN_FLAG
                         UNION ALL
                           SELECT RRA.AXIS_SEQ                                     SL,
                                  RRA.DESCRIPTION,
                                  RRA.ATTRIBUTE1                                   NOTES,
                                  0                                                CURRENT_PERIOD,
                                    (CASE WHEN RRA.CHANGE_SIGN_FLAG = 'Y' THEN -1 ELSE 1 END)
                                  * (SUM (
                                           (CASE WHEN SIGN = '-' THEN -1 ELSE 1 END)
                                         * (  (  NVL (BAL.BEGIN_BALANCE_DR, 0)
                                               - NVL (BAL.BEGIN_BALANCE_CR, 0))
                                            + (  NVL (BAL.PERIOD_NET_DR, 0)
                                               - NVL (BAL.PERIOD_NET_CR, 0)))))    PREVIOUS_PERIOD
                             FROM GL_BALANCES            BAL,
                                  GL_CODE_COMBINATIONS   GCC,
                                  GL_PERIOD_STATUSES     GPS,
                                  RG_REPORT_AXES         RRA,
                                  RG_REPORT_AXIS_CONTENTS RAC
                            WHERE     BAL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                                  AND BAL.LEDGER_ID = GPS.LEDGER_ID
                                  AND BAL.PERIOD_NAME = GPS.PERIOD_NAME
                                  AND RRA.AXIS_SET_ID = RAC.AXIS_SET_ID
                                  AND RRA.AXIS_SEQ = RAC.AXIS_SEQ
                                  AND GCC.TEMPLATE_ID IS NULL
                                  AND GPS.APPLICATION_ID = 101
                                  AND BAL.ACTUAL_FLAG = 'A'
                                  AND GCC.SUMMARY_FLAG = 'N'
                                  AND BAL.LEDGER_ID = P_LEDGER_ID
                                  AND BAL.CURRENCY_CODE = 'BDT'
                                  AND RRA.AXIS_SET_ID = 1000
                                  AND GPS.EFFECTIVE_PERIOD_NUM = P_PREVIOUS_PERIOD
                                  AND (CASE
                                           WHEN P_COMPANY = 100 AND GCC.SEGMENT1 BETWEEN 101 AND 599
                                           THEN
                                               1
                                           WHEN     P_COMPANY BETWEEN 101 AND 599
                                                AND GCC.SEGMENT1 = P_COMPANY
                                           THEN
                                               1
                                           ELSE
                                               NULL
                                       END) =
                                      1
                                  AND GCC.SEGMENT2 BETWEEN NVL (RAC.SEGMENT2_LOW, GCC.SEGMENT2)
                                                       AND NVL (RAC.SEGMENT2_HIGH, GCC.SEGMENT2)
                                  AND GCC.SEGMENT3 BETWEEN NVL (RAC.SEGMENT3_LOW, GCC.SEGMENT3)
                                                       AND NVL (RAC.SEGMENT3_HIGH, GCC.SEGMENT3)
                                  AND GCC.SEGMENT4 BETWEEN NVL (RAC.SEGMENT4_LOW, GCC.SEGMENT4)
                                                       AND NVL (RAC.SEGMENT4_HIGH, GCC.SEGMENT4)
                                  AND GCC.SEGMENT5 BETWEEN NVL (RAC.SEGMENT5_LOW, GCC.SEGMENT5)
                                                       AND NVL (RAC.SEGMENT5_HIGH, GCC.SEGMENT5)
                                  AND GCC.SEGMENT6 BETWEEN NVL (RAC.SEGMENT6_LOW, GCC.SEGMENT6)
                                                       AND NVL (RAC.SEGMENT6_HIGH, GCC.SEGMENT6)
                         GROUP BY RRA.AXIS_SEQ,
                                  RRA.DESCRIPTION,
                                  RRA.ATTRIBUTE1,
                                  RRA.CHANGE_SIGN_FLAG
                         UNION ALL
                         SELECT RRA.AXIS_SEQ       SL,
                                RRA.DESCRIPTION,
                                RRA.ATTRIBUTE1     NOTES,
                                0,
                                0
                           FROM RG_REPORT_AXES RRA
                          WHERE RRA.AXIS_SET_ID = 1000 AND DISPLAY_ZERO_AMOUNT_FLAG = 'Y')
                  SELECT TO_NUMBER (SUBSTR (SL, 1, 1))     SL,
                         TO_NUMBER (SUBSTR (SL, 2, 2))     ORD,
                         DESCRIPTION,
                         NOTES,
                         SUM (CURRENT_PERIOD)              CURRENT_PERIOD,
                         SUM (PREVIOUS_PERIOD)             PREVIOUS_PERIOD
                    FROM XX_WITH_CLAUSE_TAB
                   WHERE P_PROCESS_MODE = 'F'
                GROUP BY SL, DESCRIPTION, NOTES;
        END;
    END;

    PROCEDURE INSERT_INFO_BSN (P_LEDGER_ID         IN NUMBER,
                               P_COMPANY           IN NUMBER,
                               P_CURRENCY_CODE     IN VARCHAR2,
                               P_CURRENT_PERIOD    IN NUMBER,
                               P_PREVIOUS_PERIOD   IN NUMBER,
                               P_PROCESS_MODE      IN VARCHAR2)
    AS
    BEGIN
        DECLARE
            P_CURRENT_DATE    DATE;
            P_PREVIOUS_DATE   DATE;
        BEGIN
            SELECT END_DATE
              INTO P_CURRENT_DATE
              FROM GL_PERIOD_STATUSES
             WHERE     APPLICATION_ID = 101
                   AND SET_OF_BOOKS_ID = P_LEDGER_ID
                   AND EFFECTIVE_PERIOD_NUM = P_CURRENT_PERIOD;

            SELECT END_DATE
              INTO P_PREVIOUS_DATE
              FROM GL_PERIOD_STATUSES
             WHERE     APPLICATION_ID = 101
                   AND SET_OF_BOOKS_ID = P_LEDGER_ID
                   AND EFFECTIVE_PERIOD_NUM = P_PREVIOUS_PERIOD;

            INSERT INTO XX_FINANCIAL_STATEMENT_GT (ORD,
                                                   NOTES,
                                                   NOTES_NAME,
                                                   ACCOUNT,
                                                   DESCRIPTION,
                                                   CURRENT_PERIOD,
                                                   PREVIOUS_PERIOD)
                  SELECT TO_NUMBER (NOTES)         ORD,
                         NOTES,
                         NOTES_NAME,
                         ACCOUNT,
                         DESCRIPTION,
                         SUM (CURRENT_PERIOD)      CURRENT_PERIOD,
                         SUM (PREVIOUS_PERIOD)     PREVIOUS_PERIOD
                    FROM (  SELECT RRA.ATTRIBUTE1
                                       NOTES,
                                   RRA.DESCRIPTION
                                       NOTES_NAME,
                                   TBD.ACCOUNT,
                                   TBD.DESCRIPTION,
                                     (CASE WHEN RRA.CHANGE_SIGN_FLAG = 'Y' THEN -1 ELSE 1 END)
                                   * (SUM (
                                            (CASE WHEN SIGN = '-' THEN -1 ELSE 1 END)
                                          * (NVL (TBD.ACCOUNTED_DR, 0) - NVL (TBD.ACCOUNTED_CR, 0))))
                                       CURRENT_PERIOD,
                                   0
                                       PREVIOUS_PERIOD
                              FROM XX_TRIAL_BALANCE_DRAFT_V TBD,
                                   RG_REPORT_AXES        RRA,
                                   RG_REPORT_AXIS_CONTENTS RAC
                             WHERE     RRA.AXIS_SET_ID = RAC.AXIS_SET_ID
                                   AND RRA.AXIS_SEQ = RAC.AXIS_SEQ
                                   AND TBD.ACCOUNT BETWEEN NVL (RAC.SEGMENT4_LOW, TBD.ACCOUNT)
                                                       AND NVL (RAC.SEGMENT4_HIGH, TBD.ACCOUNT)
                                   AND RRA.AXIS_SET_ID = 1000
                                   AND TBD.LEDGER_ID = P_LEDGER_ID
                                   AND (CASE
                                            WHEN P_COMPANY = 100 AND TBD.COMPANY BETWEEN 101 AND 599
                                            THEN
                                                1
                                            WHEN     P_COMPANY BETWEEN 101 AND 599
                                                 AND TBD.COMPANY = P_COMPANY
                                            THEN
                                                1
                                            ELSE
                                                NULL
                                        END) =
                                       1
                                   AND TBD.ACCOUNT NOT BETWEEN 40000000 AND 59999999
                                   AND TRUNC (TBD.ACCOUNTING_DATE) <= P_CURRENT_DATE
                          GROUP BY RRA.ATTRIBUTE1,
                                   RRA.DESCRIPTION,
                                   RRA.CHANGE_SIGN_FLAG,
                                   TBD.ACCOUNT,
                                   TBD.DESCRIPTION
                          UNION ALL
                            SELECT RRA.ATTRIBUTE1                                                        NOTES,
                                   RRA.DESCRIPTION                                                       NOTES_NAME,
                                   TBD.ACCOUNT,
                                   TBD.DESCRIPTION,
                                   0                                                                     CURRENT_PERIOD,
                                     (CASE WHEN RRA.CHANGE_SIGN_FLAG = 'Y' THEN -1 ELSE 1 END)
                                   * (SUM (
                                            (CASE WHEN SIGN = '-' THEN -1 ELSE 1 END)
                                          * (NVL (TBD.ACCOUNTED_DR, 0) - NVL (TBD.ACCOUNTED_CR, 0))))    PREVIOUS_PERIOD
                              FROM XX_TRIAL_BALANCE_DRAFT_V TBD,
                                   RG_REPORT_AXES        RRA,
                                   RG_REPORT_AXIS_CONTENTS RAC
                             WHERE     RRA.AXIS_SET_ID = RAC.AXIS_SET_ID
                                   AND RRA.AXIS_SEQ = RAC.AXIS_SEQ
                                   AND TBD.ACCOUNT BETWEEN NVL (RAC.SEGMENT4_LOW, TBD.ACCOUNT)
                                                       AND NVL (RAC.SEGMENT4_HIGH, TBD.ACCOUNT)
                                   AND RRA.AXIS_SET_ID = 1000
                                   AND TBD.LEDGER_ID = P_LEDGER_ID
                                   AND (CASE
                                            WHEN P_COMPANY = 100 AND TBD.COMPANY BETWEEN 101 AND 599
                                            THEN
                                                1
                                            WHEN     P_COMPANY BETWEEN 101 AND 599
                                                 AND TBD.COMPANY = P_COMPANY
                                            THEN
                                                1
                                            ELSE
                                                NULL
                                        END) =
                                       1
                                   AND TBD.ACCOUNT NOT BETWEEN 40000000 AND 59999999
                                   AND TRUNC (TBD.ACCOUNTING_DATE) <= P_PREVIOUS_DATE
                          GROUP BY RRA.ATTRIBUTE1,
                                   RRA.DESCRIPTION,
                                   RRA.CHANGE_SIGN_FLAG,
                                   TBD.ACCOUNT,
                                   TBD.DESCRIPTION
                          UNION ALL
                          SELECT '19',
                                 'Retained Earnings',
                                 '32010101'
                                     ACCOUNT,
                                 'Retained Earnings',
                                 SUM (NVL (TBD.ACCOUNTED_CR, 0) - NVL (TBD.ACCOUNTED_DR, 0))
                                     CURRENT_PERIOD,
                                 0
                                     PREVIOUS_PERIOD
                            FROM XX_TRIAL_BALANCE_DRAFT_V TBD
                           WHERE     TBD.LEDGER_ID = P_LEDGER_ID
                                 AND (CASE
                                          WHEN P_COMPANY = 100 AND TBD.COMPANY BETWEEN 101 AND 599
                                          THEN
                                              1
                                          WHEN     P_COMPANY BETWEEN 101 AND 599
                                               AND TBD.COMPANY = P_COMPANY
                                          THEN
                                              1
                                          ELSE
                                              NULL
                                      END) =
                                     1
                                 AND TBD.ACCOUNTING_DATE < TRUNC ((P_CURRENT_DATE), 'MON')
                                 AND ACCOUNT BETWEEN 40000000 AND 59999999
                          UNION ALL
                          SELECT '19',
                                 'Retained Earnings',
                                 '32010101'                                                     ACCOUNT,
                                 'Retained Earnings',
                                 0                                                              CURRENT_PERIOD,
                                 SUM (NVL (TBD.ACCOUNTED_CR, 0) - NVL (TBD.ACCOUNTED_DR, 0))    PREVIOUS_PERIOD
                            FROM XX_TRIAL_BALANCE_DRAFT_V TBD
                           WHERE     TBD.LEDGER_ID = P_LEDGER_ID
                                 AND (CASE
                                          WHEN P_COMPANY = 100 AND TBD.COMPANY BETWEEN 101 AND 599
                                          THEN
                                              1
                                          WHEN     P_COMPANY BETWEEN 101 AND 599
                                               AND TBD.COMPANY = P_COMPANY
                                          THEN
                                              1
                                          ELSE
                                              NULL
                                      END) =
                                     1
                                 AND TBD.ACCOUNTING_DATE < TRUNC ((P_PREVIOUS_DATE), 'MON')
                                 AND ACCOUNT BETWEEN 40000000 AND 59999999
                          UNION ALL
                          SELECT '19',
                                 'Retained Earnings',
                                 NULL
                                     ACCOUNT,
                                 'Current Period''s Profit',
                                 SUM (NVL (TBD.ACCOUNTED_CR, 0) - NVL (TBD.ACCOUNTED_DR, 0))
                                     CURRENT_PERIOD,
                                 0
                                     PREVIOUS_PERIOD
                            FROM XX_TRIAL_BALANCE_DRAFT_V TBD
                           WHERE     TBD.LEDGER_ID = P_LEDGER_ID
                                 AND (CASE
                                          WHEN P_COMPANY = 100 AND TBD.COMPANY BETWEEN 101 AND 599
                                          THEN
                                              1
                                          WHEN     P_COMPANY BETWEEN 101 AND 599
                                               AND TBD.COMPANY = P_COMPANY
                                          THEN
                                              1
                                          ELSE
                                              NULL
                                      END) =
                                     1
                                 --AND TO_CHAR (TBD.ACCOUNTING_DATE, 'MMRR') = TO_CHAR (P_CURRENT_DATE, 'MMRR')
                                 AND TRUNC (TBD.ACCOUNTING_DATE) BETWEEN TRUNC ((P_CURRENT_DATE),
                                                                                'MON')
                                                                     AND P_CURRENT_DATE
                                 AND ACCOUNT BETWEEN 40000000 AND 59999999
                          UNION ALL
                          SELECT '19',
                                 'Retained Earnings',
                                 NULL                                                           ACCOUNT,
                                 'Current Period''s Profit',
                                 0                                                              CURRENT_PERIOD,
                                 SUM (NVL (TBD.ACCOUNTED_CR, 0) - NVL (TBD.ACCOUNTED_DR, 0))    PREVIOUS_PERIOD
                            FROM XX_TRIAL_BALANCE_DRAFT_V TBD
                           WHERE     TBD.LEDGER_ID = P_LEDGER_ID
                                 AND (CASE
                                          WHEN P_COMPANY = 100 AND TBD.COMPANY BETWEEN 101 AND 599
                                          THEN
                                              1
                                          WHEN     P_COMPANY BETWEEN 101 AND 599
                                               AND TBD.COMPANY = P_COMPANY
                                          THEN
                                              1
                                          ELSE
                                              NULL
                                      END) =
                                     1
                                 --     AND TO_CHAR (TBD.ACCOUNTING_DATE, 'MMRR') = TO_CHAR (P_PREVIOUS_DATE, 'MMRR')
                                 AND TRUNC (TBD.ACCOUNTING_DATE) BETWEEN TRUNC ((P_PREVIOUS_DATE),
                                                                                'MON')
                                                                     AND P_PREVIOUS_DATE
                                 AND ACCOUNT BETWEEN 40000000 AND 59999999)
                   WHERE NOTES IS NOT NULL AND P_PROCESS_MODE = 'D'
                GROUP BY TO_NUMBER (NOTES),
                         NOTES,
                         NOTES_NAME,
                         ACCOUNT,
                         DESCRIPTION;

            --Final
            INSERT INTO XX_FINANCIAL_STATEMENT_GT (ORD,
                                                   NOTES,
                                                   NOTES_NAME,
                                                   ACCOUNT,
                                                   DESCRIPTION,
                                                   CURRENT_PERIOD,
                                                   PREVIOUS_PERIOD)
                WITH
                    XX_WITH_CLAUSE_TAB
                    AS
                        (  SELECT RRA.ATTRIBUTE1                                   NOTES,
                                  RRA.DESCRIPTION                                  NOTES_NAME,
                                  GCC.SEGMENT4                                     ACCOUNT,
                                  FFV.DESCRIPTION,
                                    (CASE WHEN RRA.CHANGE_SIGN_FLAG = 'Y' THEN -1 ELSE 1 END)
                                  * (SUM (
                                           (CASE WHEN SIGN = '-' THEN -1 ELSE 1 END)
                                         * (  (  NVL (BAL.BEGIN_BALANCE_DR, 0)
                                               - NVL (BAL.BEGIN_BALANCE_CR, 0))
                                            + (  NVL (BAL.PERIOD_NET_DR, 0)
                                               - NVL (BAL.PERIOD_NET_CR, 0)))))    CURRENT_PERIOD,
                                  0                                                PREVIOUS_PERIOD
                             FROM GL_BALANCES            BAL,
                                  GL_CODE_COMBINATIONS   GCC,
                                  FND_FLEX_VALUES_VL     FFV,
                                  GL_PERIOD_STATUSES     GPS,
                                  RG_REPORT_AXES         RRA,
                                  RG_REPORT_AXIS_CONTENTS RAC
                            WHERE     BAL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                                  AND GCC.SEGMENT4 = FFV.FLEX_VALUE
                                  AND BAL.LEDGER_ID = GPS.LEDGER_ID
                                  AND BAL.PERIOD_NAME = GPS.PERIOD_NAME
                                  AND RRA.AXIS_SET_ID = RAC.AXIS_SET_ID
                                  AND RRA.AXIS_SEQ = RAC.AXIS_SEQ
                                  AND GCC.TEMPLATE_ID IS NULL
                                  AND GPS.APPLICATION_ID = 101
                                  AND BAL.ACTUAL_FLAG = 'A'
                                  AND GCC.SUMMARY_FLAG = 'N'
                                  AND BAL.LEDGER_ID = P_LEDGER_ID
                                  AND BAL.CURRENCY_CODE = 'BDT'
                                  AND FFV.FLEX_VALUE_SET_ID = 1016494
                                  AND RRA.AXIS_SET_ID = 1000
                                  AND GPS.EFFECTIVE_PERIOD_NUM = P_CURRENT_PERIOD
                                  AND (CASE
                                           WHEN P_COMPANY = 100 AND GCC.SEGMENT1 BETWEEN 101 AND 599
                                           THEN
                                               1
                                           WHEN     P_COMPANY BETWEEN 101 AND 599
                                                AND GCC.SEGMENT1 = P_COMPANY
                                           THEN
                                               1
                                           ELSE
                                               NULL
                                       END) =
                                      1
                                  AND GCC.SEGMENT4 BETWEEN NVL (RAC.SEGMENT4_LOW, GCC.SEGMENT4)
                                                       AND NVL (RAC.SEGMENT4_HIGH, GCC.SEGMENT4)
                                  AND GCC.SEGMENT4 NOT BETWEEN 40000000 AND 59999999
                         GROUP BY RRA.ATTRIBUTE1,
                                  RRA.DESCRIPTION,
                                  GCC.SEGMENT4,
                                  FFV.DESCRIPTION,
                                  RRA.CHANGE_SIGN_FLAG
                         UNION ALL
                           SELECT RRA.ATTRIBUTE1                                   NOTES,
                                  RRA.DESCRIPTION                                  NOTES_NAME,
                                  GCC.SEGMENT4                                     ACCOUNT,
                                  FFV.DESCRIPTION,
                                  0                                                CURRENT_PERIOD,
                                    (CASE WHEN RRA.CHANGE_SIGN_FLAG = 'Y' THEN -1 ELSE 1 END)
                                  * (SUM (
                                           (CASE WHEN SIGN = '-' THEN -1 ELSE 1 END)
                                         * (  (  NVL (BAL.BEGIN_BALANCE_DR, 0)
                                               - NVL (BAL.BEGIN_BALANCE_CR, 0))
                                            + (  NVL (BAL.PERIOD_NET_DR, 0)
                                               - NVL (BAL.PERIOD_NET_CR, 0)))))    PREVIOUS_PERIOD
                             FROM GL_BALANCES            BAL,
                                  GL_CODE_COMBINATIONS   GCC,
                                  FND_FLEX_VALUES_VL     FFV,
                                  GL_PERIOD_STATUSES     GPS,
                                  RG_REPORT_AXES         RRA,
                                  RG_REPORT_AXIS_CONTENTS RAC
                            WHERE     BAL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                                  AND GCC.SEGMENT4 = FFV.FLEX_VALUE
                                  AND BAL.LEDGER_ID = GPS.LEDGER_ID
                                  AND BAL.PERIOD_NAME = GPS.PERIOD_NAME
                                  AND RRA.AXIS_SET_ID = RAC.AXIS_SET_ID
                                  AND RRA.AXIS_SEQ = RAC.AXIS_SEQ
                                  AND GCC.TEMPLATE_ID IS NULL
                                  AND GPS.APPLICATION_ID = 101
                                  AND BAL.ACTUAL_FLAG = 'A'
                                  AND GCC.SUMMARY_FLAG = 'N'
                                  AND BAL.LEDGER_ID = P_LEDGER_ID
                                  AND BAL.CURRENCY_CODE = 'BDT'
                                  AND FFV.FLEX_VALUE_SET_ID = 1016494
                                  AND RRA.AXIS_SET_ID = 1000
                                  AND GPS.EFFECTIVE_PERIOD_NUM = P_PREVIOUS_PERIOD
                                  AND (CASE
                                           WHEN P_COMPANY = 100 AND GCC.SEGMENT1 BETWEEN 101 AND 599
                                           THEN
                                               1
                                           WHEN     P_COMPANY BETWEEN 101 AND 599
                                                AND GCC.SEGMENT1 = P_COMPANY
                                           THEN
                                               1
                                           ELSE
                                               NULL
                                       END) =
                                      1
                                  AND GCC.SEGMENT4 BETWEEN NVL (RAC.SEGMENT4_LOW, GCC.SEGMENT4)
                                                       AND NVL (RAC.SEGMENT4_HIGH, GCC.SEGMENT4)
                                  AND GCC.SEGMENT4 NOT BETWEEN 40000000 AND 59999999
                         GROUP BY RRA.ATTRIBUTE1,
                                  RRA.DESCRIPTION,
                                  GCC.SEGMENT4,
                                  FFV.DESCRIPTION,
                                  RRA.CHANGE_SIGN_FLAG
                         UNION ALL
                           SELECT '19'                                              NOTES,
                                  'Retained Earnings'                               NOTES_NAME,
                                  '32010101'                                        ACCOUNT,
                                  'Retained Earnings'                               DESCRIPTION,
                                    (CASE WHEN RRA.CHANGE_SIGN_FLAG = 'Y' THEN -1 ELSE 1 END)
                                  * (SUM (
                                           (CASE WHEN SIGN = '-' THEN -1 ELSE 1 END)
                                         * ((  NVL (BAL.BEGIN_BALANCE_DR, 0)
                                             - NVL (BAL.BEGIN_BALANCE_CR, 0)))))    CURRENT_PERIOD,
                                  0                                                 PREVIOUS_PERIOD
                             FROM GL_BALANCES            BAL,
                                  GL_CODE_COMBINATIONS   GCC,
                                  FND_FLEX_VALUES_VL     FFV,
                                  GL_PERIOD_STATUSES     GPS,
                                  RG_REPORT_AXES         RRA,
                                  RG_REPORT_AXIS_CONTENTS RAC
                            WHERE     BAL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                                  AND GCC.SEGMENT4 = FFV.FLEX_VALUE
                                  AND BAL.LEDGER_ID = GPS.LEDGER_ID
                                  AND BAL.PERIOD_NAME = GPS.PERIOD_NAME
                                  AND RRA.AXIS_SET_ID = RAC.AXIS_SET_ID
                                  AND RRA.AXIS_SEQ = RAC.AXIS_SEQ
                                  AND GCC.TEMPLATE_ID IS NULL
                                  AND GPS.APPLICATION_ID = 101
                                  AND BAL.ACTUAL_FLAG = 'A'
                                  AND GCC.SUMMARY_FLAG = 'N'
                                  AND BAL.LEDGER_ID = P_LEDGER_ID
                                  AND BAL.CURRENCY_CODE = 'BDT'
                                  AND FFV.FLEX_VALUE_SET_ID = 1016494
                                  AND RRA.AXIS_SET_ID = 1000
                                  AND GPS.EFFECTIVE_PERIOD_NUM = P_CURRENT_PERIOD
                                  AND (CASE
                                           WHEN P_COMPANY = 100 AND GCC.SEGMENT1 BETWEEN 101 AND 599
                                           THEN
                                               1
                                           WHEN     P_COMPANY BETWEEN 101 AND 599
                                                AND GCC.SEGMENT1 = P_COMPANY
                                           THEN
                                               1
                                           ELSE
                                               NULL
                                       END) =
                                      1
                                  AND GCC.SEGMENT4 BETWEEN NVL (RAC.SEGMENT4_LOW, GCC.SEGMENT4)
                                                       AND NVL (RAC.SEGMENT4_HIGH, GCC.SEGMENT4)
                                  AND GCC.SEGMENT4 BETWEEN 40000000 AND 59999999
                         GROUP BY RRA.CHANGE_SIGN_FLAG
                         UNION ALL
                           SELECT '19'                                              NOTES,
                                  'Retained Earnings'                               NOTES_NAME,
                                  '32010101'                                        ACCOUNT,
                                  'Retained Earnings'                               DESCRIPTION,
                                  0                                                 CURRENT_PERIOD,
                                    (CASE WHEN RRA.CHANGE_SIGN_FLAG = 'Y' THEN -1 ELSE 1 END)
                                  * (SUM (
                                           (CASE WHEN SIGN = '-' THEN -1 ELSE 1 END)
                                         * ((  NVL (BAL.BEGIN_BALANCE_DR, 0)
                                             - NVL (BAL.BEGIN_BALANCE_CR, 0)))))    PREVIOUS_PERIOD
                             FROM GL_BALANCES            BAL,
                                  GL_CODE_COMBINATIONS   GCC,
                                  FND_FLEX_VALUES_VL     FFV,
                                  GL_PERIOD_STATUSES     GPS,
                                  RG_REPORT_AXES         RRA,
                                  RG_REPORT_AXIS_CONTENTS RAC
                            WHERE     BAL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                                  AND GCC.SEGMENT4 = FFV.FLEX_VALUE
                                  AND BAL.LEDGER_ID = GPS.LEDGER_ID
                                  AND BAL.PERIOD_NAME = GPS.PERIOD_NAME
                                  AND RRA.AXIS_SET_ID = RAC.AXIS_SET_ID
                                  AND RRA.AXIS_SEQ = RAC.AXIS_SEQ
                                  AND GCC.TEMPLATE_ID IS NULL
                                  AND GPS.APPLICATION_ID = 101
                                  AND BAL.ACTUAL_FLAG = 'A'
                                  AND GCC.SUMMARY_FLAG = 'N'
                                  AND BAL.LEDGER_ID = P_LEDGER_ID
                                  AND BAL.CURRENCY_CODE = 'BDT'
                                  AND FFV.FLEX_VALUE_SET_ID = 1016494
                                  AND RRA.AXIS_SET_ID = 1000
                                  AND GPS.EFFECTIVE_PERIOD_NUM = P_PREVIOUS_PERIOD
                                  AND (CASE
                                           WHEN P_COMPANY = 100 AND GCC.SEGMENT1 BETWEEN 101 AND 599
                                           THEN
                                               1
                                           WHEN     P_COMPANY BETWEEN 101 AND 599
                                                AND GCC.SEGMENT1 = P_COMPANY
                                           THEN
                                               1
                                           ELSE
                                               NULL
                                       END) =
                                      1
                                  AND GCC.SEGMENT4 BETWEEN NVL (RAC.SEGMENT4_LOW, GCC.SEGMENT4)
                                                       AND NVL (RAC.SEGMENT4_HIGH, GCC.SEGMENT4)
                                  AND GCC.SEGMENT4 BETWEEN 40000000 AND 59999999
                         GROUP BY RRA.CHANGE_SIGN_FLAG
                         UNION ALL
                           SELECT '19'
                                      NOTES,
                                  'Retained Earnings'
                                      NOTES_NAME,
                                  NULL
                                      ACCOUNT,
                                  'Current Period''s Profit'
                                      DESCRIPTION,
                                    (CASE WHEN RRA.CHANGE_SIGN_FLAG = 'Y' THEN -1 ELSE 1 END)
                                  * (SUM (
                                           (CASE WHEN SIGN = '-' THEN -1 ELSE 1 END)
                                         * ((NVL (BAL.PERIOD_NET_DR, 0) - NVL (BAL.PERIOD_NET_CR, 0)))))
                                      CURRENT_PERIOD,
                                  0
                                      PREVIOUS_PERIOD
                             FROM GL_BALANCES            BAL,
                                  GL_CODE_COMBINATIONS   GCC,
                                  FND_FLEX_VALUES_VL     FFV,
                                  GL_PERIOD_STATUSES     GPS,
                                  RG_REPORT_AXES         RRA,
                                  RG_REPORT_AXIS_CONTENTS RAC
                            WHERE     BAL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                                  AND GCC.SEGMENT4 = FFV.FLEX_VALUE
                                  AND BAL.LEDGER_ID = GPS.LEDGER_ID
                                  AND BAL.PERIOD_NAME = GPS.PERIOD_NAME
                                  AND RRA.AXIS_SET_ID = RAC.AXIS_SET_ID
                                  AND RRA.AXIS_SEQ = RAC.AXIS_SEQ
                                  AND GCC.TEMPLATE_ID IS NULL
                                  AND GPS.APPLICATION_ID = 101
                                  AND BAL.ACTUAL_FLAG = 'A'
                                  AND GCC.SUMMARY_FLAG = 'N'
                                  AND BAL.LEDGER_ID = P_LEDGER_ID
                                  AND BAL.CURRENCY_CODE = 'BDT'
                                  AND FFV.FLEX_VALUE_SET_ID = 1016494
                                  AND RRA.AXIS_SET_ID = 1000
                                  AND GPS.EFFECTIVE_PERIOD_NUM = P_CURRENT_PERIOD
                                  AND (CASE
                                           WHEN P_COMPANY = 100 AND GCC.SEGMENT1 BETWEEN 101 AND 599
                                           THEN
                                               1
                                           WHEN     P_COMPANY BETWEEN 101 AND 599
                                                AND GCC.SEGMENT1 = P_COMPANY
                                           THEN
                                               1
                                           ELSE
                                               NULL
                                       END) =
                                      1
                                  AND GCC.SEGMENT4 BETWEEN NVL (RAC.SEGMENT4_LOW, GCC.SEGMENT4)
                                                       AND NVL (RAC.SEGMENT4_HIGH, GCC.SEGMENT4)
                                  AND GCC.SEGMENT4 BETWEEN 40000000 AND 59999999
                         GROUP BY RRA.CHANGE_SIGN_FLAG
                         UNION ALL
                           SELECT '19'                                                                      NOTES,
                                  'Retained Earnings'                                                       NOTES_NAME,
                                  NULL                                                                      ACCOUNT,
                                  'Current Period''s Profit'                                                DESCRIPTION,
                                  0                                                                         CURRENT_PERIOD,
                                    (CASE WHEN RRA.CHANGE_SIGN_FLAG = 'Y' THEN -1 ELSE 1 END)
                                  * (SUM (
                                           (CASE WHEN SIGN = '-' THEN -1 ELSE 1 END)
                                         * ((NVL (BAL.PERIOD_NET_DR, 0) - NVL (BAL.PERIOD_NET_CR, 0)))))    PREVIOUS_PERIOD
                             FROM GL_BALANCES            BAL,
                                  GL_CODE_COMBINATIONS   GCC,
                                  FND_FLEX_VALUES_VL     FFV,
                                  GL_PERIOD_STATUSES     GPS,
                                  RG_REPORT_AXES         RRA,
                                  RG_REPORT_AXIS_CONTENTS RAC
                            WHERE     BAL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                                  AND GCC.SEGMENT4 = FFV.FLEX_VALUE
                                  AND BAL.LEDGER_ID = GPS.LEDGER_ID
                                  AND BAL.PERIOD_NAME = GPS.PERIOD_NAME
                                  AND RRA.AXIS_SET_ID = RAC.AXIS_SET_ID
                                  AND RRA.AXIS_SEQ = RAC.AXIS_SEQ
                                  AND GCC.TEMPLATE_ID IS NULL
                                  AND GPS.APPLICATION_ID = 101
                                  AND BAL.ACTUAL_FLAG = 'A'
                                  AND GCC.SUMMARY_FLAG = 'N'
                                  AND BAL.LEDGER_ID = P_LEDGER_ID
                                  AND BAL.CURRENCY_CODE = 'BDT'
                                  AND FFV.FLEX_VALUE_SET_ID = 1016494
                                  AND RRA.AXIS_SET_ID = 1000
                                  AND GPS.EFFECTIVE_PERIOD_NUM = P_PREVIOUS_PERIOD
                                  AND (CASE
                                           WHEN P_COMPANY = 100 AND GCC.SEGMENT1 BETWEEN 101 AND 599
                                           THEN
                                               1
                                           WHEN     P_COMPANY BETWEEN 101 AND 599
                                                AND GCC.SEGMENT1 = P_COMPANY
                                           THEN
                                               1
                                           ELSE
                                               NULL
                                       END) =
                                      1
                                  AND GCC.SEGMENT4 BETWEEN NVL (RAC.SEGMENT4_LOW, GCC.SEGMENT4)
                                                       AND NVL (RAC.SEGMENT4_HIGH, GCC.SEGMENT4)
                                  AND GCC.SEGMENT4 BETWEEN 40000000 AND 59999999
                         GROUP BY RRA.CHANGE_SIGN_FLAG)
                  SELECT TO_NUMBER (NOTES)         ORD,
                         NOTES,
                         NOTES_NAME,
                         ACCOUNT,
                         DESCRIPTION,
                         SUM (CURRENT_PERIOD)      CURRENT_PERIOD,
                         SUM (PREVIOUS_PERIOD)     PREVIOUS_PERIOD
                    FROM XX_WITH_CLAUSE_TAB
                   WHERE NOTES IS NOT NULL AND P_PROCESS_MODE = 'F'
                  HAVING (SUM (CURRENT_PERIOD) <> 0 OR SUM (PREVIOUS_PERIOD) <> 0)
                GROUP BY TO_NUMBER (NOTES),
                         NOTES,
                         NOTES_NAME,
                         ACCOUNT,
                         DESCRIPTION;
        END;
    END;

    PROCEDURE INSERT_INFO_IS (P_LEDGER_ID              IN NUMBER,
                              P_COMPANY                IN NUMBER,
                              P_BRANCH                 IN VARCHAR2,
                              P_SUB_BRANCH             IN VARCHAR2,
                              P_CURRENCY_CODE          IN VARCHAR2,
                              P_CURRENT_PERIOD_FROM    IN NUMBER,
                              P_CURRENT_PERIOD_TO      IN NUMBER,
                              P_PREVIOUS_PERIOD_FROM   IN NUMBER,
                              P_PREVIOUS_PERIOD_TO     IN NUMBER,
                              P_PROCESS_MODE           IN VARCHAR2)
    AS
    BEGIN
        DECLARE
            P_CURRENT_DATE_FROM    DATE;
            P_CURRENT_DATE_TO      DATE;
            P_PREVIOUS_DATE_FROM   DATE;
            P_PREVIOUS_DATE_TO     DATE;
        BEGIN
            SELECT START_DATE
              INTO P_CURRENT_DATE_FROM
              FROM GL_PERIOD_STATUSES
             WHERE     APPLICATION_ID = 101
                   AND SET_OF_BOOKS_ID = P_LEDGER_ID
                   AND EFFECTIVE_PERIOD_NUM = P_CURRENT_PERIOD_FROM;

            SELECT END_DATE
              INTO P_CURRENT_DATE_TO
              FROM GL_PERIOD_STATUSES
             WHERE     APPLICATION_ID = 101
                   AND SET_OF_BOOKS_ID = P_LEDGER_ID
                   AND EFFECTIVE_PERIOD_NUM = P_CURRENT_PERIOD_TO;

            SELECT START_DATE
              INTO P_PREVIOUS_DATE_FROM
              FROM GL_PERIOD_STATUSES
             WHERE     APPLICATION_ID = 101
                   AND SET_OF_BOOKS_ID = P_LEDGER_ID
                   AND EFFECTIVE_PERIOD_NUM = P_PREVIOUS_PERIOD_FROM;

            SELECT END_DATE
              INTO P_PREVIOUS_DATE_TO
              FROM GL_PERIOD_STATUSES
             WHERE     APPLICATION_ID = 101
                   AND SET_OF_BOOKS_ID = P_LEDGER_ID
                   AND EFFECTIVE_PERIOD_NUM = P_PREVIOUS_PERIOD_TO;


            INSERT INTO XX_FINANCIAL_STATEMENT_GT (SL,
                                                   ORD,
                                                   DESCRIPTION,
                                                   NOTES,
                                                   CURRENT_PERIOD,
                                                   PREVIOUS_PERIOD,
                                                   CURRENT_BUDGET)
                  SELECT TO_NUMBER (SUBSTR (SL, 1, 1))     SL,
                         TO_NUMBER (SUBSTR (SL, 2, 2))     ORD,
                         DESCRIPTION,
                         NOTES,
                         SUM (CURRENT_PERIOD)              CURRENT_PERIOD,
                         SUM (PREVIOUS_PERIOD)             PREVIOUS_PERIOD,
                         SUM (CURRENT_BUDGET)              CURRENT_BUDGET
                    FROM (  SELECT RRA.AXIS_SEQ
                                       SL,
                                   RRA.DESCRIPTION,
                                   RRA.ATTRIBUTE1
                                       NOTES,
                                     (CASE WHEN RRA.CHANGE_SIGN_FLAG = 'Y' THEN -1 ELSE 1 END)
                                   * (SUM (
                                            (CASE WHEN SIGN = '-' THEN -1 ELSE 1 END)
                                          * (NVL (TBD.ACCOUNTED_DR, 0) - NVL (TBD.ACCOUNTED_CR, 0))))
                                       CURRENT_PERIOD,
                                   0
                                       PREVIOUS_PERIOD,
                                   0
                                       CURRENT_BUDGET
                              FROM XX_TRIAL_BALANCE_DRAFT_V TBD,
                                   RG_REPORT_AXES        RRA,
                                   RG_REPORT_AXIS_CONTENTS RAC
                             WHERE     RRA.AXIS_SET_ID = RAC.AXIS_SET_ID
                                   AND RRA.AXIS_SEQ = RAC.AXIS_SEQ
                                   AND TBD.ACCOUNT BETWEEN NVL (RAC.SEGMENT4_LOW, TBD.ACCOUNT)
                                                       AND NVL (RAC.SEGMENT4_HIGH, TBD.ACCOUNT)
                                   AND TBD.EXP_CATEGORY BETWEEN NVL (RAC.SEGMENT5_LOW,
                                                                     TBD.EXP_CATEGORY)
                                                            AND NVL (RAC.SEGMENT5_HIGH,
                                                                     TBD.EXP_CATEGORY)
                                   AND RRA.AXIS_SET_ID = 1002
                                   AND TBD.LEDGER_ID = P_LEDGER_ID
                                   AND (CASE
                                            WHEN P_COMPANY = 100 AND TBD.COMPANY BETWEEN 101 AND 599
                                            THEN
                                                1
                                            WHEN     P_COMPANY BETWEEN 101 AND 599
                                                 AND TBD.COMPANY = P_COMPANY
                                            THEN
                                                1
                                            ELSE
                                                NULL
                                        END) =
                                       1
                                   AND TBD.BRANCH IN
                                           (SELECT FLEX_VALUE
                                              FROM FND_FLEX_VALUES_VL
                                             WHERE     FLEX_VALUE_SET_ID = 1016557
                                                   AND PARENT_FLEX_VALUE_LOW =
                                                       NVL (P_BRANCH, PARENT_FLEX_VALUE_LOW)
                                                   AND FLEX_VALUE = NVL (P_SUB_BRANCH, FLEX_VALUE))
                                   AND TRUNC (TBD.ACCOUNTING_DATE) BETWEEN P_CURRENT_DATE_FROM
                                                                       AND P_CURRENT_DATE_TO
                          GROUP BY RRA.AXIS_SEQ,
                                   RRA.DESCRIPTION,
                                   RRA.ATTRIBUTE1,
                                   RRA.CHANGE_SIGN_FLAG
                          UNION ALL
                            SELECT RRA.AXIS_SEQ
                                       SL,
                                   RRA.DESCRIPTION,
                                   RRA.ATTRIBUTE1
                                       NOTES,
                                   0
                                       CURRENT_PERIOD,
                                     (CASE WHEN RRA.CHANGE_SIGN_FLAG = 'Y' THEN -1 ELSE 1 END)
                                   * (SUM (
                                            (CASE WHEN SIGN = '-' THEN -1 ELSE 1 END)
                                          * (NVL (TBD.ACCOUNTED_DR, 0) - NVL (TBD.ACCOUNTED_CR, 0))))
                                       PREVIOUS_PERIOD,
                                   0
                                       CURRENT_BUDGET
                              FROM XX_TRIAL_BALANCE_DRAFT_V TBD,
                                   RG_REPORT_AXES        RRA,
                                   RG_REPORT_AXIS_CONTENTS RAC
                             WHERE     RRA.AXIS_SET_ID = RAC.AXIS_SET_ID
                                   AND RRA.AXIS_SEQ = RAC.AXIS_SEQ
                                   AND TBD.ACCOUNT BETWEEN NVL (RAC.SEGMENT4_LOW, TBD.ACCOUNT)
                                                       AND NVL (RAC.SEGMENT4_HIGH, TBD.ACCOUNT)
                                   AND TBD.EXP_CATEGORY BETWEEN NVL (RAC.SEGMENT5_LOW,
                                                                     TBD.EXP_CATEGORY)
                                                            AND NVL (RAC.SEGMENT5_HIGH,
                                                                     TBD.EXP_CATEGORY)
                                   AND RRA.AXIS_SET_ID = 1002
                                   AND TBD.LEDGER_ID = P_LEDGER_ID
                                   AND (CASE
                                            WHEN P_COMPANY = 100 AND TBD.COMPANY BETWEEN 101 AND 599
                                            THEN
                                                1
                                            WHEN     P_COMPANY BETWEEN 101 AND 599
                                                 AND TBD.COMPANY = P_COMPANY
                                            THEN
                                                1
                                            ELSE
                                                NULL
                                        END) =
                                       1
                                   AND TBD.BRANCH IN
                                           (SELECT FLEX_VALUE
                                              FROM FND_FLEX_VALUES_VL
                                             WHERE     FLEX_VALUE_SET_ID = 1016557
                                                   AND PARENT_FLEX_VALUE_LOW =
                                                       NVL (P_BRANCH, PARENT_FLEX_VALUE_LOW)
                                                   AND FLEX_VALUE = NVL (P_SUB_BRANCH, FLEX_VALUE))
                                   AND TRUNC (TBD.ACCOUNTING_DATE) BETWEEN P_PREVIOUS_DATE_FROM
                                                                       AND P_PREVIOUS_DATE_TO
                          GROUP BY RRA.AXIS_SEQ,
                                   RRA.DESCRIPTION,
                                   RRA.ATTRIBUTE1,
                                   RRA.CHANGE_SIGN_FLAG
                          UNION ALL
                          SELECT RRA.AXIS_SEQ       SL,
                                 RRA.DESCRIPTION,
                                 RRA.ATTRIBUTE1     NOTES,
                                 0,
                                 0,
                                 0
                            FROM RG_REPORT_AXES RRA
                           WHERE RRA.AXIS_SET_ID = 1002 AND DISPLAY_ZERO_AMOUNT_FLAG = 'Y')
                   WHERE P_PROCESS_MODE = 'D'
                GROUP BY SL, DESCRIPTION, NOTES;

            --Final
            INSERT INTO XX_FINANCIAL_STATEMENT_GT (SL,
                                                   ORD,
                                                   DESCRIPTION,
                                                   NOTES,
                                                   CURRENT_PERIOD,
                                                   PREVIOUS_PERIOD,
                                                   CURRENT_BUDGET)
                WITH
                    XX_WITH_CLAUSE_TAB
                    AS
                        (  SELECT RRA.AXIS_SEQ
                                      SL,
                                  RRA.DESCRIPTION,
                                  RRA.ATTRIBUTE1
                                      NOTES,
                                    (CASE WHEN RRA.CHANGE_SIGN_FLAG = 'Y' THEN -1 ELSE 1 END)
                                  * (SUM (
                                           (CASE WHEN SIGN = '-' THEN -1 ELSE 1 END)
                                         * (NVL (BAL.PERIOD_NET_DR, 0) - NVL (BAL.PERIOD_NET_CR, 0))))
                                      CURRENT_PERIOD,
                                  0
                                      PREVIOUS_PERIOD,
                                  0
                                      CURRENT_BUDGET
                             FROM GL_BALANCES            BAL,
                                  GL_CODE_COMBINATIONS   GCC,
                                  GL_PERIOD_STATUSES     GPS,
                                  RG_REPORT_AXES         RRA,
                                  RG_REPORT_AXIS_CONTENTS RAC
                            WHERE     BAL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                                  AND BAL.LEDGER_ID = GPS.LEDGER_ID
                                  AND BAL.PERIOD_NAME = GPS.PERIOD_NAME
                                  AND BAL.ACTUAL_FLAG = 'A'
                                  AND BAL.CURRENCY_CODE = 'BDT'
                                  AND GPS.APPLICATION_ID = 101
                                  AND GCC.TEMPLATE_ID IS NULL
                                  AND GCC.SUMMARY_FLAG = 'N'
                                  AND RRA.AXIS_SET_ID = RAC.AXIS_SET_ID
                                  AND RRA.AXIS_SEQ = RAC.AXIS_SEQ
                                  AND BAL.LEDGER_ID = P_LEDGER_ID
                                  AND RRA.AXIS_SET_ID = 1002
                                  AND GPS.EFFECTIVE_PERIOD_NUM >= P_CURRENT_PERIOD_FROM
                                  AND GPS.EFFECTIVE_PERIOD_NUM <= P_CURRENT_PERIOD_TO
                                  AND (CASE
                                           WHEN P_COMPANY = 100 AND GCC.SEGMENT1 BETWEEN 101 AND 599
                                           THEN
                                               1
                                           WHEN     P_COMPANY BETWEEN 101 AND 599
                                                AND GCC.SEGMENT1 = P_COMPANY
                                           THEN
                                               1
                                           ELSE
                                               NULL
                                       END) =
                                      1
                                  AND GCC.SEGMENT2 BETWEEN NVL (RAC.SEGMENT2_LOW, GCC.SEGMENT2)
                                                       AND NVL (RAC.SEGMENT2_HIGH, GCC.SEGMENT2)
                                  AND GCC.SEGMENT3 BETWEEN NVL (RAC.SEGMENT3_LOW, GCC.SEGMENT3)
                                                       AND NVL (RAC.SEGMENT3_HIGH, GCC.SEGMENT3)
                                  AND GCC.SEGMENT4 BETWEEN NVL (RAC.SEGMENT4_LOW, GCC.SEGMENT4)
                                                       AND NVL (RAC.SEGMENT4_HIGH, GCC.SEGMENT4)
                                  AND GCC.SEGMENT5 BETWEEN NVL (RAC.SEGMENT5_LOW, GCC.SEGMENT5)
                                                       AND NVL (RAC.SEGMENT5_HIGH, GCC.SEGMENT5)
                                  AND GCC.SEGMENT6 BETWEEN NVL (RAC.SEGMENT6_LOW, GCC.SEGMENT6)
                                                       AND NVL (RAC.SEGMENT6_HIGH, GCC.SEGMENT6)
                                  AND GCC.SEGMENT7 BETWEEN NVL (RAC.SEGMENT7_LOW, GCC.SEGMENT7)
                                                       AND NVL (RAC.SEGMENT7_HIGH, GCC.SEGMENT7)
                                  AND GCC.SEGMENT2 IN
                                          (SELECT FLEX_VALUE
                                             FROM FND_FLEX_VALUES_VL
                                            WHERE     FLEX_VALUE_SET_ID = 1016557
                                                  AND PARENT_FLEX_VALUE_LOW =
                                                      NVL (P_BRANCH, PARENT_FLEX_VALUE_LOW)
                                                  AND FLEX_VALUE = NVL (P_SUB_BRANCH, FLEX_VALUE))
                         GROUP BY RRA.AXIS_SEQ,
                                  RRA.DESCRIPTION,
                                  RRA.ATTRIBUTE1,
                                  RRA.CHANGE_SIGN_FLAG
                         UNION ALL
                           SELECT RRA.AXIS_SEQ
                                      SL,
                                  RRA.DESCRIPTION,
                                  RRA.ATTRIBUTE1
                                      NOTES,
                                  0
                                      CURRENT_PERIOD,
                                    (CASE WHEN RRA.CHANGE_SIGN_FLAG = 'Y' THEN -1 ELSE 1 END)
                                  * (SUM (
                                           (CASE WHEN SIGN = '-' THEN -1 ELSE 1 END)
                                         * (NVL (BAL.PERIOD_NET_DR, 0) - NVL (BAL.PERIOD_NET_CR, 0))))
                                      PREVIOUS_PERIOD,
                                  0
                                      CURRENT_BUDGET
                             FROM GL_BALANCES            BAL,
                                  GL_CODE_COMBINATIONS   GCC,
                                  GL_PERIOD_STATUSES     GPS,
                                  RG_REPORT_AXES         RRA,
                                  RG_REPORT_AXIS_CONTENTS RAC
                            WHERE     BAL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                                  AND BAL.LEDGER_ID = GPS.LEDGER_ID
                                  AND BAL.PERIOD_NAME = GPS.PERIOD_NAME
                                  AND BAL.ACTUAL_FLAG = 'A'
                                  AND BAL.CURRENCY_CODE = 'BDT'
                                  AND GPS.APPLICATION_ID = 101
                                  AND GCC.TEMPLATE_ID IS NULL
                                  AND GCC.SUMMARY_FLAG = 'N'
                                  AND RRA.AXIS_SET_ID = RAC.AXIS_SET_ID
                                  AND RRA.AXIS_SEQ = RAC.AXIS_SEQ
                                  AND BAL.LEDGER_ID = P_LEDGER_ID
                                  AND RRA.AXIS_SET_ID = 1002
                                  AND GPS.EFFECTIVE_PERIOD_NUM >= P_PREVIOUS_PERIOD_FROM
                                  AND GPS.EFFECTIVE_PERIOD_NUM <= P_PREVIOUS_PERIOD_TO
                                  AND (CASE
                                           WHEN P_COMPANY = 100 AND GCC.SEGMENT1 BETWEEN 101 AND 599
                                           THEN
                                               1
                                           WHEN     P_COMPANY BETWEEN 101 AND 599
                                                AND GCC.SEGMENT1 = P_COMPANY
                                           THEN
                                               1
                                           ELSE
                                               NULL
                                       END) =
                                      1
                                  AND GCC.SEGMENT2 BETWEEN NVL (RAC.SEGMENT2_LOW, GCC.SEGMENT2)
                                                       AND NVL (RAC.SEGMENT2_HIGH, GCC.SEGMENT2)
                                  AND GCC.SEGMENT3 BETWEEN NVL (RAC.SEGMENT3_LOW, GCC.SEGMENT3)
                                                       AND NVL (RAC.SEGMENT3_HIGH, GCC.SEGMENT3)
                                  AND GCC.SEGMENT4 BETWEEN NVL (RAC.SEGMENT4_LOW, GCC.SEGMENT4)
                                                       AND NVL (RAC.SEGMENT4_HIGH, GCC.SEGMENT4)
                                  AND GCC.SEGMENT5 BETWEEN NVL (RAC.SEGMENT5_LOW, GCC.SEGMENT5)
                                                       AND NVL (RAC.SEGMENT5_HIGH, GCC.SEGMENT5)
                                  AND GCC.SEGMENT6 BETWEEN NVL (RAC.SEGMENT6_LOW, GCC.SEGMENT6)
                                                       AND NVL (RAC.SEGMENT6_HIGH, GCC.SEGMENT6)
                                  AND GCC.SEGMENT7 BETWEEN NVL (RAC.SEGMENT7_LOW, GCC.SEGMENT7)
                                                       AND NVL (RAC.SEGMENT7_HIGH, GCC.SEGMENT7)
                                  AND GCC.SEGMENT2 IN
                                          (SELECT FLEX_VALUE
                                             FROM FND_FLEX_VALUES_VL
                                            WHERE     FLEX_VALUE_SET_ID = 1016557
                                                  AND PARENT_FLEX_VALUE_LOW =
                                                      NVL (P_BRANCH, PARENT_FLEX_VALUE_LOW)
                                                  AND FLEX_VALUE = NVL (P_SUB_BRANCH, FLEX_VALUE))
                         GROUP BY RRA.AXIS_SEQ,
                                  RRA.DESCRIPTION,
                                  RRA.ATTRIBUTE1,
                                  RRA.CHANGE_SIGN_FLAG
                         UNION ALL
                         SELECT RRA.AXIS_SEQ       SL,
                                RRA.DESCRIPTION,
                                RRA.ATTRIBUTE1     NOTES,
                                0,
                                0,
                                0
                           FROM RG_REPORT_AXES RRA
                          WHERE RRA.AXIS_SET_ID = 1002 AND DISPLAY_ZERO_AMOUNT_FLAG = 'Y')
                  SELECT TO_NUMBER (SUBSTR (SL, 1, 1))     SL,
                         TO_NUMBER (SUBSTR (SL, 2, 2))     ORD,
                         DESCRIPTION,
                         NOTES,
                         SUM (CURRENT_PERIOD)              CURRENT_PERIOD,
                         SUM (PREVIOUS_PERIOD)             PREVIOUS_PERIOD,
                         SUM (CURRENT_BUDGET)              CURRENT_BUDGET
                    FROM XX_WITH_CLAUSE_TAB
                   WHERE P_PROCESS_MODE = 'F'
                GROUP BY SL, DESCRIPTION, NOTES;
        END;
    END;


    PROCEDURE INSERT_INFO_ISN (P_LEDGER_ID              IN NUMBER,
                               P_COMPANY                IN NUMBER,
                               P_BRANCH                 IN VARCHAR2,
                               P_SUB_BRANCH             IN VARCHAR2,
                               P_CURRENCY_CODE          IN VARCHAR2,
                               P_CURRENT_PERIOD_FROM    IN NUMBER,
                               P_CURRENT_PERIOD_TO      IN NUMBER,
                               P_PREVIOUS_PERIOD_FROM   IN NUMBER,
                               P_PREVIOUS_PERIOD_TO     IN NUMBER,
                               P_PROCESS_MODE           IN VARCHAR2)
    AS
    BEGIN
        DECLARE
            P_CURRENT_DATE_FROM    DATE;
            P_CURRENT_DATE_TO      DATE;
            P_PREVIOUS_DATE_FROM   DATE;
            P_PREVIOUS_DATE_TO     DATE;
        BEGIN
            SELECT START_DATE
              INTO P_CURRENT_DATE_FROM
              FROM GL_PERIOD_STATUSES
             WHERE     APPLICATION_ID = 101
                   AND SET_OF_BOOKS_ID = P_LEDGER_ID
                   AND EFFECTIVE_PERIOD_NUM = P_CURRENT_PERIOD_FROM;

            SELECT END_DATE
              INTO P_CURRENT_DATE_TO
              FROM GL_PERIOD_STATUSES
             WHERE     APPLICATION_ID = 101
                   AND SET_OF_BOOKS_ID = P_LEDGER_ID
                   AND EFFECTIVE_PERIOD_NUM = P_CURRENT_PERIOD_TO;

            SELECT START_DATE
              INTO P_PREVIOUS_DATE_FROM
              FROM GL_PERIOD_STATUSES
             WHERE     APPLICATION_ID = 101
                   AND SET_OF_BOOKS_ID = P_LEDGER_ID
                   AND EFFECTIVE_PERIOD_NUM = P_PREVIOUS_PERIOD_FROM;

            SELECT END_DATE
              INTO P_PREVIOUS_DATE_TO
              FROM GL_PERIOD_STATUSES
             WHERE     APPLICATION_ID = 101
                   AND SET_OF_BOOKS_ID = P_LEDGER_ID
                   AND EFFECTIVE_PERIOD_NUM = P_PREVIOUS_PERIOD_TO;


            INSERT INTO XX_FINANCIAL_STATEMENT_GT (ORD,
                                                   NOTES,
                                                   NOTES_NAME,
                                                   ACCOUNT,
                                                   DESCRIPTION,
                                                   CURRENT_PERIOD,
                                                   PREVIOUS_PERIOD,
                                                   CURRENT_BUDGET)
                  SELECT TO_NUMBER (NOTES)         ORD,
                         NOTES,
                         NOTES_NAME,
                         ACCOUNT,
                         DESCRIPTION,
                         SUM (CURRENT_PERIOD)      CURRENT_PERIOD,
                         SUM (PREVIOUS_PERIOD)     PREVIOUS_PERIOD,
                         SUM (CURRENT_BUDGET)      CURRENT_BUDGET
                    FROM (SELECT RRA.ATTRIBUTE1     NOTES,
                                 RRA.DESCRIPTION    NOTES_NAME,
                                 TBD.ACCOUNT,
                                 TBD.DESCRIPTION,
                                 (CASE
                                      WHEN TBD.ACCOUNT_TYPE = 'R'
                                      THEN
                                          (NVL (TBD.ACCOUNTED_CR, 0) - NVL (TBD.ACCOUNTED_DR, 0))
                                      WHEN TBD.ACCOUNT_TYPE = 'E'
                                      THEN
                                          (NVL (TBD.ACCOUNTED_DR, 0) - NVL (TBD.ACCOUNTED_CR, 0))
                                  END)              CURRENT_PERIOD,
                                 0                  PREVIOUS_PERIOD,
                                 0                  CURRENT_BUDGET
                            FROM XX_TRIAL_BALANCE_DRAFT_V TBD,
                                 RG_REPORT_AXES          RRA,
                                 RG_REPORT_AXIS_CONTENTS RAC
                           WHERE     RRA.AXIS_SET_ID = RAC.AXIS_SET_ID
                                 AND RRA.AXIS_SEQ = RAC.AXIS_SEQ
                                 AND TBD.ACCOUNT BETWEEN NVL (RAC.SEGMENT4_LOW, TBD.ACCOUNT)
                                                     AND NVL (RAC.SEGMENT4_HIGH, TBD.ACCOUNT)
                                 AND TBD.EXP_CATEGORY BETWEEN NVL (RAC.SEGMENT5_LOW,
                                                                   TBD.EXP_CATEGORY)
                                                          AND NVL (RAC.SEGMENT5_HIGH,
                                                                   TBD.EXP_CATEGORY)
                                 AND RRA.AXIS_SET_ID = 1002
                                 AND TBD.LEDGER_ID = P_LEDGER_ID
                                 AND (CASE
                                          WHEN P_COMPANY = 100 AND TBD.COMPANY BETWEEN 101 AND 599
                                          THEN
                                              1
                                          WHEN     P_COMPANY BETWEEN 101 AND 599
                                               AND TBD.COMPANY = P_COMPANY
                                          THEN
                                              1
                                          ELSE
                                              NULL
                                      END) =
                                     1
                                 AND TBD.BRANCH IN
                                         (SELECT FLEX_VALUE
                                            FROM FND_FLEX_VALUES_VL
                                           WHERE     FLEX_VALUE_SET_ID = 1016557
                                                 AND PARENT_FLEX_VALUE_LOW =
                                                     NVL (P_BRANCH, PARENT_FLEX_VALUE_LOW)
                                                 AND FLEX_VALUE = NVL (P_SUB_BRANCH, FLEX_VALUE))
                                 AND TRUNC (TBD.ACCOUNTING_DATE) BETWEEN P_CURRENT_DATE_FROM
                                                                     AND P_CURRENT_DATE_TO
                          UNION ALL
                          SELECT RRA.ATTRIBUTE1     NOTES,
                                 RRA.DESCRIPTION    NOTES_NAME,
                                 TBD.ACCOUNT,
                                 TBD.DESCRIPTION,
                                 0                  CURRENT_PERIOD,
                                 (CASE
                                      WHEN TBD.ACCOUNT_TYPE = 'R'
                                      THEN
                                          (NVL (TBD.ACCOUNTED_CR, 0) - NVL (TBD.ACCOUNTED_DR, 0))
                                      WHEN TBD.ACCOUNT_TYPE = 'E'
                                      THEN
                                          (NVL (TBD.ACCOUNTED_DR, 0) - NVL (TBD.ACCOUNTED_CR, 0))
                                  END)              PREVIOUS_PERIOD,
                                 0                  CURRENT_BUDGET
                            FROM XX_TRIAL_BALANCE_DRAFT_V TBD,
                                 RG_REPORT_AXES          RRA,
                                 RG_REPORT_AXIS_CONTENTS RAC
                           WHERE     RRA.AXIS_SET_ID = RAC.AXIS_SET_ID
                                 AND RRA.AXIS_SEQ = RAC.AXIS_SEQ
                                 AND TBD.ACCOUNT BETWEEN NVL (RAC.SEGMENT4_LOW, TBD.ACCOUNT)
                                                     AND NVL (RAC.SEGMENT4_HIGH, TBD.ACCOUNT)
                                 AND TBD.EXP_CATEGORY BETWEEN NVL (RAC.SEGMENT5_LOW,
                                                                   TBD.EXP_CATEGORY)
                                                          AND NVL (RAC.SEGMENT5_HIGH,
                                                                   TBD.EXP_CATEGORY)
                                 AND RRA.AXIS_SET_ID = 1002
                                 AND TBD.LEDGER_ID = P_LEDGER_ID
                                 AND (CASE
                                          WHEN P_COMPANY = 100 AND TBD.COMPANY BETWEEN 101 AND 599
                                          THEN
                                              1
                                          WHEN     P_COMPANY BETWEEN 101 AND 599
                                               AND TBD.COMPANY = P_COMPANY
                                          THEN
                                              1
                                          ELSE
                                              NULL
                                      END) =
                                     1
                                 AND TBD.BRANCH IN
                                         (SELECT FLEX_VALUE
                                            FROM FND_FLEX_VALUES_VL
                                           WHERE     FLEX_VALUE_SET_ID = 1016557
                                                 AND PARENT_FLEX_VALUE_LOW =
                                                     NVL (P_BRANCH, PARENT_FLEX_VALUE_LOW)
                                                 AND FLEX_VALUE = NVL (P_SUB_BRANCH, FLEX_VALUE))
                                 AND TRUNC (TBD.ACCOUNTING_DATE) BETWEEN P_PREVIOUS_DATE_FROM
                                                                     AND P_PREVIOUS_DATE_TO)
                   WHERE P_PROCESS_MODE = 'D'
                GROUP BY TO_NUMBER (NOTES),
                         NOTES,
                         NOTES_NAME,
                         ACCOUNT,
                         DESCRIPTION;

            -- Final
            INSERT INTO XX_FINANCIAL_STATEMENT_GT (ORD,
                                                   NOTES,
                                                   NOTES_NAME,
                                                   ACCOUNT,
                                                   DESCRIPTION,
                                                   CURRENT_PERIOD,
                                                   PREVIOUS_PERIOD,
                                                   CURRENT_BUDGET)
                WITH
                    XX_WITH_CLAUSE_TAB
                    AS
                        (  SELECT RRA.ATTRIBUTE1
                                      NOTES,
                                  RRA.DESCRIPTION
                                      NOTES_NAME,
                                  GCC.SEGMENT4
                                      ACCOUNT,
                                  FFV.DESCRIPTION,
                                    (CASE WHEN RRA.CHANGE_SIGN_FLAG = 'Y' THEN -1 ELSE 1 END)
                                  * (SUM (
                                           (CASE WHEN SIGN = '-' THEN -1 ELSE 1 END)
                                         * (NVL (BAL.PERIOD_NET_DR, 0) - NVL (BAL.PERIOD_NET_CR, 0))))
                                      CURRENT_PERIOD,
                                  0
                                      PREVIOUS_PERIOD,
                                  0
                                      CURRENT_BUDGET
                             FROM GL_BALANCES            BAL,
                                  GL_CODE_COMBINATIONS   GCC,
                                  FND_FLEX_VALUES_VL     FFV,
                                  GL_PERIOD_STATUSES     GPS,
                                  RG_REPORT_AXES         RRA,
                                  RG_REPORT_AXIS_CONTENTS RAC
                            WHERE     BAL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                                  AND GCC.SEGMENT4 = FFV.FLEX_VALUE
                                  AND BAL.LEDGER_ID = GPS.LEDGER_ID
                                  AND BAL.PERIOD_NAME = GPS.PERIOD_NAME
                                  AND BAL.ACTUAL_FLAG = 'A'
                                  AND BAL.CURRENCY_CODE = 'BDT'
                                  AND FFV.FLEX_VALUE_SET_ID = 1016494
                                  AND GPS.APPLICATION_ID = 101
                                  AND GCC.TEMPLATE_ID IS NULL
                                  AND GCC.SUMMARY_FLAG = 'N'
                                  AND RRA.AXIS_SET_ID = RAC.AXIS_SET_ID
                                  AND RRA.AXIS_SEQ = RAC.AXIS_SEQ
                                  AND BAL.LEDGER_ID = P_LEDGER_ID
                                  AND RRA.AXIS_SET_ID = 1002
                                  AND GPS.EFFECTIVE_PERIOD_NUM >= P_CURRENT_PERIOD_FROM
                                  AND GPS.EFFECTIVE_PERIOD_NUM <= P_CURRENT_PERIOD_TO
                                  AND (CASE
                                           WHEN P_COMPANY = 100 AND GCC.SEGMENT1 BETWEEN 101 AND 599
                                           THEN
                                               1
                                           WHEN     P_COMPANY BETWEEN 101 AND 599
                                                AND GCC.SEGMENT1 = P_COMPANY
                                           THEN
                                               1
                                           ELSE
                                               NULL
                                       END) =
                                      1
                                  AND GCC.SEGMENT2 BETWEEN NVL (RAC.SEGMENT2_LOW, GCC.SEGMENT2)
                                                       AND NVL (RAC.SEGMENT2_HIGH, GCC.SEGMENT2)
                                  AND GCC.SEGMENT3 BETWEEN NVL (RAC.SEGMENT3_LOW, GCC.SEGMENT3)
                                                       AND NVL (RAC.SEGMENT3_HIGH, GCC.SEGMENT3)
                                  AND GCC.SEGMENT4 BETWEEN NVL (RAC.SEGMENT4_LOW, GCC.SEGMENT4)
                                                       AND NVL (RAC.SEGMENT4_HIGH, GCC.SEGMENT4)
                                  AND GCC.SEGMENT5 BETWEEN NVL (RAC.SEGMENT5_LOW, GCC.SEGMENT5)
                                                       AND NVL (RAC.SEGMENT5_HIGH, GCC.SEGMENT5)
                                  AND GCC.SEGMENT6 BETWEEN NVL (RAC.SEGMENT6_LOW, GCC.SEGMENT6)
                                                       AND NVL (RAC.SEGMENT6_HIGH, GCC.SEGMENT6)
                                  AND GCC.SEGMENT7 BETWEEN NVL (RAC.SEGMENT7_LOW, GCC.SEGMENT7)
                                                       AND NVL (RAC.SEGMENT7_HIGH, GCC.SEGMENT7)
                                  AND GCC.SEGMENT2 IN
                                          (SELECT FLEX_VALUE
                                             FROM FND_FLEX_VALUES_VL
                                            WHERE     FLEX_VALUE_SET_ID = 1016557
                                                  AND PARENT_FLEX_VALUE_LOW =
                                                      NVL (P_BRANCH, PARENT_FLEX_VALUE_LOW)
                                                  AND FLEX_VALUE = NVL (P_SUB_BRANCH, FLEX_VALUE))
                         GROUP BY RRA.ATTRIBUTE1,
                                  RRA.DESCRIPTION,
                                  GCC.SEGMENT4,
                                  FFV.DESCRIPTION,
                                  RRA.CHANGE_SIGN_FLAG
                         UNION ALL
                           SELECT RRA.ATTRIBUTE1
                                      NOTES,
                                  RRA.DESCRIPTION
                                      NOTES_NAME,
                                  GCC.SEGMENT4
                                      ACCOUNT,
                                  FFV.DESCRIPTION,
                                  0
                                      CURRENT_PERIOD,
                                    (CASE WHEN RRA.CHANGE_SIGN_FLAG = 'Y' THEN -1 ELSE 1 END)
                                  * (SUM (
                                           (CASE WHEN SIGN = '-' THEN -1 ELSE 1 END)
                                         * (NVL (BAL.PERIOD_NET_DR, 0) - NVL (BAL.PERIOD_NET_CR, 0))))
                                      PREVIOUS_PERIOD,
                                  0
                                      CURRENT_BUDGET
                             FROM GL_BALANCES            BAL,
                                  GL_CODE_COMBINATIONS   GCC,
                                  FND_FLEX_VALUES_VL     FFV,
                                  GL_PERIOD_STATUSES     GPS,
                                  RG_REPORT_AXES         RRA,
                                  RG_REPORT_AXIS_CONTENTS RAC
                            WHERE     BAL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                                  AND GCC.SEGMENT4 = FFV.FLEX_VALUE
                                  AND BAL.LEDGER_ID = GPS.LEDGER_ID
                                  AND BAL.PERIOD_NAME = GPS.PERIOD_NAME
                                  AND BAL.ACTUAL_FLAG = 'A'
                                  AND BAL.CURRENCY_CODE = 'BDT'
                                  AND FFV.FLEX_VALUE_SET_ID = 1016494
                                  AND GPS.APPLICATION_ID = 101
                                  AND GCC.TEMPLATE_ID IS NULL
                                  AND GCC.SUMMARY_FLAG = 'N'
                                  AND RRA.AXIS_SET_ID = RAC.AXIS_SET_ID
                                  AND RRA.AXIS_SEQ = RAC.AXIS_SEQ
                                  AND BAL.LEDGER_ID = P_LEDGER_ID
                                  AND RRA.AXIS_SET_ID = 1002
                                  AND GPS.EFFECTIVE_PERIOD_NUM >= P_PREVIOUS_PERIOD_FROM
                                  AND GPS.EFFECTIVE_PERIOD_NUM <= P_PREVIOUS_PERIOD_TO
                                  AND (CASE
                                           WHEN P_COMPANY = 100 AND GCC.SEGMENT1 BETWEEN 101 AND 599
                                           THEN
                                               1
                                           WHEN     P_COMPANY BETWEEN 101 AND 599
                                                AND GCC.SEGMENT1 = P_COMPANY
                                           THEN
                                               1
                                           ELSE
                                               NULL
                                       END) =
                                      1
                                  AND GCC.SEGMENT2 BETWEEN NVL (RAC.SEGMENT2_LOW, GCC.SEGMENT2)
                                                       AND NVL (RAC.SEGMENT2_HIGH, GCC.SEGMENT2)
                                  AND GCC.SEGMENT3 BETWEEN NVL (RAC.SEGMENT3_LOW, GCC.SEGMENT3)
                                                       AND NVL (RAC.SEGMENT3_HIGH, GCC.SEGMENT3)
                                  AND GCC.SEGMENT4 BETWEEN NVL (RAC.SEGMENT4_LOW, GCC.SEGMENT4)
                                                       AND NVL (RAC.SEGMENT4_HIGH, GCC.SEGMENT4)
                                  AND GCC.SEGMENT5 BETWEEN NVL (RAC.SEGMENT5_LOW, GCC.SEGMENT5)
                                                       AND NVL (RAC.SEGMENT5_HIGH, GCC.SEGMENT5)
                                  AND GCC.SEGMENT6 BETWEEN NVL (RAC.SEGMENT6_LOW, GCC.SEGMENT6)
                                                       AND NVL (RAC.SEGMENT6_HIGH, GCC.SEGMENT6)
                                  AND GCC.SEGMENT7 BETWEEN NVL (RAC.SEGMENT7_LOW, GCC.SEGMENT7)
                                                       AND NVL (RAC.SEGMENT7_HIGH, GCC.SEGMENT7)
                                  AND GCC.SEGMENT2 IN
                                          (SELECT FLEX_VALUE
                                             FROM FND_FLEX_VALUES_VL
                                            WHERE     FLEX_VALUE_SET_ID = 1016557
                                                  AND PARENT_FLEX_VALUE_LOW =
                                                      NVL (P_BRANCH, PARENT_FLEX_VALUE_LOW)
                                                  AND FLEX_VALUE = NVL (P_SUB_BRANCH, FLEX_VALUE))
                         GROUP BY RRA.ATTRIBUTE1,
                                  RRA.DESCRIPTION,
                                  GCC.SEGMENT4,
                                  FFV.DESCRIPTION,
                                  RRA.CHANGE_SIGN_FLAG)
                  SELECT TO_NUMBER (NOTES)       ORD,
                         NOTES,
                         NOTES_NAME,
                         ACCOUNT,
                         DESCRIPTION,
                         (CASE
                              WHEN SUBSTR (ACCOUNT, 1, 1) = 5 THEN (0 - SUM (CURRENT_PERIOD))
                              ELSE SUM (CURRENT_PERIOD)
                          END)                   CURRENT_PERIOD,
                         (CASE
                              WHEN SUBSTR (ACCOUNT, 1, 1) = 5 THEN (0 - SUM (PREVIOUS_PERIOD))
                              ELSE SUM (PREVIOUS_PERIOD)
                          END)                   PREVIOUS_PERIOD,
                         SUM (CURRENT_BUDGET)    CURRENT_BUDGET
                    FROM XX_WITH_CLAUSE_TAB
                   WHERE NOTES IS NOT NULL AND P_PROCESS_MODE = 'F'
                  HAVING (   SUM (CURRENT_PERIOD) <> 0
                          OR SUM (PREVIOUS_PERIOD) <> 0
                          OR SUM (CURRENT_BUDGET) <> 0)
                GROUP BY TO_NUMBER (NOTES),
                         NOTES,
                         NOTES_NAME,
                         ACCOUNT,
                         DESCRIPTION;
        END;
    END;
END;
/
