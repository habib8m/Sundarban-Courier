CREATE OR REPLACE PACKAGE BODY APPS.AP_AI_TABLE_HANDLER_PKG as
/* $Header: apainthb.pls 120.25 2010/12/24 04:13:08 pgayen ship $ */

PROCEDURE CHECK_UNIQUE (
          p_ROWID                     VARCHAR2,
          p_INVOICE_NUM               VARCHAR2,
          p_VENDOR_ID                 NUMBER,
          p_ORG_ID                    NUMBER,   -- Bug 5407785
	  P_PARTY_SITE_ID             NUMBER, /*Bug9105666*/
	  P_VENDOR_SITE_ID            NUMBER, /*Bug9105666*/
          p_calling_sequence  IN      VARCHAR2) IS

  dummy_a                       NUMBER := 0;
  dummy_b                       NUMBER := 0;
  current_calling_sequence      VARCHAR2(2000);
  debug_info                    VARCHAR2(100);

BEGIN

  -- Update the calling sequence

  current_calling_sequence :=
               'AP_AI_TABLE_HANDLER_PKG.CHECK_UNIQUE<-'||p_calling_sequence;

  debug_info := 'Count for same vendor_id,party_site_id and invoice_num'; /*Bug9105666*/
  SELECT count(1)
    INTO dummy_a
    FROM ap_invoices_all
   WHERE invoice_num = p_INVOICE_NUM
     AND vendor_id   = p_VENDOR_ID
     AND org_id      = p_ORG_ID   -- Bug 5407785
     AND (party_site_id = P_PARTY_SITE_ID /*Bug9105666*/
        OR (party_site_id is null and P_PARTY_SITE_ID is null)) /*Bug9105666*/
     AND ((p_ROWID is null) OR
          (rowid <> p_ROWID));

  IF (dummy_a >= 1) THEN
    fnd_message.set_name('SQLAP','AP_ALL_DUPLICATE_VALUE');
    app_exception.raise_exception;
  END IF;

  debug_info := 'Count for same vendor_id,party_site_id and invoice_num amount purged invoices'; /*Bug9105666*/
  SELECT count(1)
    INTO dummy_b
    FROM ap_history_invoices_all ahi,
         ap_supplier_sites_all ass /*Bug9105666*/
   WHERE ahi.vendor_id = ass.vendor_id /*Bug9105666*/
     AND ahi.org_id = ass.org_id /*Bug9105666*/
     AND ahi.invoice_num = p_INVOICE_NUM
     AND ahi.vendor_id = p_VENDOR_ID
     AND ahi.org_id = p_ORG_ID   -- Bug 5407785
     AND (ass.party_site_id = P_PARTY_SITE_ID /*Bug9105666*/
      OR (ass.party_site_id is null and P_PARTY_SITE_ID is null)); /*Bug9105666*/

  IF (dummy_b >= 1) THEN
    fnd_message.set_name('SQLAP','AP_ALL_DUPLICATE_VALUE');
    app_exception.raise_exception;
  END IF;

  EXCEPTION
     WHEN OTHERS THEN
         IF (SQLCODE <> -20001) THEN
           FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
           FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
           FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',
                     current_calling_sequence);
           FND_MESSAGE.SET_TOKEN('PARAMETERS',
               'p_Rowid = '      ||p_Rowid
           ||', p_INVOICE_NUM = '||p_INVOICE_NUM
           ||', p_VENDOR_ID = '  ||p_VENDOR_ID
	   ||', P_VENDOR_SITE_ID = '||P_VENDOR_SITE_ID /*Bug9105666*/
	   ||', P_PARTY_SITE_ID = '||P_PARTY_SITE_ID /*Bug9105666*/
                                    );
           FND_MESSAGE.SET_TOKEN('DEBUG_INFO',debug_info);
         END IF;
       APP_EXCEPTION.RAISE_EXCEPTION;

END CHECK_UNIQUE;

