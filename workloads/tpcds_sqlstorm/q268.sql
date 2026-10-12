WITH store_agg AS (
  SELECT d.d_year AS year,
         s.s_state AS state,
         SUM(ss.ss_net_profit) AS net_profit,
         SUM(ss.ss_quantity) AS quantity
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year = 1998
    AND i.i_brand = 'Brand#12'
  GROUP BY d.d_year, s.s_state
),
catalog_agg AS (
  SELECT d.d_year AS year,
         cc.cc_state AS state,
         SUM(cs.cs_net_profit) AS net_profit,
         SUM(cs.cs_quantity) AS quantity
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year = 1998
    AND i.i_brand = 'Brand#12'
  GROUP BY d.d_year, cc.cc_state
)
SELECT year,
       state,
       total_net_profit,
       total_quantity,
       total_net_profit / SUM(total_net_profit) OVER () AS profit_pct
FROM (
  SELECT year,
         state,
         SUM(net_profit) AS total_net_profit,
         SUM(quantity) AS total_quantity
  FROM (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM catalog_agg
  ) t
  GROUP BY year, state
) agg
ORDER BY total_net_profit DESC
LIMIT 10
