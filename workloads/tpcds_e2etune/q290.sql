WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        i.i_brand,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        SUM(p.p_cost) AS total_promo_cost
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
      AND s.s_state = 'CA'
      AND (p.p_channel_tv = 'Y' OR p.p_channel_tv IS NULL)
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state, i.i_brand, i.i_category
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        i.i_brand,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_return_transactions
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2452000
      AND s.s_state = 'CA'
    GROUP BY s.s_store_sk, i.i_brand
)
SELECT
    a.s_store_name,
    a.s_state,
    a.i_brand,
    a.total_sales,
    a.total_discount,
    a.total_net_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    (a.total_sales - COALESCE(r.total_return_amount, 0)) AS net_sales_after_returns,
    (a.total_net_profit - COALESCE(r.total_return_loss, 0) - COALESCE(a.total_promo_cost, 0)) AS net_profit_after_returns_and_promos,
    ROUND((COALESCE(r.total_return_amount, 0) / NULLIF(a.total_sales, 0)) * 100, 2) AS return_rate_percent,
    RANK() OVER (PARTITION BY a.i_brand ORDER BY (a.total_net_profit - COALESCE(r.total_return_loss, 0) - COALESCE(a.total_promo_cost, 0)) DESC) AS brand_store_rank
FROM sales_agg a
LEFT JOIN returns_agg r
    ON a.s_store_sk = r.s_store_sk AND a.i_brand = r.i_brand
WHERE (a.total_sales - COALESCE(r.total_return_amount, 0)) > 10000
ORDER BY a.i_brand, brand_store_rank
LIMIT 100
