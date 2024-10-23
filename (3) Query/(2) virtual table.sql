SELECT 
    ocb.org_name,  
    a.description AS company, 
    b.description AS branch, 
    c.description AS department,
    d.description AS account,
    e.description AS exp_category,
    f.description AS product,
    g.description AS intercompany
FROM 
    XX_ORG_COMPANY_BRANCH_V ocb
JOIN 
    AP_INVOICES_ALL i ON ocb.org_id = i.org_id
JOIN 
    AP_INVOICE_LINES_ALL il ON i.invoice_id = il.invoice_id
JOIN 
    AP_INVOICE_DISTRIBUTIONS_ALL id ON il.invoice_id = id.invoice_id
JOIN 
    GL_CODE_COMBINATIONS gcc ON id.dist_code_combination_id = gcc.code_combination_id
JOIN 
    (SELECT flex_value, description FROM fnd_flex_values_vl WHERE flex_value_set_id = 1016491) a 
    ON gcc.segment1 = a.flex_value
JOIN 
    (SELECT flex_value, description FROM fnd_flex_values_vl WHERE flex_value_set_id = 1016492) b 
    ON gcc.segment2 = b.flex_value
JOIN 
    (SELECT flex_value, description FROM fnd_flex_values_vl WHERE flex_value_set_id = 1016493) c 
    ON gcc.segment3 = c.flex_value
JOIN 
    (SELECT flex_value, description FROM fnd_flex_values_vl WHERE flex_value_set_id = 1016494) d 
    ON gcc.segment4 = d.flex_value
JOIN 
    (SELECT flex_value, description FROM fnd_flex_values_vl WHERE flex_value_set_id = 1016495) e 
    ON gcc.segment5 = e.flex_value
JOIN 
    (SELECT flex_value, description FROM fnd_flex_values_vl WHERE flex_value_set_id = 1016496) f 
    ON gcc.segment6 = f.flex_value
JOIN 
    (SELECT flex_value, description FROM fnd_flex_values_vl WHERE flex_value_set_id = 1016497) g 
    ON gcc.segment7 = g.flex_value
WHERE 
    i.doc_sequence_value IN (225021270, 225022501, 225025179);
