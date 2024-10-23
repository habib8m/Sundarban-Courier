CREATE OR REPLACE PACKAGE APPS.AP_INVOICES_PKG AUTHID CURRENT_USER AS
/* $Header: apiinces.pls 120.37 2011/07/04 20:27:42 asansari ship $ */

TYPE r_invoice_line_rec IS RECORD (
  invoice_id                   AP_INVOICE_LINES.INVOICE_ID%TYPE,
  line_number                  AP_INVOICE_LINES.LINE_NUMBER%TYPE,
  line_type_lookup_code        AP_INVOICE_LINES.LINE_TYPE_LOOKUP_CODE%TYPE,
  requester_id                 AP_INVOICE_LINES.REQUESTER_ID%TYPE,
  description                  AP_INVOICE_LINES.DESCRIPTION%TYPE,
  line_source                  AP_INVOICE_LINES.LINE_SOURCE%TYPE,
  org_id                       AP_INVOICE_LINES.ORG_ID%TYPE,
  line_group_number            AP_INVOICE_LINES.LINE_GROUP_NUMBER%TYPE,
  inventory_item_id            AP_INVOICE_LINES.INVENTORY_ITEM_ID%TYPE,
  item_description             AP_INVOICE_LINES.ITEM_DESCRIPTION%TYPE,
  serial_number                AP_INVOICE_LINES.SERIAL_NUMBER%TYPE,
  manufacturer                 AP_INVOICE_LINES.MANUFACTURER%TYPE,
  model_number                 AP_INVOICE_LINES.MODEL_NUMBER%TYPE,
  warranty_number              AP_INVOICE_LINES.WARRANTY_NUMBER%TYPE,
  generate_dists               AP_INVOICE_LINES.GENERATE_DISTS%TYPE,
  match_type                   AP_INVOICE_LINES.MATCH_TYPE%TYPE,
  distribution_set_id          AP_INVOICE_LINES.DISTRIBUTION_SET_ID%TYPE,
  account_segment              AP_INVOICE_LINES.ACCOUNT_SEGMENT%TYPE,
  balancing_segment            AP_INVOICE_LINES.BALANCING_SEGMENT%TYPE,
  cost_center_segment          AP_INVOICE_LINES.COST_CENTER_SEGMENT%TYPE,
  overlay_dist_code_concat     AP_INVOICE_LINES.OVERLAY_DIST_CODE_CONCAT%TYPE,
  default_dist_ccid            AP_INVOICE_LINES.DEFAULT_DIST_CCID%TYPE,
  prorate_across_all_items     AP_INVOICE_LINES.PRORATE_ACROSS_ALL_ITEMS%TYPE,
  accounting_date              AP_INVOICE_LINES.ACCOUNTING_DATE%TYPE,
  period_name                  AP_INVOICE_LINES.PERIOD_NAME%TYPE,
  deferred_acctg_flag          AP_INVOICE_LINES.DEFERRED_ACCTG_FLAG%TYPE,
  def_acctg_start_date         AP_INVOICE_LINES.DEF_ACCTG_START_DATE %TYPE,
  def_acctg_end_date           AP_INVOICE_LINES.DEF_ACCTG_END_DATE%TYPE,
  def_acctg_number_of_periods
             AP_INVOICE_LINES.DEF_ACCTG_NUMBER_OF_PERIODS%TYPE,
  def_acctg_period_type        AP_INVOICE_LINES.DEF_ACCTG_PERIOD_TYPE%TYPE,
  set_of_books_id              AP_INVOICE_LINES.SET_OF_BOOKS_ID%TYPE,
  amount                       AP_INVOICE_LINES.AMOUNT%TYPE,
  base_amount                  AP_INVOICE_LINES.BASE_AMOUNT%TYPE,
  rounding_amt                 AP_INVOICE_LINES.ROUNDING_AMT%TYPE,
  quantity_invoiced            AP_INVOICE_LINES.QUANTITY_INVOICED%TYPE,
  unit_meas_lookup_code        AP_INVOICE_LINES.UNIT_MEAS_LOOKUP_CODE%TYPE,
  unit_price                   AP_INVOICE_LINES.UNIT_PRICE%TYPE,
  wfapproval_status            AP_INVOICE_LINES.WFAPPROVAL_STATUS%TYPE,
  discarded_flag               AP_INVOICE_LINES.DISCARDED_FLAG%TYPE,
  original_amount              AP_INVOICE_LINES.ORIGINAL_AMOUNT%TYPE,
  original_base_amount         AP_INVOICE_LINES.ORIGINAL_BASE_AMOUNT%TYPE,
  original_rounding_amt        AP_INVOICE_LINES.ORIGINAL_ROUNDING_AMT%TYPE,
  cancelled_flag               AP_INVOICE_LINES.CANCELLED_FLAG%TYPE,
  income_tax_region            AP_INVOICE_LINES.INCOME_TAX_REGION%TYPE,
  type_1099                    AP_INVOICE_LINES.TYPE_1099%TYPE,
  stat_amount                  AP_INVOICE_LINES.STAT_AMOUNT%TYPE,
  prepay_invoice_id            AP_INVOICE_LINES.PREPAY_INVOICE_ID%TYPE,
  prepay_line_number           AP_INVOICE_LINES.PREPAY_LINE_NUMBER%TYPE,
  invoice_includes_prepay_flag
             AP_INVOICE_LINES.INVOICE_INCLUDES_PREPAY_FLAG%TYPE,
  corrected_inv_id             AP_INVOICE_LINES.CORRECTED_INV_ID%TYPE,
  corrected_line_number        AP_INVOICE_LINES.CORRECTED_LINE_NUMBER%TYPE,
  po_header_id                 AP_INVOICE_LINES.PO_HEADER_ID%TYPE,
  po_line_id                   AP_INVOICE_LINES.PO_LINE_ID%TYPE,
  po_release_id                AP_INVOICE_LINES.PO_RELEASE_ID%TYPE,
  po_line_location_id          AP_INVOICE_LINES.PO_LINE_LOCATION_ID%TYPE,
  po_distribution_id           AP_INVOICE_LINES.PO_DISTRIBUTION_ID%TYPE,
  rcv_transaction_id           AP_INVOICE_LINES.RCV_TRANSACTION_ID%TYPE,
  final_match_flag             AP_INVOICE_LINES.FINAL_MATCH_FLAG%TYPE,
  assets_tracking_flag         AP_INVOICE_LINES.ASSETS_TRACKING_FLAG%TYPE,
  asset_book_type_code         AP_INVOICE_LINES.ASSET_BOOK_TYPE_CODE%TYPE,
  asset_category_id            AP_INVOICE_LINES.ASSET_CATEGORY_ID%TYPE,
  project_id                   AP_INVOICE_LINES.PROJECT_ID%TYPE,
  task_id                      AP_INVOICE_LINES.TASK_ID%TYPE,
  expenditure_type             AP_INVOICE_LINES.EXPENDITURE_TYPE%TYPE,
  expenditure_item_date        AP_INVOICE_LINES.EXPENDITURE_ITEM_DATE%TYPE,
  expenditure_organization_id
             AP_INVOICE_LINES.EXPENDITURE_ORGANIZATION_ID%TYPE,
  pa_quantity                  AP_INVOICE_LINES.PA_QUANTITY%TYPE,
  pa_cc_ar_invoice_id          AP_INVOICE_LINES.PA_CC_AR_INVOICE_ID%TYPE,
  pa_cc_ar_invoice_line_num    AP_INVOICE_LINES.PA_CC_AR_INVOICE_LINE_NUM%TYPE,
  pa_cc_processed_code         AP_INVOICE_LINES.PA_CC_PROCESSED_CODE%TYPE,
  award_id                     AP_INVOICE_LINES.AWARD_ID%TYPE,
  awt_group_id                 AP_INVOICE_LINES.AWT_GROUP_ID%TYPE,
  reference_1                  AP_INVOICE_LINES.REFERENCE_1%TYPE,
  reference_2                  AP_INVOICE_LINES.REFERENCE_2%TYPE,
  receipt_verified_flag        AP_INVOICE_LINES.RECEIPT_VERIFIED_FLAG%TYPE,
  receipt_required_flag        AP_INVOICE_LINES.RECEIPT_REQUIRED_FLAG%TYPE,
  receipt_missing_flag         AP_INVOICE_LINES.RECEIPT_MISSING_FLAG%TYPE,
  justification                AP_INVOICE_LINES.JUSTIFICATION%TYPE,
  expense_group                AP_INVOICE_LINES.EXPENSE_GROUP%TYPE,
  start_expense_date           AP_INVOICE_LINES.START_EXPENSE_DATE%TYPE,
  end_expense_date             AP_INVOICE_LINES.END_EXPENSE_DATE%TYPE,
  receipt_currency_code        AP_INVOICE_LINES.RECEIPT_CURRENCY_CODE%TYPE,
  receipt_conversion_rate      AP_INVOICE_LINES.RECEIPT_CONVERSION_RATE%TYPE,
  receipt_currency_amount      AP_INVOICE_LINES.RECEIPT_CONVERSION_RATE%TYPE,
  daily_amount                 AP_INVOICE_LINES.DAILY_AMOUNT%TYPE,
  web_parameter_id             AP_INVOICE_LINES.WEB_PARAMETER_ID%TYPE,
  adjustment_reason            AP_INVOICE_LINES.ADJUSTMENT_REASON%TYPE,
  merchant_document_number     AP_INVOICE_LINES.MERCHANT_DOCUMENT_NUMBER%TYPE,
  merchant_name                AP_INVOICE_LINES.MERCHANT_NAME%TYPE,
  merchant_reference           AP_INVOICE_LINES.MERCHANT_REFERENCE%TYPE,
  merchant_tax_reg_number      AP_INVOICE_LINES.MERCHANT_TAX_REG_NUMBER%TYPE,
  merchant_taxpayer_id         AP_INVOICE_LINES.MERCHANT_TAXPAYER_ID%TYPE,
  country_of_supply            AP_INVOICE_LINES.COUNTRY_OF_SUPPLY%TYPE,
  credit_card_trx_id           AP_INVOICE_LINES.CREDIT_CARD_TRX_ID%TYPE,
  company_prepaid_invoice_id   AP_INVOICE_LINES.COMPANY_PREPAID_INVOICE_ID%TYPE,
  cc_reversal_flag             AP_INVOICE_LINES.CC_REVERSAL_FLAG%TYPE,
  creation_date                AP_INVOICE_LINES.CREATION_DATE%TYPE,
  created_by                   AP_INVOICE_LINES.CREATED_BY%TYPE,
  last_updated_by              AP_INVOICE_LINES.LAST_UPDATED_BY%TYPE,
  last_update_date             AP_INVOICE_LINES.LAST_UPDATE_DATE%TYPE,
  last_update_login            AP_INVOICE_LINES.LAST_UPDATE_LOGIN%TYPE,
  program_application_id       AP_INVOICE_LINES.PROGRAM_APPLICATION_ID%TYPE,
  program_id                   AP_INVOICE_LINES.PROGRAM_ID%TYPE,
  program_update_date          AP_INVOICE_LINES.PROGRAM_UPDATE_DATE%TYPE,
  request_id                   AP_INVOICE_LINES.REQUEST_ID%TYPE,
  attribute_category           AP_INVOICE_LINES.ATTRIBUTE_CATEGORY%TYPE,
  attribute1                   AP_INVOICE_LINES.ATTRIBUTE1%TYPE,
  attribute2                   AP_INVOICE_LINES.ATTRIBUTE2%TYPE,
  attribute3                   AP_INVOICE_LINES.ATTRIBUTE3%TYPE,
  attribute4                   AP_INVOICE_LINES.ATTRIBUTE4%TYPE,
  attribute5                   AP_INVOICE_LINES.ATTRIBUTE5%TYPE,
  attribute6                   AP_INVOICE_LINES.ATTRIBUTE6%TYPE,
  attribute7                   AP_INVOICE_LINES.ATTRIBUTE7%TYPE,
  attribute8                   AP_INVOICE_LINES.ATTRIBUTE8%TYPE,
  attribute9                   AP_INVOICE_LINES.ATTRIBUTE9%TYPE,
  attribute10                  AP_INVOICE_LINES.ATTRIBUTE10%TYPE,
  attribute11                  AP_INVOICE_LINES.ATTRIBUTE11%TYPE,
  attribute12                  AP_INVOICE_LINES.ATTRIBUTE12%TYPE,
  attribute13                  AP_INVOICE_LINES.ATTRIBUTE13%TYPE,
  attribute14                  AP_INVOICE_LINES.ATTRIBUTE14%TYPE,
  attribute15                  AP_INVOICE_LINES.ATTRIBUTE15%TYPE,
  global_attribute_category    AP_INVOICE_LINES.GLOBAL_ATTRIBUTE_CATEGORY%TYPE,
  global_attribute1            AP_INVOICE_LINES.GLOBAL_ATTRIBUTE1%TYPE,
  global_attribute2            AP_INVOICE_LINES.GLOBAL_ATTRIBUTE2%TYPE,
  global_attribute3            AP_INVOICE_LINES.GLOBAL_ATTRIBUTE3%TYPE,
  global_attribute4            AP_INVOICE_LINES.GLOBAL_ATTRIBUTE4%TYPE,
  global_attribute5            AP_INVOICE_LINES.GLOBAL_ATTRIBUTE5%TYPE,
  global_attribute6            AP_INVOICE_LINES.GLOBAL_ATTRIBUTE6%TYPE,
  global_attribute7            AP_INVOICE_LINES.GLOBAL_ATTRIBUTE7%TYPE,
  global_attribute8            AP_INVOICE_LINES.GLOBAL_ATTRIBUTE8%TYPE,
  global_attribute9            AP_INVOICE_LINES.GLOBAL_ATTRIBUTE9%TYPE,
  global_attribute10           AP_INVOICE_LINES.GLOBAL_ATTRIBUTE10%TYPE,
  global_attribute11           AP_INVOICE_LINES.GLOBAL_ATTRIBUTE11%TYPE,
  global_attribute12           AP_INVOICE_LINES.GLOBAL_ATTRIBUTE12%TYPE,
  global_attribute13           AP_INVOICE_LINES.GLOBAL_ATTRIBUTE13%TYPE,
  global_attribute14           AP_INVOICE_LINES.GLOBAL_ATTRIBUTE14%TYPE,
  global_attribute15           AP_INVOICE_LINES.GLOBAL_ATTRIBUTE15%TYPE,
  global_attribute16           AP_INVOICE_LINES.GLOBAL_ATTRIBUTE16%TYPE,
  global_attribute17           AP_INVOICE_LINES.GLOBAL_ATTRIBUTE17%TYPE,
  global_attribute18           AP_INVOICE_LINES.GLOBAL_ATTRIBUTE18%TYPE,
  global_attribute19           AP_INVOICE_LINES.GLOBAL_ATTRIBUTE19%TYPE,
  global_attribute20           AP_INVOICE_LINES.GLOBAL_ATTRIBUTE20%TYPE,
  --ETAX: invwkb
  included_tax_amount	       AP_INVOICE_LINES.INCLUDED_TAX_AMOUNT%TYPE,
  primary_intended_use         AP_INVOICE_LINES.PRIMARY_INTENDED_USE%TYPE,
  application_id	       AP_INVOICE_LINES.APPLICATION_ID%TYPE,
  product_table		       AP_INVOICE_LINES.PRODUCT_TABLE%TYPE,
  reference_key1	       AP_INVOICE_LINES.REFERENCE_KEY1%TYPE,
  reference_key2               AP_INVOICE_LINES.REFERENCE_KEY2%TYPE,
  reference_key3               AP_INVOICE_LINES.REFERENCE_KEY3%TYPE,
  reference_key4               AP_INVOICE_LINES.REFERENCE_KEY4%TYPE,
  reference_key5               AP_INVOICE_LINES.REFERENCE_KEY5%TYPE,
  --bugfix:4674194
  ship_to_location_id	       AP_INVOICE_LINES.SHIP_TO_LOCATION_ID%TYPE,
  --bug7022001
  pay_awt_group_id             AP_INVOICE_LINES.PAY_AWT_GROUP_ID%TYPE);

