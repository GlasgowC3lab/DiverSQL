WITH returns_agg AS (
    SELECT
        cr_returned_time_sk AS time_sk,
        cr_warehouse_sk,
        SUM(cr_net_loss) AS total_return_loss,
        SUM(cr_return_quantity) AS total_return_qty
    FROM catalog_returns
    GROUP BY cr_returned_time_sk, cr_warehouse_sk
),
sales_agg AS (
    SELECT
        ss_store_sk,
        ss_sold_time_sk,
        ss_net_profit,
        ss_quantity,
        ss_ticket_number,
        ss_promo_sk,
        ss_ext_discount_amt
    FROM store_sales
)
SELECT
    s.ss_store_sk AS store_id,
    td.t_shift,
    SUM(s.ss_net_profit) AS total_sales_profit,
    COALESCE(SUM(r.total_return_loss), 0) AS total_return_loss,
    SUM(s.ss_net_profit) - COALESCE(SUM(r.total_return_loss), 0) - SUM(COALESCE(p.p_cost, 0) * s.ss_quantity) AS net_profit_adjusted,
    AVG(s.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT s.ss_ticket_number) AS num_transactions,
    RANK() OVER (PARTITION BY td.t_shift ORDER BY (SUM(s.ss_net_profit) - COALESCE(SUM(r.total_return_loss), 0) - SUM(COALESCE(p.p_cost, 0) * s.ss_quantity)) DESC) AS profit_rank_by_shift
FROM sales_agg s
JOIN time_dim td ON s.ss_sold_time_sk = td.t_time_sk
LEFT JOIN promotion p ON s.ss_promo_sk = p.p_promo_sk
LEFT JOIN returns_agg r ON r.time_sk = td.t_time_sk
LEFT JOIN warehouse w ON r.cr_warehouse_sk = w.w_warehouse_sk AND w.w_state = 'CA'
WHERE td.t_hour BETWEEN 9 AND 21
  AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
GROUP BY s.ss_store_sk, td.t_shift
HAVING SUM(s.ss_net_profit) > 10000
ORDER BY net_profit_adjusted DESC
LIMIT 50
