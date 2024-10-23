CREATE OR REPLACE PACKAGE BODY APPS.AP_INVOICES_PKG AS
/* $Header: apiinceb.pls 120.62.12020000.6 2015/01/29 03:02:22 dunayak ship $ */

-- Bug 10103631 - Start
G_PKG_NAME          CONSTANT VARCHAR2(30) := 'AP_INVOICES_PKG';
G_MSG_UERROR        CONSTANT NUMBER       := FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR;
G_MSG_ERROR         CONSTANT NUMBER       := FND_MSG_PUB.G_MSG_LVL_ERROR;
G_MSG_SUCCESS       CONSTANT NUMBER       := FND_MSG_PUB.G_MSG_LVL_SUCCESS;
G_MSG_HIGH          CONSTANT NUMBER       := FND_MSG_PUB.G_MSG_LVL_DEBUG_HIGH;
G_MSG_MEDIUM        CONSTANT NUMBER       := FND_MSG_PUB.G_MSG_LVL_DEBUG_MEDIUM;
G_MSG_LOW           CONSTANT NUMBER       := FND_MSG_PUB.G_MSG_LVL_DEBUG_LOW;
G_LINES_PER_FETCH   CONSTANT NUMBER       := 1000;

G_CURRENT_RUNTIME_LEVEL CONSTANT NUMBER   := FND_LOG.G_CURRENT_RUNTIME_LEVEL;
G_LEVEL_UNEXPECTED      CONSTANT NUMBER   := FND_LOG.LEVEL_UNEXPECTED;
G_LEVEL_ERROR           CONSTANT NUMBER   := FND_LOG.LEVEL_ERROR;
G_LEVEL_EXCEPTION       CONSTANT NUMBER   := FND_LOG.LEVEL_EXCEPTION;
G_LEVEL_EVENT           CONSTANT NUMBER   := FND_LOG.LEVEL_EVENT;
G_LEVEL_PROCEDURE       CONSTANT NUMBER   := FND_LOG.LEVEL_PROCEDURE;
G_LEVEL_STATEMENT       CONSTANT NUMBER   := FND_LOG.LEVEL_STATEMENT;
G_MODULE_NAME           CONSTANT VARCHAR2(100) := 'AP.PLSQL.AP_INVOICES_PKG.';
-- Bug 10103631 - End

PROCEDURE Insert_Row(X_Rowid            IN OUT NOCOPY VARCHAR2,
          X_Invoice_Id                  IN OUT NOCOPY NUMBER,
          X_Last_Update_Date                   DATE,
          X_Last_Updated_By                    NUMBER,
          X_Vendor_Id                          NUMBER,
          X_Invoice_Num                        VARCHAR2,
          X_Invoice_Amount                     NUMBER,
          X_Vendor_Site_Id                     NUMBER,
          X_Amount_Paid                        NUMBER,
          X_Discount_Amount_Taken              NUMBER,
          X_Invoice_Date                       DATE,
          X_Source                             VARCHAR2,
          X_Invoice_Type_Lookup_Code           VARCHAR2,
          X_Description                        VARCHAR2,
          X_Batch_Id                           NUMBER,
          X_Amt_Applicable_To_Discount         NUMBER,
          X_Terms_Id                           NUMBER,
          X_Terms_Date                         DATE,
          X_Goods_Received_Date                DATE,
          X_Invoice_Received_Date              DATE,
          X_Voucher_Num                        VARCHAR2,
          X_Approved_Amount                    NUMBER,
          X_Approval_Status                    VARCHAR2,
          X_Approval_Description               VARCHAR2,
          X_Pay_Group_Lookup_Code              VARCHAR2,
          X_Set_Of_Books_Id                    NUMBER,
          X_Accts_Pay_CCId                     NUMBER,
          X_Recurring_Payment_Id               NUMBER,
          X_Invoice_Currency_Code              VARCHAR2,
          X_Payment_Currency_Code              VARCHAR2,
          X_Exchange_Rate                      NUMBER,
          X_Payment_Amount_Total               NUMBER,
          X_Payment_Status_Flag                VARCHAR2,
          X_Posting_Status                     VARCHAR2,
          X_Authorized_By                      VARCHAR2,
          X_Attribute_Category                 VARCHAR2,
          X_Attribute1                         VARCHAR2,
          X_Attribute2                         VARCHAR2,
          X_Attribute3                         VARCHAR2,
          X_Attribute4                         VARCHAR2,
          X_Attribute5                         VARCHAR2,
          X_Creation_Date                      DATE,
          X_Created_By                         NUMBER,
          X_Vendor_Prepay_Amount               NUMBER,
          X_Base_Amount                        NUMBER,
          X_Exchange_Rate_Type                 VARCHAR2,
          X_Exchange_Date                      DATE,
          X_Payment_Cross_Rate                 NUMBER,
          X_Payment_Cross_Rate_Type            VARCHAR2,
          X_Payment_Cross_Rate_Date            Date,
          X_Pay_Curr_Invoice_Amount            NUMBER,
          X_Last_Update_Login                  NUMBER,
          X_Original_Prepayment_Amount         NUMBER,
          X_Earliest_Settlement_Date           DATE,
          X_Attribute11                        VARCHAR2,
          X_Attribute12                        VARCHAR2,
          X_Attribute13                        VARCHAR2,
          X_Attribute14                        VARCHAR2,
          X_Attribute6                         VARCHAR2,
          X_Attribute7                         VARCHAR2,
          X_Attribute8                         VARCHAR2,
          X_Attribute9                         VARCHAR2,
          X_Attribute10                        VARCHAR2,
          X_Attribute15                        VARCHAR2,
          X_Cancelled_Date                     DATE,
          X_Cancelled_By                       NUMBER,
          X_Cancelled_Amount                   NUMBER,
          X_Temp_Cancelled_Amount              NUMBER,
          X_Exclusive_Payment_Flag             VARCHAR2,
          X_Po_Header_Id                       NUMBER,
          X_Doc_Sequence_Id                    NUMBER,
          X_Doc_Sequence_Value                 NUMBER,
          X_Doc_Category_Code                  VARCHAR2,
          X_Expenditure_Item_Date              DATE,
          X_Expenditure_Organization_Id        NUMBER,
          X_Expenditure_Type                   VARCHAR2,
          X_Pa_Default_Dist_Ccid               NUMBER,
          X_Pa_Quantity                        NUMBER,
          X_Project_Id                         NUMBER,
          X_Task_Id                            NUMBER,
          X_Awt_Flag                           VARCHAR2,
          X_Awt_Group_Id                       NUMBER,
          X_Pay_Awt_Group_Id                   NUMBER,--bug6639866
          X_Reference_1                        VARCHAR2,
          X_Reference_2                        VARCHAR2,
          X_Org_Id                             NUMBER,
          X_global_attribute_category          VARCHAR2 DEFAULT NULL,
          X_global_attribute1                  VARCHAR2 DEFAULT NULL,
          X_global_attribute2                  VARCHAR2 DEFAULT NULL,
          X_global_attribute3                  VARCHAR2 DEFAULT NULL,
          X_global_attribute4                  VARCHAR2 DEFAULT NULL,
          X_global_attribute5                  VARCHAR2 DEFAULT NULL,
          X_global_attribute6                  VARCHAR2 DEFAULT NULL,
          X_global_attribute7                  VARCHAR2 DEFAULT NULL,
          X_global_attribute8                  VARCHAR2 DEFAULT NULL,
          X_global_attribute9                  VARCHAR2 DEFAULT NULL,
          X_global_attribute10                 VARCHAR2 DEFAULT NULL,
          X_global_attribute11                 VARCHAR2 DEFAULT NULL,
          X_global_attribute12                 VARCHAR2 DEFAULT NULL,
          X_global_attribute13                 VARCHAR2 DEFAULT NULL,
          X_global_attribute14                 VARCHAR2 DEFAULT NULL,
          X_global_attribute15                 VARCHAR2 DEFAULT NULL,
          X_global_attribute16                 VARCHAR2 DEFAULT NULL,
          X_global_attribute17                 VARCHAR2 DEFAULT NULL,
          X_global_attribute18                 VARCHAR2 DEFAULT NULL,
          X_global_attribute19                 VARCHAR2 DEFAULT NULL,
          X_global_attribute20                 VARCHAR2 DEFAULT NULL,
          X_calling_sequence            IN     VARCHAR2,
          X_gl_date                            DATE,
          X_Award_Id                           NUMBER,
          X_APPROVAL_ITERATION                 NUMBER   DEFAULT NULL,
          X_APPROVAL_READY_FLAG                VARCHAR2 DEFAULT 'Y',
          X_WFAPPROVAL_STATUS                  VARCHAR2 DEFAULT 'NOT REQUIRED',
          X_REQUESTER_ID                       NUMBER DEFAULT NULL,
          -- Invoice Lines Project Stage 1
          X_QUICK_CREDIT                       VARCHAR2 DEFAULT NULL,
          X_CREDITED_INVOICE_ID                NUMBER   DEFAULT NULL,
          X_DISTRIBUTION_SET_ID                NUMBER   DEFAULT NULL,
	  --ETAX: Invwkb
	  X_FORCE_REVALIDATION_FLAG	       VARCHAR2 DEFAULT NULL,
	  X_CONTROL_AMOUNT                     NUMBER   DEFAULT NULL,
	  X_TAX_RELATED_INVOICE_ID             NUMBER   DEFAULT NULL,
	  X_TRX_BUSINESS_CATEGORY              VARCHAR2 DEFAULT NULL,
	  X_USER_DEFINED_FISC_CLASS            VARCHAR2 DEFAULT NULL,
	  X_TAXATION_COUNTRY                   VARCHAR2 DEFAULT NULL,
	  X_DOCUMENT_SUB_TYPE                  VARCHAR2 DEFAULT NULL,
	  X_SUPPLIER_TAX_INVOICE_NUMBER        VARCHAR2 DEFAULT NULL,
	  X_SUPPLIER_TAX_INVOICE_DATE          DATE     DEFAULT NULL,
	  X_SUPPLIER_TAX_EXCHANGE_RATE         NUMBER   DEFAULT NULL,
	  X_TAX_INVOICE_RECORDING_DATE         DATE     DEFAULT NULL,
	  X_TAX_INVOICE_INTERNAL_SEQ           VARCHAR2 DEFAULT NULL, -- bug 8912305: modify
	  X_LEGAL_ENTITY_ID		       NUMBER   DEFAULT NULL,
	  X_QUICK_PO_HEADER_ID		       NUMBER   DEFAULT NULL,
          x_PAYMENT_METHOD_CODE                varchar2 ,
          x_PAYMENT_REASON_CODE                varchar2 default null,
          X_PAYMENT_REASON_COMMENTS            varchar2 default null,
          x_UNIQUE_REMITTANCE_IDENTIFIER       varchar2 default null,
          x_URI_CHECK_DIGIT                    varchar2 default null,
          x_BANK_CHARGE_BEARER                 varchar2 default null,
          x_DELIVERY_CHANNEL_CODE              varchar2 default null,
          x_SETTLEMENT_PRIORITY                varchar2 default null,
          x_NET_OF_RETAINAGE_FLAG	       varchar2 default null,
	  x_RELEASE_AMOUNT_NET_OF_TAX	       number   default null,
	  x_PORT_OF_ENTRY_CODE		       varchar2 default null,
          x_external_bank_account_id           number   default null,
          x_party_id                           number   default null,
          x_party_site_id                      number   default null,
          /* bug 4931755. Exclude Tax and Freight from Discount */
          x_disc_is_inv_less_tax_flag          varchar2 default null,
          x_exclude_freight_from_disc          varchar2 default null,
          x_remit_msg1                         varchar2 default null,
          x_remit_msg2                         varchar2 default null,
          x_remit_msg3                         varchar2 default null,
	  x_cust_registration_number	       varchar2 default null,
	  /* Third Party Payments*/
	  x_remit_to_supplier_name	varchar2 default null,
	  x_remit_to_supplier_id	number default null,
	  x_remit_to_supplier_site	varchar2 default null,
	  x_remit_to_supplier_site_id number default null,
	  x_relationship_id		number default null,
	  /* Bug 7831073 */
	  x_original_invoice_amount number default null,
	  x_dispute_reason varchar2 default null
 ) IS
    current_calling_sequence      VARCHAR2(2000);
    debug_info                    VARCHAR2(100);
    l_le_id                       number(15);
BEGIN
  -- Update the calling sequence
  --
  current_calling_sequence :=
            'AP_INVOICES_PKG.INSERT_ROW<-'||X_calling_sequence;

  -- Get LE Information
  --
  IF x_legal_entity_id IS NULL THEN

     AP_UTILITIES_PKG.Get_Invoice_LE(
                  X_vendor_site_id,
                  X_accts_pay_ccid,
                  X_org_id,
                  l_le_id);

  END IF;

  AP_AI_TABLE_HANDLER_PKG.Insert_Row
         (X_Rowid,
          X_Invoice_Id,
          X_Last_Update_Date,
          X_Last_Updated_By,
          X_Vendor_Id,
          X_Invoice_Num,
          X_Invoice_Amount,
          X_Vendor_Site_Id,
          X_Amount_Paid,
          X_Discount_Amount_Taken,
          X_Invoice_Date,
          X_Source,
          X_Invoice_Type_Lookup_Code,
          X_Description,
          X_Batch_Id,
          X_Amt_Applicable_To_Discount,
          X_Terms_Id,
          X_Terms_Date,
          X_Goods_Received_Date,
          X_Invoice_Received_Date,
          X_Voucher_Num,
          X_Approved_Amount,
          X_Approval_Status,
          X_Approval_Description,
          X_Pay_Group_Lookup_Code,
          X_Set_Of_Books_Id,
          X_Accts_Pay_CCId,
          X_Recurring_Payment_Id,
          X_Invoice_Currency_Code,
          X_Payment_Currency_Code,
          X_Exchange_Rate,
          X_Payment_Amount_Total,
          X_Payment_Status_Flag,
          X_Posting_Status,
          X_Authorized_By,
          X_Attribute_Category,
          X_Attribute1,
          X_Attribute2,
          X_Attribute3,
          X_Attribute4,
          X_Attribute5,
          X_Creation_Date,
          X_Created_By,
          X_Vendor_Prepay_Amount,
          X_Base_Amount,
          X_Exchange_Rate_Type,
          X_Exchange_Date,
          X_Payment_Cross_Rate,
          X_Payment_Cross_Rate_Type,
          X_Payment_Cross_Rate_Date,
          X_Pay_Curr_Invoice_Amount,
          X_Last_Update_Login,
          X_Original_Prepayment_Amount,
          X_Earliest_Settlement_Date,
          X_Attribute11,
          X_Attribute12,
          X_Attribute13,
          X_Attribute14,
          X_Attribute6,
          X_Attribute7,
          X_Attribute8,
          X_Attribute9,
          X_Attribute10,
          X_Attribute15,
          X_Cancelled_Date,
          X_Cancelled_By,
          X_Cancelled_Amount,
          X_Temp_Cancelled_Amount,
          X_Exclusive_Payment_Flag,
          X_Po_Header_Id,
          X_Doc_Sequence_Id,
          X_Doc_Sequence_Value,
          X_Doc_Category_Code,
          X_Expenditure_Item_Date,
          X_Expenditure_Organization_Id,
          X_Expenditure_Type,
          X_Pa_Default_Dist_Ccid,
          X_Pa_Quantity,
          X_Project_Id,
          X_Task_Id,
          X_Awt_Flag,
          X_Awt_Group_Id,
          X_Pay_Awt_Group_Id,--bug6639866
          X_Reference_1,
          X_Reference_2,
          X_Org_id,
          X_global_attribute_category,
          X_global_attribute1,
          X_global_attribute2,
          X_global_attribute3,
          X_global_attribute4,
          X_global_attribute5,
          X_global_attribute6,
          X_global_attribute7,
          X_global_attribute8,
          X_global_attribute9,
          X_global_attribute10,
          X_global_attribute11,
          X_global_attribute12,
          X_global_attribute13,
          X_global_attribute14,
          X_global_attribute15,
          X_global_attribute16,
          X_global_attribute17,
          X_global_attribute18,
          X_global_attribute19,
          X_global_attribute20,
          current_calling_sequence,
          X_gl_date,
          X_Award_Id,
          X_APPROVAL_ITERATION,
          X_approval_ready_flag,
          X_wfapproval_status,
          NULL,
          NULL,
          NULL,
          X_requester_id,  --2289496
          -- Invoice Lines Project Stage 1
          X_quick_credit,
          X_credited_invoice_id,
          X_distribution_set_id,
	  --Etax: Invwkb
	  X_force_revalidation_flag,
	  X_CONTROL_AMOUNT,
	  X_TAX_RELATED_INVOICE_ID,
	  X_TRX_BUSINESS_CATEGORY,
	  X_USER_DEFINED_FISC_CLASS,
	  X_TAXATION_COUNTRY,
	  X_DOCUMENT_SUB_TYPE,
	  X_SUPPLIER_TAX_INVOICE_NUMBER,
	  X_SUPPLIER_TAX_INVOICE_DATE,
	  X_SUPPLIER_TAX_EXCHANGE_RATE,
	  X_TAX_INVOICE_RECORDING_DATE,
	  X_TAX_INVOICE_INTERNAL_SEQ,
	  NVL(X_LEGAL_ENTITY_ID,l_le_id),
	  X_QUICK_PO_HEADER_ID,
          x_PAYMENT_METHOD_CODE,
          x_PAYMENT_REASON_CODE,
          x_PAYMENT_REASON_COMMENTS,
          x_UNIQUE_REMITTANCE_IDENTIFIER,
          x_URI_CHECK_DIGIT,
          x_BANK_CHARGE_BEARER,
          x_DELIVERY_CHANNEL_CODE,
          x_SETTLEMENT_PRIORITY,
          x_NET_OF_RETAINAGE_FLAG,
	  x_RELEASE_AMOUNT_NET_OF_TAX,
	  x_PORT_OF_ENTRY_CODE,
          x_external_bank_account_id,
          x_party_id,
          x_party_site_id,
          x_disc_is_inv_less_tax_flag,
          x_exclude_freight_from_disc,
          x_remit_msg1,
          x_remit_msg2,
          x_remit_msg3,
	  x_cust_registration_number,
	  x_remit_to_supplier_name,
	  x_remit_to_supplier_id,
	  x_remit_to_supplier_site,
	  x_remit_to_supplier_site_id,
	  x_relationship_id,
	 /* Bug 7831073 */
	  x_original_invoice_amount,
	  x_dispute_reason
	  );

  EXCEPTION
     WHEN OTHERS THEN
         IF (SQLCODE <> -20001) THEN
           FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
           FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
           FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',
                     current_calling_sequence);
           FND_MESSAGE.SET_TOKEN('PARAMETERS',
               'X_Rowid = '||X_Rowid
           ||', X_invoice_id = '||X_invoice_id
                                    );
           FND_MESSAGE.SET_TOKEN('DEBUG_INFO',debug_info);
         END IF;
       APP_EXCEPTION.RAISE_EXCEPTION;


END Insert_Row;