TYPE t_invoice_lines_table is TABLE of r_invoice_line_rec
     index by BINARY_INTEGER;

PROCEDURE Insert_Row(
          X_Rowid                       IN OUT NOCOPY VARCHAR2,
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
          X_Pay_Awt_Group_Id                       NUMBER,--bug6639866
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
	  --Etax: Invwkb
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
          x_NET_OF_RETAINAGE_FLAG              varchar2 default null,
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
	  );

PROCEDURE Lock_Row(
          X_Invoice_id                         NUMBER,
          X_calling_sequence                   VARCHAR2);

PROCEDURE Lock_Row(X_Rowid                    VARCHAR2,
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
          X_Pay_Awt_Group_Id                       NUMBER,--bug6639866
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
          X_Award_Id                          NUMBER,
          X_APPROVAL_ITERATION                NUMBER,
          X_APPROVAL_READY_FLAG               VARCHAR2,
          X_WFAPPROVAL_STATUS                 VARCHAR2,
          X_REQUESTER_ID                      NUMBER DEFAULT NULL,
          -- Invoice Lines Project Stage 1
          X_QUICK_CREDIT                      VARCHAR2 DEFAULT NULL,
          X_CREDITED_INVOICE_ID               NUMBER   DEFAULT NULL,
          X_DISTRIBUTION_SET_ID               NUMBER   DEFAULT NULL,
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
          x_NET_OF_RETAINAGE_FLAG              varchar2 default null,
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
	  );


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
          X_Pay_Awt_Group_Id                       NUMBER,--bug6639866
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
          x_NET_OF_RETAINAGE_FLAG              varchar2 default null,
	  x_RELEASE_AMOUNT_NET_OF_TAX	       number	default null,
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
	  );


