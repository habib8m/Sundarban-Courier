
CREATE OR REPLACE PACKAGE BODY APPS.XX_AP_PKG
AS
    FUNCTION GET_INVOICE_STATUS(P_INVOICE_ID NUMBER)
        RETURN VARCHAR2
    AS
        V_INVOICE_STATUS   VARCHAR2(32);
    BEGIN
        SELECT APPS.AP_INVOICES_UTILITY_PKG.GET_APPROVAL_STATUS(AI.INVOICE_ID,
                                                                AI.INVOICE_AMOUNT,
                                                                AI.PAYMENT_STATUS_FLAG,
                                                                AI.INVOICE_TYPE_LOOKUP_CODE)    INVOICE_STATUS
          INTO V_INVOICE_STATUS
          FROM AP.AP_INVOICES_ALL AI
         WHERE AI.INVOICE_ID = P_INVOICE_ID;

        RETURN (CASE
                    WHEN V_INVOICE_STATUS = 'NEVER APPROVED' THEN 'Never Validated'
                    WHEN V_INVOICE_STATUS = 'APPROVED' THEN 'Validated'
                    WHEN V_INVOICE_STATUS = 'NEEDS REAPPROVAL' THEN 'Needs Revalidation'
                    WHEN V_INVOICE_STATUS = 'UNAPPROVED' THEN 'Unvalidated'
                    WHEN V_INVOICE_STATUS = 'UNPAID' THEN 'Unpaid'
                    WHEN V_INVOICE_STATUS = 'AVAILABLE' THEN 'Available'
                    WHEN V_INVOICE_STATUS = 'FULL' THEN 'Fully Applied'
                    WHEN V_INVOICE_STATUS = 'PERMANENT' THEN 'Permanent Prepayment'
                    WHEN V_INVOICE_STATUS = 'CANCELLED' THEN 'Cancelled'
                    ELSE V_INVOICE_STATUS
                END);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_INVOICE_STATUS;



    FUNCTION GET_INVOICE_POSTING_STATUS (L_INVOICE_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        INVOICE_POSTING_FLAG        VARCHAR2(1);
        DISTRIBUTION_POSTING_FLAG   VARCHAR2(1);
        L_CASH_BASIS_FLAG           VARCHAR2(1);
        L_ORG_ID                    AP_SYSTEM_PARAMETERS_ALL.ORG_ID%TYPE;


        CURSOR POSTING_CURSOR IS
            SELECT CASH_POSTED_FLAG
              FROM AP_INVOICE_DISTRIBUTIONS_ALL
             WHERE INVOICE_ID = L_INVOICE_ID AND L_CASH_BASIS_FLAG = 'Y'
            UNION
            SELECT ACCRUAL_POSTED_FLAG
              FROM AP_INVOICE_DISTRIBUTIONS_ALL
             WHERE INVOICE_ID = L_INVOICE_ID AND L_CASH_BASIS_FLAG <> 'Y'
            UNION
            SELECT 'P'
              FROM AP_INVOICE_DISTRIBUTIONS_ALL
             WHERE     INVOICE_ID = L_INVOICE_ID
                   AND (   (CASH_POSTED_FLAG = 'Y' AND L_CASH_BASIS_FLAG = 'Y')
                        OR (ACCRUAL_POSTED_FLAG = 'Y' AND L_CASH_BASIS_FLAG <> 'Y'))
                   AND EXISTS
                           (SELECT 'An N is also in the valid flags'
                              FROM AP_INVOICE_DISTRIBUTIONS_ALL
                             WHERE     INVOICE_ID = L_INVOICE_ID
                                   AND (   (CASH_POSTED_FLAG = 'N' AND L_CASH_BASIS_FLAG = 'Y')
                                        OR (ACCRUAL_POSTED_FLAG = 'N' AND L_CASH_BASIS_FLAG <> 'Y')))
            UNION
            SELECT CASH_POSTED_FLAG
              FROM AP_SELF_ASSESSED_TAX_DIST_ALL
             WHERE INVOICE_ID = L_INVOICE_ID AND L_CASH_BASIS_FLAG = 'Y'
            UNION
            SELECT ACCRUAL_POSTED_FLAG
              FROM AP_SELF_ASSESSED_TAX_DIST_ALL
             WHERE INVOICE_ID = L_INVOICE_ID AND L_CASH_BASIS_FLAG <> 'Y'
            UNION
            SELECT 'P'
              FROM AP_SELF_ASSESSED_TAX_DIST_ALL
             WHERE     INVOICE_ID = L_INVOICE_ID
                   AND (   (CASH_POSTED_FLAG = 'Y' AND L_CASH_BASIS_FLAG = 'Y')
                        OR (ACCRUAL_POSTED_FLAG = 'Y' AND L_CASH_BASIS_FLAG <> 'Y'))
                   AND EXISTS
                           (SELECT 'An N is also in the valid flags'
                              FROM AP_SELF_ASSESSED_TAX_DIST_ALL
                             WHERE     INVOICE_ID = L_INVOICE_ID
                                   AND (   (CASH_POSTED_FLAG = 'N' AND L_CASH_BASIS_FLAG = 'Y')
                                        OR (ACCRUAL_POSTED_FLAG = 'N' AND L_CASH_BASIS_FLAG <> 'Y')));
    BEGIN
        SELECT NVL(SOB.SLA_LEDGER_CASH_BASIS_FLAG, 'N'), ASP.ORG_ID
          INTO L_CASH_BASIS_FLAG, L_ORG_ID
          FROM AP_INVOICES_ALL AI, AP_SYSTEM_PARAMETERS_ALL ASP, GL_SETS_OF_BOOKS SOB
         WHERE     AI.INVOICE_ID = L_INVOICE_ID
               AND AI.ORG_ID = ASP.ORG_ID
               AND ASP.SET_OF_BOOKS_ID = SOB.SET_OF_BOOKS_ID;

        INVOICE_POSTING_FLAG := 'X';

        OPEN POSTING_CURSOR;

        LOOP
            FETCH POSTING_CURSOR INTO DISTRIBUTION_POSTING_FLAG;

            EXIT WHEN POSTING_CURSOR%NOTFOUND;

            IF (DISTRIBUTION_POSTING_FLAG = 'S')
            THEN
                INVOICE_POSTING_FLAG := 'S';
            ELSIF (DISTRIBUTION_POSTING_FLAG = 'P' AND INVOICE_POSTING_FLAG <> 'S')
            THEN
                INVOICE_POSTING_FLAG := 'P';
            ELSIF (DISTRIBUTION_POSTING_FLAG = 'N' AND INVOICE_POSTING_FLAG NOT IN ('S', 'P'))
            THEN
                INVOICE_POSTING_FLAG := 'N';
            ELSIF (DISTRIBUTION_POSTING_FLAG IS NULL)
            THEN
                INVOICE_POSTING_FLAG := 'N';
            END IF;

            IF (INVOICE_POSTING_FLAG NOT IN ('S', 'P', 'N'))
            THEN
                INVOICE_POSTING_FLAG := 'Y';
            END IF;
        END LOOP;

        CLOSE POSTING_CURSOR;

        IF (INVOICE_POSTING_FLAG = 'X')
        THEN
            INVOICE_POSTING_FLAG := 'N';
        END IF;

        IF INVOICE_POSTING_FLAG = 'N'
        THEN
            BEGIN
                SELECT 'D'
                  INTO INVOICE_POSTING_FLAG
                  FROM AP_INVOICE_DISTRIBUTIONS_ALL AID, XLA_EVENTS XE
                 WHERE     AID.INVOICE_ID = L_INVOICE_ID
                       AND AID.ACCOUNTING_EVENT_ID = XE.EVENT_ID
                       AND (   (AID.ACCRUAL_POSTED_FLAG = 'N' AND L_CASH_BASIS_FLAG = 'N')
                            OR (AID.CASH_POSTED_FLAG = 'N' AND L_CASH_BASIS_FLAG = 'Y'))
                       AND XE.PROCESS_STATUS_CODE = 'D'
                       AND ROWNUM < 2;
            EXCEPTION
                WHEN OTHERS
                THEN
                    RETURN NULL;
            END;
        END IF;

        RETURN (INVOICE_POSTING_FLAG);
    END GET_INVOICE_POSTING_STATUS;
	
	

    FUNCTION GET_AMOUNT_WITHHELD(P_INVOICE_ID IN NUMBER)
        RETURN NUMBER
    IS
        AMOUNT_WITHHELD   NUMBER := 0;
    BEGIN
        SELECT (0 - SUM(NVL(AMOUNT, 0)))
          INTO AMOUNT_WITHHELD
          FROM AP_INVOICE_DISTRIBUTIONS_ALL
         WHERE INVOICE_ID = P_INVOICE_ID AND LINE_TYPE_LOOKUP_CODE = 'AWT';

        RETURN (AMOUNT_WITHHELD);
    END GET_AMOUNT_WITHHELD;

    FUNCTION GET_VALIDATION_DATE(P_INVOICE_ID NUMBER)
        RETURN DATE
    AS
        V_VALIDATION_DATE   DATE;
    BEGIN
        SELECT MAX(ZD.LAST_UPDATE_DATE)
          INTO V_VALIDATION_DATE
          FROM AP_INVOICES_ALL AI, ZX_LINES_DET_FACTORS ZD
         WHERE     AP_INVOICES_UTILITY_PKG.GET_APPROVAL_STATUS(AI.INVOICE_ID,
                                                               AI.INVOICE_AMOUNT,
                                                               AI.PAYMENT_STATUS_FLAG,
                                                               AI.INVOICE_TYPE_LOOKUP_CODE) =
                   'APPROVED'
               AND AI.INVOICE_ID = ZD.TRX_ID
               AND ZD.APPLICATION_ID = 200
               AND AI.INVOICE_ID = P_INVOICE_ID;

        RETURN V_VALIDATION_DATE;
    EXCEPTION
        WHEN OTHERS
        THEN
            RAISE;
    END GET_VALIDATION_DATE;


    FUNCTION GET_VALIDATION_USER_ID(P_INVOICE_ID NUMBER)
        RETURN NUMBER
    AS
        V_VALIDATION_USER   NUMBER;
    BEGIN
          SELECT MAX(ZD.LAST_UPDATED_BY)
            INTO V_VALIDATION_USER
            FROM AP_INVOICES_ALL AI, ZX_LINES_DET_FACTORS ZD
           WHERE     AP_INVOICES_UTILITY_PKG.GET_APPROVAL_STATUS(AI.INVOICE_ID,
                                                                 AI.INVOICE_AMOUNT,
                                                                 AI.PAYMENT_STATUS_FLAG,
                                                                 AI.INVOICE_TYPE_LOOKUP_CODE) =
                     'APPROVED'
                 AND AI.INVOICE_ID = ZD.TRX_ID
                 AND ZD.APPLICATION_ID = 200
                 AND AI.INVOICE_ID = P_INVOICE_ID
        GROUP BY AI.INVOICE_ID;

        RETURN V_VALIDATION_USER;
    EXCEPTION
        WHEN OTHERS
        THEN
            RAISE;
    END GET_VALIDATION_USER_ID;

    FUNCTION GET_INVOICE_NUM_PAID(L_CHECK_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        L_INV_NUM        AP_INVOICES_ALL.INVOICE_NUM%TYPE;
        L_INV_NUM_LIST   VARCHAR2(2000) := NULL;

        CURSOR INV_NUM_CURSOR IS
            SELECT AI.INVOICE_NUM
              FROM AP_INVOICES_ALL AI, AP_INVOICE_PAYMENTS_ALL AIP
             WHERE AIP.CHECK_ID = L_CHECK_ID AND AIP.INVOICE_ID = AI.INVOICE_ID;
    BEGIN
        OPEN INV_NUM_CURSOR;

        LOOP
            FETCH INV_NUM_CURSOR INTO L_INV_NUM;

            EXIT WHEN INV_NUM_CURSOR%NOTFOUND;

            IF (L_INV_NUM_LIST IS NOT NULL)
            THEN
                L_INV_NUM_LIST := L_INV_NUM_LIST || ', ';
            END IF;

            L_INV_NUM_LIST := L_INV_NUM_LIST || L_INV_NUM;
        END LOOP;

        CLOSE INV_NUM_CURSOR;

        RETURN (L_INV_NUM_LIST);
    END GET_INVOICE_NUM_PAID;

    FUNCTION GET_INVOICE_VOUCHER_PAID(P_CHECK_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_INV_VOUCHER        AP_INVOICES_ALL.DOC_SEQUENCE_VALUE%TYPE;
        V_INV_VOUCHER_LIST   VARCHAR2(2000) := NULL;

        CURSOR INV_VOUCHER_CURSOR IS
            SELECT AI.DOC_SEQUENCE_VALUE
              FROM AP_INVOICES_ALL AI, AP_INVOICE_PAYMENTS_ALL AIP
             WHERE     AIP.CHECK_ID = P_CHECK_ID
                   AND NVL(AIP.REVERSAL_FLAG, 'IBCS') <> 'Y'
                   AND AIP.INVOICE_ID = AI.INVOICE_ID;
    BEGIN
        OPEN INV_VOUCHER_CURSOR;

        LOOP
            FETCH INV_VOUCHER_CURSOR INTO V_INV_VOUCHER;

            EXIT WHEN INV_VOUCHER_CURSOR%NOTFOUND;

            IF (V_INV_VOUCHER_LIST IS NOT NULL)
            THEN
                V_INV_VOUCHER_LIST := V_INV_VOUCHER_LIST || ', ';
            END IF;

            V_INV_VOUCHER_LIST := V_INV_VOUCHER_LIST || V_INV_VOUCHER;
        END LOOP;

        CLOSE INV_VOUCHER_CURSOR;

        RETURN (V_INV_VOUCHER_LIST);
    END GET_INVOICE_VOUCHER_PAID;

    FUNCTION GET_CHECK_NUMBER_FROM_INV(P_INVOICE_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_CHECK_NUMBER        AP_CHECKS_ALL.CHECK_NUMBER%TYPE;
        V_CHECK_NUMBER_LIST   VARCHAR2(2000) := NULL;

        CURSOR CHECK_NUMBER_CUR IS
            SELECT CK.CHECK_NUMBER
              FROM AP_CHECKS_ALL CK, AP_INVOICE_PAYMENTS_ALL PM
             WHERE     PM.INVOICE_ID = P_INVOICE_ID
                   AND CK.CHECK_ID = PM.CHECK_ID
                   AND NVL(PM.REVERSAL_FLAG, 'IBCS') <> 'Y';
    BEGIN
        OPEN CHECK_NUMBER_CUR;

        LOOP
            FETCH CHECK_NUMBER_CUR INTO V_CHECK_NUMBER;

            EXIT WHEN CHECK_NUMBER_CUR%NOTFOUND;

            IF (V_CHECK_NUMBER_LIST IS NOT NULL)
            THEN
                V_CHECK_NUMBER_LIST := V_CHECK_NUMBER_LIST || ', ';
            END IF;

            V_CHECK_NUMBER_LIST := V_CHECK_NUMBER_LIST || V_CHECK_NUMBER;
        END LOOP;

        CLOSE CHECK_NUMBER_CUR;

        RETURN (V_CHECK_NUMBER_LIST);
    END GET_CHECK_NUMBER_FROM_INV;


    FUNCTION GET_MAX_CHECK_NUM_FROM_INVOICE(P_INVOICE_ID IN NUMBER)
        RETURN NUMBER
    IS
        V_OUTPUT   NUMBER;

        CURSOR P_CURSOR IS
            SELECT MAX(CHECK_NUMBER)
              FROM AP_INVOICES_ALL AI, AP_INVOICE_PAYMENTS_ALL PM, AP_CHECKS_ALL CK
             WHERE     AI.INVOICE_ID = PM.INVOICE_ID
                   AND PM.CHECK_ID = CK.CHECK_ID
                   AND NVL(CK.STATUS_LOOKUP_CODE, 'BCL') <> 'VOIDED'
                   AND AI.INVOICE_ID = P_INVOICE_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_OUTPUT;

        CLOSE P_CURSOR;

        RETURN (V_OUTPUT);
    END;

    FUNCTION GET_MAX_CHK_DATE_FROM_INVOICE(P_INVOICE_ID IN NUMBER)
        RETURN DATE
    IS
        V_OUTPUT   DATE;

        CURSOR P_CURSOR IS
            SELECT CK.CHECK_DATE
              FROM AP_CHECKS_ALL CK, AP_INVOICE_PAYMENTS_ALL PM
             WHERE     CK.CHECK_ID = PM.CHECK_ID
                   AND (CK.CHECK_DATE, PM.INVOICE_ID) IN
                           (  SELECT MAX(CK.CHECK_DATE), PM.INVOICE_ID
                                FROM AP_CHECKS_ALL CK, AP_INVOICE_PAYMENTS_ALL PM
                               WHERE     CK.CHECK_ID = PM.CHECK_ID
                                     AND PM.INVOICE_ID = P_INVOICE_ID
                                     AND NVL(PM.REVERSAL_FLAG, 'N') <> 'Y'
                            GROUP BY PM.INVOICE_ID);
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_OUTPUT;

        CLOSE P_CURSOR;

        RETURN (V_OUTPUT);
    END;

    FUNCTION GET_MAX_ACCT_NAME_FROM_INVOICE(P_INVOICE_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_OUTPUT   VARCHAR2(30);

        CURSOR P_CURSOR IS
            SELECT BA.BANK_ACCOUNT_NUM
              FROM AP_INVOICE_PAYMENTS_ALL  PM,
                   AP_CHECKS_ALL            CK,
                   CE_BANK_ACCT_USES_ALL    CU,
                   CE_BANK_ACCOUNTS         BA
             WHERE     PM.CHECK_ID = CK.CHECK_ID
                   AND CK.CE_BANK_ACCT_USE_ID = CU.BANK_ACCT_USE_ID
                   AND CU.BANK_ACCOUNT_ID = BA.BANK_ACCOUNT_ID
                   AND (CK.CHECK_DATE, PM.INVOICE_ID) IN
                           (  SELECT MAX(CK.CHECK_DATE), PM.INVOICE_ID
                                FROM AP_CHECKS_ALL CK, AP_INVOICE_PAYMENTS_ALL PM
                               WHERE     CK.CHECK_ID = PM.CHECK_ID
                                     AND NVL(PM.REVERSAL_FLAG, 'N') <> 'Y'
                                     AND PM.INVOICE_ID = P_INVOICE_ID
                            GROUP BY PM.INVOICE_ID);
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_OUTPUT;

        CLOSE P_CURSOR;

        RETURN (V_OUTPUT);
    END;

    FUNCTION GET_INVOICE_PAID_AMOUNT (P_INVOICE_ID IN NUMBER)
        RETURN NUMBER
    AS
        V_PAY_AMOUNT   NUMBER;
    BEGIN
          SELECT SUM(AMOUNT + DISCOUNT_TAKEN)
            INTO V_PAY_AMOUNT
            FROM AP_INVOICE_PAYMENTS_ALL
           WHERE INVOICE_ID = P_INVOICE_ID AND NVL(REVERSAL_FLAG, 'N') <> 'Y'
        GROUP BY INVOICE_ID;

        RETURN NVL(V_PAY_AMOUNT, 0);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 0;
    END GET_INVOICE_PAID_AMOUNT;

    FUNCTION GET_INVOICE_CURRENCY_CODE(P_INVOICE_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_OUTPUT   VARCHAR2(128);

        CURSOR P_CURSOR IS
            SELECT DECODE(
                       AI.EXCHANGE_RATE,
                       NULL, AI.INVOICE_CURRENCY_CODE,
                          AI.INVOICE_CURRENCY_CODE
                       || ' ('
                       || TO_CHAR(ABS(AI.INVOICE_AMOUNT), 'FM999,999,999,990.90')
                       || ' @ '
                       || AI.EXCHANGE_RATE
                       || ')')
              FROM AP_INVOICES_ALL AI
             WHERE AI.INVOICE_ID = P_INVOICE_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_OUTPUT;

        CLOSE P_CURSOR;

        RETURN (V_OUTPUT);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;

    FUNCTION GET_PARTY_NAME_WITH_NUMBER(P_PARTY_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_PARTY_NAME   HZ_PARTIES.PARTY_NAME%TYPE := '';

        CURSOR P_PARTY_CURSOR IS
            SELECT NVL(SP.SEGMENT1, HP.PARTY_NUMBER) || ' - ' || HP.PARTY_NAME
              FROM HZ_PARTIES HP, AP_SUPPLIERS SP
             WHERE HP.PARTY_ID = SP.PARTY_ID(+) AND HP.PARTY_ID = P_PARTY_ID;
    BEGIN
        OPEN P_PARTY_CURSOR;

        FETCH P_PARTY_CURSOR INTO V_PARTY_NAME;

        CLOSE P_PARTY_CURSOR;

        RETURN (V_PARTY_NAME);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_PARTY_NAME_WITH_NUMBER;

    FUNCTION GET_VENDOR_NAME_WITH_NUMBER(P_VENDOR_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_VENDOR_NAME   AP_SUPPLIERS.VENDOR_NAME%TYPE := '';

        CURSOR P_VENDOR_CURSOR IS
            SELECT SEGMENT1 || ' - ' || VENDOR_NAME
              FROM AP_SUPPLIERS
             WHERE VENDOR_ID = P_VENDOR_ID;
    BEGIN
        OPEN P_VENDOR_CURSOR;

        FETCH P_VENDOR_CURSOR INTO V_VENDOR_NAME;

        CLOSE P_VENDOR_CURSOR;

        RETURN (V_VENDOR_NAME);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_VENDOR_NAME_WITH_NUMBER;


    FUNCTION GET_VENDOR_NUMBER_FROM_ID(P_VENDOR_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_VENDOR_NAME   AP_SUPPLIERS.SEGMENT1%TYPE := '';

        CURSOR P_VENDOR_CURSOR IS
            SELECT SEGMENT1
              FROM AP_SUPPLIERS
             WHERE VENDOR_ID = P_VENDOR_ID;
    BEGIN
        OPEN P_VENDOR_CURSOR;

        FETCH P_VENDOR_CURSOR INTO V_VENDOR_NAME;

        CLOSE P_VENDOR_CURSOR;

        RETURN (V_VENDOR_NAME);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;

    FUNCTION GET_EMP_NAME_WITH_NUMBER(P_EMPLOYEE_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_VENDOR_NAME   AP_SUPPLIERS.VENDOR_NAME%TYPE := '';

        CURSOR P_VENDOR_CURSOR IS
            SELECT VENDOR_NAME
              FROM AP_SUPPLIERS
             WHERE EMPLOYEE_ID = P_EMPLOYEE_ID;
    BEGIN
        OPEN P_VENDOR_CURSOR;

        FETCH P_VENDOR_CURSOR INTO V_VENDOR_NAME;

        CLOSE P_VENDOR_CURSOR;

        RETURN (V_VENDOR_NAME);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;

    FUNCTION GET_EMP_NAME_FROM_VENDOR_ID(P_VENDOR_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_RESULT   VARCHAR2(128);

        CURSOR P_CURSOR IS
            SELECT    DECODE(EMP.FIRST_NAME, NULL, NULL, EMP.FIRST_NAME)
                   || DECODE(EMP.MIDDLE_NAMES, NULL, NULL, ' ' || EMP.MIDDLE_NAMES)
                   || DECODE(EMP.LAST_NAME, NULL, NULL, ' ' || EMP.LAST_NAME)
              FROM AP_SUPPLIERS SUP, PER_ALL_PEOPLE_F EMP
             WHERE SUP.EMPLOYEE_ID = EMP.PERSON_ID AND SUP.VENDOR_ID = P_VENDOR_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN V_RESULT;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;


    FUNCTION GET_VENDOR_NUMBER(P_VENDOR_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_VENDOR_NUMBER   AP_SUPPLIERS.SEGMENT1%TYPE := '';

        CURSOR P_VENDOR_CURSOR IS
            SELECT SEGMENT1
              FROM AP_SUPPLIERS
             WHERE VENDOR_ID = P_VENDOR_ID;
    BEGIN
        OPEN P_VENDOR_CURSOR;

        FETCH P_VENDOR_CURSOR INTO V_VENDOR_NUMBER;

        CLOSE P_VENDOR_CURSOR;

        RETURN (V_VENDOR_NUMBER);
    END GET_VENDOR_NUMBER;

    FUNCTION GET_PARTY_NAME(P_PARTY_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_PARTY_NAME   HZ_PARTIES.PARTY_NAME%TYPE := '';

        CURSOR P_PARTY_CURSOR IS
            SELECT PARTY_NAME
              FROM HZ_PARTIES
             WHERE PARTY_ID = P_PARTY_ID;
    BEGIN
        OPEN P_PARTY_CURSOR;

        FETCH P_PARTY_CURSOR INTO V_PARTY_NAME;

        CLOSE P_PARTY_CURSOR;

        RETURN (V_PARTY_NAME);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_PARTY_NAME;

    FUNCTION GET_VENDOR_NAME(P_VENDOR_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_VENDOR_NAME   AP_SUPPLIERS.VENDOR_NAME%TYPE := '';

        CURSOR P_VENDOR_CURSOR IS
            SELECT VENDOR_NAME
              FROM AP_SUPPLIERS
             WHERE VENDOR_ID = P_VENDOR_ID;
    BEGIN
        OPEN P_VENDOR_CURSOR;

        FETCH P_VENDOR_CURSOR INTO V_VENDOR_NAME;

        CLOSE P_VENDOR_CURSOR;

        RETURN (V_VENDOR_NAME);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_VENDOR_NAME;

    FUNCTION GET_VENDOR_ID_FROM_NAME(P_VENDOR_NAME IN VARCHAR2)
        RETURN NUMBER
    AS
        V_OUTPUT   NUMBER;
    BEGIN
        SELECT VENDOR_ID
          INTO V_OUTPUT
          FROM PO_VENDORS
         WHERE UPPER(VENDOR_NAME) = UPPER(P_VENDOR_NAME);

        RETURN (V_OUTPUT);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;

    FUNCTION GET_BS_FROM_BANK_ACCT_USE_ID(P_BANK_ACCT_USE_ID NUMBER)
        RETURN VARCHAR2
    AS
        V_BALANCING_SEGMENT   VARCHAR2(240);
    BEGIN
        SELECT GCC.SEGMENT1
          INTO V_BALANCING_SEGMENT
          FROM CE_BANK_ACCOUNTS BA, CE_BANK_ACCT_USES_ALL CU, GL_CODE_COMBINATIONS GCC
         WHERE     CU.BANK_ACCOUNT_ID = BA.BANK_ACCOUNT_ID
               AND BA.ASSET_CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
               AND CU.BANK_ACCT_USE_ID = P_BANK_ACCT_USE_ID;

        RETURN (V_BALANCING_SEGMENT);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;

    FUNCTION GET_BANK_NAME_FROM_BANK_ID(P_BANK_ID IN NUMBER)
        RETURN VARCHAR2
    AS
        V_BANK_NAME   VARCHAR2(360);
    BEGIN
        SELECT BANK_NAME
          INTO V_BANK_NAME
          FROM CE_BANKS_V
         WHERE BANK_PARTY_ID = P_BANK_ID;

        RETURN V_BANK_NAME;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;

    FUNCTION GET_BRANCH_NAME_FROM_BRANCH_ID(P_BRANCH_ID IN NUMBER)
        RETURN VARCHAR2
    AS
        V_BRANCH_NAME   VARCHAR2(360);
    BEGIN
        SELECT BANK_BRANCH_NAME
          INTO V_BRANCH_NAME
          FROM CE_BANK_BRANCHES_V
         WHERE BRANCH_PARTY_ID = P_BRANCH_ID;

        RETURN V_BRANCH_NAME;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;


    FUNCTION GET_BANK_NAME_FROM_CHECK_ID(P_CHECK_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_RESULT   VARCHAR2(240);

        CURSOR P_CURSOR IS
            SELECT BN.BANK_NAME
              FROM AP_CHECKS_ALL          CK,
                   CE_BANK_ACCT_USES_ALL  CU,
                   CE_BANK_ACCOUNTS       BA,
                   CE_BANKS_V             BN
             WHERE     CK.CE_BANK_ACCT_USE_ID = CU.BANK_ACCT_USE_ID
                   AND CU.BANK_ACCOUNT_ID = BA.BANK_ACCOUNT_ID
                   AND BA.BANK_ID = BN.BANK_PARTY_ID
                   AND CK.CHECK_ID = P_CHECK_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN (V_RESULT);
    END;

    FUNCTION GET_BRANCH_NAME_FROM_CHECK_ID(P_CHECK_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_RESULT   VARCHAR2(240);

        CURSOR P_CURSOR IS
            SELECT MAX(BB.BANK_BRANCH_NAME)
              FROM AP_CHECKS_ALL          CK,
                   CE_BANK_ACCT_USES_ALL  CU,
                   CE_BANK_ACCOUNTS       BA,
                   CE_BANK_BRANCHES_V     BB
             WHERE     CK.CE_BANK_ACCT_USE_ID = CU.BANK_ACCT_USE_ID
                   AND CU.BANK_ACCOUNT_ID = BA.BANK_ACCOUNT_ID
                   AND BA.BANK_BRANCH_ID = BB.BRANCH_PARTY_ID
                   AND CK.CHECK_ID = P_CHECK_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN (V_RESULT);
    END;

    FUNCTION GET_BANK_ACCOUNT_FROM_CHECK_ID(P_CHECK_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_RESULT   VARCHAR2(240);

        CURSOR P_CURSOR IS
            SELECT MAX(BA.BANK_ACCOUNT_NUM)
              FROM AP_CHECKS_ALL CK, CE_BANK_ACCT_USES_ALL CU, CE_BANK_ACCOUNTS BA
             WHERE     CK.CE_BANK_ACCT_USE_ID = CU.BANK_ACCT_USE_ID
                   AND CU.BANK_ACCOUNT_ID = BA.BANK_ACCOUNT_ID
                   AND CK.CHECK_ID = P_CHECK_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN (V_RESULT);
    END;
	
	

    FUNCTION GET_INVOICE_DUE_AMOUNT (P_INVOICE_ID IN NUMBER, P_DATE DATE DEFAULT '23-JUN-2099')
        RETURN NUMBER
    AS
        V_DUE_AMOUNT   NUMBER;
    BEGIN
          SELECT SUM(AMOUNT)
            INTO V_DUE_AMOUNT
            FROM AP_INVOICE_DISTRIBUTIONS_ALL
           WHERE INVOICE_ID = P_INVOICE_ID AND ACCOUNTING_DATE <= P_DATE
        GROUP BY INVOICE_ID;

        RETURN NVL(V_DUE_AMOUNT, 0);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 0;
    END GET_INVOICE_DUE_AMOUNT;
	
	

    FUNCTION INV_PAY_BY_CHECK_AFTER_DATE (P_INVOICE_ID IN NUMBER, P_DATE IN DATE)
        RETURN NUMBER
    AS
        V_PAY_AMOUNT   NUMBER;
    BEGIN
          SELECT SUM(AMOUNT + DISCOUNT_TAKEN)
            INTO V_PAY_AMOUNT
            FROM AP_INVOICE_PAYMENTS_ALL
           WHERE INVOICE_ID = P_INVOICE_ID AND REVERSAL_FLAG <> 'Y' AND ACCOUNTING_DATE > P_DATE
        GROUP BY INVOICE_ID;

        RETURN NVL(V_PAY_AMOUNT, 0);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 0;
    END INV_PAY_BY_CHECK_AFTER_DATE;


    FUNCTION INV_PAY_BY_PREPAY_AFTER_DATE (P_INVOICE_ID IN NUMBER, P_DATE IN DATE)
        RETURN NUMBER
    AS
        V_ADJUST_AMOUNT   NUMBER;
    BEGIN
          SELECT SUM(ADS.AMOUNT)
            INTO V_ADJUST_AMOUNT
            FROM AP_INVOICES_ALL             AIS,
                 AP_INVOICE_DISTRIBUTIONS_ALL ADS,
                 AP_INVOICES_ALL             AIP,
                 AP_INVOICE_DISTRIBUTIONS_ALL ADP
           WHERE     AIS.INVOICE_ID = ADS.INVOICE_ID
                 AND AIP.INVOICE_ID = ADP.INVOICE_ID
                 AND ADS.INVOICE_ID = P_INVOICE_ID
                 AND ADS.PREPAY_DISTRIBUTION_ID = ADP.INVOICE_DISTRIBUTION_ID
                 AND AIP.INVOICE_TYPE_LOOKUP_CODE = 'PREPAYMENT'
                 AND AIS.CANCELLED_DATE IS NULL
                 AND ADS.LINE_TYPE_LOOKUP_CODE = 'PREPAY'
                 AND ADS.REVERSAL_FLAG <> 'Y'
                 AND ADS.ACCOUNTING_DATE > P_DATE
        GROUP BY P_INVOICE_ID;

        RETURN NVL(ABS(V_ADJUST_AMOUNT), 0);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 0;
    END INV_PAY_BY_PREPAY_AFTER_DATE;
	

    FUNCTION INV_AMOUNT_DEDUCTED_AFTER_DATE(P_INVOICE_ID IN NUMBER, P_DATE IN DATE)
        RETURN NUMBER
    IS
        AMOUNT_DEDUCTED   NUMBER := 0;
    BEGIN
        SELECT (0 - SUM(NVL(AMOUNT, 0)))
          INTO AMOUNT_DEDUCTED
          FROM AP_INVOICE_DISTRIBUTIONS_ALL
         WHERE     INVOICE_ID = P_INVOICE_ID
               AND LINE_TYPE_LOOKUP_CODE = 'AWT'
               AND REVERSAL_FLAG <> 'Y'
               AND ACCOUNTING_DATE > P_DATE;

        RETURN NVL(AMOUNT_DEDUCTED, 0);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 0;
    END INV_AMOUNT_DEDUCTED_AFTER_DATE;


    FUNCTION GET_PREPAY_AMOUNT_APPLIED(P_INVOICE_ID IN NUMBER)
        RETURN NUMBER
    AS
        V_RESULT   NUMBER;

        CURSOR P_CURSOR IS
            SELECT SUM(NVL(ADS.AMOUNT, 0))
              FROM AP_INVOICES_ALL               AIS,
                   AP_INVOICE_DISTRIBUTIONS_ALL  ADS,
                   AP_INVOICES_ALL               AIP,
                   AP_INVOICE_DISTRIBUTIONS_ALL  ADP
             WHERE     AIS.INVOICE_ID = ADS.INVOICE_ID
                   AND AIP.INVOICE_ID = ADP.INVOICE_ID
                   AND ADS.PREPAY_DISTRIBUTION_ID = ADP.INVOICE_DISTRIBUTION_ID
                   AND AIS.CANCELLED_DATE IS NULL
                   AND AIP.CANCELLED_DATE IS NULL
                   AND AIS.INVOICE_TYPE_LOOKUP_CODE = 'STANDARD'
                   AND AIP.INVOICE_TYPE_LOOKUP_CODE = 'PREPAYMENT'
                   AND ADS.LINE_TYPE_LOOKUP_CODE = 'PREPAY'
                   AND NVL(ADS.REVERSAL_FLAG, 'N') <> 'Y'
                   AND NVL(ADP.REVERSAL_FLAG, 'N') <> 'Y'
                   AND AIP.INVOICE_ID = P_INVOICE_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN NVL((0 - V_RESULT), 0);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;


    FUNCTION PREPAY_APPLIED_AFTER_DATE(P_INVOICE_ID IN NUMBER, P_DATE IN DATE)
        RETURN NUMBER
    AS
        V_PREPAY_AMOUNT   NUMBER;
    BEGIN
          SELECT SUM(ADS.AMOUNT)
            INTO V_PREPAY_AMOUNT
            FROM AP_INVOICES_ALL             AIS,
                 AP_INVOICE_DISTRIBUTIONS_ALL ADS,
                 AP_INVOICES_ALL             AIP,
                 AP_INVOICE_DISTRIBUTIONS_ALL ADP
           WHERE     AIS.INVOICE_ID = ADS.INVOICE_ID
                 AND AIP.INVOICE_ID = ADP.INVOICE_ID
                 --AND ADP.INVOICE_ID = P_INVOICE_ID old
                 AND ADS.INVOICE_ID = P_INVOICE_ID
                 AND ADS.PREPAY_DISTRIBUTION_ID = ADP.INVOICE_DISTRIBUTION_ID
                 AND AIS.INVOICE_TYPE_LOOKUP_CODE = 'STANDARD'
                 AND AIS.CANCELLED_DATE IS NULL
                 AND ADS.LINE_TYPE_LOOKUP_CODE = 'PREPAY'
                 AND ADS.REVERSAL_FLAG <> 'Y'
                 AND ADS.ACCOUNTING_DATE > P_DATE
        GROUP BY ADS.INVOICE_ID;

        RETURN NVL(ABS(V_PREPAY_AMOUNT), 0);
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            RETURN 0;
    END PREPAY_APPLIED_AFTER_DATE;

    FUNCTION PREPAY_DIST_APPLIED_AFTER_DATE(P_INVOICE_DISTRIBUTION_ID IN NUMBER, P_DATE IN DATE)
        RETURN NUMBER
    AS
        V_PREPAY_AMOUNT   NUMBER;
    BEGIN
          SELECT NVL(SUM(ADS.AMOUNT), 0)
            INTO V_PREPAY_AMOUNT
            FROM AP_INVOICES_ALL             AIS,
                 AP_INVOICE_DISTRIBUTIONS_ALL ADS,
                 AP_INVOICES_ALL             AIP,
                 AP_INVOICE_DISTRIBUTIONS_ALL ADP
           WHERE     AIS.INVOICE_ID = ADS.INVOICE_ID
                 AND AIP.INVOICE_ID = ADP.INVOICE_ID
                 AND ADP.INVOICE_DISTRIBUTION_ID = P_INVOICE_DISTRIBUTION_ID
                 AND ADS.PREPAY_DISTRIBUTION_ID = ADP.INVOICE_DISTRIBUTION_ID
                 AND AIS.INVOICE_TYPE_LOOKUP_CODE = 'STANDARD'
                 AND ADS.LINE_TYPE_LOOKUP_CODE = 'PREPAY'
                 AND AIP.CANCELLED_DATE IS NULL
                 AND AIS.CANCELLED_DATE IS NULL
                 AND NVL(ADP.REVERSAL_FLAG, 'N') <> 'Y'
                 AND NVL(ADS.REVERSAL_FLAG, 'N') <> 'Y'
                 AND ADS.ACCOUNTING_DATE > P_DATE
        GROUP BY ADP.INVOICE_DISTRIBUTION_ID;

        RETURN NVL(ABS(V_PREPAY_AMOUNT), 0);
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            RETURN 0;
    END PREPAY_DIST_APPLIED_AFTER_DATE;
  
  
  
    FUNCTION GET_INVOICE_UNPAID_AMOUNT (P_INVOICE_ID NUMBER, P_DATE DATE DEFAULT '23-JUN-2099')
        RETURN NUMBER
    AS
        V_UNPAID_AMOUNT   NUMBER := 0;
    BEGIN
        SELECT   XX_AP_PKG.GET_INVOICE_DUE_AMOUNT (P_INVOICE_ID, P_DATE)
               - XX_AP_PKG.GET_INVOICE_PAID_AMOUNT (P_INVOICE_ID)
               + XX_AP_PKG.INV_PAY_BY_CHECK_AFTER_DATE (P_INVOICE_ID, P_DATE)
               + XX_AP_PKG.INV_PAY_BY_PREPAY_AFTER_DATE (P_INVOICE_ID, P_DATE)
               + XX_AP_PKG.INV_AMOUNT_DEDUCTED_AFTER_DATE (P_INVOICE_ID, P_DATE)
          INTO V_UNPAID_AMOUNT
          FROM DUAL;

        RETURN V_UNPAID_AMOUNT;
    EXCEPTION
        WHEN OTHERS
        THEN
            RAISE;
    END GET_INVOICE_UNPAID_AMOUNT;
	
	

    FUNCTION GET_INVOICE_AGING_AMOUNT(P_INVOICE_ID NUMBER,
                                      P_DATE       DATE DEFAULT SYSDATE,
                                      P_DAYS_FROM  NUMBER,
                                      P_DAYS_TO    NUMBER)
        RETURN NUMBER
    IS
        V_OUTPUT   VARCHAR2(512);

        CURSOR P_CURSOR IS
              SELECT SUM((NVL(APS.AMOUNT_REMAINING, 0) * NVL(AIA.EXCHANGE_RATE, 1)))
                FROM AP_SUPPLIERS SUP, AP_INVOICES_ALL AIA, AP_PAYMENT_SCHEDULES_ALL APS
               WHERE     SUP.VENDOR_ID = AIA.VENDOR_ID
                     AND AIA.INVOICE_ID = APS.INVOICE_ID
                     AND NVL(APS.AMOUNT_REMAINING, 0) <> 0
                     AND NVL(AIA.PAYMENT_STATUS_FLAG, 'N') IN ('N', 'P')
                     AND AIA.INVOICE_ID = P_INVOICE_ID
                     AND (TRUNC(P_DATE) - TRUNC(AIA.INVOICE_DATE)) >= P_DAYS_FROM
                     AND (TRUNC(P_DATE) - TRUNC(AIA.INVOICE_DATE)) <= P_DAYS_TO
            GROUP BY AIA.INVOICE_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_OUTPUT;

        CLOSE P_CURSOR;

        RETURN (V_OUTPUT);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;

    FUNCTION GET_SUPPLIER_ADDRESS(P_VENDOR_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_OUTPUT   VARCHAR2(512);

        CURSOR P_CURSOR IS
            SELECT VENDOR_ADDRESS
              FROM (SELECT ST.VENDOR_ID,
                           ST.VENDOR_SITE_ID,
                              DECODE(ST.ADDRESS_LINE1, NULL, NULL, ST.ADDRESS_LINE1)
                           || DECODE(ST.ADDRESS_LINE2, NULL, NULL, ', ' || ST.ADDRESS_LINE2)
                           || DECODE(ST.ADDRESS_LINE3, NULL, NULL, ', ' || ST.ADDRESS_LINE3)
                           || DECODE(ST.CITY, NULL, NULL, ', ' || ST.CITY)
                           || DECODE(ST.ZIP, NULL, NULL, ', ' || ST.ZIP)
                           || DECODE(CN.TERRITORY_SHORT_NAME,
                                     NULL, NULL,
                                     ', ' || CN.TERRITORY_SHORT_NAME)    VENDOR_ADDRESS
                      FROM AP_SUPPLIERS AV, AP_SUPPLIER_SITES_ALL ST, FND_TERRITORIES_TL CN
                     WHERE AV.VENDOR_ID = ST.VENDOR_ID AND ST.COUNTRY = CN.TERRITORY_CODE) VENDOR,
                   (  SELECT VENDOR_ID, MIN(VENDOR_SITE_ID) VENDOR_SITE_ID
                        FROM AP_SUPPLIER_SITES_ALL
                    GROUP BY VENDOR_ID) SITE
             WHERE     VENDOR.VENDOR_ID = SITE.VENDOR_ID
                   AND VENDOR.VENDOR_SITE_ID = SITE.VENDOR_SITE_ID
                   AND VENDOR.VENDOR_ID = P_VENDOR_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_OUTPUT;

        CLOSE P_CURSOR;

        RETURN (V_OUTPUT);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;



    FUNCTION GET_SUPPLIER_CITY(P_VENDOR_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_OUTPUT   VARCHAR2(512);

        CURSOR P_CURSOR IS
            SELECT VENDOR_CITY
              FROM (SELECT ST.VENDOR_ID, ST.VENDOR_SITE_ID, ST.CITY VENDOR_CITY
                      FROM AP_SUPPLIERS AV, AP_SUPPLIER_SITES_ALL ST, FND_TERRITORIES_TL CN
                     WHERE AV.VENDOR_ID = ST.VENDOR_ID AND ST.COUNTRY = CN.TERRITORY_CODE) VENDOR,
                   (  SELECT VENDOR_ID, MIN(VENDOR_SITE_ID) VENDOR_SITE_ID
                        FROM AP_SUPPLIER_SITES_ALL
                    GROUP BY VENDOR_ID) SITE
             WHERE     VENDOR.VENDOR_ID = SITE.VENDOR_ID
                   AND VENDOR.VENDOR_SITE_ID = SITE.VENDOR_SITE_ID
                   AND VENDOR.VENDOR_ID = P_VENDOR_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_OUTPUT;

        CLOSE P_CURSOR;

        RETURN (V_OUTPUT);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;


    FUNCTION GET_SUPPLIER_COUNTRY_NAME(P_VENDOR_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_COUNTRY_NAME   FND_TERRITORIES_TL.TERRITORY_SHORT_NAME%TYPE := '';

        CURSOR P_COUNTRY_CURSOR IS
              SELECT MAX(CO.TERRITORY_SHORT_NAME)
                FROM AP_SUPPLIERS AV, AP_SUPPLIER_SITES_ALL ST, FND_TERRITORIES_TL CO
               WHERE     AV.VENDOR_ID = ST.VENDOR_ID
                     AND ST.COUNTRY = CO.TERRITORY_CODE
                     AND AV.VENDOR_ID = P_VENDOR_ID
            GROUP BY AV.VENDOR_ID;
    BEGIN
        OPEN P_COUNTRY_CURSOR;

        FETCH P_COUNTRY_CURSOR INTO V_COUNTRY_NAME;

        CLOSE P_COUNTRY_CURSOR;

        RETURN (NVL(V_COUNTRY_NAME, 'Not Defined'));
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;

    FUNCTION GET_RECEIPT_NUMBER_FROM_INV(P_INVOICE_ID NUMBER)
        RETURN VARCHAR2
    IS
        V_RESULT        AP_INVOICE_LINES_V.RECEIPT_NUMBER%TYPE;
        V_RESULT_LIST   VARCHAR2(2000) := NULL;

        CURSOR P_CURSOR IS
            SELECT DISTINCT RECEIPT_NUMBER
              FROM AP_INVOICE_LINES_V
             WHERE INVOICE_ID = P_INVOICE_ID;
    BEGIN
        OPEN P_CURSOR;

        LOOP
            FETCH P_CURSOR INTO V_RESULT;

            EXIT WHEN P_CURSOR%NOTFOUND;

            IF (V_RESULT_LIST IS NOT NULL)
            THEN
                V_RESULT_LIST := V_RESULT_LIST || ', ';
            END IF;

            V_RESULT_LIST := V_RESULT_LIST || V_RESULT;
        END LOOP;

        CLOSE P_CURSOR;

        RETURN (V_RESULT_LIST);
    END;

    FUNCTION GET_WITHHOLDING_VAT_FROM_CHECK(P_CHECK_ID NUMBER, P_INVOICE_ID NUMBER)
        RETURN NUMBER
    IS
        V_OUTPUT   NUMBER;

        CURSOR P_CURSOR IS
            SELECT SUM(0 - NVL(AID.BASE_AMOUNT, AID.AMOUNT))
              FROM AP_CHECKS_ALL                 ACA,
                   AP_INVOICE_PAYMENTS_ALL       AIP,
                   AP_INVOICES_ALL               AIA,
                   AP_INVOICE_DISTRIBUTIONS_ALL  AID
             WHERE     ACA.CHECK_ID = AIP.CHECK_ID
                   AND AIP.INVOICE_ID = AIA.INVOICE_ID
                   AND AIA.INVOICE_ID = AID.INVOICE_ID
                   -- AND (AID.ACCOUNTING_DATE = '29-FEB-2012' OR
                   AND ACA.CHECK_DATE = AID.ACCOUNTING_DATE
                   AND AID.LINE_TYPE_LOOKUP_CODE = 'AWT'
                   --AND AID.DIST_CODE_COMBINATION_ID = 28237
                   AND XX_COM_PKG.GET_SEGMENT_VALUE_FROM_CCID(AID.DIST_CODE_COMBINATION_ID, 5) IN
                           ('22020203')
                   AND ACA.CHECK_ID = P_CHECK_ID
                   AND AIP.INVOICE_ID = P_INVOICE_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_OUTPUT;

        CLOSE P_CURSOR;

        RETURN (V_OUTPUT);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;

    FUNCTION GET_WITHHOLDING_TAX_FROM_CHECK(P_CHECK_ID NUMBER, P_INVOICE_ID NUMBER)
        RETURN NUMBER
    IS
        V_OUTPUT   NUMBER;

        CURSOR P_CURSOR IS
            SELECT SUM(0 - NVL(AID.BASE_AMOUNT, AID.AMOUNT))
              FROM AP_CHECKS_ALL                 ACA,
                   AP_INVOICE_PAYMENTS_ALL       AIP,
                   AP_INVOICES_ALL               AIA,
                   AP_INVOICE_DISTRIBUTIONS_ALL  AID
             WHERE     ACA.CHECK_ID = AIP.CHECK_ID
                   AND AIP.INVOICE_ID = AIA.INVOICE_ID
                   AND AIA.INVOICE_ID = AID.INVOICE_ID
                   -- AND (AID.ACCOUNTING_DATE = '29-FEB-2012' OR
                   AND ACA.CHECK_DATE = AID.ACCOUNTING_DATE
                   AND AID.LINE_TYPE_LOOKUP_CODE = 'AWT'
                   --AND AID.DIST_CODE_COMBINATION_ID IN (22237, 32293)
                   AND XX_COM_PKG.GET_SEGMENT_VALUE_FROM_CCID(AID.DIST_CODE_COMBINATION_ID, 5) IN
                           ('22020201')
                   AND ACA.CHECK_ID = P_CHECK_ID
                   AND AIP.INVOICE_ID = P_INVOICE_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_OUTPUT;

        CLOSE P_CURSOR;

        RETURN (V_OUTPUT);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;

    FUNCTION GET_LAST_GRN_DATE(P_LC_ID IN NUMBER)
        RETURN DATE
    IS
        V_OUTPUT   DATE;

        CURSOR P_CURSOR IS
            SELECT TRUNC(MAX(RCT.TRANSACTION_DATE))
              FROM RCV_SHIPMENT_HEADERS  RSH,
                   RCV_SHIPMENT_LINES    RSL,
                   PO_HEADERS_ALL        POH,
                   PO_LINES_ALL          POL,
                   RCV_TRANSACTIONS      RCT,
                   XX_LC_DETAILS         LCD
             WHERE     RSH.SHIPMENT_HEADER_ID = RSL.SHIPMENT_HEADER_ID
                   AND RSL.PO_HEADER_ID = POH.PO_HEADER_ID
                   AND RSL.PO_LINE_ID = POL.PO_LINE_ID
                   AND RSL.SHIPMENT_HEADER_ID = RCT.SHIPMENT_HEADER_ID
                   AND RSL.SHIPMENT_LINE_ID = RCT.SHIPMENT_LINE_ID
                   AND RCT.TRANSACTION_TYPE IN ('RECEIVE', 'MATCH')
                   AND POH.PO_HEADER_ID = LCD.PO_HEADER_ID
                   AND LCD.LC_ID = P_LC_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_OUTPUT;

        CLOSE P_CURSOR;

        RETURN (V_OUTPUT);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;


    FUNCTION GET_PREPAY_AMOUNT_REMAINING(P_INVOICE_ID IN NUMBER)
        RETURN NUMBER
    IS
        V_OUTPUT   NUMBER := 0;

        CURSOR P_CURSOR IS
            SELECT SUM(NVL(AID.PREPAY_AMOUNT_REMAINING, AID.TOTAL_DIST_AMOUNT))
              FROM AP_INVOICES_ALL AIA, AP_INVOICE_LINES_ALL AIL, AP_INVOICE_DISTRIBUTIONS_ALL AID
             WHERE     AIA.INVOICE_ID = AIL.INVOICE_ID
                   AND AIL.INVOICE_ID = AID.INVOICE_ID
                   AND AIL.LINE_NUMBER = AID.INVOICE_LINE_NUMBER
                   AND NVL(AID.REVERSAL_FLAG, 'N') <> 'Y'
                   AND NVL(AIL.LINE_SELECTED_FOR_APPL_FLAG, 'N') <> 'Y'
                   AND AIL.LINE_TYPE_LOOKUP_CODE <> 'TAX'
                   AND AID.LINE_TYPE_LOOKUP_CODE IN ('ITEM',
                                                     'ACCRUAL',
                                                     'REC_TAX',
                                                     'NONREC_TAX')
                   AND AIA.INVOICE_TYPE_LOOKUP_CODE = 'PREPAYMENT'
                   AND AIA.EARLIEST_SETTLEMENT_DATE IS NOT NULL
                   AND AID.INVOICE_ID = P_INVOICE_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_OUTPUT;

        CLOSE P_CURSOR;

        RETURN (V_OUTPUT);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;

    FUNCTION GET_CHECK_CASH_FROM_INV(P_INVOICE_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_CHECK_NUMBER        VARCHAR2(2000);
        V_CHECK_NUMBER_LIST   VARCHAR2(2000) := NULL;

        CURSOR CHECK_NUMBER_CUR IS
            SELECT DECODE(PAYMENT_PROFILE_ID,  167, 'Pay Advice',  169, 'Cash',  CK.CHECK_NUMBER)
              FROM AP_CHECKS_ALL CK, AP_INVOICE_PAYMENTS_ALL PM
             WHERE     PM.INVOICE_ID = P_INVOICE_ID
                   AND CK.CHECK_ID = PM.CHECK_ID
                   AND NVL(PM.REVERSAL_FLAG, 'IBCS') <> 'Y';
    BEGIN
        OPEN CHECK_NUMBER_CUR;

        LOOP
            FETCH CHECK_NUMBER_CUR INTO V_CHECK_NUMBER;

            EXIT WHEN CHECK_NUMBER_CUR%NOTFOUND;

            IF (V_CHECK_NUMBER_LIST IS NOT NULL)
            THEN
                V_CHECK_NUMBER_LIST := V_CHECK_NUMBER_LIST || ', ';
            END IF;

            V_CHECK_NUMBER_LIST := V_CHECK_NUMBER_LIST || V_CHECK_NUMBER;
        END LOOP;

        CLOSE CHECK_NUMBER_CUR;

        RETURN (V_CHECK_NUMBER_LIST);
    END GET_CHECK_CASH_FROM_INV;

    FUNCTION GET_PERIOD_FROM_DATE(P_DATE DATE)
        RETURN VARCHAR2
    IS
        V_PERIOD   VARCHAR2(10);
    BEGIN
        SELECT PERIOD_NAME
          INTO V_PERIOD
          FROM GL_PERIOD_STATUSES_V
         WHERE     TO_DATE(P_DATE) BETWEEN START_DATE AND END_DATE
               AND LEDGER_ID = 2021
               AND APPLICATION_ID = 101;

        RETURN V_PERIOD;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;

    FUNCTION DIST_LINE_AMOUNT_PAID(P_INVOICE_DISTRIBUTION_ID IN NUMBER)
        RETURN NUMBER
    IS
        V_RESULT   NUMBER;

        CURSOR P_CURSOR IS
            SELECT ROUND((DIST_AMOUNT * PAY_AMOUNT) / SUM_AMOUNT, 2)     DIST_PCT
              FROM (SELECT AI.INVOICE_ID,
                           AD.INVOICE_DISTRIBUTION_ID,
                           NVL(AD.BASE_AMOUNT, AD.AMOUNT)     DIST_AMOUNT
                      FROM AP_INVOICES_ALL AI, AP_INVOICE_DISTRIBUTIONS_ALL AD
                     WHERE     AI.INVOICE_ID = AD.INVOICE_ID
                           AND NVL(AD.REVERSAL_FLAG, 'N') <> 'Y'
                           AND NVL(AD.BASE_AMOUNT, AD.AMOUNT) <> 0) AID,
                   (  SELECT AI.INVOICE_ID, SUM(NVL(AD.BASE_AMOUNT, AD.AMOUNT)) SUM_AMOUNT
                        FROM AP_INVOICES_ALL AI, AP_INVOICE_DISTRIBUTIONS_ALL AD
                       WHERE     AI.INVOICE_ID = AD.INVOICE_ID
                             AND NVL(AD.REVERSAL_FLAG, 'N') <> 'Y'
                             AND NVL(AD.BASE_AMOUNT, AD.AMOUNT) <> 0
                    GROUP BY AI.INVOICE_ID) AIS,
                   (SELECT AI.INVOICE_ID,
                           NVL(PM.INVOICE_BASE_AMOUNT, PM.AMOUNT) + NVL(PM.DISCOUNT_TAKEN, 0)    PAY_AMOUNT
                      FROM AP_INVOICES_ALL AI, AP_INVOICE_PAYMENTS_ALL PM, AP_CHECKS_ALL CK
                     WHERE     AI.INVOICE_ID = PM.INVOICE_ID
                           AND PM.CHECK_ID = CK.CHECK_ID
                           AND NVL(PM.REVERSAL_FLAG, 'N') <> 'Y') AIM
             WHERE     AID.INVOICE_ID = AIS.INVOICE_ID
                   AND AID.INVOICE_ID = AIM.INVOICE_ID
                   AND AID.INVOICE_DISTRIBUTION_ID = P_INVOICE_DISTRIBUTION_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN V_RESULT;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;
	
	

    PROCEDURE CREATE_SUPPLIER_FROM_EMP(ERRBUF         OUT NOCOPY VARCHAR2,
                                       RETCODE        OUT NOCOPY VARCHAR2,
                                       P_PERSON_ID    IN         NUMBER,
                                       P_ORG_ID       IN         NUMBER)
    IS
        V_VENDOR_ID         NUMBER(15);
        V_PARTY_ID          NUMBER(15);
        V_RETURN_STATUS     VARCHAR2(1);
        V_MSG_COUNT         NUMBER(15);
        V_CUR_MSG_COUNT     NUMBER(15);
        V_MSG_DATA          VARCHAR2(4000);
        V_VENDOR_REC        AP_VENDOR_PUB_PKG.R_VENDOR_REC_TYPE;

        V_VENDOR_SITE_ID    NUMBER(15);
        V_PARTY_SITE_ID     NUMBER(15);
        V_LOCATION_ID       NUMBER;
        V_ACCTS_PAY_CODE    NUMBER := 22019901;
        V_PREPAY_CODE       NUMBER := 12030302;
        V_VENDOR_SITE_REC   AP_VENDOR_PUB_PKG.R_VENDOR_SITE_REC_TYPE;

        CURSOR VENDOR_CUR IS
            SELECT PERSON_ID               EMPLOYEE_ID,
                   TRIM(EMPLOYEE_NAME)     VENDOR_NAME,
                   'EMPLOYEE'              VENDOR_TYPE_LOOKUP_CODE
              FROM XX_EMPLOYEE_INFO_V
             WHERE PERSON_ID = P_PERSON_ID;

        CURSOR VENDOR_SITE_CUR IS
              SELECT DISTINCT POV.VENDOR_ID,
                              POV.VENDOR_NAME,
                              'OFFICE'     VENDOR_SITE_CODE,
                              OCB.ORG_ID,
                              OCB.ORG_NAME,
                              OCB.COMPANY_CODE,
                              OCB.BRANCH_CODE
                FROM PO_VENDORS POV, XX_EMPLOYEE_INFO_V EMP, XX_ORG_COMPANY_BRANCH_V OCB
               WHERE     POV.EMPLOYEE_ID = EMP.PERSON_ID
                     AND POV.VENDOR_TYPE_LOOKUP_CODE = 'EMPLOYEE'
                     AND EMP.PERSON_ID = P_PERSON_ID
                     AND OCB.ORG_ID = P_ORG_ID
            ORDER BY OCB.ORG_ID;
    BEGIN
        FOR VENDOR_REC IN VENDOR_CUR
        LOOP
            FND_FILE.PUT_LINE(FND_FILE.LOG, '=======================');
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Supplier Creation Process Started...');
            FND_FILE.PUT_LINE(FND_FILE.LOG, '=======================');

            V_VENDOR_REC.EMPLOYEE_ID := VENDOR_REC.EMPLOYEE_ID;
            V_VENDOR_REC.VENDOR_NAME := VENDOR_REC.VENDOR_NAME;
            V_VENDOR_REC.VENDOR_TYPE_LOOKUP_CODE := VENDOR_REC.VENDOR_TYPE_LOOKUP_CODE;

            AP_VENDOR_PUB_PKG.CREATE_VENDOR(P_API_VERSION     => 1.0,
                                            P_VENDOR_REC      => V_VENDOR_REC,
                                            X_VENDOR_ID       => V_VENDOR_ID,
                                            X_PARTY_ID        => V_PARTY_ID,
                                            X_RETURN_STATUS   => V_RETURN_STATUS,
                                            X_MSG_COUNT       => V_MSG_COUNT,
                                            X_MSG_DATA        => V_MSG_DATA);

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Employee Name : ' || VENDOR_REC.VENDOR_NAME);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Status : ' || (CASE WHEN V_RETURN_STATUS = 'S' THEN 'Success' ELSE 'Error' END));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Massage Count : ' || V_MSG_COUNT);

            IF (V_RETURN_STATUS <> FND_API.G_RET_STS_SUCCESS)
            THEN
                FOR I IN 1 .. FND_MSG_PUB.COUNT_MSG
                LOOP
                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Massage Data  : ' || (SUBSTR(FND_MSG_PUB.GET(P_ENCODED => FND_API.G_FALSE), 1, 4000)));
                END LOOP;
            END IF;

            V_CUR_MSG_COUNT := V_MSG_COUNT;

            FND_FILE.PUT_LINE(FND_FILE.LOG, '===========================');

            FOR VENDOR_SITE_REC IN VENDOR_SITE_CUR
            LOOP
                FND_CLIENT_INFO.SET_ORG_CONTEXT (VENDOR_SITE_REC.ORG_ID);

                V_VENDOR_SITE_REC.VENDOR_ID := VENDOR_SITE_REC.VENDOR_ID;
                V_VENDOR_SITE_REC.VENDOR_SITE_CODE := VENDOR_SITE_REC.VENDOR_SITE_CODE;
                V_VENDOR_SITE_REC.ORG_ID := VENDOR_SITE_REC.ORG_ID;
                V_VENDOR_SITE_REC.ACCTS_PAY_CODE_COMBINATION_ID :=
                    XX_GL_PKG.CREATE_GET_GL_CCID(
                           VENDOR_SITE_REC.COMPANY_CODE
                        || '.'
                        || VENDOR_SITE_REC.BRANCH_CODE
                        || '.999.'
                        || V_ACCTS_PAY_CODE
                        || '.99.999.999');
                V_VENDOR_SITE_REC.PREPAY_CODE_COMBINATION_ID :=
                    XX_GL_PKG.CREATE_GET_GL_CCID(
                           VENDOR_SITE_REC.COMPANY_CODE
                        || '.'
                        || VENDOR_SITE_REC.BRANCH_CODE
                        || '.999.'
                        || V_PREPAY_CODE
                        || '.99.999.999');
                V_VENDOR_SITE_REC.PAY_SITE_FLAG := 'Y';
                V_VENDOR_SITE_REC.INVOICE_CURRENCY_CODE := 'BDT';
                V_VENDOR_SITE_REC.PAYMENT_CURRENCY_CODE := 'BDT';

                AP_VENDOR_PUB_PKG.CREATE_VENDOR_SITE(P_API_VERSION       => 1.0,
                                                     P_VENDOR_SITE_REC   => V_VENDOR_SITE_REC,
                                                     X_VENDOR_SITE_ID    => V_VENDOR_SITE_ID,
                                                     X_PARTY_SITE_ID     => V_PARTY_SITE_ID,
                                                     X_LOCATION_ID       => V_LOCATION_ID,
                                                     X_RETURN_STATUS     => V_RETURN_STATUS,
                                                     X_MSG_COUNT         => V_MSG_COUNT,
                                                     X_MSG_DATA          => V_MSG_DATA);

                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Operating Unit: ' || VENDOR_SITE_REC.ORG_NAME);
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Status : ' || (CASE WHEN V_RETURN_STATUS = 'S' THEN 'Success' ELSE 'Error' END));
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Massage Count : ' || (V_MSG_COUNT - V_CUR_MSG_COUNT));

                IF (V_RETURN_STATUS <> FND_API.G_RET_STS_SUCCESS)
                THEN
                    FOR I IN V_CUR_MSG_COUNT + 1 .. FND_MSG_PUB.COUNT_MSG
                    LOOP
                        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Massage Data  : ' || (SUBSTR(FND_MSG_PUB.GET(P_ENCODED => FND_API.G_FALSE), 1, 4000)));
                    END LOOP;
                END IF;

                V_CUR_MSG_COUNT := V_MSG_COUNT;
                FND_FILE.PUT_LINE(FND_FILE.LOG, '========================');
            END LOOP;
        END LOOP;

        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Supplier Creation Process Ended...');
        FND_FILE.PUT_LINE(FND_FILE.LOG, '===========================');

        UPDATE AP_SUPPLIERS UPD
           SET UPD.VENDOR_NAME =
                   (SELECT BST.EMPLOYEE_NUMBER || ' - ' || TRIM(EMPLOYEE_NAME)
                      FROM XX_EMPLOYEE_INFO_V BST
                     WHERE UPD.EMPLOYEE_ID = BST.PERSON_ID)
         WHERE UPD.EMPLOYEE_ID = P_PERSON_ID;


        UPDATE AP_SUPPLIER_SITES_ALL
           SET TERMS_ID = 10000
         WHERE     VENDOR_ID = (SELECT VENDOR_ID
                                  FROM AP_SUPPLIERS
                                 WHERE EMPLOYEE_ID = P_PERSON_ID)
               AND ORG_ID = P_ORG_ID;

        COMMIT;
    END CREATE_SUPPLIER_FROM_EMP;



    PROCEDURE INSERT_INFO_AP_DB (P_DATE_FROM IN DATE, P_DATE_TO IN DATE, P_TYPE IN VARCHAR2)
    AS
    BEGIN
        DELETE FROM XX_AP_EXPENSE_DASHBOARD_GT
              WHERE 1 = 1;

        -- Details
        IF P_TYPE = 'ALL'
        THEN
            INSERT INTO XX_AP_EXPENSE_DASHBOARD_GT (COMPANY,
                                                   BRANCH,
                                                   ACCOUNT,
                                                   ACC_DESCRIPTION,
                                                   TODAY_AMOUNT)
                  SELECT COMPANY,
                         BRANCH,
                         ACCOUNT,
                         ACC_DESCRIPTION,
                         SUM(PAID_AMOUNT)
                    FROM XX_AP_EXPENSE_DASHBOARD_V
                   WHERE PAY_DATE BETWEEN P_DATE_FROM AND P_DATE_TO
                GROUP BY COMPANY,
                         BRANCH,
                         ACCOUNT,
                         ACC_DESCRIPTION;
        -- Top 20
        ELSIF P_TYPE = 'TP20'
        THEN
            INSERT INTO XX_AP_EXPENSE_DASHBOARD_GT (YESTERDAY_AMOUNT,
                                                   COMPANY,
                                                   BRANCH,
                                                   TODAY_AMOUNT)
                SELECT ROWNUM,
                       COMPANY,
                       BRANCH,
                       PAID_AMOUNT
                  FROM (  SELECT COMPANY, BRANCH, SUM(PAID_AMOUNT) PAID_AMOUNT
                            FROM XX_AP_EXPENSE_DASHBOARD_V
                           WHERE PAY_DATE BETWEEN P_DATE_FROM AND P_DATE_TO
                        GROUP BY COMPANY, BRANCH
                        ORDER BY 3 DESC)
                 WHERE ROWNUM <= 20;
        -- Bottom 20
        ELSIF P_TYPE = 'BT20'
        THEN
            INSERT INTO XX_AP_EXPENSE_DASHBOARD_GT (YESTERDAY_AMOUNT,
                                                   COMPANY,
                                                   BRANCH,
                                                   TODAY_AMOUNT)
                SELECT ROWNUM,
                       COMPANY,
                       BRANCH,
                       PAID_AMOUNT
                  FROM (  SELECT COMPANY, BRANCH, SUM(PAID_AMOUNT) PAID_AMOUNT
                            FROM XX_AP_EXPENSE_DASHBOARD_V
                           WHERE PAY_DATE BETWEEN P_DATE_FROM AND P_DATE_TO
                        GROUP BY COMPANY, BRANCH
                        ORDER BY 3)
                 WHERE ROWNUM <= 20;
        ELSE
            NULL;
        END IF;
    END INSERT_INFO_AP_DB;
	
END XX_AP_PKG;
/
S