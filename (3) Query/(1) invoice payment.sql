SELECT s.VENDOR_NAME,
       i.doc_sequence_value voucher_no,
       i.invoice_amount,
       id.amount dist_amount,
       a.description AS company,
       b.description AS branc,
       c.description AS department,
       d.description AS accounts,
       e.description AS exp_category,
       f.description AS product,
       g.description AS inter_com,
	   null as payment_date,
	   null as payment_amount
  FROM AP_SUPPLIERS s,
       AP_INVOICES_ALL i,
       AP_INVOICE_DISTRIBUTIONS_ALL id,
       GL_CODE_COMBINATIONS gcc,
       fnd_flex_values_vl fv,
       (SELECT flex_value, description
          FROM fnd_flex_values_vl
         WHERE flex_value_set_id = 1016491) a,
       (SELECT flex_value, description
          FROM fnd_flex_values_vl
         WHERE flex_value_set_id = 1016492) b,
       (SELECT flex_value, description
          FROM fnd_flex_values_vl
         WHERE flex_value_set_id = 1016493) c,
       (SELECT flex_value, description
          FROM fnd_flex_values_vl
         WHERE flex_value_set_id = 1016494) d,
       (SELECT flex_value, description
          FROM fnd_flex_values_vl
         WHERE flex_value_set_id = 1016495) e,
       (SELECT flex_value, description
          FROM fnd_flex_values_vl
         WHERE flex_value_set_id = 1016496) f,
       (SELECT flex_value, description
          FROM fnd_flex_values_vl
         WHERE flex_value_set_id = 1016497) g
 WHERE     s.vendor_id = i.vendor_id
       AND i.invoice_id = id.invoice_id
       AND id.dist_code_combination_id = gcc.CODE_COMBINATION_ID
       AND i.invoice_amount <> 0
       AND gcc.segment4 = fv.flex_value
       AND gcc.segment1 = a.flex_value
       AND gcc.segment2 = b.flex_value
       AND gcc.segment3 = c.flex_value
       AND gcc.segment4 = d.flex_value
       AND gcc.segment5 = e.flex_value
       AND gcc.segment6 = f.flex_value
       AND gcc.segment7 = g.flex_value
       --AND s.segment1 = 10064
       --AND s.vendor_id = 64
       and I.DOC_SEQUENCE_VALUE = 223645451 -- 219000001 -- 223645451
UNION
SELECT null as VENDOR_NAME,
       null as voucher_no,
	   null as invoice_amount,
	   null as dist_amount,
	   null as company,
	   null as branc,
	   null as department,
	   null as accounts,
	   null as exp_category,
	   null as product,
       null as inter_com,
       ip.accounting_date AS payment_date,
       ip.amount AS payment_amount
  FROM AP_CHECKS_ALL c,
       AP_INVOICE_PAYMENTS_ALL ip,
       AP_INVOICES_ALL i,
       AP_SUPPLIERS s
 WHERE     c.check_id = ip.check_id
       AND ip.invoice_id = i.invoice_id
       AND i.vendor_id = s.vendor_id
       AND i.invoice_amount <> 0
       AND c.status_lookup_code <> 'VOIDED'
       --AND s.segment1 = 10064
       --AND s.vendor_id = 64
       and I.DOC_SEQUENCE_VALUE = 223645451 -- 219000001 -- 223645451