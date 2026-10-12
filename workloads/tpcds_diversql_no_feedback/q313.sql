WITH base AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_state,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_bill_customer_sk,
        i.i_item_id,
        i.i_current_price,
        i.i_category,
        p.p_promo_name,
        p.p_discount_active,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_fee,
        r.r_reason_desc
    FROM call_center cc
    JOIN catalog_sales cs
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer cu
        ON cs.cs_bill_customer_sk = cu.c_customer_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cc.cc_state = 'CA'
      AND i.i_current_price BETWEEN 1 AND 5
      AND p.p_discount_active = 'Y'
      AND (r.r_reason_desc IS NULL OR r.r_reason_desc NOT LIKE '%fault%')
      AND cs.cs_quantity > 0
      AND (cr.cr_fee IS NULL OR cr.cr_fee > 10)
      AND NOT EXISTS (
          SELECT 1 FROM catalog_returns cr2
          WHERE cr2.cr_order_number = cs.cs_order_number
            AND cr2.cr_return_quantity > 0
      )
),
agg AS (
    SELECT
        cc_name,
        i_item_id,
        p_promo_name,
        SUM(cs_net_paid) AS total_sales,
        COALESCE(SUM(cr_return_amount), 0) AS total_returns,
        COUNT(DISTINCT cs_order_number) AS order_cnt
    FROM base
    GROUP BY
        cc_name,
        i_item_id,
        p_promo_name
),
 tier AS (
    SELECT *
    FROM (VALUES
        (1, 'Low',    0,       1000),
        (2, 'Medium', 1000,    5000),
        (3, 'High',   5000,  1000000)
    ) AS t(tier_id, tier_name, min_sales, max_sales)
)
SELECT
    agg.cc_name,
    agg.i_item_id,
    agg.p_promo_name,
    agg.total_sales,
    agg.total_returns,
    agg.order_cnt,
    ROW_NUMBER() OVER (PARTITION BY agg.cc_name ORDER BY agg.total_sales DESC) AS sales_rank,
    tier.tier_name
FROM agg
CROSS JOIN tier
WHERE agg.total_sales >= tier.min_sales
  AND agg.total_sales < tier.max_sales
ORDER BY agg.cc_name, sales_rank
