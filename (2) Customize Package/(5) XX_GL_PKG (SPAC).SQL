
CREATE OR REPLACE PACKAGE APPS.XX_GL_PKG
AS
    FUNCTION GET_LEDGER_NAME (P_LEDGER_ID NUMBER)
        RETURN VARCHAR2;

    FUNCTION CREATE_GET_GL_CCID (P_CONCAT_SEGMENTS VARCHAR2)
        RETURN NUMBER;

    FUNCTION GET_ACCT_FLEX_SEGMENT_DESC (P_SEQUENCE IN NUMBER, P_FLEX_CODE IN VARCHAR2)
        RETURN VARCHAR2;

    PROCEDURE CLEAN_GL_INTERFACE (ERRBUF         OUT NOCOPY VARCHAR2,
                                  RETCODE        OUT NOCOPY NUMBER,
                                  P_USER_ID                 NUMBER,
                                  P_RESP_ID                 NUMBER);

    FUNCTION GET_CCID_FROM_CONCAT_SEGMENTS (P_CONCAT_SEGMENTS VARCHAR2)
        RETURN NUMBER;

    FUNCTION GET_GL_BALANCE (P_ACTIVITY        IN VARCHAR2,
                             P_LEDGER_ID       IN NUMBER,
                             P_CURRENCY_CODE   IN VARCHAR2,
                             P_PERIOD_FROM     IN NUMBER,
                             P_PERIOD_TO       IN NUMBER,
                             P_COMPANY         IN VARCHAR2,
                             P_ACCOUNT_FROM    IN VARCHAR2,
                             P_ACCOUNT_TO      IN VARCHAR2)
        RETURN NUMBER;

    PROCEDURE INSERT_INFO_TB (P_LEDGER_ID       IN NUMBER,
                              P_COMPANY         IN NUMBER,
                              P_CURRENCY_CODE   IN VARCHAR2,
                              P_PERIOD_FROM     IN NUMBER,
                              P_PERIOD_TO       IN NUMBER,
                              P_PROCESS_MODE    IN VARCHAR2);

    PROCEDURE INSERT_INFO_BS (P_LEDGER_ID         IN NUMBER,
                              P_COMPANY           IN NUMBER,
                              P_CURRENCY_CODE     IN VARCHAR2,
                              P_CURRENT_PERIOD    IN NUMBER,
                              P_PREVIOUS_PERIOD   IN NUMBER,
                              P_PROCESS_MODE      IN VARCHAR2);

    PROCEDURE INSERT_INFO_BSN (P_LEDGER_ID         IN NUMBER,
                               P_COMPANY           IN NUMBER,
                               P_CURRENCY_CODE     IN VARCHAR2,
                               P_CURRENT_PERIOD    IN NUMBER,
                               P_PREVIOUS_PERIOD   IN NUMBER,
                               P_PROCESS_MODE      IN VARCHAR2);

    PROCEDURE INSERT_INFO_IS (P_LEDGER_ID              IN NUMBER,
                              P_COMPANY                IN NUMBER,
                              P_BRANCH                 IN VARCHAR2,
                              P_SUB_BRANCH             IN VARCHAR2,
                              P_CURRENCY_CODE          IN VARCHAR2,
                              P_CURRENT_PERIOD_FROM    IN NUMBER,
                              P_CURRENT_PERIOD_TO      IN NUMBER,
                              P_PREVIOUS_PERIOD_FROM   IN NUMBER,
                              P_PREVIOUS_PERIOD_TO     IN NUMBER,
                              P_PROCESS_MODE           IN VARCHAR2);

    PROCEDURE INSERT_INFO_ISN (P_LEDGER_ID              IN NUMBER,
                               P_COMPANY                IN NUMBER,
                               P_BRANCH                 IN VARCHAR2,
                               P_SUB_BRANCH             IN VARCHAR2,
                               P_CURRENCY_CODE          IN VARCHAR2,
                               P_CURRENT_PERIOD_FROM    IN NUMBER,
                               P_CURRENT_PERIOD_TO      IN NUMBER,
                               P_PREVIOUS_PERIOD_FROM   IN NUMBER,
                               P_PREVIOUS_PERIOD_TO     IN NUMBER,
                               P_PROCESS_MODE           IN VARCHAR2);
END;
/

