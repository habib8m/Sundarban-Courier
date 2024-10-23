
CREATE OR REPLACE PACKAGE BODY APPS.XX_PCM_PKG
AS
    PROCEDURE IMPORT_CUSTOMER_FROM_PCM (P_UNIT_NAME IN VARCHAR2, P_PROCESS_MODE IN VARCHAR2)
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
        INSERT INTO XX_PCM_PARTY_DETAILS_BKP (UNIT_NAME,
                                              CUSTOMER_ID,
                                              CUSTOMER_NAME,
                                              CUSTOMER_TYPE,
                                              ADDRESS1,
                                              ADDRESS2,
                                              ADDRESS3,
                                              ADDRESS4,
                                              CITY,
                                              POSTAL_CODE,
                                              COUNTRY,
                                              PROCESS_FLAG,
                                              PROCESS_DATE,
                                              REQUEST_ID,
                                              CREATED_BY,
                                              CREATION_DATE,
                                              LAST_UPDATED_BY,
                                              LAST_UPDATE_DATE,
                                              LAST_UPDATE_LOGIN)
            SELECT UNIT_NAME,
                   CUSTOMER_ID,
                   CUSTOMER_NAME,
                   CUSTOMER_TYPE,
                   ADDRESS1,
                   ADDRESS2,
                   ADDRESS3,
                   ADDRESS4,
                   CITY,
                   POSTAL_CODE,
                   COUNTRY,
                   PROCESS_FLAG,
                   PROCESS_DATE,
                   REQUEST_ID,
                   CREATED_BY,
                   CREATION_DATE,
                   LAST_UPDATED_BY,
                   LAST_UPDATE_DATE,
                   LAST_UPDATE_LOGIN
              FROM XX_PCM_PARTY_DETAILS
             WHERE PROCESS_FLAG = 'N' AND NVL (PROCESS_FLAG, 'N') <> 'Y';

        --Delete Draft data from custom Party table
        DELETE FROM XX_PCM_PARTY_DETAILS
              WHERE PROCESS_FLAG = 'N' AND NVL (PROCESS_FLAG, 'N') <> 'Y';

        COMMIT;

        --Populate Party Data
        INSERT INTO XX_PCM_PARTY_DETAILS (UNIT_NAME,
                                          CUSTOMER_ID,
                                          CUSTOMER_NAME,
                                          CUSTOMER_TYPE,
                                          ADDRESS1,
                                          ADDRESS2,
                                          ADDRESS3,
                                          ADDRESS4,
                                          CITY,
                                          POSTAL_CODE,
                                          COUNTRY,
                                          PROCESS_FLAG,
                                          PROCESS_DATE,
                                          REQUEST_ID,
                                          CREATED_BY,
                                          CREATION_DATE,
                                          LAST_UPDATED_BY,
                                          LAST_UPDATE_DATE,
                                          LAST_UPDATE_LOGIN)
            SELECT UPPER (XPC.UNIT_NAME),
                   UPPER (XPC.CUSTOMER_ID),
                   XPC.CUSTOMER_NAME,
                   XPC.CUSTOMER_TYPE,
                   NVL (XPC.ADDRESS1, UPPER (XPC.UNIT_NAME)),
                   XPC.ADDRESS2,
                   XPC.ADDRESS3,
                   XPC.ADDRESS4,
                   XPC.CITY,
                   XPC.POSTAL_CODE,
                   'BD',
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
              FROM XX_PCM_CUSTOMERS XPC
             WHERE                                                       -- CUSTOMER_TYPE = 'Credit'
                       NOT EXISTS
                           (SELECT 1
                              FROM HZ_CUST_ACCOUNTS HCA
                             WHERE UPPER (XPC.CUSTOMER_ID) = UPPER (HCA.ACCOUNT_NUMBER))
                   AND (UPPER (XPC.UNIT_NAME) = UPPER (P_UNIT_NAME) OR UPPER (P_UNIT_NAME) = 'ALL');

        COMMIT;

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
                  SELECT PPD.ROWID             ROW_ID,
                         PPD.UNIT_NAME,
                         PPD.CUSTOMER_NAME     ORGANIZATION_NAME,
                         PPD.CUSTOMER_ID       ACCOUNT_NUMBER,
                         FFV.DESCRIPTION       ACCOUNT_NAME
                    FROM XX_PCM_PARTY_DETAILS PPD, FND_FLEX_VALUES_VL FFV
                   WHERE     SUBSTR (PPD.CUSTOMER_ID, 1, 2) = SUBSTR (FFV.FLEX_VALUE, 2, 2)
                         AND FFV.FLEX_VALUE_SET_ID = 1016493
                         AND FFV.FLEX_VALUE < 300
                         AND PPD.PARTY_ID IS NULL
                         AND PPD.PROCESS_FLAG = 'Y'
                         AND P_PROCESS_MODE = 'F'
                ORDER BY PPD.UNIT_NAME, PPD.CUSTOMER_ID;
        BEGIN
            FOR REC IN CUR
            LOOP
                P_ORGANIZATION_REC.ORGANIZATION_NAME := REC.ORGANIZATION_NAME;
                P_ORGANIZATION_REC.CREATED_BY_MODULE := P_CREATED_BY_MODULE;

                P_CUST_ACCOUNT_REC.ACCOUNT_NUMBER := REC.ACCOUNT_NUMBER;
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
                     VALUES ('HZ_CUST_ACCOUNT_V2PUB.CREATE_CUST_ACCOUNT',
                             X_PARTY_ID,
                             X_PARTY_NUMBER,
                             X_RETURN_STATUS,
                             X_MSG_COUNT,
                             X_MSG_DATA,
                             L_REQUEST_ID,
                             L_USER_ID,
                             SYSDATE,
                             L_USER_ID,
                             SYSDATE,
                             L_LOGIN_ID);

                UPDATE XX_PCM_PARTY_DETAILS
                   SET PARTY_ID = X_PARTY_ID,
                       CUST_ACCOUNT_ID = X_CUST_ACCOUNT_ID,
                       ACCOUNT_NUMBER = X_ACCOUNT_NUMBER
                 WHERE ROWID = REC.ROW_ID AND PROCESS_FLAG = 'Y' AND P_PROCESS_MODE = 'F';
            END LOOP;
        END;

        -- 3. Create A Physical Location
        --    HZ_LOCATIONS

        DECLARE
            P_LOCATION_REC        HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
            P_CREATED_BY_MODULE   VARCHAR2 (16) := 'XX_CUSTOM_API';
            X_LOCATION_ID         NUMBER;
            X_RETURN_STATUS       VARCHAR2 (2000);
            X_MSG_COUNT           NUMBER;
            X_MSG_DATA            VARCHAR2 (2000);

            CURSOR CUR IS
                  SELECT PPD.ROWID     ROW_ID,
                         PPD.ADDRESS1,
                         PPD.ADDRESS2,
                         PPD.ADDRESS3,
                         PPD.ADDRESS4,
                         PPD.CITY,
                         PPD.POSTAL_CODE,
                         PPD.COUNTRY
                    FROM XX_PCM_PARTY_DETAILS PPD
                   WHERE PPD.LOCATION_ID IS NULL AND PPD.PROCESS_FLAG = 'Y' AND P_PROCESS_MODE = 'F'
                ORDER BY PPD.ADDRESS1;
        BEGIN
            FOR REC IN CUR
            LOOP
                P_LOCATION_REC.ADDRESS1 := REC.ADDRESS1;
                P_LOCATION_REC.ADDRESS2 := REC.ADDRESS2;
                P_LOCATION_REC.ADDRESS3 := REC.ADDRESS3;
                P_LOCATION_REC.ADDRESS4 := REC.ADDRESS4;
                P_LOCATION_REC.CITY := REC.CITY;
                P_LOCATION_REC.POSTAL_CODE := REC.POSTAL_CODE;
                P_LOCATION_REC.COUNTRY := REC.COUNTRY;
                P_LOCATION_REC.CREATED_BY_MODULE := P_CREATED_BY_MODULE;

                HZ_LOCATION_V2PUB.CREATE_LOCATION (P_INIT_MSG_LIST   => FND_API.G_TRUE,
                                                   P_LOCATION_REC    => P_LOCATION_REC,
                                                   X_LOCATION_ID     => X_LOCATION_ID,
                                                   X_RETURN_STATUS   => X_RETURN_STATUS,
                                                   X_MSG_COUNT       => X_MSG_COUNT,
                                                   X_MSG_DATA        => X_MSG_DATA);

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
                     VALUES ('HZ_LOCATION_V2PUB.CREATE_LOCATION',
                             X_LOCATION_ID,
                             'None',
                             X_RETURN_STATUS,
                             X_MSG_COUNT,
                             X_MSG_DATA,
                             L_REQUEST_ID,
                             L_USER_ID,
                             SYSDATE,
                             L_USER_ID,
                             SYSDATE,
                             L_LOGIN_ID);

                UPDATE XX_PCM_PARTY_DETAILS
                   SET LOCATION_ID = X_LOCATION_ID
                 WHERE ROWID = REC.ROW_ID AND PROCESS_FLAG = 'Y' AND P_PROCESS_MODE = 'F';
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
                  SELECT PPD.ROWID          ROW_ID,
                         HZP.PARTY_NAME     ORGANIZATION_NAME,
                         HZP.PARTY_ID,
                         PPD.LOCATION_ID
                    FROM HZ_PARTIES HZP, HZ_CUST_ACCOUNTS HCA, XX_PCM_PARTY_DETAILS PPD
                   WHERE     HZP.PARTY_ID = HCA.PARTY_ID
                         AND HCA.PARTY_ID = PPD.PARTY_ID
                         AND HCA.ACCOUNT_NUMBER = PPD.CUSTOMER_ID
                         AND PPD.PARTY_SITE_ID IS NULL
                         AND PPD.PROCESS_FLAG = 'Y'
                         AND P_PROCESS_MODE = 'F'
                ORDER BY HZP.PARTY_ID;
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
                     VALUES ('HZ_PARTY_SITE_V2PUB.CREATE_PARTY_SITE',
                             X_PARTY_SITE_ID,
                             X_PARTY_SITE_NUMBER,
                             X_RETURN_STATUS,
                             X_MSG_COUNT,
                             X_MSG_DATA,
                             L_REQUEST_ID,
                             L_USER_ID,
                             SYSDATE,
                             L_USER_ID,
                             SYSDATE,
                             L_LOGIN_ID);

                UPDATE XX_PCM_PARTY_DETAILS
                   SET PARTY_SITE_ID = X_PARTY_SITE_ID
                 WHERE ROWID = REC.ROW_ID AND PROCESS_FLAG = 'Y' AND P_PROCESS_MODE = 'F';
            END LOOP;
        END;

        -- 5. Create An Account Site
        --    HZ_CUST_ACCT_SITES_ALL

        DECLARE
            P_CUST_ACCT_SITE_REC   HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
            P_CREATED_BY_MODULE    VARCHAR2 (16) := 'XX_CUSTOM_API';
            X_RETURN_STATUS        VARCHAR2 (2000);
            X_MSG_COUNT            NUMBER;
            X_MSG_DATA             VARCHAR2 (2000);
            X_CUST_ACCT_SITE_ID    NUMBER;

            CURSOR CUR IS
                SELECT PPD.ROWID                                                ROW_ID,
                       XX_COM_PKG.GET_ORG_ID_FROM_CUST_ID (PPD.CUSTOMER_ID)     ORG_ID,
                       PPD.PARTY_SITE_ID,
                       PPD.CUST_ACCOUNT_ID,
                       PPD.ACCOUNT_NUMBER
                  FROM XX_PCM_PARTY_DETAILS PPD
                 WHERE CUST_ACCT_SITE_ID IS NULL AND PROCESS_FLAG = 'Y' AND P_PROCESS_MODE = 'F';
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
                     VALUES ('HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_ACCT_SITE',
                             X_CUST_ACCT_SITE_ID,
                             'None',
                             X_RETURN_STATUS,
                             X_MSG_COUNT,
                             X_MSG_DATA,
                             L_REQUEST_ID,
                             L_USER_ID,
                             SYSDATE,
                             L_USER_ID,
                             SYSDATE,
                             L_LOGIN_ID);

                UPDATE XX_PCM_PARTY_DETAILS
                   SET CUST_ACCT_SITE_ID = X_CUST_ACCT_SITE_ID
                 WHERE ROWID = REC.ROW_ID AND PROCESS_FLAG = 'Y' AND P_PROCESS_MODE = 'F';
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
                ORDER BY CAS.CUST_ACCT_SITE_ID, HOU.ORGANIZATION_ID;
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
                     VALUES ('HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE',
                             X_SITE_USE_ID,
                             'None',
                             X_RETURN_STATUS,
                             X_MSG_COUNT,
                             X_MSG_DATA,
                             L_REQUEST_ID,
                             L_USER_ID,
                             SYSDATE,
                             L_USER_ID,
                             SYSDATE,
                             L_LOGIN_ID);
            END LOOP;
        END;

        UPDATE HZ_CUST_SITE_USES_ALL
           SET GL_ID_REC = XX_AR_PKG.GL_ID_REC (CUST_ACCT_SITE_ID)
         WHERE GL_ID_REC IS NULL;

        UPDATE HZ_CUST_SITE_USES_ALL
           SET GL_ID_REV = XX_AR_PKG.GL_ID_REV (CUST_ACCT_SITE_ID)
         WHERE GL_ID_REV IS NULL;

        COMMIT;
    END IMPORT_CUSTOMER_FROM_PCM;
	
	
