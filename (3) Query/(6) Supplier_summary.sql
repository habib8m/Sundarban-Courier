WITH DEBIT_BALANCE
     AS (  SELECT S.SEGMENT1,
                  S.VENDOR_NAME,
                  S.CREATION_DATE,
                  XX_COM_PKG.GET_HR_OPERATING_UNIT (I.ORG_ID) OPERATING_UNITS,
                  NVL (SUM (IP.AMOUNT), 0) AS DEBIT_AMOUNT
             FROM AP_SUPPLIERS S,
                  AP_INVOICES_ALL I,
                  AP_INVOICE_PAYMENTS_ALL IP,
                  AP_CHECKS_ALL C
            WHERE     S.VENDOR_ID = I.VENDOR_ID
                  AND I.INVOICE_ID = IP.INVOICE_ID
                  AND IP.CHECK_ID = C.CHECK_ID
                  AND C.STATUS_LOOKUP_CODE <> 'VOIDED'
                  AND NVL (IP.REVERSAL_FLAG, 'N') <> 'Y'
                  AND I.INVOICE_AMOUNT <> 0
                  AND C.AMOUNT <> 0
                  AND S.SEGMENT1 = :P_SUPPLIER_NO                      --10041
                  AND I.ORG_ID = NVL ( :P_ORG_ID, I.ORG_ID)              --205
                  AND IP.ACCOUNTING_DATE <
                         NVL ( :P_START_DATE,
                              TO_CHAR (S.CREATION_DATE, 'DD-MON-YY')) --'01-JAN-2024'
         GROUP BY S.SEGMENT1,
                  S.VENDOR_NAME,
                  S.CREATION_DATE,
                  I.ORG_ID),
     CREDIT_BALANCE
     AS (  SELECT S.SEGMENT1,
                  S.VENDOR_NAME,
                  S.CREATION_DATE,
                  XX_COM_PKG.GET_HR_OPERATING_UNIT (I.ORG_ID) OPERATING_UNITS,
                  NVL (SUM (ID.AMOUNT), 0) AS CREDIT_AMOUNT
             FROM AP_SUPPLIERS S,
                  AP_INVOICES_ALL I,
                  AP_INVOICE_DISTRIBUTIONS_ALL ID
            WHERE     S.VENDOR_ID = I.VENDOR_ID
                  AND I.INVOICE_ID = ID.INVOICE_ID
                  AND I.INVOICE_AMOUNT <> 0
                  AND ID.AMOUNT <> 0
                  AND NVL (ID.REVERSAL_FLAG, 'N') <> 'Y'
                  AND S.SEGMENT1 = :P_SUPPLIER_NO                      --10041
                  AND I.ORG_ID = NVL ( :P_ORG_ID, I.ORG_ID)              --205
                  AND I.GL_DATE <
                         NVL ( :P_START_DATE,
                              TO_CHAR (S.CREATION_DATE, 'DD-MON-YY')) --'01-JAN-2024'
                  AND I.PAYMENT_STATUS_FLAG <> 'N'
         GROUP BY S.SEGMENT1,
                  S.VENDOR_NAME,
                  S.CREATION_DATE,
                  I.ORG_ID),
     OPENING_BALANCE
     AS (SELECT DB.SEGMENT1,
                DB.VENDOR_NAME,
                DB.CREATION_DATE,
                DB.OPERATING_UNITS,
                ABS (NVL (DB.DEBIT_AMOUNT, 0) - NVL (CB.CREDIT_AMOUNT, 0))
                   AS BALANCE
           FROM DEBIT_BALANCE DB, CREDIT_BALANCE CB
          WHERE 1 = 1),
     ALL_TRANSACTIONS
     AS (SELECT 'DEBIT' AS TRANS_TYPE,
                --IP.ACCOUNTING_DATE AS TRANS_DATE,
                S.SEGMENT1 AS SUPPLIER_NUMBER,
                S.VENDOR_NAME AS SUPPLIER_NAME,
                XX_COM_PKG.GET_HR_OPERATING_UNIT (I.ORG_ID)
                   AS OPERATING_UNITS,
                IP.ACCOUNTING_DATE AS GL_DATE,
                S.CREATION_DATE,
                C.DOC_SEQUENCE_VALUE AS VOUCHER_NUMBER,
                TO_CHAR (C.CHECK_NUMBER) AS REFERENCE,
                I.INVOICE_TYPE_LOOKUP_CODE AS INV_TYPE,
                FV.FLEX_VALUE || ' - ' || FV.DESCRIPTION AS GL_DESCRIPTION,
                NULL AS DESCRIPTION,
                BA.BANK_ACCOUNT_NUM AS ACCOUNT_NUMBER,
                IP.AMOUNT AS DEBIT_AMOUNT,
                0 AS CREDIT_AMOUNT
           --IP.AMOUNT AS TRANS_AMOUNT
           FROM AP_SUPPLIERS S,
                AP_INVOICES_ALL I,
                AP_INVOICE_PAYMENTS_ALL IP,
                AP_CHECKS_ALL C,
                GL_CODE_COMBINATIONS GCC,
                FND_FLEX_VALUES_VL FV,
                CE_BANK_ACCT_USES_ALL BAU,
                CE_BANK_ACCOUNTS BA
          WHERE     S.VENDOR_ID = I.VENDOR_ID
                AND I.INVOICE_ID = IP.INVOICE_ID
                AND IP.CHECK_ID = C.CHECK_ID
                AND GCC.CODE_COMBINATION_ID = BA.ASSET_CODE_COMBINATION_ID
                AND GCC.SEGMENT4 = FV.FLEX_VALUE
                AND C.CE_BANK_ACCT_USE_ID = BAU.BANK_ACCT_USE_ID
                AND BAU.BANK_ACCOUNT_ID = BA.BANK_ACCOUNT_ID
                AND C.STATUS_LOOKUP_CODE <> 'VOIDED'
                AND NVL (IP.REVERSAL_FLAG, 'N') <> 'Y'
                AND I.INVOICE_AMOUNT <> 0
                AND C.AMOUNT <> 0
                AND S.SEGMENT1 = :P_SUPPLIER_NO
                AND I.ORG_ID = NVL ( :P_ORG_ID, I.ORG_ID)
                AND IP.ACCOUNTING_DATE BETWEEN NVL (
                                                  :P_START_DATE,
                                                  TO_CHAR (S.CREATION_DATE,
                                                           'DD-MON-YY'))
                                           AND NVL ( :P_END_DATE, SYSDATE)
         UNION ALL
         SELECT 'CREDIT' AS TRANS_TYPE,
                --I.GL_DATE AS TRANS_DATE,
                S.SEGMENT1 AS SUPPLIER_NUMBER,
                S.VENDOR_NAME AS SUPPLIER_NAME,
                XX_COM_PKG.GET_HR_OPERATING_UNIT (I.ORG_ID)
                   AS OPERATING_UNITS,
                I.GL_DATE AS GL_DATE,
                S.CREATION_DATE,
                I.DOC_SEQUENCE_VALUE AS VOUCHER_NUMBER,
                TO_CHAR (I.INVOICE_NUM) AS REFERENCE,
                I.INVOICE_TYPE_LOOKUP_CODE AS INV_TYPE,
                FV.FLEX_VALUE || ' - ' || FV.DESCRIPTION AS GL_DESCRIPTION,
                TO_CHAR (ID.DESCRIPTION) AS DESCRIPTION,
                NULL AS ACCOUNT_NUMBER,
                0 AS DEBIT_AMOUNT,
                ID.AMOUNT AS CREDIT_AMOUNT
           --ID.AMOUNT AS TRANS_AMOUNT
           FROM AP_SUPPLIERS S,
                AP_INVOICES_ALL I,
                AP_INVOICE_DISTRIBUTIONS_ALL ID,
                GL_CODE_COMBINATIONS GCC,
                FND_FLEX_VALUES_VL FV
          WHERE     S.VENDOR_ID = I.VENDOR_ID
                AND I.INVOICE_ID = ID.INVOICE_ID
                AND ID.DIST_CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
                AND GCC.SEGMENT4 = FV.FLEX_VALUE
                AND I.INVOICE_AMOUNT <> 0
                AND ID.AMOUNT <> 0
                AND NVL (ID.REVERSAL_FLAG, 'N') <> 'Y'
                AND S.SEGMENT1 = :P_SUPPLIER_NO
                AND I.ORG_ID = NVL ( :P_ORG_ID, I.ORG_ID)
                AND I.GL_DATE BETWEEN NVL (
                                         :P_START_DATE,
                                         TO_CHAR (S.CREATION_DATE,
                                                  'DD-MON-YY'))
                                  AND NVL ( :P_END_DATE, SYSDATE)
                AND I.PAYMENT_STATUS_FLAG <> 'N')
