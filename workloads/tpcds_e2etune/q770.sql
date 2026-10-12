WITH sales_by_month AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cs.cs_warehouse_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity_sold
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cs.cs_ext_tax > 0
    GROUP BY d.d_year, d.d_month_seq, cs.cs_warehouse_sk
),
returns_by_month AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_amt_inc_tax > 0
    GROUP BY d.d_year, d.d_month_seq, r.r_reason_desc
),
returns_ranked AS (
    SELECT
        r.*, 
        ROW_NUMBER() OVER (PARTITION BY r.d_year, r.d_month_seq ORDER BY r.total_return_amount DESC) AS reason_rank
    FROM returns_by_month r
),
inventory_by_month AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.cs_warehouse_sk,
    s.total_net_paid,
    s.total_net_profit,
    i.total_inventory_on_hand,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    (s.total_net_profit - COALESCE(r.total_return_amount, 0)) AS net_profit_after_returns,
    r.r_reason_desc,
    r.reason_rank
FROM sales_by_month s
LEFT JOIN returns_ranked r
    ON s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND r.reason_rank <= 3
LEFT JOIN inventory_by_month i
    ON s.d_year = i.d_year
   AND s.d_month_seq = i.d_month_seq
WHERE s.total_net_profit > 0
ORDER BY s.d_year DESC, s.d_month_seq DESC, net_profit_after_returns DESC
LIMIT 200
