SELECT
    sm.sm_type AS ship_mode_type,
    sm.sm_carrier AS carrier,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ws.ws_net_paid) AS total_web_sales
FROM catalog_sales cs
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_sales ws ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cs.cs_sold_date_sk BETWEEN 2450816 AND 2450852
  AND ws.ws_sold_date_sk BETWEEN 2450816 AND 2450852
  AND sm.sm_type = 'TWO DAY                       '
GROUP BY sm.sm_type, sm.sm_carrier
