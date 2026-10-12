WITH hd_stats AS (
    SELECT AVG(hd_vehicle_count) AS avg_vehicle_cnt
    FROM household_demographics
    WHERE hd_income_band_sk = 4
      AND hd_buy_potential = '1001-5000'
),
store_stats AS (
    SELECT s_market_id,
           COUNT(*) AS store_cnt,
           AVG(s_floor_space) AS avg_floor_space,
           SUM(s_number_employees) AS total_employees,
           AVG(s_tax_percentage) AS avg_store_tax
    FROM store
    WHERE s_rec_end_date IS NULL
      AND s_state = 'CA'
    GROUP BY s_market_id
),
web_stats AS (
    SELECT web_mkt_id,
           COUNT(*) AS website_cnt,
           AVG(web_tax_percentage) AS avg_web_tax,
           AVG(web_gmt_offset) AS avg_gmt_offset
    FROM web_site
    WHERE web_rec_end_date IS NULL
      AND web_country = 'United States'
    GROUP BY web_mkt_id
)
SELECT ss.s_market_id,
       ss.store_cnt,
       ss.avg_floor_space,
       ss.total_employees,
       ss.avg_store_tax,
       ws.website_cnt,
       ws.avg_web_tax,
       ws.avg_gmt_offset,
       hd.avg_vehicle_cnt,
       ROUND(ss.avg_floor_space * ws.avg_web_tax * hd.avg_vehicle_cnt, 2) AS composite_metric
FROM store_stats ss
JOIN web_stats ws
  ON ss.s_market_id = ws.web_mkt_id
CROSS JOIN hd_stats hd
WHERE ss.store_cnt > 5
ORDER BY composite_metric DESC
LIMIT 10
