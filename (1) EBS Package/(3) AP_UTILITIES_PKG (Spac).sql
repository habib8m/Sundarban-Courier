CREATE OR REPLACE PACKAGE APPS.AP_UTILITIES_PKG AUTHID CURRENT_USER AS
/* $Header: aputilss.pls 120.28.12020000.6 2015/03/25 07:45:34 sbonala ship $ */
/*#
 * This Package provides different APIs for various operations in
 * Invoices module.
 * @rep:scope public
 * @rep:product AP
 * @rep:lifecycle active
 * @rep:displayname  Utility Package
 * @rep:category BUSINESS_ENTITY AP_INVOICE
 */

type number_table_type is table of NUMBER index by binary_integer;
                                                                         --

/*Bug 7172942 Natural Segment Caching */

TYPE g_natural_acct_seg_rec IS RECORD (natural_acct_seg  GL_CODE_COMBINATIONS.SEGMENT1%TYPE);

TYPE g_natural_acct_seg_tab IS TABLE OF g_natural_acct_seg_rec INDEX BY VARCHAR2(100);

g_natural_acct_seg_t  g_natural_acct_seg_tab;


/* Bug 5572876. Period Name Caching */
TYPE g_curr_period_name_rec IS RECORD (period_name   gl_period_statuses.period_name%TYPE);

TYPE g_curr_period_name_tab IS TABLE OF g_curr_period_name_rec INDEX BY VARCHAR2(30);

g_curr_period_name_t     g_curr_period_name_tab;

TYPE g_open_period_name_rec IS RECORD (period_name   gl_period_statuses.period_name%TYPE,
                                       start_date     date);

TYPE g_open_period_name_tab IS TABLE OF g_open_period_name_rec INDEX BY VARCHAR2(30);

g_open_period_name_t     g_open_period_name_tab;

/* Bug 5572876. Asset Book Caching */
TYPE g_asset_book_code_rec IS RECORD (asset_book_code  fa_book_controls.book_type_code%TYPE);

TYPE g_asset_book_code_tab IS TABLE OF g_asset_book_code_rec INDEX BY BINARY_INTEGER;

g_asset_book_code_t      g_asset_book_code_tab;

/* Bug 5572876. Curreny Related data Caching */
TYPE g_fnd_currency_rec IS RECORD
  (currency_code           FND_CURRENCIES.currency_code%TYPE,
   minimum_accountable_unit FND_CURRENCIES.minimum_accountable_unit%TYPE,
   precision               FND_CURRENCIES.precision%TYPE);

TYPE g_fnd_currency_tab IS TABLE OF g_fnd_currency_rec INDEX BY VARCHAR2(15);

g_fnd_currency_code_t    g_fnd_currency_tab;

/* Bug 8713737 Added r_invoice_attribute_rec for passing attribute columns
   to PA APIs */

TYPE r_invoice_attribute_rec IS RECORD (
    attribute_category       ap_invoices_all.attribute_category%TYPE,
    attribute1               ap_invoices_all.attribute1%TYPE,
    attribute2               ap_invoices_all.attribute2%TYPE,
    attribute3               ap_invoices_all.attribute3%TYPE,
    attribute4               ap_invoices_all.attribute4%TYPE,
    attribute5               ap_invoices_all.attribute5%TYPE,
    attribute6               ap_invoices_all.attribute6%TYPE,
    attribute7               ap_invoices_all.attribute7%TYPE,
    attribute8               ap_invoices_all.attribute8%TYPE,
    attribute9               ap_invoices_all.attribute9%TYPE,
    attribute10              ap_invoices_all.attribute10%TYPE,
    attribute11              ap_invoices_all.attribute11%TYPE,
    attribute12              ap_invoices_all.attribute12%TYPE,
    attribute13              ap_invoices_all.attribute13%TYPE,
    attribute14              ap_invoices_all.attribute14%TYPE,
    attribute15              ap_invoices_all.attribute15%TYPE,
    line_attribute_category  ap_invoice_lines_all.attribute_category%TYPE,
    line_attribute1          ap_invoice_lines_all.attribute1%TYPE,
    line_attribute2          ap_invoice_lines_all.attribute2%TYPE,
    line_attribute3          ap_invoice_lines_all.attribute3%TYPE,
    line_attribute4          ap_invoice_lines_all.attribute4%TYPE,
    line_attribute5          ap_invoice_lines_all.attribute5%TYPE,
    line_attribute6          ap_invoice_lines_all.attribute6%TYPE,
    line_attribute7          ap_invoice_lines_all.attribute7%TYPE,
    line_attribute8          ap_invoice_lines_all.attribute8%TYPE,
    line_attribute9          ap_invoice_lines_all.attribute9%TYPE,
    line_attribute10         ap_invoice_lines_all.attribute10%TYPE,
    line_attribute11         ap_invoice_lines_all.attribute11%TYPE,
    line_attribute12         ap_invoice_lines_all.attribute12%TYPE,
    line_attribute13         ap_invoice_lines_all.attribute13%TYPE,
    line_attribute14         ap_invoice_lines_all.attribute14%TYPE,
    line_attribute15         ap_invoice_lines_all.attribute15%TYPE
);

