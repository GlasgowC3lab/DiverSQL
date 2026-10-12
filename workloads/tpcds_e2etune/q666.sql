WITH cr_agg AS (
    SELECT 
        cc.cc_call_center_id,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_net_loss) AS total_cr_net_loss,
        SUM(cr.cr_return_quantity) AS total_cr_qty,
        SUM(cr.cr_return_amount) AS total_cr_amount
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE cc.cc_gmt_offset = -5.00
      AND cc.cc_open_date_sk = (
          SELECT d2.d_date_sk
          FROM date_dim d2
          WHERE d2.d_year = 2002 AND d2.d_month_seq = 1
          LIMIT 1
      )
    GROUP BY cc.cc_call_center_id, d.d_year, d.d_month_seq
),
wr_agg AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(wr.wr_net_loss) AS total_wr_net_loss,
        SUM(wr.wr_return_quantity) AS total_wr_qty,
        SUM(wr.wr_return_amt) AS total_wr_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
    GROUP BY d.d_year, d.d_month_seq
),
inv_agg AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, d.d_month_seq
)
SELECT 
    cr.cc_call_center_id,
    cr.d_year,
    cr.d_month_seq,
    cr.total_cr_net_loss,
    wr.total_wr_net_loss,
    inv.total_inventory,
    (cr.total_cr_net_loss + wr.total_wr_net_loss) AS combined_net_loss,
    (cr.total_cr_net_loss + wr.total_wr_net_loss) / NULLIF(inv.total_inventory, 0) AS loss_per_inventory
FROM cr_agg cr
LEFT JOIN wr_agg wr ON cr.d_year = wr.d_year AND cr.d_month_seq = wr.d_month_seq
LEFT JOIN inv_agg inv ON cr.d_year = inv.d_year AND cr.d_month_seq = inv.d_month_seq
WHERE cr.total_cr_net_loss > 1000
ORDER BY combined_net_loss DESC
LIMIT 100
