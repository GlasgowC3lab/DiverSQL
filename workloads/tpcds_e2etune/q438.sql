WITH sales_agg AS (
    SELECT
        cs.cs_call_center_sk AS call_center_sk,
        i.i_category AS category,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cc.cc_manager IN ('Bob Belcher', 'Felipe Perkins')
      AND i.i_current_price > 100
      AND p.p_discount_active = 'Y'
      AND cs.cs_sold_date_sk BETWEEN 2450810 AND 2451200
    GROUP BY cs.cs_call_center_sk, i.i_category
),
returns_agg AS (
    SELECT
        cr.cr_call_center_sk AS call_center_sk,
        i.i_category AS category,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_manager IN ('Bob Belcher', 'Felipe Perkins')
      AND cr.cr_returned_date_sk BETWEEN 2450810 AND 2451200
    GROUP BY cr.cr_call_center_sk, i.i_category
)
SELECT
    cc.cc_name AS call_center_name,
    s.category,
    (s.total_net_profit - COALESCE(r.total_net_loss, 0)) AS net_profit_after_returns,
    s.distinct_customers,
    s.total_quantity,
    s.total_discount,
    RANK() OVER (PARTITION BY s.category ORDER BY (s.total_net_profit - COALESCE(r.total_net_loss, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.call_center_sk = r.call_center_sk
   AND s.category = r.category
JOIN call_center cc
    ON s.call_center_sk = cc.cc_call_center_sk
WHERE (s.total_net_profit - COALESCE(r.total_net_loss, 0)) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 20