---------------------------------------------------------------------
PROCEDURE Insert_Row(
          p_Rowid                       IN OUT NOCOPY VARCHAR2,
          p_Invoice_Id                  IN OUT NOCOPY NUMBER,
          p_Last_Update_Date                   DATE,
          p_Last_Updated_By                    NUMBER,
          p_Vendor_Id                          NUMBER,
          p_Invoice_Num                        VARCHAR2,
          p_Invoice_Amount                     NUMBER,
          p_Vendor_Site_Id                     NUMBER,
          p_Amount_Paid                        NUMBER,
          p_Discount_Amount_Taken              NUMBER,
          p_Invoice_Date                       DATE,
          p_Source                             VARCHAR2,
          p_Invoice_Type_Lookup_Code           VARCHAR2,
          p_Description                        VARCHAR2,
          p_Batch_Id                           NUMBER,
          p_Amt_Applicable_To_Discount         NUMBER,
          p_Terms_Id                           NUMBER,
          p_Terms_Date                         DATE,
          p_Goods_Received_Date                DATE,
          p_Invoice_Received_Date              DATE,
          p_Voucher_Num                        VARCHAR2,
          p_Approved_Amount                    NUMBER,
          p_Approval_Status                    VARCHAR2,
          p_Approval_Description               VARCHAR2,
          p_Pay_Group_Lookup_Code              VARCHAR2,
          p_Set_Of_Books_Id                    NUMBER,
          p_Accts_Pay_CCId                     NUMBER,
          p_Recurring_Payment_Id               NUMBER,
          p_Invoice_Currency_Code              VARCHAR2,
          p_Payment_Currency_Code              VARCHAR2,
          p_Exchange_Rate                      NUMBER,
          p_Payment_Amount_Total               NUMBER,
          p_Payment_Status_Flag                VARCHAR2,
          p_Posting_Status                     VARCHAR2,
          p_Authorized_By                      VARCHAR2,
          p_Attribute_Category                 VARCHAR2,
          p_Attribute1                         VARCHAR2,
          p_Attribute2                         VARCHAR2,
          p_Attribute3                         VARCHAR2,
          p_Attribute4                         VARCHAR2,
          p_Attribute5                         VARCHAR2,
          p_Creation_Date                      DATE,
          p_Created_By                         NUMBER,
          p_Vendor_Prepay_Amount               NUMBER,
          p_Base_Amount                        NUMBER,
          p_Exchange_Rate_Type                 VARCHAR2,
          p_Exchange_Date                      DATE,
          p_Payment_Cross_Rate                 NUMBER,
          p_Payment_Cross_Rate_Type            VARCHAR2,
          p_Payment_Cross_Rate_Date            Date,
          p_Pay_Curr_Invoice_Amount            NUMBER,
          p_Last_Update_Login                  NUMBER,
          p_Original_Prepayment_Amount         NUMBER,
          p_Earliest_Settlement_Date           DATE,
          p_Attribute11                        VARCHAR2,
          p_Attribute12                        VARCHAR2,
          p_Attribute13                        VARCHAR2,
          p_Attribute14                        VARCHAR2,
          p_Attribute6                         VARCHAR2,
          p_Attribute7                         VARCHAR2,
          p_Attribute8                         VARCHAR2,
          p_Attribute9                         VARCHAR2,
          p_Attribute10                        VARCHAR2,
          p_Attribute15                        VARCHAR2,
          p_Cancelled_Date                     DATE,
          p_Cancelled_By                       NUMBER,
          p_Cancelled_Amount                   NUMBER,
          p_Temp_Cancelled_Amount              NUMBER,
          p_Exclusive_Payment_Flag             VARCHAR2,
          p_Po_Header_Id                       NUMBER,
          p_Doc_Sequence_Id                    NUMBER,
          p_Doc_Sequence_Value                 NUMBER,
          p_Doc_Category_Code                  VARCHAR2,
          p_Expenditure_Item_Date              DATE,
          p_Expenditure_Organization_Id        NUMBER,
          p_Expenditure_Type                   VARCHAR2,
          p_Pa_Default_Dist_Ccid               NUMBER,
          p_Pa_Quantity                        NUMBER,
          p_Project_Id                         NUMBER,
          p_Task_Id                            NUMBER,
          p_Awt_Flag                           VARCHAR2,
          p_Awt_Group_Id                       NUMBER,
          p_Pay_Awt_Group_Id                       NUMBER,--bug6639866
          p_Reference_1                        VARCHAR2,
          p_Reference_2                        VARCHAR2,
          p_Org_Id                             NUMBER,
          p_global_attribute_category          VARCHAR2 DEFAULT NULL,
          p_global_attribute1                  VARCHAR2 DEFAULT NULL,
          p_global_attribute2                  VARCHAR2 DEFAULT NULL,
          p_global_attribute3                  VARCHAR2 DEFAULT NULL,
          p_global_attribute4                  VARCHAR2 DEFAULT NULL,
          p_global_attribute5                  VARCHAR2 DEFAULT NULL,
          p_global_attribute6                  VARCHAR2 DEFAULT NULL,
          p_global_attribute7                  VARCHAR2 DEFAULT NULL,
          p_global_attribute8                  VARCHAR2 DEFAULT NULL,
          p_global_attribute9                  VARCHAR2 DEFAULT NULL,
          p_global_attribute10                 VARCHAR2 DEFAULT NULL,
          p_global_attribute11                 VARCHAR2 DEFAULT NULL,
          p_global_attribute12                 VARCHAR2 DEFAULT NULL,
          p_global_attribute13                 VARCHAR2 DEFAULT NULL,
          p_global_attribute14                 VARCHAR2 DEFAULT NULL,
          p_global_attribute15                 VARCHAR2 DEFAULT NULL,
          p_global_attribute16                 VARCHAR2 DEFAULT NULL,
          p_global_attribute17                 VARCHAR2 DEFAULT NULL,
          p_global_attribute18                 VARCHAR2 DEFAULT NULL,
          p_global_attribute19                 VARCHAR2 DEFAULT NULL,
          p_global_attribute20                 VARCHAR2 DEFAULT NULL,
          p_calling_sequence            IN     VARCHAR2,
          p_gl_date                            DATE,
          p_Award_Id                           NUMBER,
          p_approval_iteration                 NUMBER,
          p_approval_ready_flag                VARCHAR2 DEFAULT 'Y',
          p_wfapproval_status                  VARCHAR2 DEFAULT 'NOT REQUIRED',
          p_paid_on_behalf_employee_id         NUMBER   DEFAULT NULL,
          p_amt_due_employee                   NUMBER   DEFAULT NULL,
          p_amt_due_ccard_company              NUMBER   DEFAULT NULL,
          p_requester_id                       NUMBER   DEFAULT NULL,
          -- Invoice Lines Project Stage 1
          p_quick_credit                       VARCHAR2 DEFAULT NULL,
          p_credited_invoice_id                NUMBER   DEFAULT NULL,
          p_distribution_set_id                NUMBER   DEFAULT NULL,
	  --ETAX: Invwkb
	  p_force_revalidation_flag	       VARCHAR2 DEFAULT NULL,
	  p_control_amount		       NUMBER   DEFAULT NULL,
	  p_tax_related_invoice_id	       NUMBER   DEFAULT NULL,
	  p_trx_business_category      	       VARCHAR2 DEFAULT NULL,
	  p_user_defined_fisc_class    	       VARCHAR2 DEFAULT NULL,
	  p_taxation_country	               VARCHAR2 DEFAULT NULL,
	  p_document_sub_type                  VARCHAR2 DEFAULT NULL,
	  p_supplier_tax_invoice_number        VARCHAR2 DEFAULT NULL,
	  p_supplier_tax_invoice_date          DATE     DEFAULT NULL,
	  p_supplier_tax_exchange_rate         NUMBER   DEFAULT NULL,
	  p_tax_invoice_recording_date         DATE     DEFAULT NULL,
	  p_tax_invoice_internal_seq           VARCHAR2 DEFAULT NULL, -- bug 8912305: modify
	  p_legal_entity_id		       NUMBER   DEFAULT NULL,
	  p_quick_po_header_id		       NUMBER   DEFAULT NULL,
          P_PAYMENT_METHOD_CODE                varchar2 ,
          P_PAYMENT_REASON_CODE                varchar2 default null,
          P_PAYMENT_REASON_COMMENTS            varchar2 default null,
          P_UNIQUE_REMITTANCE_IDENTIFIER       varchar2 default null,
          P_URI_CHECK_DIGIT                    varchar2 default null,
          P_BANK_CHARGE_BEARER                 varchar2 default null,
          P_DELIVERY_CHANNEL_CODE              varchar2 default null,
          P_SETTLEMENT_PRIORITY                varchar2 default null,
	  p_net_of_retainage_flag	       varchar2 default null,
	  p_release_amount_net_of_tax	       number   default null,
	  p_port_of_entry_code		       varchar2 default null,
          p_external_bank_account_id           number   default null,
          p_party_id                           number   default null,
          p_party_site_id                      number   default null,
           /* bug 4931755 */
          p_disc_is_inv_less_tax_flag          varchar2 default null,
          p_exclude_freight_from_disc          varchar2 default null,
          /* Bug 5087834 */
          p_remit_msg1                         varchar2 default null,
          p_remit_msg2                         varchar2 default null,
          p_remit_msg3                         varchar2 default null,
	  p_cust_registration_number	       varchar2 default null,
	  /* Third Party Payments*/
	  p_remit_to_supplier_name	varchar2 default null,
	  p_remit_to_supplier_id	number default null,
	  p_remit_to_supplier_site	varchar2 default null,
	  p_remit_to_supplier_site_id number default null,
	  p_relationship_id		number default null,
	  /* Bug 7831073 */
	  p_original_invoice_amount number default null,
	  p_dispute_reason varchar2 default null

	  )
  IS

  CURSOR C IS
  SELECT rowid FROM ap_invoices_all
   WHERE invoice_id = p_Invoice_Id;

  CURSOR C2 IS
  SELECT ap_invoices_s.nextval FROM sys.dual;

  current_calling_sequence            VARCHAR2(2000);
  debug_info                          VARCHAR2(100);
