WITH promo_sales AS (
    SELECT
        d_sold.d_quarter_name,
        p.p_promo_sk,
        p.p_promo_name,
        date_diff('day', d_start.d_date, d_end.d_date) AS promo_duration_days,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount_amt,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_start
      ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
      ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_sold.d_current_year = 'Y'
      AND p.p_discount_active = 'Y'
      AND d_sold.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
      AND ws.ws_quantity > 0
    GROUP BY
        d_sold.d_quarter_name,
        p.p_promo_sk,
        p.p_promo_name,
        d_start.d_date,
        d_end.d_date
)
SELECT
    d_quarter_name,
    p_promo_name,
    promo_duration_days,
    total_net_profit,
    avg_discount_amt,
    total_quantity,
    RANK() OVER (PARTITION BY d_quarter_name ORDER BY total_net_profit DESC) AS profit_rank
FROM promo_sales
ORDER BY d_quarter_name, profit_rank
