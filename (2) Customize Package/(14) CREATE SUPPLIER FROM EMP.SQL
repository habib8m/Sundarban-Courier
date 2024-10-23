
PROCEDURE CREATE_SUPPLIER_FROM_EMP(    ERRBUF      OUT NOCOPY VARCHAR2,
                                       RETCODE     OUT NOCOPY VARCHAR2,
                                       P_PERSON_ID IN         NUMBER,
                                       P_ORG_ID    IN         NUMBER)
    IS
        V_VENDOR_ID         NUMBER(15);
        V_PARTY_ID          NUMBER(15);
        V_RETURN_STATUS     VARCHAR2(1);
        V_MSG_COUNT         NUMBER(15);
        V_CUR_MSG_COUNT     NUMBER(15);
        V_MSG_DATA          VARCHAR2(4000);
        V_VENDOR_REC        AP_VENDOR_PUB_PKG.R_VENDOR_REC_TYPE; --type

        V_VENDOR_SITE_ID    NUMBER(15);
        V_PARTY_SITE_ID     NUMBER(15);
        V_LOCATION_ID       NUMBER;
        V_ACCTS_PAY_CODE    NUMBER := 22019901; --22010201
        V_PREPAY_CODE       NUMBER := 12030302; --12030301
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
            FND_FILE.PUT_LINE(
                FND_FILE.LOG,
                '=============================================================================');
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Supplier Creation Process Started...');
            FND_FILE.PUT_LINE(
                FND_FILE.LOG,
                '=============================================================================');




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
            FND_FILE.PUT_LINE(
                FND_FILE.LOG,
                   'Return Status : '
                || (CASE WHEN V_RETURN_STATUS = 'S' THEN 'Success' ELSE 'Error' END));
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Massage Count : ' || V_MSG_COUNT);

            IF (V_RETURN_STATUS <> FND_API.G_RET_STS_SUCCESS)
            THEN
                FOR I IN 1 .. FND_MSG_PUB.COUNT_MSG
                LOOP
                    FND_FILE.PUT_LINE(
                        FND_FILE.LOG,
                           'Massage Data  : '
                        || (SUBSTR(FND_MSG_PUB.GET(P_ENCODED => FND_API.G_FALSE), 1, 4000)));
                END LOOP;
            END IF;

            V_CUR_MSG_COUNT := V_MSG_COUNT;

            FND_FILE.PUT_LINE(
                FND_FILE.LOG,
                '=============================================================================');


            FOR VENDOR_SITE_REC IN VENDOR_SITE_CUR
            LOOP
                FND_CLIENT_INFO.SET_ORG_CONTEXT(VENDOR_SITE_REC.ORG_ID);

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
                FND_FILE.PUT_LINE(
                    FND_FILE.LOG,
                       'Return Status : '
                    || (CASE WHEN V_RETURN_STATUS = 'S' THEN 'Success' ELSE 'Error' END));
                FND_FILE.PUT_LINE(FND_FILE.LOG,
                                  'Massage Count : ' || (V_MSG_COUNT - V_CUR_MSG_COUNT));

                IF (V_RETURN_STATUS <> FND_API.G_RET_STS_SUCCESS)
                THEN
                    FOR I IN V_CUR_MSG_COUNT + 1 .. FND_MSG_PUB.COUNT_MSG
                    LOOP
                        FND_FILE.PUT_LINE(
                            FND_FILE.LOG,
                               'Massage Data  : '
                            || (SUBSTR(FND_MSG_PUB.GET(P_ENCODED => FND_API.G_FALSE), 1, 4000)));
                    END LOOP;
                END IF;

                V_CUR_MSG_COUNT := V_MSG_COUNT;
                FND_FILE.PUT_LINE(
                    FND_FILE.LOG,
                    '=============================================================================');
            END LOOP;
        END LOOP;

        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Supplier Creation Process Ended...');
        FND_FILE.PUT_LINE(
            FND_FILE.LOG,
            '=============================================================================');



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
    END;
