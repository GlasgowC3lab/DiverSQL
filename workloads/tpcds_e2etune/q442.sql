WITH agg_returns AS (
    SELECT
        w.w_state AS warehouse_state,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
        AND p.p_discount_active = 'Y'
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_access_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cr.cr_net_loss > 0
    GROUP BY
        w.w_state,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    HAVING SUM(cr.cr_net_loss) > 1000
)
SELECT
    warehouse_state,
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_net_loss,
    total_return_amount,
    avg_vehicle_count,
    distinct_orders,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM agg_returns
ORDER BY loss_rank
LIMIT 10