PROCEDURE Delete_Row(
          X_Rowid                             VARCHAR2,
          X_calling_sequence                  VARCHAR2);

PROCEDURE CHECK_UNIQUE (
          X_rowid                             VARCHAR2,
          X_invoice_num                       VARCHAR2,
          X_vendor_id                         NUMBER,
          X_org_id                            NUMBER, -- 5407785
	  X_PARTY_SITE_ID                     NUMBER, /*Bug9105666*/
	  X_VENDOR_SITE_ID                    NUMBER, /*Bug9105666*/
          X_calling_sequence                  VARCHAR2);

PROCEDURE CHECK_UNIQUE_VOUCHER_NUM(
          X_rowid                             VARCHAR2,
          X_voucher_num                       VARCHAR2,
          X_calling_sequence                  VARCHAR2);

FUNCTION get_distribution_total(l_invoice_id IN NUMBER) RETURN NUMBER;
FUNCTION get_posting_status(l_invoice_id IN NUMBER) RETURN VARCHAR2;
FUNCTION get_approval_status(l_invoice_id IN NUMBER,
                             l_invoice_amount IN NUMBER,
                             l_payment_status_flag IN VARCHAR2,
                             l_invoice_type_lookup_code IN VARCHAR2)
RETURN VARCHAR2;