--******************************************************************

    PROCEDURE PCM_INVOICE_UPLOAD (P_COLLECTION_TYPE   IN VARCHAR2,
                                  P_CUSTOMER_TYPE     IN VARCHAR2,
                                  P_DATE_FROM         IN DATE,
                                  P_DATE_TO           IN DATE,
                                  P_PROCESS_MODE      IN VARCHAR2)
    IS
        L_REQUEST_ID             PLS_INTEGER := FND_GLOBAL.CONC_REQUEST_ID;
        L_USER_ID                PLS_INTEGER := FND_GLOBAL.USER_ID;
        L_LOGIN_ID               PLS_INTEGER := FND_GLOBAL.CONC_LOGIN_ID;


        L_BATCH_SOURCE_REC       AR_INVOICE_API_PUB.BATCH_SOURCE_REC_TYPE;
        L_TRX_HEADER_TBL         AR_INVOICE_API_PUB.TRX_HEADER_TBL_TYPE;
        L_TRX_LINES_TBL          AR_INVOICE_API_PUB.TRX_LINE_TBL_TYPE;
        L_TRX_DIST_TBL           AR_INVOICE_API_PUB.TRX_DIST_TBL_TYPE;
        L_TRX_SALESCREDITS_TBL   AR_INVOICE_API_PUB.TRX_SALESCREDITS_TBL_TYPE;

        L_TRX_HEADER_ID          NUMBER;
        L_TRX_LINE_ID            NUMBER;
        L_TRX_DIST_ID            NUMBER;
        L_LINE_NUMBER            NUMBER;
        L_ROW_CNT                NUMBER;

        L_CUSTOMER_TRX_ID        NUMBER;
        L_RETURN_STATUS          VARCHAR2 (1);
        L_MSG_COUNT              NUMBER;
        L_MSG_DATA               VARCHAR2 (2000);



        CURSOR HEAD_CUR IS
              SELECT COLLECTION_TYPE,
                     CUSTOMER_TYPE,
                     ORG_ID,
                     GL_DATE,
                     BILL_TO_CUSTOMER_ID,
                     CUSTOMER_NAME,
                     DEPARTMENT,
                     ROUND (SUM (AMOUNT), 2)     AMOUNT
                FROM XX_PCM_TRANSACTIONS_GT
               WHERE     COLLECTION_TYPE = P_COLLECTION_TYPE
                     AND CUSTOMER_TYPE = P_CUSTOMER_TYPE
                     AND GL_DATE BETWEEN P_DATE_FROM AND P_DATE_TO
                     AND P_PROCESS_MODE = 'F'
            GROUP BY COLLECTION_TYPE,
                     CUSTOMER_TYPE,
                     ORG_ID,
                     GL_DATE,
                     BILL_TO_CUSTOMER_ID,
                     CUSTOMER_NAME,
                     DEPARTMENT
            ORDER BY ORG_ID,
                     GL_DATE,
                     BILL_TO_CUSTOMER_ID,
                     DEPARTMENT;

        CURSOR LINE_CUR (L_ORG_ID        IN NUMBER,
                         L_GL_DATE       IN DATE,
                         L_CUSTOMER_ID   IN NUMBER,
                         L_DEPARTMENT    IN VARCHAR2)
        IS
              SELECT ORG_ID,
                     GL_DATE,
                     BILL_TO_CUSTOMER_ID,
                     CUSTOMER_NAME,
                     DEPARTMENT,
                     PRODUCT,
                     INVENTORY_ITEM_ID,
                     CODE_COMBINATION_ID,
                     'PCM ' || COLLECTION_TYPE || ' Invoice-' || BOOKING_AGENCY     DESCRIPTION,
                     ROUND (SUM (AMOUNT), 2)   AMOUNT
                FROM XX_PCM_TRANSACTIONS_GT
               WHERE     COLLECTION_TYPE = P_COLLECTION_TYPE
                     AND CUSTOMER_TYPE = P_CUSTOMER_TYPE
                     AND GL_DATE BETWEEN P_DATE_FROM AND P_DATE_TO
                     AND P_PROCESS_MODE = 'F'
                     AND ORG_ID = L_ORG_ID
                     AND GL_DATE = L_GL_DATE
                     AND BILL_TO_CUSTOMER_ID = L_CUSTOMER_ID
                     AND DEPARTMENT = L_DEPARTMENT
            GROUP BY ORG_ID,
                     GL_DATE,
                     BILL_TO_CUSTOMER_ID,
                     CUSTOMER_NAME,
                     DEPARTMENT,
                     PRODUCT,
                     INVENTORY_ITEM_ID,
                     CODE_COMBINATION_ID,
                     COLLECTION_TYPE,
                     BOOKING_AGENCY
            ORDER BY ORG_ID,
                     GL_DATE,
                     BILL_TO_CUSTOMER_ID,
                     DEPARTMENT,
                     PRODUCT;
    BEGIN
        FND_GLOBAL.APPS_INITIALIZE (USER_ID        => FND_GLOBAL.USER_ID,
                                    RESP_ID        => FND_GLOBAL.RESP_ID,
                                    RESP_APPL_ID   => FND_GLOBAL.RESP_APPL_ID);
        MO_GLOBAL.INIT ('AR');

        L_TRX_HEADER_ID := 10000;
        L_TRX_LINE_ID := 10000;
        L_TRX_DIST_ID := 10000;

        -- SELECT MAX(CUSTOMER_TRX_ID) INTO L_TRX_HEADER_ID FROM RA_CUSTOMER_TRX_ALL;

        -- SELECT MAX(CUSTOMER_TRX_LINE_ID) INTO L_TRX_LINE_ID FROM RA_CUSTOMER_TRX_LINES_ALL;

        --   SELECT MAX(CUST_TRX_LINE_GL_DIST_ID) INTO L_TRX_DIST_ID FROM RA_CUST_TRX_LINE_GL_DIST_ALL;



        FOR HEAD_REC IN HEAD_CUR
        LOOP
            MO_GLOBAL.SET_POLICY_CONTEXT ('S', HEAD_REC.ORG_ID);

            L_TRX_HEADER_ID := L_TRX_HEADER_ID + 1;
            L_LINE_NUMBER := 1;
            L_ROW_CNT := 1;

            IF P_PROCESS_MODE = 'F'
            THEN
                INSERT INTO XX_PCM_CUSTOMER_TRX (CUSTOMER_TRX_ID,
                                                 COLLECTION_TYPE,
                                                 CUSTOMER_TYPE,
                                                 ORG_ID,
                                                 GL_DATE,
                                                 BILL_TO_CUSTOMER_ID,
                                                 CUSTOMER_NAME,
                                                 DEPARTMENT,
                                                 AMOUNT,
                                                 REQUEST_ID,
                                                 CREATED_BY,
                                                 CREATION_DATE,
                                                 LAST_UPDATE_LOGIN)
                     VALUES (L_TRX_HEADER_ID,
                             HEAD_REC.COLLECTION_TYPE,
                             HEAD_REC.CUSTOMER_TYPE,
                             HEAD_REC.ORG_ID,
                             HEAD_REC.GL_DATE,
                             HEAD_REC.BILL_TO_CUSTOMER_ID,
                             HEAD_REC.CUSTOMER_NAME,
                             HEAD_REC.DEPARTMENT,
                             HEAD_REC.AMOUNT,
                             L_REQUEST_ID,
                             L_USER_ID,
                             SYSDATE,
                             L_LOGIN_ID);



                -- Populate Batch
                L_BATCH_SOURCE_REC.BATCH_SOURCE_ID := -1;

                -- Populate Header
                L_TRX_HEADER_TBL (1).TRX_HEADER_ID := L_TRX_HEADER_ID;
                L_TRX_HEADER_TBL (1).TRX_NUMBER := NULL;
                L_TRX_HEADER_TBL (1).TRX_DATE := HEAD_REC.GL_DATE;
                L_TRX_HEADER_TBL (1).TRX_CURRENCY := 'BDT';
                L_TRX_HEADER_TBL (1).CUST_TRX_TYPE_ID := 1;
                L_TRX_HEADER_TBL (1).BILL_TO_CUSTOMER_ID := HEAD_REC.BILL_TO_CUSTOMER_ID;
                L_TRX_HEADER_TBL (1).TERM_ID := 5;
                L_TRX_HEADER_TBL (1).FINANCE_CHARGES := NULL;
                L_TRX_HEADER_TBL (1).PRINTING_OPTION := 'PRI';
                L_TRX_HEADER_TBL (1).STATUS_TRX := 'OP';

                FOR LINE_REC IN LINE_CUR (HEAD_REC.ORG_ID,
                                          HEAD_REC.GL_DATE,
                                          HEAD_REC.BILL_TO_CUSTOMER_ID,
                                          HEAD_REC.DEPARTMENT)
                LOOP
                    L_TRX_LINE_ID := L_TRX_LINE_ID + 1;
                    L_TRX_DIST_ID := L_TRX_DIST_ID + 1;

                    INSERT INTO XX_PCM_CUSTOMER_TRX_LINES (CUSTOMER_TRX_ID,
                                                           CUSTOMER_TRX_LINE_ID,
                                                           LINE_NUMBER,
                                                           ORG_ID,
                                                           GL_DATE,
                                                           BILL_TO_CUSTOMER_ID,
                                                           DEPARTMENT,
                                                           PRODUCT,
                                                           DESCRIPTION,
                                                           AMOUNT,
                                                           REQUEST_ID,
                                                           CREATED_BY,
                                                           CREATION_DATE,
                                                           LAST_UPDATE_LOGIN)
                         VALUES (L_TRX_HEADER_ID,
                                 L_TRX_LINE_ID,
                                 L_LINE_NUMBER,
                                 LINE_REC.ORG_ID,
                                 LINE_REC.GL_DATE,
                                 LINE_REC.BILL_TO_CUSTOMER_ID,
                                 LINE_REC.DEPARTMENT,
                                 LINE_REC.PRODUCT,
                                 LINE_REC.DESCRIPTION,
                                 LINE_REC.AMOUNT,
                                 L_REQUEST_ID,
                                 L_USER_ID,
                                 SYSDATE,
                                 L_LOGIN_ID);

                    -- Populate Line
                    L_TRX_LINES_TBL (L_ROW_CNT).TRX_HEADER_ID := L_TRX_HEADER_ID;
                    L_TRX_LINES_TBL (L_ROW_CNT).TRX_LINE_ID := L_TRX_LINE_ID;
                    L_TRX_LINES_TBL (L_ROW_CNT).LINE_TYPE := 'LINE';
                    L_TRX_LINES_TBL (L_ROW_CNT).LINE_NUMBER := L_LINE_NUMBER;
                    L_TRX_LINES_TBL (L_ROW_CNT).INVENTORY_ITEM_ID := LINE_REC.INVENTORY_ITEM_ID;
                    L_TRX_LINES_TBL (L_ROW_CNT).DESCRIPTION := LINE_REC.DESCRIPTION;
                    L_TRX_LINES_TBL (L_ROW_CNT).UOM_CODE := 'EA';
                    L_TRX_LINES_TBL (L_ROW_CNT).QUANTITY_INVOICED := 1;
                    L_TRX_LINES_TBL (L_ROW_CNT).UNIT_SELLING_PRICE := LINE_REC.AMOUNT;

                    -- Populate Distribution
                    L_TRX_DIST_TBL (L_ROW_CNT).TRX_HEADER_ID := L_TRX_HEADER_ID;
                    L_TRX_DIST_TBL (L_ROW_CNT).TRX_LINE_ID := L_TRX_LINE_ID;
                    L_TRX_DIST_TBL (L_ROW_CNT).TRX_DIST_ID := L_TRX_DIST_ID;
                    L_TRX_DIST_TBL (L_ROW_CNT).ACCOUNT_CLASS := 'REV';
                    L_TRX_DIST_TBL (L_ROW_CNT).PERCENT := 100;
                    L_TRX_DIST_TBL (L_ROW_CNT).CODE_COMBINATION_ID := LINE_REC.CODE_COMBINATION_ID;
                    L_ROW_CNT := L_ROW_CNT + 1;
                    L_LINE_NUMBER := L_LINE_NUMBER + 1;
                END LOOP;

                --Calling API
                AR_INVOICE_API_PUB.CREATE_SINGLE_INVOICE (
                    P_API_VERSION            => 1.0,
                    P_BATCH_SOURCE_REC       => L_BATCH_SOURCE_REC,
                    P_TRX_HEADER_TBL         => L_TRX_HEADER_TBL,
                    P_TRX_LINES_TBL          => L_TRX_LINES_TBL,
                    P_TRX_DIST_TBL           => L_TRX_DIST_TBL,
                    P_TRX_SALESCREDITS_TBL   => L_TRX_SALESCREDITS_TBL,
                    X_CUSTOMER_TRX_ID        => L_CUSTOMER_TRX_ID,
                    X_RETURN_STATUS          => L_RETURN_STATUS,
                    X_MSG_COUNT              => L_MSG_COUNT,
                    X_MSG_DATA               => L_MSG_DATA);

                UPDATE XX_PCM_CUSTOMER_TRX
                   SET CUSTOMER_TRX_ID = L_CUSTOMER_TRX_ID
                 WHERE CUSTOMER_TRX_ID = L_TRX_HEADER_TBL (1).TRX_HEADER_ID;

                UPDATE XX_PCM_CUSTOMER_TRX_LINES
                   SET CUSTOMER_TRX_ID = L_CUSTOMER_TRX_ID
                 WHERE CUSTOMER_TRX_ID = L_TRX_HEADER_TBL (1).TRX_HEADER_ID;

                INSERT INTO XX_AR_TRX_ERRORS
                    SELECT * FROM AR_TRX_ERRORS_GT;

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
                     VALUES ('AR_INVOICE_API_PUB.CREATE_SINGLE_INVOICE',
                             L_CUSTOMER_TRX_ID,
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
            ELSE
                NULL;
            END IF;

            IF L_RETURN_STATUS = 'S'
            THEN
                COMMIT;
            ELSE
                ROLLBACK;
            END IF;
        END LOOP;
    END PCM_INVOICE_UPLOAD;


    PROCEDURE PCM_CREDIT_MEMO_UPLOAD (P_COLLECTION_TYPE   IN VARCHAR2,
                                      P_CUSTOMER_TYPE     IN VARCHAR2,
                                      P_DATE_FROM         IN DATE,
                                      P_DATE_TO           IN DATE,
                                      P_PROCESS_MODE      IN VARCHAR2)
    IS
        L_REQUEST_ID             PLS_INTEGER := FND_GLOBAL.CONC_REQUEST_ID;
        L_USER_ID                PLS_INTEGER := FND_GLOBAL.USER_ID;
        L_LOGIN_ID               PLS_INTEGER := FND_GLOBAL.CONC_LOGIN_ID;


        L_BATCH_SOURCE_REC       AR_INVOICE_API_PUB.BATCH_SOURCE_REC_TYPE;
        L_TRX_HEADER_TBL         AR_INVOICE_API_PUB.TRX_HEADER_TBL_TYPE;
        L_TRX_LINES_TBL          AR_INVOICE_API_PUB.TRX_LINE_TBL_TYPE;
        L_TRX_DIST_TBL           AR_INVOICE_API_PUB.TRX_DIST_TBL_TYPE;
        L_TRX_SALESCREDITS_TBL   AR_INVOICE_API_PUB.TRX_SALESCREDITS_TBL_TYPE;

        L_TRX_HEADER_ID          NUMBER;
        L_TRX_LINE_ID            NUMBER;
        L_TRX_DIST_ID            NUMBER;
        L_LINE_NUMBER            NUMBER;
        L_ROW_CNT                NUMBER;

        L_CUSTOMER_TRX_ID        NUMBER;
        L_RETURN_STATUS          VARCHAR2 (1);
        L_MSG_COUNT              NUMBER;
        L_MSG_DATA               VARCHAR2 (2000);

        CURSOR HEAD_CUR IS
              SELECT COLLECTION_TYPE,
                     CUSTOMER_TYPE,
                     ORG_ID,
                     GL_DATE,
                     BILL_TO_CUSTOMER_ID,
                     CUSTOMER_NAME,
                     DEPARTMENT,
                     ROUND (SUM (AMOUNT), 2)     AMOUNT
                FROM XX_PCM_DEDUCTIONS_GT
               WHERE     COLLECTION_TYPE = P_COLLECTION_TYPE
                     AND CUSTOMER_TYPE = P_CUSTOMER_TYPE
                     AND GL_DATE BETWEEN P_DATE_FROM AND P_DATE_TO
                     AND P_PROCESS_MODE = 'F'
            GROUP BY COLLECTION_TYPE,
                     CUSTOMER_TYPE,
                     ORG_ID,
                     GL_DATE,
                     BILL_TO_CUSTOMER_ID,
                     CUSTOMER_NAME,
                     DEPARTMENT
            ORDER BY ORG_ID,
                     GL_DATE,
                     BILL_TO_CUSTOMER_ID,
                     DEPARTMENT;

        CURSOR LINE_CUR (L_ORG_ID        IN NUMBER,
                         L_GL_DATE       IN DATE,
                         L_CUSTOMER_ID   IN NUMBER,
                         L_DEPARTMENT    IN VARCHAR2)
        IS
              SELECT ORG_ID,
                     GL_DATE,
                     BILL_TO_CUSTOMER_ID,
                     CUSTOMER_NAME,
                     DEPARTMENT,
                     PRODUCT,
                     INVENTORY_ITEM_ID,
                     CODE_COMBINATION_ID,
                     'PCM Invoice ' || RETURN_TYPE || '-' || BOOKING_AGENCY     DESCRIPTION,
                     ROUND (SUM (AMOUNT), 2)   AMOUNT
                FROM XX_PCM_DEDUCTIONS_GT
               WHERE     COLLECTION_TYPE = P_COLLECTION_TYPE
                     AND CUSTOMER_TYPE = P_CUSTOMER_TYPE
                     AND GL_DATE BETWEEN P_DATE_FROM AND P_DATE_TO
                     AND P_PROCESS_MODE = 'F'
                     AND ORG_ID = L_ORG_ID
                     AND GL_DATE = L_GL_DATE
                     AND BILL_TO_CUSTOMER_ID = L_CUSTOMER_ID
                     AND DEPARTMENT = L_DEPARTMENT
            GROUP BY RETURN_TYPE,
                     ORG_ID,
                     GL_DATE,
                     BILL_TO_CUSTOMER_ID,
                     CUSTOMER_NAME,
                     DEPARTMENT,
                     PRODUCT,
                     INVENTORY_ITEM_ID,
                     CODE_COMBINATION_ID,
                     COLLECTION_TYPE,
                     BOOKING_AGENCY
            ORDER BY ORG_ID,
                     GL_DATE,
                     BILL_TO_CUSTOMER_ID,
                     DEPARTMENT,
                     PRODUCT;
    BEGIN
        FND_GLOBAL.APPS_INITIALIZE (USER_ID        => FND_GLOBAL.USER_ID,
                                    RESP_ID        => FND_GLOBAL.RESP_ID,
                                    RESP_APPL_ID   => FND_GLOBAL.RESP_APPL_ID);
        MO_GLOBAL.INIT ('AR');

        L_TRX_HEADER_ID := 10000;
        L_TRX_LINE_ID := 10000;
        L_TRX_DIST_ID := 10000;

        --SELECT MAX(CUSTOMER_TRX_ID) INTO L_TRX_HEADER_ID FROM RA_CUSTOMER_TRX_ALL;

        -- SELECT MAX(CUSTOMER_TRX_LINE_ID) INTO L_TRX_LINE_ID FROM RA_CUSTOMER_TRX_LINES_ALL;

        -- SELECT MAX(CUST_TRX_LINE_GL_DIST_ID) INTO L_TRX_DIST_ID FROM RA_CUST_TRX_LINE_GL_DIST_ALL;



        FOR HEAD_REC IN HEAD_CUR
        LOOP
            MO_GLOBAL.SET_POLICY_CONTEXT ('S', HEAD_REC.ORG_ID);

            L_TRX_HEADER_ID := L_TRX_HEADER_ID + 1;
            L_LINE_NUMBER := 1;
            L_ROW_CNT := 1;

            IF P_PROCESS_MODE = 'F'
            THEN
                INSERT INTO XX_PCM_CUSTOMER_TRX_CM (CUSTOMER_TRX_ID,
                                                    COLLECTION_TYPE,
                                                    CUSTOMER_TYPE,
                                                    ORG_ID,
                                                    GL_DATE,
                                                    BILL_TO_CUSTOMER_ID,
                                                    CUSTOMER_NAME,
                                                    DEPARTMENT,
                                                    AMOUNT,
                                                    REQUEST_ID,
                                                    CREATED_BY,
                                                    CREATION_DATE,
                                                    LAST_UPDATE_LOGIN)
                     VALUES (L_TRX_HEADER_ID,
                             HEAD_REC.COLLECTION_TYPE,
                             HEAD_REC.CUSTOMER_TYPE,
                             HEAD_REC.ORG_ID,
                             HEAD_REC.GL_DATE,
                             HEAD_REC.BILL_TO_CUSTOMER_ID,
                             HEAD_REC.CUSTOMER_NAME,
                             HEAD_REC.DEPARTMENT,
                             HEAD_REC.AMOUNT,
                             L_REQUEST_ID,
                             L_USER_ID,
                             SYSDATE,
                             L_LOGIN_ID);


                -- Populate Batch
                L_BATCH_SOURCE_REC.BATCH_SOURCE_ID := -1;

                -- Populate Header
                L_TRX_HEADER_TBL (1).TRX_HEADER_ID := L_TRX_HEADER_ID;
                L_TRX_HEADER_TBL (1).TRX_NUMBER := NULL;
                L_TRX_HEADER_TBL (1).TRX_DATE := HEAD_REC.GL_DATE;
                L_TRX_HEADER_TBL (1).TRX_CURRENCY := 'BDT';
                L_TRX_HEADER_TBL (1).CUST_TRX_TYPE_ID := 2;
                L_TRX_HEADER_TBL (1).BILL_TO_CUSTOMER_ID := HEAD_REC.BILL_TO_CUSTOMER_ID;
                -- L_TRX_HEADER_TBL (1).TERM_ID := 5; -- CM
                L_TRX_HEADER_TBL (1).FINANCE_CHARGES := NULL;
                L_TRX_HEADER_TBL (1).PRINTING_OPTION := 'PRI';
                L_TRX_HEADER_TBL (1).STATUS_TRX := 'OP';

                FOR LINE_REC IN LINE_CUR (HEAD_REC.ORG_ID,
                                          HEAD_REC.GL_DATE,
                                          HEAD_REC.BILL_TO_CUSTOMER_ID,
                                          HEAD_REC.DEPARTMENT)
                LOOP
                    L_TRX_LINE_ID := L_TRX_LINE_ID + 1;
                    L_TRX_DIST_ID := L_TRX_DIST_ID + 1;

                    INSERT INTO XX_PCM_CUSTOMER_TRX_LINES_CM (CUSTOMER_TRX_ID,
                                                              CUSTOMER_TRX_LINE_ID,
                                                              LINE_NUMBER,
                                                              ORG_ID,
                                                              GL_DATE,
                                                              BILL_TO_CUSTOMER_ID,
                                                              DEPARTMENT,
                                                              PRODUCT,
                                                              DESCRIPTION,
                                                              AMOUNT,
                                                              REQUEST_ID,
                                                              CREATED_BY,
                                                              CREATION_DATE,
                                                              LAST_UPDATE_LOGIN)
                         VALUES (L_TRX_HEADER_ID,
                                 L_TRX_LINE_ID,
                                 L_LINE_NUMBER,
                                 LINE_REC.ORG_ID,
                                 LINE_REC.GL_DATE,
                                 LINE_REC.BILL_TO_CUSTOMER_ID,
                                 LINE_REC.DEPARTMENT,
                                 LINE_REC.PRODUCT,
                                 LINE_REC.DESCRIPTION,
                                 LINE_REC.AMOUNT,
                                 L_REQUEST_ID,
                                 L_USER_ID,
                                 SYSDATE,
                                 L_LOGIN_ID);


                    -- Populate Line
                    L_TRX_LINES_TBL (L_ROW_CNT).TRX_HEADER_ID := L_TRX_HEADER_ID;
                    L_TRX_LINES_TBL (L_ROW_CNT).TRX_LINE_ID := L_TRX_LINE_ID;
                    L_TRX_LINES_TBL (L_ROW_CNT).LINE_TYPE := 'LINE';
                    L_TRX_LINES_TBL (L_ROW_CNT).LINE_NUMBER := L_LINE_NUMBER;
                    L_TRX_LINES_TBL (L_ROW_CNT).INVENTORY_ITEM_ID := LINE_REC.INVENTORY_ITEM_ID;
                    L_TRX_LINES_TBL (L_ROW_CNT).DESCRIPTION := LINE_REC.DESCRIPTION;
                    --  L_TRX_LINES_TBL (L_ROW_CNT).UOM_CODE := 'EA'; -- CM
                    L_TRX_LINES_TBL (L_ROW_CNT).QUANTITY_INVOICED := 1;
                    L_TRX_LINES_TBL (L_ROW_CNT).UNIT_SELLING_PRICE := LINE_REC.AMOUNT;

                    -- Populate Distribution
                    L_TRX_DIST_TBL (L_ROW_CNT).TRX_HEADER_ID := L_TRX_HEADER_ID;
                    L_TRX_DIST_TBL (L_ROW_CNT).TRX_LINE_ID := L_TRX_LINE_ID;
                    L_TRX_DIST_TBL (L_ROW_CNT).TRX_DIST_ID := L_TRX_DIST_ID;
                    L_TRX_DIST_TBL (L_ROW_CNT).ACCOUNT_CLASS := 'REV';
                    L_TRX_DIST_TBL (L_ROW_CNT).PERCENT := 100;
                    L_TRX_DIST_TBL (L_ROW_CNT).CODE_COMBINATION_ID := LINE_REC.CODE_COMBINATION_ID;
                    L_ROW_CNT := L_ROW_CNT + 1;
                    L_LINE_NUMBER := L_LINE_NUMBER + 1;
                END LOOP;

                --Calling API
                AR_INVOICE_API_PUB.CREATE_SINGLE_INVOICE (
                    P_API_VERSION            => 1.0,
                    P_BATCH_SOURCE_REC       => L_BATCH_SOURCE_REC,
                    P_TRX_HEADER_TBL         => L_TRX_HEADER_TBL,
                    P_TRX_LINES_TBL          => L_TRX_LINES_TBL,
                    P_TRX_DIST_TBL           => L_TRX_DIST_TBL,
                    P_TRX_SALESCREDITS_TBL   => L_TRX_SALESCREDITS_TBL,
                    X_CUSTOMER_TRX_ID        => L_CUSTOMER_TRX_ID,
                    X_RETURN_STATUS          => L_RETURN_STATUS,
                    X_MSG_COUNT              => L_MSG_COUNT,
                    X_MSG_DATA               => L_MSG_DATA);

                UPDATE XX_PCM_CUSTOMER_TRX_CM
                   SET CUSTOMER_TRX_ID = L_CUSTOMER_TRX_ID
                 WHERE CUSTOMER_TRX_ID = L_TRX_HEADER_TBL (1).TRX_HEADER_ID;

                UPDATE XX_PCM_CUSTOMER_TRX_LINES_CM
                   SET CUSTOMER_TRX_ID = L_CUSTOMER_TRX_ID
                 WHERE CUSTOMER_TRX_ID = L_TRX_HEADER_TBL (1).TRX_HEADER_ID;

                INSERT INTO XX_AR_TRX_ERRORS
                    SELECT * FROM AR_TRX_ERRORS_GT;

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
                     VALUES ('AR_INVOICE_API_PUB.CREATE_SINGLE_INVOICE',
                             L_CUSTOMER_TRX_ID,
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
            ELSE
                NULL;
            END IF;

            IF L_RETURN_STATUS = 'S'
            THEN
                COMMIT;
            ELSE
                ROLLBACK;
            END IF;
        END LOOP;
    END PCM_CREDIT_MEMO_UPLOAD;
	

    PROCEDURE PCM_COLLECTION_UPLOAD (P_COLLECTION_TYPE   IN VARCHAR2,
                                     P_CUSTOMER_TYPE     IN VARCHAR2,
                                     P_DATE_FROM         IN DATE,
                                     P_DATE_TO           IN DATE,
                                     P_PROCESS_MODE      IN VARCHAR2)
    IS
        L_REQUEST_ID      PLS_INTEGER := FND_GLOBAL.CONC_REQUEST_ID;
        L_USER_ID         PLS_INTEGER := FND_GLOBAL.USER_ID;
        L_LOGIN_ID        PLS_INTEGER := FND_GLOBAL.CONC_LOGIN_ID;

        L_CR_ID           NUMBER;
        L_RETURN_STATUS   VARCHAR2 (1);
        L_MSG_COUNT       NUMBER;
        L_MSG_DATA        VARCHAR2 (2000);

        CURSOR CUR IS
              SELECT ORG_ID,
                     RECEIPT_DATE,
                     GL_DATE,
                     CUSTOMER_ID,
                     CUSTOMER_NAME,
                     DEPARTMENT,
                     LOCATION,
                     RECEIPT_METHOD_ID,
                     RECEIPT_NUMBER,
                     ROUND (SUM (AMOUNT), 2)     AMOUNT
                FROM XX_PCM_TO_PAY_COLLECTIONS_GT
               WHERE     COLLECTION_TYPE = P_COLLECTION_TYPE
                     AND CUSTOMER_TYPE = P_CUSTOMER_TYPE
                     AND GL_DATE BETWEEN P_DATE_FROM AND P_DATE_TO
                     AND P_PROCESS_MODE = 'F'
            GROUP BY ORG_ID,
                     RECEIPT_DATE,
                     GL_DATE,
                     CUSTOMER_ID,
                     CUSTOMER_NAME,
                     DEPARTMENT,
                     LOCATION,
                     RECEIPT_METHOD_ID,
                     RECEIPT_NUMBER
              HAVING ROUND (SUM (AMOUNT), 2) > 0
            ORDER BY ORG_ID,
                     GL_DATE,
                     CUSTOMER_ID,
                     DEPARTMENT;
    BEGIN
        FND_GLOBAL.APPS_INITIALIZE (USER_ID        => FND_GLOBAL.USER_ID,
                                    RESP_ID        => FND_GLOBAL.RESP_ID,
                                    RESP_APPL_ID   => FND_GLOBAL.RESP_APPL_ID);
        MO_GLOBAL.INIT ('AR');


        FOR REC IN CUR
        LOOP
            MO_GLOBAL.SET_POLICY_CONTEXT ('S', REC.ORG_ID);

            IF P_PROCESS_MODE = 'F'
            THEN
                AR_RECEIPT_API_PUB.CREATE_CASH (P_API_VERSION         => 1.0,
                                                P_RECEIPT_METHOD_ID   => REC.RECEIPT_METHOD_ID,
                                                P_RECEIPT_NUMBER      => REC.RECEIPT_NUMBER,
                                                P_CURRENCY_CODE       => 'BDT',
                                                P_AMOUNT              => REC.AMOUNT,
                                                P_RECEIPT_DATE        => REC.RECEIPT_DATE,
                                                P_GL_DATE             => REC.GL_DATE,
                                                P_CUSTOMER_ID         => REC.CUSTOMER_ID,
                                                P_LOCATION            => REC.LOCATION,
                                                P_CR_ID               => L_CR_ID,
                                                X_RETURN_STATUS       => L_RETURN_STATUS,
                                                X_MSG_COUNT           => L_MSG_COUNT,
                                                X_MSG_DATA            => L_MSG_DATA);

                INSERT INTO XX_PCM_CASH_RECEIPTS (CASH_RECEIPT_ID,
                                                  ORG_ID,
                                                  GL_DATE,
                                                  CUSTOMER_ID,
                                                  CUSTOMER_NAME,
                                                  DEPARTMENT,
                                                  RECEIPT_NUMBER,
                                                  RECEIPT_METHOD_ID,
                                                  AMOUNT,
                                                  REQUEST_ID,
                                                  CREATED_BY,
                                                  CREATION_DATE,
                                                  LAST_UPDATE_LOGIN)
                     VALUES (L_CR_ID,
                             REC.ORG_ID,
                             REC.GL_DATE,
                             REC.CUSTOMER_ID,
                             REC.CUSTOMER_NAME,
                             REC.DEPARTMENT,
                             REC.RECEIPT_NUMBER,
                             REC.RECEIPT_METHOD_ID,
                             REC.AMOUNT,
                             L_REQUEST_ID,
                             L_USER_ID,
                             SYSDATE,
                             L_LOGIN_ID);

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
                     VALUES ('AR_RECEIPT_API_PUB.CREATE_CASH',
                             L_CR_ID,
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
            ELSE
                NULL;
            END IF;

            IF L_RETURN_STATUS = 'S'
            THEN
                COMMIT;
            ELSE
                ROLLBACK;
            END IF;
        END LOOP;
    END;

    PROCEDURE GRANT_CREDIT_CUSTOMER_ACCESS (ERRBUF             OUT NOCOPY VARCHAR2,
                                            RETCODE            OUT NOCOPY VARCHAR2,
                                            P_CUSTOMER_ID   IN            VARCHAR2)
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
                  SELECT ORG_ID,
                         PARTY_ID,
                         PARTY_NAME,
                         PARTY_SITE_ID,
                         CUST_ACCOUNT_ID,
                         ACCOUNT_NAME
                    FROM XX_PCM_WRONG_CRD_CUST_ACCESS_V
                   WHERE CUSTOMER_ID = NVL (P_CUSTOMER_ID, CUSTOMER_ID)
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
                -- AND HCA.ACCOUNT_NUMBER = UPPER (P_CUSTOMER_ID)
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
         WHERE GL_ID_REC IS NULL;

        UPDATE HZ_CUST_SITE_USES_ALL
           SET GL_ID_REV = XX_AR_PKG.GL_ID_REV (CUST_ACCT_SITE_ID)
         WHERE GL_ID_REV IS NULL;

        COMMIT;
    END;
END;
/