PROCEDURE lock_Row(
	  X_Rowid                             VARCHAR2,
          X_Invoice_Id                        NUMBER,
          X_Vendor_Id                         NUMBER,
          X_Invoice_Num                       VARCHAR2,
          X_Invoice_Amount                    NUMBER,
          X_Vendor_Site_Id                    NUMBER,
          X_Amount_Paid                       NUMBER,
          X_Discount_Amount_Taken             NUMBER,
          X_Invoice_Date                      DATE,
          X_Source                            VARCHAR2,
          X_Invoice_Type_Lookup_Code          VARCHAR2,
          X_Description                       VARCHAR2,
          X_Batch_Id                          NUMBER,
          X_Amt_Applicable_To_Discount        NUMBER,
          X_Terms_Id                          NUMBER,
          X_Terms_Date                        DATE,
          X_Goods_Received_Date               DATE,
          X_Invoice_Received_Date             DATE,
          X_Voucher_Num                       VARCHAR2,
          X_Approved_Amount                   NUMBER,
          X_Approval_Status                   VARCHAR2,
          X_Approval_Description              VARCHAR2,
          X_Pay_Group_Lookup_Code             VARCHAR2,
          X_Set_Of_Books_Id                   NUMBER,
          X_Accts_Pay_CCId                    NUMBER,
          X_Recurring_Payment_Id              NUMBER,
          X_Invoice_Currency_Code             VARCHAR2,
          X_Payment_Currency_Code             VARCHAR2,
          X_Exchange_Rate                     NUMBER,
          X_Payment_Amount_Total              NUMBER,
          X_Payment_Status_Flag               VARCHAR2,
          X_Posting_Status                    VARCHAR2,
          X_Posting_Flag                      VARCHAR2,
          X_Authorized_By                     VARCHAR2,
          X_Attribute_Category                VARCHAR2,
          X_Attribute1                        VARCHAR2,
          X_Attribute2                        VARCHAR2,
          X_Attribute3                        VARCHAR2,
          X_Attribute4                        VARCHAR2,
          X_Attribute5                        VARCHAR2,
          X_Vendor_Prepay_Amount              NUMBER,
          X_Base_Amount                       NUMBER,
          X_Exchange_Rate_Type                VARCHAR2,
          X_Exchange_Date                     DATE,
          X_Payment_Cross_Rate                NUMBER,
          X_Payment_Cross_Rate_Type           VARCHAR2,
          X_Payment_Cross_Rate_Date           DATE,
          X_Pay_Curr_Invoice_Amount           NUMBER,
          X_Original_Prepayment_Amount        NUMBER,
          X_Earliest_Settlement_Date          DATE,
          X_Attribute11                       VARCHAR2,
          X_Attribute12                       VARCHAR2,
          X_Attribute13                       VARCHAR2,
          X_Attribute14                       VARCHAR2,
          X_Attribute6                        VARCHAR2,
          X_Attribute7                        VARCHAR2,
          X_Attribute8                        VARCHAR2,
          X_Attribute9                        VARCHAR2,
          X_Attribute10                       VARCHAR2,
          X_Attribute15                       VARCHAR2,
          X_Cancelled_Date                    DATE,
          X_Cancelled_By                      NUMBER,
          X_Cancelled_Amount                  NUMBER,
          X_Temp_Cancelled_Amount             NUMBER,
          X_Exclusive_Payment_Flag            VARCHAR2,
          X_Po_Header_Id                      NUMBER,
          X_Doc_Sequence_Id                   NUMBER,
          X_Doc_Sequence_Value                NUMBER,
          X_Doc_Category_Code                 VARCHAR2,
          X_Expenditure_Item_Date             DATE,
          X_Expenditure_Organization_Id       NUMBER,
          X_Expenditure_Type                  VARCHAR2,
          X_Pa_Default_Dist_Ccid              NUMBER,
          X_Pa_Quantity                       NUMBER,
          X_Project_Id                        NUMBER,
          X_Task_Id                           NUMBER,
          X_Awt_Flag                          VARCHAR2,
          X_Awt_Group_Id                      NUMBER,
	  X_Pay_Awt_Group_Id                  NUMBER,--bug6639866
          X_Reference_1                       VARCHAR2,
          X_Reference_2                       VARCHAR2,
          X_Org_Id                            NUMBER,
          X_global_attribute_category         VARCHAR2 DEFAULT NULL,
          X_global_attribute1                 VARCHAR2 DEFAULT NULL,
          X_global_attribute2                 VARCHAR2 DEFAULT NULL,
          X_global_attribute3                 VARCHAR2 DEFAULT NULL,
          X_global_attribute4                 VARCHAR2 DEFAULT NULL,
          X_global_attribute5                 VARCHAR2 DEFAULT NULL,
          X_global_attribute6                 VARCHAR2 DEFAULT NULL,
          X_global_attribute7                 VARCHAR2 DEFAULT NULL,
          X_global_attribute8                 VARCHAR2 DEFAULT NULL,
          X_global_attribute9                 VARCHAR2 DEFAULT NULL,
          X_global_attribute10                VARCHAR2 DEFAULT NULL,
          X_global_attribute11                VARCHAR2 DEFAULT NULL,
          X_global_attribute12                VARCHAR2 DEFAULT NULL,
          X_global_attribute13                VARCHAR2 DEFAULT NULL,
          X_global_attribute14                VARCHAR2 DEFAULT NULL,
          X_global_attribute15                VARCHAR2 DEFAULT NULL,
          X_global_attribute16                VARCHAR2 DEFAULT NULL,
          X_global_attribute17                VARCHAR2 DEFAULT NULL,
          X_global_attribute18                VARCHAR2 DEFAULT NULL,
          X_global_attribute19                VARCHAR2 DEFAULT NULL,
          X_global_attribute20                VARCHAR2 DEFAULT NULL,
          X_calling_sequence           IN     VARCHAR2,
          X_gl_date                           DATE,
          X_award_Id                          NUMBER,
          X_approval_iteration                NUMBER,
          X_approval_ready_flag               VARCHAR2,
          X_wfapproval_status                 VARCHAR2,
          X_requester_id                      NUMBER DEFAULT NULL,
          -- Invoice Lines Project Stage 1
          X_quick_credit                      VARCHAR2 DEFAULT NULL,
          X_credited_invoice_id               NUMBER   DEFAULT NULL,
          X_distribution_set_iD               NUMBER   DEFAULT NULL,
	  --ETAX: Invwkb
	  X_FORCE_REVALIDATION_FLAG            VARCHAR2 DEFAULT NULL,
	  X_CONTROL_AMOUNT                     NUMBER   DEFAULT NULL,
	  X_TAX_RELATED_INVOICE_ID             NUMBER   DEFAULT NULL,
	  X_TRX_BUSINESS_CATEGORY              VARCHAR2 DEFAULT NULL,
	  X_USER_DEFINED_FISC_CLASS            VARCHAR2 DEFAULT NULL,
	  X_TAXATION_COUNTRY                   VARCHAR2 DEFAULT NULL,
	  X_DOCUMENT_SUB_TYPE                  VARCHAR2 DEFAULT NULL,
	  X_SUPPLIER_TAX_INVOICE_NUMBER        VARCHAR2 DEFAULT NULL,
	  X_SUPPLIER_TAX_INVOICE_DATE          DATE     DEFAULT NULL,
	  X_SUPPLIER_TAX_EXCHANGE_RATE         NUMBER   DEFAULT NULL,
	  X_TAX_INVOICE_RECORDING_DATE         DATE     DEFAULT NULL,
	  X_TAX_INVOICE_INTERNAL_SEQ           VARCHAR2 DEFAULT NULL, -- bug 8912305: modify
	  X_QUICK_PO_HEADER_ID		       NUMBER   DEFAULT NULL,
          x_PAYMENT_METHOD_CODE                varchar2 ,
          x_PAYMENT_REASON_CODE                varchar2 default null,
          X_PAYMENT_REASON_COMMENTS            varchar2 default null,
          x_UNIQUE_REMITTANCE_IDENTIFIER       varchar2 default null,
          x_URI_CHECK_DIGIT                    varchar2 default null,
          x_BANK_CHARGE_BEARER                 varchar2 default null,
          x_DELIVERY_CHANNEL_CODE              varchar2 default null,
          x_SETTLEMENT_PRIORITY                varchar2 default null,
	  x_NET_OF_RETAINAGE_FLAG	       varchar2 default null,
	  x_RELEASE_AMOUNT_NET_OF_TAX	       number   default null,
	  x_PORT_OF_ENTRY_CODE		       varchar2 default null,
          x_external_bank_account_id           number   default null,
          x_party_id                           number   default null,
          x_party_site_id                      number   default null,
          /* bug 4931755. Exclude Tax and Freight from Discount */
          x_disc_is_inv_less_tax_flag          varchar2 default null,
          x_exclude_freight_from_disc          varchar2 default null,
          -- Bug 5087834
          x_remit_msg1                         varchar2 default null,
          x_remit_msg2                         varchar2 default null,
          x_remit_msg3                         varchar2 default null,
	  /* Third Party Payments*/
	  x_remit_to_supplier_name	varchar2 default null,
	  x_remit_to_supplier_id	number default null,
	  x_remit_to_supplier_site	varchar2 default null,
	  x_remit_to_supplier_site_id number default null,
	  x_relationship_id		number default null,
	  /* Bug 7831073 */
	  x_original_invoice_amount number default null,
	  x_dispute_reason varchar2 default null
) IS

  --Modified below cursor for bug #9254176
  --Added rtrim for all varchar2 fields.

  CURSOR C IS
  SELECT
        INVOICE_ID,
        LAST_UPDATE_DATE,
        LAST_UPDATED_BY,
        VENDOR_ID,
        rtrim(INVOICE_NUM) INVOICE_NUM,
        SET_OF_BOOKS_ID,
        rtrim(INVOICE_CURRENCY_CODE) INVOICE_CURRENCY_CODE,
        rtrim(PAYMENT_CURRENCY_CODE) PAYMENT_CURRENCY_CODE,
        PAYMENT_CROSS_RATE,
        INVOICE_AMOUNT,
        VENDOR_SITE_ID,
        AMOUNT_PAID,
        DISCOUNT_AMOUNT_TAKEN,
        INVOICE_DATE,
        rtrim(SOURCE) SOURCE,
        rtrim(INVOICE_TYPE_LOOKUP_CODE) INVOICE_TYPE_LOOKUP_CODE,
        rtrim(DESCRIPTION) DESCRIPTION,
        BATCH_ID,
        AMOUNT_APPLICABLE_TO_DISCOUNT,
        TERMS_ID,
        TERMS_DATE,
        rtrim(PAY_GROUP_LOOKUP_CODE) PAY_GROUP_LOOKUP_CODE,
        ACCTS_PAY_CODE_COMBINATION_ID,
        PAYMENT_STATUS_FLAG,
        CREATION_DATE,
        CREATED_BY,
        BASE_AMOUNT,
        LAST_UPDATE_LOGIN,
        EXCLUSIVE_PAYMENT_FLAG,
        PO_HEADER_ID,
        GOODS_RECEIVED_DATE,
        INVOICE_RECEIVED_DATE,
        rtrim(VOUCHER_NUM) VOUCHER_NUM,
        APPROVED_AMOUNT,
        RECURRING_PAYMENT_ID,
        EXCHANGE_RATE,
        rtrim(EXCHANGE_RATE_TYPE) EXCHANGE_RATE_TYPE,
        EXCHANGE_DATE,
        EARLIEST_SETTLEMENT_DATE,
        ORIGINAL_PREPAYMENT_AMOUNT,
        DOC_SEQUENCE_ID,
        DOC_SEQUENCE_VALUE,
        DOC_CATEGORY_CODE,
       ATTRIBUTE1,
       ATTRIBUTE2,
       ATTRIBUTE3,
       ATTRIBUTE4,
       ATTRIBUTE5,
       ATTRIBUTE6,
       ATTRIBUTE7,
       ATTRIBUTE8,
       ATTRIBUTE9,
       ATTRIBUTE10,
       ATTRIBUTE11,
       ATTRIBUTE12,
       ATTRIBUTE13,
       ATTRIBUTE14,
       ATTRIBUTE15,
        rtrim(ATTRIBUTE_CATEGORY) ATTRIBUTE_CATEGORY,
        rtrim(APPROVAL_STATUS) APPROVAL_STATUS,
        rtrim(APPROVAL_DESCRIPTION) APPROVAL_DESCRIPTION,
        POSTING_STATUS,
        AP_INVOICES_PKG.GET_POSTING_STATUS(INVOICE_ID) POSTING_FLAG,
        AUTHORIZED_BY,
        CANCELLED_DATE,
        CANCELLED_BY,
        CANCELLED_AMOUNT,
        TEMP_CANCELLED_AMOUNT,
        PROJECT_ID,
        TASK_ID,
        rtrim(EXPENDITURE_TYPE) EXPENDITURE_TYPE,
        EXPENDITURE_ITEM_DATE,
        PA_QUANTITY,
        EXPENDITURE_ORGANIZATION_ID,
        PA_DEFAULT_DIST_CCID,
        VENDOR_PREPAY_AMOUNT,
        PAYMENT_AMOUNT_TOTAL,
        AWT_FLAG,
        AWT_GROUP_ID,
	PAY_AWT_GROUP_ID,  --bug6639866
        REFERENCE_1,
        REFERENCE_2,
        ORG_ID,
        rtrim(GLOBAL_ATTRIBUTE_CATEGORY) GLOBAL_ATTRIBUTE_CATEGORY,
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
        rtrim(PAYMENT_CROSS_RATE_TYPE) PAYMENT_CROSS_RATE_TYPE,
        PAYMENT_CROSS_RATE_DATE,
        PAY_CURR_INVOICE_AMOUNT,
        MRC_BASE_AMOUNT,
        MRC_EXCHANGE_RATE,
        rtrim(MRC_EXCHANGE_RATE_TYPE) MRC_EXCHANGE_RATE_TYPE,
        MRC_EXCHANGE_DATE,
        GL_DATE,
        AWARD_ID,
        APPROVAL_ITERATION,
        APPROVAL_READY_FLAG,
        rtrim(WFAPPROVAL_STATUS) WFAPPROVAL_STATUS,
        REQUESTER_ID, --2289496
        -- Invoice Lines Project Stage 1
        QUICK_CREDIT,
        CREDITED_INVOICE_ID,
        DISTRIBUTION_SET_ID,
	FORCE_REVALIDATION_FLAG,
	CONTROL_AMOUNT,
	TAX_RELATED_INVOICE_ID,
        rtrim(TRX_BUSINESS_CATEGORY) TRX_BUSINESS_CATEGORY,
        rtrim(USER_DEFINED_FISC_CLASS) USER_DEFINED_FISC_CLASS,
	rtrim(TAXATION_COUNTRY) TAXATION_COUNTRY,
	rtrim(DOCUMENT_SUB_TYPE) DOCUMENT_SUB_TYPE,
	rtrim(SUPPLIER_TAX_INVOICE_NUMBER) SUPPLIER_TAX_INVOICE_NUMBER,
	SUPPLIER_TAX_INVOICE_DATE,
	SUPPLIER_TAX_EXCHANGE_RATE,
	TAX_INVOICE_RECORDING_DATE,
	TAX_INVOICE_INTERNAL_SEQ,
	QUICK_PO_HEADER_ID,
        rtrim(PAYMENT_METHOD_CODE) PAYMENT_METHOD_CODE,
        rtrim(PAYMENT_REASON_CODE) PAYMENT_REASON_CODE,
        rtrim(PAYMENT_REASON_COMMENTS) PAYMENT_REASON_COMMENTS,
        rtrim(UNIQUE_REMITTANCE_IDENTIFIER) UNIQUE_REMITTANCE_IDENTIFIER,
        URI_CHECK_DIGIT,
        rtrim(BANK_CHARGE_BEARER) BANK_CHARGE_BEARER,
        rtrim(DELIVERY_CHANNEL_CODE) DELIVERY_CHANNEL_CODE,
        rtrim(SETTLEMENT_PRIORITY) SETTLEMENT_PRIORITY,
        NET_OF_RETAINAGE_FLAG,
	RELEASE_AMOUNT_NET_OF_TAX,
	rtrim(PORT_OF_ENTRY_CODE) PORT_OF_ENTRY_CODE,
        external_bank_account_id,
        party_id,
        party_site_id,
        disc_is_inv_less_tax_flag,
        exclude_freight_from_discount,
        rtrim(REMITTANCE_MESSAGE1) REMITTANCE_MESSAGE1,
        rtrim(REMITTANCE_MESSAGE2) REMITTANCE_MESSAGE2,
        rtrim(REMITTANCE_MESSAGE3) REMITTANCE_MESSAGE3,
	rtrim(REMIT_TO_SUPPLIER_NAME) REMIT_TO_SUPPLIER_NAME,
	REMIT_TO_SUPPLIER_ID,
	rtrim(REMIT_TO_SUPPLIER_SITE) REMIT_TO_SUPPLIER_SITE,
	REMIT_TO_SUPPLIER_SITE_ID,
	RELATIONSHIP_ID,
	/* Bug 7831073 */
	original_invoice_amount,
	rtrim(dispute_reason) dispute_reason
    FROM  ap_invoices_all
   WHERE  rowid = X_Rowid
     FOR UPDATE of Invoice_Id NOWAIT;

  Recinfo C%ROWTYPE;
  first_conditions BOOLEAN := TRUE;
  second_conditions BOOLEAN := TRUE;
  current_calling_sequence      VARCHAR2(2000);
  debug_info                    VARCHAR2(100);