FUNCTION get_po_number(l_invoice_id IN NUMBER) RETURN VARCHAR2;
FUNCTION get_release_number(l_invoice_id IN NUMBER) RETURN VARCHAR2;
FUNCTION get_receipt_number(l_invoice_id IN NUMBER) RETURN VARCHAR2;
FUNCTION get_po_number_list(l_invoice_id IN NUMBER) RETURN VARCHAR2;
FUNCTION get_amount_withheld(l_invoice_id IN NUMBER) RETURN NUMBER;
FUNCTION get_prepaid_amount(l_invoice_id IN NUMBER) RETURN NUMBER;
FUNCTION get_notes_count(l_invoice_id IN NUMBER) RETURN NUMBER;
FUNCTION get_holds_count(l_invoice_id IN NUMBER) RETURN NUMBER;
FUNCTION get_sched_holds_count(l_invoice_id IN NUMBER) RETURN NUMBER;  --bug 5334577
FUNCTION get_amount_hold_flag(l_invoice_id IN NUMBER) RETURN VARCHAR2;
FUNCTION get_vendor_hold_flag(l_invoice_id IN NUMBER) RETURN VARCHAR2;
FUNCTION get_total_prepays(l_vendor_id IN NUMBER,
                           l_org_id    IN NUMBER
                           ) RETURN NUMBER;
