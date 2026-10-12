WITH sales_agg AS (
    SELECT
        ss.ss_promo_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        COUNT(*) AS total_transactions
    FROM store_sales ss
    GROUP BY ss.ss_promo_sk
),
returns_agg AS (
    SELECT
        ss.ss_promo_sk,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) FILTER (WHERE sr.sr_return_quantity > 0) AS return_transactions
    FROM store_sales ss
    JOIN store_returns sr
        ON ss.ss_item_sk = sr.sr_item_sk
        AND ss.ss_ticket_number = sr.sr_ticket_number
    GROUP BY ss.ss_promo_sk
)
SELECT
    p.p_promo_id,
    p.p_channel_tv,
    p.p_channel_email,
    s.total_net_profit,
    s.total_sales_amount,
    s.total_discount_amount,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_amount - COALESCE(r.total_return_amount, 0) AS net_sales_after_returns,
    ROUND(100.0 * COALESCE(r.total_return_amount, 0) / NULLIF(s.total_sales_amount, 0), 2) AS return_rate_percent,
    s.distinct_tickets,
    s.total_transactions,
    COALESCE(r.return_transactions, 0) AS return_transactions,
    RANK() OVER (PARTITION BY p.p_channel_tv ORDER BY s.total_net_profit DESC) AS rank_within_tv_channel
FROM promotion p
JOIN sales_agg s ON p.p_promo_sk = s.ss_promo_sk
LEFT JOIN returns_agg r ON p.p_promo_sk = r.ss_promo_sk
WHERE p.p_promo_id IN ('AAAAAAAABAAAAAAA', 'AAAAAAAACAAAAAAA', 'AAAAAAAADAAAAAAA')
  AND p.p_start_date_sk BETWEEN 2450000 AND 2451000
  AND s.total_sales_amount > 10000
ORDER BY s.total_net_profit DESC
LIMIT 100