BEGIN
  -- Update the calling sequence

  current_calling_sequence :=
               'AP_INVOICES_PKG.LOCK_ROW<-'||X_calling_sequence;

  debug_info := 'Open cursor C';
  OPEN C;
  debug_info := 'Fetch cursor C';
  FETCH C INTO Recinfo;

  IF (C%NOTFOUND) THEN
    debug_info := 'Close cursor C - ROW NOTFOUND';
    CLOSE C;
    RAISE NO_DATA_FOUND;
  END IF;
  debug_info := 'Close cursor C';
  CLOSE C;

  first_conditions :=
     (
          (   (Recinfo.invoice_id = X_Invoice_Id)
           OR (    (Recinfo.invoice_id IS NULL)
               AND (X_Invoice_Id IS NULL)))
      AND (   (Recinfo.vendor_id = X_Vendor_Id)
           OR (    (Recinfo.vendor_id IS NULL)
               AND (X_Vendor_Id IS NULL)))
      AND (   (Recinfo.invoice_num = X_Invoice_Num)
           OR (    (Recinfo.invoice_num IS NULL)
               AND (X_Invoice_Num IS NULL)))
      AND (   (Recinfo.invoice_amount = X_Invoice_Amount)
           OR (    (Recinfo.invoice_amount IS NULL)
               AND (X_Invoice_Amount IS NULL)))
      AND (   (Recinfo.vendor_site_id = X_Vendor_Site_Id)
           OR (    (Recinfo.vendor_site_id IS NULL)
               AND (X_Vendor_Site_Id IS NULL)))
      AND (   (Recinfo.amount_paid = X_Amount_Paid)
           OR (    (Recinfo.amount_paid IS NULL)
               AND (X_Amount_Paid IS NULL)))
      AND (   (Recinfo.discount_amount_taken = X_Discount_Amount_Taken)
           OR (    (Recinfo.discount_amount_taken IS NULL)
               AND (X_Discount_Amount_Taken IS NULL)))
      AND (   (Recinfo.invoice_date = X_Invoice_Date)
           OR (    (Recinfo.invoice_date IS NULL)
               AND (X_Invoice_Date IS NULL)))
      AND (   (Recinfo.source = X_Source)
           OR (    (Recinfo.source IS NULL)
               AND (X_Source IS NULL)))
      AND (   (Recinfo.invoice_type_lookup_code = X_Invoice_Type_Lookup_Code)
           OR (    (Recinfo.invoice_type_lookup_code IS NULL)
               AND (X_Invoice_Type_Lookup_Code IS NULL)))
      AND (   (Recinfo.description = X_Description)
           OR (    (Recinfo.description IS NULL)
               AND (X_Description IS NULL)))
      AND (   (Recinfo.batch_id = X_Batch_Id)
           OR (    (Recinfo.batch_id IS NULL)
               AND (X_Batch_Id IS NULL)))
      AND (   (Recinfo.amount_applicable_to_discount =
                             X_Amt_Applicable_To_Discount)
           OR (    (Recinfo.amount_applicable_to_discount IS NULL)
               AND (X_Amt_Applicable_To_Discount IS NULL)))
      AND (   (Recinfo.terms_id = X_Terms_Id)
           OR (    (Recinfo.terms_id IS NULL)
               AND (X_Terms_Id IS NULL)))
      AND (   (Recinfo.terms_date = X_Terms_Date)
           OR (    (Recinfo.terms_date IS NULL)
               AND (X_Terms_Date IS NULL)))
      AND (   (Recinfo.goods_received_date = X_Goods_Received_Date)
           OR (    (Recinfo.goods_received_date IS NULL)
               AND (X_Goods_Received_Date IS NULL)))
      AND (   (Recinfo.invoice_received_date = X_Invoice_Received_Date)
           OR (    (Recinfo.invoice_received_date IS NULL)
               AND (X_Invoice_Received_Date IS NULL)))
      AND (   (Recinfo.voucher_num = X_Voucher_Num)
           OR (    (Recinfo.voucher_num IS NULL)
               AND (X_Voucher_Num IS NULL)))
      AND (   (Recinfo.approved_amount = X_Approved_Amount)
           OR (    (Recinfo.approved_amount IS NULL)
               AND (X_Approved_Amount IS NULL)))
      AND (   (Recinfo.approval_status = X_Approval_Status)
           OR (    (Recinfo.approval_status IS NULL)
               AND (X_Approval_Status IS NULL)))
      AND (   (Recinfo.approval_description = X_Approval_Description)
           OR (    (Recinfo.approval_description IS NULL)
               AND (X_Approval_Description IS NULL)))
      AND (   (Recinfo.pay_group_lookup_code = X_Pay_Group_Lookup_Code)
           OR (    (Recinfo.pay_group_lookup_code IS NULL)
               AND (X_Pay_Group_Lookup_Code IS NULL)))
      AND (   (Recinfo.set_of_books_id = X_Set_Of_Books_Id)
           OR (    (Recinfo.set_of_books_id IS NULL)
               AND (X_Set_Of_Books_Id IS NULL)))
      AND (   (Recinfo.accts_pay_code_combination_id = X_Accts_Pay_CCId)
           OR (    (Recinfo.accts_pay_code_combination_id IS NULL)
               AND (X_Accts_Pay_CCId IS NULL)))
      AND (   (Recinfo.recurring_payment_id = X_Recurring_Payment_Id)
           OR (    (Recinfo.recurring_payment_id IS NULL)
               AND (X_Recurring_Payment_Id IS NULL)))
      AND (   (Recinfo.invoice_currency_code = X_Invoice_Currency_Code)
           OR (    (Recinfo.invoice_currency_code IS NULL)
               AND (X_Invoice_Currency_Code IS NULL)))
      AND (   (Recinfo.payment_currency_code = X_Payment_Currency_Code)
           OR (    (Recinfo.payment_currency_code IS NULL)
               AND (X_Payment_Currency_Code IS NULL)))
      AND (   (Recinfo.exchange_rate = X_Exchange_Rate)
           OR (    (Recinfo.exchange_rate IS NULL)
               AND (X_Exchange_Rate IS NULL)))
      AND (   (Recinfo.payment_amount_total = X_Payment_Amount_Total)
           OR (    (Recinfo.payment_amount_total IS NULL)
               AND (X_Payment_Amount_Total IS NULL)))
      AND (   (Recinfo.payment_status_flag = X_Payment_Status_Flag)
           OR (    (Recinfo.payment_status_flag IS NULL)
               AND (X_Payment_Status_Flag IS NULL)))
      AND (   (Recinfo.posting_status = X_Posting_Status)
           OR (    (Recinfo.posting_status IS NULL)
               AND (X_Posting_Status IS NULL)))
      AND (   (Recinfo.posting_flag = X_Posting_Flag)
           OR (    (Recinfo.posting_flag IS NULL)
               AND (X_Posting_Flag IS NULL)))
      AND (   (Recinfo.authorized_by = X_Authorized_By)
           OR (    (Recinfo.authorized_by IS NULL)
               AND (X_Authorized_By IS NULL)))
      AND (   (Recinfo.attribute_category = X_Attribute_Category)
           OR (    (Recinfo.attribute_category IS NULL)
               AND (X_Attribute_Category IS NULL)))
      AND (   (Recinfo.attribute1 = X_Attribute1)
           OR (    (Recinfo.attribute1 IS NULL)
               AND (X_Attribute1 IS NULL)))
      AND (   (Recinfo.attribute2 = X_Attribute2)
           OR (    (Recinfo.attribute2 IS NULL)
               AND (X_Attribute2 IS NULL)))
      AND (   (Recinfo.attribute3 = X_Attribute3)
           OR (    (Recinfo.attribute3 IS NULL)
               AND (X_Attribute3 IS NULL)))
      AND (   (Recinfo.attribute4 = X_Attribute4)
           OR (    (Recinfo.attribute4 IS NULL)
               AND (X_Attribute4 IS NULL)))
      AND (   (Recinfo.attribute5 = X_Attribute5)
           OR (    (Recinfo.attribute5 IS NULL)
               AND (X_Attribute5 IS NULL)))
      AND (   (Recinfo.vendor_prepay_amount = X_Vendor_Prepay_Amount)
           OR (    (Recinfo.vendor_prepay_amount IS NULL)
               AND (X_Vendor_Prepay_Amount IS NULL)))
      -- Third Party Payments
      AND (   (Recinfo.remit_to_supplier_id = X_remit_to_supplier_Id)
           OR (    (Recinfo.remit_to_supplier_id IS NULL)
               AND (X_remit_to_supplier_Id IS NULL)))
      AND (   (Recinfo.remit_to_supplier_site_id = X_remit_to_supplier_site_Id)
           OR (    (Recinfo.remit_to_supplier_site_id IS NULL)
               AND (X_remit_to_supplier_site_Id IS NULL)))
      AND (   (Recinfo.relationship_id = X_relationship_id)
           OR (    (Recinfo.relationship_id IS NULL)
               AND (X_relationship_id IS NULL))));

   second_conditions :=
   (
     (   (Recinfo.base_amount = X_Base_Amount)
           OR (    (Recinfo.base_amount IS NULL)
               AND (X_Base_Amount IS NULL)))
      AND (   (Recinfo.exchange_rate_type = X_Exchange_Rate_Type)
           OR (    (Recinfo.exchange_rate_type IS NULL)
               AND (X_Exchange_Rate_Type IS NULL)))
      AND (   (Recinfo.exchange_date = X_Exchange_Date)
           OR (    (Recinfo.exchange_date IS NULL)
               AND (X_Exchange_Date IS NULL)))
      AND (   (Recinfo.payment_cross_rate = X_Payment_Cross_Rate)
           OR (    (Recinfo.payment_cross_rate IS NULL)
               AND (X_Payment_Cross_Rate IS NULL)))
      AND (   (Recinfo.payment_cross_rate_type = X_Payment_Cross_Rate_Type)
           OR (    (Recinfo.payment_cross_rate_type IS NULL)
               AND (X_Payment_Cross_Rate_Type IS NULL)))
      AND (   (Recinfo.payment_cross_rate_date = X_Payment_Cross_Rate_Date)
           OR (    (Recinfo.payment_cross_rate_date IS NULL)
               AND (X_Payment_Cross_Rate_Date IS NULL)))
      AND (   (nvl(Recinfo.pay_curr_invoice_amount,Recinfo.invoice_amount) =
                                X_Pay_Curr_Invoice_Amount)
           OR (    (Recinfo.pay_curr_invoice_amount IS NULL)
               AND (X_Pay_Curr_Invoice_Amount IS NULL)))
      AND (   (Recinfo.earliest_settlement_date = X_Earliest_Settlement_Date)
           OR (    (Recinfo.earliest_settlement_date IS NULL)
               AND (X_Earliest_Settlement_Date IS NULL)))
      AND (   (Recinfo.attribute11 = X_Attribute11)
           OR (    (Recinfo.attribute11 IS NULL)
               AND (X_Attribute11 IS NULL)))
      AND (   (Recinfo.attribute12 = X_Attribute12)
           OR (    (Recinfo.attribute12 IS NULL)
               AND (X_Attribute12 IS NULL)))
      AND (   (Recinfo.attribute13 = X_Attribute13)
           OR (    (Recinfo.attribute13 IS NULL)
               AND (X_Attribute13 IS NULL)))
      AND (   (Recinfo.attribute14 = X_Attribute14)
           OR (    (Recinfo.attribute14 IS NULL)
               AND (X_Attribute14 IS NULL)))
      AND (   (Recinfo.attribute6 = X_Attribute6)
           OR (    (Recinfo.attribute6 IS NULL)
               AND (X_Attribute6 IS NULL)))
      AND (   (Recinfo.attribute7 = X_Attribute7)
           OR (    (Recinfo.attribute7 IS NULL)
               AND (X_Attribute7 IS NULL)))
      AND (   (Recinfo.attribute8 = X_Attribute8)
           OR (    (Recinfo.attribute8 IS NULL)
               AND (X_Attribute8 IS NULL)))
      AND (   (Recinfo.attribute9 = X_Attribute9)
           OR (    (Recinfo.attribute9 IS NULL)
               AND (X_Attribute9 IS NULL)))
      AND (   (Recinfo.attribute10 = X_Attribute10)
           OR (    (Recinfo.attribute10 IS NULL)
               AND (X_Attribute10 IS NULL)))
      AND (   (Recinfo.attribute15 = X_Attribute15)
           OR (    (Recinfo.attribute15 IS NULL)
               AND (X_Attribute15 IS NULL)))
      AND (   (Recinfo.cancelled_date = X_Cancelled_Date)
           OR (    (Recinfo.cancelled_date IS NULL)
               AND (X_Cancelled_Date IS NULL)))
      AND (   (Recinfo.cancelled_by = X_Cancelled_By)
           OR (    (Recinfo.cancelled_by IS NULL)
               AND (X_Cancelled_By IS NULL)))
      AND (   (Recinfo.cancelled_amount = X_Cancelled_Amount)
           OR (    (Recinfo.cancelled_amount IS NULL)
               AND (X_Cancelled_Amount IS NULL)))
      AND (   (Recinfo.temp_cancelled_amount = X_Temp_Cancelled_Amount)
           OR (    (Recinfo.temp_cancelled_amount IS NULL)
               AND (X_Temp_Cancelled_Amount IS NULL)))
      AND (   (Recinfo.exclusive_payment_flag = X_Exclusive_Payment_Flag)
           OR (    (Recinfo.exclusive_payment_flag IS NULL)
               AND (X_Exclusive_Payment_Flag IS NULL)))
      AND (   (Recinfo.po_header_id = X_Po_Header_Id)
           OR (    (Recinfo.po_header_id IS NULL)
               AND (X_Po_Header_Id IS NULL)))
      AND (   (Recinfo.doc_sequence_id = X_Doc_Sequence_Id)
           OR (    (Recinfo.doc_sequence_id IS NULL)
               AND (X_Doc_Sequence_Id IS NULL)))
      AND (   (Recinfo.doc_sequence_value = X_Doc_Sequence_Value)
           OR (    (Recinfo.doc_sequence_value IS NULL)
               AND (X_Doc_Sequence_Value IS NULL)))
      AND (   (Recinfo.doc_category_code = X_Doc_Category_Code)
           OR (    (Recinfo.doc_category_code IS NULL)
               AND (X_Doc_Category_Code IS NULL)))
      AND (   (Recinfo.expenditure_item_date = X_Expenditure_Item_Date)
           OR (    (Recinfo.expenditure_item_date IS NULL)
               AND (X_Expenditure_Item_Date IS NULL)))
      AND (   (Recinfo.expenditure_organization_id =
                          X_Expenditure_Organization_Id)
           OR (    (Recinfo.expenditure_organization_id IS NULL)
               AND (X_Expenditure_Organization_Id IS NULL)))
      AND (   (Recinfo.expenditure_type = X_Expenditure_Type)
           OR (    (Recinfo.expenditure_type IS NULL)
               AND (X_Expenditure_Type IS NULL)))
      AND (   (Recinfo.pa_default_dist_ccid = X_Pa_Default_Dist_Ccid)
           OR (    (Recinfo.pa_default_dist_ccid IS NULL)
               AND (X_Pa_Default_Dist_Ccid IS NULL)))
      AND (   (Recinfo.pa_quantity = X_Pa_Quantity)
           OR (    (Recinfo.pa_quantity IS NULL)
               AND (X_Pa_Quantity IS NULL)))
      AND (   (Recinfo.project_id = X_Project_Id)
           OR (    (Recinfo.project_id IS NULL)
               AND (X_Project_Id IS NULL))));

   IF (first_conditions
      AND second_conditions
      AND (   (Recinfo.task_id = X_Task_Id)
           OR (    (Recinfo.task_id IS NULL)
               AND (X_Task_Id IS NULL)))
      AND (   (Recinfo.awt_flag = X_Awt_Flag)
           OR (    (Recinfo.awt_flag IS NULL)
               AND (X_Awt_Flag IS NULL)))
      AND (   (Recinfo.awt_group_id = X_Awt_Group_Id)
           OR (    (Recinfo.awt_group_id IS NULL)
               AND (X_Awt_Group_Id IS NULL)))
       AND (   (Recinfo.Pay_awt_group_id = X_Pay_Awt_Group_Id)
           OR (    (Recinfo.Pay_awt_group_id IS NULL)
               AND (X_Pay_Awt_Group_Id IS NULL)))              --bug6639866
      AND (   (Recinfo.reference_1 = X_Reference_1)
           OR (    (Recinfo.reference_1 IS NULL)
               AND (X_Reference_1 IS NULL)))
      AND (   (Recinfo.reference_2 = X_Reference_2)
           OR (    (Recinfo.reference_2 IS NULL)
               AND (X_Reference_2 IS NULL)))
      AND (   (Recinfo.global_attribute_category =
                       X_global_attribute_category)
           OR (    (Recinfo.global_attribute_category IS NULL)
               AND (X_global_attribute_category IS NULL)))
      AND (   (Recinfo.global_attribute1 =  X_global_attribute1)
           OR (    (Recinfo.global_attribute1 IS NULL)
               AND (X_global_attribute1 IS NULL)))
      AND (   (Recinfo.global_attribute2 =  X_global_attribute2)
           OR (    (Recinfo.global_attribute2 IS NULL)
               AND (X_global_attribute2 IS NULL)))
      AND (   (Recinfo.global_attribute3 =  X_global_attribute3)
           OR (    (Recinfo.global_attribute3 IS NULL)
               AND (X_global_attribute3 IS NULL)))
      AND (   (Recinfo.global_attribute4 =  X_global_attribute4)
           OR (    (Recinfo.global_attribute4 IS NULL)
               AND (X_global_attribute4 IS NULL)))
      AND (   (Recinfo.global_attribute5 =  X_global_attribute5)
           OR (    (Recinfo.global_attribute5 IS NULL)
               AND (X_global_attribute5 IS NULL)))
      AND (   (Recinfo.global_attribute6 =  X_global_attribute6)
           OR (    (Recinfo.global_attribute6 IS NULL)
               AND (X_global_attribute6 IS NULL)))
      AND (   (Recinfo.global_attribute7 =  X_global_attribute7)
           OR (    (Recinfo.global_attribute7 IS NULL)
               AND (X_global_attribute7 IS NULL)))
      AND (   (Recinfo.global_attribute8 =  X_global_attribute8)
           OR (    (Recinfo.global_attribute8 IS NULL)
               AND (X_global_attribute8 IS NULL)))
      AND (   (Recinfo.global_attribute9 =  X_global_attribute9)
           OR (    (Recinfo.global_attribute9 IS NULL)
               AND (X_global_attribute9 IS NULL)))
      AND (   (Recinfo.global_attribute10 =  X_global_attribute10)
           OR (    (Recinfo.global_attribute10 IS NULL)
               AND (X_global_attribute10 IS NULL)))
      AND (   (Recinfo.global_attribute11 =  X_global_attribute11)
           OR (    (Recinfo.global_attribute11 IS NULL)
               AND (X_global_attribute11 IS NULL)))
      AND (   (Recinfo.global_attribute12 =  X_global_attribute12)
           OR (    (Recinfo.global_attribute12 IS NULL)
               AND (X_global_attribute12 IS NULL)))
      AND (   (Recinfo.global_attribute13 =  X_global_attribute13)
           OR (    (Recinfo.global_attribute13 IS NULL)
               AND (X_global_attribute13 IS NULL)))
      AND (   (Recinfo.global_attribute14 =  X_global_attribute14)
           OR (    (Recinfo.global_attribute14 IS NULL)
               AND (X_global_attribute14 IS NULL)))
      AND (   (Recinfo.global_attribute15 =  X_global_attribute15)
           OR (    (Recinfo.global_attribute15 IS NULL)
               AND (X_global_attribute15 IS NULL)))
      AND (   (Recinfo.global_attribute16 =  X_global_attribute16)
           OR (    (Recinfo.global_attribute16 IS NULL)
               AND (X_global_attribute16 IS NULL)))
      AND (   (Recinfo.global_attribute17 =  X_global_attribute17)
           OR (    (Recinfo.global_attribute17 IS NULL)
               AND (X_global_attribute17 IS NULL)))
      AND (   (Recinfo.global_attribute18 =  X_global_attribute18)
           OR (    (Recinfo.global_attribute18 IS NULL)
               AND (X_global_attribute18 IS NULL)))
      AND (   (Recinfo.global_attribute19 =  X_global_attribute19)
           OR (    (Recinfo.global_attribute19 IS NULL)
               AND (X_global_attribute19 IS NULL)))
      AND (   (Recinfo.global_attribute20 =  X_global_attribute20)
           OR (    (Recinfo.global_attribute20 IS NULL)
               AND (X_global_attribute20 IS NULL)))
      AND (   (Recinfo.gl_date =  X_gl_date)
           OR (    (Recinfo.gl_date IS NULL)
               AND (X_gl_date IS NULL)))
      AND (   (Recinfo.award_id =  X_Award_Id)
           OR (    (Recinfo.award_id IS NULL)
               AND (X_Award_Id IS NULL)))
      AND (   (Recinfo.Approval_iteration =  X_Approval_Iteration)
           OR (    (Recinfo.approval_iteration IS NULL)
               AND (X_approval_iteration IS NULL)))
      AND (   (Recinfo.approval_ready_flag =  X_approval_ready_flag)
           OR (    (Recinfo.approval_ready_flag IS NULL)
               AND (X_approval_ready_flag IS NULL)))
      AND (   (Recinfo.wfapproval_status =  X_wfapproval_status)
           OR (    (Recinfo.wfapproval_status IS NULL)
               AND (X_wfapproval_status IS NULL)))
      AND (   (Recinfo.requester_id =  X_requester_id)
           OR (    (Recinfo.requester_id IS NULL)
               AND (X_requester_id IS NULL)))
      -- Invoice Lines Project Stage 1
      AND (   (Recinfo.quick_credit =  X_quick_credit)
           OR (    (Recinfo.quick_credit IS NULL)
               AND (X_quick_credit IS NULL)))
      AND (   (Recinfo.credited_invoice_id =  X_credited_invoice_id)
           OR (    (Recinfo.credited_invoice_id IS NULL)
               AND (X_credited_invoice_id IS NULL)))
      AND (   (Recinfo.distribution_set_id =  X_distribution_set_id)
           OR (    (Recinfo.distribution_set_id IS NULL)
               AND (X_distribution_set_id IS NULL)))
      -- Moac project
      AND (   (Recinfo.org_id =  X_org_id)
           OR (    (Recinfo.org_id IS NULL)
               AND (X_org_id IS NULL)))
      AND (   (Recinfo.disc_is_inv_less_tax_flag =  X_disc_is_inv_less_tax_flag)
           OR (    (Recinfo.disc_is_inv_less_tax_flag IS NULL)
               AND (X_disc_is_inv_less_tax_flag IS NULL)))
      AND (   (Recinfo.exclude_freight_from_discount =  X_exclude_freight_from_disc)
           OR (    (Recinfo.exclude_freight_from_discount IS NULL)
               AND (X_exclude_freight_from_disc IS NULL)))

      --ETAX: Invwkb
      AND (   (Recinfo.force_revalidation_flag =  X_force_revalidation_flag)
                 OR (    (Recinfo.force_revalidation_flag IS NULL)
		                AND (X_force_revalidation_flag IS NULL)))
      AND (   (Recinfo.control_amount =  X_control_amount)
                 OR (    (Recinfo.control_amount IS NULL)
		                AND (X_control_amount IS NULL)))
      AND (   (Recinfo.TAX_RELATED_INVOICE_ID =  X_TAX_RELATED_INVOICE_ID)
                 OR (    (Recinfo.TAX_RELATED_INVOICE_ID IS NULL)
		                AND (X_TAX_RELATED_INVOICE_ID IS NULL)))
      AND (   (Recinfo.TRX_BUSINESS_CATEGORY =  X_TRX_BUSINESS_CATEGORY)
                 OR (    (Recinfo.TRX_BUSINESS_CATEGORY IS NULL)
		                AND (X_TRX_BUSINESS_CATEGORY IS NULL)))
      AND (   (Recinfo.USER_DEFINED_FISC_CLASS =  X_USER_DEFINED_FISC_CLASS)
                 OR (    (Recinfo.USER_DEFINED_FISC_CLASS IS NULL)
		                AND (X_USER_DEFINED_FISC_CLASS IS NULL)))
      AND (   (Recinfo.TAXATION_COUNTRY =  X_TAXATION_COUNTRY)
                 OR (    (Recinfo.TAXATION_COUNTRY IS NULL)
		                AND (X_TAXATION_COUNTRY IS NULL)))
      AND (   (Recinfo.DOCUMENT_SUB_TYPE =  X_DOCUMENT_SUB_TYPE)
                 OR (    (Recinfo.DOCUMENT_SUB_TYPE IS NULL)
		                AND (X_DOCUMENT_SUB_TYPE IS NULL)))
      AND (   (Recinfo.SUPPLIER_TAX_INVOICE_NUMBER =  X_SUPPLIER_TAX_INVOICE_NUMBER)
                 OR (    (Recinfo.SUPPLIER_TAX_INVOICE_NUMBER IS NULL)
		                AND (X_SUPPLIER_TAX_INVOICE_NUMBER IS NULL)))
      AND (   (Recinfo.SUPPLIER_TAX_INVOICE_DATE =  X_SUPPLIER_TAX_INVOICE_DATE)
                 OR (    (Recinfo.SUPPLIER_TAX_INVOICE_DATE IS NULL)
		                AND (X_SUPPLIER_TAX_INVOICE_DATE IS NULL)))
      AND (   (Recinfo.SUPPLIER_TAX_EXCHANGE_RATE =  X_SUPPLIER_TAX_EXCHANGE_RATE)
                 OR (    (Recinfo.SUPPLIER_TAX_EXCHANGE_RATE IS NULL)
		                AND (X_SUPPLIER_TAX_EXCHANGE_RATE IS NULL)))
      AND (   (Recinfo.TAX_INVOICE_RECORDING_DATE =  X_TAX_INVOICE_RECORDING_DATE)
                 OR (    (Recinfo.TAX_INVOICE_RECORDING_DATE IS NULL)
		                AND (X_TAX_INVOICE_RECORDING_DATE IS NULL)))
      AND (   (Recinfo.TAX_INVOICE_INTERNAL_SEQ =  X_TAX_INVOICE_INTERNAL_SEQ)
                 OR (    (Recinfo.TAX_INVOICE_INTERNAL_SEQ IS NULL)
		                AND (X_TAX_INVOICE_INTERNAL_SEQ IS NULL)))
      AND (   (Recinfo.QUICK_PO_HEADER_ID =  X_QUICK_PO_HEADER_ID)
                 OR (    (Recinfo.QUICK_PO_HEADER_ID IS NULL)
			        AND (X_QUICK_PO_HEADER_ID IS NULL)))
      AND (   (Recinfo.PAYMENT_METHOD_CODE =  X_PAYMENT_METHOD_CODE)
                 OR (    (Recinfo.PAYMENT_METHOD_CODE IS NULL)
                                AND (X_PAYMENT_METHOD_CODE IS NULL)))
      AND (   (Recinfo.PAYMENT_REASON_CODE =  X_PAYMENT_REASON_CODE)
                 OR (    (Recinfo.PAYMENT_REASON_CODE IS NULL)
                                AND (X_PAYMENT_REASON_CODE IS NULL)))
      AND (   (Recinfo.PAYMENT_REASON_COMMENTS =  X_PAYMENT_REASON_COMMENTS)
                 OR (    (Recinfo.PAYMENT_REASON_COMMENTS IS NULL)
                                AND (X_PAYMENT_REASON_COMMENTS IS NULL)))
      AND (   (Recinfo.UNIQUE_REMITTANCE_IDENTIFIER =  X_UNIQUE_REMITTANCE_IDENTIFIER)
                 OR (    (Recinfo.UNIQUE_REMITTANCE_IDENTIFIER IS NULL)
                                AND (X_UNIQUE_REMITTANCE_IDENTIFIER IS NULL)))
      AND (   (Recinfo.URI_CHECK_DIGIT =  X_URI_CHECK_DIGIT)
                 OR (    (Recinfo.URI_CHECK_DIGIT IS NULL)
                                AND (X_URI_CHECK_DIGIT IS NULL)))
      AND (   (Recinfo.BANK_CHARGE_BEARER =  X_BANK_CHARGE_BEARER)
                 OR (    (Recinfo.BANK_CHARGE_BEARER IS NULL)
                                AND (X_BANK_CHARGE_BEARER IS NULL)))
      AND (   (Recinfo.DELIVERY_CHANNEL_CODE =  X_DELIVERY_CHANNEL_CODE)
                 OR (    (Recinfo.DELIVERY_CHANNEL_CODE IS NULL)
                                AND (X_DELIVERY_CHANNEL_CODE IS NULL)))
      AND (   (Recinfo.SETTLEMENT_PRIORITY =  X_SETTLEMENT_PRIORITY)
                 OR (    (Recinfo.SETTLEMENT_PRIORITY IS NULL)
                                AND (X_SETTLEMENT_PRIORITY IS NULL)))
      AND (   (Recinfo.NET_OF_RETAINAGE_FLAG =  X_NET_OF_RETAINAGE_FLAG)
                 OR (    (Recinfo.NET_OF_RETAINAGE_FLAG IS NULL)
                                AND (X_NET_OF_RETAINAGE_FLAG IS NULL)))
      AND (   (Recinfo.RELEASE_AMOUNT_NET_OF_TAX =  X_RELEASE_AMOUNT_NET_OF_TAX)
                 OR (    (Recinfo.RELEASE_AMOUNT_NET_OF_TAX IS NULL)
                                AND (X_RELEASE_AMOUNT_NET_OF_TAX IS NULL)))
      AND (   (Recinfo.PORT_OF_ENTRY_CODE =  X_PORT_OF_ENTRY_CODE)
                 OR (    (Recinfo.PORT_OF_ENTRY_CODE IS NULL)
                                AND (X_PORT_OF_ENTRY_CODE IS NULL)))
      AND (   (Recinfo.external_bank_account_id =  X_external_bank_account_id)
                 OR (    (Recinfo.external_bank_account_id IS NULL)
                                AND (x_external_bank_account_id IS NULL)))
      AND (   (Recinfo.party_id =  X_party_id)
                 OR (    (Recinfo.party_id IS NULL)
                                AND (x_party_id IS NULL)))
      AND (   (Recinfo.party_site_id =  X_party_site_id)
                 OR (    (Recinfo.party_site_id IS NULL)
                                AND (x_party_site_id IS NULL)))
      -- Bug 5087834
      AND (   (Recinfo.REMITTANCE_MESSAGE1 =  x_remit_msg1)
                 OR (    (Recinfo.REMITTANCE_MESSAGE1 IS NULL)
                                AND (x_remit_msg1 IS NULL)))
      AND (   (Recinfo.REMITTANCE_MESSAGE2 =  x_remit_msg2)
                 OR (    (Recinfo.REMITTANCE_MESSAGE2 IS NULL)
                                AND (x_remit_msg2 IS NULL)))
      AND (   (Recinfo.REMITTANCE_MESSAGE3 =  x_remit_msg3)
                 OR (    (Recinfo.REMITTANCE_MESSAGE3 IS NULL)
                                AND (x_remit_msg3 IS NULL)))
          ) then
    RETURN;
  ELSE
    FND_MESSAGE.Set_Name('FND', 'FORM_RECORD_CHANGED');
    APP_EXCEPTION.RAISE_EXCEPTION;
  END IF;

  EXCEPTION
     WHEN NO_DATA_FOUND THEN
          RETURN;
     WHEN OTHERS THEN
         IF (SQLCODE <> -20001) THEN
           IF (SQLCODE = -54) THEN
             FND_MESSAGE.SET_NAME('SQLAP','AP_RESOURCE_BUSY');
           ELSE
             FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
             FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
             FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',
                       current_calling_sequence);
             FND_MESSAGE.SET_TOKEN('PARAMETERS',
                 'X_Rowid = '||X_Rowid
             ||', X_invoice_id = '||X_invoice_id
                                  );
             FND_MESSAGE.SET_TOKEN('DEBUG_INFO',debug_info);
           END IF;
         END IF;
         APP_EXCEPTION.RAISE_EXCEPTION;