/*Bug11720134*/
g_org_id  NUMBER DEFAULT mo_global.get_current_org_id;

Function Ledger_Asset_Book (P_ledger_id     IN Number) Return Varchar2;

function Ap_Get_Displayed_Field
                             (LookupType    IN varchar2
                             ,LookupCode    IN varchar2
                             ) return varchar2;
                                                                         --
function Ap_Round_Currency
                         (P_Amount         IN number
                         ,P_Currency_Code  IN varchar2
                         ) return number;
--pragma restrict_references(Ap_Round_Currency, WNDS, WNPS, RNPS);

function Ap_Round_Tax
		    (P_Amount           IN number
                    ,P_Currency_Code    IN varchar2
                    ,P_Round_Rule       IN varchar2
                    ,P_Calling_Sequence IN varchar2
                    ) return number;
function Ap_Round_Non_Rec_Tax
                   (P_Amount            IN number
                   ,P_Currency_Code     IN varchar2
                   ,P_Round_Rule        IN varchar2
                   ,P_Calling_Sequence  IN varchar2
                   ) return number;

function Ap_Round_Precision
                         (P_Amount         IN number
                         ,P_Min_unit 	   IN number
			 ,P_Precision	   IN number
                         ) return number;
FUNCTION net_invoice_amount(p_invoice_id IN NUMBER) RETURN NUMBER;  -- Added by Bug:2022200

--PRAGMA RESTRICT_REFERENCES (Ap_Round_Precision, WNDS, WNPS, RNPS);

-- MOAC.  Added org_id parameter
function get_current_gl_date (P_Date IN date,
                              P_Org_Id IN number default
                                 mo_global.get_current_org_id) return varchar2;

function get_gl_period_name (P_Date IN date,
                             P_Org_Id IN number default
                                 mo_global.get_current_org_id) return varchar2;


-- MOAC.  Added org_id parameter
procedure get_open_gl_date
                         (P_Date              IN date
                         ,P_Period_Name       OUT NOCOPY varchar2
                         ,P_GL_Date           OUT NOCOPY date
                         ,P_Org_Id            IN number DEFAULT
                            mo_global.get_current_org_id);

procedure get_only_open_gl_date
                         (P_Date              IN date
                         ,P_Period_Name       OUT NOCOPY varchar2
                         ,P_GL_Date           OUT NOCOPY date
                         ,P_Org_Id            IN number DEFAULT
                              mo_global.get_current_org_id);
--    PRAGMA RESTRICT_REFERENCES(get_only_open_gl_date, WNDS);
--    PRAGMA RESTRICT_REFERENCES(get_open_gl_date, WNDS, RNPS, WNPS);
--    PRAGMA RESTRICT_REFERENCES(get_current_gl_date, WNDS, RNPS, WNPS);


FUNCTION get_exchange_rate(
                 p_from_currency_code IN varchar2,
                 p_to_currency_code   IN varchar2,
                 p_exchange_rate_type IN varchar2,
                 p_exchange_date      IN date,
		 p_calling_sequence   IN varchar2) RETURN NUMBER;
--pragma restrict_references(Get_exchange_rate, WNDS, WNPS, RNPS);

PROCEDURE Set_Profile(p_profile_option   IN vARCHAR2,
		      p_profile_value    IN VARCHAR2);

