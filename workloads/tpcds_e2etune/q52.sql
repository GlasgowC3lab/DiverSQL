SELECT cp.cp_type,
       p.p_promo_name,
       d_sales.d_year,
       SUM(cs.cs_net_paid_inc_tax) AS total_sales_amount,
       SUM(cs.cs_net_profit) AS total_gross_profit,
       SUM(COALESCE(cr_agg.return_amount, 0)) AS total_return_amount,
       SUM(COALESCE(cr_agg.net_loss, 0)) AS total_return_loss,
       SUM(cs.cs_quantity) AS total_units_sold,
       SUM(COALESCE(cr_agg.return_qty, 0)) AS total_units_returned,
       CASE WHEN SUM(cs.cs_quantity) = 0 THEN 0
            ELSE ROUND(100.0 * SUM(COALESCE(cr_agg.return_qty, 0)) / SUM(cs.cs_quantity), 2)
       END AS return_rate_pct,
       (SUM(cs.cs_net_profit) - SUM(COALESCE(cr_agg.net_loss, 0))) AS net_profit_after_returns,
       RANK() OVER (PARTITION BY d_sales.d_year ORDER BY (SUM(cs.cs_net_profit) - SUM(COALESCE(cr_agg.net_loss, 0))) DESC) AS profit_rank
FROM catalog_sales cs
JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN (
    SELECT cr.cr_order_number,
           cr.cr_item_sk,
           SUM(cr.cr_return_quantity) AS return_qty,
           SUM(cr.cr_return_amount) AS return_amount,
           SUM(cr.cr_net_loss) AS net_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_order_number, cr.cr_item_sk
) cr_agg ON cs.cs_order_number = cr_agg.cr_order_number
          AND cs.cs_item_sk = cr_agg.cr_item_sk
WHERE d_sales.d_year = 2001
  AND cp.cp_type IN ('bi-annual', 'quarterly')
  AND d_sales.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
GROUP BY cp.cp_type, p.p_promo_name, d_sales.d_year
HAVING SUM(cs.cs_net_paid_inc_tax) > 100000
ORDER BY net_profit_after_returns DESC
LIMIT 10
