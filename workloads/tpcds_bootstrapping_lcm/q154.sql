WITH start_promos AS (
    SELECT p_start_date_sk AS date_sk, AVG(p_cost) AS avg_start_cost
    FROM promotion
    GROUP BY p_start_date_sk
), end_promos AS (
    SELECT p_end_date_sk AS date_sk, AVG(p_cost) AS avg_end_cost
    FROM promotion
    GROUP BY p_end_date_sk
), daily_agg AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount,
        COALESCE(SUM(wr.wr_return_tax), 0) AS total_return_tax,
        COALESCE(SUM(wr.wr_net_loss), 0) AS total_net_loss,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_order_returns,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory_on_hand,
        COUNT(DISTINCT s.s_store_sk) AS closed_stores_count,
        sp.avg_start_cost,
        ep.avg_end_cost
    FROM date_dim d
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN start_promos sp ON sp.date_sk = d.d_date_sk
    LEFT JOIN end_promos ep ON ep.date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d.d_date, d.d_year, d.d_month_seq, d.d_day_name, sp.avg_start_cost, ep.avg_end_cost
)
SELECT
    d_agg.d_date,
    d_agg.d_year,
    d_agg.d_month_seq,
    d_agg.d_day_name,
    d_agg.total_return_amount,
    d_agg.total_return_tax,
    d_agg.total_net_loss,
    d_agg.distinct_order_returns,
    d_agg.total_inventory_on_hand,
    d_agg.closed_stores_count,
    d_agg.avg_start_cost,
    d_agg.avg_end_cost,
    ROW_NUMBER() OVER (ORDER BY d_agg.total_return_amount DESC) AS return_amount_rank
FROM daily_agg d_agg
ORDER BY d_agg.total_return_amount DESC
LIMIT 100
