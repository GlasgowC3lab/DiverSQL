SELECT
    sm.sm_carrier,
    COUNT(*) AS order_count,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_paid_inc_ship_tax
FROM tpcds.catalog_sales cs
JOIN tpcds.ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_type = 'EXPRESS'
  AND cs.cs_net_paid_inc_ship_tax > 1000
GROUP BY sm.sm_carrier
ORDER BY total_paid_inc_ship_tax DESC
LIMIT 5