BEGIN
  -- Update the calling sequence

  current_calling_sequence := 'AP_AI_TABLE_HANDLER_PKG.INSERT_ROW<-'||
                              p_calling_sequence;

  -- Check uniqueness first
  ap_ai_table_handler_pkg.check_unique(
           p_ROWID,
           p_INVOICE_NUM,
           p_VENDOR_ID,
           p_ORG_ID,  -- Bug 5407785
	   P_PARTY_SITE_ID, /*Bug9105666*/
           P_VENDOR_SITE_ID, /*Bug9105666*/
           current_calling_sequence);

  IF (p_Invoice_Id is NULL) THEN
    debug_info := 'Open cursor C2';
    OPEN C2;
    debug_info := 'Fetch cursor C2';
    FETCH C2 INTO
          p_Invoice_Id;
    debug_info := 'hello Close cursor C2';
    CLOSE C2;
  END IF;

  debug_info := 'Insert into ap_invoices_all';

  INSERT INTO ap_invoices_all(
          invoice_id,
          last_update_date,
          last_updated_by,
          vendor_id,
          invoice_num,
          invoice_amount,
          vendor_site_id,
          amount_paid,
          discount_amount_taken,
          invoice_date,
          source,
          invoice_type_lookup_code,
          description,
          batch_id,
          amount_applicable_to_discount,
          terms_id,
          terms_date,
          goods_received_date,
          invoice_received_date,
          voucher_num,
          approved_amount,
          approval_status,
          approval_description,
          pay_group_lookup_code,
          set_of_books_id,
          accts_pay_code_combination_id,
          recurring_payment_id,
          invoice_currency_code,
          payment_currency_code,
          exchange_rate,
          payment_amount_total,
          payment_status_flag,
          posting_status,
          authorized_by,
          attribute_category,
          attribute1,
          attribute2,
          attribute3,
          attribute4,
          attribute5,
          creation_date,
          created_by,
          vendor_prepay_amount,
          base_amount,
          exchange_rate_type,
          exchange_date,
          payment_cross_rate,
          payment_cross_rate_type,
          payment_cross_rate_date,
          pay_curr_invoice_amount,
          last_update_login,
          original_prepayment_amount,
          earliest_settlement_date,
          attribute11,
          attribute12,
          attribute13,
          attribute14,
          attribute6,
          attribute7,
          attribute8,
          attribute9,
          attribute10,
          attribute15,
          cancelled_date,
          cancelled_by,
          cancelled_amount,
          temp_cancelled_amount,
          exclusive_payment_flag,
          po_header_id,
          doc_sequence_id,
          doc_sequence_value,
          doc_category_code,
          expenditure_item_date,
          expenditure_organization_id,
          expenditure_type,
          pa_default_dist_ccid,
          pa_quantity,
          project_id,
          task_id,
          awt_flag,
          awt_group_id,
          pay_awt_group_id,--bug6639866
          reference_1,
          reference_2,
          global_attribute_category,
          global_attribute1,
          global_attribute2,
          global_attribute3,
          global_attribute4,
          global_attribute5,
          global_attribute6,
          global_attribute7,
          global_attribute8,
          global_attribute9,
          global_attribute10,
          global_attribute11,
          global_attribute12,
          global_attribute13,
          global_attribute14,
          global_attribute15,
          global_attribute16,
          global_attribute17,
          global_attribute18,
          global_attribute19,
          global_attribute20,
          gl_date,
          award_id,
          approval_iteration,
          approval_ready_flag,
          wfapproval_status,
          paid_on_behalf_employee_id,
          amt_due_employee,
          amt_due_ccard_company,
          requester_id,
          org_id,
          -- Invoice Lines Project Stage 1
          quick_credit,
          credited_invoice_id,
          distribution_set_id,
	  --ETAX:Invwkb
	  force_revalidation_flag,
	  control_amount,
	  tax_related_invoice_id,
	  trx_business_category,
	  user_defined_fisc_class,
	  taxation_country,
	  document_sub_type,
	  supplier_tax_invoice_number,
	  supplier_tax_invoice_date,
	  supplier_tax_exchange_rate,
	  tax_invoice_recording_date,
	  tax_invoice_internal_seq,
	  legal_entity_id,
	  --Contract Payments
	  quick_po_header_id,
          PAYMENT_METHOD_CODE,
          PAYMENT_REASON_CODE,
          PAYMENT_REASON_COMMENTS,
          UNIQUE_REMITTANCE_IDENTIFIER,
          URI_CHECK_DIGIT,
          BANK_CHARGE_BEARER,
          DELIVERY_CHANNEL_CODE,
          SETTLEMENT_PRIORITY,
	  net_of_retainage_flag,
	  release_amount_net_of_tax,
	  port_of_entry_code,
          external_bank_account_id,
          party_id,
          party_site_id,
           /* bug 4931755 */
          disc_is_inv_less_tax_flag,
          exclude_freight_from_discount,
          REMITTANCE_MESSAGE1,
          REMITTANCE_MESSAGE2,
          REMITTANCE_MESSAGE3,
	  CUST_REGISTRATION_NUMBER,
	  /* Third Party Payments*/
	  REMIT_TO_SUPPLIER_NAME,
	  REMIT_TO_SUPPLIER_ID,
	  REMIT_TO_SUPPLIER_SITE,
	  REMIT_TO_SUPPLIER_SITE_ID,
	  RELATIONSHIP_ID,
      /* Bug 7831073 */
      original_invoice_amount,
      dispute_reason
	  )
  VALUES (
          p_Invoice_Id,
          p_Last_Update_Date,
          p_Last_Updated_By,
          p_Vendor_Id,
          p_Invoice_Num,
          p_Invoice_Amount,
          p_Vendor_Site_Id,
          p_Amount_Paid,
          p_Discount_Amount_Taken,
          p_Invoice_Date,
          p_Source,
          p_Invoice_Type_Lookup_Code,
          p_Description,
          p_Batch_Id,
          p_Amt_Applicable_To_Discount,
          p_Terms_Id,
          p_Terms_Date,
          p_Goods_Received_Date,
          p_Invoice_Received_Date,
          p_Voucher_Num,
          p_Approved_Amount,
          p_Approval_Status,
          p_Approval_Description,
          p_Pay_Group_Lookup_Code,
          p_Set_Of_Books_Id,
          p_Accts_Pay_CCId,
          p_Recurring_Payment_Id,
          p_Invoice_Currency_Code,
          p_Payment_Currency_Code,
          p_Exchange_Rate,
          p_Payment_Amount_Total,
          p_Payment_Status_Flag,
          p_Posting_Status,
          p_Authorized_By,
          p_Attribute_Category,
          p_Attribute1,
          p_Attribute2,
          p_Attribute3,
          p_Attribute4,
          p_Attribute5,
          p_Creation_Date,
          p_Created_By,
          p_Vendor_Prepay_Amount,
          p_Base_Amount,
          p_Exchange_Rate_Type,
          p_Exchange_Date,
          p_Payment_Cross_Rate,
          p_Payment_Cross_Rate_Type,
          p_Payment_Cross_Rate_Date,
          p_Pay_Curr_Invoice_Amount,
          p_Last_Update_Login,
          p_Original_Prepayment_Amount,
          p_Earliest_Settlement_Date,
          p_Attribute11,
          p_Attribute12,
          p_Attribute13,
          p_Attribute14,
          p_Attribute6,
          p_Attribute7,
          p_Attribute8,
          p_Attribute9,
          p_Attribute10,
          p_Attribute15,
          p_Cancelled_Date,
          p_Cancelled_By,
          p_Cancelled_Amount,
          p_Temp_Cancelled_Amount,
          p_Exclusive_Payment_Flag,
          p_Po_Header_Id,
          p_Doc_Sequence_Id,
          p_Doc_Sequence_Value,
          p_Doc_Category_Code,
          p_Expenditure_Item_Date,
          p_Expenditure_Organization_Id,
          p_Expenditure_Type,
          p_Pa_Default_Dist_Ccid,
          p_Pa_Quantity,
          p_Project_Id,
          p_Task_Id,
          p_Awt_Flag,
          p_Awt_Group_Id,
          p_Pay_Awt_Group_Id,--bug6639866
          p_Reference_1,
          p_Reference_2,
          p_global_attribute_category,
          p_global_attribute1,
          p_global_attribute2,
          p_global_attribute3,
          p_global_attribute4,
          p_global_attribute5,
          p_global_attribute6,
          p_global_attribute7,
          p_global_attribute8,
          p_global_attribute9,
          p_global_attribute10,
          p_global_attribute11,
          p_global_attribute12,
          p_global_attribute13,
          p_global_attribute14,
          p_global_attribute15,
          p_global_attribute16,
          p_global_attribute17,
          p_global_attribute18,
          p_global_attribute19,
          p_global_attribute20,
          p_gl_date,
          p_Award_Id,
          p_approval_iteration,
          p_approval_ready_flag,
          p_wfapproval_status,
          p_paid_on_behalf_employee_id,
          p_amt_due_employee,
          p_amt_due_ccard_company,
          p_requester_id,
          p_org_id,
          -- Invoice Lines Project Stage 1
          p_quick_credit,
          p_credited_invoice_id,
          p_distribution_set_id,
	  --ETAX: Invwkb
	  p_force_revalidation_flag,
	  p_control_amount,
          p_tax_related_invoice_id,
	  p_trx_business_category,
	  p_user_defined_fisc_class,
	  p_taxation_country,
	  p_document_sub_type,
	  p_supplier_tax_invoice_number,
	  p_supplier_tax_invoice_date,
	  p_supplier_tax_exchange_rate,
	  p_tax_invoice_recording_date,
	  p_tax_invoice_internal_seq,
	  p_legal_entity_id,
	  p_quick_po_header_id,
          P_PAYMENT_METHOD_CODE,
          P_PAYMENT_REASON_CODE,
          P_PAYMENT_REASON_COMMENTS,
          P_UNIQUE_REMITTANCE_IDENTIFIER,
          P_URI_CHECK_DIGIT,
          P_BANK_CHARGE_BEARER,
          P_DELIVERY_CHANNEL_CODE,
          P_SETTLEMENT_PRIORITY,
	  p_net_of_retainage_flag,
	  p_release_amount_net_of_tax,
	  p_port_of_entry_code,
          p_external_bank_account_id,
          p_party_id,
          p_party_site_id,
          p_disc_is_inv_less_tax_flag,
          p_exclude_freight_from_disc,
          p_remit_msg1,
          p_remit_msg2,
          p_remit_msg3,
	  p_cust_registration_number,
	  /* Third Party Payments*/
	  p_remit_to_supplier_name,
	  p_remit_to_supplier_id,
	  p_remit_to_supplier_site,
	  p_remit_to_supplier_site_id,
	  p_relationship_id,
	 /* Bug 7831073 */
	  p_original_invoice_amount,
	  p_dispute_reason
	  );

  debug_info := 'Open cursor C';
  OPEN C;
  debug_info := 'Fetch cursor C';
  FETCH C INTO p_Rowid;
  IF (C%NOTFOUND) THEN
    debug_info := 'Close cursor C - ROW NOTFOUND';
    CLOSE C;
    RAISE NO_DATA_FOUND;
  END IF;
  debug_info := 'Close cursor C';
  CLOSE C;

  --Bug 4539462 DBI logging
  AP_DBI_PKG.Maintain_DBI_Summary
              (p_table_name => 'AP_INVOICES',
               p_operation => 'I',
               p_key_value1 => p_invoice_id,
                p_calling_sequence => current_calling_sequence);

  EXCEPTION
     WHEN OTHERS THEN
         IF (SQLCODE <> -20001) THEN
           FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
           FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
           FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',
                     current_calling_sequence);
           FND_MESSAGE.SET_TOKEN('PARAMETERS',
               'p_Rowid = '||p_Rowid
           ||', p_invoice_id = '||p_invoice_id
                                    );
           FND_MESSAGE.SET_TOKEN('DEBUG_INFO',debug_info);
         END IF;
       APP_EXCEPTION.RAISE_EXCEPTION;

