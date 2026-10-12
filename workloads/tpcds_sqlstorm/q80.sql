WITH
sales_union AS (
    SELECT
        ss_sold_date_sk AS sold_date_sk,
        ss_sold_time_sk AS sold_time_sk,
        ss_item_sk AS item_sk,
        ss_promo_sk AS promo_sk,
        ss_ticket_number AS order_number,
        ss_quantity AS quantity,
        ss_net_paid AS net_paid,
        ss_net_profit AS net_profit,
        ss_coupon_amt AS coupon_amt,
        ss_ext_discount_amt AS ext_discount_amt,
        'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_item_sk,
        cs_promo_sk,
        cs_order_number,
        cs_quantity,
        cs_net_paid,
        cs_net_profit,
        cs_coupon_amt,
        cs_ext_discount_amt,
        'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_item_sk,
        ws_promo_sk,
        ws_order_number,
        ws_quantity,
        ws_net_paid,
        ws_net_profit,
        ws_coupon_amt,
        ws_ext_discount_amt,
        'web' AS channel
    FROM web_sales
),
returns_union AS (
    SELECT
        sr_returned_date_sk AS return_date_sk,
        sr_item_sk AS item_sk,
        sr_ticket_number AS order_number,
        sr_return_quantity AS quantity,
        sr_return_amt AS return_amt,
        sr_net_loss AS net_loss,
        'store' AS channel
    FROM store_returns
    UNION ALL
    SELECT
        cr_returned_date_sk,
        cr_item_sk,
        cr_order_number,
        cr_return_quantity,
        cr_return_amount,
        cr_net_loss,
        'catalog' AS channel
    FROM catalog_returns
    UNION ALL
    SELECT
        wr_returned_date_sk,
        wr_item_sk,
        wr_order_number,
        wr_return_quantity,
        wr_return_amt,
        wr_net_loss,
        'web' AS channel
    FROM web_returns
),
sales_aggregated AS (
    SELECT
        su.item_sk,
        d.d_year,
        d.d_quarter_seq,
        su.channel,
        SUM(su.quantity) AS total_quantity,
        SUM(su.net_paid) AS total_net_paid,
        SUM(su.net_profit) AS total_net_profit,
        SUM(su.coupon_amt) AS total_coupon_amt,
        SUM(su.ext_discount_amt) AS total_discount_amt,
        COALESCE(SUM(p.p_cost), 0) AS total_promo_cost,
        COUNT(DISTINCT su.order_number) AS distinct_orders
    FROM sales_union su
    LEFT JOIN promotion p ON su.promo_sk = p.p_promo_sk
    JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
    GROUP BY su.item_sk, d.d_year, d.d_quarter_seq, su.channel
),
returns_aggregated AS (
    SELECT
        ru.item_sk,
        d.d_year,
        d.d_quarter_seq,
        ru.channel,
        SUM(ru.quantity) AS total_return_qty,
        SUM(ru.return_amt) AS total_return_amt,
        SUM(ru.net_loss) AS total_return_loss
    FROM returns_union ru
    JOIN date_dim d ON ru.return_date_sk = d.d_date_sk
    GROUP BY ru.item_sk, d.d_year, d.d_quarter_seq, ru.channel
),
item_details AS (
    SELECT
        i_item_sk AS item_sk,
        i_item_id,
        i_product_name,
        i_brand,
        i_category,
        i_manufact,
        CONCAT(i_item_id, ': ', i_product_name) AS item_label
    FROM item
),
combined AS (
    SELECT
        sa.item_sk,
        id.item_label,
        id.i_brand AS brand,
        id.i_category AS category,
        id.i_manufact AS manufact,
        sa.d_year,
        sa.d_quarter_seq,
        sa.channel,
        sa.total_quantity,
        sa.total_net_paid,
        sa.total_net_profit,
        sa.total_coupon_amt,
        sa.total_discount_amt,
        sa.total_promo_cost,
        COALESCE(ra.total_return_qty, 0) AS total_return_qty,
        COALESCE(ra.total_return_amt, 0) AS total_return_amt,
        COALESCE(ra.total_return_loss, 0) AS total_return_loss,
        CASE
            WHEN sa.total_quantity > 0 THEN CAST(COALESCE(ra.total_return_qty, 0) AS double) / sa.total_quantity
            ELSE NULL
        END AS return_qty_rate,
        CASE
            WHEN sa.total_net_paid > 0 THEN COALESCE(ra.total_return_amt, 0) / sa.total_net_paid
            ELSE NULL
        END AS return_amt_rate,
        (SELECT
             AVG(s2.net_paid / NULLIF(s2.quantity, 0))
         FROM sales_union s2
         JOIN date_dim d2 ON s2.sold_date_sk = d2.d_date_sk
         WHERE s2.item_sk = sa.item_sk
           AND d2.d_year = sa.d_year - 1
        ) AS prior_year_avg_price,
        CASE
            WHEN sa.total_net_paid > 0 THEN sa.total_net_profit / sa.total_net_paid
            ELSE NULL
        END AS profit_margin,
        CASE
            WHEN sa.total_net_paid > 0 THEN sa.total_discount_amt / sa.total_net_paid
            ELSE NULL
        END AS discount_rate,
        CASE
            WHEN sa.total_quantity > 0 THEN sa.total_promo_cost / sa.total_quantity
            ELSE NULL
        END AS promo_cost_per_qty,
        CASE
            WHEN sa.total_net_paid > 0 THEN (sa.total_net_profit - sa.total_promo_cost) / sa.total_net_paid
            ELSE NULL
        END AS profit_margin_adj,
        CASE
            WHEN sa.total_net_paid > 0 THEN sa.total_promo_cost / sa.total_net_paid
            ELSE NULL
        END AS promo_cost_rate
    FROM sales_aggregated sa
    LEFT JOIN returns_aggregated ra
        ON sa.item_sk = ra.item_sk
        AND sa.d_year = ra.d_year
        AND sa.d_quarter_seq = ra.d_quarter_seq
        AND sa.channel = ra.channel
    JOIN item_details id ON sa.item_sk = id.item_sk
),
ranked AS (
    SELECT
        c.*,
        ROW_NUMBER() OVER (PARTITION BY c.d_year, c.d_quarter_seq ORDER BY c.total_net_profit DESC) AS profit_rank,
        RANK() OVER (PARTITION BY c.d_year, c.d_quarter_seq ORDER BY c.total_quantity DESC) AS quantity_rank,
        approx_percentile(c.total_net_profit, 0.9) OVER (PARTITION BY c.d_year, c.d_quarter_seq) AS profit_90th_pct
    FROM combined c
),
final AS (
    SELECT
        r.item_label,
        r.brand,
        r.category,
        r.manufact,
        r.d_year,
        r.d_quarter_seq,
        r.channel,
        r.total_quantity,
        r.total_net_paid,
        r.total_net_profit,
        r.profit_margin,
        r.discount_rate,
        r.promo_cost_per_qty,
        r.profit_margin_adj,
        r.promo_cost_rate,
        r.total_return_qty,
        r.total_return_amt,
        r.return_qty_rate,
        r.return_amt_rate,
        r.prior_year_avg_price,
        r.profit_rank,
        r.quantity_rank,
        CASE WHEN r.total_net_profit >= r.profit_90th_pct THEN 1 ELSE 0 END AS is_top_10_percent_profit
    FROM ranked r
)
SELECT *
FROM final
WHERE profit_rank <= 10
   OR is_top_10_percent_profit = 1
ORDER BY d_year DESC, d_quarter_seq DESC, profit_rank ASC
LIMIT 100
