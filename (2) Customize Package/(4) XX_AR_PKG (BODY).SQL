
CREATE OR REPLACE PACKAGE BODY APPS.XX_AR_PKG
AS
    FUNCTION GL_ID_REC (P_CUST_ACCT_SITE_ID NUMBER)
        RETURN NUMBER
    AS
        L_OUTPUT   NUMBER;
    BEGIN
        SELECT XX_GL_PKG.CREATE_GET_GL_CCID (
                      OCB.COMPANY_CODE
                   || '.'
                   || OCB.BRANCH_CODE
                   || '.'
                   || DEP.FLEX_VALUE
                   || '.12020101.99.999.999')
          INTO L_OUTPUT
          FROM HZ_CUST_ACCOUNTS         HCA,
               HZ_CUST_ACCT_SITES_ALL   CAS,
               XX_ORG_COMPANY_BRANCH_V  OCB,
               FND_FLEX_VALUES_VL       DEP
         WHERE     HCA.CUST_ACCOUNT_ID = CAS.CUST_ACCOUNT_ID
               AND CAS.ORG_ID = OCB.ORG_ID
               AND UPPER (HCA.ACCOUNT_NAME) = UPPER (DEP.DESCRIPTION)
               AND DEP.FLEX_VALUE_SET_ID = 1016493
               AND CAS.CUST_ACCT_SITE_ID = P_CUST_ACCT_SITE_ID;

        RETURN (CASE WHEN L_OUTPUT > 0 THEN L_OUTPUT ELSE NULL END);
    EXCEPTION
        WHEN OTHERS
        THEN
            RAISE;
    END;


    FUNCTION GL_ID_REV (P_CUST_ACCT_SITE_ID NUMBER)
        RETURN NUMBER
    AS
        L_OUTPUT   NUMBER;
    BEGIN
        SELECT XX_GL_PKG.CREATE_GET_GL_CCID (
                      OCB.COMPANY_CODE
                   || '.'
                   || OCB.BRANCH_CODE
                   || '.'
                   || DEP.FLEX_VALUE
                   || '.41010101.99.999.999')
          INTO L_OUTPUT
          FROM HZ_CUST_ACCOUNTS         HCA,
               HZ_CUST_ACCT_SITES_ALL   CAS,
               XX_ORG_COMPANY_BRANCH_V  OCB,
               FND_FLEX_VALUES_VL       DEP
         WHERE     HCA.CUST_ACCOUNT_ID = CAS.CUST_ACCOUNT_ID
               AND CAS.ORG_ID = OCB.ORG_ID
               AND UPPER (HCA.ACCOUNT_NAME) = UPPER (DEP.DESCRIPTION)
               AND DEP.FLEX_VALUE_SET_ID = 1016493
               AND CAS.CUST_ACCT_SITE_ID = P_CUST_ACCT_SITE_ID;

        RETURN (CASE WHEN L_OUTPUT > 0 THEN L_OUTPUT ELSE NULL END);
    EXCEPTION
        WHEN OTHERS
        THEN
            RAISE;
    END;


    FUNCTION GET_CUSTOMER_NAME_FROM_NUMBER (P_CUSTOMER_NUMBER VARCHAR2)
        RETURN VARCHAR2
    AS
        L_OUTPUT   VARCHAR2 (512);
    BEGIN
        SELECT DISTINCT CUSTOMER_NAME
          INTO L_OUTPUT
          FROM XX_AR_CUSTOMER_SITE_V
         WHERE CUSTOMER_NUMBER = P_CUSTOMER_NUMBER;

        RETURN L_OUTPUT;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 'No Customer Found';
    END;

    FUNCTION GET_CUSTOMER_NUMBER_FROM_ID (P_CUSTOMER_ID NUMBER)
        RETURN VARCHAR2
    AS
        L_OUTPUT   VARCHAR2 (512);
    BEGIN
        SELECT DISTINCT CUSTOMER_NUMBER
          INTO L_OUTPUT
          FROM XX_AR_CUSTOMER_SITE_V
         WHERE CUSTOMER_ID = P_CUSTOMER_ID;

        RETURN UPPER (L_OUTPUT);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 'No Customer Found';
    END;


    FUNCTION GET_CUSTOMER_NAME_FROM_ID (P_CUSTOMER_ID NUMBER)
        RETURN VARCHAR2
    AS
        L_OUTPUT   VARCHAR2 (512);
    BEGIN
        SELECT DISTINCT CUSTOMER_NAME
          INTO L_OUTPUT
          FROM XX_AR_CUSTOMER_SITE_V
         WHERE CUSTOMER_ID = P_CUSTOMER_ID;

        RETURN L_OUTPUT;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 'No Customer Found';
    END;



    PROCEDURE CASH_CREATE_AND_APPLY (P_ORG_ID          IN NUMBER,
                                     P_DEPARTMENT_ID   IN NUMBER,
                                     P_DATE_FROM       IN DATE,
                                     P_DATE_TO         IN DATE,
                                     P_PROCESS_MODE    IN VARCHAR2)
    IS
        --Input parameters
        L_REQUEST_ID   PLS_INTEGER := FND_GLOBAL.CONC_REQUEST_ID;
        L_USER_ID      PLS_INTEGER := FND_GLOBAL.USER_ID;
        L_LOGIN_ID     PLS_INTEGER := FND_GLOBAL.CONC_LOGIN_ID;
		
    BEGIN
        IF L_REQUEST_ID > 0
        THEN
            FND_GLOBAL.APPS_INITIALIZE (USER_ID        => FND_GLOBAL.USER_ID,
                                        RESP_ID        => FND_GLOBAL.RESP_ID,
                                        RESP_APPL_ID   => FND_GLOBAL.RESP_APPL_ID);
            MO_GLOBAL.INIT ('AR');
        END IF;

        --Backup Deleted Data
        INSERT INTO XX_CASH_CREATE_AND_APPLY_BKP (ORG_ID,
                                                  RECEIPT_NUMBER,
                                                  CUSTOMER_TRX_ID,
                                                  GL_DATE,
                                                  CUSTOMER_ID,
                                                  CUSTOMER_NUMBER,
                                                  CUSTOMER_NAME,
                                                  LOCATION,
                                                  AMOUNT,
                                                  RECEIPT_METHOD_ID,
                                                  PROCESS_FLAG,
                                                  PROCESS_DATE,
                                                  REQUEST_ID,
                                                  CREATED_BY,
                                                  CREATION_DATE,
                                                  LAST_UPDATED_BY,
                                                  LAST_UPDATE_DATE,
                                                  LAST_UPDATE_LOGIN)
            SELECT ORG_ID,
                   RECEIPT_NUMBER,
                   CUSTOMER_TRX_ID,
                   GL_DATE,
                   CUSTOMER_ID,
                   CUSTOMER_NUMBER,
                   CUSTOMER_NAME,
                   LOCATION,
                   AMOUNT,
                   RECEIPT_METHOD_ID,
                   PROCESS_FLAG,
                   PROCESS_DATE,
                   REQUEST_ID,
                   CREATED_BY,
                   CREATION_DATE,
                   LAST_UPDATED_BY,
                   LAST_UPDATE_DATE,
                   LAST_UPDATE_LOGIN
              FROM XX_CASH_CREATE_AND_APPLY
             WHERE CASH_RECEIPT_ID IS NULL;

        --PROCESS_FLAG = 'N' AND NVL (PROCESS_FLAG, 'N') <> 'Y';

        --Delete Draft data from custom table
        DELETE FROM XX_CASH_CREATE_AND_APPLY
              WHERE CASH_RECEIPT_ID IS NULL;

        -- PROCESS_FLAG = 'N' AND NVL (PROCESS_FLAG, 'N') <> 'Y';

        COMMIT;

        --Populate Cash Data
        INSERT INTO XX_CASH_CREATE_AND_APPLY (ORG_ID,
                                              RECEIPT_NUMBER,
                                              CUSTOMER_TRX_ID,
                                              GL_DATE,
                                              CUSTOMER_ID,
                                              CUSTOMER_NUMBER,
                                              CUSTOMER_NAME,
                                              LOCATION,
                                              AMOUNT,
                                              RECEIPT_METHOD_ID,
                                              PROCESS_FLAG,
                                              PROCESS_DATE,
                                              REQUEST_ID,
                                              CREATED_BY,
                                              CREATION_DATE,
                                              LAST_UPDATED_BY,
                                              LAST_UPDATE_DATE,
                                              LAST_UPDATE_LOGIN)
              SELECT RCT.ORG_ID,
                     RCT.DOC_SEQUENCE_VALUE
                         RECEIPT_NUMBER,
                     RCT.CUSTOMER_TRX_ID,
                     APS.GL_DATE,
                     CST.CUSTOMER_ID,
                     CST.CUSTOMER_NUMBER,
                     CST.CUSTOMER_NAME,
                     CST.LOCATION,
                     APS.AMOUNT_DUE_REMAINING
                         AMOUNT,
                     ARM.RECEIPT_METHOD_ID,
                     (CASE
                          WHEN P_PROCESS_MODE = 'F' THEN 'Y'
                          WHEN P_PROCESS_MODE = 'D' THEN 'N'
                          ELSE NULL
                      END),
                     SYSDATE,
                     L_REQUEST_ID,
                     L_USER_ID,
                     SYSDATE,
                     L_USER_ID,
                     SYSDATE,
                     L_LOGIN_ID
                FROM AR_PAYMENT_SCHEDULES_ALL      APS,
                     RA_CUSTOMER_TRX_ALL           RCT,
                     XX_AR_CUSTOMER_SITE_V         CST,
                     AR_RECEIPT_METHODS            ARM,
                     AR_RECEIPT_METHOD_ACCOUNTS_ALL RMA,
                     CE_BANK_ACCT_USES_ALL         BAU,
                     XX_AUTO_CASH_DEPARTMENTS_V    ACD
               WHERE     APS.ORG_ID = RCT.ORG_ID
                     AND APS.CUSTOMER_TRX_ID = RCT.CUSTOMER_TRX_ID
                     AND RCT.ORG_ID = CST.ORG_ID
                     AND RCT.BILL_TO_CUSTOMER_ID = CST.CUSTOMER_ID
                     AND ARM.RECEIPT_METHOD_ID = RMA.RECEIPT_METHOD_ID
                     AND CST.ORG_ID = RMA.ORG_ID
                     AND RMA.ORG_ID = BAU.ORG_ID
                     AND RMA.REMIT_BANK_ACCT_USE_ID = BAU.BANK_ACCT_USE_ID
                     AND APS.STATUS = 'OP'
                     AND APS.CLASS = 'INV'
                     AND RCT.COMPLETE_FLAG = 'Y'
                     AND CST.SITE_USE_CODE = 'BILL_TO'
                     AND CST.PRIMARY_FLAG = 'Y'
                     AND CST.STATUS = 'A'
                     AND CST.SITE_USE_STATUS = 'A'
                     AND CST.ACCT_USE_STATUS = 'A'
                     AND NVL (APS.AMOUNT_DUE_REMAINING, 0) <> 0
                     AND BAU.BANK_ACCOUNT_ID IN (11017, 11019, 11021)
                     AND UPPER (CST.ACCOUNT_NAME) = UPPER (ACD.DESCRIPTION)
                     AND RCT.ORG_ID = NVL (P_ORG_ID, RCT.ORG_ID)
                     AND ACD.DEPT_CODE = NVL (P_DEPARTMENT_ID, ACD.DEPT_CODE)
                     AND APS.GL_DATE BETWEEN P_DATE_FROM AND P_DATE_TO
            ORDER BY RCT.ORG_ID, APS.GL_DATE;


        COMMIT;

        DECLARE
            L_CASH_RECEIPT_ID   NUMBER := 0;
            L_RETURN_STATUS     VARCHAR2 (1);
            L_MSG_COUNT         NUMBER;
            L_MSG_DATA          VARCHAR2 (4000);

            CURSOR CUR IS
                  SELECT CCA.ROWID     ROW_ID,
                         CCA.ORG_ID,
                         CCA.RECEIPT_NUMBER,
                         CCA.CUSTOMER_TRX_ID,
                         CCA.GL_DATE,
                         CCA.CUSTOMER_ID,
                         CCA.CUSTOMER_NUMBER,
                         CCA.CUSTOMER_NAME,
                         CCA.LOCATION,
                         CCA.AMOUNT,
                         CCA.RECEIPT_METHOD_ID
                    FROM XX_CASH_CREATE_AND_APPLY CCA
                   WHERE     CCA.CASH_RECEIPT_ID IS NULL
                         AND CCA.PROCESS_FLAG = 'Y'
                         AND P_PROCESS_MODE = 'F'
                ORDER BY CCA.ORG_ID, CCA.GL_DATE;
        BEGIN
            FOR REC IN CUR
            LOOP
                MO_GLOBAL.SET_POLICY_CONTEXT ('S', REC.ORG_ID);

                AR_RECEIPT_API_PUB.CREATE_AND_APPLY (P_API_VERSION         => 1.0,
                                                     P_ORG_ID              => REC.ORG_ID,
                                                     P_RECEIPT_METHOD_ID   => REC.RECEIPT_METHOD_ID,
                                                     P_RECEIPT_NUMBER      => REC.RECEIPT_NUMBER,
                                                     P_CURRENCY_CODE       => 'BDT',
                                                     P_AMOUNT              => REC.AMOUNT,
                                                     P_RECEIPT_DATE        => REC.GL_DATE,
                                                     P_GL_DATE             => REC.GL_DATE,
                                                     P_CUSTOMER_ID         => REC.CUSTOMER_ID,
                                                     P_LOCATION            => REC.LOCATION,
                                                     P_CUSTOMER_TRX_ID     => REC.CUSTOMER_TRX_ID,
                                                     P_APPLY_DATE          => REC.GL_DATE,
                                                     P_APPLY_GL_DATE       => REC.GL_DATE,
                                                     P_CR_ID               => L_CASH_RECEIPT_ID,
                                                     X_RETURN_STATUS       => L_RETURN_STATUS,
                                                     X_MSG_COUNT           => L_MSG_COUNT,
                                                     X_MSG_DATA            => L_MSG_DATA);

                INSERT INTO XX_API_ERROR_LOGS (API_NAME,
                                               ID,
                                               DESCRIPTION,
                                               RETURN_STATUS,
                                               MSG_COUNT,
                                               MESSAGE,
                                               REQUEST_ID,
                                               CREATED_BY,
                                               CREATION_DATE,
                                               LAST_UPDATED_BY,
                                               LAST_UPDATE_DATE,
                                               LAST_UPDATE_LOGIN)
                     VALUES ('AR_RECEIPT_API_PUB.CREATE_AND_APPLY',
                             L_CASH_RECEIPT_ID,
                             'None',
                             L_RETURN_STATUS,
                             L_MSG_COUNT,
                             L_MSG_DATA,
                             L_REQUEST_ID,
                             L_USER_ID,
                             SYSDATE,
                             L_USER_ID,
                             SYSDATE,
                             L_LOGIN_ID);
							 

                UPDATE XX_CASH_CREATE_AND_APPLY
                   SET CASH_RECEIPT_ID = L_CASH_RECEIPT_ID
                 WHERE ROWID = REC.ROW_ID AND PROCESS_FLAG = 'Y' AND P_PROCESS_MODE = 'F';
            END LOOP;

            COMMIT;
        END;
    END;


    PROCEDURE WRITELOG (P_TEXT VARCHAR2)
    IS
    -- Wrapper Prc
    -- Write LOG or 'dbms_output'
    BEGIN
        IF FND_GLOBAL.CONC_REQUEST_ID > 0
        THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, P_TEXT);
        ELSE
            DBMS_OUTPUT.ENABLE (1000000);
            DBMS_OUTPUT.PUT_LINE (P_TEXT);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END WRITELOG;

    PROCEDURE AR_TRANSACTION_APPLY (P_ORG_ID            NUMBER,
                                    P_CASH_RECEIPT_ID   NUMBER,
                                    P_RECEIPT_NUMBER    VARCHAR2,
                                    P_VOUCHER_NUMBER    VARCHAR2,
                                    P_CUSTOMER_TRX_ID   NUMBER,
                                    P_TRX_NUMBER        VARCHAR2,
                                    P_APPLY_AMOUNT      NUMBER,
                                    P_DISCOUNT_AMOUNT   NUMBER,
                                    P_APPLY_DATE        DATE,
                                    P_APPLY_GL_DATE     DATE)
    AS
        L_RETURN_STATUS     VARCHAR2 (1);
        L_MSG_COUNT         NUMBER;
        L_MSG_DATA          VARCHAR2 (240);
        L_COUNT             NUMBER;
        L_CASH_RECEIPT_ID   NUMBER;
        L_MSG_DATA_OUT      VARCHAR2 (240);
        L_MESG              VARCHAR2 (240);
        P_COUNT             NUMBER;
        V_ERROR_MSG         VARCHAR2 (4000);
    BEGIN
        MO_GLOBAL.SET_POLICY_CONTEXT ('S', P_ORG_ID);


        AR_RECEIPT_API_PUB.APPLY (P_API_VERSION        => 1.0,
                                  P_INIT_MSG_LIST      => FND_API.G_FALSE,
                                  P_COMMIT             => FND_API.G_TRUE,
                                  P_VALIDATION_LEVEL   => FND_API.G_VALID_LEVEL_FULL,
                                  X_RETURN_STATUS      => L_RETURN_STATUS,
                                  X_MSG_COUNT          => L_MSG_COUNT,
                                  X_MSG_DATA           => L_MSG_DATA,
                                  P_CASH_RECEIPT_ID    => P_CASH_RECEIPT_ID,
                                  P_CUSTOMER_TRX_ID    => P_CUSTOMER_TRX_ID,
                                  P_TRX_NUMBER         => P_TRX_NUMBER,
                                  P_AMOUNT_APPLIED     => P_APPLY_AMOUNT,
                                  P_DISCOUNT           => P_DISCOUNT_AMOUNT,
                                  P_APPLY_DATE         => P_APPLY_DATE,
                                  P_APPLY_GL_DATE      => P_APPLY_GL_DATE);

        DBMS_OUTPUT.PUT_LINE ('Message count ' || L_MSG_COUNT);
        DBMS_OUTPUT.PUT_LINE ('Status ' || L_RETURN_STATUS);

        IF L_RETURN_STATUS = 'S'
        THEN
            NULL;

            INSERT INTO XX_RECEIPT_MATCH_INVOICES (ORG_ID,
                                                   CASH_RECEIPT_ID,
                                                   CUSTOMER_TRX_ID,
                                                   CREATION_DATE)
                 VALUES (NULL,
                         P_CASH_RECEIPT_ID,
                         P_CUSTOMER_TRX_ID,
                         SYSDATE);
        ELSE
            IF L_MSG_COUNT = 1
            THEN
                V_ERROR_MSG :=
                    SUBSTR (
                           'Cash Receipt ID = '
                        || P_CASH_RECEIPT_ID
                        || ', Receipt Number = '
                        || P_RECEIPT_NUMBER
                        || ', Voucher Number = '
                        || P_VOUCHER_NUMBER
                        || ', Apply Date = '
                        || P_APPLY_DATE
                        || ', Apply GL Date = '
                        || P_APPLY_GL_DATE
                        || ', Error Message = '
                        || L_MSG_DATA,
                        1,
                        4000);
                WRITELOG (V_ERROR_MSG);

                DBMS_OUTPUT.PUT_LINE ('l_msg_data ' || L_MSG_DATA);
            ELSIF L_MSG_COUNT > 1
            THEN
                LOOP
                    L_MSG_DATA := FND_MSG_PUB.GET (FND_MSG_PUB.G_NEXT, FND_API.G_FALSE);

                    IF L_MSG_DATA IS NULL
                    THEN
                        EXIT;
                    END IF;

                    V_ERROR_MSG :=
                        SUBSTR (
                               'Cash Receipt ID = '
                            || P_CASH_RECEIPT_ID
                            || ', Receipt Number = '
                            || P_RECEIPT_NUMBER
                            || ', Voucher Number = '
                            || P_VOUCHER_NUMBER
                            || ', Apply Date = '
                            || P_APPLY_DATE
                            || ', Apply GL Date = '
                            || P_APPLY_GL_DATE
                            || ', Error Message = '
                            || L_COUNT
                            || ' ---'
                            || L_MSG_DATA,
                            1,
                            4000);
                    WRITELOG (V_ERROR_MSG);

                    DBMS_OUTPUT.PUT_LINE ('Message' || L_COUNT || ' ---' || L_MSG_DATA);
                END LOOP;
            END IF;
        END IF;

        COMMIT;
    END AR_TRANSACTION_APPLY;


    PROCEDURE RECEIPT_APPLY (ERRBUFF         OUT VARCHAR2,
                             RETCODE         OUT VARCHAR2,
                             P_ORG_ID            NUMBER,
                             P_CUSTOMER_ID       NUMBER,
                             P_DATE_TO           VARCHAR2)
    AS
        V_ERROR_MSG                  VARCHAR2 (4000);

        --- l_from_date                  DATE := TO_DATE (p_date_from, 'RRRR/MM/DD  HH24:MI:SS');
        L_TO_DATE                    DATE := TO_DATE (P_DATE_TO, 'RRRR/MM/DD  HH24:MI:SS');


        CURSOR RCVCUR IS
              SELECT CR.ORG_ID,
                     CR.PAY_FROM_CUSTOMER                                     CUSTOMER_ID,
                     CR.CASH_RECEIPT_ID,
                     CR.RECEIPT_NUMBER,
                     CR.RECEIPT_DATE,
                     CRH.GL_DATE,
                     --  '30-APR-2016' V_OPEN_AR_GL_DATE,
                     CR.DOC_SEQUENCE_VALUE                                    VOUCHER_NUMBER,
                     CR.AMOUNT                                                RECEIPT_AMOUNT,
                     NVL (SUM (RA.AMOUNT_APPLIED), 0)                         AMOUNT_APPLIED,
                     NVL (CR.AMOUNT, 0) - NVL (SUM (RA.AMOUNT_APPLIED), 0)    UNAPPLIED_RECEIPT_AMOUNT
                FROM AR_CASH_RECEIPTS_ALL          CR,
                     AR_CASH_RECEIPT_HISTORY_ALL   CRH,
                     AR_RECEIVABLE_APPLICATIONS_ALL RA
               WHERE     CR.CASH_RECEIPT_ID = CRH.CASH_RECEIPT_ID
                     AND NVL (CRH.CURRENT_RECORD_FLAG, 'N') = 'Y'
                     AND CR.TYPE = 'CASH'
                     AND CR.CASH_RECEIPT_ID = RA.CASH_RECEIPT_ID(+)
                     AND RA.DISPLAY(+) = 'Y'
                     AND CR.STATUS = 'UNAPP'
                     AND CR.CURRENCY_CODE = 'BDT'
                     AND CR.ORG_ID = P_ORG_ID
                     AND (CR.PAY_FROM_CUSTOMER = P_CUSTOMER_ID OR P_CUSTOMER_ID IS NULL)
                     AND TRUNC (CRH.GL_DATE) <= TRUNC (L_TO_DATE)
            ---   AND CR.CASH_RECEIPT_ID=7557
            GROUP BY CR.ORG_ID,
                     CR.PAY_FROM_CUSTOMER,
                     CR.CASH_RECEIPT_ID,
                     CR.RECEIPT_NUMBER,
                     CR.RECEIPT_DATE,
                     CRH.GL_DATE,
                     CR.DOC_SEQUENCE_VALUE,
                     CR.AMOUNT
              HAVING (NVL (CR.AMOUNT, 0) - NVL (SUM (RA.AMOUNT_APPLIED), 0)) > 0
            ORDER BY CR.PAY_FROM_CUSTOMER, CRH.GL_DATE;


        CURSOR TRXCUR (L_ORG_ID NUMBER, L_CUSTOMER_ID NUMBER, L_DATE_TO DATE)
        IS
              SELECT PS.TRX_NUMBER                                TRX_NUMBER,
                     CT.TRX_DATE                                  TRX_DATE,
                     PS.CUSTOMER_ID                               CUSTOMER_ID,
                     CST.ACCOUNT_NUMBER                           CUSTOMER_NUMBER,
                     SUBSTRB (CST_PARTY.PARTY_NAME, 1, 50)        CUSTOMER_NAME,
                     PS.CLASS                                     CLASS,
                     TRUNC (
                         DECODE (SIGN (PS.CUSTOMER_ID),
                                 -1, FND_DATE.CANONICAL_TO_DATE (NULL),
                                 PS.DUE_DATE))                    TRX_DUE_DATE,
                     PS.CUST_TRX_TYPE_ID                          CUST_TRX_TYPE_ID,
                     PS.INVOICE_CURRENCY_CODE                     INVOICE_CURRENCY_CODE,
                     PS.AMOUNT_DUE_REMAINING                      BALANCE_DUE_CURR_UNFORMATTED,
                     PS.ACCTD_AMOUNT_DUE_REMAINING                BALANCE_DUE_FUNCTIONAL,
                     PS.AMOUNT_DUE_ORIGINAL                       AMOUNT_DUE_ORIGINAL,
                     PS.AMOUNT_LINE_ITEMS_ORIGINAL                AMOUNT_LINE_ITEMS_ORIGINAL,
                     PS.DISCOUNT_TAKEN_EARNED                     DISCOUNT_TAKEN_EARNED,
                     PS.DISCOUNT_TAKEN_UNEARNED                   DISCOUNT_TAKEN_UNEARNED,
                     PS.EXCHANGE_RATE                             TRX_EXCHANGE_RATE,
                     CT.CUSTOMER_TRX_ID                           CUSTOMER_TRX_ID,
                     PS.GL_DATE                                   TRX_GL_DATE,
                     PS.TERM_ID                                   TERM_ID,
                     NVL (PS.AMOUNT_ADJUSTED, 0)                  AMOUNT_ADJUSTED,
                     NVL (PS.AMOUNT_ADJUSTED_PENDING, 0)          AMOUNT_ADJUSTED_PENDING,
                     NVL (PS.AMOUNT_LINE_ITEMS_REMAINING, 0)      AMOUNT_LINE_ITEMS_REMAINING,
                     NVL (PS.FREIGHT_ORIGINAL, 0)                 FREIGHT_ORIGINAL,
                     NVL (PS.FREIGHT_REMAINING, 0)                FREIGHT_REMAINING,
                     NVL (PS.RECEIVABLES_CHARGES_REMAINING, 0)    RECEIVABLES_CHARGES_REMAINING,
                     NVL (PS.TAX_ORIGINAL, 0)                     TAX_ORIGINAL,
                     NVL (PS.TAX_REMAINING, 0)                    TAX_REMAINING,
                     PS.SELECTED_FOR_RECEIPT_BATCH_ID             SELECTED_FOR_RECEIPT_BATCH_ID,
                     CT.BILL_TO_SITE_USE_ID                       BILL_TO_SITE_USE_ID,
                     CT.ORG_ID,
                     PS.AMOUNT_DUE_REMAINING
                FROM RA_CUSTOMER_TRX_ALL         CT,
                     RA_CUST_TRX_TYPES_ALL       CTT,
                     AR_PAYMENT_SCHEDULES_ALL    PS,
                     HZ_CUST_ACCOUNTS            CST,
                     HZ_PARTIES                  CST_PARTY,
                     RA_CUST_TRX_LINE_GL_DIST_ALL DIST
               WHERE     CT.CUST_TRX_TYPE_ID = CTT.CUST_TRX_TYPE_ID
                     AND CT.ORG_ID = CTT.ORG_ID
                     AND CT.CUSTOMER_TRX_ID = DIST.CUSTOMER_TRX_ID
                     AND DIST.ACCOUNT_CLASS = 'REC'
                     AND CTT.TYPE <> 'BR'
                     AND PS.CLASS IN ('CB',
                                      'CM',
                                      'DEP',
                                      'DM',
                                      'INV',
                                      'BR')
                     AND DECODE (ARP_VIEW_CONSTANTS.GET_PS_SELECTED_IN_BATCH,
                                 NULL, 1,
                                 PS.SELECTED_FOR_RECEIPT_BATCH_ID) =
                         NVL (PS.SELECTED_FOR_RECEIPT_BATCH_ID, 1)
                     AND PS.RESERVED_TYPE IS NULL
                     AND PS.RESERVED_VALUE IS NULL
                     AND PS.PAYMENT_SCHEDULE_ID NOT IN (-5, -2, -7)
                     AND CT.CUSTOMER_TRX_ID(+) = PS.CUSTOMER_TRX_ID
                     AND CT.PREVIOUS_CUSTOMER_TRX_ID IS NULL
                     AND CST.CUST_ACCOUNT_ID(+) = PS.CUSTOMER_ID
                     AND CST.PARTY_ID = CST_PARTY.PARTY_ID(+)
                     AND CT.ORG_ID = L_ORG_ID
                     AND CT.BILL_TO_CUSTOMER_ID = L_CUSTOMER_ID
                     AND CT.COMPLETE_FLAG = 'Y'
                     AND PS.AMOUNT_DUE_REMAINING <> 0
                     AND PS.GL_DATE <= TRUNC (L_DATE_TO)
            ORDER BY PS.GL_DATE ASC, PS.AMOUNT_DUE_REMAINING;

        V_TRX_APPLIED_REMAINING      NUMBER;                     -- AR Transaction Applyed Remaining
        V_UNAPPLIED_RECEIPT_AMOUNT   NUMBER;
        V_APPLY_AMOUNT               NUMBER;          -- Mature Apply Amount for current transaction

        V_APPLY_DATE                 DATE;
        V_APPLY_GL_DATE              DATE;
        --V_OPEN_AR_GL_DATE            DATE;
        V_LEDGER_ID                  NUMBER := FND_PROFILE.VALUE ('GL_SET_OF_BKS_ID');
    BEGIN
        -- Initialize Conc. Program Variables
        ERRBUFF := '';
        RETCODE := 0;

        -- Initialize Environment

        -- For Backend Call
        IF FND_GLOBAL.CONC_REQUEST_ID = 0
        THEN
            FND_GLOBAL.APPS_INITIALIZE (USER_ID        => FND_GLOBAL.USER_ID,
                                        RESP_ID        => FND_GLOBAL.RESP_ID,
                                        RESP_APPL_ID   => FND_GLOBAL.RESP_APPL_ID);
        END IF;

        /*
              SELECT MIN (START_DATE)
                INTO V_OPEN_AR_GL_DATE
                FROM GL_PERIOD_STATUSES
               WHERE SET_OF_BOOKS_ID = V_LEDGER_ID AND APPLICATION_ID = 222 AND CLOSING_STATUS = 'O';
        */

        WRITELOG (
               CHR (10)
            || '+-----------------------------------------------Error Log-----------------------------------------------+'
            || CHR (10));

        FOR RCVREC IN RCVCUR
        LOOP
            MO_GLOBAL.SET_ORG_CONTEXT (RCVREC.ORG_ID, NULL, 'AR');
            V_UNAPPLIED_RECEIPT_AMOUNT := RCVREC.UNAPPLIED_RECEIPT_AMOUNT;
            V_TRX_APPLIED_REMAINING := 0;

            V_ERROR_MSG :=
                   'V_UNAPPLIED_RECEIPT_AMOUNT '
                || V_UNAPPLIED_RECEIPT_AMOUNT
                || '        V_TRX_APPLIED_REMAINING '
                || V_TRX_APPLIED_REMAINING;

            WRITELOG (CHR (10) || V_ERROR_MSG || CHR (10));

            FOR TRXREC IN TRXCUR (RCVREC.ORG_ID, RCVREC.CUSTOMER_ID, TRUNC (L_TO_DATE))
            LOOP
                /*IF RCVREC.GL_DATE < RCVREC.V_OPEN_AR_GL_DATE AND TRXREC.TRX_GL_DATE < RCVREC.V_OPEN_AR_GL_DATE
                THEN
                   V_APPLY_DATE := RCVREC.V_OPEN_AR_GL_DATE;
                   V_APPLY_GL_DATE := RCVREC.V_OPEN_AR_GL_DATE;*/

                IF RCVREC.GL_DATE > TRXREC.TRX_GL_DATE
                THEN
                    V_APPLY_DATE := RCVREC.GL_DATE;
                    V_APPLY_GL_DATE := RCVREC.GL_DATE;
                ELSE
                    V_APPLY_DATE := TRXREC.TRX_DATE;
                    V_APPLY_GL_DATE := TRXREC.TRX_GL_DATE;
                END IF;

                ---   V_APPLY_DATE := TRXREC.TRX_DATE;
                ---  V_APPLY_GL_DATE := TRXREC.TRX_GL_DATE;
                V_ERROR_MSG :=
                    'v_apply_date ' || V_APPLY_DATE || '   v_apply_gl_date ' || V_APPLY_GL_DATE;

                WRITELOG (CHR (10) || V_ERROR_MSG || CHR (10));

                DBMS_OUTPUT.PUT_LINE ('v_apply_date ' || V_APPLY_DATE);
                --  DBMS_OUTPUT.PUT_LINE ('v_apply_gl_date ' || RCVREC.V_OPEN_AR_GL_DATE);

                V_TRX_APPLIED_REMAINING :=
                    NVL (V_TRX_APPLIED_REMAINING, 0) + TRXREC.AMOUNT_DUE_REMAINING;

                V_ERROR_MSG :=
                       'NVL (V_TRX_APPLIED_REMAINING, 0)  '
                    || NVL (V_TRX_APPLIED_REMAINING, 0)
                    || '     TRXREC.AMOUNT_DUE_REMAINING  '
                    || TRXREC.AMOUNT_DUE_REMAINING;

                WRITELOG (CHR (10) || V_ERROR_MSG || CHR (10));

                IF V_UNAPPLIED_RECEIPT_AMOUNT > V_TRX_APPLIED_REMAINING
                THEN -- The Condistion will full fill when unapplied amount is greater then current transation amount
                    V_APPLY_AMOUNT := TRXREC.AMOUNT_DUE_REMAINING;

                    V_ERROR_MSG := 'IF     V_APPLY_AMOUNT ' || V_APPLY_AMOUNT;

                    WRITELOG (CHR (10) || V_ERROR_MSG || CHR (10));

                    AR_TRANSACTION_APPLY (RCVREC.ORG_ID,
                                          RCVREC.CASH_RECEIPT_ID,
                                          RCVREC.RECEIPT_NUMBER,
                                          RCVREC.VOUCHER_NUMBER,
                                          TRXREC.CUSTOMER_TRX_ID,
                                          TRXREC.TRX_NUMBER,
                                          V_APPLY_AMOUNT,
                                          NULL,
                                          V_APPLY_DATE,
                                          V_APPLY_GL_DATE);
                ELSE
                    V_APPLY_AMOUNT :=
                          TRXREC.AMOUNT_DUE_REMAINING
                        - (V_TRX_APPLIED_REMAINING - V_UNAPPLIED_RECEIPT_AMOUNT);

                    V_ERROR_MSG := 'ELSE    V_APPLY_AMOUNT ' || V_APPLY_AMOUNT;

                    WRITELOG (CHR (10) || V_ERROR_MSG || CHR (10));

                    AR_TRANSACTION_APPLY (RCVREC.ORG_ID,
                                          RCVREC.CASH_RECEIPT_ID,
                                          RCVREC.RECEIPT_NUMBER,
                                          RCVREC.VOUCHER_NUMBER,
                                          TRXREC.CUSTOMER_TRX_ID,
                                          TRXREC.TRX_NUMBER,
                                          V_APPLY_AMOUNT,
                                          NULL,
                                          V_APPLY_DATE,
                                          V_APPLY_GL_DATE);

                    EXIT;                                                          -- Exit from Loop
                END IF;
            END LOOP;

            WRITELOG (
                   CHR (10)
                || '+-----------------------------------------------Complete Transaction Loop-----------------------------------------------+'
                || CHR (10));
        END LOOP;

        WRITELOG (
               CHR (10)
            || '+-----------------------------------------------Complete Receipt Loop-----------------------------------------------+'
            || CHR (10));
    END;


    PROCEDURE CM_AND_RECEIPT_APPLY (ERRBUFF         OUT VARCHAR2,
                                    RETCODE         OUT VARCHAR2,
                                    P_ORG_ID            NUMBER,
                                    P_CUSTOMER_ID       NUMBER,
                                    P_DATE_TO           VARCHAR2,
                                    P_TRX_TYPE          VARCHAR2)
    IS
        L_CM_APP_REC                  AR_CM_API_PUB.CM_APP_REC_TYPE;
        L_COMMENTS                    VARCHAR2 (2000);
        L_OUT_REC_APPLICATION_ID      NUMBER;
        L_ACCTD_AMOUNT_APPLIED_FROM   NUMBER;
        L_ACCTD_AMOUNT_APPLIED_TO     NUMBER;
        L_RETURN_STATUS               VARCHAR2 (1);

        L_MSG_COUNT                   NUMBER;
        L_MSG_DATA                    VARCHAR2 (2000);
        L_ORG_ID                      NUMBER;
        L_CUSTOMER_ID                 NUMBER;
        L_CM_CUSTOMER_TRX_ID          NUMBER;
        L_INV_CUSTOMER_TRX_ID         NUMBER;
        L_CASH_RECEIPT_ID             NUMBER;
        L_CUSTOMER_TRX_ID             NUMBER;

        V_DATE                        DATE := TO_DATE (P_DATE_TO, 'YYYY/MM/DD HH24:MI:SS');
    BEGIN
        FND_GLOBAL.APPS_INITIALIZE (USER_ID        => FND_GLOBAL.USER_ID,
                                    RESP_ID        => FND_GLOBAL.RESP_ID,
                                    RESP_APPL_ID   => FND_GLOBAL.RESP_APPL_ID);

        MO_GLOBAL.INIT ('AR');

        IF P_TRX_TYPE = 'CM'
        THEN
            LOOP
                WITH
                    WITH_CLAUSE_TAB
                    AS
                        (SELECT ORG_ID,
                                CUSTOMER_ID,
                                GL_DATE,
                                CM_CUSTOMER_TRX_ID,
                                INV_CUSTOMER_TRX_ID
                           FROM (SELECT APS.ORG_ID,
                                        APS.CUSTOMER_ID,
                                        APS.GL_DATE,
                                        APS.CUSTOMER_TRX_ID    CM_CUSTOMER_TRX_ID,
                                        (SELECT MIN (CUSTOMER_TRX_ID)
                                           FROM (SELECT PSI.CUSTOMER_TRX_ID,
                                                        DENSE_RANK () OVER (ORDER BY PSI.GL_DATE)    AS RNK
                                                   FROM AR_PAYMENT_SCHEDULES_ALL PSI
                                                  WHERE     APS.ORG_ID = PSI.ORG_ID
                                                        AND APS.CUSTOMER_ID = PSI.CUSTOMER_ID
                                                        AND PSI.CLASS IN ('INV')
                                                        AND PSI.AMOUNT_DUE_REMAINING > 0
                                                        AND PSI.GL_DATE <= V_DATE)
                                          WHERE RNK = 1)       INV_CUSTOMER_TRX_ID
                                   FROM AR_PAYMENT_SCHEDULES_ALL APS
                                  WHERE     APS.CLASS IN ('CM')
                                        AND APS.AMOUNT_DUE_REMAINING < 0
                                        AND APS.ORG_ID = NVL (P_ORG_ID, APS.ORG_ID)
                                        AND APS.CUSTOMER_ID = NVL (P_CUSTOMER_ID, APS.CUSTOMER_ID)
                                        AND APS.GL_DATE <= V_DATE
                                        AND EXISTS
                                                (SELECT 1
                                                   FROM AR_PAYMENT_SCHEDULES_ALL EXS
                                                  WHERE     APS.ORG_ID = EXS.ORG_ID
                                                        AND APS.CUSTOMER_ID = EXS.CUSTOMER_ID
                                                        AND EXS.AMOUNT_DUE_REMAINING > 0
                                                        AND EXS.CLASS IN ('INV')
                                                        AND EXS.GL_DATE <= V_DATE)))
                SELECT ORG_ID,
                       CUSTOMER_ID,
                       CM_CUSTOMER_TRX_ID,
                       INV_CUSTOMER_TRX_ID
                  INTO L_ORG_ID,
                       L_CUSTOMER_ID,
                       L_CM_CUSTOMER_TRX_ID,
                       L_INV_CUSTOMER_TRX_ID
                  FROM (SELECT ORG_ID,
                               CUSTOMER_ID,
                               CM_CUSTOMER_TRX_ID,
                               INV_CUSTOMER_TRX_ID,
                               DENSE_RANK ()
                                   OVER (ORDER BY
                                             ORG_ID,
                                             CUSTOMER_ID,
                                             GL_DATE,
                                             CM_CUSTOMER_TRX_ID)    AS RNK
                          FROM WITH_CLAUSE_TAB)
                 WHERE RNK = 1;

                MO_GLOBAL.SET_POLICY_CONTEXT ('S', L_ORG_ID);

                EXIT WHEN L_CUSTOMER_ID IS NULL;

                L_CM_APP_REC.CM_CUSTOMER_TRX_ID := L_CM_CUSTOMER_TRX_ID;
                L_CM_APP_REC.CM_TRX_NUMBER := NULL;
                L_CM_APP_REC.INV_CUSTOMER_TRX_ID := L_INV_CUSTOMER_TRX_ID;
                L_CM_APP_REC.INV_TRX_NUMBER := NULL;
                L_CM_APP_REC.AMOUNT_APPLIED := NULL;
                L_CM_APP_REC.APPLY_DATE := V_DATE;
                L_CM_APP_REC.GL_DATE := V_DATE;
                L_CM_APP_REC.COMMENTS := L_COMMENTS;

                AR_CM_API_PUB.APPLY_ON_ACCOUNT (
                    P_API_VERSION                 => 1.0,
                    P_INIT_MSG_LIST               => FND_API.G_FALSE,
                    P_COMMIT                      => FND_API.G_FALSE,
                    P_CM_APP_REC                  => L_CM_APP_REC,
                    X_RETURN_STATUS               => L_RETURN_STATUS,
                    X_MSG_COUNT                   => L_MSG_COUNT,
                    X_MSG_DATA                    => L_MSG_DATA,
                    X_OUT_REC_APPLICATION_ID      => L_OUT_REC_APPLICATION_ID,
                    X_ACCTD_AMOUNT_APPLIED_FROM   => L_ACCTD_AMOUNT_APPLIED_FROM,
                    X_ACCTD_AMOUNT_APPLIED_TO     => L_ACCTD_AMOUNT_APPLIED_TO);

                COMMIT;

                INSERT INTO RASHED
                     VALUES (L_CM_CUSTOMER_TRX_ID || '-' || L_INV_CUSTOMER_TRX_ID, L_MSG_DATA);

                COMMIT;
            END LOOP;
        END IF;


        IF P_TRX_TYPE = 'REC'
        THEN
            LOOP
                SELECT ORG_ID,
                       CUSTOMER_ID,
                       CUSTOMER_TRX_ID,
                       CASH_RECEIPT_ID
                  INTO L_ORG_ID,
                       L_CUSTOMER_ID,
                       L_CUSTOMER_TRX_ID,
                       L_CASH_RECEIPT_ID
                  FROM (SELECT APS.ORG_ID,
                               APS.CUSTOMER_ID,
                               APS.CUSTOMER_TRX_ID,
                               (  SELECT MIN (REC.CASH_RECEIPT_ID)
                                    FROM AR_PAYMENT_SCHEDULES_ALL REC
                                   WHERE     APS.ORG_ID = REC.ORG_ID
                                         AND APS.CUSTOMER_ID = REC.CUSTOMER_ID
                                         AND REC.CLASS = 'PMT'
                                         AND REC.STATUS = 'OP'
                                         AND REC.GL_DATE <= V_DATE
                                GROUP BY REC.ORG_ID, REC.CUSTOMER_ID)    CASH_RECEIPT_ID
                          FROM AR_PAYMENT_SCHEDULES_ALL APS
                         WHERE     APS.CLASS IN ('INV')
                               AND APS.AMOUNT_DUE_REMAINING > 0
                               AND APS.ORG_ID = NVL (P_ORG_ID, APS.ORG_ID)
                               AND APS.CUSTOMER_ID = NVL (P_CUSTOMER_ID, APS.CUSTOMER_ID)
                               AND APS.GL_DATE <= V_DATE
                               AND EXISTS
                                       (SELECT 1
                                          FROM AR_PAYMENT_SCHEDULES_ALL RPC
                                         WHERE     APS.ORG_ID = RPC.ORG_ID
                                               AND APS.CUSTOMER_ID = RPC.CUSTOMER_ID
                                               AND RPC.AMOUNT_DUE_REMAINING <> 0
                                               AND RPC.CUSTOMER_ID IS NOT NULL
                                               AND RPC.CLASS = 'PMT'
                                               AND RPC.STATUS = 'OP'
                                               AND RPC.GL_DATE <= V_DATE) -- order by CUSTOMER_TRX_ID
                                                                         )
                 WHERE ROWNUM = 1 AND CUSTOMER_TRX_ID IS NOT NULL AND CASH_RECEIPT_ID IS NOT NULL;


                MO_GLOBAL.SET_POLICY_CONTEXT ('S', L_ORG_ID);

                EXIT WHEN L_CUSTOMER_ID IS NULL;

                AR_RECEIPT_API_PUB.APPLY (P_API_VERSION       => 1.0,
                                          P_ORG_ID            => FND_PROFILE.VALUE (L_ORG_ID),
                                          P_CUSTOMER_TRX_ID   => L_CUSTOMER_TRX_ID,
                                          P_CASH_RECEIPT_ID   => L_CASH_RECEIPT_ID,
                                          P_APPLY_DATE        => V_DATE,
                                          P_APPLY_GL_DATE     => V_DATE,
                                          P_AMOUNT_APPLIED    => NULL,
                                          X_RETURN_STATUS     => L_RETURN_STATUS,
                                          X_MSG_COUNT         => L_MSG_COUNT,
                                          X_MSG_DATA          => L_MSG_DATA);

                COMMIT;

                INSERT INTO RASHED
                     VALUES (L_CUSTOMER_TRX_ID || '-' || L_CASH_RECEIPT_ID, L_MSG_DATA);

                COMMIT;
            END LOOP;
        END IF;
    END;



    FUNCTION GET_BRANCH_FROM_AGENCY (P_AGENCY_CODE IN VARCHAR2, P_DATE IN DATE)
        RETURN VARCHAR2
    AS
        V_AGENCY_CODE   VARCHAR2 (3);
    BEGIN
        WITH
            XX_WITH_CLAUSE_TAB
            AS
                (SELECT UPPER (TRIM (BRANCH_CODE))     BRANCH_CODE
                   FROM XX_AGENCY_DETAILS_V
                  WHERE     AGENCY_CODE = UPPER (P_AGENCY_CODE)
                        AND P_DATE BETWEEN START_DATE AND END_DATE
                 UNION ALL
                 SELECT DISTINCT UPPER (TRIM (BRANCH_CODE))     BRANCH_CODE
                   FROM XX_ORG_COMPANY_BRANCH_V
                  WHERE     BRANCH_CODE = UPPER (P_AGENCY_CODE)
                        AND P_DATE BETWEEN START_DATE AND END_DATE)
        SELECT BRANCH_CODE
          INTO V_AGENCY_CODE
          FROM XX_WITH_CLAUSE_TAB;

        RETURN V_AGENCY_CODE;
    EXCEPTION
        WHEN OTHERS
        THEN
            RAISE_APPLICATION_ERROR (-20101, P_AGENCY_CODE || ' Branch is missing');
    END;


    FUNCTION IS_BRANCH (P_UNIT VARCHAR2)
        RETURN VARCHAR2
    AS
        V_OUTPUT   VARCHAR2 (1);
    BEGIN
          SELECT 'Y'
            INTO V_OUTPUT
            FROM XX_ORG_COMPANY_BRANCH_V
           WHERE UPPER (BRANCH_CODE) = UPPER (P_UNIT)
           and TRUNC (SYSDATE) <= TRUNC (NVL (END_DATE, SYSDATE))
        GROUP BY UPPER (BRANCH_CODE);


        RETURN V_OUTPUT;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            RETURN 'N';
    END;


    FUNCTION IS_AGENCY (P_UNIT VARCHAR2)
        RETURN VARCHAR2
    AS
        V_OUTPUT   VARCHAR2 (1);
    BEGIN
          SELECT 'Y'
            INTO V_OUTPUT
            FROM XX_AGENCY_DETAILS
           WHERE     UPPER (AGENCY_CODE) = UPPER (P_UNIT)
                 AND TRUNC (SYSDATE) >= TRUNC (NVL (START_DATE, SYSDATE))
                 AND TRUNC (SYSDATE) <= TRUNC (NVL (END_DATE, SYSDATE))
        GROUP BY UPPER (AGENCY_CODE);


        RETURN V_OUTPUT;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            RETURN 'N';
    END;

    FUNCTION GET_ORG_ID_FROM_PCM_UNIT (P_UNIT_CODE VARCHAR2, P_COMPANY_ID NUMBER)
        RETURN NUMBER
    AS
        L_OUTPUT   NUMBER;
    BEGIN
        SELECT OCB.ORG_ID
          INTO L_OUTPUT
          FROM (SELECT DISTINCT UPPER (TRIM (BRANCH_CODE))     BRANCH_CODE
                  FROM XX_ORG_COMPANY_BRANCH_V
                 WHERE UPPER (BRANCH_CODE) = UPPER (P_UNIT_CODE)
                UNION ALL
                SELECT UPPER (TRIM (BRANCH_CODE))     BRANCH_CODE
                  FROM XX_AGENCY_DETAILS
                 WHERE UPPER (AGENCY_CODE) = UPPER (P_UNIT_CODE)) UNT,
               XX_ORG_COMPANY_BRANCH_V  OCB
         WHERE UNT.BRANCH_CODE = OCB.BRANCH_CODE AND SUBSTR (OCB.COMPANY_CODE, 1, 1) = P_COMPANY_ID;

        RETURN L_OUTPUT;
    EXCEPTION
        WHEN OTHERS
        THEN
            RAISE_APPLICATION_ERROR (-20101, UPPER (P_UNIT_CODE) || ' has errors');
    END;

    PROCEDURE UPLOAD_NEW_AGENCY (ERRBUF             OUT NOCOPY VARCHAR2,
                                 RETCODE            OUT NOCOPY VARCHAR2,
                                 P_AGENCY_CODE   IN            VARCHAR2,
                                 P_DEPT_CODE     IN            NUMBER)
    IS
    BEGIN
        FND_GLOBAL.APPS_INITIALIZE (USER_ID        => FND_GLOBAL.USER_ID,
                                    RESP_ID        => FND_GLOBAL.RESP_ID,
                                    RESP_APPL_ID   => FND_GLOBAL.RESP_APPL_ID);
        MO_GLOBAL.INIT ('AR');

        -- 1. Create A Party and an Initial Account
        --    HZ_PARTIES
        --    HZ_CUST_ACCOUNTS

        DECLARE
            P_CUST_ACCOUNT_REC       HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
            P_ORGANIZATION_REC       HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
            P_CUSTOMER_PROFILE_REC   HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
            P_CREATED_BY_MODULE      VARCHAR2 (16) := 'XX_CUSTOM_API';
            X_CUST_ACCOUNT_ID        NUMBER;
            X_ACCOUNT_NUMBER         VARCHAR2 (2000);
            X_PARTY_ID               NUMBER;
            X_PARTY_NUMBER           VARCHAR2 (2000);
            X_PROFILE_ID             NUMBER;
            X_RETURN_STATUS          VARCHAR2 (2000);
            X_MSG_COUNT              NUMBER;
            X_MSG_DATA               VARCHAR2 (2000);

            CURSOR CUR IS
                  SELECT UPPER (AGENCY_CODE)                           AGENCY_CODE,
                         UPPER (AGENCY_CODE) || '-' || AGENCY_NAME     ORGANIZATION_NAME,
                         'Credit and Service'                          ACCOUNT_NAME
                    FROM XX_AGENCY_DETAILS
                   WHERE PARTY_ID IS NULL AND UPPER (AGENCY_CODE) = UPPER (P_AGENCY_CODE)
                ORDER BY AGENCY_CODE;
        BEGIN
            FOR REC IN CUR
            LOOP
                P_ORGANIZATION_REC.ORGANIZATION_NAME := REC.ORGANIZATION_NAME;
                P_ORGANIZATION_REC.CREATED_BY_MODULE := P_CREATED_BY_MODULE;

                P_CUST_ACCOUNT_REC.ACCOUNT_NAME := REC.ACCOUNT_NAME;
                P_CUST_ACCOUNT_REC.CREATED_BY_MODULE := P_CREATED_BY_MODULE;

                HZ_CUST_ACCOUNT_V2PUB.CREATE_CUST_ACCOUNT (
                    P_INIT_MSG_LIST          => FND_API.G_TRUE,
                    P_CUST_ACCOUNT_REC       => P_CUST_ACCOUNT_REC,
                    P_ORGANIZATION_REC       => P_ORGANIZATION_REC,
                    P_CUSTOMER_PROFILE_REC   => P_CUSTOMER_PROFILE_REC,
                    P_CREATE_PROFILE_AMT     => FND_API.G_FALSE,
                    X_CUST_ACCOUNT_ID        => X_CUST_ACCOUNT_ID,
                    X_ACCOUNT_NUMBER         => X_ACCOUNT_NUMBER,
                    X_PARTY_ID               => X_PARTY_ID,
                    X_PARTY_NUMBER           => X_PARTY_NUMBER,
                    X_PROFILE_ID             => X_PROFILE_ID,
                    X_RETURN_STATUS          => X_RETURN_STATUS,
                    X_MSG_COUNT              => X_MSG_COUNT,
                    X_MSG_DATA               => X_MSG_DATA);

                UPDATE XX_AGENCY_DETAILS
                   SET PARTY_ID = X_PARTY_ID
                 WHERE AGENCY_CODE = REC.AGENCY_CODE;
            END LOOP;
        END;

        -- 2. Add Other Account
        --    HZ_CUST_ACCOUNTS

        DECLARE
            P_CUST_ACCOUNT_REC       HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
            P_ORGANIZATION_REC       HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
            P_CUSTOMER_PROFILE_REC   HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
            P_CREATED_BY_MODULE      VARCHAR2 (16) := 'XX_CUSTOM_API';
            X_CUST_ACCOUNT_ID        NUMBER;
            X_ACCOUNT_NUMBER         VARCHAR2 (2000);
            X_PARTY_ID               NUMBER;
            X_PARTY_NUMBER           VARCHAR2 (2000);
            X_PROFILE_ID             NUMBER;
            X_RETURN_STATUS          VARCHAR2 (2000);
            X_MSG_COUNT              NUMBER;
            X_MSG_DATA               VARCHAR2 (2000);

            CURSOR CUR IS
                  SELECT DISTINCT
                         HZP.PARTY_ID, HZP.PARTY_NAME ORGANIZATION_NAME, DEP.DESCRIPTION ACCOUNT_NAME
                    FROM HZ_PARTIES HZP, XX_AGENCY_DETAILS XAD, XX_AGENCY_DEPARTMENTS_V DEP
                   WHERE     HZP.PARTY_ID = XAD.PARTY_ID
                         AND UPPER (XAD.AGENCY_CODE) = UPPER (P_AGENCY_CODE)
                         AND DEP.DEPT_CODE = NVL (P_DEPT_CODE, DEP.DEPT_CODE)
                         AND NOT EXISTS
                                 (SELECT 1
                                    FROM HZ_CUST_ACCOUNTS HCA
                                   WHERE     XAD.PARTY_ID = HCA.PARTY_ID
                                         AND UPPER (DEP.DESCRIPTION) = UPPER (HCA.ACCOUNT_NAME))
                ORDER BY HZP.PARTY_ID, DEP.DESCRIPTION;
        BEGIN
            FOR REC IN CUR
            LOOP
                P_ORGANIZATION_REC.PARTY_REC.PARTY_ID := REC.PARTY_ID;
                P_ORGANIZATION_REC.ORGANIZATION_NAME := REC.ORGANIZATION_NAME;
                P_ORGANIZATION_REC.CREATED_BY_MODULE := P_CREATED_BY_MODULE;

                P_CUST_ACCOUNT_REC.ACCOUNT_NAME := REC.ACCOUNT_NAME;
                P_CUST_ACCOUNT_REC.CREATED_BY_MODULE := P_CREATED_BY_MODULE;

                HZ_CUST_ACCOUNT_V2PUB.CREATE_CUST_ACCOUNT (
                    P_INIT_MSG_LIST          => FND_API.G_TRUE,
                    P_CUST_ACCOUNT_REC       => P_CUST_ACCOUNT_REC,
                    P_ORGANIZATION_REC       => P_ORGANIZATION_REC,
                    P_CUSTOMER_PROFILE_REC   => P_CUSTOMER_PROFILE_REC,
                    P_CREATE_PROFILE_AMT     => FND_API.G_FALSE,
                    X_CUST_ACCOUNT_ID        => X_CUST_ACCOUNT_ID,
                    X_ACCOUNT_NUMBER         => X_ACCOUNT_NUMBER,
                    X_PARTY_ID               => X_PARTY_ID,
                    X_PARTY_NUMBER           => X_PARTY_NUMBER,
                    X_PROFILE_ID             => X_PROFILE_ID,
                    X_RETURN_STATUS          => X_RETURN_STATUS,
                    X_MSG_COUNT              => X_MSG_COUNT,
                    X_MSG_DATA               => X_MSG_DATA);
            END LOOP;
        END;

        -- 4. Create A Party Site
        --    HZ_PARTY_SITES

        DECLARE
            P_PARTY_SITE_REC      HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;
            P_CREATED_BY_MODULE   VARCHAR2 (16) := 'XX_CUSTOM_API';
            X_PARTY_SITE_ID       NUMBER;
            X_PARTY_SITE_NUMBER   VARCHAR2 (2000);
            X_RETURN_STATUS       VARCHAR2 (2000);
            X_MSG_COUNT           NUMBER;
            X_MSG_DATA            VARCHAR2 (2000);

            CURSOR CUR IS
                SELECT HZP.PARTY_ID, HZP.PARTY_NAME, 228 LOCATION_ID
                  FROM HZ_PARTIES HZP, XX_AGENCY_DETAILS XAD
                 WHERE     HZP.PARTY_ID = XAD.PARTY_ID
                       AND UPPER (XAD.AGENCY_CODE) = UPPER (P_AGENCY_CODE)
                       AND NOT EXISTS
                               (SELECT 1
                                  FROM HZ_PARTY_SITES HPS
                                 WHERE HZP.PARTY_ID = HPS.PARTY_ID);
        BEGIN
            FOR REC IN CUR
            LOOP
                P_PARTY_SITE_REC.PARTY_ID := REC.PARTY_ID;
                P_PARTY_SITE_REC.LOCATION_ID := REC.LOCATION_ID;
                P_PARTY_SITE_REC.IDENTIFYING_ADDRESS_FLAG := 'Y';
                P_PARTY_SITE_REC.CREATED_BY_MODULE := P_CREATED_BY_MODULE;

                HZ_PARTY_SITE_V2PUB.CREATE_PARTY_SITE (P_INIT_MSG_LIST       => FND_API.G_TRUE,
                                                       P_PARTY_SITE_REC      => P_PARTY_SITE_REC,
                                                       X_PARTY_SITE_ID       => X_PARTY_SITE_ID,
                                                       X_PARTY_SITE_NUMBER   => X_PARTY_SITE_NUMBER,
                                                       X_RETURN_STATUS       => X_RETURN_STATUS,
                                                       X_MSG_COUNT           => X_MSG_COUNT,
                                                       X_MSG_DATA            => X_MSG_DATA);
            END LOOP;
        END;

        -- 5. Create an Account Site
        --    HZ_CUST_ACCT_SITES_ALL

        DECLARE
            P_CUST_ACCT_SITE_REC   HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
            P_CREATED_BY_MODULE    VARCHAR2 (16) := 'XX_CUSTOM_API';
            X_RETURN_STATUS        VARCHAR2 (2000);
            X_MSG_COUNT            NUMBER;
            X_MSG_DATA             VARCHAR2 (2000);
            X_CUST_ACCT_SITE_ID    NUMBER;

            CURSOR CUR IS
                SELECT OCB.ORG_ID,
                       HZP.PARTY_ID,
                       HZP.PARTY_NAME,
                       HPS.PARTY_SITE_ID,
                       HCA.CUST_ACCOUNT_ID,
                       HCA.ACCOUNT_NAME
                  FROM XX_AGENCY_DETAILS        XAD,
                       HZ_PARTIES               HZP,
                       HZ_CUST_ACCOUNTS         HCA,
                       HZ_PARTY_SITES           HPS,
                       XX_AGENCY_DEPARTMENTS_V  DEP,
                       XX_ORG_COMPANY_BRANCH_V  OCB
                 WHERE     XAD.PARTY_ID = HZP.PARTY_ID
                       AND HZP.PARTY_ID = HCA.PARTY_ID
                       AND HCA.PARTY_ID = HPS.PARTY_ID
                       AND UPPER (HCA.ACCOUNT_NAME) = UPPER (DEP.DESCRIPTION)
                       AND UPPER (XAD.BRANCH_CODE) = UPPER (OCB.BRANCH_CODE)
                       AND DEP.COMPANY = OCB.PARENT_ORG
                       AND UPPER (XAD.AGENCY_CODE) = UPPER (P_AGENCY_CODE)
                       AND DEP.DEPT_CODE = NVL (P_DEPT_CODE, DEP.DEPT_CODE)
                       AND NOT EXISTS
                               (SELECT 1
                                  FROM HZ_CUST_ACCT_SITES_ALL CAS
                                 WHERE     HPS.PARTY_SITE_ID = CAS.PARTY_SITE_ID
                                       AND HCA.CUST_ACCOUNT_ID = CAS.CUST_ACCOUNT_ID
                                       AND OCB.ORG_ID = CAS.ORG_ID)
                UNION ALL
                SELECT OCB.ORG_ID,
                       HZP.PARTY_ID,
                       HZP.PARTY_NAME,
                       HPS.PARTY_SITE_ID,
                       HCA.CUST_ACCOUNT_ID,
                       HCA.ACCOUNT_NAME
                  FROM XX_AGENCY_DETAILS        XAD,
                       HZ_PARTIES               HZP,
                       HZ_CUST_ACCOUNTS         HCA,
                       HZ_PARTY_SITES           HPS,
                       XX_AGENCY_DEPARTMENTS_V  DEP,
                       XX_ORG_COMPANY_BRANCH_V  OCB
                 WHERE     XAD.PARTY_ID = HZP.PARTY_ID
                       AND HZP.PARTY_ID = HCA.PARTY_ID
                       AND HCA.PARTY_ID = HPS.PARTY_ID
                       AND UPPER (HCA.ACCOUNT_NAME) = UPPER (DEP.DESCRIPTION)
                       AND UPPER (XAD.BRANCH_CODE) <> 'DHK'          -- no need if it is already DHK
                       AND UPPER (OCB.BRANCH_CODE) = 'DHK'
                       AND OCB.ORG_ID IN (86, 205)                -- additional check to include DHK
                       AND DEP.COMPANY = OCB.PARENT_ORG
                       AND UPPER (XAD.AGENCY_CODE) = UPPER (P_AGENCY_CODE)
                       AND DEP.DEPT_CODE = NVL (P_DEPT_CODE, DEP.DEPT_CODE)
                       AND NOT EXISTS
                               (SELECT 1
                                  FROM HZ_CUST_ACCT_SITES_ALL CAS
                                 WHERE     HPS.PARTY_SITE_ID = CAS.PARTY_SITE_ID
                                       AND HCA.CUST_ACCOUNT_ID = CAS.CUST_ACCOUNT_ID
                                       AND OCB.ORG_ID = CAS.ORG_ID)
                ORDER BY 1, 5;
        BEGIN
            FOR REC IN CUR
            LOOP
                P_CUST_ACCT_SITE_REC.ORG_ID := REC.ORG_ID;
                P_CUST_ACCT_SITE_REC.PARTY_SITE_ID := REC.PARTY_SITE_ID;
                P_CUST_ACCT_SITE_REC.CUST_ACCOUNT_ID := REC.CUST_ACCOUNT_ID;

                P_CUST_ACCT_SITE_REC.APPLICATION_ID := 222;
                P_CUST_ACCT_SITE_REC.STATUS := 'A';
                P_CUST_ACCT_SITE_REC.CREATED_BY_MODULE := P_CREATED_BY_MODULE;

                HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_ACCT_SITE (
                    P_INIT_MSG_LIST        => FND_API.G_TRUE,
                    P_CUST_ACCT_SITE_REC   => P_CUST_ACCT_SITE_REC,
                    X_CUST_ACCT_SITE_ID    => X_CUST_ACCT_SITE_ID,
                    X_RETURN_STATUS        => X_RETURN_STATUS,
                    X_MSG_COUNT            => X_MSG_COUNT,
                    X_MSG_DATA             => X_MSG_DATA);
            END LOOP;
        END;


        -- 6. Create an Account Site Use 'BILL_TO'
        --    HZ_CUST_SITE_USES_ALL

        DECLARE
            P_CUST_SITE_USE_REC      HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
            P_CUSTOMER_PROFILE_REC   HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
            P_CREATED_BY_MODULE      VARCHAR2 (16) := 'XX_CUSTOM_API';
            X_SITE_USE_ID            NUMBER;
            X_RETURN_STATUS          VARCHAR2 (2000);
            X_MSG_COUNT              NUMBER;
            X_MSG_DATA               VARCHAR2 (2000);

            CURSOR CUR IS
                  SELECT HOU.ORGANIZATION_ID     ORG_ID,
                         HZP.PARTY_NAME,
                         HPS.PARTY_SITE_ID,
                         CAS.CUST_ACCT_SITE_ID,
                         HCA.ACCOUNT_NAME        LOCATION
                    FROM HR_OPERATING_UNITS    HOU,
                         HZ_PARTIES            HZP,
                         HZ_PARTY_SITES        HPS,
                         HZ_CUST_ACCOUNTS      HCA,
                         HZ_CUST_ACCT_SITES_ALL CAS
                   WHERE     HZP.PARTY_ID = HPS.PARTY_ID
                         AND HZP.PARTY_ID = HCA.PARTY_ID
                         AND HOU.ORGANIZATION_ID = CAS.ORG_ID
                         AND HPS.PARTY_SITE_ID = CAS.PARTY_SITE_ID
                         AND HCA.CUST_ACCOUNT_ID = CAS.CUST_ACCOUNT_ID
                         AND HZP.PARTY_ID = (SELECT PARTY_ID
                                               FROM XX_AGENCY_DETAILS
                                              WHERE AGENCY_CODE = UPPER (P_AGENCY_CODE))
                         AND CAS.CUST_ACCT_SITE_ID NOT IN
                                 (SELECT CUST_ACCT_SITE_ID FROM HZ_CUST_SITE_USES_ALL)
                ORDER BY 1, 4;
        BEGIN
            FOR REC IN CUR
            LOOP
                MO_GLOBAL.SET_POLICY_CONTEXT ('S', REC.ORG_ID);

                P_CUST_SITE_USE_REC.CUST_ACCT_SITE_ID := REC.CUST_ACCT_SITE_ID;
                P_CUST_SITE_USE_REC.LOCATION := REC.LOCATION;
                P_CUST_SITE_USE_REC.SITE_USE_CODE := 'BILL_TO';

                P_CUST_SITE_USE_REC.CREATED_BY_MODULE := P_CREATED_BY_MODULE;

                HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE (
                    P_INIT_MSG_LIST          => FND_API.G_TRUE,
                    P_CUST_SITE_USE_REC      => P_CUST_SITE_USE_REC,
                    P_CUSTOMER_PROFILE_REC   => P_CUSTOMER_PROFILE_REC,
                    P_CREATE_PROFILE         => FND_API.G_TRUE,
                    P_CREATE_PROFILE_AMT     => FND_API.G_TRUE,
                    X_SITE_USE_ID            => X_SITE_USE_ID,
                    X_RETURN_STATUS          => X_RETURN_STATUS,
                    X_MSG_COUNT              => X_MSG_COUNT,
                    X_MSG_DATA               => X_MSG_DATA);
            END LOOP;
        END;

        UPDATE HZ_CUST_SITE_USES_ALL
           SET GL_ID_REC = XX_AR_PKG.GL_ID_REC (CUST_ACCT_SITE_ID)
         WHERE     STATUS = 'A'
               AND GL_ID_REC IS NULL
               AND ORG_ID NOT IN (SELECT ORG_ID
                                    FROM XX_ORG_COMPANY_BRANCH_V
                                   WHERE TRUNC (SYSDATE) >= TRUNC (NVL (END_DATE, SYSDATE)));

        UPDATE HZ_CUST_SITE_USES_ALL
           SET GL_ID_REV = XX_AR_PKG.GL_ID_REV (CUST_ACCT_SITE_ID)
         WHERE     STATUS = 'A'
               AND GL_ID_REV IS NULL
               AND ORG_ID NOT IN (SELECT ORG_ID
                                    FROM XX_ORG_COMPANY_BRANCH_V
                                   WHERE TRUNC (SYSDATE) >= TRUNC (NVL (END_DATE, SYSDATE)));

        COMMIT;
    END;


    PROCEDURE UPDATE_AGENCY_ASSIGNMENT (ERRBUF             OUT NOCOPY VARCHAR2,
                                        RETCODE            OUT NOCOPY VARCHAR2,
                                        P_AGENCY_CODE   IN            VARCHAR2,
                                        P_BRANCH_CODE   IN            VARCHAR2)
    IS
    BEGIN
        FND_GLOBAL.APPS_INITIALIZE (USER_ID        => FND_GLOBAL.USER_ID,
                                    RESP_ID        => FND_GLOBAL.RESP_ID,
                                    RESP_APPL_ID   => FND_GLOBAL.RESP_APPL_ID);
        MO_GLOBAL.INIT ('AR');


        -- 5. Create an Account Site
        --    HZ_CUST_ACCT_SITES_ALL

        DECLARE
            P_CUST_ACCT_SITE_REC   HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
            P_CREATED_BY_MODULE    VARCHAR2 (16) := 'XX_CUSTOM_API';
            X_RETURN_STATUS        VARCHAR2 (2000);
            X_MSG_COUNT            NUMBER;
            X_MSG_DATA             VARCHAR2 (2000);
            X_CUST_ACCT_SITE_ID    NUMBER;

            CURSOR CUR IS
                SELECT OCB.ORG_ID,
                       HZP.PARTY_ID,
                       HZP.PARTY_NAME,
                       HPS.PARTY_SITE_ID,
                       HCA.CUST_ACCOUNT_ID,
                       HCA.ACCOUNT_NAME
                  FROM XX_AGENCY_DETAILS        XAD,
                       HZ_PARTIES               HZP,
                       HZ_CUST_ACCOUNTS         HCA,
                       HZ_PARTY_SITES           HPS,
                       XX_AGENCY_DEPARTMENTS_V  DEP,
                       XX_ORG_COMPANY_BRANCH_V  OCB
                 WHERE     XAD.PARTY_ID = HZP.PARTY_ID
                       AND HZP.PARTY_ID = HCA.PARTY_ID
                       AND HCA.PARTY_ID = HPS.PARTY_ID
                       AND UPPER (HCA.ACCOUNT_NAME) = UPPER (DEP.DESCRIPTION)
                       AND UPPER (XAD.BRANCH_CODE) = UPPER (OCB.BRANCH_CODE)
                       AND DEP.COMPANY = OCB.PARENT_ORG
                       AND UPPER (XAD.AGENCY_CODE) = UPPER (P_AGENCY_CODE)
                       AND XAD.BRANCH_CODE = UPPER (P_BRANCH_CODE)
                       AND NOT EXISTS
                               (SELECT 1
                                  FROM HZ_CUST_ACCT_SITES_ALL CAS
                                 WHERE     HPS.PARTY_SITE_ID = CAS.PARTY_SITE_ID
                                       AND HCA.CUST_ACCOUNT_ID = CAS.CUST_ACCOUNT_ID
                                       AND OCB.ORG_ID = CAS.ORG_ID);
        BEGIN
            FOR REC IN CUR
            LOOP
                P_CUST_ACCT_SITE_REC.ORG_ID := REC.ORG_ID;
                P_CUST_ACCT_SITE_REC.PARTY_SITE_ID := REC.PARTY_SITE_ID;
                P_CUST_ACCT_SITE_REC.CUST_ACCOUNT_ID := REC.CUST_ACCOUNT_ID;

                P_CUST_ACCT_SITE_REC.APPLICATION_ID := 222;
                P_CUST_ACCT_SITE_REC.STATUS := 'A';
                P_CUST_ACCT_SITE_REC.CREATED_BY_MODULE := P_CREATED_BY_MODULE;

                HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_ACCT_SITE (
                    P_INIT_MSG_LIST        => FND_API.G_TRUE,
                    P_CUST_ACCT_SITE_REC   => P_CUST_ACCT_SITE_REC,
                    X_CUST_ACCT_SITE_ID    => X_CUST_ACCT_SITE_ID,
                    X_RETURN_STATUS        => X_RETURN_STATUS,
                    X_MSG_COUNT            => X_MSG_COUNT,
                    X_MSG_DATA             => X_MSG_DATA);
            END LOOP;
        END;


        -- 6. Create an Account Site Use 'BILL_TO'
        --    HZ_CUST_SITE_USES_ALL

        DECLARE
            P_CUST_SITE_USE_REC      HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
            P_CUSTOMER_PROFILE_REC   HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
            P_CREATED_BY_MODULE      VARCHAR2 (16) := 'XX_CUSTOM_API';
            X_SITE_USE_ID            NUMBER;
            X_RETURN_STATUS          VARCHAR2 (2000);
            X_MSG_COUNT              NUMBER;
            X_MSG_DATA               VARCHAR2 (2000);

            CURSOR CUR IS
                  SELECT HOU.ORGANIZATION_ID     ORG_ID,
                         HZP.PARTY_NAME,
                         HPS.PARTY_SITE_ID,
                         CAS.CUST_ACCT_SITE_ID,
                         HCA.ACCOUNT_NAME        LOCATION
                    FROM HR_OPERATING_UNITS    HOU,
                         HZ_PARTIES            HZP,
                         HZ_PARTY_SITES        HPS,
                         HZ_CUST_ACCOUNTS      HCA,
                         HZ_CUST_ACCT_SITES_ALL CAS
                   WHERE     HZP.PARTY_ID = HPS.PARTY_ID
                         AND HZP.PARTY_ID = HCA.PARTY_ID
                         AND HOU.ORGANIZATION_ID = CAS.ORG_ID
                         AND HPS.PARTY_SITE_ID = CAS.PARTY_SITE_ID
                         AND HCA.CUST_ACCOUNT_ID = CAS.CUST_ACCOUNT_ID
                         AND HZP.PARTY_ID = (SELECT PARTY_ID
                                               FROM XX_AGENCY_DETAILS
                                              WHERE AGENCY_CODE = UPPER (P_AGENCY_CODE))
                         AND CAS.CUST_ACCT_SITE_ID NOT IN
                                 (SELECT CUST_ACCT_SITE_ID FROM HZ_CUST_SITE_USES_ALL)
                ORDER BY 1, 4;
        BEGIN
            FOR REC IN CUR
            LOOP
                MO_GLOBAL.SET_POLICY_CONTEXT ('S', REC.ORG_ID);

                P_CUST_SITE_USE_REC.CUST_ACCT_SITE_ID := REC.CUST_ACCT_SITE_ID;
                P_CUST_SITE_USE_REC.LOCATION := REC.LOCATION;
                P_CUST_SITE_USE_REC.SITE_USE_CODE := 'BILL_TO';

                P_CUST_SITE_USE_REC.CREATED_BY_MODULE := P_CREATED_BY_MODULE;

                HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE (
                    P_INIT_MSG_LIST          => FND_API.G_TRUE,
                    P_CUST_SITE_USE_REC      => P_CUST_SITE_USE_REC,
                    P_CUSTOMER_PROFILE_REC   => P_CUSTOMER_PROFILE_REC,
                    P_CREATE_PROFILE         => FND_API.G_TRUE,
                    P_CREATE_PROFILE_AMT     => FND_API.G_TRUE,
                    X_SITE_USE_ID            => X_SITE_USE_ID,
                    X_RETURN_STATUS          => X_RETURN_STATUS,
                    X_MSG_COUNT              => X_MSG_COUNT,
                    X_MSG_DATA               => X_MSG_DATA);
            END LOOP;
        END;


        UPDATE HZ_CUST_SITE_USES_ALL
           SET GL_ID_REC = XX_AR_PKG.GL_ID_REC (CUST_ACCT_SITE_ID)
         WHERE     STATUS = 'A'
               AND GL_ID_REC IS NULL
               AND ORG_ID NOT IN (SELECT ORG_ID
                                    FROM XX_ORG_COMPANY_BRANCH_V
                                   WHERE TRUNC (SYSDATE) >= TRUNC (NVL (END_DATE, SYSDATE)));

        UPDATE HZ_CUST_SITE_USES_ALL
           SET GL_ID_REV = XX_AR_PKG.GL_ID_REV (CUST_ACCT_SITE_ID)
         WHERE     STATUS = 'A'
               AND GL_ID_REV IS NULL
               AND ORG_ID NOT IN (SELECT ORG_ID
                                    FROM XX_ORG_COMPANY_BRANCH_V
                                   WHERE TRUNC (SYSDATE) >= TRUNC (NVL (END_DATE, SYSDATE)));

        COMMIT;
    END;


    PROCEDURE CREATE_CUSTOMER_ACCOUNT_SITE (ERRBUF             OUT NOCOPY VARCHAR2,
                                            RETCODE            OUT NOCOPY VARCHAR2,
                                            P_CUSTOMER_ID   IN            VARCHAR2,
                                            P_ORG_ID        IN            NUMBER)
    IS
    BEGIN
        FND_GLOBAL.APPS_INITIALIZE (USER_ID        => FND_GLOBAL.USER_ID,
                                    RESP_ID        => FND_GLOBAL.RESP_ID,
                                    RESP_APPL_ID   => FND_GLOBAL.RESP_APPL_ID);
        MO_GLOBAL.INIT ('AR');

        -- 5. Create an Account Site
        --    HZ_CUST_ACCT_SITES_ALL

        DECLARE
            P_CUST_ACCT_SITE_REC   HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
            P_CREATED_BY_MODULE    VARCHAR2 (16) := 'XX_CUSTOM_API';
            X_RETURN_STATUS        VARCHAR2 (2000);
            X_MSG_COUNT            NUMBER;
            X_MSG_DATA             VARCHAR2 (2000);
            X_CUST_ACCT_SITE_ID    NUMBER;

            CURSOR CUR IS
                  SELECT P_ORG_ID     ORG_ID,
                         HZP.PARTY_ID,
                         HZP.PARTY_NAME,
                         HPS.PARTY_SITE_ID,
                         HCA.CUST_ACCOUNT_ID,
                         HCA.ACCOUNT_NAME
                    FROM HZ_PARTIES HZP, HZ_CUST_ACCOUNTS HCA, HZ_PARTY_SITES HPS
                   WHERE     HZP.PARTY_ID = HCA.PARTY_ID
                         AND HCA.PARTY_ID = HPS.PARTY_ID
                         AND NOT EXISTS
                                 (SELECT 1
                                    FROM HZ_CUST_ACCT_SITES_ALL CAS
                                   WHERE     HPS.PARTY_SITE_ID = CAS.PARTY_SITE_ID
                                         AND HCA.CUST_ACCOUNT_ID = CAS.CUST_ACCOUNT_ID
                                         AND CAS.ORG_ID = P_ORG_ID)
                         AND HCA.ACCOUNT_NUMBER = UPPER (P_CUSTOMER_ID)
                ORDER BY 1, 5;
        BEGIN
            FOR REC IN CUR
            LOOP
                P_CUST_ACCT_SITE_REC.ORG_ID := REC.ORG_ID;
                P_CUST_ACCT_SITE_REC.PARTY_SITE_ID := REC.PARTY_SITE_ID;
                P_CUST_ACCT_SITE_REC.CUST_ACCOUNT_ID := REC.CUST_ACCOUNT_ID;

                P_CUST_ACCT_SITE_REC.APPLICATION_ID := 222;
                P_CUST_ACCT_SITE_REC.STATUS := 'A';
                P_CUST_ACCT_SITE_REC.CREATED_BY_MODULE := P_CREATED_BY_MODULE;

                HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_ACCT_SITE (
                    P_INIT_MSG_LIST        => FND_API.G_TRUE,
                    P_CUST_ACCT_SITE_REC   => P_CUST_ACCT_SITE_REC,
                    X_CUST_ACCT_SITE_ID    => X_CUST_ACCT_SITE_ID,
                    X_RETURN_STATUS        => X_RETURN_STATUS,
                    X_MSG_COUNT            => X_MSG_COUNT,
                    X_MSG_DATA             => X_MSG_DATA);
            END LOOP;
        END;


        -- 6. Create an Account Site Use 'BILL_TO'
        --    HZ_CUST_SITE_USES_ALL

        DECLARE
            P_CUST_SITE_USE_REC      HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
            P_CUSTOMER_PROFILE_REC   HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
            P_CREATED_BY_MODULE      VARCHAR2 (16) := 'XX_CUSTOM_API';
            X_SITE_USE_ID            NUMBER;
            X_RETURN_STATUS          VARCHAR2 (2000);
            X_MSG_COUNT              NUMBER;
            X_MSG_DATA               VARCHAR2 (2000);

            CURSOR CUR IS
                  SELECT HOU.ORGANIZATION_ID     ORG_ID,
                         HZP.PARTY_NAME,
                         HPS.PARTY_SITE_ID,
                         CAS.CUST_ACCT_SITE_ID,
                         HCA.ACCOUNT_NAME        LOCATION
                    FROM HR_OPERATING_UNITS    HOU,
                         HZ_PARTIES            HZP,
                         HZ_PARTY_SITES        HPS,
                         HZ_CUST_ACCOUNTS      HCA,
                         HZ_CUST_ACCT_SITES_ALL CAS
                   WHERE     HZP.PARTY_ID = HPS.PARTY_ID
                         AND HZP.PARTY_ID = HCA.PARTY_ID
                         AND HOU.ORGANIZATION_ID = CAS.ORG_ID
                         AND HPS.PARTY_SITE_ID = CAS.PARTY_SITE_ID
                         AND HCA.CUST_ACCOUNT_ID = CAS.CUST_ACCOUNT_ID
                         AND CAS.CUST_ACCT_SITE_ID NOT IN
                                 (SELECT CUST_ACCT_SITE_ID FROM HZ_CUST_SITE_USES_ALL)
                         AND HCA.ACCOUNT_NUMBER = UPPER (P_CUSTOMER_ID)
                ORDER BY 1, 4;
        BEGIN
            FOR REC IN CUR
            LOOP
                MO_GLOBAL.SET_POLICY_CONTEXT ('S', REC.ORG_ID);

                P_CUST_SITE_USE_REC.CUST_ACCT_SITE_ID := REC.CUST_ACCT_SITE_ID;
                P_CUST_SITE_USE_REC.LOCATION := REC.LOCATION;
                P_CUST_SITE_USE_REC.SITE_USE_CODE := 'BILL_TO';

                P_CUST_SITE_USE_REC.CREATED_BY_MODULE := P_CREATED_BY_MODULE;

                HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE (
                    P_INIT_MSG_LIST          => FND_API.G_TRUE,
                    P_CUST_SITE_USE_REC      => P_CUST_SITE_USE_REC,
                    P_CUSTOMER_PROFILE_REC   => P_CUSTOMER_PROFILE_REC,
                    P_CREATE_PROFILE         => FND_API.G_TRUE,
                    P_CREATE_PROFILE_AMT     => FND_API.G_TRUE,
                    X_SITE_USE_ID            => X_SITE_USE_ID,
                    X_RETURN_STATUS          => X_RETURN_STATUS,
                    X_MSG_COUNT              => X_MSG_COUNT,
                    X_MSG_DATA               => X_MSG_DATA);
            END LOOP;
        END;

        UPDATE HZ_CUST_SITE_USES_ALL
           SET GL_ID_REC = XX_AR_PKG.GL_ID_REC (CUST_ACCT_SITE_ID)
         WHERE     STATUS = 'A'
               AND GL_ID_REC IS NULL
               AND ORG_ID NOT IN (SELECT ORG_ID
                                    FROM XX_ORG_COMPANY_BRANCH_V
                                   WHERE TRUNC (SYSDATE) >= TRUNC (NVL (END_DATE, SYSDATE)));

        UPDATE HZ_CUST_SITE_USES_ALL
           SET GL_ID_REV = XX_AR_PKG.GL_ID_REV (CUST_ACCT_SITE_ID)
         WHERE     STATUS = 'A'
               AND GL_ID_REV IS NULL
               AND ORG_ID NOT IN (SELECT ORG_ID
                                    FROM XX_ORG_COMPANY_BRANCH_V
                                   WHERE TRUNC (SYSDATE) >= TRUNC (NVL (END_DATE, SYSDATE)));

        COMMIT;
    END;

    PROCEDURE INSERT_INFO_AR_DB (P_DATE_FROM IN DATE, P_DATE_TO IN DATE, P_TYPE IN VARCHAR2)
    AS
    BEGIN
        DELETE FROM XX_AR_REVENUE_DASHBOARD_GT
              WHERE 1 = 1;

        -- Details
        IF P_TYPE = 'DTLS'
        THEN
            INSERT INTO XX_AR_REVENUE_DASHBOARD_GT (COMPANY,
                                                    BRANCH,
                                                    DEPARTMENT,
                                                    OPENING,
                                                    REVENUE,
                                                    COLLECTION,
                                                    CLOSING)
                WITH
                    WITH_CLAUSE_TAB
                    AS
                        (  SELECT COMPANY,
                                  BRANCH_CODE,
                                  DEPARTMENT,
                                  (NVL (SUM (DR_AMOUNT), 0) - NVL (SUM (CR_AMOUNT), 0))    OPENING,
                                  0                                                        DR_AMOUNT,
                                  0                                                        CR_AMOUNT
                             FROM XX_AR_REVENUE_DASHBOARD_V
                            WHERE GL_DATE < P_DATE_FROM
                         GROUP BY COMPANY, BRANCH_CODE, DEPARTMENT
                         UNION ALL
                           SELECT COMPANY,
                                  BRANCH_CODE,
                                  DEPARTMENT,
                                  0                            OPENING,
                                  SUM (NVL (DR_AMOUNT, 0))     DR_AMOUNT,
                                  SUM (NVL (CR_AMOUNT, 0))     CR_AMOUNT
                             FROM XX_AR_REVENUE_DASHBOARD_V
                            WHERE GL_DATE BETWEEN P_DATE_FROM AND P_DATE_TO
                         GROUP BY COMPANY, BRANCH_CODE, DEPARTMENT)
                  SELECT COMPANY,
                         BRANCH_CODE,
                         DEPARTMENT,
                         SUM (OPENING)                                           OPENING,
                         SUM (DR_AMOUNT)                                         DR_AMOUNT,
                         SUM (CR_AMOUNT)                                         CR_AMOUNT,
                         (SUM (OPENING) + SUM (DR_AMOUNT) - SUM (CR_AMOUNT))     CLOSING
                    FROM WITH_CLAUSE_TAB
                GROUP BY COMPANY, BRANCH_CODE, DEPARTMENT;
        -- Summary
        ELSIF P_TYPE = 'SUMM'
        THEN
            INSERT INTO XX_AR_REVENUE_DASHBOARD_GT (COMPANY,
                                                    BRANCH,
                                                    OPENING,
                                                    REVENUE,
                                                    COLLECTION,
                                                    CLOSING)
                WITH
                    WITH_CLAUSE_TAB
                    AS
                        (  SELECT COMPANY,
                                  BRANCH_CODE,
                                  (NVL (SUM (DR_AMOUNT), 0) - NVL (SUM (CR_AMOUNT), 0))    OPENING,
                                  0                                                        DR_AMOUNT,
                                  0                                                        CR_AMOUNT
                             FROM XX_AR_REVENUE_DASHBOARD_V
                            WHERE GL_DATE < P_DATE_FROM
                         GROUP BY COMPANY, BRANCH_CODE
                         UNION ALL
                           SELECT COMPANY,
                                  BRANCH_CODE,
                                  0                            OPENING,
                                  SUM (NVL (DR_AMOUNT, 0))     DR_AMOUNT,
                                  SUM (NVL (CR_AMOUNT, 0))     CR_AMOUNT
                             FROM XX_AR_REVENUE_DASHBOARD_V
                            WHERE GL_DATE BETWEEN P_DATE_FROM AND P_DATE_TO
                         GROUP BY COMPANY, BRANCH_CODE)
                  SELECT COMPANY,
                         BRANCH_CODE,
                         SUM (OPENING)                                           OPENING,
                         SUM (DR_AMOUNT)                                         DR_AMOUNT,
                         SUM (CR_AMOUNT)                                         CR_AMOUNT,
                         (SUM (OPENING) + SUM (DR_AMOUNT) - SUM (CR_AMOUNT))     CLOSING
                    FROM WITH_CLAUSE_TAB
                GROUP BY COMPANY, BRANCH_CODE;
        -- Top 20
        ELSIF P_TYPE = 'TP20'
        THEN
            INSERT INTO XX_AR_REVENUE_DASHBOARD_GT (ROW_NUM,
                                                    COMPANY,
                                                    BRANCH,
                                                    OPENING,
                                                    REVENUE,
                                                    COLLECTION,
                                                    CLOSING)
                SELECT ROWNUM,
                       COMPANY,
                       BRANCH_CODE,
                       OPENING,
                       DR_AMOUNT,
                       CR_AMOUNT,
                       CLOSING
                  FROM (WITH
                            WITH_CLAUSE_TAB
                            AS
                                (  SELECT COMPANY,
                                          BRANCH_CODE,
                                          (NVL (SUM (DR_AMOUNT), 0) - NVL (SUM (CR_AMOUNT), 0))
                                              OPENING,
                                          0
                                              DR_AMOUNT,
                                          0
                                              CR_AMOUNT
                                     FROM XX_AR_REVENUE_DASHBOARD_V
                                    WHERE GL_DATE < P_DATE_FROM
                                 GROUP BY COMPANY, BRANCH_CODE
                                 UNION ALL
                                   SELECT COMPANY,
                                          BRANCH_CODE,
                                          0                            OPENING,
                                          SUM (NVL (DR_AMOUNT, 0))     DR_AMOUNT,
                                          SUM (NVL (CR_AMOUNT, 0))     CR_AMOUNT
                                     FROM XX_AR_REVENUE_DASHBOARD_V
                                    WHERE GL_DATE BETWEEN P_DATE_FROM AND P_DATE_TO
                                 GROUP BY COMPANY, BRANCH_CODE)
                          SELECT COMPANY,
                                 BRANCH_CODE,
                                 SUM (OPENING)                                           OPENING,
                                 SUM (DR_AMOUNT)                                         DR_AMOUNT,
                                 SUM (CR_AMOUNT)                                         CR_AMOUNT,
                                 (SUM (OPENING) + SUM (DR_AMOUNT) - SUM (CR_AMOUNT))     CLOSING
                            FROM WITH_CLAUSE_TAB
                        GROUP BY COMPANY, BRANCH_CODE
                        ORDER BY CLOSING DESC)
                 WHERE ROWNUM <= 20;
        -- Bottom 20
        ELSIF P_TYPE = 'BT20'
        THEN
            INSERT INTO XX_AR_REVENUE_DASHBOARD_GT (ROW_NUM,
                                                    COMPANY,
                                                    BRANCH,
                                                    OPENING,
                                                    REVENUE,
                                                    COLLECTION,
                                                    CLOSING)
                SELECT ROWNUM,
                       COMPANY,
                       BRANCH_CODE,
                       OPENING,
                       DR_AMOUNT,
                       CR_AMOUNT,
                       CLOSING
                  FROM (WITH
                            WITH_CLAUSE_TAB
                            AS
                                (  SELECT COMPANY,
                                          BRANCH_CODE,
                                          (NVL (SUM (DR_AMOUNT), 0) - NVL (SUM (CR_AMOUNT), 0))
                                              OPENING,
                                          0
                                              DR_AMOUNT,
                                          0
                                              CR_AMOUNT
                                     FROM XX_AR_REVENUE_DASHBOARD_V
                                    WHERE GL_DATE < P_DATE_FROM
                                 GROUP BY COMPANY, BRANCH_CODE
                                 UNION ALL
                                   SELECT COMPANY,
                                          BRANCH_CODE,
                                          0                            OPENING,
                                          SUM (NVL (DR_AMOUNT, 0))     DR_AMOUNT,
                                          SUM (NVL (CR_AMOUNT, 0))     CR_AMOUNT
                                     FROM XX_AR_REVENUE_DASHBOARD_V
                                    WHERE GL_DATE BETWEEN P_DATE_FROM AND P_DATE_TO
                                 GROUP BY COMPANY, BRANCH_CODE)
                          SELECT COMPANY,
                                 BRANCH_CODE,
                                 SUM (OPENING)                                           OPENING,
                                 SUM (DR_AMOUNT)                                         DR_AMOUNT,
                                 SUM (CR_AMOUNT)                                         CR_AMOUNT,
                                 (SUM (OPENING) + SUM (DR_AMOUNT) - SUM (CR_AMOUNT))     CLOSING
                            FROM WITH_CLAUSE_TAB
                        GROUP BY COMPANY, BRANCH_CODE
                        ORDER BY CLOSING)
                 WHERE ROWNUM <= 20;
        ELSE
            NULL;
        END IF;
    END;

    PROCEDURE CUSTOMER_LEDGER_DETAILS (P_ORG_ID        IN NUMBER,
                                       P_CUSTOMER_ID   IN NUMBER,
                                       P_DATE_FROM     IN DATE,
                                       P_DATE_TO       IN DATE)
    AS
    BEGIN
        INSERT INTO XX_AR_CUSTOMER_LEDGER_GT (SL,
                                              ORD,
                                              ORG_ID,
                                              VOUCHER,
                                              TRX_NUMBER,
                                              TRANSACTION_ID,
                                              GL_DATE,
                                              CUSTOMER_ID,
                                              CUSTOMER_NUMBER,
                                              CUSTOMER_NAME,
                                              CURRENCY,
                                              QUANTITY,
                                              DESCRIPTION,
                                              DR_AMOUNT,
                                              CR_AMOUNT)
            SELECT SL,
                   ORD,
                   ORG_ID,
                   VOUCHER,
                   TRX_NUMBER,
                   TRANSACTION_ID,
                   GL_DATE,
                   CUSTOMER_ID,
                   CUSTOMER_NUMBER,
                   CUSTOMER_NAME,
                   CURRENCY,
                   QUANTITY,
                   DESCRIPTION,
                   DR_AMOUNT,
                   CR_AMOUNT
              FROM XX_AR_CUSTOMER_LEDGER_V
             WHERE ORG_ID = P_ORG_ID               --  AND GL_DATE BETWEEN P_DATE_FROM AND P_DATE_TO
                                     AND CUSTOMER_ID = P_CUSTOMER_ID;
    END;
END XX_AR_PKG;
/