END Insert_Row;

PROCEDURE Update_Row(
          p_Rowid                              VARCHAR2,
          p_Invoice_Id                         NUMBER,
          p_Last_Update_Date                   DATE,
          p_Last_Updated_By                    NUMBER,
          p_Vendor_Id                          NUMBER,
          p_Invoice_Num                        VARCHAR2,
          p_Invoice_Amount                     NUMBER,
          p_Vendor_Site_Id                     NUMBER,
          p_Amount_Paid                        NUMBER,
          p_Discount_Amount_Taken              NUMBER,
          p_Invoice_Date                       DATE,
          p_Source                             VARCHAR2,
          p_Invoice_Type_Lookup_Code           VARCHAR2,
          p_Description                        VARCHAR2,
          p_Batch_Id                           NUMBER,
          p_Amt_Applicable_To_Discount         NUMBER,
          p_Terms_Id                           NUMBER,
          p_Terms_Date                         DATE,
          p_Goods_Received_Date                DATE,
          p_Invoice_Received_Date              DATE,
          p_Voucher_Num                        VARCHAR2,
          p_Approved_Amount                    NUMBER,
          p_Approval_Status                    VARCHAR2,
          p_Approval_Description               VARCHAR2,
          p_Pay_Group_Lookup_Code              VARCHAR2,
          p_Set_Of_Books_Id                    NUMBER,
          p_Accts_Pay_CCId                     NUMBER,
          p_Recurring_Payment_Id               NUMBER,
          p_Invoice_Currency_Code              VARCHAR2,
          p_Payment_Currency_Code              VARCHAR2,
          p_Exchange_Rate                      NUMBER,
          p_Payment_Amount_Total               NUMBER,
          p_Payment_Status_Flag                VARCHAR2,
          p_Posting_Status                     VARCHAR2,
          p_Authorized_By                      VARCHAR2,
          p_Attribute_Category                 VARCHAR2,
          p_Attribute1                         VARCHAR2,
          p_Attribute2                         VARCHAR2,
          p_Attribute3                         VARCHAR2,
          p_Attribute4                         VARCHAR2,
          p_Attribute5                         VARCHAR2,
          p_Vendor_Prepay_Amount               NUMBER,
          p_Base_Amount                        NUMBER,
          p_Exchange_Rate_Type                 VARCHAR2,
          p_Exchange_Date                      DATE,
          p_Payment_Cross_Rate                 NUMBER,
          p_Payment_Cross_Rate_Type            VARCHAR2,
          p_Payment_Cross_Rate_Date            DATE,
          p_Pay_Curr_Invoice_Amount            NUMBER,
          p_Last_Update_Login                  NUMBER,
          p_Original_Prepayment_Amount         NUMBER,
          p_Earliest_Settlement_Date           DATE,
          p_Attribute11                        VARCHAR2,
          p_Attribute12                        VARCHAR2,
          p_Attribute13                        VARCHAR2,
          p_Attribute14                        VARCHAR2,
          p_Attribute6                         VARCHAR2,
          p_Attribute7                         VARCHAR2,
          p_Attribute8                         VARCHAR2,
          p_Attribute9                         VARCHAR2,
          p_Attribute10                        VARCHAR2,
          p_Attribute15                        VARCHAR2,
          p_Cancelled_Date                     DATE,
          p_Cancelled_By                       NUMBER,
          p_Cancelled_Amount                   NUMBER,
          p_Temp_Cancelled_Amount              NUMBER,
          p_Exclusive_Payment_Flag             VARCHAR2,
          p_Po_Header_Id                       NUMBER,
          p_Doc_Sequence_Id                    NUMBER,
          p_Doc_Sequence_Value                 NUMBER,
          p_Doc_Category_Code                  VARCHAR2,
          p_Expenditure_Item_Date              DATE,
          p_Expenditure_Organization_Id        NUMBER,
          p_Expenditure_Type                   VARCHAR2,
          p_Pa_Default_Dist_Ccid               NUMBER,
          p_Pa_Quantity                        NUMBER,
          p_Project_Id                         NUMBER,
          p_Task_Id                            NUMBER,
          p_Awt_Flag                           VARCHAR2,
          p_Awt_Group_Id                       NUMBER,
          p_Pay_Awt_Group_Id                       NUMBER,--bug6639866
          p_Reference_1                        VARCHAR2,
          p_Reference_2                        VARCHAR2,
          p_Org_Id                             NUMBER,
          p_global_attribute_category          VARCHAR2 DEFAULT NULL,
          p_global_attribute1                  VARCHAR2 DEFAULT NULL,
          p_global_attribute2                  VARCHAR2 DEFAULT NULL,
          p_global_attribute3                  VARCHAR2 DEFAULT NULL,
          p_global_attribute4                  VARCHAR2 DEFAULT NULL,
          p_global_attribute5                  VARCHAR2 DEFAULT NULL,
          p_global_attribute6                  VARCHAR2 DEFAULT NULL,
          p_global_attribute7                  VARCHAR2 DEFAULT NULL,
          p_global_attribute8                  VARCHAR2 DEFAULT NULL,
          p_global_attribute9                  VARCHAR2 DEFAULT NULL,
          p_global_attribute10                 VARCHAR2 DEFAULT NULL,
          p_global_attribute11                 VARCHAR2 DEFAULT NULL,
          p_global_attribute12                 VARCHAR2 DEFAULT NULL,
          p_global_attribute13                 VARCHAR2 DEFAULT NULL,
          p_global_attribute14                 VARCHAR2 DEFAULT NULL,
          p_global_attribute15                 VARCHAR2 DEFAULT NULL,
          p_global_attribute16                 VARCHAR2 DEFAULT NULL,
          p_global_attribute17                 VARCHAR2 DEFAULT NULL,
          p_global_attribute18                 VARCHAR2 DEFAULT NULL,
          p_global_attribute19                 VARCHAR2 DEFAULT NULL,
          p_global_attribute20                 VARCHAR2 DEFAULT NULL,
          p_calling_sequence            IN     VARCHAR2,
          p_gl_date                            DATE,
          p_Award_Id                           NUMBER,
          p_approval_iteration                 NUMBER,
          p_approval_ready_flag                VARCHAR2 DEFAULT 'Y',
          p_wfapproval_status                  VARCHAR2 DEFAULT 'NOT REQUIRED',
          p_requester_id                       NUMBER   DEFAULT NULL,
          -- Invoice Lines Project Stage 1
          p_quick_credit                       VARCHAR2 DEFAULT NULL,
          p_credited_invoice_id                NUMBER   DEFAULT NULL,
          p_distribution_set_id                NUMBER   DEFAULT NULL,
	  p_FORCE_REVALIDATION_FLAG	       VARCHAR2 DEFAULT NULL,
	  p_CONTROL_AMOUNT                     NUMBER   DEFAULT NULL,
	  p_TAX_RELATED_INVOICE_ID             NUMBER   DEFAULT NULL,
	  p_TRX_BUSINESS_CATEGORY              VARCHAR2 DEFAULT NULL,
	  p_USER_DEFINED_FISC_CLASS            VARCHAR2 DEFAULT NULL,
	  p_TAXATION_COUNTRY                   VARCHAR2 DEFAULT NULL,
	  p_DOCUMENT_SUB_TYPE                  VARCHAR2 DEFAULT NULL,
	  p_SUPPLIER_TAX_INVOICE_NUMBER        VARCHAR2 DEFAULT NULL,
	  p_SUPPLIER_TAX_INVOICE_DATE          DATE     DEFAULT NULL,
	  p_SUPPLIER_TAX_EXCHANGE_RATE         NUMBER   DEFAULT NULL,
	  p_TAX_INVOICE_RECORDING_DATE         DATE     DEFAULT NULL,
	  p_TAX_INVOICE_INTERNAL_SEQ           VARCHAR2 DEFAULT NULL, -- bug 8912305: modify
	  p_QUICK_PO_HEADER_ID		       NUMBER   DEFAULT NULL,
          P_PAYMENT_METHOD_CODE                varchar2 ,
          P_PAYMENT_REASON_CODE                varchar2 default null,
          P_PAYMENT_REASON_COMMENTS            varchar2 default null,
          P_UNIQUE_REMITTANCE_IDENTIFIER       varchar2 default null,
          P_URI_CHECK_DIGIT                    varchar2 default null,
          P_BANK_CHARGE_BEARER                 varchar2 default null,
          P_DELIVERY_CHANNEL_CODE              varchar2 default null,
          P_SETTLEMENT_PRIORITY                varchar2 default null,
	  p_net_of_retainage_flag	       varchar2 default null,
	  p_release_amount_net_of_tax	       number   default null,
	  p_port_of_entry_code		       varchar2 default null,
          p_external_bank_account_id           number   default null,
          p_party_id                           number   default null,
          p_party_site_id                      number   default null,
          p_disc_is_inv_less_tax_flag          varchar2 default null,
          p_exclude_freight_from_disc          varchar2 default null,
          -- Bug 5087834
          p_remit_msg1                         varchar2 default null,
          p_remit_msg2                         varchar2 default null,
          p_remit_msg3                         varchar2 default null,
	  /* Third Party Payments*/
	  p_remit_to_supplier_name	varchar2 default null,
	  p_remit_to_supplier_id	number default null,
	  p_remit_to_supplier_site	varchar2 default null,
	  p_remit_to_supplier_site_id number default null,
	  p_relationship_id		number default null,
	  /* Bug 7831073 */
	  p_original_invoice_amount number default null,
	  p_dispute_reason varchar2 default null
	  )
