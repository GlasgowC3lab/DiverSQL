WITH catalog_agg AS (
   SELECT
      p.p_promo_name AS promo_name,
      cd.cd_gender AS gender,
      ca.ca_state AS state,
      SUM(cs.cs_ext_sales_price) AS catalog_sales,
      SUM(cs.cs_net_profit) AS catalog_profit,
      AVG(cs.cs_ext_discount_amt) AS catalog_avg_discount,
      SUM(cs.cs_quantity) AS catalog_quantity
   FROM catalog_sales cs
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   WHERE cp.cp_type = 'quarterly'
     AND p.p_start_date_sk >= 2450906
   GROUP BY p.p_promo_name, cd.cd_gender, ca.ca_state
),
web_agg AS (
   SELECT
      p.p_promo_name AS promo_name,
      cd.cd_gender AS gender,
      ca.ca_state AS state,
      SUM(ws.ws_ext_sales_price) AS web_sales,
      SUM(ws.ws_net_profit) AS web_profit,
      AVG(ws.ws_ext_discount_amt) AS web_avg_discount,
      SUM(ws.ws_quantity) AS web_quantity
   FROM web_sales ws
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   WHERE p.p_start_date_sk >= 2450906
   GROUP BY p.p_promo_name, cd.cd_gender, ca.ca_state
)
SELECT
   COALESCE(ca.promo_name, wa.promo_name) AS promo_name,
   COALESCE(ca.gender, wa.gender) AS gender,
   COALESCE(ca.state, wa.state) AS state,
   ca.catalog_sales,
   wa.web_sales,
   ca.catalog_profit,
   wa.web_profit,
   (ca.catalog_quantity + wa.web_quantity) AS total_quantity,
   CASE WHEN (ca.catalog_sales + wa.web_sales) > 0
        THEN (ca.catalog_profit + wa.web_profit) / (ca.catalog_sales + wa.web_sales)
        ELSE NULL END AS overall_profit_margin
FROM catalog_agg ca
FULL OUTER JOIN web_agg wa
   ON ca.promo_name = wa.promo_name
  AND ca.gender = wa.gender
  AND ca.state = wa.state
ORDER BY overall_profit_margin DESC NULLS LAST
LIMIT 100
