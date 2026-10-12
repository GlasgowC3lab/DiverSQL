SELECT cc_call_center_id,
       cc_name,
       cc_city,
       cc_state,
       cc_tax_percentage
FROM tpcds.call_center
WHERE cc_state = 'CA'
  AND cc_tax_percentage > 0.05
ORDER BY cc_tax_percentage DESC
LIMIT 10
