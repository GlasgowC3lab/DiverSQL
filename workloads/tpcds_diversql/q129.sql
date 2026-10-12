WITH
  cs_agg AS (
    SELECT
      cs_bill_cdemo_sk AS cd_demo_sk,
      SUM(cs_ext_sales_price) AS total_cs_sales,
      COUNT(*) AS cnt_cs,
      AVG(cs_sales_price) AS avg_cs_price,
      MIN(cs_sales_price) AS min_cs_price,
      MAX(cs_sales_price) AS max_cs_price
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450000 AND 2450100
      AND cs_quantity > 1
      AND cs_ext_discount_amt > 0
      AND cs_net_profit > 0
      AND cs_list_price BETWEEN 50 AND 200
    GROUP BY cs_bill_cdemo_sk
  ),
  ws_agg AS (
    SELECT
      ws_bill_cdemo_sk AS cd_demo_sk,
      ws_web_site_sk,
      SUM(ws_ext_sales_price) AS total_ws_sales,
      COUNT(*) AS cnt_ws,
      AVG(ws_sales_price) AS avg_ws_price,
      MIN(ws_sales_price) AS min_ws_price,
      MAX(ws_sales_price) AS max_ws_price
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2450100
      AND ws_quantity > 1
      AND ws_ext_discount_amt > 0
      AND ws_net_profit > 0
      AND ws_list_price BETWEEN 50 AND 200
    GROUP BY ws_bill_cdemo_sk, ws_web_site_sk
  ),
  demog_filtered AS (
    SELECT cd_demo_sk
    FROM customer_demographics
    WHERE cd_credit_rating = 'Good'
      AND cd_marital_status = 'M'
      AND cd_purchase_estimate BETWEEN 4000 AND 8000
      AND cd_gender = 'F'
      AND cd_education_status = 'College'
  ),
  intersect_demo AS (
    SELECT cd_demo_sk FROM demog_filtered
    INTERSECT
    SELECT cd_demo_sk FROM cs_agg
  ),
  full_join AS (
    SELECT
      COALESCE(cs.cd_demo_sk, ws.cd_demo_sk) AS cd_demo_sk,
      cs.total_cs_sales,
      cs.cnt_cs,
      cs.avg_cs_price,
      ws.total_ws_sales,
      ws.cnt_ws,
      ws.avg_ws_price,
      ws.ws_web_site_sk
    FROM cs_agg cs
    FULL OUTER JOIN ws_agg ws
      ON cs.cd_demo_sk = ws.cd_demo_sk
  )
SELECT
  fj.cd_demo_sk,
  d.cd_gender,
  d.cd_credit_rating,
  fj.total_cs_sales,
  fj.total_ws_sales,
  fj.cnt_cs,
  fj.cnt_ws,
  fj.avg_cs_price,
  fj.avg_ws_price,
  ws_site.web_name,
  ws_site.web_manager
FROM full_join fj
JOIN customer_demographics d
  ON fj.cd_demo_sk = d.cd_demo_sk
JOIN web_site ws_site
  ON fj.ws_web_site_sk = ws_site.web_site_sk
WHERE EXISTS (
  SELECT 1 FROM intersect_demo i WHERE i.cd_demo_sk = fj.cd_demo_sk
)
ORDER BY fj.total_cs_sales DESC NULLS LAST,
         fj.total_ws_sales DESC NULLS LAST
LIMIT 100
