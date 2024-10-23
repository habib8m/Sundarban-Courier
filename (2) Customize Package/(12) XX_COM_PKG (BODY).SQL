
CREATE OR REPLACE PACKAGE BODY APPS.XX_COM_PKG
AS

    FUNCTION GET_USER_NAME (P_USER_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_USER_NAME   FND_USER.USER_NAME%TYPE := '';

        CURSOR P_USER_CURSOR IS
            SELECT USER_NAME
              FROM FND_USER
             WHERE USER_ID = P_USER_ID;
    BEGIN
        OPEN P_USER_CURSOR;

        FETCH P_USER_CURSOR INTO V_USER_NAME;

        CLOSE P_USER_CURSOR;

        RETURN V_USER_NAME;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_USER_NAME;
	
	

    FUNCTION XXBRANCH_SUB_BRANCH (P_BRANCH IN VARCHAR2, P_SUB_BRANCH IN VARCHAR2)
        RETURN VARCHAR2
    IS
        V_BRANCH       VARCHAR2 (240);
        V_SUB_BRANCH   VARCHAR2 (240);
    BEGIN
        IF P_BRANCH IS NULL
        THEN
            V_BRANCH := 'ALL';
        ELSE
            SELECT PARENT_FLEX_VALUE_LOW || '-' || DESCRIPTION
              INTO V_BRANCH
              FROM FND_FLEX_VALUES_VL
             WHERE     NVL (ENABLED_FLAG, 'N') = 'Y'
                   AND FLEX_VALUE_SET_ID = 1016557
                   AND FLEX_VALUE = P_BRANCH;
        END IF;

        IF P_SUB_BRANCH IS NULL
        THEN
            V_SUB_BRANCH := 'ALL';
        ELSE
            SELECT FLEX_VALUE || '-' || DESCRIPTION
              INTO V_SUB_BRANCH
              FROM FND_FLEX_VALUES_VL
             WHERE     NVL (ENABLED_FLAG, 'N') = 'Y'
                   AND FLEX_VALUE_SET_ID = 1016492
                   AND FLEX_VALUE = P_SUB_BRANCH;
        END IF;

        RETURN 'Branch: ' || V_BRANCH || ' and Sub Branch: ' || V_SUB_BRANCH;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END XXBRANCH_SUB_BRANCH;



    FUNCTION GET_EMP_NAME_FROM_USER_ID (P_USER_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_RESULT   VARCHAR2 (128);

        CURSOR P_CURSOR IS
            WITH
                XX_CLAUSE_TAB
                AS
				
                    (SELECT 1 SL,
                            USR.USER_ID,
                            TRIM (
                                   DECODE (EMP.FIRST_NAME, NULL, NULL, EMP.FIRST_NAME)
                                || DECODE (EMP.MIDDLE_NAMES, NULL, NULL, ' ' || EMP.MIDDLE_NAMES)
                                || DECODE (EMP.LAST_NAME, NULL, NULL, ' ' || EMP.LAST_NAME))    USER_NAME
                       FROM FND_USER USR, PER_ALL_PEOPLE_F EMP
                      WHERE     USR.EMPLOYEE_ID = EMP.PERSON_ID
                            AND USR.USER_ID = P_USER_ID
                            AND EFFECTIVE_END_DATE > TRUNC (SYSDATE)
							
                     UNION ALL
                     SELECT 2, USR.USER_ID, NVL (DESCRIPTION, USR.USER_NAME)
                       FROM FND_USER USR
                      WHERE USR.USER_ID = P_USER_ID)

            SELECT USER_NAME
              FROM XX_CLAUSE_TAB
             WHERE USER_ID = P_USER_ID AND SL = (SELECT MIN (SL) FROM XX_CLAUSE_TAB);
			 
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN V_RESULT;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_EMP_NAME_FROM_USER_ID;
	



    FUNCTION GET_EMP_NAME_FROM_EMP_ID (P_EMP_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_EMP   VARCHAR2 (200);

        CURSOR P_CUR IS
            SELECT    EMP.EMPLOYEE_NUMBER
                   || '-'
                   || TRIM (
                             DECODE (EMP.FIRST_NAME, NULL, NULL, EMP.FIRST_NAME)
                          || DECODE (EMP.MIDDLE_NAMES, NULL, NULL, ' ' || EMP.MIDDLE_NAMES)
                          || DECODE (EMP.LAST_NAME, NULL, NULL, ' ' || EMP.LAST_NAME))    EMP_NAME
              FROM PER_ALL_PEOPLE_F EMP
             WHERE EMP.PERSON_ID = P_EMP_ID;
    BEGIN
        OPEN P_CUR;

        FETCH P_CUR INTO V_EMP;

        CLOSE P_CUR;

        RETURN V_EMP;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_EMP_NAME_FROM_EMP_ID;



    FUNCTION GET_EMP_NAME_FROM_USER_NAME (P_USER_NAME IN VARCHAR2)
        RETURN VARCHAR2
    IS
        V_RESULT   VARCHAR2 (128);

        CURSOR P_CURSOR IS
            SELECT    DECODE (EMP.FIRST_NAME, NULL, NULL, EMP.FIRST_NAME)
                   || DECODE (EMP.MIDDLE_NAMES, NULL, NULL, ' ' || EMP.MIDDLE_NAMES)
                   || DECODE (EMP.LAST_NAME, NULL, NULL, ' ' || EMP.LAST_NAME)
              FROM FND_USER USR, PER_ALL_PEOPLE_F EMP
             WHERE     USR.EMPLOYEE_ID = EMP.PERSON_ID
                   AND USR.USER_NAME = P_USER_NAME
                   AND EFFECTIVE_END_DATE > SYSDATE;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN V_RESULT;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_EMP_NAME_FROM_USER_NAME;
	
	

    FUNCTION GET_RESPONSIBILITY_NAME (P_RESPONSIBILITY_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_RESPONSIBILITY_NAME   FND_RESPONSIBILITY_TL.RESPONSIBILITY_NAME%TYPE := '';

        CURSOR P_RESPONSIBILITY_CURSOR IS
            SELECT RESPONSIBILITY_NAME
              FROM FND_RESPONSIBILITY_TL
             WHERE RESPONSIBILITY_ID = P_RESPONSIBILITY_ID;
    BEGIN
        OPEN P_RESPONSIBILITY_CURSOR;

        FETCH P_RESPONSIBILITY_CURSOR INTO V_RESPONSIBILITY_NAME;

        CLOSE P_RESPONSIBILITY_CURSOR;

        RETURN (V_RESPONSIBILITY_NAME);
    END GET_RESPONSIBILITY_NAME;
	
	

    FUNCTION GET_APPLICATION_NAME (P_APPLICATION_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_APPLICATION_NAME   FND_APPLICATION_TL.APPLICATION_NAME%TYPE := '';

        CURSOR P_APPLICATION_CURSOR IS
            SELECT APPLICATION_NAME
              FROM FND_APPLICATION_TL
             WHERE APPLICATION_ID = P_APPLICATION_ID;
    BEGIN
        OPEN P_APPLICATION_CURSOR;

        FETCH P_APPLICATION_CURSOR INTO V_APPLICATION_NAME;

        CLOSE P_APPLICATION_CURSOR;

        RETURN (V_APPLICATION_NAME);
    END GET_APPLICATION_NAME;
	


    FUNCTION GET_BRANCH_CODE_FROM_ORG_ID (P_ORG_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        L_OUTPUT   VARCHAR2 (3);
    BEGIN
        SELECT UPPER (BRANCH_CODE)
          INTO L_OUTPUT
          FROM XX_ORG_COMPANY_BRANCH_V
         WHERE ORG_ID = P_ORG_ID;


        RETURN L_OUTPUT;
    END GET_BRANCH_CODE_FROM_ORG_ID;



    FUNCTION GET_BRANCH_NAME_FROM_CODE (P_BRANCH_CODE IN VARCHAR2)
        RETURN VARCHAR2
    IS
        L_OUTPUT   VARCHAR2 (512);
    BEGIN
        SELECT DESCRIPTION
          INTO L_OUTPUT
          FROM FND_FLEX_VALUES_VL
         WHERE FLEX_VALUE_SET_ID = 1016492 AND FLEX_VALUE = UPPER (P_BRANCH_CODE);

        RETURN L_OUTPUT;
    EXCEPTION
        WHEN OTHERS
        THEN
            RAISE;
    END GET_BRANCH_NAME_FROM_CODE;



    FUNCTION GET_HR_OPERATING_UNIT (P_ORG_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_UNIT_NAME   HR_OPERATING_UNITS.NAME%TYPE := '';

        CURSOR P_UNIT_CURSOR IS
            SELECT NAME
              FROM HR_OPERATING_UNITS
             WHERE ORGANIZATION_ID = P_ORG_ID;
    BEGIN
        OPEN P_UNIT_CURSOR;

        FETCH P_UNIT_CURSOR INTO V_UNIT_NAME;

        CLOSE P_UNIT_CURSOR;

        RETURN V_UNIT_NAME;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_HR_OPERATING_UNIT;



    FUNCTION GET_UNIT_ADDRESS (P_ORG_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_UNIT_ADDRESS   FND_LOOKUP_VALUES_VL.DESCRIPTION%TYPE;

        CURSOR P_ORG_CURSOR IS
            SELECT DESCRIPTION
              FROM FND_LOOKUP_VALUES_VL
             WHERE LOOKUP_TYPE = 'XX_OU_NAMES' AND LOOKUP_CODE = P_ORG_ID;
    BEGIN
        OPEN P_ORG_CURSOR;

        FETCH P_ORG_CURSOR INTO V_UNIT_ADDRESS;

        CLOSE P_ORG_CURSOR;

        RETURN V_UNIT_ADDRESS;
    END GET_UNIT_ADDRESS;



    FUNCTION GET_FLEX_VALUES_FROM_FLEX_ID (P_SEGMENT_VALUE VARCHAR2, P_SEGMENT_NUMBER NUMBER)
        RETURN VARCHAR2
    IS
        V_RESULT   VARCHAR2 (240);

        CURSOR P_CURSOR IS
            SELECT FVV.DESCRIPTION
              FROM FND_ID_FLEX_SEGMENTS_VL FVD, FND_FLEX_VALUES_VL FVV
             WHERE     FVD.FLEX_VALUE_SET_ID = FVV.FLEX_VALUE_SET_ID
                   AND FVD.APPLICATION_ID = 101
                   AND FVD.ID_FLEX_CODE = 'GL#'
                   --AND FVV.SUMMARY_FLAG = 'N'  -- FOR PARRENT VALUE INCLUDE
                   AND SUBSTR (FVD.APPLICATION_COLUMN_NAME, 8, 1) = TO_CHAR (P_SEGMENT_NUMBER)
                   AND FVV.FLEX_VALUE = P_SEGMENT_VALUE;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN (V_RESULT);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_FLEX_VALUES_FROM_FLEX_ID;



    FUNCTION GET_CONCAT_DESC_FROM_CCID (P_CCID NUMBER, P_SEPARATOR VARCHAR2 DEFAULT '.')
        RETURN VARCHAR2
    AS
        V_CONCAT_DESC   VARCHAR2 (2000);
    BEGIN
        SELECT    XX_COM_PKG.GET_FLEX_VALUES_FROM_FLEX_ID (SEGMENT1, 1)
               || P_SEPARATOR
               || XX_COM_PKG.GET_FLEX_VALUES_FROM_FLEX_ID (SEGMENT2, 2)
               || P_SEPARATOR
               || XX_COM_PKG.GET_FLEX_VALUES_FROM_FLEX_ID (SEGMENT3, 3)
               || P_SEPARATOR
               || XX_COM_PKG.GET_FLEX_VALUES_FROM_FLEX_ID (SEGMENT4, 4)
               || P_SEPARATOR
               || XX_COM_PKG.GET_FLEX_VALUES_FROM_FLEX_ID (SEGMENT5, 5)
               || XX_COM_PKG.GET_FLEX_VALUES_FROM_FLEX_ID (SEGMENT6, 6)
               || XX_COM_PKG.GET_FLEX_VALUES_FROM_FLEX_ID (SEGMENT7, 7)
               || XX_COM_PKG.GET_FLEX_VALUES_FROM_FLEX_ID (SEGMENT8, 8)
          INTO V_CONCAT_DESC
          FROM GL_CODE_COMBINATIONS_KFV
         WHERE CODE_COMBINATION_ID = P_CCID;

        RETURN V_CONCAT_DESC;
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END GET_CONCAT_DESC_FROM_CCID;
	
	

    FUNCTION GET_CONCAT_CODE_FROM_CCID (P_CCID NUMBER, P_SEPARATOR VARCHAR2 DEFAULT '.')
        RETURN VARCHAR2
    AS
        V_CONCAT_DESC   VARCHAR2 (2000);
    BEGIN
        SELECT CONCATENATED_SEGMENTS
          INTO V_CONCAT_DESC
          FROM GL_CODE_COMBINATIONS_KFV
         WHERE CODE_COMBINATION_ID = P_CCID;

        RETURN V_CONCAT_DESC;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 'Not Found';
    END GET_CONCAT_CODE_FROM_CCID;



    FUNCTION GET_SEGMENT_VALUE_FROM_CCID (P_CCID IN NUMBER, P_SEGMENT_NUMBER NUMBER)
        RETURN VARCHAR2
    AS
        V_SEGMENT_VALUE   VARCHAR2 (128);
    BEGIN
        SELECT DECODE (P_SEGMENT_NUMBER,
                       1, SEGMENT1,
                       2, SEGMENT2,
                       3, SEGMENT3,
                       4, SEGMENT4,
                       5, SEGMENT5,
                       6, SEGMENT6,
                       7, SEGMENT7,
                       8, SEGMENT8)
          INTO V_SEGMENT_VALUE
          FROM GL_CODE_COMBINATIONS_KFV
         WHERE CODE_COMBINATION_ID = P_CCID;

        RETURN V_SEGMENT_VALUE;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN -1;
    END GET_SEGMENT_VALUE_FROM_CCID;
	

    FUNCTION GET_GL_CODE_DESC_FROM_CCID (P_CCID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_OUTPUT   VARCHAR2 (240);

        CURSOR P_CURSOR IS
            SELECT FVV.FLEX_VALUE || ' - ' || FVV.DESCRIPTION
              FROM FND_ID_FLEX_SEGMENTS_VL       FVD,
                   FND_SEGMENT_ATTRIBUTE_VALUES  SAV,
                   FND_FLEX_VALUES_VL            FVV,
                   GL_CODE_COMBINATIONS          GCC
             WHERE     FVD.ID_FLEX_NUM = SAV.ID_FLEX_NUM
                   AND FVD.ID_FLEX_CODE = SAV.ID_FLEX_CODE
                   AND FVD.APPLICATION_ID = SAV.APPLICATION_ID
                   AND FVD.APPLICATION_COLUMN_NAME = SAV.APPLICATION_COLUMN_NAME
                   AND FVD.FLEX_VALUE_SET_ID = FVV.FLEX_VALUE_SET_ID
                   AND FVD.ID_FLEX_NUM = GCC.CHART_OF_ACCOUNTS_ID
                   AND FVV.FLEX_VALUE =
                       DECODE (SUBSTR (FVD.APPLICATION_COLUMN_NAME, 8, 1),
                               '1', GCC.SEGMENT1,
                               '2', GCC.SEGMENT2,
                               '3', GCC.SEGMENT3,
                               '4', GCC.SEGMENT4,
                               '5', GCC.SEGMENT5,
                               '6', GCC.SEGMENT6,
                               '7', GCC.SEGMENT7,
                               '8', GCC.SEGMENT8)
                   AND FVD.APPLICATION_ID = 101
                   AND FVD.ID_FLEX_CODE = 'GL#'
                   AND SAV.SEGMENT_ATTRIBUTE_TYPE = 'GL_ACCOUNT'
                   AND SAV.ATTRIBUTE_VALUE = 'Y'
                   AND GCC.CODE_COMBINATION_ID = P_CCID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_OUTPUT;

        CLOSE P_CURSOR;

        RETURN (V_OUTPUT);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_GL_CODE_DESC_FROM_CCID;



    FUNCTION GET_GL_DESC_FROM_CCID (P_CCID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_OUTPUT   VARCHAR2 (240);

        CURSOR P_CURSOR IS
            SELECT FVV.DESCRIPTION
              FROM FND_ID_FLEX_SEGMENTS_VL       FVD,
                   FND_SEGMENT_ATTRIBUTE_VALUES  SAV,
                   FND_FLEX_VALUES_VL            FVV,
                   GL_CODE_COMBINATIONS          GCC
             WHERE     FVD.ID_FLEX_NUM = SAV.ID_FLEX_NUM
                   AND FVD.ID_FLEX_CODE = SAV.ID_FLEX_CODE
                   AND FVD.APPLICATION_ID = SAV.APPLICATION_ID
                   AND FVD.APPLICATION_COLUMN_NAME = SAV.APPLICATION_COLUMN_NAME
                   AND FVD.FLEX_VALUE_SET_ID = FVV.FLEX_VALUE_SET_ID
                   AND FVD.ID_FLEX_NUM = GCC.CHART_OF_ACCOUNTS_ID
                   AND FVV.FLEX_VALUE =
                       DECODE (SUBSTR (FVD.APPLICATION_COLUMN_NAME, 8, 1),
                               '1', GCC.SEGMENT1,
                               '2', GCC.SEGMENT2,
                               '3', GCC.SEGMENT3,
                               '4', GCC.SEGMENT4,
                               '5', GCC.SEGMENT5,
                               '6', GCC.SEGMENT6,
                               '7', GCC.SEGMENT7,
                               '8', GCC.SEGMENT8)
                   AND FVD.APPLICATION_ID = 101
                   AND FVD.ID_FLEX_CODE = 'GL#'
                   AND SAV.SEGMENT_ATTRIBUTE_TYPE = 'GL_ACCOUNT'
                   AND SAV.ATTRIBUTE_VALUE = 'Y'
                   AND GCC.CODE_COMBINATION_ID = P_CCID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_OUTPUT;

        CLOSE P_CURSOR;

        RETURN (V_OUTPUT);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_GL_DESC_FROM_CCID;



    FUNCTION GET_GL_CODE_DESC_FROM_CCID_IC (P_CCID IN NUMBER)
        RETURN VARCHAR2
    AS
        V_RESULT   VARCHAR2 (240);

        CURSOR P_CURSOR IS
            SELECT DECODE (
                       GCC.SEGMENT3,
                       '1080101',    FVN.FLEX_VALUE
                                  || ' - '
                                  || FVN.DESCRIPTION
                                  || ' ('
                                  || FVI.DESCRIPTION
                                  || ')',
                       FVN.FLEX_VALUE || ' - ' || FVN.DESCRIPTION)
              FROM FND_FLEX_VALUES_VL FVN, GL_CODE_COMBINATIONS GCC, FND_FLEX_VALUES_VL FVI
             WHERE     GCC.SEGMENT3 = FVN.FLEX_VALUE
                   AND GCC.SEGMENT4 = FVI.FLEX_VALUE
                   AND FVN.FLEX_VALUE_SET_ID = 1014889
                   AND FVI.FLEX_VALUE_SET_ID = 1014967
                   AND GCC.CODE_COMBINATION_ID = P_CCID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN V_RESULT;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_GL_CODE_DESC_FROM_CCID_IC;
	
	

    FUNCTION GET_BS_SHORT_CODE (P_SEGMENT_VALUE IN VARCHAR2)
        RETURN VARCHAR2
    AS
        V_OUTPUT   VARCHAR2 (100);

        CURSOR P_CURSOR IS
            SELECT FVV.DESCRIPTION
              FROM FND_ID_FLEX_SEGMENTS_VL       FVD,
                   FND_FLEX_VALUES_VL            FVV,
                   FND_SEGMENT_ATTRIBUTE_VALUES  SAV
             WHERE     FVD.APPLICATION_ID = SAV.APPLICATION_ID
                   AND FVD.ID_FLEX_CODE = SAV.ID_FLEX_CODE
                   AND FVD.ID_FLEX_NUM = SAV.ID_FLEX_NUM
                   AND FVD.APPLICATION_COLUMN_NAME = SAV.APPLICATION_COLUMN_NAME
                   AND FVD.FLEX_VALUE_SET_ID = FVV.FLEX_VALUE_SET_ID
                   AND FVD.APPLICATION_ID = 101
                   AND FVD.ID_FLEX_CODE = 'GL#'
                   AND FVV.SUMMARY_FLAG = 'N'
                   AND SAV.SEGMENT_ATTRIBUTE_TYPE = 'GL_BALANCING'
                   AND SAV.ATTRIBUTE_VALUE = 'Y'
                   AND FVV.FLEX_VALUE = P_SEGMENT_VALUE;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_OUTPUT;

        CLOSE P_CURSOR;

        RETURN (V_OUTPUT);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_BS_SHORT_CODE;
	
	

    FUNCTION GET_VALUE_SET_ID (P_SEGMENT IN VARCHAR2)
        RETURN NUMBER
    AS
        V_RESULT   NUMBER (10);

        CURSOR P_CURSOR IS
            SELECT FLEX_VALUE_SET_ID
              FROM FND_ID_FLEX_SEGMENTS_VL
             WHERE     APPLICATION_ID = 101
                   AND ID_FLEX_CODE = 'GL#'
                   AND APPLICATION_COLUMN_NAME = P_SEGMENT;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN (V_RESULT);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_VALUE_SET_ID;
	
	

    FUNCTION CONVERT_UOM_TO_PCS (P_INVENTORY_ITEM_ID      NUMBER,
                                 P_FROM_UOM               VARCHAR2,
                                 P_QTY                    NUMBER,
                                 P_TO_UOM              IN VARCHAR2)
        RETURN NUMBER
    AS
        V_PCS_QTY         NUMBER;
        V_PCS_TOTAL_QTY   NUMBER;
    BEGIN
        --IF  P_FROM_UOM=P_TO_UOM THEN
        -- V_PCS_TOTAL_QTY:=P_QTY*1;
        --   ELSE
        IF P_FROM_UOM = 'FT'
        THEN
            SELECT ROUND ((C.CONVERSION_RATE * A.CONVERSION_RATE), 3)
              INTO V_PCS_QTY
              FROM MTL_UOM_CONVERSIONS C, MTL_UNITS_OF_MEASURE B, MTL_UOM_CLASS_CONVERSIONS A
             WHERE     C.INVENTORY_ITEM_ID = P_INVENTORY_ITEM_ID
                   AND C.UOM_CODE = P_FROM_UOM
                   AND B.UOM_CLASS = C.UOM_CLASS
                   AND B.BASE_UOM_FLAG = 'Y'
                   AND C.INVENTORY_ITEM_ID = A.INVENTORY_ITEM_ID
                   AND A.TO_UOM_CODE = B.UOM_CODE
                   AND A.FROM_UOM_CODE = P_TO_UOM;
        ELSE
            SELECT ROUND ((C.CONVERSION_RATE * A.CONVERSION_RATE), 2)
              INTO V_PCS_QTY
              FROM MTL_UOM_CONVERSIONS C, MTL_UNITS_OF_MEASURE B, MTL_UOM_CLASS_CONVERSIONS A
             WHERE     C.INVENTORY_ITEM_ID = P_INVENTORY_ITEM_ID
                   AND C.UOM_CODE = P_FROM_UOM
                   AND B.UOM_CLASS = C.UOM_CLASS
                   AND B.BASE_UOM_FLAG = 'Y'
                   AND C.INVENTORY_ITEM_ID = A.INVENTORY_ITEM_ID
                   AND A.TO_UOM_CODE = B.UOM_CODE
                   AND A.FROM_UOM_CODE = P_TO_UOM;
        END IF;

        ---  END IF;
        V_PCS_TOTAL_QTY := ROUND (NVL (V_PCS_QTY, 0) * NVL (P_QTY, 0));
        RETURN V_PCS_TOTAL_QTY;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 0;
    END CONVERT_UOM_TO_PCS;
	
	

    FUNCTION GET_SECCOND_FROM_TIME_DIFF (P_DATE_FROM IN DATE, P_DATE_TO IN DATE)
        RETURN NUMBER
    IS
        NDATE_1     NUMBER;
        NDATE_2     NUMBER;
        NSECOND_1   NUMBER (5, 0);
        NSECOND_2   NUMBER (5, 0);
    BEGIN
        -- GET JULIAN DATE NUMBER FROM FIRST DATE (DATE_1)
        NDATE_1 := TO_NUMBER (TO_CHAR (P_DATE_FROM, 'J'));

        -- GET JULIAN DATE NUMBER FROM SECOND DATE (DATE_2)
        NDATE_2 := TO_NUMBER (TO_CHAR (P_DATE_TO, 'J'));

        -- GET SECONDS SINCE MIDNIGHT FROM FIRST DATE (DATE_1)
        NSECOND_1 := TO_NUMBER (TO_CHAR (P_DATE_FROM, 'SSSSS'));

        -- GET SECONDS SINCE MIDNIGHT FROM SECOND DATE (DATE_2)
        NSECOND_2 := TO_NUMBER (TO_CHAR (P_DATE_TO, 'SSSSS'));

        RETURN FLOOR (((P_DATE_TO - P_DATE_FROM) * 86400) + (P_DATE_TO - P_DATE_FROM));
    END GET_SECCOND_FROM_TIME_DIFF;



    FUNCTION GET_DIFF_TIME (P_DATE_FROM IN DATE, P_DATE_TO IN DATE)
        RETURN VARCHAR2
    AS
        V_TIME   VARCHAR2 (100);
    BEGIN
        SELECT    DECODE (
                      FLOOR (GET_SECCOND_FROM_TIME_DIFF (P_DATE_FROM, P_DATE_TO) / 86400),
                      0, '',
                         FLOOR (GET_SECCOND_FROM_TIME_DIFF (P_DATE_FROM, P_DATE_TO) / 86400)
                      || ' DAY(S), ')
               || TO_CHAR (
                      TO_DATE (
                          MOD (FLOOR (GET_SECCOND_FROM_TIME_DIFF (P_DATE_FROM, P_DATE_TO)), 86400),
                          'SSSSS'),
                      'HH24:MI:SS')
          INTO V_TIME
          FROM DUAL;

        RETURN (V_TIME);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 'Error';
    END GET_DIFF_TIME;
	
	

    FUNCTION GET_LE_ID_FROM_LEDGER_ID (P_LEDGER_ID IN NUMBER)
        RETURN NUMBER
    IS
        V_LEGAL_ENTITY   ORG_ORGANIZATION_DEFINITIONS.LEGAL_ENTITY%TYPE := '';

        CURSOR P_LEGAL_ENTITY_CURSOR IS
            SELECT MAX (LEGAL_ENTITY)
              FROM ORG_ORGANIZATION_DEFINITIONS
             WHERE SET_OF_BOOKS_ID = P_LEDGER_ID;
    BEGIN
        OPEN P_LEGAL_ENTITY_CURSOR;

        FETCH P_LEGAL_ENTITY_CURSOR INTO V_LEGAL_ENTITY;

        CLOSE P_LEGAL_ENTITY_CURSOR;

        RETURN (V_LEGAL_ENTITY);
    END GET_LE_ID_FROM_LEDGER_ID;
	
	

    FUNCTION GET_LE_ID_FROM_ORG_ID (P_ORG_ID IN NUMBER)
        RETURN NUMBER
    IS
        V_LEGAL_ENTITY   ORG_ORGANIZATION_DEFINITIONS.LEGAL_ENTITY%TYPE := '';

        CURSOR P_LEGAL_ENTITY_CURSOR IS
            SELECT MAX (LEGAL_ENTITY)
              FROM ORG_ORGANIZATION_DEFINITIONS
             WHERE OPERATING_UNIT = P_ORG_ID;
    BEGIN
        OPEN P_LEGAL_ENTITY_CURSOR;

        FETCH P_LEGAL_ENTITY_CURSOR INTO V_LEGAL_ENTITY;

        CLOSE P_LEGAL_ENTITY_CURSOR;

        RETURN (V_LEGAL_ENTITY);
    END GET_LE_ID_FROM_ORG_ID;
	
	

    FUNCTION GET_LE_NAME_FROM_LE_ID (P_LE_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_RESULT   VARCHAR2 (240);

        CURSOR P_CURSOR IS
            SELECT NAME
              FROM XLE.XLE_ENTITY_PROFILES
             WHERE LEGAL_ENTITY_ID = P_LE_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN (V_RESULT);
    END GET_LE_NAME_FROM_LE_ID;
	
	

    FUNCTION GET_LEDGER_ID_FROM_ORG_ID (P_ORG_ID IN NUMBER)
        RETURN NUMBER
    IS
        V_LEDGER_ID   NUMBER;

        CURSOR P_LEDGER_CURSOR IS
            SELECT SET_OF_BOOKS_ID
              FROM HR_OPERATING_UNITS
             WHERE ORGANIZATION_ID = P_ORG_ID;
    BEGIN
        OPEN P_LEDGER_CURSOR;

        FETCH P_LEDGER_CURSOR INTO V_LEDGER_ID;

        CLOSE P_LEDGER_CURSOR;

        RETURN (V_LEDGER_ID);
    END GET_LEDGER_ID_FROM_ORG_ID;
	
	

    FUNCTION GET_SUPPLIERS_COUNTRY_NAME (P_VENDOR_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_COUNTRY_NAME   FND_TERRITORIES_TL.TERRITORY_SHORT_NAME%TYPE := '';

        CURSOR P_COUNTRY_CURSOR IS
              SELECT MAX (CO.TERRITORY_SHORT_NAME)
                FROM AP_SUPPLIERS AV, AP_SUPPLIER_SITES_ALL ST, FND_TERRITORIES_TL CO
               WHERE     AV.VENDOR_ID = ST.VENDOR_ID
                     AND ST.COUNTRY = CO.TERRITORY_CODE
                     AND AV.VENDOR_ID = P_VENDOR_ID
            GROUP BY AV.VENDOR_ID;
    BEGIN
        OPEN P_COUNTRY_CURSOR;

        FETCH P_COUNTRY_CURSOR INTO V_COUNTRY_NAME;

        CLOSE P_COUNTRY_CURSOR;

        RETURN (NVL (V_COUNTRY_NAME, 'Not Defined'));
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_SUPPLIERS_COUNTRY_NAME;
	


    FUNCTION GET_COMPANY_NAME (P_COMPANY_CODE IN VARCHAR2)
        RETURN VARCHAR2
    IS
        V_COMPANY_NAME   FND_LOOKUP_VALUES_VL.MEANING%TYPE;

        CURSOR P_COMPANY_CURSOR IS
            SELECT DESCRIPTION
              FROM FND_FLEX_VALUES_VL
             WHERE FLEX_VALUE_SET_ID = 1016491 AND FLEX_VALUE = P_COMPANY_CODE;
    BEGIN
        OPEN P_COMPANY_CURSOR;

        FETCH P_COMPANY_CURSOR INTO V_COMPANY_NAME;

        CLOSE P_COMPANY_CURSOR;

        RETURN V_COMPANY_NAME;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_COMPANY_NAME;
	
	

    FUNCTION GET_UNIT_NAME_FROM_BS (P_COMPANY_CODE IN VARCHAR2)
        RETURN VARCHAR2
    IS
        V_COMPANY_NAME   FND_LOOKUP_VALUES_VL.MEANING%TYPE;

        CURSOR P_COMPANY_CURSOR IS
            SELECT OU.NAME
              FROM FND_FLEX_VALUES_VL BS, HR_OPERATING_UNITS OU
             WHERE     BS.DESCRIPTION = OU.SHORT_CODE
                   AND BS.FLEX_VALUE_SET_ID = 1016198
                   AND BS.FLEX_VALUE = P_COMPANY_CODE;
    BEGIN
        OPEN P_COMPANY_CURSOR;

        FETCH P_COMPANY_CURSOR INTO V_COMPANY_NAME;

        CLOSE P_COMPANY_CURSOR;

        RETURN V_COMPANY_NAME;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_UNIT_NAME_FROM_BS;
	
	

    FUNCTION GET_ORGANIZATION_NAME (P_ORG_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_ORGANIZATION_NAME   VARCHAR2 (4000);

        CURSOR P_ORGNAME_CURSOR IS
            SELECT NAME
              FROM HR_ALL_ORGANIZATION_UNITS
             WHERE ORGANIZATION_ID = P_ORG_ID;
    BEGIN
        OPEN P_ORGNAME_CURSOR;

        FETCH P_ORGNAME_CURSOR INTO V_ORGANIZATION_NAME;

        CLOSE P_ORGNAME_CURSOR;

        RETURN V_ORGANIZATION_NAME;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_ORGANIZATION_NAME;
	
	

    FUNCTION GET_ORGANIZATION_ADDRESS (P_ORG_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_ORGANIZATION_ADDRESSE   VARCHAR2 (4000);

        CURSOR P_ADDRESS_CURSOR IS
            SELECT    ADDRESS_LINE_1
                   || ' '
                   || ADDRESS_LINE_2
                   || ' '
                   || ADDRESS_LINE_3
                   || DECODE (TOWN_OR_CITY, NULL, NULL, ', ' || TOWN_OR_CITY)    ADDRESS
              FROM HR_LOCATIONS_ALL LOC, HR_ALL_ORGANIZATION_UNITS ORG
             WHERE LOC.LOCATION_ID = ORG.LOCATION_ID AND ORG.ORGANIZATION_ID = P_ORG_ID;
    BEGIN
        OPEN P_ADDRESS_CURSOR;

        FETCH P_ADDRESS_CURSOR INTO V_ORGANIZATION_ADDRESSE;

        CLOSE P_ADDRESS_CURSOR;

        RETURN V_ORGANIZATION_ADDRESSE;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_ORGANIZATION_ADDRESS;
--********************************************	


    FUNCTION AMOUNT_IN_WORD (P_AMT IN NUMBER)
        RETURN VARCHAR2
    IS
        M_MAIN_AMT_TEXT     VARCHAR2 (2000);
        M_TOP_AMT_TEXT      VARCHAR2 (2000);
        M_BOTTOM_AMT_TEXT   VARCHAR2 (2000);
        M_DECIMAL_TEXT      VARCHAR2 (2000);
        M_TOP               NUMBER (20, 5);
        M_MAIN_AMT          NUMBER (20, 5);
        M_TOP_AMT           NUMBER (20, 5);
        M_BOTTOM_AMT        NUMBER (20, 5);
        M_DECIMAL           NUMBER (20, 5);
        M_AMT               NUMBER (20, 5);
        M_TEXT              VARCHAR2 (2000);
    BEGIN
        M_MAIN_AMT := NULL;
        M_TOP_AMT_TEXT := NULL;
        M_BOTTOM_AMT_TEXT := NULL;
        M_DECIMAL_TEXT := NULL;
        M_DECIMAL := TRUNC (ABS (P_AMT), 2) - TRUNC (ABS (P_AMT));

        IF M_DECIMAL > 0
        THEN
            M_DECIMAL := M_DECIMAL * 100;
        END IF;

        M_AMT := TRUNC (ABS (P_AMT));
        M_TOP := TRUNC (M_AMT / 100000); 
        M_MAIN_AMT := TRUNC (M_TOP / 100); -- Core
        M_TOP_AMT := M_TOP - (M_MAIN_AMT * 100); --Lac
        M_BOTTOM_AMT := M_AMT - (M_TOP * 100000); --Thousand

        IF M_MAIN_AMT > 0
        THEN
            M_MAIN_AMT_TEXT := TO_CHAR (TO_DATE (M_MAIN_AMT, 'J'), 'JSP');

            IF M_MAIN_AMT = 1
            THEN
                M_MAIN_AMT_TEXT := M_MAIN_AMT_TEXT || ' CRORE ';
            ELSE
                M_MAIN_AMT_TEXT := M_MAIN_AMT_TEXT || ' CRORES ';
            END IF;
        END IF;

        IF M_TOP_AMT > 0
        THEN
            M_TOP_AMT_TEXT := TO_CHAR (TO_DATE (M_TOP_AMT, 'J'), 'JSP');

            IF M_TOP_AMT = 1
            THEN
                M_TOP_AMT_TEXT := M_TOP_AMT_TEXT || ' LAC ';
            ELSE
                M_TOP_AMT_TEXT := M_TOP_AMT_TEXT || ' LACS ';
            END IF;
        END IF;

        IF M_BOTTOM_AMT > 0
        THEN
            M_BOTTOM_AMT_TEXT := TO_CHAR (TO_DATE (M_BOTTOM_AMT, 'J'), 'JSP');
        END IF;

        IF M_DECIMAL > 0
        THEN
            IF NVL (M_BOTTOM_AMT, 0) + NVL (M_TOP_AMT, 0) > 0
            THEN
                M_DECIMAL_TEXT :=
                    'AND ' || INITCAP (TO_CHAR (TO_DATE (M_DECIMAL, 'J'), 'JSP')) || ' PAISA ';
            ELSE
                M_DECIMAL_TEXT :=
                    'AND ' || INITCAP (TO_CHAR (TO_DATE (M_DECIMAL, 'J'), 'JSP')) || ' PAISA ';
            END IF;
        END IF;

        M_TEXT :=
               INITCAP (M_MAIN_AMT_TEXT)
            || INITCAP (M_TOP_AMT_TEXT)
            || INITCAP (M_BOTTOM_AMT_TEXT)
            || ' TAKA '
            || M_DECIMAL_TEXT
            || 'ONLY';
        M_TEXT := UPPER (SUBSTR (M_TEXT, 1, 1)) || SUBSTR (M_TEXT, 2);
        M_TEXT := ' ' || M_TEXT;
        RETURN (TRIM (
                    CASE
                        WHEN SUBSTR (TRIM (REPLACE (M_TEXT, '-', ' ')), 1, 4) = 'TAKA'
                        THEN
                            SUBSTR (TRIM (REPLACE (M_TEXT, '-', ' ')), 10, 2000)
                        ELSE
                            TRIM (REPLACE (M_TEXT, '-', ' '))
                    END));
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 'Input Is Too Long To Display';
    END AMOUNT_IN_WORD;
--********************************************	
	

    FUNCTION GET_SEQUENCE_VALUE (P_TABLE_NAME     VARCHAR2,
                                 P_COLUMN_NAME    VARCHAR2,
                                 P_WHERE_CLAUSE   VARCHAR2 DEFAULT NULL)
        RETURN NUMBER
    IS
        V_SEQUENCE_VALUE   NUMBER;
        V_SQL_STATEMENT    VARCHAR2 (2000);
    BEGIN
        IF P_WHERE_CLAUSE IS NOT NULL
        THEN
            V_SQL_STATEMENT :=
                   'SELECT NVL(MAX('
                || P_COLUMN_NAME
                || '),10000) + 1 FROM XX.'
                || P_TABLE_NAME
                || ' WHERE '
                || P_WHERE_CLAUSE;
        ELSE
            V_SQL_STATEMENT :=
                'SELECT NVL(MAX(' || P_COLUMN_NAME || '),10000) + 1 FROM ' || P_TABLE_NAME;
        END IF;

        EXECUTE IMMEDIATE V_SQL_STATEMENT
            INTO V_SEQUENCE_VALUE;

        RETURN V_SEQUENCE_VALUE;
    END GET_SEQUENCE_VALUE;
	
	

    FUNCTION IS_NUMBER (P_INPUT VARCHAR2)
        RETURN NUMBER
    AS
        V_INPUT   NUMBER;
    BEGIN
        V_INPUT := NVL (TRANSLATE ((P_INPUT), '.', 1), 'XX');
        RETURN 1;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END IS_NUMBER;
	
	

    FUNCTION GET_NUMBER_FROM_STRING (P_STRING IN VARCHAR2)
        RETURN VARCHAR2
    AS
        V_LENGTH   NUMBER;
        V_INPUT    VARCHAR2 (1);
        V_OUTPUT   VARCHAR2 (4000);
    BEGIN
        V_LENGTH := LENGTH (P_STRING);

        FOR I IN 1 .. V_LENGTH
        LOOP
            V_INPUT := SUBSTR (P_STRING, I, 1);

            IF IS_NUMBER (V_INPUT) = 1
            THEN
                V_OUTPUT := V_OUTPUT || V_INPUT;
            END IF;
        END LOOP;

        RETURN V_OUTPUT;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;

    FUNCTION REMOVE_NUMBER_FROM_STRING (P_STRING IN VARCHAR2)
        RETURN VARCHAR2
    AS
        V_LENGTH   NUMBER;
        V_INPUT    VARCHAR2 (1);
        V_OUTPUT   VARCHAR2 (4000);
    BEGIN
        V_LENGTH := LENGTH (P_STRING);

        FOR I IN 1 .. V_LENGTH
        LOOP
            V_INPUT := SUBSTR (P_STRING, I, 1);

            IF IS_NUMBER (V_INPUT) = 0
            THEN
                V_OUTPUT := V_OUTPUT || V_INPUT;
            END IF;
        END LOOP;

        RETURN V_OUTPUT;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;

    FUNCTION GET_EVENT_ID_FROM_DESCRIPTION (P_DESCRIPTION IN VARCHAR2)
        RETURN NUMBER
    IS
        V_RESULT   NUMBER;

        CURSOR P_CURSOR IS
            SELECT GET_NUMBER_FROM_STRING (
                       SUBSTR (P_DESCRIPTION, INSTR (P_DESCRIPTION, 'EVENT_ID OF'), 24))
              FROM DUAL;
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


    PROCEDURE TRUNCATE_TABLE (P_TABLE_NAME IN VARCHAR2)
    IS
    --   PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || P_TABLE_NAME;
    END;
	

    FUNCTION GET_LEDGER_NAME_FROM_ID (P_LEDGER_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_RESULT   VARCHAR2 (30);

        CURSOR P_CURSOR IS
            SELECT NAME
              FROM GL_LEDGERS
             WHERE LEDGER_ID = P_LEDGER_ID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_RESULT;

        CLOSE P_CURSOR;

        RETURN (V_RESULT);
    END;


    FUNCTION GET_COMPANY_DESC_FROM_CCID (P_CCID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_OUTPUT   VARCHAR2 (240);

        CURSOR P_CURSOR IS
            SELECT FVV.DESCRIPTION
              FROM FND_ID_FLEX_SEGMENTS_VL       FVD,
                   FND_SEGMENT_ATTRIBUTE_VALUES  SAV,
                   FND_FLEX_VALUES_VL            FVV,
                   GL_CODE_COMBINATIONS          GCC
             WHERE     FVD.ID_FLEX_NUM = SAV.ID_FLEX_NUM
                   AND FVD.ID_FLEX_CODE = SAV.ID_FLEX_CODE
                   AND FVD.APPLICATION_ID = SAV.APPLICATION_ID
                   AND FVD.APPLICATION_COLUMN_NAME = SAV.APPLICATION_COLUMN_NAME
                   AND FVD.FLEX_VALUE_SET_ID = FVV.FLEX_VALUE_SET_ID
                   AND FVD.ID_FLEX_NUM = GCC.CHART_OF_ACCOUNTS_ID
                   AND FVV.FLEX_VALUE =
                       DECODE (SUBSTR (FVD.APPLICATION_COLUMN_NAME, 8, 1),
                               '1', GCC.SEGMENT1,
                               '2', GCC.SEGMENT2,
                               '3', GCC.SEGMENT3,
                               '4', GCC.SEGMENT4,
                               '5', GCC.SEGMENT5,
                               '6', GCC.SEGMENT6,
                               '7', GCC.SEGMENT7,
                               '8', GCC.SEGMENT8)
                   AND FVD.APPLICATION_ID = 101
                   AND FVD.ID_FLEX_CODE = 'GL#'
                   AND SAV.SEGMENT_ATTRIBUTE_TYPE = 'GL_BALANCING'
                   AND SAV.ATTRIBUTE_VALUE = 'Y'
                   AND GCC.CODE_COMBINATION_ID = P_CCID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_OUTPUT;

        CLOSE P_CURSOR;

        RETURN (V_OUTPUT);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_COMPANY_DESC_FROM_CCID;
	


    FUNCTION GET_ORG_ID_FROM_CUST_ID (P_CUST_ID IN VARCHAR2)
        RETURN NUMBER
    IS
        V_OUTPUT   NUMBER;

        CURSOR P_CURSOR IS
            SELECT OCB.ORG_ID
              FROM FND_FLEX_VALUES_VL FFV, XX_ORG_COMPANY_BRANCH_V OCB
             WHERE     UPPER (SUBSTR (OCB.ORG_CODE, 1, 3)) = UPPER (SUBSTR (P_CUST_ID, 3, 3))
                   AND SUBSTR (FFV.FLEX_VALUE, 2, 2) = SUBSTR (P_CUST_ID, 1, 2)
                   AND FFV.FLEX_VALUE_SET_ID = 1016493
                   AND FFV.FLEX_VALUE < 300
                   AND (CASE
                            WHEN OCB.PARENT_ORG = 'SCS' AND SUBSTR (FFV.FLEX_VALUE, 1, 1) = 1
                            THEN
                                1
                            WHEN OCB.PARENT_ORG = 'SETS' AND SUBSTR (FFV.FLEX_VALUE, 1, 1) = 2
                            THEN
                                1
                            ELSE
                                0
                        END) =
                       1;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_OUTPUT;

        CLOSE P_CURSOR;

        RETURN (V_OUTPUT);
    EXCEPTION
        WHEN OTHERS
        THEN
            RAISE;
    END GET_ORG_ID_FROM_CUST_ID;



    FUNCTION GET_BRANCH_SUB_BRANCH (P_BRANCH IN VARCHAR2, P_SUB_BRANCH IN VARCHAR2)
        RETURN VARCHAR2
    IS
        V_BRANCH       VARCHAR2 (240);
        V_SUB_BRANCH   VARCHAR2 (240);
    BEGIN
        IF P_BRANCH IS NULL
        THEN
            V_BRANCH := 'ALL';
        ELSE
            SELECT FLEX_VALUE || '-' || DESCRIPTION
              INTO V_BRANCH
              FROM FND_FLEX_VALUES_VL
             WHERE     NVL (ENABLED_FLAG, 'N') = 'Y'
                   AND FLEX_VALUE_SET_ID = 1016492
                   AND FLEX_VALUE = P_BRANCH;
        END IF;

        IF P_SUB_BRANCH IS NULL
        THEN
            V_SUB_BRANCH := 'ALL';
        ELSE
            SELECT FLEX_VALUE || '-' || DESCRIPTION
              INTO V_SUB_BRANCH
              FROM FND_FLEX_VALUES_VL
             WHERE     NVL (ENABLED_FLAG, 'N') = 'Y'
                   AND FLEX_VALUE_SET_ID = 1016492
                   AND FLEX_VALUE = P_SUB_BRANCH;
        END IF;

        RETURN 'Branch: ' || V_BRANCH || ' and Sub Branch: ' || V_SUB_BRANCH;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END GET_BRANCH_SUB_BRANCH;
	
	

    FUNCTION UPDATE_CODE_COMBINATION (P_CCID            IN NUMBER,
                                      P_WRONG_ACCOUNT      NUMBER,
                                      P_RIGHT_ACCOUNT      NUMBER)
        RETURN NUMBER
    IS
        V_OUTPUT   NUMBER;

        CURSOR P_CURSOR IS
            SELECT XX_GL_PKG.CREATE_GET_GL_CCID (
                          GCC.SEGMENT1
                       || '.'
                       || GCC.SEGMENT2
                       || '.'
                       || GCC.SEGMENT3
                       || '.'
                       || 53010101
                       || '.'
                       || GCC.SEGMENT5
                       || '.'
                       || GCC.SEGMENT6
                       || '.'
                       || GCC.SEGMENT7)
              FROM GL_CODE_COMBINATIONS GCC
             WHERE GCC.CODE_COMBINATION_ID = P_CCID;
    BEGIN
        OPEN P_CURSOR;

        FETCH P_CURSOR INTO V_OUTPUT;

        CLOSE P_CURSOR;

        RETURN (V_OUTPUT);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END UPDATE_CODE_COMBINATION;
	
	

    FUNCTION GET_REPLACED_CCID (P_CCID IN NUMBER, P_SEG_NUM NUMBER, P_SEG_VALUE VARCHAR2)
        RETURN NUMBER
    IS
        V_OUTPUT   NUMBER;
    BEGIN
        SELECT XX_GL_PKG.CREATE_GET_GL_CCID (
                      CASE WHEN P_SEG_NUM = 1 THEN P_SEG_VALUE ELSE GCC.SEGMENT1 END
                   || '.'
                   || CASE WHEN P_SEG_NUM = 2 THEN P_SEG_VALUE ELSE GCC.SEGMENT2 END
                   || '.'
                   || CASE WHEN P_SEG_NUM = 3 THEN P_SEG_VALUE ELSE GCC.SEGMENT3 END
                   || '.'
                   || CASE WHEN P_SEG_NUM = 4 THEN P_SEG_VALUE ELSE GCC.SEGMENT4 END
                   || '.'
                   || CASE WHEN P_SEG_NUM = 5 THEN P_SEG_VALUE ELSE GCC.SEGMENT5 END
                   || '.'
                   || CASE WHEN P_SEG_NUM = 6 THEN P_SEG_VALUE ELSE GCC.SEGMENT6 END
                   || '.'
                   || CASE WHEN P_SEG_NUM = 7 THEN P_SEG_VALUE ELSE GCC.SEGMENT7 END)
          INTO V_OUTPUT
          FROM GL_CODE_COMBINATIONS GCC
         WHERE GCC.CODE_COMBINATION_ID = P_CCID;

        RETURN V_OUTPUT;
    EXCEPTION
        WHEN OTHERS
        THEN
            RAISE_APPLICATION_ERROR (-20101, 'Error');
    END GET_REPLACED_CCID;
	
	

    FUNCTION GET_RECEIPT_CLASSES (P_RECEIPT IN NUMBER)
        RETURN VARCHAR2
    IS
        V_RECEPT   VARCHAR2 (240);
    BEGIN
        IF P_RECEIPT IS NULL
        THEN
            V_RECEPT := 'All Receipt';
        ELSE
            SELECT NAME
              INTO V_RECEPT
              FROM AR_RECEIPT_CLASSES
             WHERE RECEIPT_CLASS_ID > 1 AND RECEIPT_CLASS_ID = P_RECEIPT;
        END IF;


        RETURN V_RECEPT;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;

    FUNCTION GET_PARTY_NAME_FROM_ID (P_PARTY_ID IN NUMBER)
        RETURN VARCHAR2
    IS
        V_OUTPUT   VARCHAR2 (240);
    BEGIN
        SELECT PARTY_NAME
          INTO V_OUTPUT
          FROM HZ_PARTIES
         WHERE PARTY_ID = P_PARTY_ID;

        RETURN V_OUTPUT;
    EXCEPTION
        WHEN OTHERS
        THEN
            RAISE;
    END;

    PROCEDURE EXECUTE_IMMEDIATE (ERRBUFF          OUT VARCHAR2,
                                 RETCODE          OUT VARCHAR2,
                                 P_STATEMENT   IN     VARCHAR2)
    AS
    BEGIN
        EXECUTE IMMEDIATE P_STATEMENT;
    END;

    PROCEDURE UPLOAD_NEW_BRANCH (ERRBUF             OUT NOCOPY VARCHAR2,
                                 RETCODE            OUT NOCOPY VARCHAR2,
                                 P_BRANCH_CODE   IN            VARCHAR2)
    IS
    BEGIN
        -- Payables
        FND_GLOBAL.APPS_INITIALIZE (USER_ID        => FND_GLOBAL.USER_ID,
                                    RESP_ID        => 50721,          -- Payables Administrator, SCS
                                    RESP_APPL_ID   => 200);                              -- Payables
        MO_GLOBAL.INIT ('SQLAP');

        -- Complete Financial Options for AP

        INSERT INTO AP.FINANCIALS_SYSTEM_PARAMS_ALL
            SELECT SYSDATE,
                   FND_GLOBAL.USER_ID
                       LAST_UPDATED_BY,
                   SET_OF_BOOKS_ID,
                   PAYMENT_METHOD_LOOKUP_CODE,
                   USER_DEFINED_VENDOR_NUM_CODE,
                   VENDOR_NUM_START_NUM,
                   SHIP_TO_LOCATION_ID,
                   BILL_TO_LOCATION_ID,
                   SHIP_VIA_LOOKUP_CODE,
                   FOB_LOOKUP_CODE,
                   TERMS_ID,
                   ALWAYS_TAKE_DISC_FLAG,
                   PAY_DATE_BASIS_LOOKUP_CODE,
                   INVOICE_CURRENCY_CODE,
                   PAYMENT_CURRENCY_CODE,
                   XX_GL_PKG.CREATE_GET_GL_CCID (
                       COMPANY_CODE || '.' || BRANCH_CODE || '.999.22010201.99.999.999')
                       ACCTS_PAY_CODE_COMBINATION_ID,
                   XX_GL_PKG.CREATE_GET_GL_CCID (
                       COMPANY_CODE || '.' || BRANCH_CODE || '.999.12030301.99.999.999')
                       PREPAY_CODE_COMBINATION_ID,
                   XX_GL_PKG.CREATE_GET_GL_CCID (
                       COMPANY_CODE || '.' || BRANCH_CODE || '.999.42490101.99.999.999')
                       DISC_TAKEN_CODE_COMBINATION_ID,
                   FUTURE_PERIOD_LIMIT,
                   RESERVE_AT_COMPLETION_FLAG,
                   RES_ENCUMB_CODE_COMBINATION_ID,
                   REQ_ENCUMBRANCE_FLAG,
                   REQ_ENCUMBRANCE_TYPE_ID,
                   PURCH_ENCUMBRANCE_FLAG,
                   PURCH_ENCUMBRANCE_TYPE_ID,
                   INV_ENCUMBRANCE_TYPE_ID,
                   MANUAL_VENDOR_NUM_TYPE,
                   INVENTORY_ORGANIZATION_ID,
                   FND_GLOBAL.LOGIN_ID
                       LAST_UPDATE_LOGIN,
                   SYSDATE,
                   FND_GLOBAL.USER_ID
                       CREATED_BY,
                   FREIGHT_TERMS_LOOKUP_CODE,
                   RFQ_ONLY_SITE_FLAG,
                   RECEIPT_ACCEPTANCE_DAYS,
                   BUSINESS_GROUP_ID,
                   EXPENSE_CHECK_ADDRESS_FLAG,
                   TERMS_DATE_BASIS,
                   USE_POSITIONS_FLAG,
                   RATE_VAR_CODE_COMBINATION_ID,
                   HOLD_UNMATCHED_INVOICES_FLAG,
                   EXCLUSIVE_PAYMENT_FLAG,
                   REVISION_SORT_ORDERING,
                   VAT_REGISTRATION_NUM,
                   VAT_COUNTRY_CODE,
                   NULL
                       RATE_VAR_GAIN_CCID,
                   NULL
                       RATE_VAR_LOSS_CCID,
                   OCB.ORG_ID,
                   BANK_CHARGE_BEARER,
                   VAT_CODE,
                   MATCH_OPTION,
                   NON_RECOVERABLE_TAX_FLAG,
                   TAX_ROUNDING_RULE,
                   PRECISION,
                   MINIMUM_ACCOUNTABLE_UNIT,
                   DEFAULT_RECOVERY_RATE,
                   CASH_BASIS_ENC_NR_TAX,
                   FUTURE_DATED_PAYMENT_CCID,
                   EXPENSE_CLEARING_CCID,
                   MISC_CHARGE_CCID,
                   GLOBAL_ATTRIBUTE_CATEGORY,
                   GLOBAL_ATTRIBUTE1,
                   GLOBAL_ATTRIBUTE2,
                   GLOBAL_ATTRIBUTE3,
                   GLOBAL_ATTRIBUTE4,
                   GLOBAL_ATTRIBUTE5,
                   GLOBAL_ATTRIBUTE6,
                   GLOBAL_ATTRIBUTE7,
                   GLOBAL_ATTRIBUTE8,
                   GLOBAL_ATTRIBUTE9,
                   GLOBAL_ATTRIBUTE10,
                   GLOBAL_ATTRIBUTE11,
                   GLOBAL_ATTRIBUTE12,
                   GLOBAL_ATTRIBUTE13,
                   GLOBAL_ATTRIBUTE14,
                   GLOBAL_ATTRIBUTE15,
                   GLOBAL_ATTRIBUTE16,
                   GLOBAL_ATTRIBUTE17,
                   GLOBAL_ATTRIBUTE18,
                   GLOBAL_ATTRIBUTE19,
                   GLOBAL_ATTRIBUTE20,
                   RETAINAGE_CODE_COMBINATION_ID
              FROM AP.FINANCIALS_SYSTEM_PARAMS_ALL FSP, XX_ORG_COMPANY_BRANCH_V OCB
             WHERE     FSP.ORG_ID = 86
                   AND OCB.ORG_ID NOT IN (SELECT ORG_ID FROM AP.FINANCIALS_SYSTEM_PARAMS_ALL)
                   AND PARENT_ORG <> 'LOG';

        -- Complete Payable Options for AP

        INSERT INTO AP.AP_SYSTEM_PARAMETERS_ALL
            SELECT SYSDATE,
                   FND_GLOBAL.USER_ID
                       LAST_UPDATED_BY,
                   SET_OF_BOOKS_ID,
                   BASE_CURRENCY_CODE,
                   RECALC_PAY_SCHEDULE_FLAG,
                   AUTO_CALCULATE_INTEREST_FLAG,
                   INVOICE_CURRENCY_CODE,
                   PAYMENT_CURRENCY_CODE,
                   INVOICE_NET_GROSS_FLAG,
                   BANK_ACCOUNT_ID,
                   CHECK_OVERFLOW_LOOKUP_CODE,
                   BATCH_CONTROL_FLAG,
                   TERMS_ID,
                   ALWAYS_TAKE_DISC_FLAG,
                   PAY_DATE_BASIS_LOOKUP_CODE,
                   XX_GL_PKG.CREATE_GET_GL_CCID (
                       COMPANY_CODE || '.' || BRANCH_CODE || '.999.22010201.99.999.999')
                       ACCTS_PAY_CODE_COMBINATION_ID,
                   SALES_TAX_CODE_COMBINATION_ID,
                   XX_GL_PKG.CREATE_GET_GL_CCID (
                       COMPANY_CODE || '.' || BRANCH_CODE || '.999.42490101.99.999.999')
                       DISC_LOST_CODE_COMBINATION_ID,
                   XX_GL_PKG.CREATE_GET_GL_CCID (
                       COMPANY_CODE || '.' || BRANCH_CODE || '.999.42490101.99.999.999')
                       DISC_TAKEN_CODE_COMBINATION_ID,
                   HOLD_GAIN_CODE_COMBINATION_ID,
                   TRANS_GAIN_CODE_COMBINATION_ID,
                   APPLY_ADVANCES_DEFAULT,
                   ADD_DAYS_SETTLEMENT_DATE,
                   COST_OF_MONEY,
                   DAYS_BETWEEN_CHECK_CYCLES,
                   FEDERAL_IDENTIFICATION_NUM,
                   LOCATION_ID,
                   CREATE_EMPLOYEE_VENDOR_FLAG,
                   EMPLOYEE_TERMS_ID,
                   EMPLOYEE_PAY_GROUP_LOOKUP_CODE,
                   EMPLOYEE_PAYMENT_PRIORITY,
                   XX_GL_PKG.CREATE_GET_GL_CCID (
                       COMPANY_CODE || '.' || BRANCH_CODE || '.999.12030301.99.999.999')
                       PREPAY_CODE_COMBINATION_ID,
                   CONFIRM_DATE_AS_INV_NUM_FLAG,
                   UPDATE_PAY_SITE_FLAG,
                   DEFAULT_EXCHANGE_RATE_TYPE,
                   GAIN_CODE_COMBINATION_ID,
                   LOSS_CODE_COMBINATION_ID,
                   MAKE_RATE_MANDATORY_FLAG,
                   MULTI_CURRENCY_FLAG,
                   GL_DATE_FROM_RECEIPT_FLAG,
                   DISC_IS_INV_LESS_TAX_FLAG,
                   MATCH_ON_TAX_FLAG,
                   ACCOUNTING_METHOD_OPTION,
                   EXPENSE_POST_OPTION,
                   DISCOUNT_TAKEN_POST_OPTION,
                   GAIN_LOSS_POST_OPTION,
                   CASH_POST_OPTION,
                   FUTURE_PAY_POST_OPTION,
                   DATE_FORMAT_LOOKUP_CODE,
                   REPLACE_CHECK_FLAG,
                   ONLINE_PRINT_FLAG,
                   EFT_USER_NUMBER,
                   MAX_OUTLAY,
                   VENDOR_PAY_GROUP_LOOKUP_CODE,
                   REQUIRE_TAX_ENTRY_FLAG,
                   APPROVALS_OPTION,
                   POST_DATED_PAYMENTS_FLAG,
                   SECONDARY_ACCOUNTING_METHOD,
                   SECONDARY_SET_OF_BOOKS_ID,
                   TAKE_VAT_BEFORE_DISCOUNT_FLAG,
                   INTEREST_TOLERANCE_AMOUNT,
                   INTEREST_CODE_COMBINATION_ID,
                   TERMS_DATE_BASIS,
                   ALLOW_FUTURE_PAY_FLAG,
                   AUTO_TAX_CALC_FLAG,
                   AUTOMATIC_OFFSETS_FLAG,
                   LIABILITY_POST_LOOKUP_CODE,
                   INTEREST_ACCTS_PAY_CCID,
                   LIABILITY_POST_OPTION,
                   DISCOUNT_DISTRIBUTION_METHOD,
                   RATE_VAR_CODE_COMBINATION_ID,
                   COMBINED_FILING_FLAG,
                   INCOME_TAX_REGION,
                   INCOME_TAX_REGION_FLAG,
                   HOLD_UNMATCHED_INVOICES_FLAG,
                   ALLOW_DIST_MATCH_FLAG,
                   ALLOW_FINAL_MATCH_FLAG,
                   ALLOW_FLEX_OVERRIDE_FLAG,
                   ALLOW_PAID_INVOICE_ADJUST,
                   USSGL_TRANSACTION_CODE,
                   USSGL_TRX_CODE_CONTEXT,
                   INV_DOC_CATEGORY_OVERRIDE,
                   PAY_DOC_CATEGORY_OVERRIDE,
                   VENDOR_AUTO_INT_DEFAULT,
                   SUMMARY_JOURNALS_DEFAULT,
                   RATE_VAR_GAIN_CCID,
                   RATE_VAR_LOSS_CCID,
                   TRANSFER_DESC_FLEX_FLAG,
                   ALLOW_AWT_FLAG,
                   DEFAULT_AWT_GROUP_ID,
                   ALLOW_AWT_OVERRIDE,
                   CREATE_AWT_DISTS_TYPE,
                   CREATE_AWT_INVOICES_TYPE,
                   AWT_INCLUDE_DISCOUNT_AMT,
                   AWT_INCLUDE_TAX_AMT,
                   OCB.ORG_ID,
                   RECON_ACCOUNTING_FLAG,
                   AUTO_CREATE_FREIGHT_FLAG,
                   FREIGHT_CODE_COMBINATION_ID,
                   GLOBAL_ATTRIBUTE_CATEGORY,
                   GLOBAL_ATTRIBUTE1,
                   GLOBAL_ATTRIBUTE2,
                   GLOBAL_ATTRIBUTE3,
                   GLOBAL_ATTRIBUTE4,
                   GLOBAL_ATTRIBUTE5,
                   GLOBAL_ATTRIBUTE6,
                   GLOBAL_ATTRIBUTE7,
                   GLOBAL_ATTRIBUTE8,
                   GLOBAL_ATTRIBUTE9,
                   GLOBAL_ATTRIBUTE10,
                   GLOBAL_ATTRIBUTE11,
                   GLOBAL_ATTRIBUTE12,
                   GLOBAL_ATTRIBUTE13,
                   GLOBAL_ATTRIBUTE14,
                   GLOBAL_ATTRIBUTE15,
                   GLOBAL_ATTRIBUTE16,
                   GLOBAL_ATTRIBUTE17,
                   GLOBAL_ATTRIBUTE18,
                   GLOBAL_ATTRIBUTE19,
                   GLOBAL_ATTRIBUTE20,
                   ALLOW_SUPPLIER_BANK_OVERRIDE,
                   USE_MULTIPLE_SUPPLIER_BANKS,
                   AUTO_TAX_CALC_OVERRIDE,
                   AMOUNT_INCLUDES_TAX_FLAG,
                   AMOUNT_INCLUDES_TAX_OVERRIDE,
                   VAT_CODE,
                   USE_BANK_CHARGE_FLAG,
                   BANK_CHARGE_BEARER,
                   ROUNDING_ERROR_CCID,
                   ROUNDING_ERROR_POST_OPTION,
                   TAX_FROM_PO_FLAG,
                   TAX_FROM_VENDOR_SITE_FLAG,
                   TAX_FROM_VENDOR_FLAG,
                   TAX_FROM_ACCOUNT_FLAG,
                   TAX_FROM_SYSTEM_FLAG,
                   TAX_FROM_INV_HEADER_FLAG,
                   TAX_FROM_TEMPLATE_FLAG,
                   TAX_HIER_PO_SHIPMENT,
                   TAX_HIER_VENDOR,
                   TAX_HIER_VENDOR_SITE,
                   TAX_HIER_ACCOUNT,
                   TAX_HIER_SYSTEM,
                   TAX_HIER_INVOICE,
                   TAX_HIER_TEMPLATE,
                   ENFORCE_TAX_FROM_ACCOUNT,
                   MRC_BASE_CURRENCY_CODE,
                   MRC_SECONDARY_SET_OF_BOOKS_ID,
                   MATCH_OPTION,
                   GAIN_LOSS_CALC_LEVEL,
                   WHEN_TO_ACCOUNT_PMT,
                   WHEN_TO_ACCOUNT_GAIN_LOSS,
                   FUTURE_DATED_PMT_ACCT_SOURCE,
                   FUTURE_DATED_PMT_LIAB_RELIEF,
                   GL_TRANSFER_ALLOW_OVERRIDE,
                   GL_TRANSFER_PROCESS_DAYS,
                   GL_TRANSFER_MODE,
                   GL_TRANSFER_SUBMIT_JOURNAL_IMP,
                   INCLUDE_REPORTING_SOB,
                   EXPENSE_REPORT_ID,
                   PREPAYMENT_TERMS_ID,
                   CALC_USER_XRATE,
                   SORT_BY_ALTERNATE_FIELD,
                   APPROVAL_WORKFLOW_FLAG,
                   ALLOW_FORCE_APPROVAL_FLAG,
                   VALIDATE_BEFORE_APPROVAL_FLAG,
                   XML_PAYMENTS_AUTO_CONFIRM_FLAG,
                   PRORATE_INT_INV_ACROSS_DISTS,
                   BUILD_PREPAYMENT_ACCOUNTS_FLAG,
                   ENABLE_1099_ON_AWT_FLAG,
                   STOP_PREPAY_ACROSS_BAL_FLAG,
                   AUTOMATIC_OFFSETS_CHANGE_FLAG,
                   TOLERANCE_ID,
                   PREPAY_TAX_DIFF_CCID,
                   CE_BANK_ACCT_USE_ID,
                   APPROVAL_TIMING,
                   SERVICES_TOLERANCE_ID,
                   RECEIPT_ACCEPTANCE_DAYS,
                   TAX_TOLERANCE,
                   TAX_TOL_AMT_RANGE,
                   ALLOW_INV_THIRD_PARTY_OVRD,
                   ALLOW_PYMT_THIRD_PARTY_OVRD,
                   WITHHOLDING_DATE_BASIS,
                   INVRATE_FOR_PREPAY_TAX
              FROM AP.AP_SYSTEM_PARAMETERS_ALL ASP, XX_ORG_COMPANY_BRANCH_V OCB
             WHERE     ASP.ORG_ID = 86
                   AND OCB.ORG_ID NOT IN (SELECT ORG_ID FROM AP.AP_SYSTEM_PARAMETERS_ALL)
                   AND PARENT_ORG <> 'LOG';


        -- Supplier Site for Cash Payment Supplier

        DECLARE
            V_RETURN_STATUS     VARCHAR2 (1);
            V_MSG_COUNT         NUMBER;
            V_MSG_DATA          VARCHAR2 (2000);
            V_VENDOR_SITE_ID    NUMBER (15);
            V_PARTY_SITE_ID     NUMBER (15);
            V_LOCATION_ID       NUMBER;
            V_VENDOR_SITE_REC   AP_VENDOR_PUB_PKG.R_VENDOR_SITE_REC_TYPE;

            CURSOR CUR IS
                  SELECT POV.VENDOR_ID,
                         POV.VENDOR_NAME,
                         PVS.PARTY_SITE_ID,
                         PVS.LOCATION_ID,
                         PVS.PURCHASING_SITE_FLAG,
                         PVS.PAY_SITE_FLAG,
                         PVS.ALLOW_AWT_FLAG,
                         PVS.INVOICE_CURRENCY_CODE,
                         PVS.PAYMENT_CURRENCY_CODE,
                         PVS.VENDOR_SITE_CODE,
                         HOU.ORGANIZATION_ID     ORG_ID
                    FROM PO_VENDORS POV, PO_VENDOR_SITES_ALL PVS, HR_OPERATING_UNITS HOU
                   WHERE     POV.VENDOR_ID = PVS.VENDOR_ID
                         AND POV.VENDOR_ID = 64
                         AND PVS.ORG_ID = 86
                         AND HOU.ORGANIZATION_ID <> 449
                         AND HOU.ORGANIZATION_ID NOT IN (SELECT ORG_ID FROM PO_VENDOR_SITES_ALL)
                ORDER BY HOU.ORGANIZATION_ID;
        BEGIN
            FOR REC IN CUR
            LOOP
                FND_CLIENT_INFO.SET_ORG_CONTEXT (REC.ORG_ID);

                V_VENDOR_SITE_REC.VENDOR_ID := REC.VENDOR_ID;
                V_VENDOR_SITE_REC.PARTY_SITE_ID := REC.PARTY_SITE_ID;
                V_VENDOR_SITE_REC.LOCATION_ID := REC.LOCATION_ID;
                V_VENDOR_SITE_REC.PURCHASING_SITE_FLAG := REC.PURCHASING_SITE_FLAG;
                V_VENDOR_SITE_REC.PAY_SITE_FLAG := REC.PAY_SITE_FLAG;
                V_VENDOR_SITE_REC.ALLOW_AWT_FLAG := REC.ALLOW_AWT_FLAG;
                V_VENDOR_SITE_REC.INVOICE_CURRENCY_CODE := REC.INVOICE_CURRENCY_CODE;
                V_VENDOR_SITE_REC.PAYMENT_CURRENCY_CODE := REC.PAYMENT_CURRENCY_CODE;
                V_VENDOR_SITE_REC.VENDOR_SITE_CODE := REC.VENDOR_SITE_CODE;
                V_VENDOR_SITE_REC.ORG_ID := REC.ORG_ID;

                AP_VENDOR_PUB_PKG.CREATE_VENDOR_SITE (P_API_VERSION       => 1.0,
                                                      P_VENDOR_SITE_REC   => V_VENDOR_SITE_REC,
                                                      X_VENDOR_SITE_ID    => V_VENDOR_SITE_ID,
                                                      X_PARTY_SITE_ID     => V_PARTY_SITE_ID,
                                                      X_LOCATION_ID       => V_LOCATION_ID,
                                                      X_RETURN_STATUS     => V_RETURN_STATUS,
                                                      X_MSG_COUNT         => V_MSG_COUNT,
                                                      X_MSG_DATA          => V_MSG_DATA);

                V_MSG_COUNT := FND_MSG_PUB.COUNT_MSG;

                IF V_MSG_COUNT > 1
                THEN
                    FOR I IN 1 .. V_MSG_COUNT
                    LOOP
                        INSERT INTO RASHED
                                 VALUES (
                                            REC.VENDOR_ID,
                                            (SUBSTR (FND_MSG_PUB.GET (P_ENCODED => FND_API.G_FALSE),
                                                     1,
                                                     255)));
                    END LOOP;
                END IF;
            END LOOP;

            COMMIT;
        END;

        BEGIN
            --Receivables
            FND_GLOBAL.APPS_INITIALIZE (USER_ID        => FND_GLOBAL.USER_ID,
                                        RESP_ID        => 50724,   -- Receivables Administrator, SCS
                                        RESP_APPL_ID   => 222);                       -- Receivables
            MO_GLOBAL.INIT ('AR');

            -- Update System Parameters

            UPDATE AR_SYSTEM_PARAMETERS_ALL
               SET DOCUMENT_SEQ_GEN_LEVEL = 'WHEN_TRX_COMPLETED',
                   ALLOW_LATE_CHARGES = 'N',
                   AUTO_SITE_NUMBERING = 'N',
                   SITE_REQUIRED_FLAG = 'N',
                   PRINT_REMIT_TO = 'N',
                   DEFAULT_CB_DUE_DATE = 'DUE_DATE',
                   DEFAULT_COUNTRY = 'BD',
                   RUN_GL_JOURNAL_IMPORT_FLAG = 'Y',
                   TAX_CURRENCY_CODE = 'BDT',
                   TAX_PRECISION = 2
             WHERE SET_OF_BOOKS_ID = 2021 AND TAX_CURRENCY_CODE IS NULL;

            -- Gain

            UPDATE AR_SYSTEM_PARAMETERS_ALL ARS
               SET ARS.CODE_COMBINATION_ID_GAIN =
                       (SELECT XX_GL_PKG.CREATE_GET_GL_CCID (
                                      OCB.COMPANY_CODE
                                   || '.'
                                   || OCB.BRANCH_CODE
                                   || '.999.52050301.60.999.999')
                          FROM XX_ORG_COMPANY_BRANCH_V OCB
                         WHERE ARS.ORG_ID = OCB.ORG_ID AND OCB.COMPANY_NAME IS NOT NULL)
             WHERE NVL (ARS.ORG_ID, 0) > 0 AND ARS.CODE_COMBINATION_ID_GAIN IS NULL;

            -- Loss

            UPDATE AR_SYSTEM_PARAMETERS_ALL
               SET CODE_COMBINATION_ID_LOSS = CODE_COMBINATION_ID_GAIN
             WHERE     NVL (CODE_COMBINATION_ID_LOSS, -1) <> NVL (CODE_COMBINATION_ID_GAIN, -2)
                   AND SET_OF_BOOKS_ID = 2021;

            --Tax Account

            UPDATE AR_SYSTEM_PARAMETERS_ALL ARS
               SET ARS.LOCATION_TAX_ACCOUNT =
                       (SELECT XX_GL_PKG.CREATE_GET_GL_CCID (
                                      OCB.COMPANY_CODE
                                   || '.'
                                   || OCB.BRANCH_CODE
                                   || '.999.53012124.10.999.999')
                          FROM XX_ORG_COMPANY_BRANCH_V OCB
                         WHERE ARS.ORG_ID = OCB.ORG_ID AND OCB.COMPANY_NAME IS NOT NULL)
             WHERE NVL (ARS.ORG_ID, 0) > 0 AND ARS.LOCATION_TAX_ACCOUNT IS NULL;

            --Rate Type

            UPDATE AR_SYSTEM_PARAMETERS_ALL
               SET CROSS_CURRENCY_RATE_TYPE = 'User'
             WHERE NVL (CROSS_CURRENCY_RATE_TYPE, 'XX') <> 'User' AND SET_OF_BOOKS_ID = 2021;

            --Rounding

            UPDATE AR_SYSTEM_PARAMETERS_ALL ARS
               SET ARS.CODE_COMBINATION_ID_ROUND =
                       (SELECT XX_GL_PKG.CREATE_GET_GL_CCID (
                                      OCB.COMPANY_CODE
                                   || '.'
                                   || OCB.BRANCH_CODE
                                   || '.999.12110505.99.999.999')
                          FROM XX_ORG_COMPANY_BRANCH_V OCB
                         WHERE ARS.ORG_ID = OCB.ORG_ID AND OCB.COMPANY_NAME IS NOT NULL)
             WHERE NVL (ARS.ORG_ID, 0) > 0 AND ARS.CODE_COMBINATION_ID_ROUND IS NULL;

            UPDATE RA_CUST_TRX_TYPES_ALL
               SET DEFAULT_TERM = 5
             WHERE ORG_ID >= 0 AND CUST_TRX_TYPE_ID = 1 AND NVL (DEFAULT_TERM, 0) <> 5;

            UPDATE RA_CUST_TRX_TYPES_ALL
               SET DEFAULT_TERM = 5
             WHERE ORG_ID >= 0 AND CUST_TRX_TYPE_ID = 2 AND NVL (DEFAULT_TERM, 0) <> 5;

            UPDATE RA_CUST_TRX_TYPES_ALL CTT
               SET CTT.GL_ID_REC =
                       (SELECT XX_GL_PKG.CREATE_GET_GL_CCID (
                                      OCB.COMPANY_CODE
                                   || '.'
                                   || OCB.BRANCH_CODE
                                   || '.999.12020101.99.999.999')
                          FROM XX_ORG_COMPANY_BRANCH_V OCB
                         WHERE CTT.ORG_ID = OCB.ORG_ID AND OCB.COMPANY_NAME IS NOT NULL)
             WHERE     CTT.NAME = 'Invoice'
                   AND CTT.GL_ID_REC IS NULL
                   AND CTT.SET_OF_BOOKS_ID IS NOT NULL;

            UPDATE RA_CUST_TRX_TYPES_ALL CTT
               SET CTT.GL_ID_REV =
                       (SELECT XX_GL_PKG.CREATE_GET_GL_CCID (
                                      OCB.COMPANY_CODE
                                   || '.'
                                   || OCB.BRANCH_CODE
                                   || '.999.41010101.99.999.999')
                          FROM XX_ORG_COMPANY_BRANCH_V OCB
                         WHERE CTT.ORG_ID = OCB.ORG_ID AND OCB.COMPANY_NAME IS NOT NULL)
             WHERE     CTT.NAME = 'Invoice'
                   AND CTT.GL_ID_REV IS NULL
                   AND CTT.SET_OF_BOOKS_ID IS NOT NULL;

            UPDATE RA_CUST_TRX_TYPES_ALL CTT
               SET CTT.GL_ID_REC =
                       (SELECT XX_GL_PKG.CREATE_GET_GL_CCID (
                                      OCB.COMPANY_CODE
                                   || '.'
                                   || OCB.BRANCH_CODE
                                   || '.999.12020101.99.999.999')
                          FROM XX_ORG_COMPANY_BRANCH_V OCB
                         WHERE CTT.ORG_ID = OCB.ORG_ID AND OCB.COMPANY_NAME IS NOT NULL)
             WHERE     CTT.NAME = 'Credit Memo'
                   AND CTT.GL_ID_REC IS NULL
                   AND CTT.SET_OF_BOOKS_ID IS NOT NULL;

            UPDATE RA_CUST_TRX_TYPES_ALL CTT
               SET CTT.GL_ID_REV =
                       (SELECT XX_GL_PKG.CREATE_GET_GL_CCID (
                                      OCB.COMPANY_CODE
                                   || '.'
                                   || OCB.BRANCH_CODE
                                   || '.999.41010101.99.999.999')
                          FROM XX_ORG_COMPANY_BRANCH_V OCB
                         WHERE CTT.ORG_ID = OCB.ORG_ID AND OCB.COMPANY_NAME IS NOT NULL)
             WHERE     CTT.NAME = 'Credit Memo'
                   AND CTT.GL_ID_REV IS NULL
                   AND CTT.SET_OF_BOOKS_ID IS NOT NULL;

            UPDATE RA_CUST_TRX_TYPES_ALL
               SET ALLOW_OVERAPPLICATION_FLAG = 'N'
             WHERE     NVL (ORG_ID, 0) > 0
                   AND CUST_TRX_TYPE_ID IN (1, 2)
                   AND NVL (ALLOW_OVERAPPLICATION_FLAG, 'N') <> 'N';

            -- Batch Source

            UPDATE RA_BATCH_SOURCES_ALL
               SET COPY_DOC_NUMBER_FLAG = 'Y'
             WHERE     ORG_ID >= 0
                   AND NVL (COPY_DOC_NUMBER_FLAG, 'X') <> 'Y'
                   AND DESCRIPTION = 'Manual Order Entry';

            UPDATE RA_BATCH_SOURCES_ALL
               SET NAME = XX_COM_PKG.GET_HR_OPERATING_UNIT (ORG_ID)
             WHERE     ORG_ID >= 0
                   AND NAME <> XX_COM_PKG.GET_HR_OPERATING_UNIT (ORG_ID)
                   AND DESCRIPTION = 'Manual Order Entry';

            -- Add branch Access for To Pay Sales
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
                        FROM HZ_PARTIES             HZP,
                             HZ_CUST_ACCOUNTS       HCA,
                             HZ_PARTY_SITES         HPS,
                             XX_TO_PAY_DEPARTMENTS_V DEP,
                             XX_ORG_COMPANY_BRANCH_V OCB
                       WHERE     HZP.PARTY_ID = HCA.PARTY_ID
                             AND HCA.PARTY_ID = HPS.PARTY_ID
                             AND UPPER (HCA.ACCOUNT_NAME) = UPPER (DEP.DESCRIPTION)
                             AND DEP.COMPANY = OCB.PARENT_ORG
                             AND HZP.PARTY_ID = 15330
                             AND HZP.PARTY_NAME = 'To Pay Sales'
                             AND OCB.BRANCH_CODE <> '999'
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
             WHERE GL_ID_REC IS NULL;

            UPDATE HZ_CUST_SITE_USES_ALL
               SET GL_ID_REV = XX_AR_PKG.GL_ID_REV (CUST_ACCT_SITE_ID)
             WHERE GL_ID_REV IS NULL;

            -- Add branch Access for Cash Sales

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
                        FROM HZ_PARTIES             HZP,
                             HZ_CUST_ACCOUNTS       HCA,
                             HZ_PARTY_SITES         HPS,
                             XX_CASH_DEPARTMENTS_V  DEP,
                             XX_ORG_COMPANY_BRANCH_V OCB
                       WHERE     HZP.PARTY_ID = HCA.PARTY_ID
                             AND HCA.PARTY_ID = HPS.PARTY_ID
                             AND UPPER (HCA.ACCOUNT_NAME) = UPPER (DEP.DESCRIPTION)
                             AND DEP.COMPANY = OCB.PARENT_ORG
                             AND HZP.PARTY_ID = 4163
                             AND HZP.PARTY_NAME = 'Cash Sales'
                             AND OCB.BRANCH_CODE <> '999'
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
             WHERE GL_ID_REC IS NULL;

            UPDATE HZ_CUST_SITE_USES_ALL
               SET GL_ID_REV = XX_AR_PKG.GL_ID_REV (CUST_ACCT_SITE_ID)
             WHERE GL_ID_REV IS NULL;

            COMMIT;
        END;

        BEGIN
            -- Cash Management

            FND_GLOBAL.APPS_INITIALIZE (USER_ID        => FND_GLOBAL.USER_ID,
                                        RESP_ID        => 50727, -- Cash Management Administrator, SCS
                                        RESP_APPL_ID   => 260);                       -- Receivables
            MO_GLOBAL.INIT ('CE');



            -- Cash Bank Account Access

            DECLARE
                V_ACCT_USE_ID     NUMBER;
                V_RETURN_STATUS   VARCHAR2 (1);
                V_MSG_COUNT       NUMBER;
                V_MSG_DATA        VARCHAR2 (4000);
                P_ACCT_USE_REC    CE_BANK_PUB.BANKACCT_USE_REC_TYPE;

                CURSOR CUR IS
                      SELECT CB.ORG_ID,
                             BB.BANK_PARTY_ID
                                 BANK_ID,
                             BB.BRANCH_PARTY_ID
                                 BANK_BRANCH_ID,
                             CA.BANK_ACCOUNT_ID,
                             CA.BANK_ACCOUNT_NAME,
                             CB.PARENT_ORG,
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
                             AND CA.BANK_ACCOUNT_ID BETWEEN 11017 AND 11025
                             AND (CASE
                                      WHEN     CA.BANK_ACCOUNT_NAME LIKE '%DHK%SCS%Cash%'
                                           AND CB.PARENT_ORG = 'SCS'
                                      THEN
                                          1
                                      WHEN     CA.BANK_ACCOUNT_NAME LIKE '%DHK%SETS%Cash%'
                                           AND CB.PARENT_ORG = 'SETS'
                                      THEN
                                          1
                                      WHEN     CA.BANK_ACCOUNT_NAME LIKE '%DHK%VD%Cash%'
                                           AND CB.PARENT_ORG = 'VD'
                                      THEN
                                          1
                                      ELSE
                                          0
                                  END) =
                                 1
                             AND NOT EXISTS
                                     (SELECT 1
                                        FROM CE_BANK_ACCT_USES_ALL AU
                                       WHERE     CA.BANK_ACCOUNT_ID = AU.BANK_ACCOUNT_ID
                                             AND CB.ORG_ID = AU.ORG_ID)
                    ORDER BY CA.BANK_ACCOUNT_ID, CB.ORG_ID;
            BEGIN
                FOR REC IN CUR
                LOOP
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
                END LOOP;
            END;

            -- Update Bank Account

            UPDATE CE_BANK_ACCT_USES_ALL
               SET PAYMENT_DOC_CATEGORY = 'CHECK PAY'
             WHERE NVL (PAYMENT_DOC_CATEGORY, 'XX') <> 'CHECK PAY';

            -- Update AP and AR Use


            UPDATE CE_BANK_ACCT_USES_ALL
               SET AR_USE_ENABLE_FLAG = NULL
             WHERE     AR_USE_ENABLE_FLAG IS NOT NULL
                   AND BANK_ACCOUNT_ID IN (SELECT BANK_ACCOUNT_ID
                                             FROM CE_BANK_ACCOUNTS
                                            WHERE BANK_ACCOUNT_NAME LIKE '%Payment%');



            UPDATE CE_BANK_ACCT_USES_ALL
               SET AP_USE_ENABLE_FLAG = NULL
             WHERE     AP_USE_ENABLE_FLAG IS NOT NULL
                   AND BANK_ACCOUNT_ID IN (SELECT BANK_ACCOUNT_ID
                                             FROM CE_BANK_ACCOUNTS
                                            WHERE BANK_ACCOUNT_NAME LIKE '%Receipt%');

            COMMIT;
            /* -- Create Operating Unit From Inventory

  SELECT FFV.FLEX_VALUE || '-' || FFV.DESCRIPTION || ' - ' || OCB.PARENT_ORG    UNIT_NAME,
         'TAB',
         'TAB',
         TO_CHAR (START_DATE_ACTIVE, 'DD-MON-RRRR')                             START_DATE,
         'TAB',
         'TAB',
         'Corporate',
         'TAB',
         'TAB',
         'ENT',
         '*SAVE',
         'TAB',
         'Operating Unit'                                                       OPERATING_UNIT,
         'TAB',
         '*SB',
         '*SAVE',
         '*AO',
         'ENT',
         'TAB',
         'SCS',
         'TAB',
         CASE
             WHEN PARENT_ORG <> 'SCS' THEN 'Sundarban Express Transportation System (SETS) Ltd.'
             ELSE 'Sundarban Courier Service (Pvt.) Ltd.'
         END                                                                    COMPANY_NAME,
         'TAB',
         FFV.FLEX_VALUE || '-' || OCB.PARENT_ORG                                UNIT_CODE,
         '*AO',
         '*SAVE',
         'ENT',
         '*SP'
    FROM FND_FLEX_VALUES_VL FFV, XX_ORG_COMPANY_BRANCH_V OCB
   WHERE     FFV.FLEX_VALUE_SET_ID = 1016492
         AND FFV.FLEX_VALUE <> '999'
         AND OCB.BRANCH_CODE = '999'
         AND OCB.PARENT_ORG <> 'LOG'
         AND NOT EXISTS
                 (SELECT 1
                    FROM XX_ORG_COMPANY_BRANCH_V ARE
                   WHERE     FFV.FLEX_VALUE = ARE.BRANCH_CODE
                         AND OCB.PARENT_ORG = ARE.PARENT_ORG
                         AND ARE.BRANCH_CODE <> '999')
ORDER BY FFV.FLEX_VALUE, OCB.COMPANY_CODE;


  SELECT *
    FROM HR_OPERATING_UNITS
ORDER BY ORGANIZATION_ID DESC;

  -- Run Replicate Seed Data from Toad

DECLARE
    P_REQUEST_ID   NUMBER;

    CURSOR CUR IS
          SELECT HOU.ORGANIZATION_ID     ORG_ID
            FROM HR_OPERATING_UNITS HOU
           WHERE NOT EXISTS
                     (SELECT 1
                        FROM AR_SYSTEM_PARAMETERS_ALL ASP
                       WHERE HOU.ORGANIZATION_ID = ASP.ORG_ID)
        ORDER BY HOU.ORGANIZATION_ID;
BEGIN
    FOR REC IN CUR
    LOOP
        FND_GLOBAL.APPS_INITIALIZE (1111, 20420, 1);
        P_REQUEST_ID :=
            FND_REQUEST.SUBMIT_REQUEST (APPLICATION   => 'AK',
                                        PROGRAM       => 'AKXMOSED',
                                        DESCRIPTION   => NULL,
                                        START_TIME    => SYSDATE,
                                        SUB_REQUEST   => FALSE,
                                        ARGUMENT1     => REC.ORG_ID);
    END LOOP;
END;

COMMIT;

-- Complete Tax Setup

-- Complete Receivable Activities

--Earned Discount

  SELECT OCB.ORG_NAME,
         'TAB',
         'Earned Discount',
         'TAB',
         'TAB',
         '*DN',
         '*DN',
         'TAB',
         'TAB',
         'TAB',
         'TAB',
         (OCB.COMPANY_CODE || '.' || OCB.BRANCH_CODE || '.999.53014941.10.999.999')     GL_ACCOUNT,
         '*SP'
    FROM XX_ORG_COMPANY_BRANCH_V OCB
   WHERE NOT EXISTS
             (SELECT 1
                FROM AR_RECEIVABLES_TRX_ALL ART
               WHERE OCB.ORG_ID = ART.ORG_ID AND ART.TYPE = 'EDISC')
ORDER BY OCB.ORG_ID;

--Unearned Discount

  SELECT OCB.ORG_NAME,
         'TAB',
         'Unearned Discount',
         'TAB',
         'TAB',
         '*AU',
         'TAB',
         'TAB',
         'TAB',
         'TAB',
         (OCB.COMPANY_CODE || '.' || OCB.BRANCH_CODE || '.999.53014941.10.999.999')     GL_ACCOUNT,
         '*SP'
    FROM XX_ORG_COMPANY_BRANCH_V OCB
   WHERE NOT EXISTS
             (SELECT 1
                FROM AR_RECEIVABLES_TRX_ALL ART
               WHERE OCB.ORG_ID = ART.ORG_ID AND ART.TYPE = 'UNEDISC')
ORDER BY OCB.ORG_ID;

--Miscellaneous Income

  SELECT OCB.ORG_NAME,
         'TAB',
         'Miscellaneous Income',
         'TAB',
         'TAB',
         '*AM',
         'TAB',
         'TAB',
         'TAB',
         'TAB',
         (OCB.COMPANY_CODE || '.' || OCB.BRANCH_CODE || '.451.42490151.99.999.999')     GL_ACCOUNT,
         '*SP'
    FROM XX_ORG_COMPANY_BRANCH_V OCB
   WHERE NOT EXISTS
             (SELECT 1
                FROM AR_RECEIVABLES_TRX_ALL ART
               WHERE OCB.ORG_ID = ART.ORG_ID AND ART.TYPE = 'MISCCASH')
ORDER BY OCB.ORG_ID;

--Refund

  SELECT OCB.ORG_NAME,
         'TAB',
         'Refund',
         'TAB',
         'TAB',
         '*AR',
         '*AR',
         'TAB',
         'TAB',
         'TAB',
         'TAB',
         (OCB.COMPANY_CODE || '.' || OCB.BRANCH_CODE || '.999.22010702.99.999.999')     GL_ACCOUNT,
         '*SP'
    FROM XX_ORG_COMPANY_BRANCH_V OCB
   WHERE     OCB.BRANCH_CODE NOT IN ('999', 'LOG')
         AND NOT EXISTS
                 (SELECT 1
                    FROM AR_RECEIVABLES_TRX_ALL ART
                   WHERE OCB.ORG_ID = ART.ORG_ID AND ART.TYPE = 'CM_REFUND')
ORDER BY OCB.ORG_ID;


 --Auto Accounting
 -- Receivables

  SELECT HOU.NAME,
         'TAB',
         'Receivable',
         'TAB',
         'Transaction Types',
         '*DN',
         'Transaction Types',
         '*DN',
         'Site',
         '*DN',
         'Transaction Types',
         '*DN',
         'Transaction Types',
         '*DN',
         'Transaction Types',
         '*DN',
         'Transaction Types',
         '*SP',
         'ENT'
    FROM HR_OPERATING_UNITS HOU
   WHERE NOT EXISTS
             (SELECT 1
                FROM RA_ACCOUNT_DEFAULTS_ALL RAD
               WHERE HOU.ORGANIZATION_ID = RAD.ORG_ID AND RAD.TYPE = 'REC')
ORDER BY HOU.ORGANIZATION_ID;

-- Revenue

  SELECT HOU.NAME,
         'TAB',
         'Revenue',
         'TAB',
         'Transaction Types',
         '*DN',
         'Transaction Types',
         '*DN',
         'Site',
         '*DN',
         'Transaction Types',
         '*DN',
         'Transaction Types',
         '*DN',
         'Standard Lines',
         '*DN',
         'Transaction Types',
         '*SP',
         'ENT'
    FROM HR_OPERATING_UNITS HOU
   WHERE NOT EXISTS
             (SELECT 1
                FROM RA_ACCOUNT_DEFAULTS_ALL RAD
               WHERE HOU.ORGANIZATION_ID = RAD.ORG_ID AND RAD.TYPE = 'REV')
ORDER BY HOU.ORGANIZATION_ID;

  SELECT DISTINCT SEGMENT_NUM, SEGMENT, TABLE_NAME
    FROM RA_ACCOUNT_DEFAULT_SEGMENTS
   WHERE GL_DEFAULT_ID IN (SELECT GL_DEFAULT_ID
                             FROM RA_ACCOUNT_DEFAULTS_ALL
                            WHERE TYPE = 'REC')
ORDER BY 1;

  SELECT DISTINCT SEGMENT_NUM, SEGMENT, TABLE_NAME
    FROM RA_ACCOUNT_DEFAULT_SEGMENTS
   WHERE GL_DEFAULT_ID IN (SELECT GL_DEFAULT_ID
                             FROM RA_ACCOUNT_DEFAULTS_ALL
                            WHERE TYPE = 'REV')
ORDER BY 1;

--OM System Parameters -- issue found

  SELECT HOU.NAME,
         'TAB',
         '*ML(235, 235)',
         '*QE',
         'Item Validation Organization',
         '*QR',
         'SUNDARBAN ITEM MASTER ORG',
         '*SP',
         'ENT'
    FROM HR_OPERATING_UNITS HOU
   WHERE NOT EXISTS
             (SELECT 1
                FROM OE_SYS_PARAMETERS_ALL OSM
               WHERE     OSM.PARAMETER_CODE = 'MASTER_ORGANIZATION_ID'
                     AND OSM.PARAMETER_VALUE = 85
                     AND HOU.ORGANIZATION_ID = OSM.ORG_ID)
ORDER BY HOU.ORGANIZATION_ID;

-- Run request (XX Upload New Branch) from Receivables

 -- Receipt Class

  SELECT XX_COM_PKG.GET_HR_OPERATING_UNIT (BAU.ORG_ID)     ORG_NAME,
         'TAB',
         'Cash in Hand',
         'TAB',
         'ENT',
         'DHK',
         'TAB',
         CBA.BANK_ACCOUNT_NUM,
         'TAB',
         'TAB',
         'TAB',
         '1-Jul-20',
         'TAB',
         'TAB',
         '*SB',
         'TAB',
         'TAB',
         'TAB',
         'TAB',
         'TAB',
         'TAB',
         'TAB',
         'Unearned Discount',
         'TAB',
         'Earned Discount',
         '*SAVE',
         '*DN'
    FROM CE_BANK_ACCOUNTS CBA, CE_BANK_ACCT_USES_ALL BAU
   WHERE     CBA.BANK_ACCOUNT_ID = BAU.BANK_ACCOUNT_ID
         AND CBA.BANK_ACCOUNT_ID IN (11017, 11019, 11021)
         AND CBA.BANK_ACCOUNT_NAME LIKE '%Rec%'
         AND CBA.BANK_ACCOUNT_NUM = 'DHK-SCS-Cash-Receipt '
         AND NOT EXISTS
                 (SELECT 1
                    FROM AR_RECEIPT_METHOD_ACCOUNTS_ALL RMA
                   WHERE     BAU.BANK_ACCT_USE_ID = RMA.REMIT_BANK_ACCT_USE_ID
                         AND BAU.ORG_ID = RMA.ORG_ID)
ORDER BY BAU.ORG_ID;*/


        END;
    END;
END;
/