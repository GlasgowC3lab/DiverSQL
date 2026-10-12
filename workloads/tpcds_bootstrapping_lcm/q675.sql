WITH agg AS (
    SELECT
        d.d_year AS report_year,
        d.d_month_seq AS month_seq,
        i.i_category AS category,
        i.i_class AS class,
        s.s_division_name AS division_name,
        w.web_market_manager AS market_manager,
        COUNT(DISTINCT wr.wr_order_number) AS order_count,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_fee) AS avg_fee,
        SUM(wr.wr_return_amt) / NULLIF(SUM(wr.wr_return_quantity), 0) AS avg_return_amt_per_item
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site w
        ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_category IS NOT NULL
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        s.s_division_name,
        w.web_market_manager
)
SELECT
    agg.*,
    ROW_NUMBER() OVER (PARTITION BY agg.category ORDER BY agg.total_net_loss DESC) AS category_loss_rank
FROM agg
ORDER BY agg.total_net_loss DESC
LIMIT 100
