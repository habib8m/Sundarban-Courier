DROP VIEW APPS.XX_AP_SUPPLIER_LEDGER_V;

/* Formatted on 01/Oct/24 3:22:57 PM (QP5 v5.287) */
CREATE OR REPLACE FORCE VIEW APPS.XX_AP_SUPPLIER_LEDGER_V
(
   SL,
   LEGAL_ENTITY_ID,
   BAL_SEG,
   ORG_ID,
   INVOICE_ID,
   ACCOUNTING_DATE,
   PARTY_ID,
   VENDOR_TYPE,
   VENDOR_GROUP,
   VENDOR_ID,
   PARTY_NUM,
   EMPLOYEE_ID,
   INV_TYPE,
   INVOICE_NUM,
   VOUCHER,
   DESCRIPTION,
   DIST_GL_CODE,
   GL_CODE_AND_DESC,
   BAL_SEG_NAME,
   ACCOUNT_NUM,
   DR_AMOUNT,
   CR_AMOUNT
)
   BEQUEATH DEFINER
AS
     SELECT 1,
            AI.LEGAL_ENTITY_ID,
            GC.SEGMENT1,
            AI.ORG_ID,
            AI.INVOICE_ID,
            TRUNC (AD.ACCOUNTING_DATE),
            AI.PARTY_ID,
            AV.VENDOR_TYPE_LOOKUP_CODE,
            AV.ATTRIBUTE13,
            AV.VENDOR_ID,
            AV.SEGMENT1,
            AV.EMPLOYEE_ID,
            INITCAP (AI.INVOICE_TYPE_LOOKUP_CODE),
            AI.INVOICE_NUM,
            AI.DOC_SEQUENCE_VALUE VOUCHER,
            AD.DESCRIPTION,
            GC.SEGMENT5,
            XX_COM_PKG.GET_GL_CODE_DESC_FROM_CCID (AD.DIST_CODE_COMBINATION_ID),
            XX_COM_PKG.GET_FLEX_VALUES_FROM_FLEX_ID (XX_COM_PKG.GET_SEGMENT_VALUE_FROM_CCID (AD.DIST_CODE_COMBINATION_ID, 1), 1),
            NULL,
            ABS (LEAST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0)),
            GREATEST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0)
       FROM AP_INVOICES_ALL AI,
            AP_SUPPLIERS AV,
            AP_INVOICE_DISTRIBUTIONS_ALL AD,
            GL_CODE_COMBINATIONS GC
      WHERE     AI.INVOICE_ID = AD.INVOICE_ID
            AND AI.VENDOR_ID = AV.VENDOR_ID
            AND AD.DIST_CODE_COMBINATION_ID = GC.CODE_COMBINATION_ID
            AND XX_AP_PKG.GET_INVOICE_STATUS (AI.INVOICE_ID) = 'Validated'
            AND AD.LINE_TYPE_LOOKUP_CODE NOT IN ('PREPAY')
            AND NVL (AD.REVERSAL_FLAG, 'N') <> 'Y'
            AND AI.INVOICE_DATE >= '31-AUG-2020'
            AND GC.SEGMENT4 <> 21010101  --Term Loan - Bank
   --AND ai.invoice_id = 1082723
   GROUP BY AI.LEGAL_ENTITY_ID,
            GC.SEGMENT1,
            AI.ORG_ID,
            AI.INVOICE_ID,
            AD.ACCOUNTING_DATE,
            AI.PARTY_ID,
            AV.VENDOR_TYPE_LOOKUP_CODE,
            AV.ATTRIBUTE13,
            AV.VENDOR_ID,
            AV.SEGMENT1,
            AV.EMPLOYEE_ID,
            AI.INVOICE_TYPE_LOOKUP_CODE,
            AI.INVOICE_NUM,
            AI.DOC_SEQUENCE_VALUE,
            AD.DESCRIPTION,
            GC.SEGMENT5,
            AD.DIST_CODE_COMBINATION_ID
   UNION ALL
     SELECT 2,
            AI.LEGAL_ENTITY_ID,
            GC.SEGMENT1,
            AI.ORG_ID,
            AI.INVOICE_ID,
            TRUNC (CK.CHECK_DATE),
            AI.PARTY_ID,
            AV.VENDOR_TYPE_LOOKUP_CODE,
            AV.ATTRIBUTE13,
            AV.VENDOR_ID,
            AV.SEGMENT1,
            AV.EMPLOYEE_ID,
            INITCAP (AI.INVOICE_TYPE_LOOKUP_CODE),
            DECODE (AI.INVOICE_TYPE_LOOKUP_CODE,
                    'PREPAYMENT', AI.INVOICE_NUM,
                    TO_CHAR (CHECK_NUMBER)),
            CK.DOC_SEQUENCE_VALUE,
            CK.DESCRIPTION,
            GC.SEGMENT5,
            XX_COM_PKG.GET_GL_CODE_DESC_FROM_CCID (CS.AP_ASSET_CCID),
            XX_COM_PKG.GET_FLEX_VALUES_FROM_FLEX_ID (XX_COM_PKG.GET_SEGMENT_VALUE_FROM_CCID (CS.AP_ASSET_CCID, 1), 1),
            CK.BANK_ACCOUNT_NUM,
            GREATEST (SUM (NVL (PM.INVOICE_BASE_AMOUNT, PM.AMOUNT)), 0),
            ABS (LEAST (SUM (NVL (PM.INVOICE_BASE_AMOUNT, PM.AMOUNT)), 0))
       FROM AP_INVOICES_ALL AI,
            AP_SUPPLIERS AV,
            AP_INVOICE_PAYMENTS_ALL PM,
            AP_CHECKS_ALL CK,
            CE_GL_ACCOUNTS_CCID CS,
            GL_CODE_COMBINATIONS GC
      WHERE     AI.INVOICE_ID = PM.INVOICE_ID
            AND AI.VENDOR_ID = AV.VENDOR_ID
            AND PM.CHECK_ID = CK.CHECK_ID
            AND CK.CE_BANK_ACCT_USE_ID = CS.BANK_ACCT_USE_ID
            AND CS.AP_ASSET_CCID = GC.CODE_COMBINATION_ID
            AND NVL (PM.REVERSAL_FLAG, 'N') <> 'Y'
            AND AI.INVOICE_TYPE_LOOKUP_CODE <> 'PREPAYMENT'
            AND PM.AMOUNT > 0
            AND AI.INVOICE_DATE >= '31-AUG-2020'
   GROUP BY AI.LEGAL_ENTITY_ID,
            GC.SEGMENT1,
            AI.ORG_ID,
            AI.INVOICE_ID,
            CK.CHECK_DATE,
            AI.PARTY_ID,
            AV.VENDOR_TYPE_LOOKUP_CODE,
            AV.ATTRIBUTE13,
            AV.VENDOR_ID,
            AV.SEGMENT1,
            AV.EMPLOYEE_ID,
            AI.INVOICE_TYPE_LOOKUP_CODE,
            CHECK_NUMBER,
            AI.INVOICE_TYPE_LOOKUP_CODE,
            AI.DOC_SEQUENCE_VALUE,
            CK.DOC_SEQUENCE_VALUE,
            CK.DESCRIPTION,
            GC.SEGMENT5,
            CS.AP_ASSET_CCID,
            AI.INVOICE_NUM,
            CK.BANK_ACCOUNT_NUM
   UNION ALL
     SELECT 3,
            AI.LEGAL_ENTITY_ID,
            GC.SEGMENT1,
            AI.ORG_ID,
            AI.INVOICE_ID,
            TRUNC (CK.CHECK_DATE),
            AI.PARTY_ID,
            AV.VENDOR_TYPE_LOOKUP_CODE,
            AV.ATTRIBUTE13,
            AV.VENDOR_ID,
            AV.SEGMENT1,
            AV.EMPLOYEE_ID,
            INITCAP (AI.INVOICE_TYPE_LOOKUP_CODE),
            DECODE (AI.INVOICE_TYPE_LOOKUP_CODE,
                    'PREPAYMENT', AI.INVOICE_NUM,
                    TO_CHAR (CHECK_NUMBER)),
            CK.DOC_SEQUENCE_VALUE,
            CK.DESCRIPTION,
            GC.SEGMENT5,
            XX_COM_PKG.GET_GL_CODE_DESC_FROM_CCID (CS.AP_ASSET_CCID),
            XX_COM_PKG.GET_FLEX_VALUES_FROM_FLEX_ID (XX_COM_PKG.GET_SEGMENT_VALUE_FROM_CCID (CS.AP_ASSET_CCID, 1),1),
            CK.BANK_ACCOUNT_NUM,
            GREATEST (SUM (NVL (CK.BASE_AMOUNT, PM.AMOUNT)), 0), --OLD GREATEST (SUM (NVL (CK.BASE_AMOUNT, CK.AMOUNT)), 0),
            ABS (LEAST (SUM (NVL (CK.BASE_AMOUNT, PM.AMOUNT)), 0)) --OLD ABS (LEAST (SUM (NVL (CK.BASE_AMOUNT,CK.AMOUNT)), 0))
       FROM AP_INVOICES_ALL AI,
            AP_SUPPLIERS AV,
            AP_INVOICE_PAYMENTS_ALL PM,
            AP_CHECKS_ALL CK,
            CE_GL_ACCOUNTS_CCID CS,
            GL_CODE_COMBINATIONS GC
      WHERE     AI.INVOICE_ID = PM.INVOICE_ID
            AND AI.VENDOR_ID = AV.VENDOR_ID
            AND PM.CHECK_ID = CK.CHECK_ID
            AND CK.CE_BANK_ACCT_USE_ID = CS.BANK_ACCT_USE_ID
            AND CS.AP_ASSET_CCID = GC.CODE_COMBINATION_ID
            AND NVL (PM.REVERSAL_FLAG, 'N') <> 'Y'
            AND AI.INVOICE_TYPE_LOOKUP_CODE = 'PREPAYMENT'
            AND AI.EARLIEST_SETTLEMENT_DATE IS NOT NULL
            AND PM.AMOUNT > 0
            AND AI.INVOICE_DATE >= '31-AUG-2020'
   GROUP BY AI.LEGAL_ENTITY_ID,
            GC.SEGMENT1,
            AI.ORG_ID,
            AI.INVOICE_ID,
            CK.CHECK_DATE,
            AI.PARTY_ID,
            AV.VENDOR_TYPE_LOOKUP_CODE,
            AV.ATTRIBUTE13,
            AV.VENDOR_ID,
            AV.SEGMENT1,
            AV.EMPLOYEE_ID,
            AI.INVOICE_TYPE_LOOKUP_CODE,
            CHECK_NUMBER,
            AI.INVOICE_TYPE_LOOKUP_CODE,
            AI.DOC_SEQUENCE_VALUE,
            CK.DOC_SEQUENCE_VALUE,
            CK.DESCRIPTION,
            GC.SEGMENT5,
            CS.AP_ASSET_CCID,
            AI.INVOICE_NUM,
            CK.BANK_ACCOUNT_NUM
   UNION ALL
     SELECT 4,
            AI.LEGAL_ENTITY_ID,
            GC.SEGMENT1,
            AI.ORG_ID,
            AI.INVOICE_ID,
            TRUNC (AD.ACCOUNTING_DATE),
            AI.PARTY_ID,
            AV.VENDOR_TYPE_LOOKUP_CODE,
            AV.ATTRIBUTE13,
            AV.VENDOR_ID,
            AV.SEGMENT1,
            AV.EMPLOYEE_ID,
            INITCAP (AI.INVOICE_TYPE_LOOKUP_CODE),
            AI.INVOICE_NUM,
            AI.DOC_SEQUENCE_VALUE VOUCHER,
            AD.DESCRIPTION,
            GC.SEGMENT5,
            XX_COM_PKG.GET_GL_CODE_DESC_FROM_CCID (AD.DIST_CODE_COMBINATION_ID),
            XX_COM_PKG.GET_FLEX_VALUES_FROM_FLEX_ID (XX_COM_PKG.GET_SEGMENT_VALUE_FROM_CCID (AD.DIST_CODE_COMBINATION_ID,1),1),
            NULL,
            ABS (LEAST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0)),
            GREATEST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0)
       FROM AP_INVOICES_ALL AI,
            AP_SUPPLIERS AV,
            AP_INVOICE_DISTRIBUTIONS_ALL AD,
            GL_CODE_COMBINATIONS GC
      WHERE     AI.INVOICE_ID = AD.INVOICE_ID
            AND AI.VENDOR_ID = AV.VENDOR_ID
            AND AD.DIST_CODE_COMBINATION_ID = GC.CODE_COMBINATION_ID
            AND AI.INVOICE_TYPE_LOOKUP_CODE = 'PREPAYMENT'
            --AND AD.LINE_TYPE_LOOKUP_CODE = 'AWT'
            AND NVL (AD.REVERSAL_FLAG, 'N') <> 'Y'
            AND AI.INVOICE_DATE >= '31-AUG-2020'
   GROUP BY AI.LEGAL_ENTITY_ID,
            GC.SEGMENT1,
            AI.ORG_ID,
            AI.INVOICE_ID,
            AD.ACCOUNTING_DATE,
            AI.PARTY_ID,
            AV.VENDOR_TYPE_LOOKUP_CODE,
            AV.ATTRIBUTE13,
            AV.VENDOR_ID,
            AV.SEGMENT1,
            AV.EMPLOYEE_ID,
            AI.INVOICE_TYPE_LOOKUP_CODE,
            AI.INVOICE_NUM,
            AI.DOC_SEQUENCE_VALUE,
            AD.DESCRIPTION,
            GC.SEGMENT5,
            AD.DIST_CODE_COMBINATION_ID
   UNION ALL
     SELECT 5,
            AI.LEGAL_ENTITY_ID,
            GC.SEGMENT1,
            AI.ORG_ID,
            AI.INVOICE_ID,
            TRUNC (CK.CHECK_DATE),
            AI.PARTY_ID,
            AV.VENDOR_TYPE_LOOKUP_CODE,
            AV.ATTRIBUTE13,
            AV.VENDOR_ID,
            AV.SEGMENT1,
            AV.EMPLOYEE_ID,
            INITCAP (AI.INVOICE_TYPE_LOOKUP_CODE),
            TO_CHAR (CHECK_NUMBER),
            CK.DOC_SEQUENCE_VALUE,
            'Discount on Payments',
            GC.SEGMENT5,
            XX_COM_PKG.GET_GL_CODE_DESC_FROM_CCID (SP.DISC_TAKEN_CODE_COMBINATION_ID),
            XX_COM_PKG.GET_FLEX_VALUES_FROM_FLEX_ID (XX_COM_PKG.GET_SEGMENT_VALUE_FROM_CCID (SP.DISC_TAKEN_CODE_COMBINATION_ID,1),1),
            CK.BANK_ACCOUNT_NUM,
            GREATEST (SUM (PM.DISCOUNT_TAKEN), 0),
            ABS (LEAST (SUM (PM.DISCOUNT_TAKEN), 0))
       FROM AP_INVOICES_ALL AI,
            AP_SUPPLIERS AV,
            AP_INVOICE_PAYMENTS_ALL PM,
            AP_CHECKS_ALL CK,
            GL_CODE_COMBINATIONS GC,
            FINANCIALS_SYSTEM_PARAMS_ALL SP
      WHERE     AI.INVOICE_ID = PM.INVOICE_ID
            AND AI.VENDOR_ID = AV.VENDOR_ID
            AND PM.CHECK_ID = CK.CHECK_ID
            AND SP.DISC_TAKEN_CODE_COMBINATION_ID = GC.CODE_COMBINATION_ID
            AND AI.ORG_ID = SP.ORG_ID
            AND NVL (PM.DISCOUNT_TAKEN, 0) <> 0
            AND NVL (PM.REVERSAL_FLAG, 'N') <> 'Y'
            AND PM.AMOUNT > 0
            AND AI.INVOICE_DATE >= '31-AUG-2020'
   GROUP BY AI.LEGAL_ENTITY_ID,
            GC.SEGMENT1,
            AI.ORG_ID,
            AI.INVOICE_ID,
            CK.CHECK_DATE,
            AI.PARTY_ID,
            AV.VENDOR_TYPE_LOOKUP_CODE,
            AV.ATTRIBUTE13,
            AV.VENDOR_ID,
            AV.SEGMENT1,
            AV.EMPLOYEE_ID,
            AI.INVOICE_TYPE_LOOKUP_CODE,
            CHECK_NUMBER,
            AI.INVOICE_TYPE_LOOKUP_CODE,
            AI.DOC_SEQUENCE_VALUE,
            CK.DOC_SEQUENCE_VALUE,
            CK.DESCRIPTION,
            GC.SEGMENT5,
            SP.DISC_TAKEN_CODE_COMBINATION_ID,
            CK.BANK_ACCOUNT_NUM
   UNION ALL
     SELECT 6,
            AI.LEGAL_ENTITY_ID,
            GC.SEGMENT1,
            AI.ORG_ID,
            AI.INVOICE_ID,
            TRUNC (AD.ACCOUNTING_DATE),
            AI.PARTY_ID,
            AV.VENDOR_TYPE_LOOKUP_CODE,
            AV.ATTRIBUTE13,
            AV.VENDOR_ID,
            AV.SEGMENT1,
            AV.EMPLOYEE_ID,
            INITCAP (AI.INVOICE_TYPE_LOOKUP_CODE),
            AI.INVOICE_NUM,
            AI.DOC_SEQUENCE_VALUE VOUCHER,
            AD.DESCRIPTION,
            GC.SEGMENT5,
            XX_COM_PKG.GET_GL_CODE_DESC_FROM_CCID (AD.DIST_CODE_COMBINATION_ID),
            XX_COM_PKG.GET_FLEX_VALUES_FROM_FLEX_ID (XX_COM_PKG.GET_SEGMENT_VALUE_FROM_CCID (AD.DIST_CODE_COMBINATION_ID,1),1),
            NULL,
            GREATEST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0),
            ABS (LEAST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0))
       FROM AP_INVOICES_ALL AI,
            AP_SUPPLIERS AV,
            AP_INVOICE_DISTRIBUTIONS_ALL AD,
            GL_CODE_COMBINATIONS GC
      WHERE     AI.INVOICE_ID = AD.INVOICE_ID
            AND AI.VENDOR_ID = AV.VENDOR_ID
            AND AD.DIST_CODE_COMBINATION_ID = GC.CODE_COMBINATION_ID
            AND XX_AP_PKG.GET_INVOICE_STATUS (AI.INVOICE_ID) = 'Validated'
            AND AI.INVOICE_TYPE_LOOKUP_CODE = 'MIXED'
            AND NVL (AD.REVERSAL_FLAG, 'N') <> 'Y'
            AND AI.INVOICE_DATE >= '31-AUG-2020'
            --AND ai.invoice_id = 429734
            AND AD.AMOUNT <> 0
   GROUP BY AI.LEGAL_ENTITY_ID,
            GC.SEGMENT1,
            AI.ORG_ID,
            AI.INVOICE_ID,
            AD.ACCOUNTING_DATE,
            AI.PARTY_ID,
            AV.VENDOR_TYPE_LOOKUP_CODE,
            AV.ATTRIBUTE13,
            AV.VENDOR_ID,
            AV.SEGMENT1,
            AV.EMPLOYEE_ID,
            AI.INVOICE_TYPE_LOOKUP_CODE,
            AI.INVOICE_NUM,
            AI.DOC_SEQUENCE_VALUE,
            AD.DESCRIPTION,
            GC.SEGMENT5,
            AD.DIST_CODE_COMBINATION_ID
   UNION ALL
     SELECT 7,                       ----12-09-22- Credit-Memo-add-Term-Loan--
            AI.LEGAL_ENTITY_ID,
            GC.SEGMENT1,
            AI.ORG_ID,
            AI.INVOICE_ID,
            TRUNC (AD.ACCOUNTING_DATE),
            AI.PARTY_ID,
            AV.VENDOR_TYPE_LOOKUP_CODE,
            AV.ATTRIBUTE13,
            AV.VENDOR_ID,
            AV.SEGMENT1,
            AV.EMPLOYEE_ID,
            INITCAP (AI.INVOICE_TYPE_LOOKUP_CODE),
            AI.INVOICE_NUM,
            AI.DOC_SEQUENCE_VALUE VOUCHER,
            AD.DESCRIPTION,
            GC.SEGMENT5,
            XX_COM_PKG.GET_GL_CODE_DESC_FROM_CCID (AD.DIST_CODE_COMBINATION_ID),
            XX_COM_PKG.GET_FLEX_VALUES_FROM_FLEX_ID (XX_COM_PKG.GET_SEGMENT_VALUE_FROM_CCID (AD.DIST_CODE_COMBINATION_ID,1),1),
            NULL,
            GREATEST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0),
            ABS (LEAST (SUM (NVL (AD.BASE_AMOUNT, AD.AMOUNT)), 0))
       FROM AP_INVOICES_ALL AI,
            AP_SUPPLIERS AV,
            AP_INVOICE_DISTRIBUTIONS_ALL AD,
            GL_CODE_COMBINATIONS GC
      WHERE     AI.INVOICE_ID = AD.INVOICE_ID
            AND AI.VENDOR_ID = AV.VENDOR_ID
            AND AD.DIST_CODE_COMBINATION_ID = GC.CODE_COMBINATION_ID
            AND XX_AP_PKG.GET_INVOICE_STATUS (AI.INVOICE_ID) = 'Validated'
            AND AI.INVOICE_TYPE_LOOKUP_CODE = 'CREDIT'
            AND NVL (AD.REVERSAL_FLAG, 'N') <> 'Y'
            AND AI.INVOICE_DATE >= '31-AUG-2020'
            --AND GC.SEGMENT4 = 21010101
            --AND ai.invoice_id = 429734
            AND AD.AMOUNT <> 0
   GROUP BY AI.LEGAL_ENTITY_ID,
            GC.SEGMENT1,
            AI.ORG_ID,
            AI.INVOICE_ID,
            AD.ACCOUNTING_DATE,
            AI.PARTY_ID,
            AV.VENDOR_TYPE_LOOKUP_CODE,
            AV.ATTRIBUTE13,
            AV.VENDOR_ID,
            AV.SEGMENT1,
            AV.EMPLOYEE_ID,
            AI.INVOICE_TYPE_LOOKUP_CODE,
            AI.INVOICE_NUM,
            AI.DOC_SEQUENCE_VALUE,
            AD.DESCRIPTION,
            GC.SEGMENT5,
            AD.DIST_CODE_COMBINATION_ID;


CREATE OR REPLACE SYNONYM MYUSER.XX_AP_SUPPLIER_LEDGER_V FOR APPS.XX_AP_SUPPLIER_LEDGER_V;


GRANT SELECT ON APPS.XX_AP_SUPPLIER_LEDGER_V TO MYUSER;