IS
  current_calling_sequence           VARCHAR2(2000);
  debug_info                         VARCHAR2(100);
  l_invoice_id                       NUMBER;
BEGIN

  -- Update the calling sequence

  current_calling_sequence :=
               'AP_AI_TABLE_HANDLER_PKG.UPDATE_ROW<-'||p_calling_sequence;

  -- Check uniqueness first
  ap_ai_table_handler_pkg.check_unique(
          p_ROWID,
          p_INVOICE_NUM,
          p_VENDOR_ID,
          p_ORG_ID,     -- Bug 5407785
	  P_PARTY_SITE_ID, /*Bug9105666*/
          P_VENDOR_SITE_ID, /*Bug9105666*/
          current_calling_sequence);

  debug_info := 'Update ap_invoices';
  UPDATE ap_invoices_all
  SET
    invoice_id                     = p_Invoice_Id,
    last_update_date               = p_Last_Update_Date,
    last_updated_by                = p_Last_Updated_By,
    vendor_id                      = p_Vendor_Id,
    invoice_num                    = p_Invoice_Num,
    invoice_amount                 = p_Invoice_Amount,
    vendor_site_id                 = p_Vendor_Site_Id,
    amount_paid                    = p_Amount_Paid,
    discount_amount_taken          = p_Discount_Amount_Taken,
    invoice_date                   = p_Invoice_Date,
    source                         = p_Source,
    invoice_type_lookup_code       = p_Invoice_Type_Lookup_Code,
    description                    = p_Description,
    batch_id                       = p_Batch_Id,
    amount_applicable_to_discount  = p_Amt_Applicable_To_Discount,
    terms_id                       = p_Terms_Id,
    terms_date                     = p_Terms_Date,
    goods_received_date            = p_Goods_Received_Date,
    invoice_received_date          = p_Invoice_Received_Date,
    voucher_num                    = p_Voucher_Num,
    approved_amount                = p_Approved_Amount,
    approval_status                = p_Approval_Status,
    approval_description           = p_Approval_Description,
    pay_group_lookup_code          = p_Pay_Group_Lookup_Code,
    set_of_books_id                = p_Set_Of_Books_Id,
    accts_pay_code_combination_id  = p_Accts_Pay_CCId,
    recurring_payment_id           = p_Recurring_Payment_Id,
    invoice_currency_code          = p_Invoice_Currency_Code,
    payment_currency_code          = p_Payment_Currency_Code,
    exchange_rate                  = p_Exchange_Rate,
    payment_amount_total           = p_Payment_Amount_Total,
    payment_status_flag            = p_Payment_Status_Flag,
    posting_status                 = p_Posting_Status,
    authorized_by                  = p_Authorized_By,
    attribute_category             = p_Attribute_Category,
    attribute1                     = p_Attribute1,
    attribute2                     = p_Attribute2,
    attribute3                     = p_Attribute3,
    attribute4                     = p_Attribute4,
    attribute5                     = p_Attribute5,
    vendor_prepay_amount           = p_Vendor_Prepay_Amount,
    base_amount                    = p_Base_Amount,
    exchange_rate_type             = p_Exchange_Rate_Type,
    exchange_date                  = p_Exchange_Date,
    payment_cross_rate             = p_Payment_Cross_Rate,
    payment_cross_rate_type        = p_Payment_Cross_Rate_Type,
    payment_cross_rate_date        = p_Payment_Cross_Rate_Date,
    pay_curr_invoice_amount        = p_Pay_Curr_Invoice_Amount,
    last_update_login              = p_Last_Update_Login,
    original_prepayment_amount     = p_Original_Prepayment_Amount,
    earliest_settlement_date       = p_Earliest_Settlement_Date,
    attribute11                    = p_Attribute11,
    attribute12                    = p_Attribute12,
    attribute13                    = p_Attribute13,
    attribute14                    = p_Attribute14,
    attribute6                     = p_Attribute6,
    attribute7                     = p_Attribute7,
    attribute8                     = p_Attribute8,
    attribute9                     = p_Attribute9,
    attribute10                    = p_Attribute10,
    attribute15                    = p_Attribute15,
    cancelled_date                 = p_Cancelled_Date,
    cancelled_by                   = p_Cancelled_By,
    cancelled_amount               = p_Cancelled_Amount,
    temp_cancelled_amount          = p_Temp_Cancelled_Amount,
    exclusive_payment_flag         = p_Exclusive_Payment_Flag,
    po_header_id                   = p_Po_Header_Id,
    doc_sequence_id                = p_Doc_Sequence_Id,
    doc_sequence_value             = p_Doc_Sequence_Value,
    doc_category_code              = p_Doc_Category_Code,
    expenditure_item_date          = p_Expenditure_Item_Date,
    expenditure_organization_id    = p_Expenditure_Organization_Id,
    expenditure_type               = p_Expenditure_Type,
    pa_default_dist_ccid           = p_Pa_Default_Dist_Ccid,
    pa_quantity                    = p_Pa_Quantity,
    project_id                     = p_Project_Id,
    task_id                        = p_Task_Id,
    awt_flag                       = p_Awt_Flag,
    awt_group_id                   = p_Awt_Group_Id,
    pay_awt_group_id                   = p_Pay_Awt_Group_Id,--bug6639866
    reference_1                    = p_Reference_1,
    reference_2                    = p_Reference_2,
    global_attribute_category      = p_global_attribute_category,
    global_attribute1              = p_global_attribute1,
    global_attribute2              = p_global_attribute2,
    global_attribute3              = p_global_attribute3,
    global_attribute4              = p_global_attribute4,
    global_attribute5              = p_global_attribute5,
    global_attribute6              = p_global_attribute6,
    global_attribute7              = p_global_attribute7,
    global_attribute8              = p_global_attribute8,
    global_attribute9              = p_global_attribute9,
    global_attribute10             = p_global_attribute10,
    global_attribute11             = p_global_attribute11,
    global_attribute12             = p_global_attribute12,
    global_attribute13             = p_global_attribute13,
    global_attribute14             = p_global_attribute14,
    global_attribute15             = p_global_attribute15,
    global_attribute16             = p_global_attribute16,
    global_attribute17             = p_global_attribute17,
    global_attribute18             = p_global_attribute18,
    global_attribute19             = p_global_attribute19,
    global_attribute20             = p_global_attribute20,
    award_id                       = p_Award_Id,
    gl_date                        = p_gl_date,
    approval_iteration             = p_approval_iteration,
    approval_ready_flag            = p_approval_ready_flag,
    wfapproval_status              = p_wfapproval_status,
    requester_id                   = p_requester_id,
    -- Invoice Lines Project Stage 1
    quick_credit                   = p_quick_credit,
    credited_invoice_id            = p_credited_invoice_id,
    distribution_set_id            = p_distribution_set_id,
    --ETAX: Invwkb
    force_revalidation_flag        = p_force_revalidation_flag,
    control_amount		   = p_control_amount,
    tax_related_invoice_id         = p_tax_related_invoice_id,
    trx_business_category          = p_trx_business_category,
    user_defined_fisc_class        = p_user_defined_fisc_class,
    taxation_country               = p_taxation_country,
    document_sub_type              = p_document_sub_type,
    supplier_tax_invoice_number    = p_supplier_tax_invoice_number,
    supplier_tax_invoice_date      = p_supplier_tax_invoice_date,
    supplier_tax_exchange_rate     = p_supplier_tax_exchange_rate,
    tax_invoice_recording_date     = p_tax_invoice_recording_date,
    tax_invoice_internal_seq       = p_tax_invoice_internal_seq,
    quick_po_header_id		   = p_quick_po_header_id,
    PAYMENT_METHOD_CODE            = p_PAYMENT_METHOD_CODE,
    PAYMENT_REASON_CODE            = p_PAYMENT_REASON_CODE,
    PAYMENT_REASON_COMMENTS        = P_PAYMENT_REASON_COMMENTS,
    UNIQUE_REMITTANCE_IDENTIFIER   = p_UNIQUE_REMITTANCE_IDENTIFIER,
    URI_CHECK_DIGIT                = p_URI_CHECK_DIGIT,
    BANK_CHARGE_BEARER             = p_BANK_CHARGE_BEARER,
    DELIVERY_CHANNEL_CODE          = p_DELIVERY_CHANNEL_CODE,
    SETTLEMENT_PRIORITY            = p_SETTLEMENT_PRIORITY,
    net_of_retainage_flag	   = p_net_of_retainage_flag,
    release_amount_net_of_tax	   = p_release_amount_net_of_tax,
    port_of_entry_code		   = p_port_of_entry_code,
    external_bank_account_id       = p_external_bank_account_id,
    party_id                       = p_party_id,
    party_site_id                  = p_party_site_id,
     /* bug 4931755 */
    disc_is_inv_less_tax_flag      = p_disc_is_inv_less_tax_flag,
    exclude_freight_from_discount  = p_exclude_freight_from_disc,
    REMITTANCE_MESSAGE1            = p_remit_msg1,
    REMITTANCE_MESSAGE2            = p_remit_msg2,
    REMITTANCE_MESSAGE3            = p_remit_msg3,
	  /* Third Party Payments*/
    remit_to_supplier_name            = p_remit_to_supplier_name,
    remit_to_supplier_id			 = p_remit_to_supplier_id,
    remit_to_supplier_site		 = p_remit_to_supplier_site,
    remit_to_supplier_site_id           = p_remit_to_supplier_site_id,
    relationship_id				 = p_relationship_id,
	/* Bug 7831073 */
	original_invoice_amount      = p_original_invoice_amount,
	dispute_reason               = p_dispute_reason
  WHERE rowid = p_rowid;

  IF (SQL%NOTFOUND) THEN
    RAISE NO_DATA_FOUND;
  END IF;

  SELECT invoice_id
    INTO l_invoice_id
    FROM ap_invoices_all
   WHERE rowid = p_rowid;

   --Bug 4539462 DBI logging
   AP_DBI_PKG.Maintain_DBI_Summary
              (p_table_name => 'AP_INVOICES',
               p_operation => 'U',
               p_key_value1 => P_invoice_id,
                p_calling_sequence => current_calling_sequence);

 EXCEPTION
     WHEN OTHERS THEN
         IF (SQLCODE <> -20001) THEN
           FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
           FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
           FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',
                     current_calling_sequence);
           FND_MESSAGE.SET_TOKEN('PARAMETERS',
               'p_Rowid = '||p_Rowid
           ||', p_invoice_id = '||p_invoice_id
                                    );
           FND_MESSAGE.SET_TOKEN('DEBUG_INFO',debug_info);
         END IF;
       APP_EXCEPTION.RAISE_EXCEPTION;