FUNCTION get_available_prepays(l_vendor_id IN NUMBER,
                               l_org_id    IN NUMBER
                               ) RETURN NUMBER;
FUNCTION get_encumbered_flag(l_invoice_id IN NUMBER) RETURN VARCHAR2;
FUNCTION get_gl_date(l_invoice_date IN date,
                     l_receipt_date IN date default null) RETURN DATE;
FUNCTION get_period_name(l_invoice_date IN date,
                         l_receipt_date IN date default null,
                         l_org_id IN NUMBER DEFAULT
                         MO_GLOBAL.GET_CURRENT_ORG_ID
                         ) RETURN VARCHAR2;
FUNCTION get_similar_drcr_memo(
         P_vendor_id IN NUMBER,
         P_vendor_site_id IN NUMBER,
         P_invoice_amount IN NUMBER,
         P_invoice_type_lookup_code IN VARCHAR2,
         P_invoice_currency_code IN VARCHAR2,
         P_calling_sequence  IN VARCHAR2) RETURN varchar2;

PROCEDURE get_gl_date_and_period(
         P_Date             IN            DATE,
         P_Receipt_Date     IN            DATE DEFAULT NULL,
         P_Period_Name         OUT NOCOPY VARCHAR2,
         P_GL_Date             OUT NOCOPY DATE,
         P_Batch_GL_Date    IN            DATE DEFAULT NULL,
         P_Org_Id           IN            NUMBER DEFAULT
                                           MO_GLOBAL.GET_CURRENT_ORG_ID);