PROCEDURE AP_Get_Message(p_err_txt      OUT NOCOPY VARCHAR2);

--MO Access Control
FUNCTION Get_Window_Title RETURN VARCHAR2;

FUNCTION Get_Window_Session_Title RETURN VARCHAR2;
--pragma restrict_references(Get_Window_Session_Title, WNDS);

FUNCTION overlay_segments (
        p_balancing_segment             IN      VARCHAR2,
        p_cost_center_segment           IN      VARCHAR2,
        p_account_segment               IN      VARCHAR2,
        p_concatenated_segments         IN      VARCHAR2,
        p_ccid                          IN OUT NOCOPY  NUMBER,
        p_set_of_books_id               IN      NUMBER,
        p_overlay_mode                  IN      VARCHAR2,
        p_unbuilt_flex                  OUT NOCOPY     VARCHAR2,
        p_reason_unbuilt_flex           OUT NOCOPY     VARCHAR2,
	p_resp_appl_id			IN	NUMBER,
	p_resp_id			IN	NUMBER,
	p_user_id			IN	NUMBER,
        p_calling_sequence              IN      VARCHAR2,
        p_ccid_to_segs                  IN      VARCHAR2 Default Null,
        p_accounting_date               IN DATE DEFAULT SYSDATE) --7531219
RETURN BOOLEAN;

--following function added for BUG 1909374
FUNCTION overlay_segments_by_gldate (
        p_balancing_segment             IN      VARCHAR2,
        p_cost_center_segment           IN      VARCHAR2,
        p_account_segment               IN      VARCHAR2,
        p_concatenated_segments         IN      VARCHAR2,
        p_ccid                          IN OUT NOCOPY  NUMBER,
        p_accounting_date               IN      DATE,
        p_set_of_books_id               IN      NUMBER,
        p_overlay_mode                  IN      VARCHAR2,
        p_unbuilt_flex                  OUT NOCOPY     VARCHAR2,
        p_reason_unbuilt_flex           OUT NOCOPY     VARCHAR2,
	p_resp_appl_id			IN	NUMBER,
	p_resp_id			IN	NUMBER,
	p_user_id			IN	NUMBER,
        p_calling_sequence              IN      VARCHAR2,
        p_ccid_to_segs                  IN      VARCHAR2 Default Null)
RETURN BOOLEAN;


FUNCTION check_partial(
        p_concatenated_segments         IN      VARCHAR2,
        p_partial_segments_flag         OUT NOCOPY     VARCHAR2,
        p_set_of_books_id               IN      NUMBER,
        p_error_message                 OUT NOCOPY     VARCHAR2,
        p_calling_sequence              IN      VARCHAR2)
RETURN BOOLEAN;

FUNCTION is_ccid_valid (
        p_ccid				IN    	NUMBER,
	p_chart_of_accounts_id		IN	NUMBER,
	p_date				IN	DATE,
	p_calling_sequence		IN	VARCHAR2)
RETURN BOOLEAN;

--MO Access Control: Added the p_org_id parameter.
FUNCTION get_inventory_org(p_org_id number default mo_global.get_current_org_id) RETURN NUMBER;


PROCEDURE mc_flag_enabled ( p_sob_id            IN     NUMBER,
                            p_appl_id           IN     NUMBER,
                            p_org_id            IN     NUMBER,
                            p_fa_book_code      IN     VARCHAR2,
                            p_base_currency     IN     VARCHAR2,
                            p_mc_flag_enabled   OUT NOCOPY    VARCHAR2,
                            p_calling_sequence  IN     VARCHAR2);

function AP_Get_Sob_Order_Col(
                           P_Primary_SOB_ID     IN   number
                          ,P_Secondary_SOB_ID   IN   number
                          ,P_SOB_ID             IN   number
                          ,P_ORG_ID             IN   number
                          ,P_Calling_Sequence   IN   varchar2
                          ) return number;

function get_charge_account(
                           p_ccid	                IN  number
                         , p_chart_of_accounts_id	IN  number
                         , p_calling_sequence		IN  varchar2
                          ) return varchar2;

function get_invoice_status(p_invoice_id       IN NUMBER,
                            p_calling_sequence IN VARCHAR2
                           ) return varchar2;