END Update_Row;


PROCEDURE Delete_Row(
          p_Rowid                      VARCHAR2,
          p_calling_sequence   IN      VARCHAR2)
IS
  l_invoice_id                  NUMBER;
  current_calling_sequence      VARCHAR2(2000);
  debug_info                    VARCHAR2(100);
  l_key_value_list              gl_ca_utility_pkg.r_key_value_arr;

   /*Start of 7388641*/
  l_invoice_type_lookup_code    AP_INVOICES.INVOICE_TYPE_LOOKUP_CODE%TYPE;
  l_return_status_service       VARCHAR2(50);
  l_msg_count                   NUMBER;
  l_msg_data                    VARCHAR2(100);
  l_transaction_rec             ZX_API_PUB.TRANSACTION_REC_TYPE;
  l_event_class_code            VARCHAR2(25) := NULL;
  l_event_type_code             VARCHAR2(25) := NULL;
  l_error_code                  VARCHAR2(25);
  l_success                     BOOLEAN;

  /*End of 7388641*/

BEGIN
  -- Update the calling sequence
  --
  current_calling_sequence :=
               'AP_AI_TABLE_HANDLER_PKG.DELETE_ROW<-'||p_calling_sequence;

  -- Get the invoice_id
  debug_info := 'Get the invoice_id';

 /*7388641 also selecting invoice_type_lookup_code*/
  SELECT invoice_id,invoice_type_lookup_code
    INTO   l_invoice_id,l_invoice_type_lookup_code
    FROM   ap_invoices
   WHERE  rowid = p_rowid;

  -- Delete attachments
  debug_info := 'Delete from fnd_attachments';
  fnd_attached_documents2_pkg.delete_attachments(
                'AP_INVOICES',
                l_invoice_id);

  -- Delete from the child entities
  -- debug_info := 'Delete from child entity - jg_zz_invoice_info';

  -- DELETE FROM jg_zz_invoice_info
  -- WHERE invoice_id = l_invoice_id;

  debug_info := 'Delete from child entity - ap_invoice_distributions';

  DELETE FROM ap_invoice_distributions_all
  WHERE  invoice_id = l_invoice_id
  RETURNING invoice_distribution_id
  BULK COLLECT INTO l_key_value_list;

  --Bugfix:4670908
  debug_info := 'Delete from child entity - ap_invoice_lines';
  DELETE FROM ap_invoice_lines_all
  WHERE invoice_id = l_invoice_id;

  --added back in the following deletes
  debug_info := 'Delete from child entity - ap_payment_schedules';
  delete from ap_payment_schedules_all
  where  invoice_id = l_invoice_id;

  debug_info := 'Delete from child entity - ap_holds';
  delete from ap_holds_all
  where  invoice_id = l_invoice_id;

  --7388641 to de orphan records in tax tables---

  debug_info := 'Delete from child entity - ap_self_assessed_tax_dist';
  DELETE FROM ap_self_assessed_tax_dist_all
  WHERE invoice_id = l_invoice_id;

  debug_info := 'Before deleting data in Tax tables taking required data';

   l_transaction_rec.application_id := 200;
   l_transaction_rec.entity_code := 'AP_INVOICES';
   l_transaction_rec.trx_id := l_invoice_id;

   l_success :=  AP_ETAX_UTILITY_PKG.Get_Event_Class_Code(
                   P_Invoice_Type_Lookup_Code => l_invoice_type_lookup_code,
                   P_Event_Class_Code         => l_event_class_code,
                   P_error_code               => l_error_code,
                   P_calling_sequence         => current_calling_sequence);

    IF (l_success) THEN
         l_transaction_rec.event_class_code := l_event_class_code;
    END IF;

    l_success :=  AP_ETAX_UTILITY_PKG.Get_Event_Type_Code(
                    P_Event_Class_Code          => l_event_class_code,
                    P_Calling_Mode              => 'DELETE INVOICE' ,
                    P_eTax_Already_called_flag  =>  NULL,
                    P_Event_Type_Code           => l_event_type_code,
                    P_Error_Code                => l_error_code,
                    P_Calling_Sequence          => current_calling_sequence);

     IF (l_success) THEN
         l_transaction_rec.event_type_code := l_event_type_code;
     END IF;

     debug_info := 'Calling ZX API to delete entries in Tax tables';

      zx_api_pub.global_document_update(
         p_api_version        => 1.0,              --in parameter
         p_init_msg_list      => FND_API.G_TRUE,   --in parameter
         p_commit             => FND_API.G_FALSE,  --in parameter
         p_validation_level   => FND_API.G_VALID_LEVEL_FULL,--in out parameter
         p_transaction_rec    => l_transaction_rec,--in parameter
         x_return_status      => l_return_status_service,--out parameter
         x_msg_count          => l_msg_count,      --out parameter
         x_msg_data           => l_msg_data);      --out parameter

     --End of 7388641 --

  debug_info := 'Delete from ap_invoices';
  DELETE FROM ap_invoices_all
  WHERE  rowid = p_Rowid;

  --Bug 4539462 DBI logging
  AP_DBI_PKG.Maintain_DBI_Summary
              (p_table_name => 'AP_INVOICES',
               p_operation => 'D',
               p_key_value1 => l_invoice_id,
                p_calling_sequence => current_calling_sequence);

  IF (SQL%NOTFOUND) THEN
    RAISE NO_DATA_FOUND;
  END IF;

  EXCEPTION
     WHEN OTHERS THEN
         IF (SQLCODE <> -20001) THEN
           FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
           FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
           FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',
                     current_calling_sequence);
           FND_MESSAGE.SET_TOKEN('PARAMETERS',
               'p_Rowid = '||p_Rowid
                                    );
           FND_MESSAGE.SET_TOKEN('DEBUG_INFO',debug_info);
         END IF;
       APP_EXCEPTION.RAISE_EXCEPTION;


END DELETE_ROW;

END AP_AI_TABLE_HANDLER_PKG;
/