FUNCTION eft_bank_details_exist (
         P_vendor_site_id   IN            NUMBER,
         P_calling_sequence IN            VARCHAR2) RETURN BOOLEAN;
FUNCTION eft_bank_curr_details_exist (
         P_vendor_site_id    IN NUMBER,
         P_currency_code     IN VARCHAR2,
         P_calling_sequence  IN VARCHAR2) RETURN boolean;
FUNCTION selected_for_payment_flag (P_invoice_id IN NUMBER) RETURN VARCHAR2;
FUNCTION get_unposted_void_payment (P_invoice_id IN NUMBER)
         RETURN VARCHAR2;
FUNCTION get_discount_pay_dists_flag (P_invoice_id IN NUMBER)
         RETURN VARCHAR2;
FUNCTION get_prepayments_applied_flag (P_invoice_id IN NUMBER)
         RETURN VARCHAR2;
FUNCTION get_payments_exist_flag (P_invoice_id IN NUMBER)
         RETURN VARCHAR2;
FUNCTION get_prepay_amount_applied (P_invoice_id IN NUMBER)
         RETURN NUMBER;
FUNCTION get_packet_id (P_invoice_id IN NUMBER)
         RETURN NUMBER;

PROCEDURE create_holds (
          X_invoice_id           IN            NUMBER,
          X_event                IN            VARCHAR2 DEFAULT 'UPDATE',
          X_update_base          IN            VARCHAR2 DEFAULT 'N',
          X_vendor_changed_flag  IN            VARCHAR2 DEFAULT 'N',
          X_calling_sequence     IN            VARCHAR2);

