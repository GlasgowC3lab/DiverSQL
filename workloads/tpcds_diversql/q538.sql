WITH
  base AS (
    SELECT
      d.d_date,
      cs.cs_order_number,
      cs.cs_net_paid_inc_ship,
      cr.cr_return_amount,
      i.i_item_sk,
      i.i_current_price,
      r.r_reason_desc,
      cd.cd_gender,
      hd.hd_income_band_sk,
      inv.inv_quantity_on_hand,
      s.s_store_name,
      wp.wp_url,
      ws.web_name,
      CASE WHEN cr.cr_return_amount > 1000 THEN 'High' ELSE 'Low' END AS return_amount_category,
      LAG(cs.cs_net_paid_inc_ship) OVER (PARTITION BY i.i_item_sk ORDER BY d.d_date) AS lag_net_paid,
      SUM(cs.cs_ext_sales_price) OVER (PARTITION BY i.i_item_sk ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales
    FROM
      date_dim d
      JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
      JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                               AND cr.cr_item_sk = cs.cs_item_sk
      JOIN item i ON i.i_item_sk = cr.cr_item_sk
      JOIN reason r ON r.r_reason_sk = cr.cr_reason_sk
      JOIN customer_demographics cd ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
      JOIN household_demographics hd ON hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
      JOIN (SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)) inv ON inv.inv_date_sk = d.d_date_sk
                                                              AND inv.inv_item_sk = i.i_item_sk
      FULL OUTER JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
      FULL OUTER JOIN store s ON s.s_store_sk = sr.sr_store_sk
      JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
      JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE
      d.d_year = 2001
      AND s.s_country = 'United States'
      AND i.i_current_price > 50
      AND r.r_reason_desc LIKE '%defect%'
  ),
  simple AS (
    SELECT
      d.d_date,
      cs.cs_order_number,
      cs.cs_net_paid_inc_ship,
      CAST(NULL AS decimal(7,2)) AS cr_return_amount,
      i.i_item_sk,
      i.i_current_price,
      CAST(NULL AS varchar) AS r_reason_desc,
      CAST(NULL AS varchar) AS cd_gender,
      CAST(NULL AS integer) AS hd_income_band_sk,
      CAST(NULL AS integer) AS inv_quantity_on_hand,
      CAST(NULL AS varchar) AS s_store_name,
      CAST(NULL AS varchar) AS wp_url,
      CAST(NULL AS varchar) AS web_name,
      'N/A' AS return_amount_category,
      CAST(NULL AS decimal(7,2)) AS lag_net_paid,
      SUM(cs.cs_ext_sales_price) OVER (PARTITION BY i.i_item_sk ORDER BY d.d_date ROWS UNBOUNDED PRECEDING) AS running_sales
    FROM
      date_dim d
      JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
      JOIN item i ON i.i_item_sk = cs.cs_item_sk
    WHERE
      d.d_year = 2001
      AND i.i_current_price > 50
  )
SELECT
  q.d_date,
  q.cs_order_number,
  q.cs_net_paid_inc_ship,
  q.cr_return_amount,
  q.i_item_sk,
  q.i_current_price,
  q.r_reason_desc,
  q.cd_gender,
  q.hd_income_band_sk,
  q.inv_quantity_on_hand,
  q.s_store_name,
  q.wp_url,
  q.web_name,
  q.return_amount_category,
  q.lag_net_paid,
  q.running_sales
FROM (
  SELECT * FROM base
  UNION DISTINCT
  SELECT * FROM simple
) q
WHERE q.cs_order_number NOT IN (
  SELECT cr_order_number
  FROM catalog_returns
  WHERE cr_return_amount > 1500
)
ORDER BY q.running_sales DESC
LIMIT 100