END Lock_Row;

PROCEDURE Lock_Row(
         X_invoice_id               NUMBER,
         X_calling_sequence  IN     VARCHAR2) IS
  CURSOR C IS
  SELECT
        INVOICE_ID,
        LAST_UPDATE_DATE,
        LAST_UPDATED_BY,
        VENDOR_ID,
        INVOICE_NUM,
        SET_OF_BOOKS_ID,
        INVOICE_CURRENCY_CODE,
        PAYMENT_CURRENCY_CODE,
        PAYMENT_CROSS_RATE,
        INVOICE_AMOUNT,
        VENDOR_SITE_ID,
        AMOUNT_PAID,
        DISCOUNT_AMOUNT_TAKEN,
        INVOICE_DATE,
        SOURCE,
        INVOICE_TYPE_LOOKUP_CODE,
        DESCRIPTION,
        BATCH_ID,
        AMOUNT_APPLICABLE_TO_DISCOUNT,
        TERMS_ID,
        TERMS_DATE,
        PAY_GROUP_LOOKUP_CODE,
        ACCTS_PAY_CODE_COMBINATION_ID,
        PAYMENT_STATUS_FLAG,
        CREATION_DATE,
        CREATED_BY,
        BASE_AMOUNT,
        LAST_UPDATE_LOGIN,
        EXCLUSIVE_PAYMENT_FLAG,
        PO_HEADER_ID,
        GOODS_RECEIVED_DATE,
        INVOICE_RECEIVED_DATE,
        VOUCHER_NUM,
        APPROVED_AMOUNT,
        RECURRING_PAYMENT_ID,
        EXCHANGE_RATE,
        EXCHANGE_RATE_TYPE,
        EXCHANGE_DATE,
        EARLIEST_SETTLEMENT_DATE,
        ORIGINAL_PREPAYMENT_AMOUNT,
        DOC_SEQUENCE_ID,
        DOC_SEQUENCE_VALUE,
        DOC_CATEGORY_CODE,
        ATTRIBUTE1,
        ATTRIBUTE2,
        ATTRIBUTE3,
        ATTRIBUTE4,
        ATTRIBUTE5,
        ATTRIBUTE6,
        ATTRIBUTE7,
        ATTRIBUTE8,
        ATTRIBUTE9,
        ATTRIBUTE10,
        ATTRIBUTE11,
        ATTRIBUTE12,
        ATTRIBUTE13,
        ATTRIBUTE14,
        ATTRIBUTE15,
        ATTRIBUTE_CATEGORY,
        APPROVAL_STATUS,
        APPROVAL_DESCRIPTION,
        POSTING_STATUS,
        AUTHORIZED_BY,
        CANCELLED_DATE,
        CANCELLED_BY,
        CANCELLED_AMOUNT,
        TEMP_CANCELLED_AMOUNT,
        PROJECT_ID,
        TASK_ID,
        EXPENDITURE_TYPE,
        EXPENDITURE_ITEM_DATE,
        PA_QUANTITY,
        EXPENDITURE_ORGANIZATION_ID,
        PA_DEFAULT_DIST_CCID,
        VENDOR_PREPAY_AMOUNT,
        PAYMENT_AMOUNT_TOTAL,
        AWT_FLAG,
        AWT_GROUP_ID,
	PAY_AWT_GROUP_ID,       -- bug6639866
        REFERENCE_1,
        REFERENCE_2,
        ORG_ID,
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
        PAYMENT_CROSS_RATE_TYPE,
        PAYMENT_CROSS_RATE_DATE,
        PAY_CURR_INVOICE_AMOUNT,
        MRC_BASE_AMOUNT,
        MRC_EXCHANGE_RATE,
        MRC_EXCHANGE_RATE_TYPE,
        MRC_EXCHANGE_DATE,
        GL_DATE,
        AWARD_ID,
        APPROVAL_ITERATION,
        APPROVAL_READY_FLAG,
        WFAPPROVAL_STATUS,
        REQUESTER_ID, --2289496
        -- Invoice Lines Project Stage 1
        QUICK_CREDIT,
        CREDITED_INVOICE_ID,
        DISTRIBUTION_SET_ID,
	QUICK_PO_HEADER_ID,
        PAYMENT_METHOD_CODE,
        PAYMENT_REASON_CODE,
        PAYMENT_REASON_COMMENTS,
        UNIQUE_REMITTANCE_IDENTIFIER,
        URI_CHECK_DIGIT,
        BANK_CHARGE_BEARER,
        DELIVERY_CHANNEL_CODE,
        SETTLEMENT_PRIORITY,
        NET_OF_RETAINAGE_FLAG,
	RELEASE_AMOUNT_NET_OF_TAX,
	PORT_OF_ENTRY_CODE,
        external_bank_account_id,
        party_id,
        party_site_id,
        disc_is_inv_less_tax_flag,
        exclude_freight_from_discount,
        REMITTANCE_MESSAGE1,
        REMITTANCE_MESSAGE2,
        REMITTANCE_MESSAGE3,
	REMIT_TO_SUPPLIER_NAME,
	REMIT_TO_SUPPLIER_ID,
	REMIT_TO_SUPPLIER_SITE,
	REMIT_TO_SUPPLIER_SITE_ID,
	RELATIONSHIP_ID,
	/* Bug 7831073 */
	original_invoice_amount,
	dispute_reason
    FROM   ap_invoices_all
   WHERE  invoice_id = X_Invoice_id
     FOR UPDATE of Invoice_Id NOWAIT;

  Recinfo C%ROWTYPE;
  current_calling_sequence      VARCHAR2(2000);
  debug_info                    VARCHAR2(100);

BEGIN
  -- Update the calling sequence

  current_calling_sequence := 'AP_INVOICES_PKG.LOCK_ROW(Invoice_id)<-'||
                              X_calling_sequence;

  debug_info := 'Open cursor C';
  OPEN C;
  debug_info := 'Fetch cursor C';
  FETCH C INTO Recinfo;
  IF (C%NOTFOUND) THEN
    debug_info := 'Close cursor C - ROW NOTFOUND';
    CLOSE C;
    RAISE NO_DATA_FOUND;
  END IF;
  debug_info := 'Close cursor C';
  CLOSE C;

  EXCEPTION
     WHEN OTHERS THEN
       IF (SQLCODE <> -20001) THEN
         IF (SQLCODE = -54) THEN
           FND_MESSAGE.SET_NAME('SQLAP','AP_RESOURCE_BUSY');
         ELSE
           FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
           FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
           FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',
                     current_calling_sequence);
           FND_MESSAGE.SET_TOKEN('PARAMETERS',
               'X_invoice_id = '||X_invoice_id
                                    );
           FND_MESSAGE.SET_TOKEN('DEBUG_INFO',debug_info);
         END IF;
       END IF;
       APP_EXCEPTION.RAISE_EXCEPTION;

END Lock_Row;

PROCEDURE Update_Row(
          X_Rowid                             VARCHAR2,
          X_Invoice_Id                        NUMBER,
          X_Last_Update_Date                  DATE,
          X_Last_Updated_By                   NUMBER,
          X_Vendor_Id                         NUMBER,
          X_Invoice_Num                       VARCHAR2,
          X_Invoice_Amount                    NUMBER,
          X_Vendor_Site_Id                    NUMBER,
          X_Amount_Paid                       NUMBER,
          X_Discount_Amount_Taken             NUMBER,
          X_Invoice_Date                      DATE,
          X_Source                            VARCHAR2,
          X_Invoice_Type_Lookup_Code          VARCHAR2,
          X_Description                       VARCHAR2,
          X_Batch_Id                          NUMBER,
          X_Amt_Applicable_To_Discount        NUMBER,
          X_Terms_Id                          NUMBER,
          X_Terms_Date                        DATE,
          X_Goods_Received_Date               DATE,
          X_Invoice_Received_Date             DATE,
          X_Voucher_Num                       VARCHAR2,
          X_Approved_Amount                   NUMBER,
          X_Approval_Status                   VARCHAR2,
          X_Approval_Description              VARCHAR2,
          X_Pay_Group_Lookup_Code             VARCHAR2,
          X_Set_Of_Books_Id                   NUMBER,
          X_Accts_Pay_CCId                    NUMBER,
          X_Recurring_Payment_Id              NUMBER,
          X_Invoice_Currency_Code             VARCHAR2,
          X_Payment_Currency_Code             VARCHAR2,
          X_Exchange_Rate                     NUMBER,
          X_Payment_Amount_Total              NUMBER,
          X_Payment_Status_Flag               VARCHAR2,
          X_Posting_Status                    VARCHAR2,
          X_Authorized_By                     VARCHAR2,
          X_Attribute_Category                VARCHAR2,
          X_Attribute1                        VARCHAR2,
          X_Attribute2                        VARCHAR2,
          X_Attribute3                        VARCHAR2,
          X_Attribute4                        VARCHAR2,
          X_Attribute5                        VARCHAR2,
          X_Vendor_Prepay_Amount              NUMBER,
          X_Base_Amount                       NUMBER,
          X_Exchange_Rate_Type                VARCHAR2,
          X_Exchange_Date                     DATE,
          X_Payment_Cross_Rate                NUMBER,
          X_Payment_Cross_Rate_Type           VARCHAR2,
          X_Payment_Cross_Rate_Date           DATE,
          X_Pay_Curr_Invoice_Amount           NUMBER,
          X_Last_Update_Login                 NUMBER,
          X_Original_Prepayment_Amount        NUMBER,
          X_Earliest_Settlement_Date          DATE,
          X_Attribute11                       VARCHAR2,
          X_Attribute12                       VARCHAR2,
          X_Attribute13                       VARCHAR2,
          X_Attribute14                       VARCHAR2,
          X_Attribute6                        VARCHAR2,
          X_Attribute7                        VARCHAR2,
          X_Attribute8                        VARCHAR2,
          X_Attribute9                        VARCHAR2,
          X_Attribute10                       VARCHAR2,
          X_Attribute15                       VARCHAR2,
          X_Cancelled_Date                    DATE,
          X_Cancelled_By                      NUMBER,
          X_Cancelled_Amount                  NUMBER,
          X_Temp_Cancelled_Amount             NUMBER,
          X_Exclusive_Payment_Flag            VARCHAR2,
          X_Po_Header_Id                      NUMBER,
          X_Doc_Sequence_Id                   NUMBER,
          X_Doc_Sequence_Value                NUMBER,
          X_Doc_Category_Code                 VARCHAR2,
          X_Expenditure_Item_Date             DATE,
          X_Expenditure_Organization_Id       NUMBER,
          X_Expenditure_Type                  VARCHAR2,
          X_Pa_Default_Dist_Ccid              NUMBER,
          X_Pa_Quantity                       NUMBER,
          X_Project_Id                        NUMBER,
          X_Task_Id                           NUMBER,
          X_Awt_Flag                          VARCHAR2,
          X_Awt_Group_Id                      NUMBER,
	  X_Pay_Awt_Group_Id                  NUMBER,--bug6639866
          X_Reference_1                       VARCHAR2,
          X_Reference_2                       VARCHAR2,
          X_Org_Id                            NUMBER,
          X_global_attribute_category         VARCHAR2 DEFAULT NULL,
          X_global_attribute1                 VARCHAR2 DEFAULT NULL,
          X_global_attribute2                 VARCHAR2 DEFAULT NULL,
          X_global_attribute3                 VARCHAR2 DEFAULT NULL,
          X_global_attribute4                 VARCHAR2 DEFAULT NULL,
          X_global_attribute5                 VARCHAR2 DEFAULT NULL,
          X_global_attribute6                 VARCHAR2 DEFAULT NULL,
          X_global_attribute7                 VARCHAR2 DEFAULT NULL,
          X_global_attribute8                 VARCHAR2 DEFAULT NULL,
          X_global_attribute9                 VARCHAR2 DEFAULT NULL,
          X_global_attribute10                VARCHAR2 DEFAULT NULL,
          X_global_attribute11                VARCHAR2 DEFAULT NULL,
          X_global_attribute12                VARCHAR2 DEFAULT NULL,
          X_global_attribute13                VARCHAR2 DEFAULT NULL,
          X_global_attribute14                VARCHAR2 DEFAULT NULL,
          X_global_attribute15                VARCHAR2 DEFAULT NULL,
          X_global_attribute16                VARCHAR2 DEFAULT NULL,
          X_global_attribute17                VARCHAR2 DEFAULT NULL,
          X_global_attribute18                VARCHAR2 DEFAULT NULL,
          X_global_attribute19                VARCHAR2 DEFAULT NULL,
          X_global_attribute20                VARCHAR2 DEFAULT NULL,
          X_calling_sequence           IN     VARCHAR2,
          X_gl_date                           DATE,
          X_award_Id                          NUMBER,
          X_approval_iteration                NUMBER,
          X_approval_ready_flag               VARCHAR2,
          X_wfapproval_status                 VARCHAR2,
          X_requester_id                      NUMBER   DEFAULT NULL,
          -- Invoice Lines Project Stage 1
          X_quick_credit                      VARCHAR2 DEFAULT NULL,
          X_credited_invoice_id               NUMBER   DEFAULT NULL,
          X_distribution_set_id               NUMBER   DEFAULT NULL,
	  --ETAX: Invwkb
	  X_FORCE_REVALIDATION_FLAG            VARCHAR2 DEFAULT NULL,
	  X_CONTROL_AMOUNT                     NUMBER   DEFAULT NULL,
	  X_TAX_RELATED_INVOICE_ID             NUMBER   DEFAULT NULL,
	  X_TRX_BUSINESS_CATEGORY              VARCHAR2 DEFAULT NULL,
	  X_USER_DEFINED_FISC_CLASS            VARCHAR2 DEFAULT NULL,
	  X_TAXATION_COUNTRY                   VARCHAR2 DEFAULT NULL,
	  X_DOCUMENT_SUB_TYPE                  VARCHAR2 DEFAULT NULL,
	  X_SUPPLIER_TAX_INVOICE_NUMBER        VARCHAR2 DEFAULT NULL,
	  X_SUPPLIER_TAX_INVOICE_DATE          DATE     DEFAULT NULL,
	  X_SUPPLIER_TAX_EXCHANGE_RATE         NUMBER   DEFAULT NULL,
	  X_TAX_INVOICE_RECORDING_DATE         DATE     DEFAULT NULL,
	  X_TAX_INVOICE_INTERNAL_SEQ           VARCHAR2 DEFAULT NULL, -- bug 8912305: modify
	  X_QUICK_PO_HEADER_ID		       NUMBER   DEFAULT NULL,
          x_PAYMENT_METHOD_CODE                varchar2 ,
          x_PAYMENT_REASON_CODE                varchar2 default null,
          X_PAYMENT_REASON_COMMENTS            varchar2 default null,
          x_UNIQUE_REMITTANCE_IDENTIFIER       varchar2 default null,
          x_URI_CHECK_DIGIT                    varchar2 default null,
          x_BANK_CHARGE_BEARER                 varchar2 default null,
          x_DELIVERY_CHANNEL_CODE              varchar2 default null,
          x_SETTLEMENT_PRIORITY                varchar2 default null,
	  x_NET_OF_RETAINAGE_FLAG	       varchar2 default null,
	  x_RELEASE_AMOUNT_NET_OF_TAX	       number   default null,
	  x_PORT_OF_ENTRY_CODE		       varchar2 default null,
          x_external_bank_account_id           number   default null,
          x_party_id                           number   default null,
          x_party_site_id                      number   default null,
          /* bug 4931755. Exclude Tax and Freight from Discount */
          x_disc_is_inv_less_tax_flag          varchar2 default null,
          x_exclude_freight_from_disc          varchar2 default null,
          x_remit_msg1                         varchar2 default null,
          x_remit_msg2                         varchar2 default null,
          x_remit_msg3                         varchar2 default null,
	  /* Third Party Payments*/
	  x_remit_to_supplier_name	varchar2 default null,
	  x_remit_to_supplier_id	number default null,
	  x_remit_to_supplier_site	varchar2 default null,
	  x_remit_to_supplier_site_id number default null,
	  x_relationship_id		number default null,
	  /* Bug 7831073 */
	  x_original_invoice_amount number default null,
	  x_dispute_reason varchar2 default null
) IS
  current_calling_sequence      VARCHAR2(2000);
  debug_info                    VARCHAR2(100);
  l_invoice_id                  NUMBER;
  l_return_status               VARCHAR2(2000);   -- Bug 7570234
  -- Bug 10103631 Start
  l_event_source_info           XLA_EVENTS_PUB_PKG.t_event_source_info;
  l_event_security_context      XLA_EVENTS_PUB_PKG.t_security;
  l_le_id			NUMBER(15);
  l_is_update_required		VARCHAR2(2000) ;
  l_api_name			CONSTANT VARCHAR2(100) := 'Update_Row';
  -- Bug 10103631 End

  --bug 17758819 Start
  l_synchronize_tax_flag        VARCHAR2(1);  -- Bug 16368920
  l_tax_only_inv                VARCHAR2(1);
  l_currency_conversion_rate   zx_rec_nrec_dist.currency_conversion_rate%TYPE;
  l_err_code                   zx_errors_gt.message_text%TYPE;
  --bug 17758819 End