PROCEDURE build_offset_account(P_base_ccid             IN     NUMBER
                              ,P_overlay_ccid          IN     NUMBER
                              ,P_accounting_date       IN     DATE
                              ,P_result_ccid           OUT NOCOPY    NUMBER
                              ,P_Reason_Unbuilt_Flex   OUT NOCOPY    VARCHAR2
                              ,P_calling_sequence      IN     VARCHAR2);

function get_auto_offsets_segments(
                                  P_base_ccid        IN     NUMBER
                                  )return varchar2;

FUNCTION get_auto_offsets_segments
           (P_base_ccid IN NUMBER,
            P_flex_qualifier_name   IN       VARCHAR2,
            P_flex_segment_num   IN     NUMBER,
            P_chart_of_accts_id  IN GL_SETS_OF_BOOKS.chart_of_accounts_id%TYPE
        ) return varchar2;

FUNCTION delete_invoice_from_interface(p_invoice_id_table IN number_table_type,
                                       p_invoice_line_id_table IN number_table_type,
                                       p_calling_sequence IN VARCHAR2
                                 ) return boolean;


--Added function for exchange rate calculation project.
FUNCTION calculate_user_xrate(P_invoice_curr         IN     VARCHAR2,
                              P_base_curr            IN     VARCHAR2,
                              P_exchange_date        IN     DATE,
                              P_exchange_rate_type    IN     VARCHAR2
                             ) return VARCHAR2;

FUNCTION get_gl_batch_name(P_batch_id                IN     NUMBER,
                           P_GL_SL_link_id           IN     NUMBER,
                           P_ledger_id               IN     NUMBER) return VARCHAR2;

-- Bug 2249806
-- Code modified by MSWAMINA
-- Added a new stored function for the performance reasons
-- This will get the Lookup code and the lookup type
-- as the input arguments and will return the corresponding
-- Meaning as output.
-- This function is created inorder to avoid the reparsing
-- of these simple/common SQLs in our reports.

FUNCTION FND_Get_Displayed_Field
                             (LookupType    IN VARCHAR2
                             ,LookupCode    IN VARCHAR2
                             ) RETURN VARCHAR2;

-- Bug 2693900.  Forward porting Bug 2610252.
-- Bug 5584997.  Added the P_org_id
function get_reversal_gl_date (P_Date IN date, P_Org_Id IN Number) return date;

-- Bug 5584997.  Added the P_org_id
function get_reversal_period (P_Date IN date, P_Org_Id IN Number) return Varchar2;

/* =======================================================================*/
/* New Function pa_flexbuild was created for in the scope of the Invoice  */
/* Lines Project - Stage 1                                                */
/* =======================================================================*/

FUNCTION pa_flexbuild(
   p_vendor_id                  IN            NUMBER,
   p_employee_id                IN            NUMBER,
   p_set_of_books_id            IN            NUMBER,
   p_chart_of_accounts_id       IN            NUMBER,
   p_base_currency_code         IN            VARCHAR2,
   p_Accounting_date            IN            DATE,
   p_award_id                   IN            NUMBER,
   P_project_id                 IN AP_INVOICE_DISTRIBUTIONS.PROJECT_ID%TYPE,
   p_task_id                    IN AP_INVOICE_DISTRIBUTIONS.TASK_ID%TYPE,
   p_expenditure_type           IN
        AP_INVOICE_DISTRIBUTIONS.EXPENDITURE_TYPE%TYPE,
   p_expenditure_org_id         IN
        AP_INVOICE_DISTRIBUTIONS.EXPENDITURE_ORGANIZATION_ID%TYPE,
   p_expenditure_item_date      IN
        AP_INVOICE_DISTRIBUTIONS.EXPENDITURE_ITEM_DATE%TYPE,
   p_invoice_attribute_rec      IN  AP_UTILITIES_PKG.r_invoice_attribute_rec, --bug 8713737
   p_billable_flag              IN            VARCHAR2, --Bug6523162
   p_employee_ccid              IN            NUMBER,   --Bug5003249
   p_web_parameter_id           IN            NUMBER,   --Bug5003249
   p_invoice_type_lookup_code   IN            VARCHAR2, --Bug5003249
   p_default_last_updated_by    IN            NUMBER,
   p_default_last_update_login  IN            NUMBER,
   p_pa_default_dist_ccid          OUT NOCOPY NUMBER,
   p_pa_concatenated_segments      OUT NOCOPY VARCHAR2,
   p_debug_Info                    OUT  NOCOPY VARCHAR2,
   p_debug_Context                 OUT  NOCOPY VARCHAR2,
   p_calling_sequence          IN            VARCHAR2,
   p_default_dist_ccid         IN  AP_INVOICE_LINES.DEFAULT_DIST_CCID%TYPE --bug 5386396
   ) RETURN BOOLEAN;


