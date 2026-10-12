WITH promotion_dates AS (
    SELECT
        p.p_promo_sk,
        p.p_discount_active,
        p.p_start_date_sk,
        p.p_end_date_sk
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
),
active_promotions AS (
    SELECT
        pd.p_promo_sk,
        d.d_date_sk
    FROM promotion_dates pd
    JOIN date_dim d
        ON d.d_date_sk BETWEEN pd.p_start_date_sk AND pd.p_end_date_sk
),
agg_returns AS (
    SELECT
        ca.ca_state AS state,
        d_ret.d_year,
        d_ret.d_moy,
        COUNT(DISTINCT wr.wr_order_number) AS num_orders,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT ap.p_promo_sk) AS active_promo_cnt
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_address ca
        ON wr.wr_returning_addr_sk = ca.ca_address_sk
    LEFT JOIN active_promotions ap
        ON d_ret.d_date_sk = ap.d_date_sk
    WHERE d_ret.d_year BETWEEN 2015 AND 2020
    GROUP BY ca.ca_state, d_ret.d_year, d_ret.d_moy
    HAVING SUM(wr.wr_net_loss) > 0
)
SELECT
    state,
    CONCAT(CAST(d_year AS VARCHAR), '-', LPAD(CAST(d_moy AS VARCHAR), 2, '0')) AS year_month,
    num_orders,
    total_net_loss,
    avg_return_qty,
    active_promo_cnt,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM agg_returns
ORDER BY total_net_loss DESC
LIMIT 10