BEGIN

  -- Update the calling sequence

  current_calling_sequence := 'AP_INVOICES_PKG.UPDATE_ROW<-'||
                              X_calling_sequence;

  -- Bug 10103631
  SELECT CASE WHEN NULLIF(X_Invoice_Num,ai.invoice_num) IS NOT NULL
                   AND EXISTS ( SELECT 1
	                          FROM ap_invoice_distributions aid
	                         WHERE aid.invoice_id = ai.invoice_id
		                   AND aid.accounting_event_id IS NOT NULL
			           AND rownum = 1
		              )
              THEN 'TRUE'
	      ELSE 'FALSE'
	 END
    INTO l_is_update_required
    FROM ap_invoices ai
   WHERE rowid = X_Rowid ;

   BEGIN -- Bug 16368920
     SELECT 'N'
     INTO   l_synchronize_tax_flag
     FROM   AP_INVOICES_ALL
     WHERE  invoice_id                  = X_Invoice_Id
     AND    invoice_type_lookup_code    = X_Invoice_Type_Lookup_Code
     AND    invoice_num                 = X_Invoice_Num
     AND    ((description = X_description) OR
             (X_description IS NULL and description IS NULL))
     AND    ((doc_sequence_id = X_Doc_Sequence_Id) OR
             (X_Doc_Sequence_Id IS NULL and doc_sequence_id IS NULL))
     AND    ((doc_sequence_value = X_Doc_Sequence_Value) OR
             (X_Doc_Sequence_Value IS NULL and doc_sequence_value IS NULL))
     AND    ((batch_id = X_Batch_Id) OR
             (X_Batch_Id IS NULL and batch_id IS NULL))
     AND    invoice_date                = X_Invoice_Date
     AND    ((terms_date = X_Terms_Date) OR
             (X_Terms_Date IS NULL and terms_date IS NULL))
     AND    ((supplier_tax_invoice_number = X_Supplier_Tax_Invoice_Number) OR
             (X_Supplier_Tax_Invoice_Number IS NULL and
              supplier_tax_invoice_number IS NULL))
     AND    ((supplier_tax_invoice_date = X_Supplier_Tax_Invoice_Date) OR
             (X_Supplier_Tax_Invoice_Date IS NULL and
              supplier_tax_invoice_date IS NULL))
     AND    ((supplier_tax_exchange_rate = X_Supplier_Tax_Exchange_Rate) OR
             (X_Supplier_Tax_Exchange_Rate IS NULL and
              supplier_tax_exchange_rate IS NULL))
     AND    ((tax_invoice_internal_seq = X_Tax_Invoice_Internal_Seq) OR
             (X_Tax_Invoice_Internal_Seq IS NULL and
              tax_invoice_internal_seq IS NULL))
     AND    ((tax_invoice_recording_date = X_Tax_Invoice_Recording_Date) OR
             (X_Tax_Invoice_Recording_Date IS NULL and
              tax_invoice_recording_date IS NULL))
     AND    ((quick_credit = X_quick_credit) OR
             (X_quick_credit IS NULL and quick_credit IS NULL))
     AND    ((credited_invoice_id = X_credited_invoice_id) OR
             (X_credited_invoice_id IS NULL and credited_invoice_id IS NULL))
     AND    ((document_sub_type = X_DOCUMENT_SUB_TYPE) OR  /* Bug17612737: Start: Added below columns check */
             (X_DOCUMENT_SUB_TYPE IS NULL and document_sub_type IS NULL))
     AND    ((taxation_country = X_TAXATION_COUNTRY) OR
             (X_TAXATION_COUNTRY IS NULL and taxation_country IS NULL))
     AND    vendor_id                   = X_Vendor_Id
     AND    vendor_site_id              = X_Vendor_Site_Id; /* Bug17612737: End */

   EXCEPTION
     WHEN NO_DATA_FOUND THEN
      l_synchronize_tax_flag := 'Y';
   END;

   debug_info := 'l_synchronize_tax_flag = ' || l_synchronize_tax_flag;
   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
   END IF;

   debug_info := 'l_is_update_required = ' || l_is_update_required ;
   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
   END IF;

   debug_info := 'Update ap_invoices';
   AP_AI_TABLE_HANDLER_PKG.Update_Row
         (X_Rowid,
          X_Invoice_Id,
          X_Last_Update_Date,
          X_Last_Updated_By,
          X_Vendor_Id,
          X_Invoice_Num,
          X_Invoice_Amount,
          X_Vendor_Site_Id,
          X_Amount_Paid,
          X_Discount_Amount_Taken,
          X_Invoice_Date,
          X_Source,
          X_Invoice_Type_Lookup_Code,
          X_Description,
          X_Batch_Id,
          X_Amt_Applicable_To_Discount,
          X_Terms_Id,
          X_Terms_Date,
          X_Goods_Received_Date,
          X_Invoice_Received_Date,
          X_Voucher_Num,
          X_Approved_Amount,
          X_Approval_Status,
          X_Approval_Description,
          X_Pay_Group_Lookup_Code,
          X_Set_Of_Books_Id,
          X_Accts_Pay_CCId,
          X_Recurring_Payment_Id,
          X_Invoice_Currency_Code,
          X_Payment_Currency_Code,
          X_Exchange_Rate,
          X_Payment_Amount_Total,
          X_Payment_Status_Flag,
          X_Posting_Status,
          X_Authorized_By,
          X_Attribute_Category,
          X_Attribute1,
          X_Attribute2,
          X_Attribute3,
          X_Attribute4,
          X_Attribute5,
          X_Vendor_Prepay_Amount,
          X_Base_Amount,
          X_Exchange_Rate_Type,
          X_Exchange_Date,
          X_Payment_Cross_Rate,
          X_Payment_Cross_Rate_Type,
          X_Payment_Cross_Rate_Date,
          X_Pay_Curr_Invoice_Amount,
          X_Last_Update_Login,
          X_Original_Prepayment_Amount,
          X_Earliest_Settlement_Date,
          X_Attribute11,
          X_Attribute12,
          X_Attribute13,
          X_Attribute14,
          X_Attribute6,
          X_Attribute7,
          X_Attribute8,
          X_Attribute9,
          X_Attribute10,
          X_Attribute15,
          X_Cancelled_Date,
          X_Cancelled_By,
          X_Cancelled_Amount,
          X_Temp_Cancelled_Amount,
          X_Exclusive_Payment_Flag,
          X_Po_Header_Id,
          X_Doc_Sequence_Id,
          X_Doc_Sequence_Value,
          X_Doc_Category_Code,
          X_Expenditure_Item_Date,
          X_Expenditure_Organization_Id,
          X_Expenditure_Type,
          X_Pa_Default_Dist_Ccid,
          X_Pa_Quantity,
          X_Project_Id,
          X_Task_Id,
          X_Awt_Flag,
          X_Awt_Group_Id,
	  X_Pay_Awt_Group_Id,--bug6639866
          X_Reference_1,
          X_Reference_2,
          X_Org_id,
          X_global_attribute_category,
          X_global_attribute1,
          X_global_attribute2,
          X_global_attribute3,
          X_global_attribute4,
          X_global_attribute5,
          X_global_attribute6,
          X_global_attribute7,
          X_global_attribute8,
          X_global_attribute9,
          X_global_attribute10,
          X_global_attribute11,
          X_global_attribute12,
          X_global_attribute13,
          X_global_attribute14,
          X_global_attribute15,
          X_global_attribute16,
          X_global_attribute17,
          X_global_attribute18,
          X_global_attribute19,
          X_global_attribute20,
          current_calling_sequence,
          X_gl_date,
          X_Award_Id,
          X_approval_iteration,
          X_approval_ready_flag,
          X_wfapproval_status,
          X_requester_id , --2289496
          -- Invoice Lines Project Stage 1
          X_quick_credit,
          X_credited_invoice_id,
          X_distribution_set_id,
	  X_FORCE_REVALIDATION_FLAG,
	  X_CONTROL_AMOUNT,
	  X_TAX_RELATED_INVOICE_ID,
	  X_TRX_BUSINESS_CATEGORY,
	  X_USER_DEFINED_FISC_CLASS,
	  X_TAXATION_COUNTRY,
	  X_DOCUMENT_SUB_TYPE,
	  X_SUPPLIER_TAX_INVOICE_NUMBER,
	  X_SUPPLIER_TAX_INVOICE_DATE,
	  X_SUPPLIER_TAX_EXCHANGE_RATE,
	  X_TAX_INVOICE_RECORDING_DATE,
	  X_TAX_INVOICE_INTERNAL_SEQ,
	  X_QUICK_PO_HEADER_ID,
          x_PAYMENT_METHOD_CODE ,
          x_PAYMENT_REASON_CODE,
          x_PAYMENT_REASON_COMMENTS,
          x_UNIQUE_REMITTANCE_IDENTIFIER,
          x_URI_CHECK_DIGIT,
          x_BANK_CHARGE_BEARER,
          x_DELIVERY_CHANNEL_CODE ,
          x_SETTLEMENT_PRIORITY,
          x_NET_OF_RETAINAGE_FLAG,
	  x_RELEASE_AMOUNT_NET_OF_TAX,
	  x_PORT_OF_ENTRY_CODE,
          x_external_bank_account_id,
          x_party_id,
          x_party_site_id,
          x_disc_is_inv_less_tax_flag,
          x_exclude_freight_from_disc,
          x_remit_msg1,
          x_remit_msg2,
          x_remit_msg3,
	  x_remit_to_supplier_name,
	  x_remit_to_supplier_id,
	  x_remit_to_supplier_site,
	  x_remit_to_supplier_site_id,
	  x_relationship_id,
	  /* Bug 7831073 */
	  x_original_invoice_amount,
	  x_dispute_reason
	  );

 -- Bug 7570234  Start
-- Bug 13402071: Calling AP_ETAX_SERVICES_PKG.synchronize_for_doc_seq regardless of
--               the invoice status
/*    IF (AP_INVOICES_PKG.get_approval_status(
                          X_Invoice_Id,
                          X_Invoice_Amount ,
                          X_Payment_Status_Flag ,
                          X_Invoice_Type_Lookup_Code)
         IN ('APPROVED','CANCELLED','AVAILABLE','FULL','UNPAID')) THEN */

    IF (l_synchronize_tax_flag = 'Y') THEN  -- Bug 16368920

        AP_ETAX_SERVICES_PKG.synchronize_for_doc_seq
                        (X_Invoice_Id,
                         current_calling_sequence,
                         l_return_status);

        debug_info:= 'After calling AP_ETAX_SERVICES_PKG.synchronize_for_doc_seq()';

        IF (l_return_status = FND_API.G_RET_STS_SUCCESS) THEN
            NULL;
        ELSE
            FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
            FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
            FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',current_calling_sequence);
            FND_MESSAGE.SET_TOKEN('PARAMETERS','X_Rowid = '||X_Rowid||', X_invoice_id = '||X_invoice_id);
            FND_MESSAGE.SET_TOKEN('DEBUG_INFO',debug_info);

            APP_EXCEPTION.RAISE_EXCEPTION;
        END IF;
/*    END IF;       */
 -- Bug 7570234  End

    END IF; -- 16368920

    -- Bug 10103631 Start
    IF l_is_update_required = 'TRUE' THEN
        debug_info := 'Calling Get_Invoice_LE';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
        END IF;

        AP_UTILITIES_PKG.Get_Invoice_LE( X_vendor_site_id,
                                         X_accts_pay_ccid,
                                         X_org_id,
                                         l_le_id
                                       );

        l_event_source_info.application_id         := 200;
        l_event_source_info.legal_entity_id        := l_le_id ;
        l_event_source_info.ledger_id              := X_set_of_books_id;
        l_event_source_info.entity_type_code       := 'AP_INVOICES';
        l_event_source_info.transaction_number     := X_invoice_num;
        l_event_source_info.source_id_int_1        := X_invoice_id;
        l_event_security_context.security_id_int_1 := X_org_id;

        debug_info:= 'Before calling XLA_EVENTS_PUB_PKG.update_transaction_number()';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
	   FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Parameters - ' ||
			  l_le_id || ', ' || X_set_of_books_id || ', ' || X_invoice_num||
			  ', ' || X_invoice_id || ', ' || X_org_id  );
        END IF;
        XLA_EVENTS_PUB_PKG.update_transaction_number( l_event_source_info,
                                                      X_invoice_num,
                                                      NULL,
                                                      l_event_security_context,
                                                      NULL
						    );
        debug_info:= 'After calling XLA_EVENTS_PUB_PKG.update_transaction_number()';
	IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
        END IF;
    END IF ;
    -- Bug 10103631 End

    -- Bug 17758819 Start

    debug_info:= 'Checking exchange rate update on tax only invoice';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
    END IF;

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
    END IF;

    IF(X_Exchange_Rate IS NOT NULL)THEN

        BEGIN
            SELECT 'Y'
              INTO l_tax_only_inv
              FROM AP_INVOICE_LINES_ALL AIL
             WHERE INVOICE_ID = X_INVOICE_ID
               AND LINE_TYPE_LOOKUP_CODE = 'TAX'
               AND NOT EXISTS ( SELECT 'NON TAX LINES'
                                  FROM AP_INVOICE_LINES_ALL AIL1
                                 WHERE AIL1.INVOICE_ID=AIL.INVOICE_ID
                                   AND LINE_TYPE_LOOKUP_CODE <> 'TAX');
            EXCEPTION
            WHEN OTHERS THEN
            l_tax_only_inv := 'N';
        END;

        debug_info:= 'Tax only invoice '||l_tax_only_inv;
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
        END IF;

        IF(l_tax_only_inv = 'Y' AND
            ap_invoices_utility_pkg.get_posting_status(X_invoice_id) <> 'Y') THEN

            debug_info:= 'Tax only invoice and not posted';
            IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
            END IF;

            BEGIN
                SELECT currency_conversion_rate
                  INTO l_currency_conversion_rate
                  FROM ZX_REC_NREC_DIST
                 WHERE trx_id = X_invoice_id
                   AND application_id=200
                   AND entity_code='AP_INVOICES'
                   AND ROWNUM = 1;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    l_currency_conversion_rate := NULL;
            END;

            debug_info:= 'l_currency_conversion_rate: '||l_currency_conversion_rate;
            IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
            END IF;

            IF (NVL(X_Exchange_Rate,0) <> NVL(l_currency_conversion_rate,0)) THEN
                debug_info:= 'Before calling AP_ETAX_UTILITY_PKG.UPDATE_EXCH_RATE';
                IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                    FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, debug_info);
                END IF;

                IF NOT(AP_ETAX_UTILITY_PKG.UPDATE_EXCH_RATE(
                                                            P_Org_Id                            => X_org_id,
                                                            P_Invoice_Id                        => X_invoice_id,
                                                            P_Tax_Already_Calculated_Flag       => 'Y',
                                                            P_Exch_Rate                         => X_Exchange_Rate,
                                                            P_Exch_Date                         => X_Exchange_Date,
                                                            P_Exch_Type                         => X_Exchange_Rate_Type,
                                                            P_Inv_Type                          => X_Invoice_Type_Lookup_Code,
                                                            P_error_code                        => l_err_code,
                                                            P_calling_sequence                  => 'ap_invoices_pkg.update_row'
                                                            )) THEN   --New API Created for  bug17758819
                    APP_EXCEPTION.RAISE_EXCEPTION;
                END IF;
            END IF; --Conversion rate check
        END IF;  --Tax only line exist
    END IF;   --Exchange rate not null

      -- Bug 17758819 End

  EXCEPTION
     WHEN OTHERS THEN
         IF (SQLCODE <> -20001) THEN
           FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
           FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
           FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',
                current_calling_sequence);
           FND_MESSAGE.SET_TOKEN('PARAMETERS',
               'X_Rowid = '||X_Rowid
           ||', X_invoice_id = '||X_invoice_id
                                    );
           FND_MESSAGE.SET_TOKEN('DEBUG_INFO',debug_info);
         END IF;
       APP_EXCEPTION.RAISE_EXCEPTION;

END Update_Row;

PROCEDURE Delete_Row(
         X_Rowid                   VARCHAR2,
         X_calling_sequence    IN  VARCHAR2)
  IS

  l_prepayments_applied_flag   VARCHAR2(1);
  l_encumbered_flag            VARCHAR2(1);
  l_payments_exist_flag        VARCHAR2(1);
  l_selected_for_payment_flag  VARCHAR2(1);
  l_posting_flag               VARCHAR2(1);
  l_po_number                  VARCHAR2(50); -- for CLM Bug 9503239
  l_prepay_amount_applied      NUMBER;
  l_approval_status            VARCHAR2(30);  -- Bug 5497262
  l_invoice_type               VARCHAR2(30);
  l_message_name               VARCHAR2(30) := '';
  l_invoice_id                 NUMBER;
  l_key_value_list             gl_ca_utility_pkg.r_key_value_arr;
  current_calling_sequence     VARCHAR2(2000);
  debug_info                   VARCHAR2(100);

