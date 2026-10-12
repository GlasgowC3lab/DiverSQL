WITH aggregated AS (
    SELECT
        d_return.d_year,
        d_return.d_month_seq,
        s.s_store_id,
        s.s_market_id,
        s.s_state,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        AVG(wr.wr_fee) AS avg_fee,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
        AVG(wp.wp_char_count) AS avg_page_char_count,
        MIN(wp.wp_creation_date_sk) AS earliest_creation_sk,
        MAX(wp.wp_access_date_sk) AS latest_access_sk
    FROM web_returns wr
    JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d_return.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_return.d_date_sk
    GROUP BY
        d_return.d_year,
        d_return.d_month_seq,
        s.s_store_id,
        s.s_market_id,
        s.s_state
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.s_store_id,
    a.s_market_id,
    a.s_state,
    a.total_returns,
    a.total_return_amount,
    a.avg_fee,
    a.total_inventory_on_hand,
    a.avg_page_char_count,
    a.earliest_creation_sk,
    a.latest_access_sk,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_return_amount DESC) AS yearly_return_rank
FROM aggregated a
ORDER BY a.d_year DESC, a.d_month_seq, a.total_return_amount DESC
LIMIT 100