PROCEDURE Get_Invoice_LE (
     p_vendor_site_id                IN            NUMBER,
     p_inv_liab_ccid                 IN            NUMBER,
     p_org_id                        IN            NUMBER,
     p_le_id                         OUT  NOCOPY NUMBER);

FUNCTION Get_Check_LE (
     p_bank_acct_use_id              IN            NUMBER) RETURN NUMBER;

PROCEDURE getInvoiceLEInfo (
     p_vendor_site_id                IN            NUMBER,
     p_inv_liab_ccid                 IN            NUMBER,
     p_org_id                        IN            NUMBER,
     p_le_id                         OUT NOCOPY    NUMBER,
     p_le_name                       OUT NOCOPY    VARCHAR2,
     p_le_registration_num           OUT NOCOPY    VARCHAR2,
     p_le_address1                   OUT NOCOPY    VARCHAR2,
     p_le_city                       OUT NOCOPY    VARCHAR2,
     p_le_postal_code                OUT NOCOPY    VARCHAR2,
     p_le_country                    OUT NOCOPY    VARCHAR2);

PROCEDURE Delete_AP_Profiles
     (P_Profile_Option_Name          IN            VARCHAR2);

FUNCTION PERIOD_STATUS (p_gl_date IN DATE) -- 3881457
   RETURN VARCHAR2;

/*This function will take in a clob and write it to the concurrent manager file.
  It can be used in conjunction with dbms_xmlgen to generate xml output for a
  concurrent request.*/
PROCEDURE clob_to_file
        (p_xml_clob IN CLOB);

FUNCTION pa_period_status(
        p_gl_date      IN      DATE,
        p_org_id       IN      number default
           mo_global.get_current_org_id)  RETURN varchar2;

FUNCTION Get_PO_Reversed_Encumb_Amount(
              P_Po_Distribution_Id   IN            NUMBER,
              P_Start_gl_Date        IN            DATE,
              P_End_gl_Date          IN            DATE,
              P_Calling_Sequence     IN            VARCHAR2 DEFAULT NULL)

 RETURN NUMBER;


--Function get_ccr_status, added for the R12 FSIO gap--
--Bug6053476
FUNCTION get_ccr_status(P_object_id              IN     NUMBER,
                        P_object_type            IN     VARCHAR2
                        ) return VARCHAR2;

--Function get_gl_natural_account added for Bug 6980939
FUNCTION get_gl_natural_account(
      p_coa_id IN NUMBER,
      p_ccid IN NUMBER,
      P_calling_sequence IN VARCHAR2 DEFAULT NULL)
RETURN VARCHAR2;

-- bug 7531219
-- Function to validate balancing segment to the ledger
FUNCTION is_balancing_segment_valid (
        p_set_of_books_id               IN      gl_sets_of_books.set_of_books_id%type,
        p_balancing_segment_value	IN    	gl_ledger_segment_values.segment_value%type,
	p_date				IN	DATE,
	p_calling_sequence		IN	VARCHAR2)
RETURN BOOLEAN;

-- Added for bug 8408345.

PROCEDURE get_gl_date_and_period_1(
         P_Date             IN            DATE,
         P_Receipt_Date     IN            DATE DEFAULT NULL,
         P_Period_Name         OUT NOCOPY VARCHAR2,
         P_GL_Date             OUT NOCOPY DATE,
         P_Batch_GL_Date    IN            DATE DEFAULT NULL,
         P_Org_Id           IN            NUMBER DEFAULT
                                           MO_GLOBAL.GET_CURRENT_ORG_ID);

function get_current_gl_date_no_cache (P_Date IN date,
                              P_Org_Id IN number default
                                 mo_global.get_current_org_id) return varchar2;