BEGIN

  -- Update the calling sequence
  --
  current_calling_sequence := 'AP_INVOICES_PKG.DELETE_ROW<-'||
                              X_calling_sequence;

  -- Get the invoice_id
  debug_info := 'Get the invoice_id';

  SELECT  invoice_id
    INTO  l_invoice_id
    FROM  ap_invoices
   WHERE  rowid = X_rowid;

  -- Verify that the record being deleted meets the requirements
  -- for deletion
  debug_info := 'Get parameter values to check requirements for deletion';
  SELECT
     ap_invoices_pkg.get_prepayments_applied_flag(invoice_id),
     ap_invoices_pkg.get_encumbered_flag(invoice_id),
     ap_invoices_pkg.get_payments_exist_flag(invoice_id),
     ap_invoices_pkg.selected_for_payment_flag(invoice_id),
     ap_invoices_pkg.get_posting_status(invoice_id),
     ap_invoices_pkg.get_po_number(invoice_id),
     ap_invoices_pkg.get_prepay_amount_applied(invoice_id),
     ap_invoices_pkg.get_approval_status(invoice_id, invoice_amount,
                         payment_status_flag, invoice_type_lookup_code),  -- Bug 5497262
     invoice_type_lookup_code
    INTO
     l_prepayments_applied_flag,
     l_encumbered_flag,
     l_payments_exist_flag,
     l_selected_for_payment_flag,
     l_posting_flag,
     l_po_number,
     l_prepay_amount_applied,
     l_approval_status,
     l_invoice_type
    FROM  ap_invoices
   WHERE  rowid = X_Rowid;

  IF (l_prepayments_applied_flag = 'Y') THEN
    l_message_name := 'AP_INV_DEL_INV_PREPAYS';
  ELSIF (l_encumbered_flag <> 'N') THEN
    l_message_name := 'AP_INV_NO_UPDATE_APPROVED_INV';
  ELSIF (l_payments_exist_flag = 'Y') THEN
    l_message_name := 'AP_INV_NO_UPDATE_PAID_INV';
  ELSIF (l_selected_for_payment_flag = 'Y') THEN
    l_message_name := 'AP_INV_SELECTED_INVOICE';
  ELSIF (l_posting_flag <> 'N' or
         l_po_number <> 'UNMATCHED') THEN
    l_message_name := 'AP_INV_MATCHED_POSTED_INVOICE';
  ELSIF (l_prepay_amount_applied <> 0) THEN
    l_message_name := 'AP_INV_DEL_APPLIED_PREPAY';
  ELSIF (l_approval_status IN ('APPROVED', 'UNPAID')) THEN
    l_message_name := 'AP_INV_DEL_PAY_REQUEST';  -- Bug 5497262
  ELSIF (l_invoice_type = 'RETAINAGE RELEASE') THEN
    l_message_name := 'AP_INV_DEL_RET_RELEASE';
  END IF;

  IF (l_message_name is not null) THEN
    FND_MESSAGE.Set_Name('SQLAP', l_message_name);
    APP_EXCEPTION.RAISE_EXCEPTION;
  END IF;

  AP_AI_TABLE_HANDLER_PKG.Delete_Row(
     X_Rowid,
     current_calling_sequence);

  EXCEPTION
     WHEN OTHERS THEN
         IF (SQLCODE <> -20001) THEN
           FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
           FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
           FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',
                     current_calling_sequence);
           FND_MESSAGE.SET_TOKEN('PARAMETERS',
               'X_Rowid = '||X_Rowid
                                    );
           FND_MESSAGE.SET_TOKEN('DEBUG_INFO',debug_info);
         END IF;
       APP_EXCEPTION.RAISE_EXCEPTION;

END Delete_Row;


----------------------------------------------------------------------
-- FUNCTION get_max_line_number RETURNs the max line NUMBER given
-- an invoice id. It RETURNs 0 IF no lines found.
----------------------------------------------------------------------

FUNCTION Get_Max_Line_Number (X_invoice_id  IN  NUMBER) RETURN NUMBER
IS
    l_max_line_number NUMBER := 0;
BEGIN

   SELECT nvl(max(line_number),0)
     INTO l_max_line_number
     FROM ap_invoice_lines
    WHERE invoice_id = X_invoice_id;

  RETURN(l_max_line_number);
END get_max_line_number;

-----------------------------------------------------------------------
-- FUNCTION get_expenditure_item_date RETURNs the expenditure item date
-- to be used given PA's profile option: 'PA: Default Expenditure Item
-- Date for AP Invoices'
-----------------------------------------------------------------------

FUNCTION Get_Expenditure_Item_Date(
         X_invoice_id          IN         NUMBER,
         X_invoice_date        IN         DATE,
         X_GL_date             IN         DATE,
         X_po_dist_id          IN         NUMBER DEFAULT NULL,
         X_rcv_trx_id          IN         NUMBER DEFAULT NULL,
         X_error_found         OUT NOCOPY VARCHAR2) RETURN DATE
IS

  l_expenditure_item_date        DATE := NULL;
  l_expenditure_item_Date_prfl   VARCHAR2(240);
  l_po_date                      DATE := NULL;
  l_rcv_date                     DATE := NULL;
BEGIN


/*  IF (X_po_dist_id is not null) THEN
     BEGIN
       SELECT decode(destination_type_code, 'EXPENSE',
             expenditure_item_date,
             NULL)
         INTO l_po_date
         FROM po_distributions
        WHERE po_distribution_id = X_po_dist_id;

     EXCEPTION
       WHEN NO_DATA_FOUND THEN
          X_error_found := 'Y';
          RETURN(NULL);
     END;

  ELSIF (X_rcv_trx_id is not null) THEN
    BEGIN
      SELECT transaction_date
        INTO l_rcv_date
        FROM rcv_transactions
       WHERE transaction_id = X_rcv_trx_id;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        X_error_found := 'Y';
        RETURN(NULL);
    END;

  END IF;


  l_expenditure_item_Date_prfl :=
        NVL(FND_PROFILE.VALUE('PA_AP_EI_DATE_DEFAULT'), 'Transaction Date');

  --bugfix:4505249
  IF l_expenditure_item_Date_prfl = 'PO Expenditure Item Date/Transaction Date'
   THEN
     IF (l_po_date is not null) THEN
       l_expenditure_item_date := l_po_date;
     ELSE
       l_expenditure_item_Date := X_invoice_date;
     END IF;
  ELSIF l_expenditure_item_Date_prfl ='PO Expenditure Item Date/Transaction GL Date'
   THEN
     IF (l_po_date is not null) THEN
       l_expenditure_item_date := l_po_date;
     ELSE
       l_expenditure_item_date := X_GL_Date;
     END IF;
  ELSIF l_expenditure_item_Date_prfl = 'PO Expenditure Item Date/Transaction System Date'
   THEN
     IF (l_po_date is not null) THEN
       l_expenditure_item_date := l_po_date;
     ELSE
       l_expenditure_item_date := TRUNC(sysdate);
     END IF;
  ELSIF l_expenditure_item_Date_prfl = 'Receipt Date/Transaction Date' THEN
     IF (l_rcv_date is not null) THEN
       l_expenditure_item_date := l_rcv_date;
     ELSE
       l_expenditure_item_date := X_invoice_date;
     END IF;
  ELSIF l_expenditure_item_Date_prfl = 'Receipt Date/Transaction GL Date' THEN
     IF (l_rcv_date is not null) THEN
       l_expenditure_item_date := l_rcv_date;
     ELSE
       l_expenditure_item_date := X_GL_Date;
     END IF;
  ELSIF l_expenditure_item_Date_prfl = 'Receipt Date/Transaction System Date' THEN
     IF (l_rcv_date is not null) THEN
       l_expenditure_item_date := l_rcv_date;
     ELSE
       l_expenditure_item_date := TRUNC(SYSDATE);
     END IF;
  ELSIF l_expenditure_item_Date_prfl = 'Transaction Date' THEN
     l_expenditure_item_date := X_invoice_date;
  ELSIF l_expenditure_item_Date_prfl = 'Transaction GL Date' THEN
     l_expenditure_item_date := X_GL_date;
  ELSIF l_expenditure_item_Date_prfl = 'Transaction System Date' THEN
     l_expenditure_item_date := TRUNC(SYSDATE);
  ELSE
     l_expenditure_item_date := null;
  END IF;
  */

  -- Bug 5294998. Expenditure_Item_Dtae will retreived based on PA API
  l_expenditure_item_date :=
      PA_AP_INTEGRATION.Get_Si_Cost_Exp_Item_Date (
             p_transaction_date   =>  x_invoice_date,
             p_gl_date            =>  x_gl_date,
             p_creation_date      =>  sysdate,
             p_po_exp_item_date   =>  NULL,
             p_po_distribution_id =>  x_po_dist_id,
             p_calling_program    =>  'PO-MATCH');


  X_error_found := 'N';
  RETURN(l_expenditure_item_date);

  END get_expenditure_item_date;

  --=========================================================================
  -- The following functions have been mapped to AP_INVOICES_UTILITY_PKG
  -- (apinvuts.pls apinvutb.pls)
  --
  --=========================================================================
FUNCTION get_distribution_total(l_invoice_id IN NUMBER)
RETURN NUMBER
  IS
    l_distribution_total  NUMBER := 0;

BEGIN
  l_distribution_total := AP_INVOICES_UTILITY_PKG.get_distribution_total(
                          l_invoice_id);

RETURN(l_distribution_total);

END get_distribution_total;



FUNCTION get_posting_status(l_invoice_id IN NUMBER)
RETURN VARCHAR2
  IS
  l_invoice_posting_flag           VARCHAR2(1);

BEGIN
  l_invoice_posting_flag := AP_INVOICES_UTILITY_PKG.get_posting_status(
                            l_invoice_id);

RETURN(l_invoice_posting_flag);

END get_posting_status;

PROCEDURE CHECK_UNIQUE (
          X_ROWID                    VARCHAR2,
          X_INVOICE_NUM              VARCHAR2,
          X_VENDOR_ID                NUMBER,
          X_ORG_ID                   NUMBER,  /* Bug 5407785 */
	  X_PARTY_SITE_ID            NUMBER, /*Bug9105666*/
	  X_VENDOR_SITE_ID           NUMBER, /*Bug9105666*/
          X_calling_sequence  IN     VARCHAR2) IS
BEGIN

  AP_INVOICES_UTILITY_PKG.CHECK_UNIQUE (
          X_ROWID,
          X_INVOICE_NUM,
          X_VENDOR_ID,
          X_ORG_ID,    /* Bug 5407785 */
	  X_PARTY_SITE_ID, /*Bug9105666*/
          X_VENDOR_SITE_ID, /*Bug9105666*/
          X_calling_sequence);

EXCEPTION
  WHEN OTHERS THEN
    APP_EXCEPTION.RAISE_EXCEPTION;

END CHECK_UNIQUE;


PROCEDURE CHECK_UNIQUE_VOUCHER_NUM (
          X_ROWID                    VARCHAR2,
          X_VOUCHER_NUM              VARCHAR2,
          X_calling_sequence  IN     VARCHAR2) IS
BEGIN

  AP_INVOICES_UTILITY_PKG.CHECK_UNIQUE_VOUCHER_NUM (
          X_ROWID,
          X_VOUCHER_NUM,
          X_calling_sequence);

EXCEPTION
  WHEN OTHERS THEN
    APP_EXCEPTION.RAISE_EXCEPTION;

END CHECK_UNIQUE_VOUCHER_NUM;

FUNCTION get_approval_status(
          l_invoice_id               IN NUMBER,
          l_invoice_amount           IN NUMBER,
          l_payment_status_flag      IN VARCHAR2,
          l_invoice_type_lookup_code IN VARCHAR2)
RETURN VARCHAR2
IS
  l_invoice_approval_status         VARCHAR2(25);
BEGIN

   l_invoice_approval_status := AP_INVOICES_UTILITY_PKG.get_approval_status(
          l_invoice_id,
          l_invoice_amount,
          l_payment_status_flag,
          l_invoice_type_lookup_code);

RETURN(l_invoice_approval_status);

END get_approval_status;

FUNCTION get_po_number(l_invoice_id IN NUMBER)
RETURN VARCHAR2
IS
          l_po_number VARCHAR2(50); -- for CLM Bug 9503239
BEGIN
  l_po_number := AP_INVOICES_UTILITY_PKG.get_po_number(l_invoice_id);

RETURN(l_po_number);

END get_po_number;

FUNCTION get_release_number(l_invoice_id IN NUMBER)
RETURN VARCHAR2
IS
  l_release_number VARCHAR2(25);
BEGIN
  l_release_number := AP_INVOICES_UTILITY_PKG.get_release_number(l_invoice_id);

RETURN(l_release_number);

END get_release_number;


FUNCTION get_receipt_number(l_invoice_id IN NUMBER)
RETURN VARCHAR2
IS
  l_receipt_number RCV_SHIPMENT_HEADERS.RECEIPT_NUM%TYPE;   --Bug 16413390
BEGIN
  l_receipt_number := AP_INVOICES_UTILITY_PKG.get_receipt_number(l_invoice_id);

RETURN(l_receipt_number);

END get_receipt_number;

FUNCTION get_po_number_list(l_invoice_id IN NUMBER)
RETURN VARCHAR2
IS
  l_po_number_list VARCHAR2(5000) := NULL; -- for CLM Bug 9503239
BEGIN

  l_po_number_list := AP_INVOICES_UTILITY_PKG.get_po_number_list(l_invoice_id);

RETURN(l_po_number_list);

END get_po_number_list;

FUNCTION get_amount_withheld(l_invoice_id IN NUMBER)
RETURN NUMBER
IS
  l_amount_withheld           NUMBER := 0;
BEGIN
  l_amount_withheld := AP_INVOICES_UTILITY_PKG.get_amount_withheld(
                       l_invoice_id);

RETURN(l_amount_withheld);

END get_amount_withheld;

FUNCTION get_prepaid_amount(l_invoice_id IN NUMBER)
RETURN NUMBER
IS
  l_prepaid_amount           NUMBER := 0;
BEGIN
  l_prepaid_amount := AP_INVOICES_UTILITY_PKG.get_prepaid_amount(l_invoice_id);

RETURN(l_prepaid_amount);

END get_prepaid_amount;

FUNCTION get_notes_count(l_invoice_id IN NUMBER)
RETURN NUMBER
IS
  l_notes_count           NUMBER := 0;
BEGIN
  l_notes_count := AP_INVOICES_UTILITY_PKG.get_notes_count(l_invoice_id);
RETURN(l_notes_count);

END get_notes_count;

FUNCTION get_holds_count(l_invoice_id IN NUMBER)
RETURN NUMBER
IS
  l_holds_count           NUMBER := 0;
BEGIN
  l_holds_count := AP_INVOICES_UTILITY_PKG.get_holds_count(l_invoice_id);

RETURN(l_holds_count);

END get_holds_count;

--bug 5334577
FUNCTION get_sched_holds_count(l_invoice_id IN NUMBER)
RETURN NUMBER
IS
  l_holds_count           NUMBER := 0;
BEGIN
  l_holds_count := AP_INVOICES_UTILITY_PKG.get_sched_holds_count(l_invoice_id);

RETURN(l_holds_count);

END get_sched_holds_count;


FUNCTION get_total_prepays(
          l_vendor_id IN     NUMBER,
          l_org_id    IN     NUMBER)
RETURN NUMBER
IS
  l_prepay_count           NUMBER := 0;
BEGIN
  -- MOAC.  Added org_id parameter to FUNCTION and to call
  l_prepay_count := AP_INVOICES_UTILITY_PKG.get_total_prepays(
                    l_vendor_id,
                    l_org_id);
RETURN(l_prepay_count);

END get_total_prepays;

FUNCTION get_available_prepays(
          l_vendor_id IN NUMBER,
          l_org_id IN NUMBER)
RETURN NUMBER
IS
  l_prepay_count           NUMBER := 0;
BEGIN
  -- MOAC.  Added org_id parameter to FUNCTION and to call
  l_prepay_count := AP_INVOICES_UTILITY_PKG.get_available_prepays(
                    l_vendor_id,
                    l_org_id);

RETURN(l_prepay_count);

END get_available_prepays;

FUNCTION get_encumbered_flag(l_invoice_id IN NUMBER) RETURN VARCHAR2
IS
  l_encumbered_flag     VARCHAR2(1);

BEGIN
  l_encumbered_flag := AP_INVOICES_UTILITY_PKG.get_encumbered_flag(
                       l_invoice_id);

  RETURN(l_encumbered_flag);

END get_encumbered_flag;

FUNCTION get_amount_hold_flag(l_invoice_id IN NUMBER)
RETURN VARCHAR2
IS
  l_amount_hold_flag  VARCHAR2(1) := 'N';
BEGIN
  l_amount_hold_flag := AP_INVOICES_UTILITY_PKG.get_amount_hold_flag(
                        l_invoice_id);

RETURN(L_amount_hold_flag);

END get_amount_hold_flag;

FUNCTION get_vendor_hold_flag(l_invoice_id IN NUMBER)
RETURN VARCHAR2
IS
  l_vendor_hold_flag  VARCHAR2(1) := 'N';
BEGIN
  l_vendor_hold_flag := AP_INVOICES_UTILITY_PKG.get_vendor_hold_flag(
                        l_invoice_id);

RETURN(l_vendor_hold_flag);

END get_vendor_hold_flag;

-- --------------------------------------------------------------------------
-- Procedure get_gl_date_and_period() can be used to determine the
-- open period given a date.  This PROCEDURE will also allow you to
-- compare with a parent GL date, such as that of ap_batches for
-- ap_invoices.  You needn't pass a parent date, however, to determine
-- the next open period.  The GL date and period name are written to
-- IN OUT NOCOPY parameters, P_GL_Date and P_Period_Name, passed to the
-- procedure.  If there is no open period, the PROCEDURE RETURNs
-- null in the IN OUT NOCOPY parameters.
-- Instead of Calling the AP_INVOICES_UTILITY_PKG.get_gl_date_and_period,
-- the code has been SHIFTED into this PROCEDURE as a part of clean-up and
-- PROCEDURE get_gl_date_and_period is REMOVED from AP_INVOICE_UTILITY_PKG.
-- -------------------------------------------------------------------------

PROCEDURE Get_gl_date_and_period (
          P_Date              IN            DATE,
          P_Receipt_Date      IN            DATE DEFAULT NULL,
          P_Period_Name          OUT NOCOPY VARCHAR2,
          P_GL_Date              OUT NOCOPY DATE,
          P_Batch_GL_Date     IN            DATE DEFAULT NULL,
          P_Org_Id            IN            NUMBER DEFAULT
                                             MO_GLOBAL.GET_CURRENT_ORG_ID)
  IS
  l_period_name gl_period_statuses.period_name%TYPE := '';
  l_current_date date := '';
  l_gl_date date      := '';
  y_date date         := '';
  n_date date         := '';

BEGIN

  -- Determine which date we should be using

  -- First set up temporary variables y_date and n_date

  IF (P_Batch_GL_Date is null) THEN
    IF (P_Receipt_Date is null) THEN
       y_date := TRUNC(SYSDATE);
       n_date := TRUNC(P_date);
    ELSE
       y_date := TRUNC(P_Receipt_Date);
       n_date := TRUNC(P_Receipt_Date);
    END IF;
  END IF;

  -- MOAC.  Added org_id parameter and predicate to select statement
  SELECT NVL(P_Batch_GL_Date,
             DECODE(SP.gl_date_from_receipt_flag,
                   'S',TRUNC(SYSDATE),
                   'Y',y_date,
                   'N',n_date,
                   TRUNC(P_Date)))
    INTO l_current_date
    FROM ap_system_parameters_all SP  --5126689
   WHERE sp.org_id = p_org_id;

  -- Initialize the IN OUT NOCOPY variables
  P_GL_Date     := '';
  P_Period_Name := '';

  -- See IF the period corresponding to P_Date is open
   -- Added org_id parameter to this call MOAC
  l_period_name := ap_utilities_pkg.get_current_gl_date(
              l_current_date, P_Org_Id);

  IF (l_period_name is null) THEN

    -- The date is in a closed period, roll forward until we find one
    -- MOAC.  Added org_id parameter to call
    ap_utilities_pkg.get_open_gl_date
           (l_current_date,
            l_period_name,
            l_gl_date,
            P_Org_Id);
  ELSE
    -- No need to call the function.  The GL date will be the
    -- date passed to the function
    l_gl_date := l_current_date;
  END IF;

  P_Period_Name := l_Period_Name;
  P_GL_Date := l_GL_Date;

END Get_gl_date_and_period;

-- =====================================================================
--
-- Bug 803299 Added an extra parameter l_receipt_date in get_gl_date and
-- get_period_name function. Please refer to bug 991787 for the fix of
-- this bug.
-- =====================================================================

FUNCTION get_gl_date(
          l_invoice_date IN     DATE,
          l_receipt_date IN     DATE DEFAULT NULL)
RETURN DATE
IS
  l_GL_Date date := '';
  l_period_name gl_period_statuses.period_name%TYPE := ''; -- Not used
BEGIN

-- Call get_gl_date_and_period from ap_invoice_pkg instead of
--       ap_invoices_utiliy_pkg; Done as a part of clean-up act

        ap_invoices_pkg.get_gl_date_and_period(           -- get_gl_date
          l_invoice_date,
          l_receipt_date,
          l_period_name,
          l_GL_Date);

RETURN(l_GL_Date);
END get_gl_date;

FUNCTION get_period_name(
          l_invoice_date IN     DATE,
          l_receipt_date IN     DATE DEFAULT NULL,
          l_org_id       IN     NUMBER DEFAULT
                                 MO_GLOBAL.GET_CURRENT_ORG_ID)
RETURN VARCHAR2
IS
  l_GL_Date date := '';
  l_period_name gl_period_statuses.period_name%TYPE := '';
BEGIN

-- Call get_gl_date_and_period from ap_invoice_pkg instead of
-- ap_invoices_utiliy_pkg; Done as a part of clean-up act
-- MOAC.  Added org_id parameter to FUNCTION and call

  ap_invoices_pkg.get_gl_date_and_period(
         P_date         => l_invoice_date,
         P_Receipt_Date => l_receipt_date,
         P_Period_Name  => l_period_name,
         P_GL_Date      => l_GL_Date,
         P_Org_Id       => l_org_id);

