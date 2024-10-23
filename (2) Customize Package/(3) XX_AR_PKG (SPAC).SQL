
CREATE OR REPLACE PACKAGE APPS.XX_AR_PKG
AS
    FUNCTION GL_ID_REC (P_CUST_ACCT_SITE_ID NUMBER)
        RETURN NUMBER;

    FUNCTION GL_ID_REV (P_CUST_ACCT_SITE_ID NUMBER)
        RETURN NUMBER;

    FUNCTION GET_CUSTOMER_NAME_FROM_NUMBER (P_CUSTOMER_NUMBER VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION GET_CUSTOMER_NUMBER_FROM_ID (P_CUSTOMER_ID NUMBER)
        RETURN VARCHAR2;

    FUNCTION GET_CUSTOMER_NAME_FROM_ID (P_CUSTOMER_ID NUMBER)
        RETURN VARCHAR2;

    PROCEDURE CASH_CREATE_AND_APPLY (P_ORG_ID          IN NUMBER,
                                     P_DEPARTMENT_ID   IN NUMBER,
                                     P_DATE_FROM       IN DATE,
                                     P_DATE_TO         IN DATE,
                                     P_PROCESS_MODE    IN VARCHAR2);


    PROCEDURE WRITELOG (P_TEXT VARCHAR2);

    PROCEDURE AR_TRANSACTION_APPLY (P_ORG_ID            NUMBER,
                                    P_CASH_RECEIPT_ID   NUMBER,
                                    P_RECEIPT_NUMBER    VARCHAR2,
                                    P_VOUCHER_NUMBER    VARCHAR2,
                                    P_CUSTOMER_TRX_ID   NUMBER,
                                    P_TRX_NUMBER        VARCHAR2,
                                    P_APPLY_AMOUNT      NUMBER,
                                    P_DISCOUNT_AMOUNT   NUMBER,
                                    P_APPLY_DATE        DATE,
                                    P_APPLY_GL_DATE     DATE);

    PROCEDURE RECEIPT_APPLY (ERRBUFF         OUT VARCHAR2,
                             RETCODE         OUT VARCHAR2,
                             P_ORG_ID            NUMBER,
                             P_CUSTOMER_ID       NUMBER,
                             P_DATE_TO           VARCHAR2);


    PROCEDURE CM_AND_RECEIPT_APPLY (ERRBUFF         OUT VARCHAR2,
                                    RETCODE         OUT VARCHAR2,
                                    P_ORG_ID            NUMBER,
                                    P_CUSTOMER_ID       NUMBER,
                                    P_DATE_TO           VARCHAR2,
                                    P_TRX_TYPE          VARCHAR2);

    FUNCTION GET_BRANCH_FROM_AGENCY (P_AGENCY_CODE IN VARCHAR2, P_DATE IN DATE)
        RETURN VARCHAR2;

    FUNCTION IS_BRANCH (P_UNIT VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION IS_AGENCY (P_UNIT VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION GET_ORG_ID_FROM_PCM_UNIT (P_UNIT_CODE VARCHAR2, P_COMPANY_ID NUMBER)
        RETURN NUMBER;

    PROCEDURE UPLOAD_NEW_AGENCY (ERRBUF             OUT NOCOPY VARCHAR2,
                                 RETCODE            OUT NOCOPY VARCHAR2,
                                 P_AGENCY_CODE   IN            VARCHAR2,
                                 P_DEPT_CODE     IN            NUMBER);

    PROCEDURE UPDATE_AGENCY_ASSIGNMENT (ERRBUF             OUT NOCOPY VARCHAR2,
                                        RETCODE            OUT NOCOPY VARCHAR2,
                                        P_AGENCY_CODE   IN            VARCHAR2,
                                        P_BRANCH_CODE   IN            VARCHAR2);

    PROCEDURE CREATE_CUSTOMER_ACCOUNT_SITE (ERRBUF             OUT NOCOPY VARCHAR2,
                                            RETCODE            OUT NOCOPY VARCHAR2,
                                            P_CUSTOMER_ID   IN            VARCHAR2,
                                            P_ORG_ID        IN            NUMBER);

    PROCEDURE INSERT_INFO_AR_DB (P_DATE_FROM IN DATE, P_DATE_TO IN DATE, P_TYPE IN VARCHAR2);

    PROCEDURE CUSTOMER_LEDGER_DETAILS (P_ORG_ID        IN NUMBER,
                                       P_CUSTOMER_ID   IN NUMBER,
                                       P_DATE_FROM     IN DATE,
                                       P_DATE_TO       IN DATE);
END;
/

