WITH
agg_sales AS (
    SELECT
        ws_ship_mode_sk,
        ws_web_site_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_cnt
    FROM web_sales
    GROUP BY CUBE(ws_ship_mode_sk, ws_web_site_sk)
),
full_ship AS (
    SELECT
        a.ws_ship_mode_sk,
        a.ws_web_site_sk,
        a.total_sales,
        a.total_profit,
        a.order_cnt,
        s.sm_carrier,
        s.sm_type,
        s.sm_code,
        s.sm_contract
    FROM agg_sales AS a
    FULL OUTER JOIN ship_mode AS s
        ON a.ws_ship_mode_sk = s.sm_ship_mode_sk
    WHERE (s.sm_carrier IN ('UPS', 'GREAT EASTERN') OR s.sm_carrier IS NULL)
      AND (s.sm_type = 'EXPRESS' OR s.sm_type IS NULL)
),
returns_filtered AS (
    SELECT
        wr_order_number,
        wr_item_sk,
        wr_return_amt_inc_tax,
        wr_return_quantity,
        wr_refunded_customer_sk,
        wr_return_tax
    FROM web_returns
    WHERE wr_return_amt_inc_tax > 500
      AND wr_return_quantity > 1
      AND wr_return_tax BETWEEN 0 AND 200
      AND wr_refunded_customer_sk IN (
          SELECT ws_bill_customer_sk
          FROM web_sales
          WHERE ws_ext_ship_cost > 300
            AND ws_web_site_sk = 51
      )
),
sales_detail AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_site_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit
    FROM web_sales AS ws
    WHERE ws.ws_ext_sales_price > 2000
      AND ws.ws_order_number IN (
          SELECT ws_order_number FROM web_sales WHERE ws_ext_sales_price > 2000
          INTERSECT
          SELECT wr_order_number FROM web_returns WHERE wr_return_amt_inc_tax > 1000
      )
),
joined_returns_sales AS (
    SELECT
        rf.wr_order_number,
        rf.wr_item_sk,
        rf.wr_return_amt_inc_tax,
        sd.ws_ext_sales_price,
        sd.ws_net_profit,
        sd.ws_ship_mode_sk,
        sd.ws_web_site_sk
    FROM returns_filtered AS rf
    JOIN sales_detail AS sd
        ON rf.wr_order_number = sd.ws_order_number
       AND rf.wr_item_sk = sd.ws_item_sk
)
SELECT
    f.sm_carrier,
    f.sm_type,
    f.ws_web_site_sk,
    f.total_sales,
    f.total_profit,
    f.order_cnt,
    DENSE_RANK() OVER (PARTITION BY f.sm_carrier ORDER BY f.total_profit DESC) AS profit_rank,
    ROW_NUMBER() OVER (ORDER BY f.total_sales DESC) AS sales_rownum,
    (SELECT AVG(wr_return_amt_inc_tax) FROM web_returns) AS avg_return_amt
FROM full_ship AS f
LEFT JOIN joined_returns_sales AS j
    ON f.ws_ship_mode_sk = j.ws_ship_mode_sk
   AND f.ws_web_site_sk = j.ws_web_site_sk
WHERE f.total_sales IS NOT NULL
  AND f.total_profit IS NOT NULL
ORDER BY profit_rank, f.sm_carrier, f.ws_web_site_sk