RETURN(l_period_name);
END get_period_name;

FUNCTION get_similar_drcr_memo(
         P_vendor_id                IN NUMBER,
         P_vendor_site_id           IN NUMBER,
         P_invoice_amount           IN NUMBER,
         P_invoice_type_lookup_code IN VARCHAR2,
         P_invoice_currency_code    IN VARCHAR2,
         P_calling_sequence         IN VARCHAR2) RETURN VARCHAR2
IS
  l_invoice_num ap_invoices.invoice_num%TYPE;

BEGIN
  l_invoice_num := AP_INVOICES_UTILITY_PKG.get_similar_drcr_memo(
          P_vendor_id,
          P_vendor_site_id,
          P_invoice_amount,
          P_invoice_type_lookup_code,
          P_invoice_currency_code,
          P_calling_sequence);
RETURN(l_invoice_num);

END get_similar_drcr_memo;

FUNCTION eft_bank_details_exist (
          P_vendor_site_id   IN     NUMBER,
          P_calling_sequence IN     VARCHAR2) RETURN BOOLEAN
IS
  l_flag boolean;
BEGIN
  l_flag := AP_INVOICES_UTILITY_PKG.eft_bank_details_exist (
          P_vendor_site_id,
          P_calling_sequence);

RETURN(l_flag);

END eft_bank_details_exist;

FUNCTION eft_bank_curr_details_exist (P_vendor_site_id IN NUMBER,
          P_currency_code IN VARCHAR2,
          P_calling_sequence IN VARCHAR2) RETURN boolean
IS
  l_flag boolean;
BEGIN
  l_flag := AP_INVOICES_UTILITY_PKG.eft_bank_curr_details_exist (
          P_vendor_site_id,
          P_currency_code,
          P_calling_sequence);

RETURN(l_flag);

END eft_bank_curr_details_exist;

FUNCTION selected_for_payment_flag (
          P_invoice_id IN     NUMBER) RETURN VARCHAR2
IS
  l_flag VARCHAR2(1) := 'N';
BEGIN
  l_flag := AP_INVOICES_UTILITY_PKG.selected_for_payment_flag (P_invoice_id);

RETURN(l_flag);

END selected_for_payment_flag;

FUNCTION get_discount_pay_dists_flag (P_invoice_id IN NUMBER)
RETURN VARCHAR2
IS
  l_flag VARCHAR2(1) := 'N';
BEGIN
  l_flag := AP_INVOICES_UTILITY_PKG.get_discount_pay_dists_flag (P_invoice_id);

RETURN(l_flag);

END get_discount_pay_dists_flag;


FUNCTION get_unposted_void_payment (
          P_invoice_id IN     NUMBER)
RETURN VARCHAR2
IS
  l_flag VARCHAR2(1) := 'N';
BEGIN
  l_flag := AP_INVOICES_UTILITY_PKG.get_unposted_void_payment (P_invoice_id);

RETURN(l_flag);

END get_unposted_void_payment;

FUNCTION get_prepayments_applied_flag (
          P_invoice_id IN     NUMBER)
RETURN VARCHAR2
IS
  l_flag VARCHAR2(1) := 'N';
BEGIN
  l_flag := AP_INVOICES_UTILITY_PKG.get_prepayments_applied_flag (P_invoice_id);
RETURN(l_flag);

END get_prepayments_applied_flag;

FUNCTION get_payments_exist_flag (
          P_invoice_id IN     NUMBER)
RETURN VARCHAR2
IS
  l_flag VARCHAR2(1) := 'N';
BEGIN
  l_flag := AP_INVOICES_UTILITY_PKG.get_payments_exist_flag (P_invoice_id);

RETURN(l_flag);

END get_payments_exist_flag;

FUNCTION get_prepay_amount_applied (P_invoice_id IN NUMBER)
RETURN NUMBER
IS
  l_prepay_amount NUMBER := 0;

BEGIN
  l_prepay_amount := AP_INVOICES_UTILITY_PKG.get_prepay_amount_applied (
                     P_invoice_id);

RETURN(l_prepay_amount);

END get_prepay_amount_applied;

FUNCTION get_packet_id (P_invoice_id IN NUMBER)
RETURN NUMBER
IS
  l_packet_id NUMBER := '';
BEGIN
  l_packet_id := AP_INVOICES_UTILITY_PKG.get_packet_id (P_invoice_id);

RETURN(l_packet_id);

END get_packet_id;

--=========================================================================
-- The functions above have been mapped to AP_INVOICES_UTILITY_PKG
-- (apinvuts.pls apinvutb.pls)
--=========================================================================

--=========================================================================
-- The Following functions have been mapped to AP_INVOICES_POST_PROCESS_PKG
-- (apinvpps.pls apinvppb.pls)
--
--=========================================================================

-----------------------------------------------------------------------
-- Procedure insert_children
-- Inserts child records into AP_HOLDS, AP_PAYMENT_SCHEDULES
-- and AP_INVOICE_LINES
-- PRECONDITION: Called from POST_INSERT
-----------------------------------------------------------------------

PROCEDURE insert_children (
          X_invoice_id            IN            NUMBER,
          X_Payment_Priority      IN            NUMBER,
          X_Hold_count            IN OUT NOCOPY NUMBER,
          X_Line_count            IN OUT NOCOPY NUMBER,
          X_Line_Total            IN OUT NOCOPY NUMBER,
          X_calling_sequence      IN            VARCHAR2,
          X_Sched_Hold_count      IN OUT NOCOPY NUMBER)  -- bug 5334577

IS
BEGIN
  AP_INVOICES_POST_PROCESS_PKG.insert_children (
          X_invoice_id,
          X_Payment_Priority,
          X_Hold_count,
          X_Line_count,
          X_Line_Total,
          X_calling_sequence,
          X_Sched_Hold_count);   --bug 5334577

EXCEPTION
  WHEN OTHERS THEN
    APP_EXCEPTION.RAISE_EXCEPTION;

END insert_children;

-----------------------------------------------------------------------
-- Procedure create_holds
-- Creates invoice limit and vendor holds
-- Called for an invoice at POST_UPDATE and POST_INSERT
-----------------------------------------------------------------------
PROCEDURE create_holds (
          X_invoice_id           IN     NUMBER,
          X_event                IN     VARCHAR2 DEFAULT 'UPDATE',
          X_update_base          IN     VARCHAR2 DEFAULT 'N',
          X_vendor_changed_flag  IN     VARCHAR2 DEFAULT 'N',
          X_calling_sequence     IN     VARCHAR2)
IS
BEGIN
  AP_INVOICES_POST_PROCESS_PKG.create_holds (
          X_invoice_id,
          X_event,
          X_update_base,
          X_vendor_changed_flag,
          X_calling_sequence);

EXCEPTION
  WHEN OTHERS THEN
    APP_EXCEPTION.RAISE_EXCEPTION;

END create_holds;

-----------------------------------------------------------------------
-- Procedure invoice_pre_update
-- Checks to see IF payment schedules should be recalculated.
-- Performs a liability adjustment on paid or partially paid invoices.
-- Determines whether match_status_flag's should be reset on all
-- distributions after the commit has occurred.
-- PRECONDITION: Called during PRE-UPDATE
-----------------------------------------------------------------------

PROCEDURE invoice_pre_update  (
          X_invoice_id                 IN            NUMBER,
          X_invoice_amount             IN            NUMBER,
          X_payment_status_flag        IN OUT NOCOPY VARCHAR2,
          X_invoice_type_lookup_code   IN            VARCHAR2,
          X_last_updated_by            IN            NUMBER,
          X_accts_pay_ccid             IN            NUMBER,
          X_terms_id                   IN            NUMBER,
          X_terms_date                 IN            DATE,
          X_discount_amount            IN            NUMBER,
          X_exchange_rate_type         IN            VARCHAR2,
          X_exchange_date              IN            DATE,
          X_exchange_rate              IN            NUMBER,
          X_vendor_id                  IN            NUMBER,
          X_payment_method_code        IN            VARCHAR2,
          X_message1                   IN OUT NOCOPY VARCHAR2,
          X_message2                   IN OUT NOCOPY VARCHAR2,
          X_reset_match_status         IN OUT NOCOPY VARCHAR2,
          X_vendor_changed_flag        IN OUT NOCOPY VARCHAR2,
          X_recalc_pay_sched           IN OUT NOCOPY VARCHAR2,
          X_liability_adjusted_flag    IN OUT NOCOPY VARCHAR2,
	  X_external_bank_account_id   IN	     NUMBER,   --bug 7714053
	  X_payment_currency_code      IN	     VARCHAR2, --Bug9294551
          X_calling_sequence           IN            VARCHAR2,
          X_revalidate_ps              IN OUT NOCOPY VARCHAR2)
IS
BEGIN
  AP_INVOICES_POST_PROCESS_PKG.invoice_pre_update  (
          X_invoice_id,
          X_invoice_amount,
          X_payment_status_flag,
          X_invoice_type_lookup_code,
          X_last_updated_by,
          X_accts_pay_ccid,
          X_terms_id,
          X_terms_date,
          X_discount_amount,
          X_exchange_rate_type,
          X_exchange_date,
          X_exchange_rate,
          X_vendor_id,
          X_payment_method_code,
          X_message1,
          X_message2,
          X_reset_match_status,
          X_vendor_changed_flag,
          X_recalc_pay_sched,
          X_liability_adjusted_flag,
	  X_external_bank_account_id,	--bug 7714053
	  X_payment_currency_code,      --Bug9294551
          X_calling_sequence,
          X_revalidate_ps);

EXCEPTION
  WHEN OTHERS THEN
    APP_EXCEPTION.RAISE_EXCEPTION;

END invoice_pre_update;

-----------------------------------------------------------------------
-- Procedure invoice_post_update
-- o Applies/releases invoice limit and vendor holds
-- o Recalculates payment schedules IF necessary
-- PRECONDITION: Called during POST-UPDATE
-----------------------------------------------------------------------

PROCEDURE invoice_post_update (
          X_invoice_id          IN            NUMBER,
          X_payment_priority    IN            NUMBER,
          X_recalc_pay_sched    IN OUT NOCOPY VARCHAR2,
          X_Hold_count          IN OUT NOCOPY NUMBER,
          X_update_base         IN            VARCHAR2,
          X_vendor_changed_flag IN            VARCHAR2,
          X_calling_sequence    IN            VARCHAR2,
          X_Sched_Hold_count    IN OUT NOCOPY NUMBER) -- bug 5334577
IS
BEGIN
  AP_INVOICES_POST_PROCESS_PKG.invoice_post_update (
          X_invoice_id,
          X_payment_priority,
          X_recalc_pay_sched,
          X_Hold_count,
          X_update_base,
          X_vendor_changed_flag,
          X_calling_sequence,
          X_Sched_Hold_count);  --bug 5334577

EXCEPTION
  WHEN OTHERS THEN
    APP_EXCEPTION.RAISE_EXCEPTION;

END invoice_post_update;

-----------------------------------------------------------------------
-- Procedure post_forms_commit
-- o Calls distribution PROCEDURE which resets match status,
--   recalculates base, 1099 info, etc.
-- o Determines new invoice-level statuses
-- PRECONDITION: Called during POST-FORMS-COMMIT
-----------------------------------------------------------------------

--Invoice Lines: Distributions.

--Modified the signature of the procedure to get
--highest line number and line total for a invoice as oppose to
--highest distribution line number and distribution total.

PROCEDURE post_forms_commit (
          X_invoice_id                   IN NUMBER,
          X_type_1099                    IN VARCHAR2,
          X_income_tax_region            IN VARCHAR2,
          X_vendor_changed_flag          IN OUT NOCOPY VARCHAR2,
          X_update_base                  IN OUT NOCOPY VARCHAR2,
          X_reset_match_status           IN OUT NOCOPY VARCHAR2,
          X_update_occurred              IN OUT NOCOPY VARCHAR2,
          X_approval_status_lookup_code  IN OUT NOCOPY VARCHAR2,
          X_holds_count                  IN OUT NOCOPY NUMBER,
          X_posting_flag                 IN OUT NOCOPY VARCHAR2,
          X_amount_paid                  IN OUT NOCOPY NUMBER,
          X_highest_line_num 	         IN OUT NOCOPY NUMBER,
          X_line_total		         IN OUT NOCOPY NUMBER,
          X_actual_invoice_count         IN OUT NOCOPY NUMBER,
          X_actual_invoice_total         IN OUT NOCOPY NUMBER,
          X_calling_sequence             IN VARCHAR2,
          X_sched_holds_count            IN OUT NOCOPY NUMBER) IS  --bug 5334577

BEGIN

     AP_INVOICES_POST_PROCESS_PKG.post_forms_commit (
          X_invoice_id,
	  NULL,
          X_type_1099,
          X_income_tax_region,
          X_vendor_changed_flag,
          X_update_base,
          X_reset_match_status,
          x_update_occurred,
          X_approval_status_lookup_code,
          X_holds_count,
          X_posting_flag,
          X_amount_paid,
          X_highest_line_num,
          X_line_total,
          X_actual_invoice_count,
          X_actual_invoice_total,
          X_calling_sequence,
          X_sched_holds_count);  --bug 5334577


EXCEPTION
  WHEN OTHERS THEN
    APP_EXCEPTION.RAISE_EXCEPTION;

END post_forms_commit;

-----------------------------------------------------------------------
-- Procedure Select_Summary calculates the initial value for the
-- batch (actual) total
--
-----------------------------------------------------------------------

PROCEDURE Select_Summary(
          X_Batch_ID         IN            NUMBER,
          X_Total            IN OUT NOCOPY NUMBER,
          X_Total_Rtot_DB    IN OUT NOCOPY NUMBER,
          X_Calling_Sequence IN            VARCHAR2)
IS
BEGIN
  AP_INVOICES_POST_PROCESS_PKG.Select_Summary(
          X_Batch_ID,
          X_Total,
          X_Total_Rtot_DB,
          X_Calling_Sequence);

EXCEPTION
  WHEN OTHERS THEN
    APP_EXCEPTION.RAISE_EXCEPTION;
END Select_Summary;

--=========================================================================
-- The Functions above have been mapped to AP_INVOICES_POST_PROCESS_PKG
-- (apinvpps.pls apinvppb.pls)
--=========================================================================

--bug4299234
FUNCTION Get_WFapproval_Status(
                           P_invoice_id IN NUMBER,
                           P_org_id     IN NUMBER) RETURN VARCHAR2 is
  header_approval_status varchar2(50);
  l_rejected number;
  l_reapprove number;
  l_approved number;
  l_not_required number;
  l_initiated    number;    -- Bug 5624375

  BEGIN

/*Bug5090887 commented the Group by  */

     select SUM(decode(wfapproval_status,'NOT REQUIRED',1,0)) ,
            SUM(decode(wfapproval_status,'APPROVED',1,0)) ,
            SUM(decode(wfapproval_status,'NEEDS WFREAPPROVAL',1,0)) , /* Bug 11655111 */
            SUM(decode(wfapproval_status,'REJECTED',1,0)),
            SUM(decode(wfapproval_status,'INITIATED',1,0))
     into   l_not_required,l_approved,l_reapprove,l_rejected, l_initiated
     from   ap_invoice_lines_all
     where  invoice_id=p_invoice_id
     and    org_id=p_org_id;
     --group  by wfapproval_status;

     --Bug4926114 chenged the return codes from init caps to caps
     If l_initiated>0 then return('INITIATED'); end if;   -- Bug 5624375
     If l_rejected>0 then return('REJECTED'); end if;
     If l_reapprove>0 then return('NEEDS WFREAPPROVAL'); end if; /* Bug 11655111 */

     select wfapproval_status
     into header_approval_status
     from ap_invoices_all
     where invoice_id=p_invoice_id
     and   org_id=p_org_id;

     IF (l_approved > 0 and header_approval_status = 'NOT REQUIRED') THEN
        return('APPROVED');
     END IF;
     return(header_approval_status);
   exception
      when no_data_found then
       return(header_approval_status);  --bug4546162

end Get_WFapproval_Status;



procedure get_payment_attributes (p_le_id                   IN NUMBER,
                                 p_org_id                   in number,
                                 p_payee_party_id           in number,
                                 p_payee_party_site_id      in number,
                                 p_supplier_site_id         in number,
                                 p_payment_currency         in varchar2,
                                 p_payment_amount           in number,
                                 p_payment_function         in varchar2,
                                 p_pay_proc_trxn_type_code  in  varchar2,
                                 p_PAYMENT_METHOD_CODE      out nocopy varchar2,
                                 p_IBY_PAYMENT_METHOD       out nocopy varchar2,
                                 p_PAYMENT_REASON_CODE      out nocopy varchar2,
                                 p_PAYMENT_REASON           out nocopy varchar2,
                                 p_BANK_CHARGE_BEARER       out nocopy varchar2,
                                 p_BANK_CHARGE_BEARER_DSP   out nocopy varchar2,
                                 p_DELIVERY_CHANNEL_CODE    out nocopy varchar2,
                                 p_DELIVERY_CHANNEL         out nocopy varchar2,
                                 p_SETTLEMENT_PRIORITY      out nocopy varchar2,
                                 p_SETTLEMENT_PRIORITY_DSP  out nocopy varchar2,
                                 p_PAY_ALONE                out nocopy varchar2,
                                 p_external_bank_account_id out nocopy number,
                                 p_bank_account_num         out nocopy varchar2,
                                 p_bank_account_name        out nocopy varchar2,
                                 p_bank_branch_name         out nocopy varchar2,
                                 p_bank_branch_num          out nocopy varchar2,
                                 p_bank_name                out nocopy varchar2,
                                 p_bank_number              out nocopy varchar2,
                                 p_payment_reason_comments  out nocopy varchar2,  --4874927
                                 p_application_id           in number default 200 -- 5115632
                                 ) IS


  l_trx_attributes iby_disbursement_comp_pub.Trxn_Attributes_Rec_Type;
  l_result_pmt_attributes iby_disbursement_comp_pub.Default_Pmt_Attrs_Rec_Type;
  l_return_status varchar2(30);
  l_msg_count number;
  l_msg_data varchar2(2000);



  BEGIN
    l_trx_attributes.application_id        := nvl(p_application_id, 200);
    l_trx_attributes.payer_legal_entity_id := p_le_id;
    l_trx_attributes.payer_org_type        := 'OPERATING_UNIT';
    l_trx_attributes.payer_org_id          := p_org_id;
    l_trx_attributes.payee_party_id        := p_payee_party_id;
    l_trx_attributes.payee_party_site_id   := p_payee_party_site_id;

    if p_supplier_site_id > 0 then
      l_trx_attributes.supplier_site_id := p_supplier_site_id;
    else
      l_trx_attributes.supplier_site_id := null;
    end if;


    l_trx_attributes.payment_currency      := p_payment_currency;
    l_trx_attributes.payment_amount        := p_payment_amount;
    l_trx_attributes.payment_function      := p_payment_function;
    l_trx_attributes.pay_proc_trxn_type_code := p_pay_proc_trxn_type_code;


    iby_disbursement_comp_pub.get_default_payment_attributes(
       p_api_version           => 1.0,
       p_trxn_attributes_rec   => l_trx_attributes,
       p_ignore_payee_pref     => 'N',
       x_return_status         => l_return_status,
       x_msg_count             => l_msg_count,
       x_msg_data              => l_msg_data,
       x_default_pmt_attrs_rec => l_result_pmt_attributes);

    if l_return_status = FND_API.G_RET_STS_SUCCESS then

      p_PAYMENT_METHOD_CODE := l_result_pmt_attributes.payment_method.Payment_Method_Code;
      p_IBY_PAYMENT_METHOD := l_result_pmt_attributes.payment_method.Payment_Method_Name;
      p_PAYMENT_REASON_CODE := l_result_pmt_attributes.payment_reason.code;
      p_PAYMENT_REASON := l_result_pmt_attributes.payment_reason.meaning;
      p_BANK_CHARGE_BEARER := l_result_pmt_attributes.Bank_Charge_Bearer.code;
      p_BANK_CHARGE_BEARER_DSP := l_result_pmt_attributes.Bank_Charge_Bearer.meaning;
      p_DELIVERY_CHANNEL_CODE := l_result_pmt_attributes.delivery_channel.code;
      p_DELIVERY_CHANNEL := l_result_pmt_attributes.delivery_channel.meaning;
      p_SETTLEMENT_PRIORITY := l_result_pmt_attributes.settlement_priority.code;
      p_SETTLEMENT_PRIORITY_DSP := l_result_pmt_attributes.settlement_priority.meaning;
      p_PAY_ALONE := l_result_pmt_attributes.pay_alone;
      p_bank_account_name := l_result_pmt_attributes.Payee_BankAccount.Payee_BankAccount_Name;
      p_bank_account_num := l_result_pmt_attributes.Payee_BankAccount.Payee_BankAccount_Num;
      p_external_bank_account_id := l_result_pmt_attributes.Payee_BankAccount.Payee_BankAccount_Id;
      p_bank_branch_name := l_result_pmt_attributes.Payee_BankAccount.Payee_BranchName;
      p_bank_branch_num := l_result_pmt_attributes.Payee_BankAccount.Payee_BranchNumber;
      p_bank_name := l_result_pmt_attributes.Payee_BankAccount.Payee_BankName;
      p_bank_number := l_result_pmt_attributes.Payee_BankAccount.Payee_BankNumber;
      p_payment_reason_comments := l_result_pmt_attributes.payment_reason_comments;  --4874927

	/* Added ELSE condition for bug 8979923 */
    ELSE
	RAISE NO_DATA_FOUND;
    end if;

  end get_payment_attributes;


