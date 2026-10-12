WITH catalog_agg AS (
    SELECT
        cr.cr_returned_date_sk AS returned_date_sk,
        cr.cr_warehouse_sk AS warehouse_sk,
        SUM(cr.cr_return_amt_inc_tax) AS cat_return_amt_inc_tax,
        SUM(cr.cr_fee) AS cat_fee,
        SUM(cr.cr_net_loss) AS cat_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS cat_orders,
        AVG(cr.cr_return_quantity) AS avg_cat_return_qty
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk, cr.cr_warehouse_sk
),
web_agg AS (
    SELECT
        wr.wr_returned_date_sk AS returned_date_sk,
        SUM(wr.wr_return_amt_inc_tax) AS web_return_amt_inc_tax,
        SUM(wr.wr_fee) AS web_fee,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(DISTINCT wr.wr_order_number) AS web_orders,
        AVG(wr.wr_return_quantity) AS avg_web_return_qty
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    s.s_store_id,
    s.s_state,
    w.w_warehouse_name,
    w.w_state AS warehouse_state,
    CASE
        WHEN w.w_state IN ('CA','OR','WA') THEN 'West Coast'
        WHEN w.w_state IN ('NY','NJ','CT') THEN 'East Coast'
        ELSE 'Other'
    END AS region,
    ca.cat_orders,
    wa.web_orders,
    ca.cat_return_amt_inc_tax,
    wa.web_return_amt_inc_tax,
    ca.cat_fee + wa.web_fee AS total_fee,
    ca.cat_net_loss + wa.web_net_loss AS total_net_loss,
    ca.avg_cat_return_qty,
    wa.avg_web_return_qty,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY (ca.cat_return_amt_inc_tax + wa.web_return_amt_inc_tax) DESC) AS rn
FROM date_dim d
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN catalog_agg ca ON ca.returned_date_sk = d.d_date_sk
JOIN web_agg wa ON wa.returned_date_sk = d.d_date_sk
JOIN warehouse w ON ca.warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2020
  AND w.w_state IN ('CA','NY','TX')
ORDER BY d.d_date
LIMIT 100
