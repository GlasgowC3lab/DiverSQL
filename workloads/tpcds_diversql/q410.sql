WITH sales_base AS (
   SELECT
       cc.cc_call_center_sk,
       cc.cc_division,
       cc.cc_class,
       cp.cp_department,
       cp.cp_type,
       cs.cs_net_paid,
       cs.cs_net_profit,
       cp.cp_description,
       cc.cc_name
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE cc.cc_name LIKE 'A%'
     AND regexp_like(cp.cp_description, '[A-Z]{2}[0-9]{2}')
)
SELECT
    division,
    class,
    department,
    type,
    extracted_code,
    SUM(total_paid) AS total_paid,
    SUM(total_profit) AS total_profit,
    SUM(return_cnt) AS total_returns
FROM (
   SELECT
       sb.cc_division AS division,
       sb.cc_class AS class,
       sb.cp_department AS department,
       sb.cp_type AS type,
       regexp_extract(sb.cp_description, '([A-Z]{2}[0-9]{2})', 1) AS extracted_code,
       sb.cs_net_paid AS total_paid,
       sb.cs_net_profit AS total_profit,
       cr_cnt.cnt AS return_cnt
   FROM sales_base sb
   CROSS JOIN LATERAL (
        SELECT count(*) AS cnt
        FROM catalog_returns cr
        WHERE cr.cr_call_center_sk = sb.cc_call_center_sk
   ) cr_cnt
   WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_call_center_sk = sb.cc_call_center_sk
          AND cr2.cr_fee > 100
   )
) sub
GROUP BY ROLLUP (division, class, department, type, extracted_code)
ORDER BY division, class, department, type, extracted_code
