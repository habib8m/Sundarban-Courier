
CREATE OR REPLACE PACKAGE BODY APPS.XX_CE_PKG AS
    FUNCTION GET_BANK_NAME_FROM_ID (P_BANK_ID NUMBER)
        RETURN VARCHAR2 AS
        V_RESULT   VARCHAR2 (100);

        CURSOR P_CURSOR IS
            SELECT BANK_NAME
              FROM XX_BANKS_V
             WHERE BANK_PARTY_ID = P_BANK_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN V_RESULT;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION GET_BRANCH_NAME_FROM_ID (P_BRANCH_ID NUMBER)
        RETURN VARCHAR2 AS
        V_RESULT   VARCHAR2 (100);

        CURSOR P_CURSOR IS
            SELECT BANK_BRANCH_NAME
              FROM XX_BANK_BRANCHES_V
             WHERE BRANCH_PARTY_ID = P_BRANCH_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN V_RESULT;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION GET_GL_DATE_FROM_CHECK_ID (P_CHECK_ID NUMBER)
        RETURN DATE AS
        V_RESULT   DATE;

        CURSOR P_CURSOR IS
            SELECT TRUNC (ACCOUNTING_DATE)
              FROM AP_PAYMENT_HISTORY_ALL PH
             WHERE     PH.PAYMENT_HISTORY_ID IN
                           (  SELECT MAX (RV.PAYMENT_HISTORY_ID)
                               FROM AP_PAYMENT_HISTORY_ALL RV
                              WHERE RV.TRANSACTION_TYPE NOT IN
                                        ('PAYMENT ADJUSTED', 'PAYMENT CLEARING ADJUSTED')
                           GROUP BY RV.CHECK_ID)
                   AND PH.CHECK_ID = P_CHECK_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN V_RESULT;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION GET_CLEARED_AMT_FROM_CHECK_ID (P_CHECK_ID NUMBER)
        RETURN NUMBER AS
        V_RESULT   NUMBER;

        CURSOR P_CURSOR IS
            SELECT NVL (PH.TRX_BASE_AMOUNT, PH.TRX_PMT_AMOUNT)
              FROM AP_PAYMENT_HISTORY_ALL PH
             WHERE     PH.PAYMENT_HISTORY_ID IN
                           (  SELECT MAX (RV.PAYMENT_HISTORY_ID)
                               FROM AP_PAYMENT_HISTORY_ALL RV
                              WHERE RV.TRANSACTION_TYPE NOT IN
                                        ('PAYMENT ADJUSTED', 'PAYMENT CLEARING ADJUSTED')
                           GROUP BY RV.CHECK_ID)
                   AND PH.CHECK_ID = P_CHECK_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN V_RESULT;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION GET_ACCOUNT_NAME_FROM_ACC_ID (P_ACCOUNT_ID NUMBER)
        RETURN VARCHAR2 AS
        V_RESULT   VARCHAR2 (100);

        CURSOR P_CURSOR IS
            SELECT BANK_ACCOUNT_NAME
              FROM CE_BANK_ACCOUNTS
             WHERE BANK_ACCOUNT_ID = P_ACCOUNT_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN V_RESULT;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION GET_ACCOUNT_NUM_FROM_ACC_ID (P_ACCOUNT_ID NUMBER)
        RETURN VARCHAR2 AS
        V_RESULT   VARCHAR2 (100);

        CURSOR P_CURSOR IS
            SELECT BANK_ACCOUNT_NUM
              FROM CE_BANK_ACCOUNTS
             WHERE BANK_ACCOUNT_ID = P_ACCOUNT_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN V_RESULT;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION GET_BAL_SEG_FROM_ACCOUNT_ID (P_ACCOUNT_ID NUMBER)
        RETURN VARCHAR2 AS
        V_RESULT   VARCHAR2 (25);

        CURSOR P_CURSOR IS
            SELECT GC.SEGMENT1
              INTO V_RESULT
              FROM CE_BANK_ACCOUNTS BA, GL_CODE_COMBINATIONS GC
             WHERE     BA.ASSET_CODE_COMBINATION_ID = GC.CODE_COMBINATION_ID
                   AND BA.BANK_ACCOUNT_ID = P_ACCOUNT_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN V_RESULT;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION GET_ACCOUNT_FROM_ACCOUNT_ID (P_ACCOUNT_ID NUMBER)
        RETURN VARCHAR2 AS
        V_RESULT   VARCHAR2 (25);

        CURSOR P_CURSOR IS
            SELECT GC.SEGMENT4
              INTO V_RESULT
              FROM CE_BANK_ACCOUNTS BA, GL_CODE_COMBINATIONS GC
             WHERE     BA.ASSET_CODE_COMBINATION_ID = GC.CODE_COMBINATION_ID
                   AND BA.BANK_ACCOUNT_ID = P_ACCOUNT_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN V_RESULT;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION GET_ORG_ID_FROM_ACCOUNT_ID (P_ACCOUNT_ID NUMBER)
        RETURN NUMBER AS
        V_RESULT   NUMBER;

        CURSOR P_CURSOR IS
            SELECT OCB.ORG_ID
              INTO V_RESULT
              FROM CE_BANK_ACCOUNTS CBA, GL_CODE_COMBINATIONS GCC, XX_ORG_COMPANY_BRANCH_V OCB
             WHERE     CBA.ASSET_CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                   AND GCC.SEGMENT1 = OCB.COMPANY_CODE
                   AND GCC.SEGMENT2 = OCB.BRANCH_CODE
                   AND CBA.BANK_ACCOUNT_ID = P_ACCOUNT_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN V_RESULT;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION GET_UNIT_FROM_ACCOUNT_ID (P_ACCOUNT_ID NUMBER)
        RETURN VARCHAR2 AS
        V_RESULT   VARCHAR2 (240);

        CURSOR P_CURSOR IS
            SELECT OCB.ORG_NAME
              INTO V_RESULT
              FROM CE_BANK_ACCOUNTS CBA, GL_CODE_COMBINATIONS GCC, XX_ORG_COMPANY_BRANCH_V OCB
             WHERE     CBA.ASSET_CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                   AND GCC.SEGMENT1 = OCB.COMPANY_CODE
                   AND GCC.SEGMENT2 = OCB.BRANCH_CODE
                   AND CBA.BANK_ACCOUNT_ID = P_ACCOUNT_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN V_RESULT;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION GET_ORG_CODE_FROM_ACCOUNT_ID (P_ACCOUNT_ID NUMBER)
        RETURN VARCHAR2 AS
        V_RESULT   VARCHAR2 (240);

        CURSOR P_CURSOR IS
            SELECT OCB.ORG_CODE
              INTO V_RESULT
              FROM CE_BANK_ACCOUNTS CBA, GL_CODE_COMBINATIONS GCC, XX_ORG_COMPANY_BRANCH_V OCB
             WHERE     CBA.ASSET_CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                   AND GCC.SEGMENT1 = OCB.COMPANY_CODE
                   AND GCC.SEGMENT2 = OCB.BRANCH_CODE
                   AND CBA.BANK_ACCOUNT_ID = P_ACCOUNT_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN V_RESULT;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION GET_CLEARED_AMT_AFTER_DATE (P_CHECK_ID NUMBER, P_DATE DATE)
        RETURN NUMBER AS
        V_RESULT   NUMBER;

        CURSOR P_CURSOR IS
            SELECT NVL (PH.TRX_BASE_AMOUNT, PH.TRX_PMT_AMOUNT)
              FROM AP_CHECKS_ALL AC, AP_PAYMENT_HISTORY_ALL PH
             WHERE     AC.CHECK_ID = PH.CHECK_ID
                   AND PH.REV_PMT_HIST_ID IS NULL
                   AND PH.PAYMENT_HISTORY_ID NOT IN
                           (SELECT NVL (REV_PMT_HIST_ID, '-1') FROM AP_PAYMENT_HISTORY_ALL)
                   AND PH.TRANSACTION_TYPE IN ('PAYMENT CLEARING', 'REFUND RECORDED')
                   AND AC.CHECK_ID = P_CHECK_ID
                   AND PH.ACCOUNTING_DATE > P_DATE;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN V_RESULT;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION GET_CLEARED_AMT_AFTER_DATE_FC (P_CHECK_ID NUMBER, P_DATE DATE)
        RETURN NUMBER AS
        V_RESULT   NUMBER;

        CURSOR P_CURSOR IS
            SELECT NVL (PH.TRX_PMT_AMOUNT, 0)
              FROM AP_CHECKS_ALL AC, AP_PAYMENT_HISTORY_ALL PH
             WHERE     AC.CHECK_ID = PH.CHECK_ID
                   AND PH.REV_PMT_HIST_ID IS NULL
                   AND PH.PAYMENT_HISTORY_ID NOT IN
                           (SELECT NVL (REV_PMT_HIST_ID, '-1') FROM AP_PAYMENT_HISTORY_ALL)
                   AND PH.TRANSACTION_TYPE IN ('PAYMENT CLEARING', 'REFUND RECORDED')
                   AND AC.CHECK_ID = P_CHECK_ID
                   AND PH.ACCOUNTING_DATE > P_DATE;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN V_RESULT;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION GET_BANK_BALANCE (P_ACCOUNT_ID NUMBER, P_DATE DATE)
        RETURN NUMBER IS
        V_RESULT   NUMBER;

        CURSOR P_CURSOR IS
            SELECT SUM (NVL (DR_AMOUNT, 0)) - SUM (NVL (CR_AMOUNT, 0))
              INTO V_RESULT
              FROM XX_BANK_LEDGER_V
             WHERE ACCOUNT_ID = P_ACCOUNT_ID AND CHECK_DATE <= P_DATE;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN V_RESULT;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION GET_ACC_FROM_BANK_ACCT_USE_ID (P_BANK_ACCT_USE_ID NUMBER)
        RETURN VARCHAR2 IS
        V_RESULT   VARCHAR2 (240);
    BEGIN
        SELECT CBA.BANK_ACCOUNT_NUM
          INTO V_RESULT
          FROM CE_BANK_ACCT_USES_ALL BAU, CE_BANK_ACCOUNTS CBA
         WHERE     BAU.BANK_ACCOUNT_ID = CBA.BANK_ACCOUNT_ID
               AND BAU.BANK_ACCT_USE_ID = P_BANK_ACCT_USE_ID;

        RETURN V_RESULT;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    PROCEDURE CREATE_BANK_ACCOUNT (ERRBUF                  OUT NOCOPY VARCHAR2,
                                   RETCODE                 OUT NOCOPY VARCHAR2,
                                   P_BANK_ACC_UPLOAD_ID IN            NUMBER) IS
        V_ACCT_ID         NUMBER;
        V_RETURN_STATUS   VARCHAR2 (1);
        V_MSG_COUNT       NUMBER;
        V_MSG_DATA        VARCHAR2 (2000);
        V_COUNT           NUMBER;
        P_REQUEST_ID      NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
        P_ACCT_REC        CE_BANK_PUB.BANKACCT_REC_TYPE;

        CURSOR CUR IS
              SELECT BANK_ACC_UPLOAD_ID,
                     CBB.BANK_PARTY_ID
                         BANK_ID,
                     CBB.BRANCH_PARTY_ID
                         BANK_BRANCH_ID,
                     XEP.PARTY_ID
                         ACCOUNT_OWNER_PARTY_ID,
                     XEP.LEGAL_ENTITY_ID
                         ACCOUNT_OWNER_ORG_ID,
                     'INTERNAL'
                         ACCOUNT_CLASSIFICATION,
                     BAU.BANK_ACCOUNT_NAME,
                     BAU.BANK_ACCOUNT_NUM,
                     BAU.CURRENCY_CODE
                         CURRENCY,
                     CASE WHEN BAU.CURRENCY_CODE = 'BDT' THEN 'Y' ELSE 'N' END
                         MULTI_CURRENCY_ALLOWED_FLAG,
                     BAU.BANK_ACCOUNT_TYPE,
                     BAU.START_DATE,
                     XX_GL_PKG.CREATE_GET_GL_CCID (
                         (UCM.BAL_SEG || '.999.999.' || BAU.CASH_ACCOUNT || '.99.999.999'))
                         ASSET_CODE,
                     XX_GL_PKG.CREATE_GET_GL_CCID (
                         (UCM.BAL_SEG || '.999.999.' || BAU.CLEARING_ACCOUNT || '.99.999.999'))
                         CASH_CLEARING_CODE,
                     XX_GL_PKG.CREATE_GET_GL_CCID ((UCM.BAL_SEG || '.999.999.52050101.60.999.999'))
                         BANK_CHARGES_CODE
                FROM CE_BANK_BRANCHES_V       CBB,
                     XX_CE_BANK_ACCOUNT_UPLOAD BAU,
                     HR_OPERATING_UNITS       HOU,
                     XLE_ENTITY_PROFILES      XEP,
                     XX_UNIT_COMPANY_MAPPING  UCM
               WHERE     CBB.BANK_PARTY_ID = BAU.BANK_ID
                     AND CBB.BRANCH_PARTY_ID = BAU.BANK_BRANCH_ID
                     AND BAU.ORG_ID = HOU.ORGANIZATION_ID
                     AND HOU.DEFAULT_LEGAL_CONTEXT_ID = XEP.LEGAL_ENTITY_ID
                     AND HOU.ORGANIZATION_ID = UCM.ORG_ID
                     AND BAU.PROCESS_FLAG = 'NEW'
                     AND NOT EXISTS
                             (SELECT 1
                                FROM CE_BANK_ACCOUNTS CBA
                               WHERE BAU.BANK_ACCOUNT_NUM = CBA.BANK_ACCOUNT_NUM)
                     AND (   P_BANK_ACC_UPLOAD_ID IS NULL
                          OR BAU.BANK_ACC_UPLOAD_ID = P_BANK_ACC_UPLOAD_ID)
            ORDER BY 1;
    BEGIN
        FND_FILE.PUT_LINE (
            FND_FILE.LOG,
            '=============================================================================');
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Bank Account Creation Process Started...');
        FND_FILE.PUT_LINE (
            FND_FILE.LOG,
            '=============================================================================');

        FOR REC IN CUR LOOP
            --Bank Branch
            P_ACCT_REC.BANK_ID := REC.BANK_ID;
            P_ACCT_REC.BRANCH_ID := REC.BANK_BRANCH_ID;

            -- Legal Entity
            P_ACCT_REC.ACCOUNT_OWNER_PARTY_ID := REC.ACCOUNT_OWNER_PARTY_ID;
            P_ACCT_REC.ACCOUNT_OWNER_ORG_ID := REC.ACCOUNT_OWNER_ORG_ID;

            --Account Information
            P_ACCT_REC.ACCOUNT_CLASSIFICATION := REC.ACCOUNT_CLASSIFICATION;
            P_ACCT_REC.BANK_ACCOUNT_NAME := REC.BANK_ACCOUNT_NAME;
            P_ACCT_REC.BANK_ACCOUNT_NUM := REC.BANK_ACCOUNT_NUM;
            P_ACCT_REC.CURRENCY := REC.CURRENCY;
            P_ACCT_REC.MULTI_CURRENCY_ALLOWED_FLAG := REC.MULTI_CURRENCY_ALLOWED_FLAG;
            P_ACCT_REC.ACCT_TYPE := REC.BANK_ACCOUNT_TYPE;
            P_ACCT_REC.START_DATE := REC.START_DATE;

            --Account Controls
            P_ACCT_REC.ASSET_CODE_COMBINATION_ID := REC.ASSET_CODE;
            P_ACCT_REC.CASH_CLEARING_CCID := REC.CASH_CLEARING_CODE;
            P_ACCT_REC.BANK_CHARGES_CCID := REC.BANK_CHARGES_CODE;
            P_ACCT_REC.PAYMENT_MULTI_CURRENCY_FLAG := REC.MULTI_CURRENCY_ALLOWED_FLAG;
            P_ACCT_REC.RECEIPT_MULTI_CURRENCY_FLAG := REC.MULTI_CURRENCY_ALLOWED_FLAG;

            --Account Access
            P_ACCT_REC.AP_USE_ALLOWED_FLAG := 'Y';
            P_ACCT_REC.AR_USE_ALLOWED_FLAG := 'Y';

            --Calling API
            CE_BANK_PUB.CREATE_BANK_ACCT (P_ACCT_REC        => P_ACCT_REC,
                                          X_ACCT_ID         => V_ACCT_ID,
                                          X_RETURN_STATUS   => V_RETURN_STATUS,
                                          X_MSG_COUNT       => V_MSG_COUNT,
                                          X_MSG_DATA        => V_MSG_DATA);

            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Bank Acc Num  : ' || REC.BANK_ACCOUNT_NUM);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Currency Code : ' || REC.CURRENCY);
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                   'Return Status : '
                || (CASE WHEN V_RETURN_STATUS = 'S' THEN 'Success' ELSE 'Error' END));
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Massage Count : ' || V_MSG_COUNT);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Massage Data  : ' || V_MSG_DATA);

            UPDATE XX_CE_BANK_ACCOUNT_UPLOAD
               SET PROCESS_FLAG = CASE WHEN V_RETURN_STATUS = 'S' THEN 'Processed' ELSE 'Error' END,
                   REQUEST_ID = P_REQUEST_ID
             WHERE BANK_ACC_UPLOAD_ID = REC.BANK_ACC_UPLOAD_ID;

            UPDATE CE_BANK_ACCOUNTS
               SET MANUAL_RECON_AMOUNT_TOLERANCE = 0
             WHERE BANK_ACCOUNT_ID = V_ACCT_ID;

            UPDATE CE_BANK_ACCOUNTS
               SET MANUAL_RECON_PERCENT_TOLERANCE = 0
             WHERE BANK_ACCOUNT_ID = V_ACCT_ID;

            UPDATE CE_BANK_ACCOUNTS
               SET AP_AMOUNT_TOLERANCE = 0
             WHERE BANK_ACCOUNT_ID = V_ACCT_ID;

            UPDATE CE_BANK_ACCOUNTS
               SET AP_PERCENT_TOLERANCE = 0
             WHERE BANK_ACCOUNT_ID = V_ACCT_ID;

            UPDATE CE_BANK_ACCOUNTS
               SET AR_AMOUNT_TOLERANCE = 0
             WHERE BANK_ACCOUNT_ID = V_ACCT_ID;

            UPDATE CE_BANK_ACCOUNTS
               SET AR_PERCENT_TOLERANCE = 0
             WHERE BANK_ACCOUNT_ID = V_ACCT_ID;

            UPDATE CE_BANK_ACCOUNTS
               SET CE_AMOUNT_TOLERANCE = 0
             WHERE BANK_ACCOUNT_ID = V_ACCT_ID;

            UPDATE CE_BANK_ACCOUNTS
               SET CE_PERCENT_TOLERANCE = 0
             WHERE BANK_ACCOUNT_ID = V_ACCT_ID;

            UPDATE CE_BANK_ACCOUNTS
               SET RECON_OI_AMOUNT_TOLERANCE = 0
             WHERE BANK_ACCOUNT_ID = V_ACCT_ID;

            UPDATE CE_BANK_ACCOUNTS
               SET RECON_OI_PERCENT_TOLERANCE = 0
             WHERE BANK_ACCOUNT_ID = V_ACCT_ID;

            COMMIT;
        END LOOP;

        SELECT COUNT (*)
          INTO V_COUNT
          FROM XX_CE_BANK_ACCOUNT_UPLOAD
         WHERE REQUEST_ID = P_REQUEST_ID;

        IF NVL (V_COUNT, 0) > 0 THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Total Created : ' || V_COUNT);
        ELSE
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Total Created : 0');
        END IF;

        FND_FILE.PUT_LINE (
            FND_FILE.LOG,
            '=============================================================================');
    END CREATE_BANK_ACCOUNT;

    PROCEDURE CREATE_BANK_ACCT_USE (ERRBUF               OUT NOCOPY VARCHAR2,
                                    RETCODE              OUT NOCOPY VARCHAR2,
                                    P_COMPANY         IN            VARCHAR2,
                                    P_ORG_ID          IN            NUMBER,
                                    P_BANK_ACCOUNT_ID IN            NUMBER) IS
        V_ACCT_USE_ID     NUMBER;
        V_RETURN_STATUS   VARCHAR2 (1);
        V_MSG_COUNT       NUMBER;
        V_MSG_DATA        VARCHAR2 (4000);
        P_ACCT_USE_REC    CE_BANK_PUB.BANKACCT_USE_REC_TYPE;

        CURSOR CUR IS
              SELECT CB.ORG_ID,
                     CB.ORG_NAME,
                     BB.BANK_PARTY_ID
                         BANK_ID,
                     BB.BRANCH_PARTY_ID
                         BANK_BRANCH_ID,
                     CA.BANK_ACCOUNT_ID,
                     CA.BANK_ACCOUNT_NUM,
                     CA.ACCOUNT_OWNER_ORG_ID
                         LEGAL_ENTITY_ID,
                     CA.ASSET_CODE_COMBINATION_ID,
                     CA.CASH_CLEARING_CCID,
                     CA.BANK_CHARGES_CCID,
                     XX_GL_PKG.CREATE_GET_GL_CCID (
                         COMPANY_CODE || '.' || GC.SEGMENT2 || '.999.12110501.99.999.999')
                         REMITTED_RECEIPTS,
                     XX_GL_PKG.CREATE_GET_GL_CCID (
                         COMPANY_CODE || '.' || BRANCH_CODE || '.999.22490302.99.999.999')
                         UNAPPLIED_RECEIPTS,
                     XX_GL_PKG.CREATE_GET_GL_CCID (
                         COMPANY_CODE || '.' || BRANCH_CODE || '.999.22490301.99.999.999')
                         UNIDENTIFIED_RECEIPTS,
                     XX_GL_PKG.CREATE_GET_GL_CCID (
                         COMPANY_CODE || '.' || BRANCH_CODE || '.999.22490303.99.999.999')
                         ON_ACCOUNT_RECEIPTS
                FROM CE_BANK_BRANCHES_V     BB,
                     CE_BANK_ACCOUNTS       CA,
                     GL_CODE_COMBINATIONS   GC,
                     XX_ORG_COMPANY_BRANCH_V CB
               WHERE     BB.BANK_PARTY_ID = CA.BANK_ID
                     AND BB.BRANCH_PARTY_ID = CA.BANK_BRANCH_ID
                     AND CA.ASSET_CODE_COMBINATION_ID = GC.CODE_COMBINATION_ID
                     AND GC.SEGMENT1 = CB.COMPANY_CODE
                     AND CB.PARENT_ORG = UPPER (P_COMPANY)
                     AND CB.ORG_ID = P_ORG_ID
                     AND CA.BANK_ACCOUNT_ID = P_BANK_ACCOUNT_ID
                     AND NOT EXISTS
                             (SELECT 1
                                FROM CE_BANK_ACCT_USES_ALL AU
                               WHERE     CA.BANK_ACCOUNT_ID = AU.BANK_ACCOUNT_ID
                                     AND CB.ORG_ID = AU.ORG_ID)
            ORDER BY CA.BANK_ACCOUNT_ID, CB.ORG_ID;
    BEGIN
        FND_GLOBAL.APPS_INITIALIZE (USER_ID        => FND_GLOBAL.USER_ID,
                                    RESP_ID        => FND_GLOBAL.RESP_ID,
                                    RESP_APPL_ID   => FND_GLOBAL.RESP_APPL_ID);
        MO_GLOBAL.INIT ('CE');

        FOR REC IN CUR LOOP
            --Account Access
            P_ACCT_USE_REC.ORG_TYPE := 'OU';
            P_ACCT_USE_REC.ORG_ID := REC.ORG_ID;
            P_ACCT_USE_REC.BANK_ACCOUNT_ID := REC.BANK_ACCOUNT_ID;
            P_ACCT_USE_REC.AP_USE_ENABLE_FLAG := 'Y';
            P_ACCT_USE_REC.AR_USE_ENABLE_FLAG := 'Y';
            P_ACCT_USE_REC.AUTHORIZED_FLAG := 'Y';
            P_ACCT_USE_REC.DEFAULT_ACCOUNT_FLAG := 'N';

            --Payables Options
            P_ACCT_USE_REC.ASSET_CODE_COMBINATION_ID := REC.ASSET_CODE_COMBINATION_ID;
            P_ACCT_USE_REC.AP_ASSET_CCID := REC.ASSET_CODE_COMBINATION_ID;
            P_ACCT_USE_REC.CASH_CLEARING_CCID := REC.CASH_CLEARING_CCID;
            P_ACCT_USE_REC.BANK_CHARGES_CCID := REC.BANK_CHARGES_CCID;

            --Receivables Options
            P_ACCT_USE_REC.AR_ASSET_CCID := REC.ASSET_CODE_COMBINATION_ID;
            P_ACCT_USE_REC.AR_BANK_CHARGES_CCID := REC.BANK_CHARGES_CCID;
            P_ACCT_USE_REC.REMITTANCE_CCID := REC.REMITTED_RECEIPTS;
            P_ACCT_USE_REC.UNAPPLIED_CCID := REC.UNAPPLIED_RECEIPTS;
            P_ACCT_USE_REC.UNIDENTIFIED_CCID := REC.UNIDENTIFIED_RECEIPTS;
            P_ACCT_USE_REC.ON_ACCOUNT_CCID := REC.ON_ACCOUNT_RECEIPTS;

            --Calling API
            CE_BANK_PUB.CREATE_BANK_ACCT_USE (P_ACCT_USE_REC    => P_ACCT_USE_REC,
                                              X_ACCT_USE_ID     => V_ACCT_USE_ID,
                                              X_RETURN_STATUS   => V_RETURN_STATUS,
                                              X_MSG_COUNT       => V_MSG_COUNT,
                                              X_MSG_DATA        => V_MSG_DATA);

            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                '=============================================================================');

            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Organization  : ' || REC.ORG_NAME);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Bank Acc Num  : ' || REC.BANK_ACCOUNT_NUM);
            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                   'Return Status : '
                || (CASE WHEN V_RETURN_STATUS = 'S' THEN 'Success' ELSE 'Error' END));
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Massage Count : ' || V_MSG_COUNT);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Massage Data  : ' || V_MSG_DATA);

            IF V_ACCT_USE_ID IS NOT NULL THEN
                FND_FILE.PUT_LINE (FND_FILE.LOG, 'Total Added   : 1');
            ELSE
                FND_FILE.PUT_LINE (FND_FILE.LOG, 'Total Added   : 0');
            END IF;

            FND_FILE.PUT_LINE (
                FND_FILE.LOG,
                '=============================================================================');

            UPDATE CE_BANK_ACCT_USES_ALL
               SET PAYMENT_DOC_CATEGORY = 'CHECK PAY'
             WHERE BANK_ACCT_USE_ID = V_ACCT_USE_ID;

            COMMIT;
        END LOOP;
    END CREATE_BANK_ACCT_USE;

    PROCEDURE BANK_LEDGER_SUMMARY (P_COMPANY      IN NUMBER,
                                   P_ACCOUNT_TYPE IN VARCHAR2,
                                   P_DATE_FROM    IN DATE,
                                   P_DATE_TO      IN DATE,
                                   P_STATUS       IN VARCHAR2) AS
    BEGIN
        INSERT INTO XX_BANK_LEDGER_GT (BANK_NAME,
                                       BRANCH_NAME,
                                       ACCOUNT_ID,
                                       ACCOUNT_NUM,
                                       OPENING,
                                       DR_AMOUNT,
                                       CR_AMOUNT,
                                       CLOSING)
            WITH
                XX_BANK_DETAILS_TAB AS
                    (  SELECT BANK_NAME,
                              BRANCH_NAME,
                              ACCOUNT_ID,
                              ACCOUNT_NUM,
                              NVL (SUM (NVL (DR_AMOUNT, 0) - NVL (CR_AMOUNT, 0)), 0)    OPEN_BALANCE,
                              0                                                         DR_AMOUNT,
                              0                                                         CR_AMOUNT
                         FROM XX_BANK_LEDGER_V
                        WHERE     ORG_ID IN (SELECT ORG_ID
                                               FROM XX_ORG_COMPANY_BRANCH_V
                                              WHERE (P_COMPANY = 100 OR COMPANY_CODE = P_COMPANY))
                              AND ACCOUNT_TYPE = NVL (UPPER (P_ACCOUNT_TYPE), ACCOUNT_TYPE)
                              AND CHECK_DATE < P_DATE_FROM
                              AND STATUS = NVL (P_STATUS, STATUS)
                     GROUP BY ACCOUNT_ID,
                              BANK_NAME,
                              BRANCH_NAME,
                              ACCOUNT_ID,
                              ACCOUNT_NUM
                     UNION ALL
                       SELECT BANK_NAME,
                              BRANCH_NAME,
                              ACCOUNT_ID,
                              ACCOUNT_NUM,
                              0                            OPEN_BALANCE,
                              SUM (NVL (DR_AMOUNT, 0))     DR_AMOUNT,
                              SUM (NVL (CR_AMOUNT, 0))     CR_AMOUNT
                         FROM XX_BANK_LEDGER_V
                        WHERE     ORG_ID IN (SELECT ORG_ID
                                               FROM XX_ORG_COMPANY_BRANCH_V
                                              WHERE (P_COMPANY = 100 OR COMPANY_CODE = P_COMPANY))
                              AND ACCOUNT_TYPE = NVL (UPPER (P_ACCOUNT_TYPE), ACCOUNT_TYPE)
                              AND CHECK_DATE >= P_DATE_FROM
                              AND CHECK_DATE <= P_DATE_TO
                              AND STATUS = NVL (P_STATUS, STATUS)
                     GROUP BY ACCOUNT_ID,
                              BANK_NAME,
                              BRANCH_NAME,
                              ACCOUNT_ID,
                              ACCOUNT_NUM)
              SELECT BANK_NAME,
                     BRANCH_NAME,
                     ACCOUNT_ID,
                     ACCOUNT_NUM,
                     SUM (OPEN_BALANCE)                                         OPENING,
                     SUM (DR_AMOUNT)                                            DR_AMOUNT,
                     SUM (CR_AMOUNT)                                            CR_AMOUNT,
                     SUM (OPEN_BALANCE) + SUM (DR_AMOUNT) - SUM (CR_AMOUNT)     CLOSING
                FROM XX_BANK_DETAILS_TAB
            GROUP BY BANK_NAME,
                     BRANCH_NAME,
                     ACCOUNT_ID,
                     ACCOUNT_NUM;
    END;
END;
/