SELECT 0 AS SL,
       SEGMENT1 AS SUPPLIER_NUMBER,
       VENDOR_NAME AS SUPPLIER_NAME,
       NVL ( :P_START_DATE, TO_CHAR (CREATION_DATE, 'DD-MON-YY'))
          AS START_DATE,
       NVL ( :P_END_DATE, SYSDATE) AS END_DATE,
       OPERATING_UNITS,
       NULL AS GL_DATE,
       NULL AS VOUCHER_NUMBER,
       NULL AS REFERENCE,
       NULL AS INV_TYPE,
       NULL AS GL_DESCRIPTION,
       'OPENING BALANCE' AS DESCRIPTION,
       NULL AS ACCOUNT_NUMBER,
       0 AS DEBIT_AMOUNT,
       0 AS CREDIT_AMOUNT,
       NVL (BALANCE, 0) BALANCE
  FROM OPENING_BALANCE
UNION ALL
SELECT ROW_NUMBER () OVER (ORDER BY GL_DATE, VOUCHER_NUMBER) AS SL,
       SUPPLIER_NUMBER,
       SUPPLIER_NAME,
       NVL ( :P_START_DATE, TO_CHAR (CREATION_DATE, 'DD-MON-YY'))
          AS START_DATE,
       NVL ( :P_END_DATE, SYSDATE) AS END_DATE,
       OPERATING_UNITS,
       GL_DATE,
       VOUCHER_NUMBER,
       REFERENCE,
       INV_TYPE,
       GL_DESCRIPTION,
       DESCRIPTION,
       ACCOUNT_NUMBER,
       DEBIT_AMOUNT,
       CREDIT_AMOUNT,
         (SELECT BALANCE
            FROM OPENING_BALANCE)
       - SUM (DEBIT_AMOUNT)
            OVER (ORDER BY GL_DATE, VOUCHER_NUMBER ROWS UNBOUNDED PRECEDING)
       + SUM (CREDIT_AMOUNT)
            OVER (ORDER BY GL_DATE, VOUCHER_NUMBER ROWS UNBOUNDED PRECEDING)
          AS BALANCE
  FROM ALL_TRANSACTIONS
ORDER BY SL;
