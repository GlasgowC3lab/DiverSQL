WITH sales_agg AS (
    SELECT
        ss_ticket_number,
        ss_item_sk,
        ss_promo_sk,
        ss_ext_sales_price,
        ss_net_profit,
        ss_ext_discount_amt
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2450365
),
returns_agg AS (
    SELECT
        sr_ticket_number,
        sr_item_sk,
        sr_return_amt_inc_tax,
        sr_refunded_cash,
        sr_fee,
        sr_return_quantity
    FROM store_returns
    WHERE sr_return_quantity > 0
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    COUNT(DISTINCT s.ss_ticket_number) AS num_sales,
    SUM(s.ss_ext_sales_price) AS total_sales,
    SUM(s.ss_net_profit) AS total_profit,
    SUM(COALESCE(r.sr_return_amt_inc_tax, 0)) AS total_returns,
    SUM(COALESCE(r.sr_refunded_cash, 0)) AS total_refunded,
    SUM(COALESCE(r.sr_fee, 0)) AS total_return_fees,
    AVG(s.ss_ext_discount_amt) AS avg_discount,
    (SUM(s.ss_net_profit) - SUM(COALESCE(r.sr_refunded_cash, 0))) AS profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.ss_ticket_number = r.sr_ticket_number
    AND s.ss_item_sk = r.sr_item_sk
JOIN promotion p
    ON s.ss_promo_sk = p.p_promo_sk
WHERE p.p_cost > 5000
GROUP BY p.p_promo_id, p.p_promo_name
HAVING SUM(s.ss_net_profit) > 10000
ORDER BY profit_after_returns DESC
LIMIT 10
