WITH sales_union AS (
  SELECT
    ss.ss_sold_date_sk AS date_sk,
    ss.ss_store_sk AS store_sk,
    NULL AS call_center_sk,
    NULL AS web_page_sk,
    NULL AS web_site_sk,
    ss.ss_item_sk AS item_sk,
    ss.ss_promo_sk AS promo_sk,
    ss.ss_quantity AS quantity,
    ss.ss_net_profit AS net_profit,
    'store' AS channel,
    ss.ss_customer_sk AS customer_sk,
    ss.ss_cdemo_sk AS demo_sk
  FROM store_sales ss
  UNION ALL
  SELECT
    cs.cs_sold_date_sk,
    NULL,
    cs.cs_call_center_sk,
    NULL,
    NULL,
    cs.cs_item_sk,
    cs.cs_promo_sk,
    cs.cs_quantity,
    cs.cs_net_profit,
    'catalog',
    cs.cs_bill_customer_sk,
    cs.cs_bill_cdemo_sk
  FROM catalog_sales cs
  UNION ALL
  SELECT
    ws.ws_sold_date_sk,
    NULL,
    NULL,
    ws.ws_web_page_sk,
    ws.ws_web_site_sk,
    ws.ws_item_sk,
    ws.ws_promo_sk,
    ws.ws_quantity,
    ws.ws_net_profit,
    'web',
    ws.ws_bill_customer_sk,
    ws.ws_bill_cdemo_sk
  FROM web_sales ws
),
aggregated AS (
  SELECT
    d.d_year,
    COALESCE(s.s_state, cc.cc_state, ws_site.web_state) AS state,
    i.i_category AS category,
    COALESCE(cd.cd_gender, 'UNKNOWN') AS gender,
    SUM(su.net_profit) AS total_net_profit,
    SUM(su.quantity) AS total_quantity,
    SUM(CASE WHEN su.channel = 'store' THEN su.net_profit ELSE 0 END) AS store_profit,
    SUM(CASE WHEN su.channel = 'catalog' THEN su.net_profit ELSE 0 END) AS catalog_profit,
    SUM(CASE WHEN su.channel = 'web' THEN su.net_profit ELSE 0 END) AS web_profit,
    AVG(su.net_profit) AS avg_profit_per_sale,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS total_active_promo_cost
  FROM sales_union su
    LEFT JOIN date_dim d ON su.date_sk = d.d_date_sk
    LEFT JOIN store s ON su.store_sk = s.s_store_sk
    LEFT JOIN call_center cc ON su.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN web_site ws_site ON su.web_site_sk = ws_site.web_site_sk
    LEFT JOIN item i ON su.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON su.promo_sk = p.p_promo_sk
    LEFT JOIN customer_demographics cd ON su.demo_sk = cd.cd_demo_sk
  WHERE d.d_year BETWEEN 1999 AND 2000
    AND i.i_category IN ('Electronics', 'Books', 'Clothing')
  GROUP BY
    d.d_year,
    COALESCE(s.s_state, cc.cc_state, ws_site.web_state),
    i.i_category,
    COALESCE(cd.cd_gender, 'UNKNOWN')
  HAVING SUM(su.net_profit) > 0
)
SELECT
  a.d_year,
  a.state,
  a.category,
  a.gender,
  a.total_net_profit,
  a.total_quantity,
  a.store_profit,
  a.catalog_profit,
  a.web_profit,
  a.avg_profit_per_sale,
  a.total_active_promo_cost,
  ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_net_profit DESC) AS profit_rank
FROM aggregated a
ORDER BY a.d_year, a.total_net_profit DESC
LIMIT 100
