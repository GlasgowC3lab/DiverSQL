WITH sales_daily AS (
    SELECT
        d.d_date AS sale_date,
        d.d_day_name,
        d.d_quarter_name,
        regexp_extract(d.d_quarter_name, '(\\d+)', 1) AS quarter_number,
        concat(d.d_day_name, '_', d.d_quarter_name) AS day_quarter,
        sum(ws.ws_net_profit) AS total_profit,
        count(distinct ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE ws.ws_sold_date_sk IN (
        SELECT d2.d_date_sk FROM date_dim d2 WHERE d2.d_year = 2002
    )
      AND regexp_like(d.d_day_name, '^S.*')
      AND d.d_holiday LIKE '%Day%'
    GROUP BY d.d_date, d.d_day_name, d.d_quarter_name
),
returns_daily AS (
    SELECT
        d.d_date AS return_date,
        sum(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND regexp_like(d.d_day_name, '^S.*')
    GROUP BY d.d_date
)
SELECT
    sd.sale_date,
    sd.d_day_name,
    sd.day_quarter,
    sd.total_profit,
    sd.order_cnt,
    coalesce(rd.total_return_loss, 0) AS total_return_loss
FROM sales_daily sd
LEFT JOIN returns_daily rd ON sd.sale_date = rd.return_date
ORDER BY sd.total_profit DESC
LIMIT 100
