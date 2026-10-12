SELECT cp.cp_type,
       COUNT(DISTINCT cp.cp_catalog_page_id) AS page_cnt,
       AVG(cp.cp_catalog_number) AS avg_cat_num,
       s.s_market_desc,
       COUNT(DISTINCT s.s_store_id) AS store_cnt,
       AVG(s.s_floor_space) AS avg_floor_space,
       sm.sm_carrier,
       COUNT(DISTINCT sm.sm_ship_mode_id) AS ship_mode_cnt
FROM catalog_page cp
JOIN store s
  ON cp.cp_catalog_number = s.s_market_id
JOIN ship_mode sm
  ON s.s_store_sk = sm.sm_ship_mode_sk
WHERE cp.cp_type IN ('monthly', 'quarterly')
  AND s.s_state = 'CA'
  AND sm.sm_type = 'Air'
GROUP BY cp.cp_type, s.s_market_desc, sm.sm_carrier
ORDER BY avg_cat_num DESC, store_cnt DESC
LIMIT 50