procedure validate_docs_payable(p_invoice_id in number,
                                p_payment_num in number default null,
                                p_hold_flag out nocopy varchar2) is

cursor docs_to_be_inserted is
  select
    IBY_DOCS_PAYABLE_GT_S.nextval,
    200,
    ai.invoice_id,
    aps.payment_num,
 --   ai.invoice_num,
    nvl(ai.pay_proc_trxn_type_code, decode(ai.invoice_type_lookup_code,'EXPENSE REPORT',
                                           'EMPLOYEE_EXP','PAYABLES_DOC')) ,
    APS.PAYMENT_METHOD_CODE, --4705834
    aps.gross_amount,
    nvl(ai.EXCLUSIVE_PAYMENT_FLAG,'N'),
    -- As per the discussion with Omar/Jayanta, we will only
    -- have payables payment function and no more employee expenses
    -- payment function.
    nvl(ai.PAYMENT_FUNCTION,'PAYABLES_DISB'),
    ai.invoice_date,
    ai.invoice_type_lookup_code,
    ai.description,
    aps.gross_amount ,
    aps.EXTERNAL_BANK_ACCOUNT_ID, --4705834
    nvl(ai.PARTY_ID,pv.party_id),
    nvl(ai.PARTY_SITE_ID, pvs.party_site_id),
    decode(sign(ai.vendor_site_id),1,ai.vendor_site_id,null),
    ai.LEGAL_ENTITY_ID,
    ai.ORG_ID ,
    'OPERATING_UNIT',
    ai.invoice_currency_code,
    ai.PAYMENT_CURRENCY_CODE,
    ai.BANK_CHARGE_BEARER ,
    ai.PAYMENT_REASON_CODE ,
    ai.PAYMENT_REASON_COMMENTS,
    ai.SETTLEMENT_PRIORITY ,
    aps.REMITTANCE_MESSAGE1 ,
    aps.REMITTANCE_MESSAGE2 ,
    aps.REMITTANCE_MESSAGE3 ,
    ai.UNIQUE_REMITTANCE_IDENTIFIER ,
    ai.URI_CHECK_DIGIT ,
    ai.DELIVERY_CHANNEL_CODE ,
    aps.DISCOUNT_DATE,
    aps.CREATED_BY ,
    sysdate ,
    aps.LAST_UPDATED_BY ,
    sysdate,
    1,
    aps.iby_hold_reason,
    aps.hold_flag
  from ap_invoices_all ai,
       ap_payment_schedules_all aps,
       ap_suppliers pv,
       ap_supplier_sites_all pvs
  where ai.invoice_id = p_invoice_id
  and   ai.invoice_id = aps.invoice_id
  and nvl(p_payment_num, aps.payment_num) = aps.payment_num
  and aps.payment_status_flag in ('N','P')
  and aps.checkrun_id is null
  /* Bug 5612834. Added outer-join for Payment request */
  and ai.party_id = pv.party_id (+)
  and ai.vendor_site_id = pvs.vendor_site_id(+);


  l_DOCUMENT_PAYABLE_ID              number;
  l_CALLING_APP_ID                   number;
  l_CALLING_APP_DOC_UNIQUE_REF1      number;
  l_CALLING_APP_DOC_UNIQUE_REF2      number;
 -- l_CALLING_APP_DOC_REF_NUMBER       ap_invoices_all.invoice_num%type;
  l_PAY_PROC_TRXN_TYPE_CODE          ap_invoices_all.pay_proc_trxn_type_code%type;
  l_PAYMENT_METHOD_CODE              ap_invoices_all.payment_method_code%type;
  l_PAYMENT_AMOUNT                   number;
  l_EXCLUSIVE_PAYMENT_FLAG           ap_invoices_all.exclusive_payment_flag%type;
  l_PAYMENT_FUNCTION                 ap_invoices_all.payment_function%type;
  l_DOCUMENT_DATE                    date;
  l_DOCUMENT_TYPE                    ap_invoices_all.invoice_type_lookup_code%type;
  l_DOCUMENT_DESCRIPTION             ap_invoices_all.description%type;
  l_DOCUMENT_AMOUNT                  number;
  l_EXTERNAL_BANK_ACCOUNT_ID         number;
  l_PAYEE_PARTY_ID                   number;
  l_PAYEE_PARTY_SITE_ID              number;
  l_SUPPLIER_SITE_ID                 number;
  l_LEGAL_ENTITY_ID                  number;
  l_ORG_ID                           number;
  l_ORG_TYPE                         varchar2(30);
  l_DOCUMENT_CURRENCY_CODE           ap_invoices_all.invoice_currency_code%type;
  l_PAYMENT_CURRENCY_CODE            ap_invoices_all.payment_currency_code%type;
  l_BANK_CHARGE_BEARER               ap_invoices_all.bank_charge_bearer%type;
  l_PAYMENT_REASON_CODE              ap_invoices_all.payment_reason_code%type;
  l_PAYMENT_REASON_COMMENTS          ap_invoices_all.payment_reason_comments%type;
  l_SETTLEMENT_PRIORITY              ap_invoices_all.settlement_priority%type;
  l_REMITTANCE_MESSAGE1              ap_payment_schedules_all.remittance_message1%type;
  l_REMITTANCE_MESSAGE2              ap_payment_schedules_all.remittance_message2%type;
  l_REMITTANCE_MESSAGE3              ap_payment_schedules_all.remittance_message3%type;
  l_UNIQUE_REMITTANCE_IDENTIFIER     ap_invoices_all.unique_remittance_identifier%type;
  l_URI_CHECK_DIGIT                  ap_invoices_all.uri_check_digit%type;
  l_DELIVERY_CHANNEL_CODE            ap_invoices_all.delivery_channel_code%type;
  l_DISCOUNT_DATE                    date;
  l_CREATED_BY                       number;
  l_CREATION_DATE                    date;
  l_LAST_UPDATED_BY                  number;
  l_LAST_UPDATE_DATE                 date;
  l_OBJECT_VERSION_NUMBER            number;
  l_iby_hold_reason                  ap_payment_schedules_all.iby_hold_reason%type;
  l_hold_flag                        ap_payment_schedules_all.hold_flag%type;

  l_return_status                    VARCHAR2(10);
  l_msg_count                        NUMBER;
  l_msg_data                         varchar2(2000);
  l_error_message                    varchar2(255);

  -- Bug 5652886
  l_iby_error_msg_list               iby_error_tab_type;
  l_iby_error_msg_str                VARCHAR2(2000);

  CURSOR iby_error_msg_cursor (p_document_payable_id IN NUMBER) IS
    select error_message,
           transaction_id
    from IBY_TRANSACTION_ERRORS_GT
    where transaction_id = p_document_payable_id;

begin

  p_hold_flag := 'N';

  open docs_to_be_inserted;
  loop
    fetch docs_to_be_inserted into
      l_DOCUMENT_PAYABLE_ID,
      l_CALLING_APP_ID,
      l_CALLING_APP_DOC_UNIQUE_REF1,
      l_CALLING_APP_DOC_UNIQUE_REF2,
   --   l_CALLING_APP_DOC_REF_NUMBER,
      l_PAY_PROC_TRXN_TYPE_CODE,
      l_PAYMENT_METHOD_CODE,
      l_PAYMENT_AMOUNT,
      l_EXCLUSIVE_PAYMENT_FLAG,
      l_PAYMENT_FUNCTION,
      l_DOCUMENT_DATE,
      l_DOCUMENT_TYPE,
      l_DOCUMENT_DESCRIPTION,
      l_DOCUMENT_AMOUNT ,
      l_EXTERNAL_BANK_ACCOUNT_ID,
      l_PAYEE_PARTY_ID,
      l_PAYEE_PARTY_SITE_ID,
      l_SUPPLIER_SITE_ID,
      l_LEGAL_ENTITY_ID,
      l_ORG_ID ,
      l_ORG_TYPE,
      l_DOCUMENT_CURRENCY_CODE,
      l_PAYMENT_CURRENCY_CODE,
      l_BANK_CHARGE_BEARER ,
      l_PAYMENT_REASON_CODE ,
      l_PAYMENT_REASON_COMMENTS,
      l_SETTLEMENT_PRIORITY ,
      l_REMITTANCE_MESSAGE1 ,
      l_REMITTANCE_MESSAGE2 ,
      l_REMITTANCE_MESSAGE3 ,
      l_UNIQUE_REMITTANCE_IDENTIFIER ,
      l_URI_CHECK_DIGIT ,
      l_DELIVERY_CHANNEL_CODE ,
      l_DISCOUNT_DATE,
      l_CREATED_BY ,
      l_CREATION_DATE ,
      l_LAST_UPDATED_BY ,
      l_LAST_UPDATE_DATE,
      l_OBJECT_VERSION_NUMBER,
      l_iby_hold_reason,
      l_hold_flag;

   exit when docs_to_be_inserted%notfound;




    insert into IBY_DOCS_PAYABLE_GT(
      DOCUMENT_PAYABLE_ID,
      CALLING_APP_ID,
      CALLING_APP_DOC_UNIQUE_REF1,
      CALLING_APP_DOC_UNIQUE_REF2,
   --   CALLING_APP_DOC_REF_NUMBER,
      PAY_PROC_TRXN_TYPE_CODE,
      PAYMENT_METHOD_CODE,
      PAYMENT_AMOUNT,
      EXCLUSIVE_PAYMENT_FLAG,
      PAYMENT_FUNCTION,
      DOCUMENT_DATE,
      DOCUMENT_TYPE,
      DOCUMENT_DESCRIPTION,
      DOCUMENT_AMOUNT ,
      EXTERNAL_BANK_ACCOUNT_ID,
      PAYEE_PARTY_ID,
      PAYEE_PARTY_SITE_ID,
      SUPPLIER_SITE_ID,
      LEGAL_ENTITY_ID,
      ORG_ID ,
      ORG_TYPE,
      DOCUMENT_CURRENCY_CODE,
      PAYMENT_CURRENCY_CODE,
      BANK_CHARGE_BEARER ,
      PAYMENT_REASON_CODE ,
      PAYMENT_REASON_COMMENTS,
      SETTLEMENT_PRIORITY ,
      REMITTANCE_MESSAGE1 ,
      REMITTANCE_MESSAGE2 ,
      REMITTANCE_MESSAGE3 ,
      UNIQUE_REMITTANCE_IDENTIFIER ,
      URI_CHECK_DIGIT ,
      DELIVERY_CHANNEL_CODE ,
      DISCOUNT_DATE,
      CREATED_BY ,
      CREATION_DATE ,
      LAST_UPDATED_BY ,
      LAST_UPDATE_DATE,
      OBJECT_VERSION_NUMBER,
      ALLOW_REMOVING_DOCUMENT_FLAG)
    values (
      l_DOCUMENT_PAYABLE_ID,
      l_CALLING_APP_ID,
      l_CALLING_APP_DOC_UNIQUE_REF1,
      l_CALLING_APP_DOC_UNIQUE_REF2,
    --  l_CALLING_APP_DOC_REF_NUMBER,
      l_PAY_PROC_TRXN_TYPE_CODE,
      l_PAYMENT_METHOD_CODE,
      l_PAYMENT_AMOUNT,
      l_EXCLUSIVE_PAYMENT_FLAG,
      l_PAYMENT_FUNCTION,
      l_DOCUMENT_DATE,
      l_DOCUMENT_TYPE,
      l_DOCUMENT_DESCRIPTION,
      l_DOCUMENT_AMOUNT ,
      l_EXTERNAL_BANK_ACCOUNT_ID,
      l_PAYEE_PARTY_ID,
      l_PAYEE_PARTY_SITE_ID,
      l_SUPPLIER_SITE_ID,
      l_LEGAL_ENTITY_ID,
      l_ORG_ID ,
      l_ORG_TYPE,
      l_DOCUMENT_CURRENCY_CODE,
      l_PAYMENT_CURRENCY_CODE,
      l_BANK_CHARGE_BEARER ,
      l_PAYMENT_REASON_CODE ,
      l_PAYMENT_REASON_COMMENTS,
      l_SETTLEMENT_PRIORITY ,
      l_REMITTANCE_MESSAGE1 ,
      l_REMITTANCE_MESSAGE2 ,
      l_REMITTANCE_MESSAGE3 ,
      l_UNIQUE_REMITTANCE_IDENTIFIER ,
      l_URI_CHECK_DIGIT ,
      l_DELIVERY_CHANNEL_CODE ,
      l_DISCOUNT_DATE,
      l_CREATED_BY ,
      l_CREATION_DATE ,
      l_LAST_UPDATED_BY ,
      l_LAST_UPDATE_DATE,
      l_OBJECT_VERSION_NUMBER,
      'N');

    --call the api;
    IBY_DISBURSEMENT_COMP_PUB.Validate_Documents(
      p_api_version              => 1,
      p_document_id              => l_DOCUMENT_PAYABLE_ID,
      x_return_status            => l_return_status,
      x_msg_count                => l_msg_count,
      x_msg_data                 => l_msg_data);


   /* Bug 5652886. Rewriting the logic for handling multiple holds */
    --check the errors table
    OPEN iby_error_msg_cursor (l_document_payable_id);
      FETCH iby_error_msg_cursor
      BULK COLLECT INTO l_iby_error_msg_list;
    CLOSE iby_error_msg_cursor;

    IF l_iby_error_msg_list.COUNT > 0 THEN

      FOR i IN 1..l_iby_error_msg_list.COUNT
      LOOP
        IF Nvl(length(l_iby_error_msg_str),0) < 1745 THEN
          -- iby_hold_reason legth is 2000 and legth of Iby
          -- error message is 2000
          IF i = 1 THEN
            l_iby_error_msg_str := l_iby_error_msg_list(i).error_message;
          ELSE
            l_iby_error_msg_str := l_iby_error_msg_str||'* *'
                            ||l_iby_error_msg_list(i).error_message;
          END IF;
        END IF;
      END LOOP;

      Update Ap_Payment_Schedules_all
      Set   hold_flag = 'Y',
            iby_hold_reason = l_iby_error_msg_str
      Where invoice_id = l_calling_app_doc_unique_ref1
      And   payment_num = l_calling_app_doc_unique_ref2
      and payment_status_flag <> 'Y';  /*Bug 16982384*/

      p_hold_flag := 'Y';

   ELSE

     --if no row exists remove the hold flag and reason on the payment schedule if it
     --was previously on hold and there was a hold reason.
     IF l_hold_flag = 'Y' and l_iby_hold_reason IS NOT NULL THEN
       Update Ap_Payment_Schedules_All
       Set    hold_flag = 'N',
              iby_hold_reason = Null
       Where invoice_id = l_calling_app_doc_unique_ref1
       And   payment_num = l_calling_app_doc_unique_ref2;
     END IF;

   END IF;

  end loop;

  close docs_to_be_inserted;

end;

/*==============================================================*/
/*                                                              */
/* This returns the sum of invoices lines amount if prepayment  */
/* included on invoice else returns null.                       */
/* Added for bug8572079                                         */
/*==============================================================*/
FUNCTION Get_Line_Total_Incl_Prepay(P_invoice_id IN NUMBER)
RETURN NUMBER IS
   l_total NUMBER;
   l_invoice_includes_prepay_flag VARCHAR2(1);
BEGIN
      SELECT 'Y'
        INTO l_invoice_includes_prepay_flag
	  FROM ap_invoices_all ai
	 WHERE ai.invoice_id = P_invoice_id
       AND EXISTS (SELECT ail.invoice_includes_prepay_flag
					FROM ap_invoice_lines_all ail
					WHERE ail.invoice_id = ai.invoice_id
					AND ail.invoice_includes_prepay_flag = 'Y');

	IF(l_invoice_includes_prepay_flag is NULL) THEN
		RETURN NULL;
	ELSE
       SELECT SUM(NVL(ail.amount,0))
         INTO l_total
         FROM ap_invoice_lines_all ail
        WHERE ail.invoice_id = P_invoice_id
          AND (ail.line_type_lookup_code NOT IN ('PREPAY', 'AWT')
                AND ail.prepay_invoice_id IS NULL
				AND ail.prepay_line_number IS NULL);

		RETURN(l_total);
	END IF;
EXCEPTION
	WHEN OTHERS THEN
	 RETURN NULL;
END Get_Line_Total_Incl_Prepay;


/*==============================================================*/
/* This returns the expected value of force_revalidation_flag   */
/* for a historical and paid invoice                            */
/* Added for bug11934187                                        */
/*==============================================================*/
PROCEDURE Get_Force_Revalidation_Flag
		(P_invoice_id IN NUMBER,
		 P_event IN VARCHAR2,
		 P_force_revalidation_flag  IN OUT NOCOPY VARCHAR2) IS
l_count NUMBER;
BEGIN
    SELECT COUNT(1)
	INTO l_count
	FROM ap_invoices_all ai
	WHERE ai.invoice_id 		= P_invoice_id
	AND ai.historical_flag      = 'Y'
	AND ai.payment_status_flag  = 'Y'
	AND NVL(ai.force_revalidation_flag,'N') = 'N'
	AND EXISTS
	  (SELECT 1
	  FROM AP_INVOICE_LINES_ALL AIL
	  WHERE AIL.INVOICE_ID              = AI.INVOICE_ID
	  AND NVL(AIL.DISCARDED_FLAG, 'N') <> 'Y'
	  AND NVL(AIL.CANCELLED_FLAG, 'N') <> 'Y'
	  AND (AIL.AMOUNT                  <> 0
	  OR (AIL.AMOUNT                    = 0
	  AND AIL.GENERATE_DISTS            = 'Y'))
	  AND NOT EXISTS
		(SELECT
		  /*+ NO_UNNEST */
		  'distributed line'
		FROM AP_INVOICE_DISTRIBUTIONS_ALL D5
		WHERE D5.INVOICE_ID        = AIL.INVOICE_ID
		AND D5.INVOICE_LINE_NUMBER = AIL.LINE_NUMBER
		)
	  UNION ALL
	  SELECT 1
	  FROM AP_INVOICE_DISTRIBUTIONS_ALL D,
		FINANCIALS_SYSTEM_PARAMS_ALL FSP
	  WHERE D.INVOICE_ID                       = AI.INVOICE_ID
	  AND FSP.ORG_ID                           = AI.ORG_ID
	  AND FSP.SET_OF_BOOKS_ID                  = AI.SET_OF_BOOKS_ID
	  AND (NVL(FSP.PURCH_ENCUMBRANCE_FLAG,'N') = 'Y'
	  AND NVL(D.MATCH_STATUS_FLAG,'N')        <> 'A'
	  OR (NVL(FSP.PURCH_ENCUMBRANCE_FLAG,'N')  = 'N'
	  AND NVL(D.MATCH_STATUS_FLAG,'N') NOT    IN ('A','T')))
	  UNION ALL
	  SELECT 1
	  FROM AP_SELF_ASSESSED_TAX_DIST_ALL D,
		FINANCIALS_SYSTEM_PARAMS_ALL FSP
	  WHERE D.INVOICE_ID                       = AI.INVOICE_ID
	  AND FSP.ORG_ID                           = AI.ORG_ID
	  AND FSP.SET_OF_BOOKS_ID                  = AI.SET_OF_BOOKS_ID
	  AND (NVL(FSP.PURCH_ENCUMBRANCE_FLAG,'N') = 'Y'
	  AND NVL(D.MATCH_STATUS_FLAG,'N')        <> 'A'
	  OR (NVL(FSP.PURCH_ENCUMBRANCE_FLAG,'N')  = 'N'
	  AND NVL(D.MATCH_STATUS_FLAG,'N') NOT    IN ('A','T')))
	  AND NOT EXISTS
		(SELECT 'Cancelled distributions'
		FROM AP_SELF_ASSESSED_TAX_DIST_ALL D2
		WHERE D2.INVOICE_ID      = D.INVOICE_ID
		AND D2.CANCELLATION_FLAG = 'Y'
		)
	  );

     If l_count > 0 then
           P_force_revalidation_flag := 'Y';
	   If(P_event = 'ON-INSERT') then
		update ap_invoices_all
		set force_revalidation_flag = 'Y'
		where invoice_id = p_invoice_id;
	   end if;
     END IF;

END Get_Force_Revalidation_Flag;


END AP_INVOICES_PKG;
/