procedure get_open_gl_date_no_cache
                         (P_Date              IN date
                         ,P_Period_Name       OUT NOCOPY varchar2
                         ,P_GL_Date           OUT NOCOPY date
                         ,P_Org_Id            IN number DEFAULT
                            mo_global.get_current_org_id);
-- End bug 8408345.

--Start 8691645

  FUNCTION get_ccr_reg_status(p_vendor_site_id IN
                               AP_INVOICES.VENDOR_SITE_ID%TYPE)
                         return VARCHAR2;

--End 8691645


 --Begin ER#19675818. Hold Event Procedure, which get called  when there is hold placed/released for BPM

procedure Raise_Hold_Event(P_INVOICE_ID          IN NUMBER,
                           P_LINE_LOCATION_ID    IN NUMBER,
                           P_HOLD_LOOKUP_CODE    IN VARCHAR2,
		           P_HOLD_REASON         IN VARCHAR2,
		           P_RELEASE_LOOKUP_CODE IN VARCHAR2,
		           P_RELEASE_REASON      IN VARCHAR2,
		           P_STATUS_FLAG         IN VARCHAR2,
		           P_HOLD_ID             IN NUMBER,
			   P_CALLING_SEQUENCE    IN VARCHAR2);

/*#
 * This Api to derive Payment terms details based on supplier site details.
 * This is used by BPM to estimate payment terms when invoice data is
 * received from third party into interface tables.
 * @param P_ORG_ID Organization Identifier Mandatory
 * @param P_VENDOR_ID Supplier Identifier Mandatory
 * @param P_VENDOR_SITE_ID Supplier Site Identifier Mandatory
 * @param P_INVOICE_DATE  Invoice Date
 * @param P_INVOICE_AMOUNT Invoice Amount
 * @param P_INVOICE_TYPE_LOOKUP_CODE Invoice Type
 *        If invoice is assoicated with PO then any one of below PO
 *        details is must to get correct terms id value
 * @param P_PO_HEADER_ID PO Header identifier
 * @param P_PO_LINE_LOCATION_ID PO shipment Identifier
 * @param P_PO_DISTRIBUTION_ID PO distribution identifier
 * @param P_GOODS_RECEIVED_DATE Invoice goods received date
 * @param P_INVOICE_RECEIVED_DATE Invoice received date
 * @param P_TERMS_ID Payment Terms Identifier
 * @param P_TERMS_NAME Payment Terms Name
 * @param P_TERMS_DATE Payment Terms Date
 * @param P_ERROR_CODE Error code
 * @param P_CALLING_SEQUENCE Calling Sequence
 * @return get payment terms info
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Get Payment Terms
 * @rep:category BUSINESS_ENTITY AP_INVOICE
 */

FUNCTION get_payment_terms (
    P_ORG_ID		         IN    NUMBER,
    P_VENDOR_ID                  IN    NUMBER,
    P_VENDOR_SITE_ID		 IN    NUMBER,
    P_INVOICE_DATE               IN    DATE      DEFAULT NULL,
    P_INVOICE_AMOUNT		 IN    NUMBER    DEFAULT NULL,
    P_INVOICE_TYPE_LOOKUP_CODE   IN    VARCHAR2  DEFAULT NULL,
    P_PO_HEADER_ID               IN    NUMBER    DEFAULT NULL,
    P_PO_LINE_LOCATION_ID        IN    NUMBER    DEFAULT NULL,
    P_PO_DISTRIBUTION_ID         IN    NUMBER    DEFAULT NULL,
    P_GOODS_RECEIVED_DATE        IN    DATE      DEFAULT NULL,
    P_INVOICE_RECEIVED_DATE      IN    DATE      DEFAULT NULL,
    P_TERMS_ID                   OUT   NOCOPY  NUMBER,
    P_TERMS_NAME                 OUT   NOCOPY  VARCHAR2,
    P_TERMS_DATE                 OUT   NOCOPY  DATE,
    P_ERROR_CODE                 OUT   NOCOPY  VARCHAR2,
    P_CALLING_SEQUENCE           IN    VARCHAR2) RETURN BOOLEAN;


