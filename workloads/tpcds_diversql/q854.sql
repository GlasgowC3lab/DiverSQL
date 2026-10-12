WITH sales_summary AS (
    SELECT
        d.d_date,
        d.d_day_name,
        CONCAT(d.d_day_name, ' ', t.t_shift) AS day_shift_desc,
        REGEXP_EXTRACT(d.d_day_name, '(\\w+)day') AS day_root,
        t.t_shift,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        MAX(ws.ws_coupon_amt) AS max_coupon,
        CASE
            WHEN SUM(ws.ws_net_profit) > 100000 THEN 'HIGH'
            WHEN SUM(ws.ws_net_profit) > 50000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_bucket
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE REGEXP_LIKE(d.d_day_name, '^S.*')            -- days starting with S (Saturday, Sunday)
      AND t.t_shift LIKE 'second%'
      AND d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_item_sk = ws.ws_item_sk
            AND ws2.ws_coupon_amt > 5000
      )
    GROUP BY d.d_date, d.d_day_name, t.t_shift, d.d_year
)
SELECT
    ss.d_date,
    ss.d_day_name,
    ss.day_shift_desc,
    ss.day_root,
    ss.t_shift,
    ss.total_sales,
    ss.total_profit,
    ss.profit_bucket,
    ss.order_cnt,
    ss.max_coupon,
    ROW_NUMBER() OVER (PARTITION BY ss.profit_bucket ORDER BY ss.total_profit DESC) AS profit_rank
FROM sales_summary ss
ORDER BY ss.total_profit DESC
OFFSET 0 LIMIT 100
