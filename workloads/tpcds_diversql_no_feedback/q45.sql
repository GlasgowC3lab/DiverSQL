WITH joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        d_sold.d_date AS sold_date,
        d_ship.d_date AS ship_date,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        s.s_store_name,
        s.s_state,
        w.web_name,
        w.web_state,
        d_sold.d_year
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d_sold.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN web_site w
        ON w.web_open_date_sk = d_sold.d_date_sk
    JOIN date_dim d_web_close
        ON w.web_close_date_sk = d_web_close.d_date_sk
    JOIN date_dim d_extra
        ON cs.cs_sold_date_sk = d_extra.d_date_sk
    JOIN date_dim d_returned2
        ON sr.sr_returned_date_sk = d_returned2.d_date_sk
    WHERE d_sold.d_year = 1909
      AND s.s_state IN ('NE', 'TN')
),
aggregated AS (
    SELECT
        sold_date,
        s_store_name,
        web_name,
        s_state,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_net_loss) AS total_net_loss
    FROM joined_data
    GROUP BY sold_date, s_store_name, web_name, s_state
)
SELECT
    sold_date,
    s_store_name,
    web_name,
    total_net_paid,
    total_net_profit,
    total_return_amount,
    total_net_loss,
    LAG(total_net_paid) OVER (PARTITION BY s_state ORDER BY sold_date) AS lag_total_net_paid_by_state,
    SUM(total_net_paid) OVER (PARTITION BY s_state ORDER BY sold_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_net_paid_by_state
FROM aggregated
ORDER BY sold_date DESC, total_net_paid DESC
LIMIT 100
