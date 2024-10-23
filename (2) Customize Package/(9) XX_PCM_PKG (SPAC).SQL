
CREATE OR REPLACE PACKAGE APPS.XX_PCM_PKG
AS
    PROCEDURE IMPORT_CUSTOMER_FROM_PCM (P_UNIT_NAME IN VARCHAR2, P_PROCESS_MODE IN VARCHAR2);

    PROCEDURE PCM_INVOICE_UPLOAD (P_COLLECTION_TYPE   IN VARCHAR2,
                                  P_CUSTOMER_TYPE     IN VARCHAR2,
                                  P_DATE_FROM         IN DATE,
                                  P_DATE_TO           IN DATE,
                                  P_PROCESS_MODE      IN VARCHAR2);

    PROCEDURE PCM_CREDIT_MEMO_UPLOAD (P_COLLECTION_TYPE   IN VARCHAR2,
                                      P_CUSTOMER_TYPE     IN VARCHAR2,
                                      P_DATE_FROM         IN DATE,
                                      P_DATE_TO           IN DATE,
                                      P_PROCESS_MODE      IN VARCHAR2);

    PROCEDURE PCM_COLLECTION_UPLOAD (P_COLLECTION_TYPE   IN VARCHAR2,
                                     P_CUSTOMER_TYPE     IN VARCHAR2,
                                     P_DATE_FROM         IN DATE,
                                     P_DATE_TO           IN DATE,
                                     P_PROCESS_MODE      IN VARCHAR2);

    PROCEDURE GRANT_CREDIT_CUSTOMER_ACCESS (ERRBUF OUT NOCOPY VARCHAR2, RETCODE OUT NOCOPY VARCHAR2, P_CUSTOMER_ID IN VARCHAR2);
END;
/

