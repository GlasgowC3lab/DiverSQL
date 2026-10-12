SELECT
    d.d_year,
    d.d_quarter_seq,
    s.s_store_id,
    s.s_store_name,
    p.p_promo_id,
    p.p_promo_name,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    SUM(wr.wr_net_loss) AS web_net_loss,
    SUM(p.p_cost) AS promotion_cost,
    (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS total_net_loss,
    (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) / NULLIF(SUM(p.p_cost), 0) AS loss_to_promo_cost_ratio
FROM catalog_returns cr
INNER JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
INNER JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
INNER JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
INNER JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
WHERE d.d_year = 2022
  AND d.d_date_sk <= p.p_end_date_sk
GROUP BY
    d.d_year,
    d.d_quarter_seq,
    s.s_store_id,
    s.s_store_name,
    p.p_promo_id,
    p.p_promo_name
HAVING (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) > 0
ORDER BY total_net_loss DESC
LIMIT 100
