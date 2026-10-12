WITH returns_agg AS (
    SELECT
        cr_order_number,
        cr_item_sk,
        cr_call_center_sk,
        SUM(cr_net_loss) AS return_loss
    FROM catalog_returns
    GROUP BY cr_order_number, cr_item_sk, cr_call_center_sk
),
sales_agg AS (
    SELECT
        cc.cc_name,
        i.i_category,
        p.p_promo_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COALESCE(SUM(r.return_loss), 0) AS total_return_loss,
        SUM(cs.cs_net_profit) - COALESCE(SUM(r.return_loss), 0) AS net_contribution
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN returns_agg r
        ON cs.cs_order_number = r.cr_order_number
        AND cs.cs_item_sk = r.cr_item_sk
        AND cs.cs_call_center_sk = r.cr_call_center_sk
    WHERE
        cc.cc_division_name IN ('pri', 'anti')
        AND cc.cc_class = 'large'
        AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2455000
        AND i.i_brand = 'Brand#12'
    GROUP BY
        cc.cc_name,
        i.i_category,
        p.p_promo_name
    HAVING
        (SUM(cs.cs_net_profit) - COALESCE(SUM(r.return_loss), 0)) > 0
)
SELECT
    cc_name,
    i_category,
    p_promo_name,
    total_sales,
    total_profit,
    total_return_loss,
    net_contribution,
    RANK() OVER (ORDER BY net_contribution DESC) AS rank_contribution
FROM sales_agg
ORDER BY net_contribution DESC
LIMIT 100