TYPE schds_rec IS RECORD(
          payment_num                 ap_payment_schedules.payment_num%TYPE,
          due_date                    ap_payment_schedules.due_date%TYPE,
          discount_date               ap_payment_schedules.discount_date%TYPE,
          discount_amount_available   ap_payment_schedules.discount_amount_available%TYPE,
          second_discount_date        ap_payment_schedules.second_discount_date%TYPE,
          second_disc_Amt_available   ap_payment_schedules.second_disc_Amt_available%TYPE,
	  third_discount_date         ap_payment_schedules.third_discount_date%TYPE,
	  third_disc_Amt_available    ap_payment_schedules.third_disc_Amt_available%TYPE);


TYPE schds_table IS TABLE OF schds_rec INDEX BY BINARY_INTEGER;

--

/*#
 * This Api to derive Due and Discount dates.
 * This is used by BPM to estimate discount amounts for invoices
 * received from third party into interface tables.
 * @param P_ORG_ID Organization Identifier Mandatory
 * @param P_VENDOR_ID Supplier Identifier Mandatory
 * @param P_VENDOR_SITE_ID Supplier Site Identifier Mandatory
 * @param P_INVOICE_DATE  Invoice Date
 * @param P_INVOICE_AMOUNT Invoice Amount
 * @param P_INV_CURR Invoice Currency
 * @param P_INVOICE_TYPE_LOOKUP_CODE Invoice Type
 *        If invoice is assoicated with PO then any one of below PO
 *        details is must to get correct terms id value
 * @param P_PO_HEADER_ID PO Header identifier
 * @param P_PO_LINE_LOCATION_ID PO shipment Identifier
 * @param P_PO_DISTRIBUTION_ID PO distribution identifier
 * @param P_GOODS_RECEIVED_DATE Invoice goods received date
 * @param P_INVOICE_RECEIVED_DATE Invoice received date
 * @param P_TERMS_ID Payment Terms Identifier
 * @param P_TERMS_NAME Payment Terms Name
 * @param P_TERMS_DATE Payment Terms Date
 * @param P_AMT_APPL_TO_DISC Total invoice amount applicable for discount
 * @param P_PAY_CURR Payment Currency
 * @param P_PAY_CROSS_RATE Invoice and Payment currency exchange rate
 * @param P_SCHDS_REC_LIST Payment schedules record.
 * @param P_ERROR_CODE Error code
 * @param P_CALLING_SEQUENCE Calling Sequence
 * @return get discount and due date
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Get Payment Terms
 * @rep:category BUSINESS_ENTITY AP_INVOICE
 */

FUNCTION GET_DISCOUNT_DUE_DATE(
    P_ORG_ID                     IN  NUMBER,
    P_VENDOR_ID                  IN  NUMBER,
    P_VENDOR_SITE_ID             IN  NUMBER,
    P_INVOICE_DATE               IN  DATE,
    P_INVOICE_AMOUNT		 IN  NUMBER,
    P_INV_CURR                   IN  VARCHAR2,
    P_INVOICE_TYPE_LOOKUP_CODE   IN  VARCHAR2 DEFAULT NULL,
    P_PO_HEADER_ID               IN  NUMBER   DEFAULT NULL,
    P_PO_LINE_LOCATION_ID        IN  NUMBER   DEFAULT NULL,
    P_PO_DISTRIBUTION_ID         IN  NUMBER   DEFAULT NULL,
    P_TERMS_ID                   IN  NUMBER   DEFAULT NULL,
    P_TERMS_NAME                 IN  VARCHAR2 DEFAULT NULL,
    P_TERMS_DATE                 IN  DATE     DEFAULT NULL,
    P_GOODS_RECEIVED_DATE        IN  DATE     DEFAULT NULL,
    P_INVOICE_RECEIVED_DATE      IN  DATE     DEFAULT NULL,
    P_AMT_APPL_TO_DISC           IN   NUMBER   DEFAULT NULL,
    P_PAY_CURR                   IN   VARCHAR2 DEFAULT NULL,
    P_PAY_CROSS_RATE             IN   NUMBER   DEFAULT NULL,
    P_SCHDS_REC_LIST             OUT NOCOPY ap_utilities_pkg.schds_table,
    P_ERROR_CODE                 OUT NOCOPY VARCHAR2,
    P_CALLING_SEQUENCE           IN  VARCHAR2) RETURN BOOLEAN;

 --End ER#19675818

END AP_UTILITIES_PKG;
/
