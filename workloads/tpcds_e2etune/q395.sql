WITH returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        wp.wp_type,
        t.t_hour,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT wr.wr_returning_customer_sk) AS distinct_customers,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_current_year = 'Y'
      AND d.d_current_month = 'Y'
      AND t.t_shift = 'Evening'
    GROUP BY d.d_year, d.d_month_seq, wp.wp_type, t.t_hour
)
SELECT
    r.d_year,
    r.d_month_seq,
    r.wp_type,
    r.t_hour,
    r.total_net_loss,
    r.total_return_qty,
    r.distinct_customers,
    r.avg_inventory_on_hand,
    RANK() OVER (PARTITION BY r.d_year, r.d_month_seq ORDER BY r.total_net_loss DESC) AS net_loss_rank
FROM returns_agg r
WHERE r.total_net_loss > 1000
ORDER BY r.d_year, r.d_month_seq, net_loss_rank
LIMIT 100