PROCEDURE insert_children (
          X_invoice_id            IN            NUMBER,
          X_Payment_Priority      IN            NUMBER,
          X_Hold_count            IN OUT NOCOPY NUMBER,
          X_Line_count            IN OUT NOCOPY NUMBER,
          X_Line_Total            IN OUT NOCOPY NUMBER,
          X_calling_sequence      IN            VARCHAR2,
          X_Sched_Hold_count      IN OUT NOCOPY NUMBER);  -- bug 5334577

PROCEDURE invoice_pre_update  (
          X_invoice_id                  IN            NUMBER,
          X_invoice_amount              IN            NUMBER,
          X_payment_status_flag         IN OUT NOCOPY VARCHAR2,
          X_invoice_type_lookup_code    IN            VARCHAR2,
          X_last_updated_by             IN            NUMBER,
          X_accts_pay_ccid              IN            NUMBER,
          X_terms_id                    IN            NUMBER,
          X_terms_date                  IN            DATE,
          X_discount_amount             IN            NUMBER,
          X_exchange_rate_type          IN            VARCHAR2,
          X_exchange_date               IN            DATE,
          X_exchange_rate               IN            NUMBER,
          X_vendor_id                   IN            NUMBER,
          X_payment_method_code         IN            VARCHAR2,
          X_message1                    IN OUT NOCOPY VARCHAR2,
          X_message2                    IN OUT NOCOPY VARCHAR2,
          X_reset_match_status          IN OUT NOCOPY VARCHAR2,
          X_vendor_changed_flag         IN OUT NOCOPY VARCHAR2,
          X_recalc_pay_sched            IN OUT NOCOPY VARCHAR2,
          X_liability_adjusted_flag     IN OUT NOCOPY VARCHAR2,
	  X_external_bank_account_id    IN	      NUMBER,	--bug 7714053
	  X_payment_currency_code       IN	      VARCHAR2, --Bug9294551
          X_calling_sequence            IN            VARCHAR2,
          X_revalidate_ps               IN OUT NOCOPY VARCHAR2);

PROCEDURE invoice_post_update (
          X_invoice_id                  IN            NUMBER,
          X_payment_priority            IN            NUMBER,
          X_recalc_pay_sched            IN OUT NOCOPY VARCHAR2,
          X_Hold_count                  IN OUT NOCOPY NUMBER,
          X_update_base                 IN            VARCHAR2,
          X_vendor_changed_flag         IN            VARCHAR2,
          X_calling_sequence            IN            VARCHAR2,
          X_Sched_Hold_count            IN OUT NOCOPY NUMBER); -- bug 5334577

PROCEDURE Select_Summary(
          X_Batch_ID                    IN            NUMBER,
          X_Total                       IN OUT NOCOPY NUMBER,
          X_Total_Rtot_DB               IN OUT NOCOPY NUMBER,
          X_Calling_Sequence            IN            VARCHAR2);

