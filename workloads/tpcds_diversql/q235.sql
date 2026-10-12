WITH agg_sales AS (
    SELECT
        ws_bill_cdemo_sk,
        ws_web_site_sk,
        ws_sold_date_sk,
        SUM(ws_net_paid_inc_ship) AS total_net_paid,
        COUNT(*) AS order_cnt
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ws_net_paid_inc_ship > 500
      AND ws_sales_price > 20
    GROUP BY ws_bill_cdemo_sk, ws_web_site_sk, ws_sold_date_sk
)
SELECT
    ws.web_site_id,
    cd.cd_gender,
    cd.cd_credit_rating,
    d_sold.d_year,
    d_sold.d_qoy,
    agg.total_net_paid,
    agg.order_cnt,
    agg.total_net_paid / agg.order_cnt AS avg_net_per_order,
    ws.web_name
FROM agg_sales agg
JOIN customer_demographics cd
    ON agg.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN web_site ws
    ON agg.ws_web_site_sk = ws.web_site_sk
JOIN date_dim d_sold
    ON agg.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_open
    ON ws.web_open_date_sk = d_open.d_date_sk
WHERE cd.cd_credit_rating = 'Good'
  AND cd.cd_gender = 'F'
  AND d_sold.d_year = 2001
  AND EXISTS (
        SELECT 1
        FROM date_dim d2
        WHERE d2.d_date_sk = agg.ws_sold_date_sk
          AND d2.d_qoy = 2
      )
  AND agg.total_net_paid > (SELECT AVG(total_net_paid) FROM agg_sales)
ORDER BY agg.total_net_paid DESC
LIMIT 100