--Invoice Lines: Distributions
PROCEDURE post_forms_commit(
          X_invoice_id                  IN            NUMBER,
          X_type_1099                   IN            VARCHAR2,
          X_income_tax_region           IN            VARCHAR2,
          X_vendor_changed_flag         IN OUT NOCOPY VARCHAR2,
          X_update_base                 IN OUT NOCOPY VARCHAR2,
          X_reset_match_status          IN OUT NOCOPY VARCHAR2,
          X_update_occurred             IN OUT NOCOPY VARCHAR2,
          X_approval_status_lookup_code IN OUT NOCOPY VARCHAR2,
          X_holds_count                 IN OUT NOCOPY NUMBER,
          X_posting_flag                IN OUT NOCOPY VARCHAR2,
          X_amount_paid                 IN OUT NOCOPY NUMBER,
          X_highest_line_num            IN OUT NOCOPY NUMBER,
          X_line_total                  IN OUT NOCOPY NUMBER,
          X_actual_invoice_count        IN OUT NOCOPY NUMBER,
          X_actual_invoice_total        IN OUT NOCOPY NUMBER,
          X_calling_sequence            IN            VARCHAR2,
          X_sched_holds_count           IN OUT NOCOPY NUMBER);  --bug 5334577


/*==========================================================================*/
/*                                                                          */
/* This RETURNs the max line NUMBER given an invoice.                       */
/*                                                                          */
/*==========================================================================*/

FUNCTION Get_Max_Line_Number(
         X_invoice_id          IN         NUMBER) RETURN NUMBER;

/*==========================================================================*/
/*                                                                          */
/* This FUNCTION RETURNs the expenditure item date for a project related    */
/* invoice, line or distribution based on the Projects profile: 'PA: Default*/
/* Expenditure Item Date for AP Invoices'.  This FUNCTION should not be     */
/* invoked unless the invoice/line or distribution is project related.      */
/* This function's parameters work as follows:                              */
/* X_invoice_id:  Always required.                                          */
/* X_invoice_date:Invoice Date.                                             */
/* X_GL_Date:     Accounting Date                                           */
/* X_po_dist_id:  Dist ID of PO distribution IF such information available  */
/*                at line or distribution level.                            */
/* X_rcv_trx_id:  Receipt Transaction ID for Receipt IF such information    */
/*                is available at the line or distribution level.           */
/* X_error_found: Out parameter RETURNing Y IF an error was found.          */
/*                                                                          */
/*==========================================================================*/

FUNCTION Get_Expenditure_Item_Date(
         X_invoice_id          IN         NUMBER,
         X_invoice_date        IN         DATE,
         X_GL_date             IN         DATE,
         X_po_dist_id          IN         NUMBER DEFAULT NULL,
         X_rcv_trx_id          IN         NUMBER DEFAULT NULL,
         X_error_found         OUT NOCOPY VARCHAR2) RETURN DATE;

--bug4299234
FUNCTION Get_WFapproval_Status(
                           P_invoice_id IN NUMBER,
                           P_org_id     IN NUMBER) RETURN VARCHAR2;


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
                                 p_payment_reason_comments  out nocopy varchar2,  --4874297
                                 p_application_id           in number default 200 -- 5115632
                                 );

-- Bug 5652886
TYPE  iby_error_rec_type is RECORD
  (error_message        IBY_TRANSACTION_ERRORS_GT.error_message%TYPE,
   transaction_id       IBY_TRANSACTION_ERRORS_GT.transaction_id%TYPE);

TYPE iby_error_tab_type is TABLE OF iby_error_rec_type
               index by BINARY_INTEGER;

procedure validate_docs_payable(p_invoice_id  in number,
                                p_payment_num in number default null,
                                p_hold_flag   out nocopy varchar2);

/*==============================================================*/
/*                                                              */
/* This returns the sum of invoices lines amount if prepayment  */
/* included on invoice else returns null.                       */
/* Added for bug8572079                                         */
/*==============================================================*/
FUNCTION Get_Line_Total_Incl_Prepay(P_invoice_id IN NUMBER)
RETURN NUMBER;



/*==============================================================*/
/* This returns the expected value of force_revalidation_flag   */
/* for a historical and paid invoice                            */
/* Added for bug11934187                                        */
/*==============================================================*/
PROCEDURE Get_Force_Revalidation_Flag(P_invoice_id IN NUMBER,
     P_event IN VARCHAR2,
     P_force_revalidation_flag IN OUT NOCOPY VARCHAR2);


END AP_INVOICES_PKG;
/
